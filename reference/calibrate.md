# Estimate free constants from observed data

\`calibrate()\` takes the same three layers as \[simulate()\], plus an
observed data frame, a map from model variable to data column, the
constants that are free to move and their bounds. It does bounded least
squares (\[stats::optim()\], \`"L-BFGS-B"\`) and returns a fitted
\`sd_parameters\` object you pass straight back to \[simulate()\].

## Usage

``` r
calibrate(
  structure,
  equations,
  parameters,
  spec = sim_spec(),
  observed,
  target,
  free,
  lower = NULL,
  upper = NULL,
  weights = NULL,
  control = list()
)
```

## Arguments

- structure:

  An \[sd_structure()\] object.

- equations:

  An \[sd_equations()\] object.

- parameters:

  An \[sd_parameters()\] object.

- spec:

  A \[sim_spec()\] object.

- observed:

  A data frame with a \`time\` column.

- target:

  Named character vector mapping model variable to observed column, e.g.
  \`c(I = "sInfected")\`.

- free:

  Character vector of constants to estimate.

- lower, upper:

  Named numeric bounds for the free constants.

- weights:

  Optional named numeric vector, one weight per target.

- control:

  Passed to \[stats::optim()\].

## Value

An object of class \`sd_calibration\`: \`\$parameters\` (fitted layer),
\`\$fit\` (estimates, SSE, convergence) and \`\$optim\` (the raw
result).

## Details

One verb, not an optimisation framework.
