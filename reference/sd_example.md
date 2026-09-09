# The catalogue of worked models

Every model in the \`tidysd\` catalogue, ready to run. Each is returned
as the three layers plus a \[sim_spec()\] – nothing is pre-simulated, so
you can inspect, edit or re-parameterise any layer before running it.

## Usage

``` r
sd_example(id)

sd_example_ids()
```

## Arguments

- id:

  A number 1-22 or the model's name (see the table).

## Value

An object of class \`sd_example\`: a list with \`structure\`,
\`equations\`, \`parameters\`, \`spec\`, and optionally \`scenarios\`,
\`observed\`, \`map\` and \`calibration\`.

## Details

\| \# \| model \| behaviour \| grammar it exercises \| \|—\|—\|—\|—\| \|
1 \| \`customer_growth\` \| exponential \| boundary flows, constant
fractions \| \| 2 \| \`s_shaped_growth\` \| logistic \| RHS literal,
\`reference()\` \| \| 3 \| \`overshoot\` \| overshoot then decay \|
\`lookup()\`, \`min()\`, \`scenarios()\` \| \| 4 \| \`solow\` \|
goal-seeking \| \`sqrt\`, unspecified units \| \| 5 \| \`sir\` \|
epidemic \| the core grammar \| \| 6 \| \`bass\` \| S-curve \| two
coupled stocks, \`update()\` form-swap \| \| 7 \| \`cohort_sir\` \| 3
coupled waves \| \`subscripts()\`, matrix \`constant()\`, \` \| 8 \|
\`material_delay\` \| exponential approach \| \`step()\`, first-order
delay as a stock \| \| 9 \| \`teacup\` \| exponential decay to a goal \|
the minimal one-stock model \| \| 10 \| \`lotka_volterra\` \| limit
cycle \| nonlinear coupling, \`reference()\` \| \| 11 \|
\`town_population\` \| growth with an aged outflow \| \`subscripts()\`,
\`delayN(order = 8)\` \| \| 12 \| \`smooth\` \| information delay \|
\`smoothN()\` at every order, aux-only \| \| 13 \| \`forecast\` \| trend
extrapolation \| \`forecast()\`, \`ramp()\`, \`delay_fixed()\` \| \| 14
\| \`delay_fixed\` \| exact translation in time \| \`delay_fixed()\`,
variable delay time \| \| 15 \| \`workforce\` \| damped oscillation \|
aging chain, \`lookup()\`, \`min()\` \| \| 16 \| \`defects\` \| pulse
shock \| \`pulse()\`, two lookups on one stock \| \| 17 \|
\`carbon_bathtub\` \| accumulation \| \`input()\` + \`input_series()\`
\| \| 18 \| \`roessler\` \| chaos \| signed net flows, \`method =
"rk4"\` \| \| 19 \| \`pendulum\` \| conservative oscillation \|
second-order system, integrator choice \| \| 20 \| \`sales_agents\` \|
collapse after a subsidy ends \| \`ifelse\` gate, \`scenarios()\` \| \|
21 \| \`capability_trap\` \| irreversible erosion \| lookups multiplied,
\`step()\` in a flow \| \| 22 \| \`boarding_school_flu\` \| SIR fitted
to real data \| \`observed =\`, \`calibrate()\` \|

## Examples

``` r
ex <- sd_example("sir")
out <- simulate(ex$structure, ex$equations, ex$parameters, spec = ex$spec)
```
