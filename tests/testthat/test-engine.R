decay <- function(spec) {
  simulate(
    sd_structure(stock("S", units = "u"),
                 flow("d", from = "S", to = .sink, units = "u/day")),
    sd_equations(d ~ S * k),
    sd_parameters(constant(k = 0.5), initial(S = 100)),
    spec = spec)
}

test_that("euler and rk4 differ in the way they are supposed to", {
  exact <- 100 * exp(-0.5 * 10)
  e <- at(decay(sim_spec(0, 10, 0.5, "euler", time_unit = "day")), "S", 10)
  r <- at(decay(sim_spec(0, 10, 0.5, "rk4", time_unit = "day")), "S", 10)
  expect_lt(abs(r - exact), abs(e - exact))
  expect_lt(abs(r - exact) / exact, 1e-3)
  ## halving dt halves the Euler error (first order) ...
  e2 <- at(decay(sim_spec(0, 10, 0.25, "euler", time_unit = "day")), "S", 10)
  expect_equal((e2 - exact) / (e - exact), 0.5, tolerance = 0.1)
  ## ... and cuts the RK4 error by about sixteen (fourth order)
  r2 <- at(decay(sim_spec(0, 10, 0.25, "rk4", time_unit = "day")), "S", 10)
  expect_equal((r2 - exact) / (r - exact), 1 / 16, tolerance = 0.15)
})

test_that("saveat thins the output without changing the integration", {
  fine <- decay(sim_spec(0, 10, 0.25, time_unit = "day"))
  thin <- decay(sim_spec(0, 10, 0.25, time_unit = "day", saveat = 1))
  expect_equal(length(series(thin, "S")), 11L)
  expect_equal(unname(at(thin, "S", 10)), unname(at(fine, "S", 10)))
  ## saveat need not be a whole multiple of dt: the nearest step is saved
  odd <- decay(sim_spec(0, 10, 0.3, time_unit = "day", saveat = 1))
  tt <- as.numeric(names(series(odd, "S")))
  expect_true(all(abs(tt - round(tt)) <= 0.15))
  ## and the last step is always in there
  expect_equal(max(tt), 9.9, tolerance = 1e-9)
})

test_that("non_negative clamps a stock, and its absence lets one go negative", {
  st <- sd_structure(stock("S", non_negative = TRUE), stock("T"),
                     flow("out_s", from = "S", to = .sink),
                     flow("out_t", from = "T", to = .sink))
  eq <- sd_equations(out_s ~ 30, out_t ~ 30)
  out <- simulate(st, eq, sd_parameters(initial(S = 10, T = 10)),
                  spec = sim_spec(0, 5, 1))
  expect_equal(min(series(out, "S")), 0)
  expect_lt(min(series(out, "T")), -100)
})

test_that("a flow between two stocks is an outflow of one and an inflow of the other", {
  st <- sd_structure(stock("A"), stock("B"), flow("f", from = "A", to = "B"))
  out <- simulate(st, sd_equations(f ~ A * 0.1),
                  sd_parameters(initial(A = 100, B = 0)), spec = sim_spec(0, 20, 0.5))
  tot <- series(out, "A") + series(out, "B")
  expect_equal(unname(tot), rep(100, length(tot)), tolerance = 1e-9)
  expect_lt(at(out, "A", 20), 100)
  expect_gt(at(out, "B", 20), 0)
})

test_that("a stock with no flows simply holds its value", {
  out <- simulate(sd_structure(stock("S")), sd_equations(),
                  sd_parameters(initial(S = 7)), spec = sim_spec(0, 5, 1))
  expect_equal(unname(series(out, "S")), rep(7, 6))
})

test_that("lookups honour interp and range", {
  mk <- function(interp, range, xs) {
    st <- sd_structure(aux("x"), aux("y"), lookup("lk", input = "x",
                                                  interp = interp, range = range))
    out <- simulate(st, sd_equations(x ~ t, y ~ lk(x)),
                    sd_parameters(lookup_data("lk", x = c(1, 2, 3), y = c(10, 20, 40))),
                    spec = sim_spec(0, 5, 1))
    vapply(xs, function(z) at(out, "y", z), numeric(1))
  }
  expect_equal(mk("linear", "clamp", c(0, 1, 2, 3, 5)), c(10, 10, 20, 40, 40))
  expect_equal(mk("constant", "clamp", c(1, 2, 3)), c(10, 20, 40))
  expect_equal(mk("linear", "extend", c(0, 5)), c(0, 80))
  expect_true(all(is.na(mk("linear", "na", c(0, 5)))))
})

