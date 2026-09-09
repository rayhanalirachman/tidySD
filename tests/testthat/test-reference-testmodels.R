## Models 9-15: the PySD conformance corpus.

test_that("9. teacup reproduces the published output", {
  out <- sd_example_run("teacup")
  times <- seq(0, 30, by = 0.125)
  ref <- ref_euler(c(T = 180), times, function(t, y)
    c(T = -(y[["T"]] - 70) / 10))
  expect_series(out, "TeacupTemperature", ref[, "T"])
  ## Vensim's output.csv: 110.212 at minute 10, 75.374 at minute 30
  expect_equal(at(out, "TeacupTemperature", 10), 110.212, tolerance = 1e-4)
  expect_equal(at(out, "TeacupTemperature", 30), 75.374, tolerance = 1e-4)
  ## one 1/e of the remaining gap per characteristic time
  gap <- series(out, "TeacupTemperature") - 70
  expect_equal(unname(gap[["10"]] / gap[["0"]]), exp(-1), tolerance = 0.01)
})

test_that("10. Lotka-Volterra matches, and Euler inflates the orbit as documented", {
  out <- sd_example_run("lotka_volterra")
  times <- seq(0, 50, by = 0.0625)
  ref <- ref_euler(c(Prey = 1000, Pred = 20), times, function(t, y) {
    fpr <- 0.2 * y[["Pred"]] / 20
    prr <- 1 * y[["Prey"]] / 1000
    c(Prey = y[["Prey"]] * 3 - y[["Prey"]] * fpr,
      Pred = y[["Pred"]] * prr - y[["Pred"]] / 10)
  }, non_negative = c("Prey", "Pred"))
  expect_series(out, "Prey", ref[, "Prey"])
  expect_series(out, "Predators", ref[, "Pred"])
  ## MODELS.md: Euler at this dt inflates the peak to about 7,670 hares
  expect_equal(max(series(out, "Prey")), 7670, tolerance = 0.01)
  ## and drives prey to numerical zero
  expect_lt(min(series(out, "Prey")), 1e-20)
  ## the fixed point: 100 hares / 300 foxes
  expect_equal(3 / (0.2 / 20), 300)     # predators where prey growth is balanced
  expect_equal((1 / 10) / (1 / 1000), 100)
})

test_that("11. the town population aging chain is an eighth-order delay", {
  out <- sd_example_run("town_population")
  tp <- tidysd::town_population
  lifespan <- 70; birthrate <- 0.1; n <- 8
  tau <- lifespan / n
  times <- 0:20
  ## Population plus the eight delay stages, for one town at a time.
  ref_town <- function(p0) {
    y0 <- c(P = p0, stats::setNames(rep((p0 / lifespan) * tau, n), paste0("L", seq_len(n))))
    ref_euler(y0, times, function(t, y) {
      births <- birthrate * y[["P"]]
      lev <- y[paste0("L", seq_len(n))]
      outf <- lev / tau
      d_lev <- c(births, outf[-n]) - outf
      c(P = births - outf[[n]], stats::setNames(d_lev, paste0("L", seq_len(n))))
    })
  }
  for (town in c("Town001", "Town050", "Town351")) {
    r <- ref_town(tp[[town]])
    expect_series(out, "Population", r[, "P"], member = town, tol = 1e-8)
    expect_series(out, "deaths", r[, "L8"] / tau, member = town, tol = 1e-8)
  }
  ## delayN(initial = ) sets the delay's *output* at t = 0, so the chain starts
  ## with deaths at Population/lifespan -- the same third argument DELAY N takes
  expect_equal(at(out, "deaths", 0, member = "Town001"),
               tp[["Town001"]] / lifespan, tolerance = 1e-9)
  ## births outrun it from the first step, which is why every town grows
  expect_gt(at(out, "births", 0, member = "Town001"),
            at(out, "deaths", 0, member = "Town001"))
  ## with a 0.1/month birthrate against a 70-month lifespan every town grows
  d <- as.data.frame(out)
  tot <- function(tt) sum(d$value[d$variable == "Population" & d$time == tt])
  expect_equal(tot(0), sum(tp))
  expect_gt(tot(20) / tot(0), 5)
  ## 351 members, all present, all growing
  expect_equal(length(unique(d$town[d$variable == "Population"])), 351L)
})

