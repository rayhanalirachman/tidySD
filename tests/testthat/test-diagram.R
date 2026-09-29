sir <- function() list(
  st = sd_structure(
    meta(name = "SIR"),
    stock("S"), stock("I"), stock("R"), aux("lambda"),
    flow("infection", from = "S", to = "I"),
    flow("recovery", from = "I", to = "R")),
  eq = sd_equations(lambda ~ beta * I / (S + I + R),
                    infection ~ lambda * S,
                    recovery ~ I / dur),
  pa = sd_parameters(constant(beta = 0.5, dur = 5), initial(S = 999, I = 1, R = 0)))

test_that("sfd and cld build, and the cld links flows to their stocks", {
  m <- sir()
  sfd <- sd_diagram(m$st, m$eq, m$pa, type = "sfd")
  expect_true(any(sfd$edges$kind == "outflow"))
  expect_equal(nrow(sd_diagram(m$st)$edges), 4L)   # structure-only wiring

  e <- sd_diagram(m$st, m$eq, m$pa, type = "cld")$edges
  has <- function(f, t, s) any(e$from == f & e$to == t & e$sign == s)
  expect_true(has("infection", "I", "+"))
  expect_true(has("infection", "S", "-"))
  expect_true(has("recovery", "R", "+"))
  expect_true(has("recovery", "I", "-"))
})

test_that("autoplot returns a ggplot for every theme", {
  m <- sir()
  for (type in c("sfd", "cld")) for (th in c("soft", "oi", "plain")) {
    p <- autoplot(sd_diagram(m$st, m$eq, m$pa, type = type), theme = th,
                  initials = m$pa$initials)
    expect_s3_class(p, "ggplot")
    expect_silent(ggplot2::ggplot_build(p))
  }
})

test_that("the SIR cld finds the infection loop through I, lambda and infection", {
  m <- sir()
  loop_through <- function(eq) {
    lp <- attr(autoplot(sd_diagram(m$st, eq, m$pa, type = "cld")), "loops")
    lp[vapply(strsplit(lp$path, " -> "), function(v)
      setequal(v, c("I", "lambda", "infection")), TRUE), ]
  }
  ## I sits in both numerator and denominator of beta * I / (S + I + R), so the
  ## syntactic sign read cannot call the I -> lambda link, nor the loop
  expect_equal(loop_through(m$eq)$polarity, "unknown")
  ## with an unambiguous force of infection the loop is reinforcing
  r <- loop_through(update(m$eq, lambda ~ beta * I / N))
  expect_equal(r$polarity, "reinforcing")
  expect_match(r$label, "^R")
})

test_that("every catalogue model draws in both types", {
  for (id in sd_example_ids()$name) {
    ex <- sd_example(id)
    for (type in c("sfd", "cld")) {
      p <- autoplot(sd_diagram(ex$structure, ex$equations, ex$parameters, type = type))
      expect_s3_class(p, "ggplot")
      expect_no_error(ggplot2::ggplot_build(p))
    }
  }
})

test_that("save_diagram writes a png", {
  m <- sir()
  f <- save_diagram(autoplot(sd_diagram(m$st, m$eq, m$pa)), tempfile(fileext = ".png"))
  expect_true(file.exists(f))
})
