## ---------------------------------------------------------------------------
## Monte Carlo draws and full-factorial grids, run through the scenario runner.
## ---------------------------------------------------------------------------

## One column of values per swept constant.
##   function      -> called as f(n)                    (random only)
##   length-2 num  -> a range: runif() / seq()
##   anything else -> a set of values: sample() / the grid levels themselves
sweep_values <- function(x, n, method, nm) {
  if (is.function(x)) {
    if (method == "grid")
      sd_abort(sprintf("'%s': `method = \"grid\"` needs a range or values, not a function.", nm))
    return(as.numeric(x(n)))
  }
  if (!length(x)) sd_abort(sprintf("'%s' has no values to sweep over.", nm))
  if (is.numeric(x) && length(x) == 2L) {
    return(if (method == "random") stats::runif(n, x[[1]], x[[2]])
           else seq(x[[1]], x[[2]], length.out = n))
  }
  if (method == "random") sample(x, n, replace = TRUE) else x
}

#' Sweep constants: Monte Carlo draws or a full-factorial grid
#'
#' A thin wrapper around the [scenarios()] runner for sensitivity analysis.
#' Each `...` argument names a constant and says how to vary it:
#'
#' * a **function**, called as `f(n)` -- e.g. `function(n) rnorm(n, 0.08, 0.01)`
#'   (`method = "random"` only);
#' * a **length-2 numeric**, a range -- drawn with [stats::runif()] when
#'   `method = "random"`, or cut into `n` levels with [seq()] when
#'   `method = "grid"`;
#' * **any other vector**, a set of values -- sampled with replacement when
#'   `method = "random"`, or used as the grid levels as given.
#'
#' `method = "grid"` runs every combination ([expand.grid()]), so the number of
#' runs is the product of the level counts, not `n`.
#'
#' @inheritParams simulate
#' @param ... Named constants to sweep, as described above.
#' @param n Number of draws (`"random"`), or levels per range (`"grid"`).
#' @param method `"random"` for Monte Carlo, `"grid"` for full factorial.
#' @return A tibble of class `sd_result` in the usual long format, with a
#'   `.run` column identifying the draw and one column per swept constant
#'   holding the value used in that run.
#' @examples
#' ex <- sd_example("customer_growth")
#' mc <- sd_sweep(ex$structure, ex$equations, ex$parameters, spec = ex$spec,
#'                growth_fraction = c(0.05, 0.11), n = 20)
#' head(mc)
#'
#' grid <- sd_sweep(ex$structure, ex$equations, ex$parameters, spec = ex$spec,
#'                  growth_fraction = c(0.05, 0.11),
#'                  decline_fraction = c(0.02, 0.03, 0.04),
#'                  n = 3, method = "grid")
#' length(unique(grid$.run))
#' @export
sd_sweep <- function(structure, equations, parameters, spec = sim_spec(), ...,
                     n = 100, method = c("random", "grid")) {
  method <- match.arg(method)
  swept <- list(...)
  if (!length(swept) || !is_named_scalar_list(swept))
    sd_abort("`sd_sweep()` needs at least one named constant, e.g. `r = c(0.05, 0.2)`.")
  if (!is.numeric(n) || length(n) != 1L || n < 1)
    sd_abort("`n` must be a positive number.")
  n <- as.integer(n)

  ## ponytail: parameters are sampled independently -- no correlation or
  ## covariance between them is modelled. For joint sampling, replace this
  ## block with one that draws the whole matrix at once (e.g. a Cholesky
  ## factor times independent normals) and keep the rest as is.
  cols <- lapply(names(swept), function(nm) sweep_values(swept[[nm]], n, method, nm))
  names(cols) <- names(swept)
  draws <- if (method == "random")
    as.data.frame(cols, stringsAsFactors = FALSE)
  else
    expand.grid(cols, stringsAsFactors = FALSE, KEEP.OUT.ATTRS = FALSE)

  scen <- lapply(seq_len(nrow(draws)), function(i) as.list(draws[i, , drop = FALSE]))
  names(scen) <- as.character(seq_along(scen))
  out <- sd_simulate_impl(structure, equations, parameters, spec,
                          do.call(scenarios, scen), NULL, NULL)

  run <- as.integer(as.character(out$scenario))
  out$scenario <- NULL
  out$.run <- run
  for (nm in names(draws)) out[[nm]] <- draws[[nm]][run]
  cls <- class(out)
  meta <- attr(out, "sd_meta")
  front <- c(".run", names(draws))
  out <- out[c(front, setdiff(names(out), front))]
  class(out) <- cls
  attr(out, "sd_meta") <- meta
  out
}
