# Simulation settings

The fourth, non-model layer: when the run starts and stops, the
integration step and method, and how often to save.

## Usage

``` r
sim_spec(
  start = 0,
  stop = 100,
  dt = 1,
  method = c("euler", "rk4"),
  time_unit = NULL,
  saveat = NULL,
  check_units = TRUE
)
```

## Arguments

- start, stop:

  Numeric start and end time.

- dt:

  Integration step.

- method:

  \`"euler"\` or \`"rk4"\`.

- time_unit:

  Name of the time unit (\`"day"\`, \`"year"\`, ...). Used for the
  flow-versus-stock unit check and for axis labels.

- saveat:

  Save interval; defaults to \`dt\` (every step).

- check_units:

  Warn when a flow's declared units disagree with the stock it moves.

## Value

An object of class \`sim_spec\`.

## Examples

``` r
sim_spec(start = 0, stop = 100, dt = 0.125, method = "euler", time_unit = "day")
#> <sim_spec> 0 -> 100, dt = 0.125, euler (day)
```
