## Models 16-22: the PySD cookbook samples, plus the fitted SIR.

test_that("16. manufacturing defects: the pulse makes the line worse at itself", {
  out <- sd_example_run("defects")
  speed <- stats::approxfun(c(0, 5, 10, 15, 20, 80),
                            c(0.1, 0.1, 0.09, 0.05, 0.04, 0.04), rule = 2)
  workday <- stats::approxfun(c(0, 2.76986, 5.53971, 10.3462, 13.1161, 16.5377,
                                20.5295, 60),
                              c(0.1, 0.128571, 0.188095, 0.347619, 0.416667,
                                0.452381, 0.469048, 0.5), rule = 2)
  times <- seq(0, 50, by = 0.015625)
  ref <- ref_euler(c(B = 11.7), times, function(t, y) {
    tap <- speed(y[["B"]]); low <- workday(y[["B"]])
    defect <- 0.01 * low / tap
    fulfil <- 2 * low / tap * (1 - defect)
    arrive <- 10 + 12 * as.numeric(t >= 20 && t < 30)
    c(B = arrive - fulfil)
  }, non_negative = "B")
  expect_series(out, "Backlog", ref[, "B"], tol = 1e-8)
  ## the documented trajectory
  expect_equal(at(out, "Backlog", 20), 12.03, tolerance = 1e-3)
  expect_equal(max(series(out, "Backlog")), 29.5, tolerance = 1e-3)
  expect_equal(at(out, "defect_rate", 20), 0.053, tolerance = 5e-3)
  expect_equal(max(series(out, "defect_rate")), 0.119, tolerance = 1e-3)
  ## the pulse runs from day 20 to day 30 and nowhere else
  expect_equal(at(out, "arrival_rate", 19.9), 10)
  expect_equal(at(out, "arrival_rate", 25), 22)
  expect_equal(at(out, "arrival_rate", 30), 10)
  ## and the backlog is back at its equilibrium by about day 35
  expect_equal(at(out, "Backlog", 35), 12.03, tolerance = 1e-2)
})

test_that("17. the carbon bathtub accumulates a data-driven inflow", {
  out <- sd_example_run("carbon_bathtub")
  em <- tidysd::global_emissions_synthetic
  f <- stats::approxfun(em$time, em$emissions, rule = 2)
  times <- seq(1751, 2011, by = 1)
  ref <- ref_euler(c(C = 0), times, function(t, y) c(C = f(t) - y[["C"]] * 0.01),
                   non_negative = "C")
  expect_series(out, "ExcessAtmosphericCarbon", ref[, "C"], tol = 1e-8)
  ## the driver reaches the model exactly as tabulated
  expect_equal(at(out, "emissions", 1751), em$emissions[1])
  expect_equal(at(out, "emissions", 2011), em$emissions[nrow(em)])
  ## the bathtub point: while emissions grow, removal never catches up
  expect_true(all(diff(series(out, "ExcessAtmosphericCarbon")) > 0))
  expect_lt(at(out, "natural_removal", 2011), at(out, "emission_flow", 2011))
  ## and the series is a parameter, so a counterfactual is a parameter edit
  flat <- data.frame(time = em$time,
                     emissions = pmin(em$emissions, em$emissions[em$time == 1990]))
  ex <- sd_example("carbon_bathtub")
  p2 <- update(ex$parameters, input_series("emissions", data = flat, interp = "linear"))
  out2 <- simulate(ex$structure, ex$equations, p2, spec = ex$spec)
  expect_lt(at(out2, "ExcessAtmosphericCarbon", 2011),
            at(out, "ExcessAtmosphericCarbon", 2011))
})

test_that("18. the Roessler attractor reproduces the RK4 trajectory", {
  out <- sd_example_run("roessler")
  times <- seq(0, 100, by = 0.03125)
  ref <- ref_rk4(c(x = 0.5, y = 0.5, z = 0.4), times, function(t, v)
    c(x = -v[["y"]] - v[["z"]],
      y = v[["x"]] + 0.2 * v[["y"]],
      z = 0.2 + v[["z"]] * (v[["x"]] - 5.7)))
  expect_series(out, "x", ref[, "x"], tol = 1e-8)
  expect_series(out, "y", ref[, "y"], tol = 1e-8)
  expect_series(out, "z", ref[, "z"], tol = 1e-8)
  ## the documented envelope
  expect_equal(range(series(out, "x")), c(-9.1, 11.4), tolerance = 0.01)
  expect_equal(max(series(out, "z")), 22.6, tolerance = 0.01)
  ## flows declared from .source run backwards when they go negative
  expect_lt(min(series(out, "dxdt")), 0)
  expect_lt(min(series(out, "x")), 0)
  ## Euler at the same dt is not accurate enough -- it inflates the z spikes
  ex <- sd_example("roessler")
  eul <- simulate(ex$structure, ex$equations, ex$parameters,
                  spec = sim_spec(start = 0, stop = 100, dt = 0.03125, method = "euler"))
  expect_gt(max(series(eul, "z")), 30)
})

