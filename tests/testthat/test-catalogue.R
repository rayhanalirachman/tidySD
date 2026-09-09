test_that("every catalogue model binds, runs and produces finite output", {
  ids <- sd_example_ids()
  expect_gte(nrow(ids), 22L)
  for (i in seq_len(nrow(ids))) {
    nm <- ids$name[[i]]
    ex <- sd_example(nm)
    expect_s3_class(ex, "sd_example")
    expect_s3_class(ex$structure, "sd_structure")
    expect_s3_class(ex$equations, "sd_equations")
    expect_s3_class(ex$parameters, "sd_parameters")
    expect_s3_class(ex$spec, "sim_spec")

    ## binding on its own must succeed, with no warnings (units included)
    expect_no_warning(sd_validate(ex$structure, ex$equations, ex$parameters, ex$spec))

    out <- sd_example_run(nm)
    expect_s3_class(out, "sd_result")
    expect_gt(nrow(out), 0L)
    vals <- if ("source" %in% names(out)) out$value[out$source == "model"] else out$value
    expect_true(all(is.finite(vals)), info = nm)
    ## every declared stock, flow, aux and input is reported
    declared <- c(struct_names(ex$structure, "stock"),
                  struct_names(ex$structure, "flow"),
                  struct_names(ex$structure, "aux"),
                  struct_names(ex$structure, "input"))
    expect_setequal(unique(out$variable[out$type != "observed"]), declared)
    ## the time grid spans the spec
    expect_equal(min(out$time), ex$spec$start)
    expect_lte(max(out$time), ex$spec$stop + 1e-9)
    ## no internal delay/smooth machinery leaks out
    expect_false(any(startsWith(out$variable, ".")), info = nm)
  }
})

test_that("sd_example accepts a number or a name, and rejects anything else", {
  expect_equal(sd_example(5)$name, "sir")
  expect_equal(sd_example("sir")$number, 5L)
  expect_error(sd_example(0), "between 1 and")
  expect_error(sd_example(99), "between 1 and")
  expect_error(sd_example("nope"), "one of")
  expect_output(print(sd_example("sir")), "sd_example")
})

test_that("the catalogue covers the grammar it claims to", {
  uses <- function(nm, fn) {
    ex <- sd_example(nm)
    any(vapply(ex$equations$eqns, function(e) expr_has_call(e$rhs, fn), logical(1)))
  }
  expect_true(uses("material_delay", "step"))
  expect_true(uses("defects", "pulse"))
  expect_true(uses("forecast", "ramp"))
  expect_true(uses("forecast", "forecast"))
  expect_true(uses("forecast", "delay_fixed"))
  expect_true(uses("delay_fixed", "delay_fixed"))
  expect_true(uses("smooth", "smoothN"))
  expect_true(uses("town_population", "delayN"))
  expect_true(uses("overshoot", "min"))
  expect_true(uses("sales_agents", "ifelse"))
  expect_true(uses("cohort_sir", "%*%"))
  expect_true(uses("cohort_sir", "sum"))
  expect_true(uses("solow", "sqrt"))
  expect_true(uses("pendulum", "sin"))
  ## subscripts, lookups, inputs, scenarios, integrator choice
  expect_length(sd_example("cohort_sir")$structure$dims, 1L)
  expect_length(sd_example("town_population")$structure$dims$town, 351L)
  expect_length(struct_names(sd_example("capability_trap")$structure, "lookup"), 3L)
  expect_length(struct_names(sd_example("carbon_bathtub")$structure, "input"), 1L)
  expect_length(sd_example("overshoot")$scenarios, 5L)
  expect_length(sd_example("sales_agents")$scenarios, 4L)
  expect_equal(sd_example("roessler")$spec$method, "rk4")
  expect_equal(sd_example("pendulum")$spec$method, "rk4")
  expect_false(is.null(sd_example("boarding_school_flu")$observed))
})

test_that("every model in the catalogue is reproducible run to run", {
  for (nm in c("sir", "overshoot", "cohort_sir", "forecast", "capability_trap")) {
    a <- sd_example_run(nm); b <- sd_example_run(nm)
    expect_equal(as.data.frame(a), as.data.frame(b), info = nm)
  }
})
