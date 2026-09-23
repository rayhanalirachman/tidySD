xmile <- function() system.file("extdata", "sir.xmile", package = "tidysd")

test_that("an XMILE file imports into the three layers and runs", {
  m <- sd_import(xmile())

  v <- sd_variables(m$structure)
  expect_equal(unname(sort(v$name[v$type == "stock"])),
               c("Infected", "Recovered", "Susceptible"))
  ## names with spaces are sanitised, wiring comes from the stocks' in/outflows
  expect_equal(unname(v$from[v$name == "infection_rate"]), "Susceptible")
  expect_equal(unname(v$to[v$name == "infection_rate"]), "Infected")
  ## a bare number becomes a constant, anything else an equation
  expect_equal(m$parameters$constants$contact_rate, 6)
  expect_equal(m$parameters$initials$Susceptible, 999)
  expect_equal(deparse1(m$equations$eqns$recovery_time$rhs), "max(1, 2)")
  expect_equal(m$spec$dt, 0.25)
  expect_equal(m$spec$stop, 60)

  out <- simulate(m$structure, m$equations, m$parameters, spec = m$spec)
  expect_s3_class(out, "sd_result")
  total <- out$value[out$variable == "total_population"]
  expect_true(all(abs(total - 1000) < 1e-6))     # conserved
  final <- out$value[out$variable == "Recovered" & out$time == 60]
  expect_gt(final, 900)                          # the epidemic burns through
})

test_that("graphical functions, IF/THEN/ELSE and derived initials translate", {
  f <- tempfile(fileext = ".xmile")
  on.exit(unlink(f))
  writeLines(c(
    '<xmile version="1.0" xmlns="http://docs.oasis-open.org/xmile/ns/XMILE/v1.0">',
    '<sim_specs><start>0</start><stop>4</stop><dt>1</dt></sim_specs><model><variables>',
    '<stock name="Level"><eqn>start level * 2</eqn><inflow>fill</inflow></stock>',
    '<flow name="fill"><eqn>IF Level &lt; 10 THEN effect ELSE 0</eqn></flow>',
    '<aux name="start level"><eqn>1</eqn></aux>',
    '<aux name="effect"><eqn>Level</eqn>',
    '  <gf><xscale min="0" max="10"/><ypts>2,2,2,2,2,2,2,2,2,2,2</ypts></gf></aux>',
    '</variables></model></xmile>'), f)

  m <- sd_import(f)
  expect_equal(deparse1(m$equations$eqns$fill$rhs), "ifelse(Level < 10, effect, 0)")
  expect_equal(deparse1(m$equations$eqns$effect$rhs), "effect_gf(Level)")
  expect_equal(deparse1(m$equations$eqns[["init:Level"]]$rhs), "start_level * 2")
  expect_equal(m$parameters$lookups$effect_gf$x, seq(0, 10, length.out = 11))

  out <- simulate(m$structure, m$equations, m$parameters, spec = m$spec)
  expect_equal(out$value[out$variable == "Level"], c(2, 4, 6, 8, 10))
})

test_that("sd_import() refuses what it cannot read", {
  expect_error(sd_import("nope.xmile"), "No such file")
  expect_error(sd_import(system.file("DESCRIPTION", package = "tidysd")), "does not know how")
})

## --- Vensim .mdl -----------------------------------------------------------

mdl_file <- function(...) {
  f <- tempfile(fileext = ".mdl")
  writeLines(c(...), f)
  f
}

