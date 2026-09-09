## ---------------------------------------------------------------------------
## The catalogue, models 12-22. See `sd_example()`.
##
## Models 12-15 follow the SDXorg/test-models conformance corpus; 16-21 follow
## the SDXorg/PySD-Cookbook sample models. Reimplementations, not translations.
## ---------------------------------------------------------------------------

ex_smooth <- function() {
  list(
    structure = sd_structure(
      meta(name = "Information smoothing"),
      aux("input"), aux("adjustment_time"),
      aux("smooth_1"), aux("smooth_1i"),
      aux("smooth_3"), aux("smooth_3i"), aux("smooth_n")
    ),
    equations = sd_equations(
      input           ~ -1 + step(5, 5),
      adjustment_time ~ 2 + step(2, 10),
      smooth_1  ~ smoothN(input, adjustment_time),
      smooth_1i ~ smoothN(input, adjustment_time, initial = initial_value),
      smooth_3  ~ smoothN(input, adjustment_time, order = 3),
      smooth_3i ~ smoothN(input, adjustment_time, initial = initial_value, order = 3),
      smooth_n  ~ smoothN(input, adjustment_time, initial = initial_value,
                          order = 2 + step(1, 10))
    ),
    parameters = sd_parameters(constant(initial_value = 5)),
    spec = sim_spec(start = 0, stop = 20, dt = 0.25, method = "euler",
                    time_unit = "month")
  )
}

ex_forecast <- function() {
  list(
    structure = sd_structure(
      meta(name = "Trend forecast"),
      aux("R", units = "widgets/month"),
      aux("R_delayed",  units = "widgets/month"),
      aux("R_forecast", units = "widgets/month")
    ),
    equations = sd_equations(
      R          ~ 10 + ramp(1, 10, 60) + step(1, 70) * (1 - step(1, 90)) +
                   step(2 * sin(6.28 * t / period), 100),
      R_delayed  ~ delay_fixed(R, delay_time, initial = R),
      R_forecast ~ forecast(R_delayed, smoothing_time, horizon)
    ),
    parameters = sd_parameters(
      constant(period = 20, delay_time = 10, smoothing_time = 5, horizon = 10)
    ),
    spec = sim_spec(start = 0, stop = 120, dt = 0.5, method = "euler",
                    time_unit = "month", saveat = 1)
  )
}

ex_delay_fixed <- function() {
  list(
    structure = sd_structure(
      meta(name = "Fixed pipeline delay"),
      aux("time_squared"),
      aux("DF05"), aux("DF1"), aux("DF12"), aux("DF15"),
      aux("DF2"),  aux("DF37"), aux("DST"), aux("DT2")
    ),
    equations = sd_equations(
      time_squared ~ t^2,
      DF05 ~ delay_fixed(time_squared, 0.5, initial = -10),
      DF1  ~ delay_fixed(time_squared, 1,   initial =  10),
      DF12 ~ delay_fixed(time_squared, 1.2, initial =  -4),
      DF15 ~ delay_fixed(time_squared, 1.5, initial =  20),
      DF2  ~ delay_fixed(time_squared, 2,   initial =  -3),
      DF37 ~ delay_fixed(time_squared, 3.7, initial =   4),
      DST  ~ delay_fixed(time_squared, 2 + 2 * sin(t), initial = 7),
      DT2  ~ delay_fixed(time_squared, t / 2, initial = 4)
    ),
    parameters = sd_parameters(),
    spec = sim_spec(start = 0, stop = 50, dt = 1, method = "euler",
                    time_unit = "month")
  )
}

