#' The catalogue of worked models
#'
#' Every model in the `tidysd` catalogue, ready to run. Each is returned as the
#' three layers plus a [sim_spec()] -- nothing is pre-simulated, so you can
#' inspect, edit or re-parameterise any layer before running it.
#'
#' | # | model | behaviour | grammar it exercises |
#' |---|---|---|---|
#' | 1 | `customer_growth` | exponential | boundary flows, constant fractions |
#' | 2 | `s_shaped_growth` | logistic | RHS literal, `reference()` |
#' | 3 | `overshoot` | overshoot then decay | `lookup()`, `min()`, `scenarios()` |
#' | 4 | `solow` | goal-seeking | `sqrt`, unspecified units |
#' | 5 | `sir` | epidemic | the core grammar |
#' | 6 | `bass` | S-curve | two coupled stocks, `update()` form-swap |
#' | 7 | `cohort_sir` | 3 coupled waves | `subscripts()`, matrix `constant()`, `%*%` |
#' | 8 | `material_delay` | exponential approach | `step()`, first-order delay as a stock |
#' | 9 | `teacup` | exponential decay to a goal | the minimal one-stock model |
#' | 10 | `lotka_volterra` | limit cycle | nonlinear coupling, `reference()` |
#' | 11 | `town_population` | growth with an aged outflow | `subscripts()`, `delayN(order = 8)` |
#' | 12 | `smooth` | information delay | `smoothN()` at every order, aux-only |
#' | 13 | `forecast` | trend extrapolation | `forecast()`, `ramp()`, `delay_fixed()` |
#' | 14 | `delay_fixed` | exact translation in time | `delay_fixed()`, variable delay time |
#' | 15 | `workforce` | damped oscillation | aging chain, `lookup()`, `min()` |
#' | 16 | `defects` | pulse shock | `pulse()`, two lookups on one stock |
#' | 17 | `carbon_bathtub` | accumulation | `input()` + `input_series()` |
#' | 18 | `roessler` | chaos | signed net flows, `method = "rk4"` |
#' | 19 | `pendulum` | conservative oscillation | second-order system, integrator choice |
#' | 20 | `sales_agents` | collapse after a subsidy ends | `ifelse` gate, `scenarios()` |
#' | 21 | `capability_trap` | irreversible erosion | lookups multiplied, `step()` in a flow |
#' | 22 | `boarding_school_flu` | SIR fitted to real data | `observed =`, `calibrate()` |
#'
#' @param id A number 1-22 or the model's name (see the table).
#' @return An object of class `sd_example`: a list with `structure`,
#'   `equations`, `parameters`, `spec`, and optionally `scenarios`, `observed`,
#'   `map` and `calibration`.
#' @examples
#' ex <- sd_example("sir")
#' out <- simulate(ex$structure, ex$equations, ex$parameters, spec = ex$spec)
#' @export
sd_example <- function(id) {
  ids <- sd_example_ids()
  if (is.numeric(id)) {
    if (length(id) != 1L || id < 1 || id > nrow(ids))
      sd_abort(sprintf("`id` must be a number between 1 and %d, or a model name.", nrow(ids)))
    nm <- ids$name[[as.integer(id)]]
  } else {
    nm <- match.arg(as.character(id), ids$name)
  }
  ex <- EXAMPLES[[nm]]()
  ex$name <- nm
  ex$number <- match(nm, ids$name)
  class(ex) <- "sd_example"
  ex
}

#' @rdname sd_example
#' @export
sd_example_ids <- function() {
  tibble::tibble(number = seq_along(EXAMPLE_NAMES), name = EXAMPLE_NAMES)
}

#' Run a catalogue model
#'
#' @param id A number 1-22 or the model's name.
#' @param ... Passed to [simulate()], overriding the example's own arguments.
#' @return An `sd_result` tibble.
#' @examples
#' out <- sd_example_run("teacup")
#' @export
sd_example_run <- function(id, ...) {
  ex <- sd_example(id)
  args <- list(structure = ex$structure, equations = ex$equations,
               parameters = ex$parameters, spec = ex$spec)
  if (!is.null(ex$scenarios)) args$scenarios <- ex$scenarios
  if (!is.null(ex$observed)) { args$observed <- ex$observed; args$map <- ex$map }
  do.call(simulate, utils::modifyList(args, list(...)))
}

#' @export
print.sd_example <- function(x, ...) {
  cat(sprintf("<sd_example %d: %s>\n", x$number, x$name))
  if (!is.null(x$structure$meta$name)) cat("  ", x$structure$meta$name, "\n", sep = "")
  print(x$spec)
  cat(sprintf("  %d stocks, %d equations%s\n",
              length(struct_names(x$structure, "stock")), length(x$equations$eqns),
              if (!is.null(x$scenarios)) sprintf(", %d scenarios", length(x$scenarios)) else ""))
  if (!is.null(x$note)) cat("  note: ", x$note, "\n", sep = "")
  invisible(x)
}
