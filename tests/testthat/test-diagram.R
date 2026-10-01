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
  for (type in c("sfd", "cld")) for (th in c("black", "soft", "oi", "plain")) {
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

test_that("diagrams are transparent unless given a background", {
  m <- sir()
  d <- sd_diagram(m$st, m$eq, m$pa)
  p <- autoplot(d)
  expect_equal(attr(p, "bg"), "transparent")
  expect_true(is.na(ggplot2::calc_element("plot.background", ggplot2::theme_get() + p$theme)$fill))
  expect_equal(attr(autoplot(d, background = "white"), "bg"), "white")
  f <- save_diagram(p, tempfile(fileext = ".png"))
  expect_true(file.exists(f))
})

test_that("no title by default; title = TRUE and legend = FALSE are honoured", {
  m <- sir()
  d <- sd_diagram(m$st, m$eq, m$pa)
  labs_of <- function(p) unlist(lapply(p$layers, function(l) l$aes_params$label))
  expect_false("SIR" %in% labs_of(autoplot(d)))
  expect_true("SIR" %in% labs_of(autoplot(d, title = TRUE)))
  expect_false("Influence" %in% labs_of(autoplot(d, legend = FALSE)))
  expect_null(autoplot(d, theme = "plain")$labels$title)
})

test_that("influence links never run through another node", {
  for (id in c("sales_agents", "lotka_volterra", "capability_trap", "workforce")) {
    ex <- sd_example(id)
    q <- layout_quality(autoplot(sd_diagram(ex$structure, ex$equations, ex$parameters)))
    expect_equal(q[["node"]], 0, label = id)
  }
})

test_that("stock labels wrap at CamelCase and underscores", {
  expect_equal(wrap_label("TotalCumulativeSales", 16), "TotalCumulative\nSales")
  expect_equal(wrap_label("months_of_expenses_per_sale"), "months of\nexpenses per\nsale")
})

test_that("black is the default theme, and colors= overrides roles", {
  expect_equal(eval(formals(autoplot.sd_diagram)$theme)[1], "black")
  m <- sir()
  d <- sd_diagram(m$st, m$eq, m$pa)
  cols <- function(p) unlist(lapply(p$layers, function(l) l$aes_params$colour))
  expect_false("#FF0000" %in% cols(autoplot(d)))
  expect_true("#FF0000" %in% cols(autoplot(d, colors = list(link = "#FF0000"))))
  expect_s3_class(autoplot(d, theme = "soft", colors = list(stock_fill = "#FFF4D6")), "ggplot")
  expect_error(autoplot(d, colors = list(not_a_role = "red")), "Unknown colour role")
  expect_error(autoplot(d, colors = list("red")), "named list")
})

test_that("a plot built with no device open prints on pdf() and png() without warnings", {
  m <- sir()
  d <- sd_diagram(m$st, m$eq, m$pa, type = "cld")
  rlang::local_options(device = grDevices::pdf)   # a default that is not ragg-capable
  while (grDevices::dev.cur() > 1L) grDevices::dev.off()
  p <- autoplot(d)
  expect_false(attr(p, "ragg_fonts"))
  for (open in list(grDevices::pdf, grDevices::png)) {
    f <- tempfile()
    open(f)
    expect_no_warning(print(p))
    grDevices::dev.off()
  }
  # save_diagram() still redraws with the full fonts
  skip_if_not_installed("ragg")
  expect_true(file.exists(save_diagram(p, tempfile(fileext = ".png"))))
})

test_that("sd_diagram() rejects the wrong kind of input", {
  m <- sir()
  ex <- list(structure = m$st, equations = m$eq, parameters = m$pa)
  expect_error(sd_diagram(ex), "must be an `sd_structure\\(\\)`", class = "tidysd_error")
  expect_error(sd_diagram(sd_structure()), "no variables", class = "tidysd_error")
  expect_error(sd_diagram(m$st, m$pa), "`equations` must be", class = "tidysd_error")
  expect_error(sd_diagram(m$st, m$eq, m$eq), "`parameters` must be", class = "tidysd_error")
})

test_that("colors= values are checked", {
  d <- sd_diagram(sir()$st)
  for (v in list("notacolor", 3, NA, c("red", "blue")))
    expect_error(autoplot(d, colors = list(stock_fill = v)), "colors\\$stock_fill", class = "tidysd_error")
  expect_error(autoplot(d, colors = list(stock_lw = "thick")), "colors\\$stock_lw", class = "tidysd_error")
  expect_s3_class(autoplot(d, colors = list(stock_fill = "grey90", stock_lw = 1)), "ggplot")
})

test_that("save_diagram() writes PNG only", {
  p <- autoplot(sd_diagram(sir()$st))
  expect_error(save_diagram(p, tempfile(fileext = ".pdf")), "PNG only", class = "tidysd_error")
  expect_true(file.exists(save_diagram(p, tempfile(fileext = ".PNG"))))
})

test_that("large diagrams warn that text may be small", {
  rlang::local_options(rlib_warning_verbosity = "verbose")
  st <- do.call(sd_structure, lapply(paste0("a", 1:35), aux))
  d <- sd_diagram(st, type = "cld")
  expect_warning(autoplot(d, theme = "plain"), "Large diagram \\(35 variables\\)")
  expect_no_warning(autoplot(sd_diagram(sir()$st), theme = "plain"))
})

test_that("layout repair moves a variable to remove a link crossing", {
  m <- sd_structure(stock("K"), stock("L"), flow("pop.growth", to = "L"), flow("investment", to = "K"),
                    flow("depreciation", from = "K"), aux("Y"))
  eq <- sd_equations(Y ~ K^alpha * L^beta, investment ~ s*Y, depreciation ~ delta*K, pop.growth ~ n*L)
  pa <- sd_parameters(constant(alpha = 0.5, beta = 0.5, s = 0.2, delta = 0.05, n = 0.02), initial(K = 100, L = 100))
  q <- layout_quality(autoplot(sd_diagram(m, eq, pa, "sfd"), initials = c(K = 100, L = 100)))
  expect_equal(q[["node"]] + q[["link"]], 0)
})

test_that("a font family without the palette's weight falls back to regular", {
  skip_if_not_installed("systemfonts")
  k <- font_weights(list(fam = "tidysd no such family", sf = TRUE,
                         font_w = "semibold", font_w_const = "medium"), ragg = TRUE)
  expect_identical(c(k$fam_r, k$fam_c), rep("tidysd no such family", 2))
})

test_that("a diagram printed smaller than its natural size scales text and lines", {
  skip_if_not_installed("ragg")
  ex <- sd_example("workforce")
  d <- sd_diagram(ex$structure, ex$equations, ex$parameters, "sfd")
  p <- autoplot(d)
  expect_s3_class(p, "sd_diagram_plot")
  expect_s3_class(p + ggplot2::labs(caption = "x"), "sd_diagram_plot")
  # the scale: proportional below the natural size, floored, 1 at or above it
  sz <- attr(p, "size_in")
  expect_equal(diagram_scale(sz, sz * 0.7), 0.7)
  expect_equal(diagram_scale(sz, sz * 0.1), 0.5)
  expect_equal(diagram_scale(sz, sz * c(2, 0.6)), 0.6)
  expect_equal(diagram_scale(sz, sz * 1.5), 1)
  # every set size/linewidth/stroke and arrow halves, on a copy
  q <- scale_diagram(p, 0.5)
  sizes <- function(x) unlist(Map(function(l, l0)   # the ones p sets, read from x
    unlist(l$aes_params[intersect(names(l0$aes_params), c("size", "linewidth", "stroke"))]),
    x$layers, p$layers))
  expect_gt(length(sizes(p)), 50)
  expect_equal(sizes(q), sizes(p) / 2)
  expect_identical(scale_diagram(p, 1), p)
  # small and large devices both draw without warnings
  for (wh in list(c(600, 450), c(3000, 3000))) {
    f <- tempfile(fileext = ".png")
    ragg::agg_png(f, width = wh[1], height = wh[2], res = 96)
    expect_silent(print(p))
    grDevices::dev.off()
    expect_true(file.exists(f))
  }
  # save_diagram() (device at the natural size) draws exactly the unscaled plot
  a <- save_diagram(p, tempfile(fileext = ".png"))
  b <- tempfile(fileext = ".png")
  p0 <- if (isFALSE(attr(p, "ragg_fonts"))) attr(p, "redraw")() else p
  class(p0) <- setdiff(class(p0), "sd_diagram_plot"); sz <- attr(p0, "size_in")
  ggplot2::ggsave(b, p0, width = max(sz[1], 5), height = max(sz[2], 3), dpi = 200,
                  bg = "transparent", device = ragg::agg_png)
  expect_identical(unname(tools::md5sum(a)), unname(tools::md5sum(b)))
})
