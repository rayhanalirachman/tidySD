## ---------------------------------------------------------------------------
## The catalogue, models 1-11. See `sd_example()`.
##
## Models 1-8 follow Jim Duggan's SDMR code (MIT (c) 2016 Jim Duggan);
## models 9-11 follow the SDXorg/test-models conformance corpus.
## These are reimplementations in the tidysd grammar, not translations of code.
## ---------------------------------------------------------------------------

ex_customer_growth <- function() {
  list(
    structure = sd_structure(
      meta(name = "Customer growth"),
      stock("Customers", units = "customers", non_negative = TRUE),
      flow("recruits", from = .source,     to = "Customers", units = "customers/year"),
      flow("losses",   from = "Customers", to = .sink,       units = "customers/year")
    ),
    equations = sd_equations(
      recruits ~ Customers * growth_fraction,
      losses   ~ Customers * decline_fraction
    ),
    parameters = sd_parameters(
      constant(growth_fraction = 0.08, decline_fraction = 0.03),
      initial(Customers = 10000)
    ),
    spec = sim_spec(start = 2015, stop = 2030, dt = 0.25, method = "euler",
                    time_unit = "year")
  )
}

## The Ch.1 variant: a piecewise-in-time growth fraction.
ex_customer_growth_piecewise <- function() {
  list(
    structure = sd_structure(
      meta(name = "Customer growth (time-varying fraction)"),
      stock("Customers", units = "customers", non_negative = TRUE),
      aux("growth_fraction", units = "1/year"),
      flow("recruits", from = .source,     to = "Customers", units = "customers/year"),
      flow("losses",   from = "Customers", to = .sink,       units = "customers/year")
    ),
    equations = sd_equations(
      growth_fraction ~ ifelse(t < 2020, 0.07, ifelse(t < 2025, 0.03, 0.02)),
      recruits        ~ Customers * growth_fraction,
      losses          ~ Customers * decline_fraction
    ),
    parameters = sd_parameters(
      constant(decline_fraction = 0.03),
      initial(Customers = 10000)
    ),
    spec = sim_spec(start = 2015, stop = 2030, dt = 0.25, method = "euler",
                    time_unit = "year")
  )
}

ex_s_shaped_growth <- function() {
  list(
    structure = sd_structure(
      meta(name = "S-shaped growth"),
      stock("Stock", units = "widgets", non_negative = TRUE),
      aux("availability", units = "1"),
      aux("effect",       units = "1"),
      aux("growth_rate",  units = "1/time"),
      flow("net_flow", from = .source, to = "Stock", units = "widgets/time")
    ),
    equations = sd_equations(
      availability ~ 1 - Stock / capacity,
      effect       ~ availability / ref_availability,
      growth_rate  ~ ref_growth_rate * effect,
      net_flow     ~ Stock * growth_rate
    ),
    parameters = sd_parameters(
      constant(capacity = 10000, ref_growth_rate = 0.10),
      reference(ref_availability = 1),
      initial(Stock = 100)
    ),
    spec = sim_spec(start = 0, stop = 100, dt = 0.25, method = "euler",
                    time_unit = "time", check_units = FALSE)
  )
}

ex_overshoot <- function() {
  list(
    structure = sd_structure(
      meta(name = "Overshoot and collapse"),
      stock("Capital",  units = "units", non_negative = TRUE),
      stock("Resource", units = "units", non_negative = TRUE),
      lookup("extr_efficiency", input = "Resource",
             in_units = "units", out_units = "1/year",
             interp = "linear", range = "clamp"),
      aux("total_revenue"), aux("capital_costs"), aux("profit"),
      aux("capital_funds"), aux("maximum_investment"), aux("desired_investment"),
      flow("extraction",   from = "Resource", to = .sink,     units = "units/year"),
      flow("investment",   from = .source,    to = "Capital", units = "units/year"),
      flow("depreciation", from = "Capital",  to = .sink,     units = "units/year")
    ),
    equations = sd_equations(
      extraction         ~ extr_efficiency(Resource) * Capital,
      total_revenue      ~ revenue_per_unit * extraction,
      capital_costs      ~ Capital * capital_cost_fraction,
      profit             ~ total_revenue - capital_costs,
      capital_funds      ~ fraction_reinvested * profit,
      maximum_investment ~ capital_funds / cost_per_investment,
      desired_investment ~ Capital * desired_growth,
      investment         ~ min(maximum_investment, desired_investment),
      depreciation       ~ Capital * depreciation_fraction
    ),
    parameters = sd_parameters(
      constant(desired_growth = 0.07, depreciation_fraction = 0.05,
               cost_per_investment = 2.0, fraction_reinvested = 0.12,
               revenue_per_unit = 3, capital_cost_fraction = 0.10),
      initial(Capital = 5, Resource = 1000),
      lookup_data("extr_efficiency",
        x = seq(0, 1000, by = 100),
        y = c(0, 0.25, 0.45, 0.63, 0.75, 0.85, 0.92, 0.96, 0.98, 0.99, 1.0))
    ),
    spec = sim_spec(start = 0, stop = 200, dt = 0.125, method = "euler",
                    time_unit = "year"),
    scenarios = scenarios(
      base = list(),
      fr13 = list(fraction_reinvested = 0.13),
      fr14 = list(fraction_reinvested = 0.14),
      dg15 = list(fraction_reinvested = 0.14, desired_growth = 0.15),
      dg16 = list(fraction_reinvested = 0.14, desired_growth = 0.16)
    )
  )
}