ex_workforce <- function() {
  list(
    structure = sd_structure(
      meta(name = "Workforce and task backlog"),
      stock("Rookies",     units = "person", non_negative = TRUE),
      stock("Experts",     units = "person", non_negative = TRUE),
      stock("TaskBacklog", units = "task",   non_negative = TRUE),
      lookup("effect_of_pressure_on_hiring", input = "pressure_to_hire",
             out_units = "person/week", interp = "linear", range = "clamp"),
      aux("pressure_to_hire"),
      aux("expert_hours_on_task", units = "person*hour/week"),
      aux("rookie_hours_on_task", units = "person*hour/week"),
      aux("expert_task_completion", units = "task/week"),
      aux("rookie_task_completion", units = "task/week"),
      flow("hiring",     from = .source,   to = "Rookies", units = "person/week"),
      flow("maturation", from = "Rookies", to = "Experts", units = "person/week"),
      flow("departure",  from = "Experts", to = .sink,     units = "person/week"),
      flow("task_arrival",    from = .source,       to = "TaskBacklog", units = "task/week"),
      flow("task_completion", from = "TaskBacklog", to = .sink)
    ),
    equations = sd_equations(
      expert_hours_on_task   ~ Experts * expert_workweek -
                               supervision_hours_per_rookie * Rookies,
      rookie_hours_on_task   ~ Rookies * rookie_workweek,
      expert_task_completion ~ expert_hours_on_task / expert_time_per_task,
      rookie_task_completion ~ rookie_hours_on_task / rookie_time_per_task,
      task_arrival     ~ arrival_rate,
      task_completion  ~ min(expert_task_completion + rookie_task_completion, TaskBacklog),
      pressure_to_hire ~ (TaskBacklog - target_backlog) / target_backlog,
      hiring           ~ effect_of_pressure_on_hiring(pressure_to_hire),
      maturation       ~ Rookies / maturation_time,
      departure        ~ Experts / average_tenure
    ),
    parameters = sd_parameters(
      constant(maturation_time = 15, average_tenure = 35, target_backlog = 500,
               expert_workweek = 40, rookie_workweek = 40,
               expert_time_per_task = 10, rookie_time_per_task = 30,
               supervision_hours_per_rookie = 20, arrival_rate = 230),
      initial(Rookies = 5, Experts = 50, TaskBacklog = 500),
      lookup_data("effect_of_pressure_on_hiring",
        x = c(-1, -0.25, 0,   0.5, 1,  2,  3),
        y = c( 0,  0,    2.5, 15,  20, 25, 25))
    ),
    spec = sim_spec(start = 0, stop = 150, dt = 0.03125, method = "euler",
                    time_unit = "week")
  )
}

ex_defects <- function() {
  list(
    structure = sd_structure(
      meta(name = "Manufacturing defects"),
      stock("Backlog", units = "unit", non_negative = TRUE),
      lookup("influence_of_backlog_on_speed",   input = "Backlog",
             in_units = "unit", out_units = "day/unit",
             interp = "linear", range = "clamp"),
      lookup("influence_of_backlog_on_workday", input = "Backlog",
             in_units = "unit", out_units = "1",
             interp = "linear", range = "clamp"),
      aux("time_allocated_per_unit", units = "day/unit"),
      aux("length_of_workday",       units = "1"),
      aux("defect_rate",             units = "1"),
      flow("arrival_rate",     from = .source,   to = "Backlog", units = "unit/day"),
      flow("fulfillment_rate", from = "Backlog", to = .sink,     units = "unit/day")
    ),
    equations = sd_equations(
      time_allocated_per_unit ~ influence_of_backlog_on_speed(Backlog),
      length_of_workday       ~ influence_of_backlog_on_workday(Backlog),
      defect_rate             ~ 0.01 * length_of_workday / time_allocated_per_unit,
      arrival_rate            ~ base_arrivals + pulse_size * pulse(20, 10),
      fulfillment_rate        ~ number_of_employees * length_of_workday /
                                time_allocated_per_unit * (1 - defect_rate)
    ),
    parameters = sd_parameters(
      constant(number_of_employees = 2, base_arrivals = 10, pulse_size = 12),
      initial(Backlog = 11.7),
      lookup_data("influence_of_backlog_on_speed",
        x = c(0, 5, 10, 15, 20, 80),
        y = c(0.1, 0.1, 0.09, 0.05, 0.04, 0.04)),
      lookup_data("influence_of_backlog_on_workday",
        x = c(0, 2.76986, 5.53971, 10.3462, 13.1161, 16.5377, 20.5295, 60),
        y = c(0.1, 0.128571, 0.188095, 0.347619, 0.416667, 0.452381, 0.469048, 0.5))
    ),
    spec = sim_spec(start = 0, stop = 50, dt = 0.015625, method = "euler",
                    time_unit = "day")
  )
}