test_that("a Vensim .mdl imports, wires its flows and reproduces the teacup", {
  f <- mdl_file(
    "{UTF-8}",
    "Characteristic Time = 10",
    "\t~\tMinutes",
    "\t~\t\t|",
    "",
    "Room Temperature = 70",
    "\t~\tDegrees Fahrenheit",
    "\t~\t\t|",
    "",
    "Heat Loss to Room = (Teacup Temperature - Room Temperature) / Characteristic Time",
    "\t~\tDegrees Fahrenheit/Minute",
    "\t~\t\t|",
    "",
    "Teacup Temperature = INTEG(-Heat Loss to Room, 180)",
    "\t~\tDegrees Fahrenheit",
    "\t~\t\t|",
    "",
    "********************************************************",
    "\t.Control",
    "********************************************************~",
    "\t\tSimulation Control Parameters",
    "\t|",
    "",
    "INITIAL TIME  = 0",
    "\t~\tMinute",
    "\t~\tThe initial time for the simulation.",
    "\t|",
    "",
    "FINAL TIME  = 30",
    "\t~\tMinute",
    "\t~\tThe final time for the simulation.",
    "\t|",
    "",
    "TIME STEP  = 0.125",
    "\t~\tMinute [0,?]",
    "\t~\tThe time step for the simulation.",
    "\t|",
    "",
    "SAVEPER  = TIME STEP",
    "\t~\tMinute [0,?]",
    "\t~\tThe frequency with which output is stored.",
    "\t|")
  on.exit(unlink(f))

  m <- sd_import(f)
  v <- sd_variables(m$structure)
  ## a negative INTEG term is an outflow; the control block becomes the spec
  expect_equal(unname(v$type[v$name == "Heat_Loss_to_Room"]), "flow")
  expect_equal(unname(v$from[v$name == "Heat_Loss_to_Room"]), "Teacup_Temperature")
  expect_equal(unname(v$to[v$name == "Heat_Loss_to_Room"]), ".sink")
  expect_equal(unname(v$units[v$name == "Teacup_Temperature"]), "Degrees Fahrenheit")
  expect_equal(m$spec$dt, 0.125)
  expect_equal(m$spec$stop, 30)
  ## bare numbers are constants, the INTEG's second argument the initial value
  expect_equal(m$parameters$constants$Characteristic_Time, 10)
  expect_equal(m$parameters$initials$Teacup_Temperature, 180)

  out <- simulate(m$structure, m$equations, m$parameters, spec = m$spec)
  temp <- out$value[out$variable == "Teacup_Temperature"]
  expect_equal(temp[out$time[out$variable == "Teacup_Temperature"] == 10], 110.2125,
               tolerance = 1e-4)          # one 1/e of the gap per 10 minutes
  expect_equal(temp[out$time[out$variable == "Teacup_Temperature"] == 30], 75.374,
               tolerance = 1e-4)
})

