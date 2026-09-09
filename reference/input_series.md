# An exogenous data series for an input()

An exogenous data series for an input()

## Usage

``` r
input_series(
  name,
  data,
  value_col = NULL,
  interp = c("linear", "constant"),
  range = c("hold", "extend", "na")
)
```

## Arguments

- name:

  Name of the \[input()\] the series drives.

- data:

  A data frame with a \`time\` column (numeric, or \`Date\` – resolved
  against \`sim_spec(start = )\`) and one value column. If it has more
  than two columns, name the value column with \`value_col\`.

- value_col:

  Name of the value column; defaults to the single non-time column, or
  to \`name\` when present.

- interp:

  \`"linear"\` or \`"constant"\` interpolation onto the solver grid.

- range:

  \`"hold"\` (hold the first/last value outside the data range),
  \`"extend"\` (linear extrapolation) or \`"na"\`.

## Value

An \`sd_element\` to be passed to \[sd_parameters()\].