ex_carbon_bathtub <- function() {
  em <- tidysd::global_emissions_synthetic
  list(
    structure = sd_structure(
      meta(name = "Atmospheric carbon bathtub"),
      stock("ExcessAtmosphericCarbon", units = "MtC", non_negative = TRUE),
      input("emissions", units = "MtC/year"),
      flow("emission_flow",   from = .source, to = "ExcessAtmosphericCarbon",
           units = "MtC/year"),
      flow("natural_removal", from = "ExcessAtmosphericCarbon", to = .sink,
           units = "MtC/year")
    ),
    equations = sd_equations(
      emission_flow   ~ emissions,
      natural_removal ~ ExcessAtmosphericCarbon * removal_constant
    ),
    parameters = sd_parameters(
      constant(removal_constant = 0.01),
      initial(ExcessAtmosphericCarbon = 0),
      input_series("emissions", data = em, interp = "linear")
    ),
    spec = sim_spec(start = 1751, stop = 2011, dt = 1, method = "euler",
                    time_unit = "year"),
    note = paste("The emissions driver shipped here is a synthetic stand-in with",
                 "the shape of the CDIAC global fossil-fuel series, which is not",
                 "redistributed with tidysd. Swap in the real CSV with",
                 "`update(parameters, input_series('emissions', data = ...))`.")
  )
}

ex_roessler <- function() {
  list(
    structure = sd_structure(
      meta(name = "Roessler attractor"),
      stock("x"), stock("y"), stock("z"),
      flow("dxdt", from = .source, to = "x"),
      flow("dydt", from = .source, to = "y"),
      flow("dzdt", from = .source, to = "z")
    ),
    equations = sd_equations(
      dxdt ~ -y - z,
      dydt ~ x + a * y,
      dzdt ~ b + z * (x - c)
    ),
    parameters = sd_parameters(
      constant(a = 0.2, b = 0.2, c = 5.7),
      initial(x = 0.5, y = 0.5, z = 0.4)
    ),
    spec = sim_spec(start = 0, stop = 100, dt = 0.03125, method = "rk4")
  )
}

ex_pendulum <- function() {
  list(
    structure = sd_structure(
      meta(name = "Single pendulum"),
      stock("AngularPosition", units = "radian"),
      stock("AngularVelocity", units = "radian/second"),
      aux("force_of_gravity",             units = "kg*m/second^2"),
      aux("angular_component_of_gravity", units = "kg*m/second^2"),
      aux("torque",                       units = "kg*m^2/second^2"),
      aux("moment_of_inertia",            units = "kg*m^2"),
      flow("change_in_angular_position", from = .source, to = "AngularPosition",
           units = "radian/second"),
      flow("change_in_angular_velocity", from = .source, to = "AngularVelocity",
           units = "radian/second^2")
    ),
    equations = sd_equations(
      force_of_gravity             ~ gravity * mass,
      angular_component_of_gravity ~ force_of_gravity * sin(AngularPosition),
      torque                       ~ angular_component_of_gravity * length,
      moment_of_inertia            ~ mass * length^2,
      change_in_angular_velocity   ~ torque / moment_of_inertia,
      change_in_angular_position   ~ AngularVelocity
    ),
    parameters = sd_parameters(
      constant(gravity = -9.8, mass = 10, length = 10),
      initial(AngularPosition = 1, AngularVelocity = 0)
    ),
    spec = sim_spec(start = 0, stop = 100, dt = 0.0078125, method = "rk4",
                    time_unit = "second", saveat = 0.1)
  )
}

