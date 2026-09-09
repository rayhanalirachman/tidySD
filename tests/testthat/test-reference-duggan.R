## Models 1-8: Duggan's SDMR deSolve models, re-integrated by hand.

test_that("1. customer growth matches the deSolve model", {
  out <- sd_example_run("customer_growth")
  times <- seq(2015, 2030, by = 0.25)
  ref <- ref_euler(c(C = 10000), times, function(t, y)
    c(C = y[["C"]] * 0.08 - y[["C"]] * 0.03), non_negative = "C")
  expect_series(out, "Customers", ref[, "C"])
  expect_series(out, "recruits", ref[, "C"] * 0.08)
  expect_series(out, "losses", ref[, "C"] * 0.03)
})

test_that("1b. the piecewise-in-time growth fraction variant tracks its steps", {
  out <- sd_example_run("customer_growth_piecewise")
  times <- seq(2015, 2030, by = 0.25)
  gf <- function(t) if (t < 2020) 0.07 else if (t < 2025) 0.03 else 0.02
  ref <- ref_euler(c(C = 10000), times, function(t, y)
    c(C = y[["C"]] * gf(t) - y[["C"]] * 0.03), non_negative = "C")
  expect_series(out, "Customers", ref[, "C"])
  expect_equal(at(out, "growth_fraction", 2019), 0.07)
  expect_equal(at(out, "growth_fraction", 2022), 0.03)
  expect_equal(at(out, "growth_fraction", 2027), 0.02)
})

test_that("2. S-shaped growth matches, and saturates below capacity", {
  out <- sd_example_run("s_shaped_growth")
  times <- seq(0, 100, by = 0.25)
  ref <- ref_euler(c(S = 100), times, function(t, y) {
    avail <- 1 - y[["S"]] / 10000
    c(S = y[["S"]] * (0.10 * (avail / 1)))
  }, non_negative = "S")
  expect_series(out, "Stock", ref[, "S"])
  expect_lt(max(ref[, "S"]), 10000)
  expect_gt(at(out, "Stock", 100), 9900)
  ## logistic: the growth rate peaks at half capacity
  nf <- series(out, "net_flow")
  st <- series(out, "Stock")
  expect_equal(unname(st[which.max(nf)]), 5000, tolerance = 0.02)
})

test_that("3. overshoot and collapse matches, over every scenario", {
  ex <- sd_example("overshoot")
  out <- sd_example_run("overshoot")
  eff <- stats::approxfun(seq(0, 1000, by = 100),
                          c(0, 0.25, 0.45, 0.63, 0.75, 0.85, 0.92, 0.96, 0.98, 0.99, 1),
                          method = "linear", rule = 2)
  times <- seq(0, 200, by = 0.125)
  mk <- function(fr, dg) function(t, y) {
    extraction <- eff(y[["R"]]) * y[["K"]]
    profit <- 3 * extraction - y[["K"]] * 0.10
    invest <- min(fr * profit / 2.0, y[["K"]] * dg)
    c(K = invest - y[["K"]] * 0.05, R = -extraction)
  }
  for (s in names(ex$scenarios)) {
    o <- ex$scenarios[[s]]
    ref <- ref_euler(c(K = 5, R = 1000), times,
                     mk(o$fraction_reinvested %||% 0.12, o$desired_growth %||% 0.07),
                     non_negative = c("K", "R"))
    expect_series(out, "Capital", ref[, "K"], scenario = s)
    expect_series(out, "Resource", ref[, "R"], scenario = s)
  }
  ## the qualitative point of the model
  cap <- series(out, "Capital", scenario = "base")
  expect_gt(max(cap), 5 * 4)
  expect_lt(cap[[length(cap)]], 1)
})

test_that("4. Solow converges on its analytic steady state", {
  out <- sd_example_run("solow")
  times <- seq(0, 100, by = 0.25)
  ref <- ref_euler(c(M = 100), times, function(t, y)
    c(M = 100 * sqrt(y[["M"]]) * 0.20 - y[["M"]] * 0.1), non_negative = "M")
  expect_series(out, "Machines", ref[, "M"])
  ## investment = depreciation  =>  0.2*100*sqrt(M) = 0.1*M  =>  M = 40000
  expect_equal(at(out, "Machines", 100), 40000, tolerance = 0.02)
  expect_equal(at(out, "investment", 100), at(out, "discards", 100), tolerance = 0.01)
})

test_that("5. SIR matches, and conserves the population", {
  out <- sd_example_run("sir")
  times <- seq(0, 100, by = 0.125)
  ref <- ref_euler(c(S = 999, I = 1, R = 0), times, function(t, y) {
    lambda <- (6 * 0.20 / 1000) * y[["I"]]
    ir <- y[["S"]] * lambda
    rr <- y[["I"]] / 5
    c(S = -ir, I = ir - rr, R = rr)
  }, non_negative = c("S", "I", "R"))
  expect_series(out, "S", ref[, "S"])
  expect_series(out, "I", ref[, "I"])
  expect_series(out, "R", ref[, "R"])
  total <- series(out, "S") + series(out, "I") + series(out, "R")
  expect_equal(unname(total), rep(1000, length(total)), tolerance = 1e-9)
})

test_that("5b. the density-dependent form swap touches only the equation layer", {
  ex <- sd_example("sir")
  dd <- update(ex$equations, lambda ~ contact_rate * infectivity * I)
  out <- simulate(ex$structure, dd, ex$parameters, spec = ex$spec)
  ## same structure, same parameters, a much faster epidemic
  expect_lt(series(out, "S")[[length(series(out, "S"))]], 1)
  expect_identical(length(ex$equations$eqns), length(dd$eqns))
  ## the original object is untouched
  expect_equal(deparse1(ex$equations$eqns$lambda$rhs), "beta * I")
})

