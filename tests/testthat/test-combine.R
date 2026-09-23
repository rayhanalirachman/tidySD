test_that("sd_stratify() expands a model over groups and runs per group", {
  m <- list(
    structure = sd_structure(
      stock("S", units = "people"),
      flow("growth", from = .source, to = "S", units = "people/year")
    ),
    equations = sd_equations(growth ~ S * r),
    parameters = sd_parameters(constant(r = 0.1), initial(S = 100))
  )
  s <- sd_stratify(m, by = list(region = c("north", "south", "east")))

  expect_equal(s$structure$dims$region, c("north", "south", "east"))
  expect_equal(s$structure$vars$S$dims, "region")
  expect_equal(s$structure$vars$growth$dims, "region")

  ## a scalar constant applies to every group ...
  out <- simulate(s$structure, s$equations, s$parameters, spec = sim_spec(0, 10, 1))
  expect_true("region" %in% names(out))
  expect_setequal(unique(out$region), c("north", "south", "east"))
  expect_equal(at(out, "S", 10, member = "north"), at(out, "S", 10, member = "east"))

  ## ... and a vector of one value per group makes them differ
  p <- update(s$parameters, constant(r = c(0.1, 0.2, 0.3)), initial(S = c(100, 100, 50)))
  out2 <- simulate(s$structure, s$equations, p, spec = sim_spec(0, 10, 1))
  expect_equal(at(out2, "S", 0, member = "east"), 50)
  expect_gt(at(out2, "S", 10, member = "south"), at(out2, "S", 10, member = "north"))

  ## `except` leaves a variable scalar
  s2 <- sd_stratify(m$structure, by = list(region = c("north", "south")), except = "growth")
  expect_null(s2$vars$growth$dims)
  expect_error(sd_stratify(m, by = list(region = "north"), except = "nope"), "does not declare")
})

test_that("sd_compose() merges two models and links one into the other", {
  supply <- list(
    structure = sd_structure(
      stock("Inventory"),
      flow("production", from = .source, to = "Inventory"),
      flow("shipping", from = "Inventory", to = .sink),
      aux("shipments")
    ),
    equations = sd_equations(production ~ rate, shipments ~ Inventory * 0.1,
                             shipping ~ shipments),
    parameters = sd_parameters(constant(rate = 10), initial(Inventory = 100))
  )
  demand <- list(
    structure = sd_structure(
      stock("Backlog"),
      flow("filling", from = "Backlog", to = .sink),
      aux("deliveries")
    ),
    equations = sd_equations(filling ~ deliveries, deliveries ~ 0),
    parameters = sd_parameters(initial(Backlog = 500))
  )

  m <- sd_compose(supply, demand, link = c(deliveries = "shipments"))
  out <- simulate(m$structure, m$equations, m$parameters, spec = sim_spec(0, 10, 1))

  ## both sets of variables are in the output, on one time base
  expect_true(all(c("Inventory", "production", "Backlog", "filling") %in% out$variable))
  ## the port is gone, replaced by model a's variable
  expect_false("deliveries" %in% out$variable)
  ## and the link really carries: Backlog falls by a's shipments
  expect_equal(at(out, "filling", 0), at(out, "shipments", 0))
  expect_lt(at(out, "Backlog", 10), 500)

  ## name collisions are an error unless namespaced
  expect_error(sd_compose(supply, supply), "Both models declare")
  m2 <- sd_compose(supply, supply, prefix = c("a_", "b_"))
  out2 <- simulate(m2$structure, m2$equations, m2$parameters, spec = sim_spec(0, 5, 1))
  expect_true(all(c("a_Inventory", "b_Inventory") %in% out2$variable))
  expect_equal(at(out2, "a_Inventory", 5), at(out2, "b_Inventory", 5))

  ## a port must be an aux() or input()
  expect_error(sd_compose(supply, demand, link = c(Backlog = "shipments")), "only an aux")
})