test_that("19. the pendulum conserves energy under RK4 and not under Euler", {
  out <- sd_example_run("pendulum")
  pos <- series(out, "AngularPosition")
  vel <- series(out, "AngularVelocity")
  E <- 0.5 * 10 * 100 * vel^2 + 10 * 9.8 * 10 * (1 - cos(pos))
  expect_lt((max(E) - min(E)) / mean(E), 1e-8)
  ## the measured period, from interpolated zero crossings
  tt <- as.numeric(names(pos))
  zc <- which(diff(sign(pos)) != 0)
  cross <- tt[zc] + pos[zc] / (pos[zc] - pos[zc + 1]) * (tt[zc + 1] - tt[zc])
  expect_equal(2 * mean(diff(cross)), 6.768, tolerance = 1e-3)
  ## longer than the small-angle approximation
  expect_gt(2 * mean(diff(cross)), 2 * pi * sqrt(10 / 9.8))
  ## Euler at the same dt pumps energy in instead
  ex <- sd_example("pendulum")
  eul <- simulate(ex$structure, ex$equations, ex$parameters,
                  spec = sim_spec(start = 0, stop = 100, dt = 0.0078125,
                                  method = "euler", time_unit = "second", saveat = 0.1))
  p2 <- series(eul, "AngularPosition")
  expect_gt(max(p2[as.numeric(names(p2)) > 90]), 1.35)
})

test_that("20. sales agent motivation collapses when the subsidy ends", {
  out <- sd_example_run("sales_agents")
  eff <- stats::approxfun(
    c(0, 0.285132, 0.448065, 0.570265, 0.733198, 0.95723, 1.4664, 3.19756, 4.03259),
    c(0, 0.0616114, 0.232228, 0.492891, 0.772512, 0.862559, 0.914692, 0.952607,
      0.957346), rule = 2)
  times <- seq(0, 200, by = 0.0625)
  mk <- function(subsidy, len) function(t, y) {
    employed <- as.numeric(y[["M"]] > 0.1)
    effort <- 200 * 0.25 * employed * eff(y[["M"]])
    sales <- effort / 4 * 0.2
    income <- (12 / 50) * sales + if (t < len) subsidy else 0
    c(M = (income - y[["M"]]) / 3, Ten = employed, Sales = sales, Inc = income)
  }
  ref <- ref_euler(c(M = 1, Ten = 0, Sales = 0, Inc = 0), times, mk(0.5, 6))
  expect_series(out, "Motivation", ref[, "M"], scenario = "base", tol = 1e-8)
  expect_series(out, "Tenure", ref[, "Ten"], scenario = "base", tol = 1e-8)
  expect_series(out, "TotalCumulativeSales", ref[, "Sales"], scenario = "base", tol = 1e-8)
  ## while the subsidy runs, income sits near 1.02 months-of-expenses per month
  expect_equal(at(out, "income", 5, scenario = "base"), 1.02, tolerance = 0.02)
  ## the moment the subsidy stops, income drops by exactly the subsidy ...
  expect_equal(at(out, "income", 5.9375, scenario = "base") -
                 at(out, "income", 6, scenario = "base"), 0.5, tolerance = 1e-3)
  ## ... and the reversed loop carries it down to about 0.47 within two months
  expect_equal(at(out, "income", 8, scenario = "base"), 0.47, tolerance = 5e-3)
  expect_true(all(diff(series(out, "income", scenario = "base")[100:250]) < 0))
  ## motivation crosses the quitting threshold at month 16.75, after 22.8 sales
  ten <- series(out, "Tenure", scenario = "base")
  expect_equal(unname(max(ten)), 16.75, tolerance = 1e-9)
  expect_equal(at(out, "TotalCumulativeSales", 16.75, scenario = "base"), 22.8,
               tolerance = 1e-3)
  ## a subsidy three times larger buys about three more months
  expect_equal(max(series(out, "Tenure", scenario = "bigger")) -
                 max(series(out, "Tenure", scenario = "base")), 3.125, tolerance = 1e-9)
  ## and the scenarios are ordered as you would expect
  ten_of <- function(s) max(series(out, "Tenure", scenario = s))
  expect_lt(ten_of("base"), ten_of("bigger"))
  expect_lt(ten_of("bigger"), ten_of("longer"))
  expect_lt(ten_of("longer"), ten_of("both"))
})