test_that("an input series interpolates onto the solver grid", {
  df <- data.frame(time = c(0, 10), emissions = c(0, 100))
  st <- sd_structure(stock("S"), input("emissions"),
                     flow("f", from = .source, to = "S"))
  out <- simulate(st, sd_equations(f ~ emissions),
                  sd_parameters(initial(S = 0),
                                input_series("emissions", data = df, interp = "linear")),
                  spec = sim_spec(0, 10, 1))
  expect_equal(at(out, "emissions", 5), 50)
  ## outside the data range the default holds the end values
  out2 <- simulate(st, sd_equations(f ~ emissions),
                   sd_parameters(initial(S = 0),
                                 input_series("emissions", data = df)),
                   spec = sim_spec(0, 20, 1))
  expect_equal(at(out2, "emissions", 20), 100)
  ## Date times resolve against sim_spec(start = )
  dd <- data.frame(time = as.Date("2020-01-01") + c(0, 10), emissions = c(0, 100))
  out3 <- simulate(st, sd_equations(f ~ emissions),
                   sd_parameters(initial(S = 0), input_series("emissions", data = dd)),
                   spec = sim_spec(0, 10, 1))
  expect_equal(at(out3, "emissions", 5), 50)
  ## a value column that has to be named
  amb <- data.frame(time = c(0, 10), a = c(0, 1), b = c(2, 3))
  expect_error(simulate(st, sd_equations(f ~ emissions),
                        sd_parameters(initial(S = 0),
                                      input_series("emissions", data = amb)),
                        spec = sim_spec(0, 10, 1)), "candidate value columns")
})

test_that("subscripted values broadcast, and keep their labels", {
  st <- sd_structure(
    subscripts(g = c("a", "b", "c")),
    stock("S", dims = "g"), aux("total"),
    flow("f", from = .source, to = "S", dims = "g"))
  out <- simulate(st, sd_equations(f ~ S * r, total ~ sum(S)),
                  sd_parameters(constant(r = c(0.1, 0.2, 0.3)), initial(S = 10)),
                  spec = sim_spec(0, 10, 1))
  expect_equal(unname(series(out, "S", member = "a")[[1]]), 10)
  expect_equal(unname(series(out, "S", member = "c")[[1]]), 10)
  expect_gt(at(out, "S", 10, member = "c"), at(out, "S", 10, member = "a"))
  expect_equal(at(out, "total", 0), 30)
  ## a wrongly-sized initial is caught
  expect_error(simulate(st, sd_equations(f ~ S * r, total ~ sum(S)),
                        sd_parameters(constant(r = 0.1), initial(S = c(1, 2))),
                        spec = sim_spec(0, 1, 1)), "has length 2")
})

test_that("the output tibble is long, tidy and correctly typed", {
  out <- sd_example_run("sir")
  expect_s3_class(out, "sd_result")
  expect_s3_class(out, "tbl_df")
  expect_true(all(c("time", "variable", "value", "unit", "type") %in% names(out)))
  expect_setequal(unique(out$type), c("stock", "flow", "aux"))
  expect_setequal(unique(out$variable), c("S", "I", "R", "IR", "RR", "beta", "lambda"))
  expect_equal(unique(out$unit[out$variable == "S"]), "people")
  meta <- attr(out, "sd_meta")
  expect_equal(meta$name, "SIR")
  expect_equal(meta$time_unit, "day")
  expect_s3_class(summary(out), "tbl_df")
  expect_output(print(out), "SIR")
  ## the subscript column appears only for a subscripted model
  expect_false("cohort" %in% names(out))
  expect_true("cohort" %in% names(sd_example_run("cohort_sir")))
})

test_that("observed data is stacked beside the model, not merged into it", {
  ex <- sd_example("sir")
  obs <- data.frame(time = c(0, 5, 10), cases = c(1, 20, 400))
  out <- simulate(ex$structure, ex$equations, ex$parameters, spec = ex$spec,
                  observed = obs, map = c(I = "cases"))
  expect_setequal(unique(out$source), c("model", "observed"))
  o <- out[out$source == "observed", ]
  expect_equal(nrow(o), 3L)
  expect_equal(o$value, c(1, 20, 400))
  expect_true(all(o$variable == "I"))
  ## the model rows are untouched
  base <- sd_example_run("sir")
  expect_equal(unname(series(out, "I")), unname(series(base, "I")))
  ## a mapped column that is not in the data is an error
  expect_error(simulate(ex$structure, ex$equations, ex$parameters, spec = ex$spec,
                        observed = obs, map = c(I = "nope")), "no column")
  expect_error(simulate(ex$structure, ex$equations, ex$parameters, spec = ex$spec,
                        observed = data.frame(x = 1)), "needs a `time` column")
})

test_that("sd_simulate is an identical, non-masking alias", {
  a <- sd_example_run("teacup")
  ex <- sd_example("teacup")
  b <- sd_simulate(ex$structure, ex$equations, ex$parameters, spec = ex$spec)
  expect_equal(as.data.frame(a), as.data.frame(b))
})
