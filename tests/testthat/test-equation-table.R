test_that("sd_equation_table() surfaces doc strings, equations and units", {
  st <- sd_structure(
    stock("S", units = "people", doc = "Susceptible people"),
    flow("IR", from = "S", to = .sink, units = "people/day",
         doc = "Infection rate"),
    aux("lambda")
  )
  eq <- sd_equations(IR ~ S * lambda, lambda ~ beta * 2)
  pa <- sd_parameters(constant(beta = 0.3), initial(S = 999))
  tb <- sd_equation_table(st, eq, pa)

  expect_s3_class(tb, "tbl_df")
  expect_equal(tb$doc[tb$name == "S"], "Susceptible people")
  expect_equal(tb$doc[tb$name == "IR"], "Infection rate")
  expect_true(is.na(tb$doc[tb$name == "lambda"]))
  expect_equal(tb$units[tb$name == "IR"], "people/day")
  expect_equal(tb$equation[tb$name == "IR"], "S * lambda")
  expect_equal(tb$equation[tb$name == "S"], "999")
  expect_equal(tb$type[tb$name == "beta"], "constant")
})

test_that("a model without any doc = still works, with an NA doc column", {
  st <- sd_structure(stock("S"), flow("f", from = .source, to = "S"))
  tb <- sd_equation_table(st, sd_equations(f ~ S / 2))
  expect_true(all(is.na(tb$doc)))
  expect_equal(tb$equation[tb$name == "f"], "S/2")
  expect_true(is.na(tb$equation[tb$name == "S"]))
})

test_that("derived initials are deparsed too", {
  st <- sd_structure(stock("S"), aux("a"))
  tb <- sd_equation_table(st, sd_equations(init(S) ~ 1000 - 1, a ~ 1))
  expect_equal(tb$equation[tb$name == "S"], "1000 - 1")
})
