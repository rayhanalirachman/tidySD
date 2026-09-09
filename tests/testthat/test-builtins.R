aux_model <- function(eqns, consts = list(), spec = sim_spec(0, 20, 1)) {
  nms <- vapply(eqns$eqns, function(e) e$name, character(1))
  st <- do.call(sd_structure, lapply(unname(nms), aux))
  pa <- if (length(consts)) do.call(sd_parameters, list(do.call(constant, consts)))
        else sd_parameters()
  simulate(st, eqns, pa, spec = spec)
}

test_that("step, pulse and ramp follow Vensim's argument order", {
  out <- aux_model(sd_equations(
    s ~ step(3, 5),
    p ~ pulse(4, 2),
    r ~ ramp(2, 3, 6)
  ))
  expect_equal(at(out, "s", 4), 0);  expect_equal(at(out, "s", 5), 3)
  expect_equal(at(out, "s", 20), 3)
  expect_equal(at(out, "p", 3), 0);  expect_equal(at(out, "p", 4), 1)
  expect_equal(at(out, "p", 5), 1);  expect_equal(at(out, "p", 6), 0)
  expect_equal(at(out, "r", 2), 0);  expect_equal(at(out, "r", 4), 2)
  expect_equal(at(out, "r", 6), 6);  expect_equal(at(out, "r", 20), 6)
})

test_that("a step height may itself be an expression of time", {
  out <- aux_model(sd_equations(s ~ step(2 * t, 5)))
  expect_equal(at(out, "s", 4), 0)
  expect_equal(at(out, "s", 8), 16)
})

test_that("smoothN defaults to first order and to the input at t = start", {
  out <- aux_model(sd_equations(x ~ 10 + step(10, 5), s ~ smoothN(x, 2)),
                   spec = sim_spec(0, 40, 0.125))
  expect_equal(at(out, "s", 0), 10)
  ## one time constant after the step, about 1 - 1/e of the way there
  expect_equal(at(out, "s", 7), 10 + 10 * (1 - exp(-1)), tolerance = 0.05)
  expect_equal(at(out, "s", 40), 20, tolerance = 1e-6)
  ## higher order is more S-shaped: it lags more early and catches up later
  out3 <- aux_model(sd_equations(x ~ 10 + step(10, 5), s ~ smoothN(x, 2, order = 3)),
                    spec = sim_spec(0, 40, 0.125))
  expect_lt(at(out3, "s", 5.5), at(out, "s", 5.5))
  expect_equal(at(out3, "s", 40), 20, tolerance = 1e-6)
})

test_that("delayN conserves material and delays it by the delay time", {
  st <- sd_structure(aux("inflow"), aux("outflow"),
                     stock("Cumulative_in"), stock("Cumulative_out"),
                     flow("fin", from = .source, to = "Cumulative_in"),
                     flow("fout", from = .source, to = "Cumulative_out"))
  eq <- sd_equations(
    inflow ~ 100 + step(100, 4),
    outflow ~ delayN(inflow, 4, order = 3, initial = 100),
    fin ~ inflow, fout ~ outflow)
  out <- simulate(st, eq, sd_parameters(initial(Cumulative_in = 0, Cumulative_out = 0)),
                  spec = sim_spec(0, 200, 0.03125))
  ## it starts in equilibrium and ends at the new inflow
  expect_equal(at(out, "outflow", 0), 100, tolerance = 1e-9)
  expect_equal(at(out, "outflow", 200), 200, tolerance = 1e-6)
  ## material is conserved up to what is still in the pipeline (= rate * delay)
  gap <- at(out, "Cumulative_in", 200) - at(out, "Cumulative_out", 200)
  expect_equal(gap, 200 * 4, tolerance = 1)
  ## it lags: at the delay time after the step it is about half way
  expect_lt(at(out, "outflow", 8), 200)
  expect_gt(at(out, "outflow", 8), 100)
})

