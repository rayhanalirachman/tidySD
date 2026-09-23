spec1 <- sim_spec(0, 5, 1, time_unit = "year")

test_that("consistent equation units pass", {
  st <- sd_structure(
    stock("Pop", units = "people"),
    flow("births", from = .source, to = "Pop", units = "people/year"),
    aux("gap", units = "people"))
  eq <- sd_equations(births ~ Pop / lifetime, gap ~ target - Pop)
  pr <- sd_parameters(constant(lifetime = 10, target = 100), initial(Pop = 1))
  expect_s3_class(simulate(st, eq, pr, spec = spec1), "sd_result")
})

test_that("adding mismatched units is an error", {
  st <- sd_structure(
    stock("Pop", units = "people"),
    flow("births", from = .source, to = "Pop", units = "people/year"),
    aux("budget", units = "dollars"),
    aux("nonsense", units = "people"))
  eq <- sd_equations(births ~ Pop / lifetime, budget ~ 100, nonsense ~ Pop + budget)
  pr <- sd_parameters(constant(lifetime = 10), initial(Pop = 1))
  expect_error(simulate(st, eq, pr, spec = spec1), "Unit mismatch.*people.*dollars")
})

test_that("multiplication and division combine units", {
  st <- sd_structure(
    stock("Pop", units = "people"),
    flow("births", from = .source, to = "Pop", units = "people/year"),
    aux("rate", units = "people/year"),
    aux("window", units = "year"),
    aux("cohort", units = "people"))
  pr <- sd_parameters(constant(k = 1), initial(Pop = 1))
  expect_s3_class(
    simulate(st, sd_equations(births ~ rate, rate ~ Pop / window, window ~ k,
                              cohort ~ rate * window),
             pr, spec = spec1), "sd_result")
  ## the same product declared as the wrong thing is caught
  expect_error(
    simulate(st, sd_equations(births ~ rate, rate ~ Pop / window, window ~ k,
                              cohort ~ rate / window),
             pr, spec = spec1), "works out to")
})