test_that("12. SMOOTH reproduces every order, and the order is fixed at init", {
  out <- sd_example_run("smooth")
  times <- seq(0, 20, by = 0.25)
  inp <- function(t) -1 + if (t >= 5) 5 else 0
  adj <- function(t) 2 + if (t >= 10) 2 else 0
  cascade <- function(init, n) {
    y0 <- stats::setNames(rep(init, n), paste0("L", seq_len(n)))
    ref_euler(y0, times, function(t, y) {
      tau <- adj(t) / n
      inflow <- c(inp(t), y[-n])
      stats::setNames((inflow - y) / tau, names(y))
    })[, n]
  }
  expect_series(out, "smooth_1",  cascade(inp(0), 1))
  expect_series(out, "smooth_1i", cascade(5, 1))
  expect_series(out, "smooth_3",  cascade(inp(0), 3))
  expect_series(out, "smooth_3i", cascade(5, 3))
  ## `order = 2 + step(1, 10)` is read once, so smooth_n stays second-order
  expect_series(out, "smooth_n",  cascade(5, 2))
  expect_false(isTRUE(all.equal(unname(series(out, "smooth_n")), unname(cascade(5, 3)))))
  ## Vensim's output.tab at month 10
  expect_equal(at(out, "smooth_1", 10), 3.65396, tolerance = 1e-5)
  expect_equal(at(out, "smooth_3", 10), 3.96633, tolerance = 1e-5)
  expect_equal(at(out, "smooth_n", 10), 3.8793, tolerance = 1e-4)
  ## an aux-only model: no stocks were declared
  expect_length(struct_names(sd_example("smooth")$structure, "stock"), 0L)
})

test_that("13. FORECAST extrapolates the trend and overshoots the turn", {
  out <- sd_example_run("forecast")
  dt <- 0.5; times <- seq(0, 120, by = dt)
  Rf <- function(t) {
    10 + 1 * min(max(t - 10, 0), 50) +
      (if (t >= 70) 1 else 0) * (1 - (if (t >= 90) 1 else 0)) +
      (if (t >= 100) 2 * sin(6.28 * t / 20) else 0)
  }
  ## hand-rolled pipeline delay + first-order smooth, on the same outer grid
  n <- length(times)
  buf <- numeric(0); Rd <- numeric(n); S <- numeric(n); Fc <- numeric(n)
  nsteps <- max(1L, floor(10 / dt + 0.5))
  s <- NA_real_
  for (i in seq_len(n)) {
    t <- times[i]
    r <- Rf(t)
    Rd[i] <- if (i - nsteps < 1L) Rf(0) else buf[i - nsteps]
    if (i == 1L) s <- Rd[i]
    S[i] <- s
    Fc[i] <- Rd[i] * (1 + 10 * (Rd[i] - s) / (s * 5))
    buf[i] <- r
    s <- s + dt * (Rd[i] - s) / 5
  }
  keep <- which(abs(times - round(times)) < 1e-9)   # SAVEPER = 1
  expect_series(out, "R_delayed", Rd[keep], tol = 1e-9)
  expect_series(out, "R_forecast", Fc[keep], tol = 1e-9)
  ## Vensim's output.tab
  expect_equal(at(out, "R_delayed", 80), 61, tolerance = 1e-6)
  expect_equal(at(out, "R_forecast", 80), 64.3028, tolerance = 1e-4)
  expect_equal(at(out, "R_delayed", 120), 60.035, tolerance = 1e-4)
  expect_equal(at(out, "R_forecast", 120), 57.911, tolerance = 1e-4)
  ## it overshoots on the way up and undershoots after the turn
  expect_gt(at(out, "R_forecast", 80), at(out, "R_delayed", 80))
  expect_lt(at(out, "R_forecast", 120), at(out, "R_delayed", 120))
})

