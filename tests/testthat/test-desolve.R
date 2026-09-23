run_with <- function(id, method) {
  ex <- sd_example(id)
  simulate(ex$structure, ex$equations, ex$parameters,
           spec = sim_spec(ex$spec$start, ex$spec$stop, ex$spec$dt,
                           method = method, time_unit = ex$spec$time_unit))
}

test_that("the deSolve methods track rk4 on an oscillator and on the SIR model", {
  for (id in c("pendulum", "sir")) {
    rk4 <- run_with(id, "rk4")
    for (m in c("lsoda", "rk45")) {
      ad <- run_with(id, m)
      expect_true(all(is.finite(ad$value)))
      expect_equal(ad$time, rk4$time)
      for (v in unique(rk4$variable)) {
        r <- unname(series(rk4, v))
        ## against the amplitude, not value by value: a series that crosses zero
        ## has no meaningful relative error there
        expect_lt(max(abs(unname(series(ad, v)) - r)) / max(abs(r), 1e-9), 1e-4)
      }
    }
  }
})

test_that("a dt-grid built-in is refused rather than silently mis-integrated", {
  expect_error(
    simulate(sd_structure(stock("S"), aux("x"),
                          flow("f", from = .source, to = "S")),
             sd_equations(x ~ delay_fixed(t, 2), f ~ x),
             sd_parameters(initial(S = 0)),
             spec = sim_spec(0, 10, 0.5, method = "lsoda")),
    "fixed `dt` grid")
})
