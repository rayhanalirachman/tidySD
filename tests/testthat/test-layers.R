test_that("the three layers are independent, inspectable data", {
  st <- sd_structure(
    meta(name = "M"),
    stock("S", units = "people"),
    flow("f", from = .source, to = "S", units = "people/day")
  )
  eq <- sd_equations(f ~ S * r)
  pa <- sd_parameters(constant(r = 0.1), initial(S = 1))
  expect_s3_class(st, "sd_structure")
  expect_s3_class(eq, "sd_equations")
  expect_s3_class(pa, "sd_parameters")
  ## no maths in the structure, no numbers in the equations
  expect_named(st$vars, c("S", "f"))
  expect_equal(deparse1(eq$eqns$f$rhs), "S * r")
  expect_equal(pa$constants$r, 0.1)
  ## printing works on each layer
  expect_output(print(st), "sd_structure")
  expect_output(print(eq), "sd_equations")
  expect_output(print(pa), "sd_parameters")
  expect_output(print(sim_spec()), "sim_spec")
})

test_that("layers are immutable: update() returns a new object", {
  eq <- sd_equations(a ~ 1, b ~ a * 2)
  eq2 <- update(eq, b ~ a * 3, c ~ b + 1)
  expect_equal(deparse1(eq$eqns$b$rhs), "a * 2")
  expect_equal(deparse1(eq2$eqns$b$rhs), "a * 3")
  expect_length(eq$eqns, 2L)
  expect_length(eq2$eqns, 3L)

  pa <- sd_parameters(constant(a = 1), initial(S = 5))
  pa2 <- update(pa, constant(a = 2))
  pa3 <- update(pa, a = 3)
  expect_equal(pa$constants$a, 1)
  expect_equal(pa2$constants$a, 2)
  expect_equal(pa3$constants$a, 3)
  expect_equal(pa2$initials$S, 5)
})

test_that("reference() marks a normalising constant without changing behaviour", {
  p <- sd_parameters(constant(a = 1), reference(b = 2))
  expect_equal(p$constants, list(a = 1, b = 2))
  expect_identical(p$references, "b")
  expect_output(print(p), "reference")
})

test_that("structure elements validate their own arguments", {
  expect_error(sd_structure(stock("S"), stock("S")), "declared twice")
  expect_error(sd_structure(stock("has space")), "not a valid R name")
  expect_error(sd_structure(flow("f", from = "Nope", to = .sink)), "not a declared stock")
  expect_error(sd_structure(stock("S", dims = "town")), "unknown dimension")
  expect_error(sd_structure(1), "structure element")
  expect_error(subscripts(c("a", "b")), "must be named")
})

test_that("equations must be two-sided formulas over declared names", {
  expect_error(sd_equations(~x), "two-sided formula")
  expect_error(sd_equations(a ~ 1, a ~ 2), "Duplicate equation")
  expect_error(sd_equations(f(x) ~ 1), "left-hand side")
  expect_error(init(x), "left-hand side of an equation")
})

test_that("parameters validate their own arguments", {
  expect_error(constant(1), "must be named")
  expect_error(constant(a = "x"), "must be numeric")
  expect_error(lookup_data("l", x = c(2, 1), y = c(1, 2)), "strictly increasing")
  expect_error(lookup_data("l", x = 1:3, y = 1:2), "equal length")
  expect_error(input_series("i", data = 1:3), "data frame")
  expect_error(sd_parameters(stock("S")), "does not belong in")
  expect_error(sd_parameters(1), "parameter element")
})

test_that("sim_spec and scenarios validate", {
  expect_error(sim_spec(dt = 0), "positive")
  expect_error(sim_spec(start = 10, stop = 0), "must not be before")
  expect_error(sim_spec(method = "magic"), "should be one of")
  expect_error(scenarios(list()), "must be named")
  expect_error(scenarios(a = 1), "list of constant overrides")
  expect_output(print(scenarios(base = list(), hi = list(a = 2))), "sd_scenarios")
})