test_that("delayN of order 1 is the same as a hand-built stock", {
  hand <- sd_example_run("material_delay")
  out <- aux_model(sd_equations(inflow ~ 100 + step(100, 4),
                                outflow ~ delayN(inflow, 4, initial = 100)),
                   spec = sim_spec(0, 25, 0.125))
  expect_equal(unname(series(out, "outflow")),
               unname(series(hand, "outflow")), tolerance = 1e-9)
})

test_that("delay_fixed is a queue, not a cascade", {
  out <- aux_model(sd_equations(
    x ~ 100 + step(100, 4),
    fixed ~ delay_fixed(x, 4, initial = 100),
    expo  ~ delayN(x, 4, order = 3, initial = 100)),
    spec = sim_spec(0, 25, 0.125))
  ## the fixed delay is a step, translated exactly four weeks
  expect_equal(at(out, "fixed", 7.875), 100)
  expect_equal(at(out, "fixed", 8), 200)
  ## the exponential delay is a smear: it has already started, and is not done
  expect_gt(at(out, "expo", 7.875), 100)
  expect_lt(at(out, "expo", 8), 200)
  ## the fixed delay only ever returns values the input actually took
  expect_setequal(unique(round(series(out, "fixed"), 9)), c(100, 200))
})

test_that("forecast is exactly its documented expansion over smoothN", {
  eq_f <- sd_equations(x ~ 10 + ramp(1, 2, 40), f ~ forecast(x, 5, 10))
  eq_m <- sd_equations(x ~ 10 + ramp(1, 2, 40), s ~ smoothN(x, 5),
                       f ~ x * (1 + 10 * (x - s) / (s * 5)))
  a <- aux_model(eq_f, spec = sim_spec(0, 50, 0.5))
  b <- aux_model(eq_m, spec = sim_spec(0, 50, 0.5))
  expect_equal(unname(series(a, "f")), unname(series(b, "f")), tolerance = 1e-12)
  ## at t = start the smooth equals the input, so the forecast equals the input
  expect_equal(at(a, "f", 0), at(a, "x", 0))
})

test_that("previous() returns the value held at the last step", {
  out <- aux_model(sd_equations(x ~ t^2, p ~ previous(x, -1)),
                   spec = sim_spec(0, 10, 1))
  expect_equal(at(out, "p", 0), -1)
  expect_equal(at(out, "p", 1), 0)
  expect_equal(at(out, "p", 5), 16)
})

test_that("smoothN and delayN read `order` once, at initialisation", {
  ## an order expression that steps later in the run does not change the model
  out <- aux_model(sd_equations(x ~ 1, s ~ smoothN(x, 2, order = 1 + step(2, 5))),
                   consts = list(), spec = sim_spec(0, 20, 0.25))
  bound <- sd_validate(
    do.call(sd_structure, list(aux("x"), aux("s"))),
    sd_equations(x ~ 1, s ~ smoothN(x, 2, order = 1 + step(2, 5))),
    sd_parameters(), sim_spec(0, 20, 0.25))
  internal <- setdiff(bound$stock_names, bound$explicit_stocks)
  expect_length(internal, 1L)      # order 1, not 3
  ## and an order that cannot be resolved at initialisation is an error
  expect_error(
    aux_model(sd_equations(x ~ 1 + t, s ~ smoothN(x, 2, order = x))),
    "must resolve to a single number at initialisation")
})

test_that("built-in argument names are matched, and typos reported", {
  expect_error(aux_model(sd_equations(x ~ 1, s ~ smoothN(x, 2, ordre = 3))),
               "has no argument")
  expect_error(aux_model(sd_equations(x ~ 1, s ~ smoothN(x))),
               "needs at least")
  expect_error(aux_model(sd_equations(x ~ 1, s ~ step(1))), "missing argument")
})

test_that("a model may be aux-only when a delay carries all the state", {
  ex <- sd_example("smooth")
  expect_length(struct_names(ex$structure, "stock"), 0L)
  out <- sd_example_run("smooth")
  expect_true(all(c("smooth_1", "smooth_3", "smooth_n") %in% out$variable))
  ## the internal stages never leak into the output
  expect_false(any(startsWith(out$variable, ".")))
})