ex_solow <- function() {
  list(
    structure = sd_structure(
      meta(name = "Solow economic growth"),
      stock("Machines", units = "machines", non_negative = TRUE),
      aux("economic_output"),
      flow("investment", from = .source,    to = "Machines", units = "machines/year"),
      flow("discards",   from = "Machines", to = .sink,      units = "machines/year")
    ),
    equations = sd_equations(
      economic_output ~ labour * sqrt(Machines),
      investment      ~ economic_output * reinvest_fraction,
      discards        ~ Machines * dep_fraction
    ),
    parameters = sd_parameters(
      constant(dep_fraction = 0.1, labour = 100, reinvest_fraction = 0.20),
      initial(Machines = 100)
    ),
    spec = sim_spec(start = 0, stop = 100, dt = 0.25, method = "euler",
                    time_unit = "year")
  )
}

ex_sir <- function() {
  list(
    structure = sd_structure(
      meta(name = "SIR"),
      stock("S", units = "people", non_negative = TRUE),
      stock("I", units = "people", non_negative = TRUE),
      stock("R", units = "people", non_negative = TRUE),
      aux("beta",   units = "1/(people*day)"),
      aux("lambda", units = "1/day"),
      flow("IR", from = "S", to = "I", units = "people/day"),
      flow("RR", from = "I", to = "R", units = "people/day")
    ),
    equations = sd_equations(
      beta   ~ contact_rate * infectivity / total_population,
      lambda ~ beta * I,
      IR     ~ S * lambda,
      RR     ~ I / recovery_time
    ),
    parameters = sd_parameters(
      constant(contact_rate = 6, infectivity = 0.20,
               total_population = 1000, recovery_time = 5),
      initial(S = 999, I = 1, R = 0)
    ),
    spec = sim_spec(start = 0, stop = 100, dt = 0.125, method = "euler",
                    time_unit = "day")
  )
}

ex_bass <- function() {
  list(
    structure = sd_structure(
      meta(name = "Bass diffusion (aggregate)"),
      stock("PotentialAdopters", units = "people", non_negative = TRUE),
      stock("Adopters",          units = "people", non_negative = TRUE),
      aux("beta", units = "1/(people*week)"),
      aux("rho",  units = "1/week"),
      flow("adoption_rate", from = "PotentialAdopters", to = "Adopters",
           units = "people/week")
    ),
    equations = sd_equations(
      beta          ~ contact_rate * infectivity / total_population,
      rho           ~ beta * Adopters,
      adoption_rate ~ PotentialAdopters * rho
    ),
    parameters = sd_parameters(
      constant(contact_rate = 6, infectivity = 0.25, total_population = 100000),
      initial(PotentialAdopters = 99999, Adopters = 1)
    ),
    spec = sim_spec(start = 0, stop = 20, dt = 0.01, method = "euler",
                    time_unit = "week", saveat = 0.25)
  )
}

ex_cohort_sir <- function() {
  list(
    structure = sd_structure(
      meta(name = "Cohort SIR"),
      subscripts(cohort = c("young", "adult", "elderly")),
      stock("S", dims = "cohort", units = "people", non_negative = TRUE),
      stock("I", dims = "cohort", units = "people", non_negative = TRUE),
      stock("R", dims = "cohort", units = "people", non_negative = TRUE),
      aux("lambda",         dims = "cohort", units = "1/day"),
      aux("total_infected",                  units = "people"),
      flow("IR", from = "S", to = "I", dims = "cohort", units = "people/day"),
      flow("RR", from = "I", to = "R", dims = "cohort", units = "people/day")
    ),
    equations = sd_equations(
      lambda         ~ (CE %*% I) / pop,
      IR             ~ lambda * S,
      RR             ~ I / recovery_time,
      total_infected ~ sum(I)
    ),
    parameters = sd_parameters(
      constant(
        CE = matrix(c(3, 2, 1,
                      2, 2, 1,
                      1, 1, 0.5), nrow = 3, byrow = TRUE),
        pop = c(young = 25000, adult = 50000, elderly = 25000),
        recovery_time = 2
      ),
      initial(
        S = c(young = 24999, adult = 50000, elderly = 25000),
        I = c(young = 1,     adult = 0,     elderly = 0),
        R = 0
      )
    ),
    spec = sim_spec(start = 0, stop = 20000, dt = 0.125, method = "euler",
                    time_unit = "day", saveat = 1),
    note = paste("Duggan's horizon (t = 20000) is kept as shipped; `saveat = 1`",
                 "only thins the 160,000-step output and does not touch the",
                 "integration. All three waves peak around day 4.")
  )
}

