test_that("autoplot builds a plot for a plain, a scenario and an observed result", {
  skip_if_not_installed("ggplot2")
  p <- autoplot(sd_example_run("sir"))
  expect_s3_class(p, "ggplot")
  expect_silent(ggplot2::ggplot_build(p))

  ps <- autoplot(sd_example_run("overshoot"), vars = c("Capital", "Resource"))
  expect_s3_class(ps, "ggplot")
  expect_silent(ggplot2::ggplot_build(ps))

  ex <- sd_example("boarding_school_flu")
  out <- simulate(ex$structure, ex$equations, ex$parameters, spec = ex$spec,
                  observed = ex$observed, map = ex$map)
  po <- autoplot(out, vars = "I")
  expect_s3_class(po, "ggplot")
  expect_silent(ggplot2::ggplot_build(po))
})

test_that("autoplot draws a phase portrait when given x and y", {
  skip_if_not_installed("ggplot2")
  p <- autoplot(sd_example_run("roessler"), x = "x", y = "y")
  expect_s3_class(p, "ggplot")
  b <- ggplot2::ggplot_build(p)
  expect_gt(nrow(b$data[[1]]), 100)
  expect_error(autoplot(sd_example_run("sir"), x = "S", y = "nope"),
               "not in the result")
})

test_that("a subscripted result facets and colours by its dimension", {
  skip_if_not_installed("ggplot2")
  p <- autoplot(sd_example_run("cohort_sir"), vars = "I") +
    ggplot2::facet_wrap(~cohort)
  expect_s3_class(p, "ggplot")
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("diagrams are functions of the model", {
  ex <- sd_example("sir")
  sfd <- sd_diagram(ex$structure, ex$equations, ex$parameters, type = "sfd")
  expect_s3_class(sfd, "sd_diagram")
  ## the wiring is read out of the structure, not drawn
  e <- sfd$edges
  expect_true(any(e$from == "S" & e$to == "IR" & e$kind == "outflow"))
  expect_true(any(e$from == "IR" & e$to == "I" & e$kind == "inflow"))
  ## and the information links out of the equations
  expect_true(any(e$from == "I" & e$to == "lambda" & e$kind == "information"))
  expect_true(any(e$from == "recovery_time" & e$to == "RR" & e$sign == "-"))
  expect_true(any(e$from == "lambda" & e$to == "IR" & e$sign == "+"))

  cld <- sd_diagram(ex$structure, ex$equations, ex$parameters, type = "cld")
  expect_true(all(cld$edges$kind == "information"))
  expect_output(print(cld), "sd_diagram")

  skip_if_not_installed("ggplot2")
  p <- autoplot(sfd)
  expect_s3_class(p, "ggplot")
  expect_silent(ggplot2::ggplot_build(p))
})
