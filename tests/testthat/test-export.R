test_that("sd_export() writes well-formed XMILE for a reference model", {
  ex <- sd_example("sir")
  bm <- sd_validate(ex$structure, ex$equations, ex$parameters, ex$spec)
  path <- tempfile(fileext = ".xmile")
  on.exit(unlink(path), add = TRUE)
  expect_equal(sd_export(bm, path), path)

  doc <- xml2::read_xml(path)
  nms <- function(what)
    xml2::xml_attr(xml2::xml_find_all(doc, sprintf("//d1:%s", what)), "name")

  expect_setequal(nms("stock"), struct_names(ex$structure, "stock"))
  expect_true(all(struct_names(ex$structure, "flow") %in% nms("flow")))
  ## stocks carry their initial value and are wired to their flows
  s <- xml2::xml_find_first(doc, "//d1:stock[@name='I']")
  expect_match(xml2::xml_text(xml2::xml_find_first(s, "./d1:eqn")), "[0-9]")
  expect_true(length(xml2::xml_find_all(s, "./d1:inflow")) > 0L)
  ## equations are XMILE syntax, not R
  expect_false(grepl("ifelse|\\bt\\b",
                     paste(xml2::xml_text(xml2::xml_find_all(doc, "//d1:eqn")),
                           collapse = " ")))
  ## sim specs round-trip
  expect_equal(xml2::xml_text(xml2::xml_find_first(doc, "//d1:sim_specs/d1:stop")),
               format(ex$spec$stop, digits = 15L, scientific = FALSE, trim = TRUE))
})

test_that("sd_export() refuses what it cannot write", {
  ex <- sd_example("cohort_sir")   # subscripted
  bm <- sd_validate(ex$structure, ex$equations, ex$parameters, ex$spec)
  expect_error(sd_export(bm, tempfile(fileext = ".xmile")),
               "subscripted")
})