ex_material_delay <- function() {
  list(
    structure = sd_structure(
      meta(name = "First-order material delay"),
      stock("Material", units = "units", non_negative = TRUE),
      flow("inflow",  from = .source,    to = "Material", units = "units/week"),
      flow("outflow", from = "Material", to = .sink,      units = "units/week")
    ),
    equations = sd_equations(
      inflow  ~ 100 + step(100, 4),
      outflow ~ Material / delay_time
    ),
    parameters = sd_parameters(
      constant(delay_time = 4),
      initial(Material = 400)
    ),
    spec = sim_spec(start = 0, stop = 25, dt = 0.125, method = "euler",
                    time_unit = "week")
  )
}

ex_teacup <- function() {
  list(
    structure = sd_structure(
      meta(name = "Teacup cooling"),
      stock("TeacupTemperature", units = "degF"),
      flow("heat_loss_to_room", from = "TeacupTemperature", to = .sink,
           units = "degF/minute")
    ),
    equations = sd_equations(
      heat_loss_to_room ~ (TeacupTemperature - room_temperature) / characteristic_time
    ),
    parameters = sd_parameters(
      constant(room_temperature = 70, characteristic_time = 10),
      initial(TeacupTemperature = 180)
    ),
    spec = sim_spec(start = 0, stop = 30, dt = 0.125, method = "euler",
                    time_unit = "minute")
  )
}

ex_lotka_volterra <- function() {
  list(
    structure = sd_structure(
      meta(name = "Lotka-Volterra"),
      stock("Prey",      units = "hares", non_negative = TRUE),
      stock("Predators", units = "foxes", non_negative = TRUE),
      aux("fractional_predation_rate",   units = "1/year"),
      aux("predator_reproduction_ratio", units = "1/year"),
      flow("prey_births",     from = .source,     to = "Prey",      units = "hares/year"),
      flow("prey_deaths",     from = "Prey",      to = .sink,       units = "hares/year"),
      flow("predator_births", from = .source,     to = "Predators", units = "foxes/year"),
      flow("predator_deaths", from = "Predators", to = .sink,       units = "foxes/year")
    ),
    equations = sd_equations(
      fractional_predation_rate   ~ ref_predation_rate * Predators / ref_predators,
      predator_reproduction_ratio ~ ref_predator_reproduction * Prey / ref_prey_population,
      prey_births     ~ Prey * prey_reproduction_ratio,
      prey_deaths     ~ Prey * fractional_predation_rate,
      predator_births ~ Predators * predator_reproduction_ratio,
      predator_deaths ~ Predators / predator_lifespan
    ),
    parameters = sd_parameters(
      constant(prey_reproduction_ratio = 3, predator_lifespan = 10,
               ref_predation_rate = 0.2, ref_predator_reproduction = 1),
      reference(ref_predators = 20, ref_prey_population = 1000),
      initial(Prey = 1000, Predators = 20)
    ),
    spec = sim_spec(start = 0, stop = 50, dt = 0.0625, method = "euler",
                    time_unit = "year")
  )
}

ex_town_population <- function() {
  tp <- tidysd::town_population
  list(
    structure = sd_structure(
      meta(name = "Subscripted town population"),
      subscripts(town = names(tp)),
      stock("Population", dims = "town", units = "people", non_negative = TRUE),
      flow("births", from = .source,      to = "Population", dims = "town",
           units = "people/month"),
      flow("deaths", from = "Population", to = .sink,        dims = "town",
           units = "people/month")
    ),
    equations = sd_equations(
      births ~ birthrate * Population,
      deaths ~ delayN(births, lifespan, order = 8, initial = Population / lifespan)
    ),
    parameters = sd_parameters(
      constant(birthrate = 0.1, lifespan = 70),
      initial(Population = tp)
    ),
    spec = sim_spec(start = 0, stop = 20, dt = 1, method = "euler",
                    time_unit = "month"),
    note = paste("The 351 town names and initial populations shipped here are",
                 "synthetic stand-ins for the Vensim sample's Massachusetts data,",
                 "which is not redistributed with tidysd.")
  )
}