test_that("6. Bass diffusion matches, and the adoption rate is bell-shaped", {
  out <- sd_example_run("bass")
  times <- seq(0, 20, by = 0.01)
  ref <- ref_euler(c(P = 99999, A = 1), times, function(t, y) {
    ar <- y[["P"]] * ((6 * 0.25 / 1e5) * y[["A"]])
    c(P = -ar, A = ar)
  }, non_negative = c("P", "A"))
  keep <- which(abs(times / 0.25 - round(times / 0.25)) < 1e-8)
  expect_series(out, "Adopters", ref[keep, "A"], tol = 1e-7)
  ar <- series(out, "adoption_rate")
  pk <- which.max(ar)
  expect_gt(pk, 1); expect_lt(pk, length(ar))
  expect_equal(unname(series(out, "Adopters")[pk]), 50000, tolerance = 0.02)
})

test_that("6b. the full Bass form adds an innovation coefficient", {
  ex <- sd_example("bass")
  eq <- update(ex$equations,
               adoption_rate ~ PotentialAdopters * (rho + innovation))
  pr <- update(ex$parameters, constant(innovation = 0.01))
  out <- simulate(ex$structure, eq, pr, spec = ex$spec)
  base <- sd_example_run("bass")
  ## innovation makes early adoption faster
  expect_gt(at(out, "Adopters", 2), at(base, "Adopters", 2))
  ## and the un-augmented parameters no longer suffice
  expect_error(simulate(ex$structure, eq, ex$parameters, spec = ex$spec), "innovation")
})

test_that("7. cohort SIR matches the matrix-vector reference", {
  ## the exact comparison runs over the epidemic itself; the shipped spec keeps
  ## Duggan's 20,000-day horizon, which is checked separately below
  out <- sd_example_run("cohort_sir",
                        spec = sim_spec(0, 200, 0.125, "euler", time_unit = "day"))
  CE <- matrix(c(3, 2, 1, 2, 2, 1, 1, 1, 0.5), nrow = 3, byrow = TRUE)
  pop <- c(25000, 50000, 25000)
  beta <- CE / pop
  times <- seq(0, 200, by = 0.125)
  y0 <- c(S1 = 24999, S2 = 50000, S3 = 25000, I1 = 1, I2 = 0, I3 = 0,
          R1 = 0, R2 = 0, R3 = 0)
  ref <- ref_euler(y0, times, function(t, y) {
    S <- y[1:3]; I <- y[4:6]
    lambda <- as.vector(beta %*% I)
    ir <- lambda * S
    rr <- I / 2
    stats::setNames(c(-ir, ir - rr, rr), names(y))
  }, non_negative = names(y0))
  for (i in seq_along(c("young", "adult", "elderly"))) {
    m <- c("young", "adult", "elderly")[i]
    expect_series(out, "S", ref[, paste0("S", i)], member = m)
    expect_series(out, "I", ref[, paste0("I", i)], member = m)
    expect_series(out, "R", ref[, paste0("R", i)], member = m)
  }
  ti <- series(out, "total_infected")
  expect_equal(unname(ti), unname(rowSums(ref[, 4:6])), tolerance = 1e-8)
  ## the reduction is a scalar, so its subscript column is NA
  d <- as.data.frame(out)
  expect_true(all(is.na(d$cohort[d$variable == "total_infected"])))
  expect_false(any(is.na(d$cohort[d$variable == "I"])))

  ## over the shipped 20,000-day horizon the epidemic burns out and the
  ## population is conserved cohort by cohort
  full <- sd_example_run("cohort_sir")
  expect_equal(max(full$time), 20000)
  expect_lt(at(full, "total_infected", 20000), 1e-6)
  for (i in seq_along(c("young", "adult", "elderly"))) {
    m <- c("young", "adult", "elderly")[i]
    tot <- series(full, "S", member = m) + series(full, "I", member = m) +
      series(full, "R", member = m)
    expect_equal(unname(tot), rep(c(25000, 50000, 25000)[i], length(tot)),
                 tolerance = 1e-9)
  }
  ## three coupled waves, all cresting around day 4, sized by cohort population
  pk <- vapply(c("young", "adult", "elderly"), function(m) {
    s <- series(full, "I", member = m)
    as.numeric(names(s)[which.max(s)])
  }, numeric(1))
  expect_true(all(pk >= 3 & pk <= 6))
  size <- vapply(c("young", "adult", "elderly"),
                 function(m) max(series(full, "I", member = m)), numeric(1))
  expect_gt(size[["adult"]], size[["young"]])
  expect_gt(size[["elderly"]], 1e4)
})

test_that("8. the first-order material delay lags the step and re-equilibrates", {
  out <- sd_example_run("material_delay")
  times <- seq(0, 25, by = 0.125)
  ref <- ref_euler(c(M = 400), times, function(t, y) {
    inflow <- 100 + if (t >= 4) 100 else 0
    c(M = inflow - y[["M"]] / 4)
  }, non_negative = "M")
  expect_series(out, "Material", ref[, "M"])
  expect_equal(at(out, "Material", 0), 400)       # starts in equilibrium
  expect_equal(at(out, "Material", 3.875), 400)   # nothing happens before the step
  expect_equal(at(out, "Material", 25), 800, tolerance = 0.01)  # new equilibrium
  ## the outflow lags the inflow
  expect_lt(at(out, "outflow", 6), at(out, "inflow", 6))
})