test_that("a two-stock .mdl keeps both stocks at their fixed point", {
  f <- mdl_file(
    "{UTF-8}",
    "Prey = INTEG(Prey Births - Prey Deaths, Initial Prey Population)",
    "\t~\tHares",
    "\t~\t\t|",
    "Predators = INTEG(Predator Births - Predator Deaths, Initial Predator Population)",
    "\t~\tFoxes",
    "\t~\t\t|",
    "Prey Births = Prey * Prey Reproduction Ratio",
    "\t~\tHares/Year",
    "\t~\t\t|",
    "Prey Deaths = Prey * Fractional Predation Rate",
    "\t~\tHares/Year",
    "\t~\t\t|",
    "Predator Births = Predators * Predator Reproduction Ratio",
    "\t~\tFoxes/Year",
    "\t~\t\t|",
    "Predator Deaths = Predators / Predator Lifespan",
    "\t~\tFoxes/Year",
    "\t~\t\t|",
    "Fractional Predation Rate = Reference Fractional Predation Rate * Predators",
    "\t / Reference Predators",
    "\t~\t1/Year",
    "\t~\t\t|",
    "Predator Reproduction Ratio = Reference Predator Reproduction Ratio * Prey",
    "\t / Reference Prey Population",
    "\t~\t1/Year",
    "\t~\t\t|",
    "Prey Reproduction Ratio = 3",
    "\t~\t1/Year",
    "\t~\t\t|",
    "Predator Lifespan = 10",
    "\t~\tYear",
    "\t~\t\t|",
    "Reference Fractional Predation Rate = 0.2",
    "\t~\t1/Year",
    "\t~\t\t|",
    "Reference Predators = 20",
    "\t~\tFoxes",
    "\t~\t\t|",
    "Reference Predator Reproduction Ratio = 1",
    "\t~\t1/Year",
    "\t~\t\t|",
    "Reference Prey Population = 1000",
    "\t~\tHares",
    "\t~\t\t|",
    "Initial Prey Population = 100",
    "\t~\tHares",
    "\t~\t\t|",
    "Initial Predator Population = 300",
    "\t~\tFoxes",
    "\t~\t\t|",
    "INITIAL TIME = 0",
    "\t~\tYear",
    "\t~\t\t|",
    "FINAL TIME = 50",
    "\t~\tYear",
    "\t~\t\t|",
    "TIME STEP = 0.0625",
    "\t~\tYear",
    "\t~\t\t|")
  on.exit(unlink(f))

  m <- sd_import(f)
  v <- sd_variables(m$structure)
  expect_equal(unname(v$to[v$name == "Prey_Births"]), "Prey")
  expect_equal(unname(v$from[v$name == "Prey_Deaths"]), "Prey")
  expect_equal(unname(v$to[v$name == "Predator_Births"]), "Predators")
  ## an INTEG whose initial value is a variable becomes an init equation
  expect_equal(deparse1(m$equations$eqns[["init:Prey"]]$rhs), "Initial_Prey_Population")

  out <- simulate(m$structure, m$equations, m$parameters, spec = m$spec)
  prey <- out$value[out$variable == "Prey"]
  pred <- out$value[out$variable == "Predators"]
  expect_true(all(abs(prey - 100) < 1e-8))     # 100 hares / 300 foxes is the
  expect_true(all(abs(pred - 300) < 1e-8))     # fixed point of this model
})

test_that(".mdl expressions translate and unsupported ones abort by name", {
  f <- mdl_file(
    "{UTF-8}",
    "Level = INTEG(gain * Inflow - Level / Tau, 10)",
    "\t~\tWidgets",
    "\t~\t\t|",
    "Inflow = IF THEN ELSE(Time < 5 :AND: Level < 100, 20, 0)",
    "\t~\tWidgets/Minute",
    "\t~\t\t|",
    "gain = 1",
    "\t~\tDmnl",
    "\t~\t\t|",
    "Tau = 4",
    "\t~\tMinute",
    "\t~\t\t|",
    "INITIAL TIME = 0",
    "\t~\tMinute",
    "\t~\t\t|",
    "FINAL TIME = 12",
    "\t~\tMinute",
    "\t~\t\t|",
    "TIME STEP = 1",
    "\t~\tMinute",
    "\t~\t\t|")
  on.exit(unlink(f))

  m <- sd_import(f)
  expect_equal(deparse1(m$equations$eqns$Inflow$rhs),
               "ifelse(t < 5 & Level < 100, 20, 0)")
  ## a net rate that is not a sum of named flows becomes one synthetic flow
  expect_equal(deparse1(m$equations$eqns$Level_net$rhs), "gain * Inflow - Level/Tau")

  out <- simulate(m$structure, m$equations, m$parameters, spec = m$spec)
  lvl <- out$value[out$variable == "Level"]
  tt <- out$time[out$variable == "Level"]
  ## once the inflow stops the level decays by 1 - dt/Tau each step
  expect_equal(lvl[tt == 12] / lvl[tt == 11], 0.75, tolerance = 1e-8)

  arr <- mdl_file("Stock[Region] = INTEG(inflow[Region], 0)", "\t~\tUnits", "\t~\t\t|")
  on.exit(unlink(arr), add = TRUE)
  expect_error(sd_import(arr), "subscripts")

  lk <- mdl_file("effect = WITH LOOKUP(Level, ([(0,0)-(10,10)],(0,0),(10,10)))",
                 "\t~\tDmnl", "\t~\t\t|")
  on.exit(unlink(lk), add = TRUE)
  expect_error(sd_import(lk), "lookup")
})
