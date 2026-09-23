#' Simulation settings
#'
#' The fourth, non-model layer: when the run starts and stops, the integration
#' step and method, and how often to save.
#'
#' @param start,stop Numeric start and end time.
#' @param dt Integration step.
#' @param method `"euler"` or `"rk4"` (fixed step, `dt`), or `"lsoda"` /
#'   `"rk45"` to hand the integration to the 'deSolve' package: adaptive step
#'   size, and in `"lsoda"`'s case automatic stiff/non-stiff switching. With
#'   those two, `dt` only sets the output grid; the solver picks its own steps,
#'   so the queue built-ins `delay_fixed()` and `previous()` are not available
#'   and discontinuities are not treated specially.
#' @param time_unit Name of the time unit (`"day"`, `"year"`, ...). Used for the
#'   flow-versus-stock unit check and for axis labels.
#' @param saveat Save interval; defaults to `dt` (every step).
#' @param check_units Warn when a flow's declared units disagree with the stock
#'   it moves.
#' @return An object of class `sim_spec`.
#' @examples
#' sim_spec(start = 0, stop = 100, dt = 0.125, method = "euler", time_unit = "day")
#' ## adaptive, stiff-capable, via deSolve
#' sim_spec(start = 0, stop = 100, dt = 0.125, method = "lsoda", time_unit = "day")
#' @export
sim_spec <- function(start = 0, stop = 100, dt = 1,
                     method = c("euler", "rk4", "lsoda", "rk45"),
                     time_unit = NULL, saveat = NULL, check_units = TRUE) {
  method <- match.arg(method)
  if (!is.numeric(start) || length(start) != 1L) sd_abort("`start` must be one number.")
  if (!is.numeric(stop) || length(stop) != 1L) sd_abort("`stop` must be one number.")
  if (!is.numeric(dt) || length(dt) != 1L || dt <= 0) sd_abort("`dt` must be a positive number.")
  if (stop < start) sd_abort("`stop` must not be before `start`.")
  if (!is.null(saveat) && (!is.numeric(saveat) || length(saveat) != 1L || saveat <= 0))
    sd_abort("`saveat` must be a positive number.")
  structure(list(start = start, stop = stop, dt = dt, method = method,
                 time_unit = time_unit, saveat = saveat %||% dt,
                 check_units = isTRUE(check_units)),
            class = "sim_spec")
}

#' Named constant overrides for a multi-scenario run
#'
#' @param ... Named lists of constant overrides; an empty list is the base run.
#' @return An object of class `sd_scenarios`.
#' @examples
#' scenarios(base = list(), aggressive = list(fraction_reinvested = 0.14))
#' @export
scenarios <- function(...) {
  s <- list(...)
  if (!length(s)) sd_abort("`scenarios()` needs at least one named scenario.")
  if (!is_named_scalar_list(s)) sd_abort("Every scenario must be named.")
  for (nm in names(s)) {
    if (!is.list(s[[nm]]))
      sd_abort(sprintf("Scenario '%s' must be a list of constant overrides.", nm))
    if (length(s[[nm]]) && !is_named_scalar_list(s[[nm]]))
      sd_abort(sprintf("Every override in scenario '%s' must be named.", nm))
  }
  structure(s, class = "sd_scenarios")
}
