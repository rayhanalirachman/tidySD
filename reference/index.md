# Package index

## The three layers

What exists and how it is wired; the functional forms; the numbers and
data.

- [`sd_structure()`](https://rayhanalirachman.github.io/tidySD/reference/sd_structure.md)
  : The structure layer: what exists and how it is wired
- [`sd_equations()`](https://rayhanalirachman.github.io/tidySD/reference/sd_equations.md)
  : The equation layer: functional forms
- [`sd_parameters()`](https://rayhanalirachman.github.io/tidySD/reference/sd_parameters.md)
  : The parameter layer: the numbers and the data

### Structure elements

- [`meta()`](https://rayhanalirachman.github.io/tidySD/reference/meta.md)
  : Model metadata
- [`stock()`](https://rayhanalirachman.github.io/tidySD/reference/stock.md)
  : Declare a stock (level)
- [`flow()`](https://rayhanalirachman.github.io/tidySD/reference/flow.md)
  : Declare a flow (rate)
- [`lookup()`](https://rayhanalirachman.github.io/tidySD/reference/lookup.md)
  : Declare a graphical (lookup) function
- [`input()`](https://rayhanalirachman.github.io/tidySD/reference/input.md)
  : Declare an exogenous data driver
- [`subscripts()`](https://rayhanalirachman.github.io/tidySD/reference/subscripts.md)
  : Declare a subscript (array) dimension
- [`.source`](https://rayhanalirachman.github.io/tidySD/reference/dot-source.md)
  [`.sink`](https://rayhanalirachman.github.io/tidySD/reference/dot-source.md)
  : Boundary of the model
- [`aux()`](https://rayhanalirachman.github.io/tidySD/reference/aux-variable.md)
  : Declare an auxiliary variable
- [`sd_variables()`](https://rayhanalirachman.github.io/tidySD/reference/sd_variables.md)
  : The variables a structure declares

### Equation elements

- [`init()`](https://rayhanalirachman.github.io/tidySD/reference/init.md)
  : Derived initial value
- [`update(`*`<sd_equations>`*`)`](https://rayhanalirachman.github.io/tidySD/reference/update.sd_equations.md)
  : Replace or add equations
- [`sd_builtins`](https://rayhanalirachman.github.io/tidySD/reference/sd_builtins.md)
  : Built-in functions on an equation right-hand side

### Parameter elements

- [`constant()`](https://rayhanalirachman.github.io/tidySD/reference/constant.md)
  : Constants
- [`reference()`](https://rayhanalirachman.github.io/tidySD/reference/reference.md)
  : Normalising reference values
- [`initial()`](https://rayhanalirachman.github.io/tidySD/reference/initial.md)
  : Stock initial values
- [`lookup_data()`](https://rayhanalirachman.github.io/tidySD/reference/lookup_data.md)
  : Points for a graphical (lookup) function
- [`input_series()`](https://rayhanalirachman.github.io/tidySD/reference/input_series.md)
  : An exogenous data series for an input()
- [`update(`*`<sd_parameters>`*`)`](https://rayhanalirachman.github.io/tidySD/reference/update.sd_parameters.md)
  : Replace or add parameters

## Running a model

- [`simulate()`](https://rayhanalirachman.github.io/tidySD/reference/simulate.md)
  [`sd_simulate()`](https://rayhanalirachman.github.io/tidySD/reference/simulate.md)
  : Bind the layers, validate, integrate
- [`sim_spec()`](https://rayhanalirachman.github.io/tidySD/reference/sim_spec.md)
  : Simulation settings
- [`scenarios()`](https://rayhanalirachman.github.io/tidySD/reference/scenarios.md)
  : Named constant overrides for a multi-scenario run
- [`sd_validate()`](https://rayhanalirachman.github.io/tidySD/reference/sd_validate.md)
  : Bind the three layers without integrating
- [`calibrate()`](https://rayhanalirachman.github.io/tidySD/reference/calibrate.md)
  : Estimate free constants from observed data

## Looking at a model

- [`autoplot(`*`<sd_result>`*`)`](https://rayhanalirachman.github.io/tidySD/reference/autoplot.sd_result.md)
  [`plot(`*`<sd_result>`*`)`](https://rayhanalirachman.github.io/tidySD/reference/autoplot.sd_result.md)
  : Plot a simulation result
- [`sd_diagram()`](https://rayhanalirachman.github.io/tidySD/reference/sd_diagram.md)
  : Diagrams as functions of the model
- [`autoplot(`*`<sd_diagram>`*`)`](https://rayhanalirachman.github.io/tidySD/reference/autoplot.sd_diagram.md)
  [`plot(`*`<sd_diagram>`*`)`](https://rayhanalirachman.github.io/tidySD/reference/autoplot.sd_diagram.md)
  : Plot a model diagram

## The catalogue

- [`sd_example()`](https://rayhanalirachman.github.io/tidySD/reference/sd_example.md)
  [`sd_example_ids()`](https://rayhanalirachman.github.io/tidySD/reference/sd_example.md)
  : The catalogue of worked models
- [`sd_example_run()`](https://rayhanalirachman.github.io/tidySD/reference/sd_example_run.md)
  : Run a catalogue model
- [`boarding_school_flu`](https://rayhanalirachman.github.io/tidySD/reference/boarding_school_flu.md)
  : Boarding-school influenza, England, 1978
- [`town_population`](https://rayhanalirachman.github.io/tidySD/reference/town_population.md)
  : Synthetic town populations
- [`global_emissions_synthetic`](https://rayhanalirachman.github.io/tidySD/reference/global_emissions_synthetic.md)
  : Synthetic global emissions series

## Package

- [`tidysd`](https://rayhanalirachman.github.io/tidySD/reference/tidysd-package.md)
  [`tidysd-package`](https://rayhanalirachman.github.io/tidySD/reference/tidysd-package.md)
  : tidysd: a tidy grammar for system dynamics
