#' Estimate free constants from observed data
#'
#' `calibrate()` takes the same three layers as [simulate()], plus an observed
#' data frame, a map from model variable to data column, the constants that are
#' free to move and their bounds. It does bounded least squares
#' ([stats::optim()], `"L-BFGS-B"`) and returns a fitted `sd_parameters` object
#' you pass straight back to [simulate()].
#'
#' One verb, not an optimisation framework.
#'
#' @inheritParams simulate
#' @param observed A data frame with a `time` column.
#' @param target Named character vector mapping model variable to observed
#'   column, e.g. `c(I = "sInfected")`.
#' @param free Character vector of constants to estimate.
#' @param lower,upper Named numeric bounds for the free constants.
#' @param weights Optional named numeric vector, one weight per target.
#' @param control Passed to [stats::optim()].
#' @return An object of class `sd_calibration`: `$parameters` (fitted layer),
#'   `$fit` (estimates, SSE, convergence) and `$optim` (the raw result).
#' @export
calibrate <- function(structure, equations, parameters, spec = sim_spec(),
                      observed, target, free, lower = NULL, upper = NULL,
                      weights = NULL, control = list()) {
  struct <- structure
  pars <- parameters
  if (!is.data.frame(observed)) sd_abort("`observed` must be a data frame.")
  if (is.null(names(target)) || any(!nzchar(names(target))))
    sd_abort("`target` must be named: `c(model_variable = \"observed_column\")`.")
  if (!is.character(free) || !length(free)) sd_abort("`free` must name at least one constant.")

  unknown <- setdiff(free, names(pars$constants))
  if (length(unknown))
    sd_abort(sprintf("`free` names constant(s) not in `sd_parameters()`: %s.", comma(unknown)))
  nonscalar <- free[vapply(pars$constants[free], function(v) length(v) != 1L, logical(1))]
  if (length(nonscalar))
    sd_abort(sprintf("`calibrate()` estimates scalar constants; these are not: %s.",
                     comma(nonscalar)))

  cols <- names(observed)
  tcol <- cols[tolower(cols) == "time"]
  if (!length(tcol)) sd_abort("`observed` needs a `time` column.")
  otime <- as.numeric(observed[[tcol[1]]])
  miss <- setdiff(unname(target), cols)
  if (length(miss)) sd_abort(sprintf("`observed` has no column(s): %s.", comma(miss)))

  w <- if (is.null(weights)) stats::setNames(rep(1, length(target)), names(target)) else weights
  start <- vapply(pars$constants[free], as.numeric, numeric(1))
  lo <- if (is.null(lower)) rep(-Inf, length(free)) else as.numeric(lower[free])
  up <- if (is.null(upper)) rep(Inf, length(free)) else as.numeric(upper[free])
  names(lo) <- names(up) <- free
  start <- pmin(pmax(start, lo), up)

  ## bind once to fail fast on a broken model
  sd_bind(struct, equations, pars, spec)

  cost <- function(p) {
    names(p) <- free
    pp <- update(pars, do.call(constant, as.list(p)))
    res <- tryCatch(sd_simulate_impl(struct, equations, pp, spec, NULL, NULL, NULL),
                    error = function(e) NULL)
    if (is.null(res)) return(1e12)
    sse <- 0
    for (mv in names(target)) {
      r <- res[res$variable == mv, c("time", "value")]
      if (!nrow(r)) sd_abort(sprintf("'%s' is not a variable in the model.", mv))
      f <- stats::approxfun(r$time, r$value, rule = 2)
      pred <- f(otime)
      obs <- as.numeric(observed[[target[[mv]]]])
      ok <- is.finite(pred) & is.finite(obs)
      if (!any(ok)) return(1e12)
      sse <- sse + (w[[mv]] %||% 1) * sum((pred[ok] - obs[ok])^2)
    }
    if (!is.finite(sse)) 1e12 else sse
  }

  ## Two stages. L-BFGS-B on well-scaled parameters gets close fast; a bounded
  ## Nelder-Mead polish (bounds folded into the parameterisation) rescues the
  ## line-search failures that finite-difference gradients over a simulation
  ## routinely produce. Whichever ends lower wins.
  scale <- pmax(abs(start), 1e-8)
  ctl <- utils::modifyList(list(parscale = scale, ndeps = rep(1e-3, length(start)),
                                factr = 1e4), control)
  fit <- tryCatch(
    stats::optim(par = start, fn = cost, method = "L-BFGS-B",
                 lower = lo, upper = up, control = ctl),
    error = function(e) list(par = start, value = cost(start), convergence = 99L,
                             message = conditionMessage(e)))

  to_free <- function(x) ifelse(is.finite(lo) & is.finite(up),
                                stats::qlogis(pmin(pmax((x - lo) / (up - lo), 1e-9), 1 - 1e-9)), x)
  from_free <- function(z) ifelse(is.finite(lo) & is.finite(up),
                                  lo + (up - lo) * stats::plogis(z), pmin(pmax(z, lo), up))
  polish <- tryCatch(
    stats::optim(par = to_free(fit$par), fn = function(z) cost(from_free(z)),
                 method = "Nelder-Mead",
                 control = utils::modifyList(list(reltol = 1e-12, maxit = 2000), control)),
    error = function(e) NULL)
  if (!is.null(polish) && is.finite(polish$value) && polish$value < fit$value) {
    fit <- list(par = from_free(polish$par), value = polish$value,
                convergence = polish$convergence, message = polish$message,
                counts = polish$counts, stage = "nelder-mead")
  } else {
    fit$stage <- "l-bfgs-b"
  }

  est <- fit$par
  names(est) <- free
  fitted_pars <- update(pars, do.call(constant, as.list(est)))

  out <- list(
    parameters = fitted_pars,
    fit = list(estimate = est, sse = fit$value, convergence = fit$convergence,
               message = fit$message, stage = fit$stage, n_obs = length(otime),
               free = free, lower = lo, upper = up),
    optim = fit,
    target = target
  )
  class(out) <- "sd_calibration"
  out
}

#' @export
print.sd_calibration <- function(x, ...) {
  cat("<sd_calibration>\n")
  cat("  estimated:\n")
  est <- x$fit$estimate
  for (nm in names(est)) cat(sprintf("    %-28s %s\n", nm, format(est[[nm]], digits = 6)))
  cat(sprintf("  SSE          %s over %d observations\n",
              format(x$fit$sse, digits = 6), x$fit$n_obs))
  cat(sprintf("  convergence  %s%s\n", x$fit$convergence,
              if (identical(x$fit$convergence, 0L)) " (converged)" else ""))
  invisible(x)
}