test_that("14. the fixed delay translates the input exactly in time", {
  out <- sd_example_run("delay_fixed")
  ## DELAY FIXED(Time^2, 2, -3) at month 6 is (6-2)^2 = 16
  expect_equal(at(out, "DF2", 6), 16)
  expect_equal(at(out, "DF1", 6), 25)
  ## delay times round to the nearest whole step: 1.5 -> 2, 1.2 -> 1, 3.7 -> 4
  expect_equal(at(out, "DF15", 6), (6 - 2)^2)
  expect_equal(at(out, "DF12", 6), (6 - 1)^2)
  expect_equal(at(out, "DF37", 6), (6 - 4)^2)
  ## before the delay has elapsed the initial value comes out
  expect_equal(at(out, "DF2", 0), -3)
  expect_equal(at(out, "DF2", 1), -3)
  expect_equal(at(out, "DF37", 3), 4)
  expect_equal(at(out, "DF37", 4), 0)
  ## a variable delay time
  for (tt in c(6, 10, 20, 30)) {
    n <- max(1, floor(tt / 2 / 1 + 0.5))
    expect_equal(at(out, "DT2", tt), (tt - n)^2)
  }
  ## the whole series, against a hand-rolled queue
  times <- 0:50
  q <- function(delay_at, init) {
    v <- numeric(length(times)); buf <- numeric(0)
    for (i in seq_along(times)) {
      n <- max(1L, floor(delay_at(times[i]) + 0.5))
      v[i] <- if (i - n < 1L) init else buf[i - n]
      buf[i] <- times[i]^2
    }
    v
  }
  expect_series(out, "DF05", q(function(t) 0.5, -10))
  expect_series(out, "DST", q(function(t) 2 + 2 * sin(t), 7))
})

test_that("15. workforce and backlog oscillates as the capacity chain fills", {
  out <- sd_example_run("workforce")
  hire <- stats::approxfun(c(-1, -0.25, 0, 0.5, 1, 2, 3),
                           c(0, 0, 2.5, 15, 20, 25, 25), rule = 2)
  times <- seq(0, 150, by = 0.03125)
  ref <- ref_euler(c(Rk = 5, Ex = 50, B = 500), times, function(t, y) {
    eh <- y[["Ex"]] * 40 - 20 * y[["Rk"]]
    rh <- y[["Rk"]] * 40
    completion <- min(eh / 10 + rh / 30, y[["B"]])
    pressure <- (y[["B"]] - 500) / 500
    c(Rk = hire(pressure) - y[["Rk"]] / 15,
      Ex = y[["Rk"]] / 15 - y[["Ex"]] / 35,
      B = 230 - completion)
  }, non_negative = c("Rk", "Ex", "B"))
  expect_series(out, "Rookies", ref[, "Rk"], tol = 1e-7)
  expect_series(out, "Experts", ref[, "Ex"], tol = 1e-7)
  expect_series(out, "TaskBacklog", ref[, "B"], tol = 1e-7)
  ## the documented trajectory
  b <- series(out, "TaskBacklog"); tb <- as.numeric(names(b))
  early <- b[tb < 40]
  expect_equal(unname(max(early)), 1082, tolerance = 1e-3)
  expect_equal(as.numeric(names(early)[which.max(early)]), 13, tolerance = 0.05)
  expect_equal(at(out, "Experts", 25), 166, tolerance = 1e-3)
  late <- b[tb > 60]
  expect_equal(unname(max(late)), 1273, tolerance = 1e-3)
  expect_equal(as.numeric(names(late)[which.max(late)]), 112, tolerance = 0.01)
})
