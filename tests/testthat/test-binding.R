tiny <- function(...) {
  list(structure = sd_structure(
         stock("S", units = "u"),
         flow("f", from = .source, to = "S", units = "u/day")),
       equations = sd_equations(f ~ S * r),
       parameters = sd_parameters(constant(r = 0.1), initial(S = 1)),
       spec = sim_spec(0, 10, 1, time_unit = "day"))
}
run_tiny <- function(m) simulate(m$structure, m$equations, m$parameters, spec = m$spec)

test_that("binding catches every mismatch between the layers", {
  m <- tiny()
  ## an equation for something that was never declared
  expect_error(simulate(m$structure, sd_equations(f ~ S * r, ghost ~ 1),
                        m$parameters, spec = m$spec), "undeclared variable")
  ## a declared flow with no equation
  st2 <- sd_structure(stock("S"), flow("f", from = .source, to = "S"),
                      aux("orphan"))
  expect_error(simulate(st2, m$equations, m$parameters, spec = m$spec),
               "No equation for: orphan")
  ## an unknown name on a right-hand side
  expect_error(simulate(m$structure, sd_equations(f ~ S * nope),
                        m$parameters, spec = m$spec), "Unknown variable")
  ## an unknown function
  expect_error(simulate(m$structure, sd_equations(f ~ wibble(S)),
                        m$parameters, spec = m$spec), "Unknown function")
  ## a stock with no initial value
  expect_error(simulate(m$structure, m$equations, sd_parameters(constant(r = 1)),
                        spec = m$spec), "no initial value")
  ## an initial for something that is not a stock
  expect_error(simulate(m$structure, m$equations,
                        update(m$parameters, initial(f = 1)), spec = m$spec),
               "not a stock")
  ## an equation typo caught with a helpful pointer
  expect_error(simulate(m$structure, sd_equations(S ~ 1, f ~ 1), m$parameters,
                        spec = m$spec), "not as a flow or aux")
})

test_that("a stock's initial value comes from exactly one place", {
  m <- tiny()
  eq <- update(m$equations, init(S) ~ 2 * r)
  expect_error(simulate(m$structure, eq, m$parameters, spec = m$spec),
               "both a numeric")
  out <- simulate(m$structure, eq, sd_parameters(constant(r = 0.1)), spec = m$spec)
  expect_equal(unname(series(out, "S")[[1]]), 0.2)
  ## init() only applies to stocks
  expect_error(simulate(m$structure, update(m$equations, init(f) ~ 1),
                        sd_parameters(constant(r = 1), initial(S = 1)), spec = m$spec),
               "not a stock")
})

test_that("derived initial values may reference other stocks", {
  st <- sd_structure(
    stock("S"), stock("I"),
    flow("ir", from = "S", to = "I"))
  eq <- sd_equations(ir ~ S * I * beta, init(S) ~ pop - I0)
  pa <- sd_parameters(constant(beta = 1e-4, pop = 1000, I0 = 1), initial(I = 1))
  out <- simulate(st, eq, pa, spec = sim_spec(0, 5, 1))
  expect_equal(unname(series(out, "S")[[1]]), 999)
})

test_that("equations resolve in dependency order, not written order", {
  st <- sd_structure(stock("S"), aux("a"), aux("b"), aux("c"),
                     flow("f", from = .source, to = "S"))
  ## deliberately written back to front
  eq <- sd_equations(f ~ c, c ~ b * 2, b ~ a + 1, a ~ S)
  out <- simulate(st, eq, sd_parameters(initial(S = 1)), spec = sim_spec(0, 3, 1))
  expect_equal(unname(series(out, "f")[[1]]), 4)
  bound <- sd_validate(st, eq, sd_parameters(initial(S = 1)), sim_spec(0, 3, 1))
  expect_lt(match("a", bound$eval_order), match("b", bound$eval_order))
  expect_lt(match("b", bound$eval_order), match("c", bound$eval_order))
  expect_output(print(bound), "sd_bound")
})

test_that("a simultaneous loop is reported as one, with the cycle", {
  st <- sd_structure(stock("S"), aux("a"), aux("b"),
                     flow("f", from = .source, to = "S"))
  eq <- sd_equations(a ~ b + 1, b ~ a + 1, f ~ a)
  expect_error(simulate(st, eq, sd_parameters(initial(S = 1)), spec = sim_spec(0, 1, 1)),
               "Circular dependency")
})

test_that("lookups and inputs must be paired with their data", {
  st <- sd_structure(stock("S"), aux("e"), lookup("lk", input = "S"),
                     flow("f", from = .source, to = "S"))
  eq <- sd_equations(e ~ lk(S), f ~ e)
  expect_error(simulate(st, eq, sd_parameters(initial(S = 1)), spec = sim_spec(0, 1, 1)),
               "No `lookup_data\\(\\)`")
  expect_error(simulate(sd_structure(stock("S"), flow("f", from = .source, to = "S")),
                        sd_equations(f ~ 1),
                        sd_parameters(initial(S = 1),
                                      lookup_data("nope", x = 1:2, y = 1:2)),
                        spec = sim_spec(0, 1, 1)), "undeclared lookup")
  st2 <- sd_structure(stock("S"), input("drv"), flow("f", from = .source, to = "S"))
  expect_error(simulate(st2, sd_equations(f ~ drv), sd_parameters(initial(S = 1)),
                        spec = sim_spec(0, 1, 1)), "No `input_series\\(\\)`")
})

test_that("units are checked against the stock a flow moves, and only then", {
  ok <- sd_structure(stock("S", units = "people"),
                     flow("f", from = .source, to = "S", units = "people/day"))
  expect_silent(check_flow_units(ok, "day"))
  bad <- sd_structure(stock("S", units = "people"),
                      flow("f", from = .source, to = "S", units = "people"))
  expect_warning(check_flow_units(bad, "day"), "Unit mismatch")
  ## unspecified units are simply not checked
  quiet <- sd_structure(stock("S"), flow("f", from = .source, to = "S"))
  expect_silent(check_flow_units(quiet, "day"))
  quiet2 <- sd_structure(stock("S", units = "people"),
                         flow("f", from = .source, to = "S"))
  expect_silent(check_flow_units(quiet2, "day"))
  ## and neither is anything when the spec names no time unit
  expect_silent(check_flow_units(bad, NULL))
  ## the parser handles powers and parentheses
  expect_true(units_equal(parse_units("radian/second^2"),
                          unit_divide(parse_units("radian/second"), c(second = 1L))))
  expect_true(units_equal(parse_units("widget/(person*hour)"),
                          parse_units("widget/person/hour")))
  expect_null(parse_units(NULL))
  expect_null(parse_units(NA_character_))
})

test_that("scenario overrides must name real constants", {
  m <- tiny()
  expect_error(simulate(m$structure, m$equations, m$parameters, spec = m$spec,
                        scenarios = scenarios(a = list(nope = 1))),
               "unknown constant")
  out <- simulate(m$structure, m$equations, m$parameters, spec = m$spec,
                  scenarios = scenarios(slow = list(r = 0.05), fast = list(r = 0.2)))
  expect_setequal(levels(out$scenario), c("slow", "fast"))
  expect_gt(at(out, "S", 10, scenario = "fast"), at(out, "S", 10, scenario = "slow"))
})

test_that("simulate() rejects misspelled arguments instead of ignoring them", {
  m <- tiny()
  expect_error(simulate(m$structure, m$equations, m$parameters, spec = m$spec,
                        senarios = scenarios(a = list())), "Unused argument")
})
