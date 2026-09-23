test_that("sd_sweep() draws n random runs and varies the swept constant", {
  ex <- sd_example("customer_growth")
  set.seed(1)
  out <- sd_sweep(ex$structure, ex$equations, ex$parameters, spec = ex$spec,
                  growth_fraction = c(0.05, 0.11), n = 5)

  one <- simulate(ex$structure, ex$equations, ex$parameters, spec = ex$spec)
  expect_s3_class(out, "sd_result")
  expect_equal(nrow(out), 5L * nrow(one))
  expect_equal(sort(unique(out$.run)), 1:5)
  expect_length(unique(out$growth_fraction), 5L)
  expect_true(all(out$growth_fraction >= 0.05 & out$growth_fraction <= 0.11))
  ## one value per run, constant within the run
  expect_equal(max(tapply(out$growth_fraction, out$.run, function(x) length(unique(x)))), 1L)
})

test_that("sd_sweep(method = 'grid') runs every combination", {
  ex <- sd_example("customer_growth")
  out <- sd_sweep(ex$structure, ex$equations, ex$parameters, spec = ex$spec,
                  growth_fraction = c(0.05, 0.11),
                  decline_fraction = c(0.02, 0.03, 0.04),
                  n = 2, method = "grid")
  expect_equal(length(unique(out$.run)), 6L)
  expect_equal(sort(unique(out$growth_fraction)), c(0.05, 0.11))
  expect_equal(sort(unique(out$decline_fraction)), c(0.02, 0.03, 0.04))
})