ex_sales_agents <- function() {
  list(
    structure = sd_structure(
      meta(name = "Sales agent motivation"),
      stock("Motivation",            units = "1"),
      stock("Tenure",                units = "month"),
      stock("TotalCumulativeSales",  units = "person"),
      stock("TotalCumulativeIncome", units = "month"),
      lookup("impact_of_motivation_on_effort", input = "Motivation",
             out_units = "1", interp = "linear", range = "clamp"),
      aux("still_employed",         units = "1"),
      aux("sales_effort_available", units = "hour/month"),
      aux("effort",                 units = "hour/month"),
      aux("sales",                  units = "person/month"),
      aux("income",                 units = "month/month"),
      flow("motivation_adjustment", from = .source, to = "Motivation", units = "1/month"),
      flow("accumulating_tenure",   from = .source, to = "Tenure",     units = "month/month"),
      flow("accumulating_sales",    from = .source, to = "TotalCumulativeSales",
           units = "person/month"),
      flow("accumulating_income",   from = .source, to = "TotalCumulativeIncome",
           units = "month/month")
    ),
    equations = sd_equations(
      still_employed         ~ ifelse(Motivation > motivation_threshold, 1, 0),
      sales_effort_available ~ total_effort_available * fraction_of_effort_for_sales *
                               still_employed,
      effort                 ~ sales_effort_available *
                               impact_of_motivation_on_effort(Motivation),
      sales                  ~ effort / effort_required_per_sale * success_rate,
      income                 ~ months_of_expenses_per_sale * sales +
                               ifelse(t < startup_subsidy_length, startup_subsidy, 0),
      motivation_adjustment  ~ (income - Motivation) / motivation_adjustment_time,
      accumulating_tenure    ~ still_employed,
      accumulating_sales     ~ sales,
      accumulating_income    ~ income
    ),
    parameters = sd_parameters(
      constant(motivation_threshold = 0.1, total_effort_available = 200,
               fraction_of_effort_for_sales = 0.25, effort_required_per_sale = 4,
               success_rate = 0.2, months_of_expenses_per_sale = 12 / 50,
               motivation_adjustment_time = 3,
               startup_subsidy = 0.5, startup_subsidy_length = 6),
      initial(Motivation = 1, Tenure = 0,
              TotalCumulativeSales = 0, TotalCumulativeIncome = 0),
      lookup_data("impact_of_motivation_on_effort",
        x = c(0, 0.285132, 0.448065, 0.570265, 0.733198, 0.95723, 1.4664,
              3.19756, 4.03259),
        y = c(0, 0.0616114, 0.232228, 0.492891, 0.772512, 0.862559, 0.914692,
              0.952607, 0.957346))
    ),
    spec = sim_spec(start = 0, stop = 200, dt = 0.0625, method = "euler",
                    time_unit = "month"),
    scenarios = scenarios(
      base   = list(),
      bigger = list(startup_subsidy = 1.5),
      longer = list(startup_subsidy_length = 12),
      both   = list(startup_subsidy = 1.5, startup_subsidy_length = 12)
    )
  )
}

ex_capability_trap <- function() {
  list(
    structure = sd_structure(
      meta(name = "Capability trap"),
      stock("Capability",                  units = "widget/(person*hour)"),
      stock("PressureToDoWork",            units = "1"),
      stock("PressureToImproveCapability", units = "1"),
      lookup("influence_of_work_pressure_on_improvement", input = "PressureToDoWork",
             out_units = "1", interp = "linear", range = "clamp"),
      lookup("influence_of_capability_pressure_on_improvement",
             input = "PressureToImproveCapability",
             out_units = "1", interp = "linear", range = "clamp"),
      lookup("influence_of_pressure_on_work_time", input = "PressureToDoWork",
             out_units = "1", interp = "linear", range = "clamp"),
      aux("time_spent_on_improvement", units = "person*hour/week"),
      aux("time_spent_working",        units = "person*hour/week"),
      aux("actual_performance",        units = "widget/week"),
      aux("desired_performance",       units = "widget/week"),
      aux("stretch",                   units = "1"),
      aux("exogenous_capability_pressure", units = "1/week"),
      flow("investment_in_capability", from = .source,      to = "Capability"),
      flow("capability_erosion",       from = "Capability", to = .sink),
      flow("change_in_pressure_to_do_work", from = .source,
           to = "PressureToDoWork", units = "1/week"),
      flow("change_in_pressure_to_improve", from = .source,
           to = "PressureToImproveCapability", units = "1/week")
    ),
    equations = sd_equations(
      time_spent_on_improvement ~ normal_time_on_improvement *
        influence_of_capability_pressure_on_improvement(PressureToImproveCapability) *
        influence_of_work_pressure_on_improvement(PressureToDoWork),
      time_spent_working ~ min(normal_time_working *
                                 influence_of_pressure_on_work_time(PressureToDoWork),
                               maximum_work_time - time_spent_on_improvement),
      actual_performance  ~ Capability * time_spent_working,
      desired_performance ~ 3000 + step(performance_step, 10),
      stretch             ~ desired_performance / actual_performance,
      investment_in_capability ~ time_spent_on_improvement * capability_per_investment,
      capability_erosion       ~ Capability / erosion_timescale,
      exogenous_capability_pressure ~ step(pressure_step, 10),
      change_in_pressure_to_do_work ~ (stretch - PressureToDoWork) /
                                      work_harder_adjustment_time,
      change_in_pressure_to_improve ~ (stretch - PressureToImproveCapability) /
                                      improve_capability_adjustment_time +
                                      exogenous_capability_pressure
    ),
    parameters = sd_parameters(
      constant(normal_time_on_improvement = 10, normal_time_working = 30,
               maximum_work_time = 40, erosion_timescale = 20,
               capability_per_investment = 0.5,
               work_harder_adjustment_time = 3, improve_capability_adjustment_time = 9,
               performance_step = 0, pressure_step = 0),
      initial(Capability = 100, PressureToDoWork = 1, PressureToImproveCapability = 1),
      lookup_data("influence_of_work_pressure_on_improvement",
        x = c(0, 1, 1.5,  2,    5),
        y = c(1, 1, 0.75, 0.25, 0)),
      lookup_data("influence_of_capability_pressure_on_improvement",
        x = c(0, 0.5, 0.75, 1, 2,   5),
        y = c(0, 0,   0.5,  1, 1.5, 1.5)),
      lookup_data("influence_of_pressure_on_work_time",
        x = c(0,    0.75, 1, 1.25, 2,   10),
        y = c(0.75, 0.75, 1, 1.25, 1.5, 1.5))
    ),
    spec = sim_spec(start = 0, stop = 100, dt = 0.0625, method = "euler",
                    time_unit = "week"),
    scenarios = scenarios(
      equilibrium = list(),
      trap        = list(pressure_step = -0.05),
      escape      = list(pressure_step =  0.1),
      demand      = list(performance_step = 500)
    )
  )
}

