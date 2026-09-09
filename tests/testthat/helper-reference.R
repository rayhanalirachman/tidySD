## Independent reference implementations.
##
## Nothing in this file uses tidysd: each model is integrated with a plain R
## loop written straight from the original deSolve / Vensim source, so that a
## match is real evidence and not a tautology.

ref_euler <- function(y0, times, f, non_negative = character()) {
  n <- length(times)
  out <- matrix(NA_real_, n, length(y0), dimnames = list(NULL, names(y0)))
  y <- y0
  out[1, ] <- y
  for (i in seq_len(n - 1L)) {
    h <- times[i + 1L] - times[i]
    y <- y + h * f(times[i], y)
    if (length(non_negative)) y[non_negative] <- pmax(y[non_negative], 0)
    out[i + 1L, ] <- y
  }
  out
}

ref_rk4 <- function(y0, times, f, non_negative = character()) {
  n <- length(times)
  out <- matrix(NA_real_, n, length(y0), dimnames = list(NULL, names(y0)))
  y <- y0
  out[1, ] <- y
  for (i in seq_len(n - 1L)) {
    h <- times[i + 1L] - times[i]
    t0 <- times[i]
    k1 <- f(t0, y)
    k2 <- f(t0 + h / 2, y + (h / 2) * k1)
    k3 <- f(t0 + h / 2, y + (h / 2) * k2)
    k4 <- f(t0 + h, y + h * k3)
    y <- y + (h / 6) * (k1 + 2 * k2 + 2 * k3 + k4)
    if (length(non_negative)) y[non_negative] <- pmax(y[non_negative], 0)
    out[i + 1L, ] <- y
  }
  out
}

## Pull one variable out of an sd_result as a plain numeric vector, ordered by
## time (and by subscript member when the variable is arrayed).
series <- function(out, var, member = NULL, scenario = NULL) {
  d <- as.data.frame(out)
  d <- d[d$variable == var, , drop = FALSE]
  if ("source" %in% names(d)) d <- d[d$source == "model", , drop = FALSE]
  if (!is.null(scenario)) d <- d[as.character(d$scenario) == scenario, , drop = FALSE]
  if (!is.null(member)) {
    dimcol <- names(d)[vapply(names(d), function(nm)
      is.character(d[[nm]]) && any(d[[nm]] == member, na.rm = TRUE), logical(1))]
    dimcol <- setdiff(dimcol, c("variable", "unit", "type", "source"))
    d <- d[d[[dimcol[1]]] == member, , drop = FALSE]
  }
  d <- d[order(d$time), , drop = FALSE]
  stats::setNames(d$value, d$time)
}

at <- function(out, var, tt, ...) {
  s <- series(out, var, ...)
  s[[which.min(abs(as.numeric(names(s)) - tt))]]
}

expect_series <- function(out, var, reference, tol = 1e-8, member = NULL,
                          scenario = NULL) {
  got <- unname(series(out, var, member = member, scenario = scenario))
  testthat::expect_equal(got, unname(reference), tolerance = tol)
}
