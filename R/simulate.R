#' Bind the layers, validate, integrate
#'
#' `simulate()` is the single verb: it binds [sd_structure()], [sd_equations()]
#' and [sd_parameters()], validates them against each other, resolves the
#' equations into a dependency graph, integrates, and returns one long-format
#' tibble.
#'
#' `tidysd::simulate()` masks [stats::simulate()]. `sd_simulate()` is an
#' identical, non-masking alias.
#'
#' @param structure An [sd_structure()] object.
#' @param equations An [sd_equations()] object.
#' @param parameters An [sd_parameters()] object.
#' @param spec A [sim_spec()] object.
#' @param scenarios Optional [scenarios()] object: named lists of constant
#'   overrides, each run separately and tagged in a `scenario` column.
#' @param observed Optional data frame with a `time` column, stacked into the
#'   output tagged `source = "observed"` beside `"model"`.
#' @param map Named character vector mapping model variables to `observed`
#'   columns, e.g. `c(I = "cases")`. Defaults to matching column names.
#' @param ... Unused; present so that misspelled arguments are caught.
#'
#' @return A tibble of class `sd_result` with columns `scenario` (when
#'   scenarios were given), one column per subscript dimension, `time`,
#'   `variable`, `value`, `unit`, `type`, and `source` (when `observed` was
#'   given).
#'
#' @examples
#' out <- simulate(
#'   sd_structure(
#'     stock("Customers", units = "customers"),
#'     flow("recruits", from = .source, to = "Customers", units = "customers/year"),
#'     flow("losses", from = "Customers", to = .sink, units = "customers/year")
#'   ),
#'   sd_equations(
#'     recruits ~ Customers * growth_fraction,
#'     losses   ~ Customers * decline_fraction
#'   ),
#'   sd_parameters(
#'     constant(growth_fraction = 0.08, decline_fraction = 0.03),
#'     initial(Customers = 10000)
#'   ),
#'   spec = sim_spec(start = 2015, stop = 2030, dt = 0.25, time_unit = "year")
#' )
#' head(out)
#' @export
simulate <- function(structure, equations, parameters, spec = sim_spec(),
                     scenarios = NULL, observed = NULL, map = NULL, ...) {
  dots <- list(...)
  if (length(dots))
    sd_abort(sprintf("Unused argument(s) to `simulate()`: %s.", comma(names(dots))))
  sd_simulate_impl(structure, equations, parameters, spec, scenarios, observed, map)
}

#' @rdname simulate
#' @export
sd_simulate <- function(structure, equations, parameters, spec = sim_spec(),
                        scenarios = NULL, observed = NULL, map = NULL, ...) {
  simulate(structure, equations, parameters, spec, scenarios, observed, map, ...)
}

sd_simulate_impl <- function(struct, eqns, pars, spec, scen, observed, map) {
  if (is.null(scen)) {
    bm <- sd_bind(struct, eqns, pars, spec)
    run <- sd_run(bm)
    tbl <- build_output(bm, run)
    obs <- observed_long(observed, map, names(struct$dims), NULL, bm$out_vars)
    return(new_sd_result(tbl, bm, obs))
  }

  if (!inherits(scen, "sd_scenarios")) {
    if (is.list(scen) && is_named_scalar_list(scen)) {
      scen <- do.call(scenarios, scen)
    } else {
      sd_abort("`scenarios` must come from `scenarios()`.")
    }
  }

  parts <- list()
  bm <- NULL
  for (nm in names(scen)) {
    bmi <- sd_bind(struct, eqns, pars, spec, overrides = scen[[nm]])
    run <- sd_run(bmi)
    parts[[nm]] <- build_output(bmi, run, scenario = nm)
    if (is.null(bm)) bm <- bmi
  }
  tbl <- tibble::as_tibble(do.call(rbind, parts))
  tbl$scenario <- factor(tbl$scenario, levels = names(scen))
  obs <- NULL
  if (!is.null(observed)) {
    obs <- do.call(rbind, lapply(names(scen), function(nm)
      observed_long(observed, map, names(struct$dims), nm, bm$out_vars)))
    obs$scenario <- factor(obs$scenario, levels = names(scen))
  }
  new_sd_result(tbl, bm, obs)
}

#' Bind the three layers without integrating
#'
#' Runs exactly the validation and graph resolution that [simulate()] does, and
#' returns the bound model. Useful for checking a model, or for inspecting the
#' evaluation order.
#'
#' @inheritParams simulate
#' @return An object of class `sd_bound`.
#' @export
sd_validate <- function(structure, equations, parameters, spec = sim_spec()) {
  sd_bind(structure, equations, parameters, spec)
}