ex_boarding_school_flu <- function() {
  list(
    structure = sd_structure(
      meta(name = "Boarding-school flu"),
      stock("S", units = "boys", non_negative = TRUE),
      stock("I", units = "boys", non_negative = TRUE),
      stock("R", units = "boys", non_negative = TRUE),
      aux("lambda", units = "1/day"),
      flow("IR", from = "S", to = "I", units = "boys/day"),
      flow("RR", from = "I", to = "R", units = "boys/day")
    ),
    equations = sd_equations(
      lambda ~ beta * I,
      IR     ~ S * lambda,
      RR     ~ I / infectious_period
    ),
    parameters = sd_parameters(
      constant(beta = 0.001, infectious_period = 2),
      initial(S = 762, I = 1, R = 0)
    ),
    spec = sim_spec(start = 0, stop = 20, dt = 0.125, method = "rk4",
                    time_unit = "day"),
    observed = tidysd::boarding_school_flu,
    map = c(I = "sInfected"),
    calibration = list(
      target = c(I = "sInfected"),
      free   = c("beta", "infectious_period"),
      lower  = c(beta = 0,    infectious_period = 1),
      upper  = c(beta = 0.01, infectious_period = 5)
    )
  )
}

EXAMPLE_NAMES <- c(
  "customer_growth", "s_shaped_growth", "overshoot", "solow", "sir", "bass",
  "cohort_sir", "material_delay", "teacup", "lotka_volterra", "town_population",
  "smooth", "forecast", "delay_fixed", "workforce", "defects", "carbon_bathtub",
  "roessler", "pendulum", "sales_agents", "capability_trap", "boarding_school_flu",
  "customer_growth_piecewise"
)

EXAMPLES <- list(
  customer_growth = ex_customer_growth,
  s_shaped_growth = ex_s_shaped_growth,
  overshoot = ex_overshoot,
  solow = ex_solow,
  sir = ex_sir,
  bass = ex_bass,
  cohort_sir = ex_cohort_sir,
  material_delay = ex_material_delay,
  teacup = ex_teacup,
  lotka_volterra = ex_lotka_volterra,
  town_population = ex_town_population,
  smooth = ex_smooth,
  forecast = ex_forecast,
  delay_fixed = ex_delay_fixed,
  workforce = ex_workforce,
  defects = ex_defects,
  carbon_bathtub = ex_carbon_bathtub,
  roessler = ex_roessler,
  pendulum = ex_pendulum,
  sales_agents = ex_sales_agents,
  capability_trap = ex_capability_trap,
  boarding_school_flu = ex_boarding_school_flu,
  customer_growth_piecewise = ex_customer_growth_piecewise
)