test_that("21. the capability trap is an equilibrium you can fall out of", {
  out <- sd_example_run("capability_trap")
  wp <- stats::approxfun(c(0, 1, 1.5, 2, 5), c(1, 1, 0.75, 0.25, 0), rule = 2)
  cp <- stats::approxfun(c(0, 0.5, 0.75, 1, 2, 5), c(0, 0, 0.5, 1, 1.5, 1.5), rule = 2)
  wt <- stats::approxfun(c(0, 0.75, 1, 1.25, 2, 10),
                         c(0.75, 0.75, 1, 1.25, 1.5, 1.5), rule = 2)
  times <- seq(0, 100, by = 0.0625)
  mk <- function(pstep, perfstep) function(t, y) {
    improve <- 10 * cp(y[["Pi"]]) * wp(y[["Pw"]])
    working <- min(30 * wt(y[["Pw"]]), 40 - improve)
    actual <- y[["C"]] * working
    desired <- 3000 + (if (t >= 10) perfstep else 0)
    stretch <- desired / actual
    c(C = improve * 0.5 - y[["C"]] / 20,
      Pw = (stretch - y[["Pw"]]) / 3,
      Pi = (stretch - y[["Pi"]]) / 9 + (if (t >= 10) pstep else 0))
  }
  for (s in c("equilibrium", "trap", "escape", "demand")) {
    o <- sd_example("capability_trap")$scenarios[[s]]
    ref <- ref_euler(c(C = 100, Pw = 1, Pi = 1), times,
                     mk(o$pressure_step %||% 0, o$performance_step %||% 0))
    expect_series(out, "Capability", ref[, "C"], scenario = s, tol = 1e-7)
  }
  ## the shipped defaults sit in exact equilibrium
  eq <- series(out, "Capability", scenario = "equilibrium")
  expect_equal(unname(eq), rep(100, length(eq)), tolerance = 1e-9)
  expect_equal(at(out, "stretch", 100, scenario = "equilibrium"), 1, tolerance = 1e-9)
  expect_equal(at(out, "actual_performance", 100, scenario = "equilibrium"), 3000,
               tolerance = 1e-9)
  ## a -0.05 pressure step erodes capability and it never recovers
  expect_equal(at(out, "Capability", 40, scenario = "trap"), 61, tolerance = 0.01)
  expect_equal(at(out, "actual_performance", 40, scenario = "trap"), 2075, tolerance = 0.01)
  expect_equal(at(out, "Capability", 100, scenario = "trap"), 66, tolerance = 0.01)
  expect_equal(at(out, "actual_performance", 100, scenario = "trap"), 2194, tolerance = 0.01)
  ## +0.1 escapes upward
  expect_equal(at(out, "Capability", 100, scenario = "escape"), 137, tolerance = 0.01)
  expect_equal(at(out, "actual_performance", 100, scenario = "escape"), 3518,
               tolerance = 0.01)
})

test_that("22. the boarding-school SIR fits the 1978 outbreak", {
  ex <- sd_example("boarding_school_flu")
  cal <- ex$calibration
  fit <- calibrate(ex$structure, ex$equations, ex$parameters, spec = ex$spec,
                   observed = ex$observed, target = cal$target, free = cal$free,
                   lower = cal$lower, upper = cal$upper)
  expect_s3_class(fit, "sd_calibration")
  expect_identical(fit$fit$convergence, 0L)
  ## Duggan's FME::modFit returns beta ~ 2.18e-3
  expect_equal(unname(fit$fit$estimate[["beta"]]), 2.18e-3, tolerance = 0.02)
  expect_gt(fit$fit$estimate[["infectious_period"]], 1.8)
  expect_lt(fit$fit$estimate[["infectious_period"]], 2.6)

  ## the fit really is a minimum: an independent search does no better
  sse <- function(v) {
    pp <- update(ex$parameters,
                 constant(beta = v[[1]], infectious_period = v[[2]]))
    r <- as.data.frame(simulate(ex$structure, ex$equations, pp, spec = ex$spec))
    r <- r[r$variable == "I", ]
    sum((stats::approxfun(r$time, r$value, rule = 2)(ex$observed$time) -
           ex$observed$sInfected)^2)
  }
  indep <- stats::optim(c(0.0022, 2.2), sse, method = "Nelder-Mead",
                        control = list(parscale = c(1e-3, 1), reltol = 1e-12,
                                       maxit = 2000))
  expect_equal(fit$fit$sse, indep$value, tolerance = 1e-4)

  ## R0 = beta * S(0) * period, in the range reported for this outbreak
  R0 <- fit$fit$estimate[["beta"]] * 762 * fit$fit$estimate[["infectious_period"]]
  expect_gt(R0, 3); expect_lt(R0, 4.5)

  ## the fitted parameters go straight back into simulate(), with the data
  out <- simulate(ex$structure, ex$equations, fit$parameters, spec = ex$spec,
                  observed = ex$observed, map = ex$map)
  expect_true(all(c("model", "observed") %in% unique(out$source)))
  obs <- out[out$source == "observed" & out$variable == "I", ]
  expect_equal(nrow(obs), nrow(ex$observed))
  ## the fitted curve peaks near the observed peak
  m <- out[out$source == "model" & out$variable == "I", ]
  expect_equal(m$time[which.max(m$value)], 6, tolerance = 0.6)
  expect_equal(max(m$value), 298, tolerance = 0.15)
})
