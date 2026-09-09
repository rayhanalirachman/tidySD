# Plot a simulation result

The tidy output means the plot comes free. By default every variable
gets a panel; give \`x\` and \`y\` for a phase portrait instead.

## Usage

``` r
# S3 method for class 'sd_result'
autoplot(
  object,
  vars = NULL,
  x = NULL,
  y = NULL,
  facet = c("variable", "scenario", "both", "none"),
  scales = "free_y",
  ...
)

# S3 method for class 'sd_result'
plot(x, ...)
```

## Arguments

- object:

  An \`sd_result\` from \[simulate()\].

- vars:

  Character vector of variables to keep. Defaults to every stock and
  flow when the model has any stocks, otherwise every variable.

- x, y:

  For \`autoplot()\`, variable names for a phase portrait; when given,
  \`vars\` is ignored. For \`plot()\`, \`x\` is the \`sd_result\`
  itself.

- facet:

  One of \`"variable"\` (default), \`"scenario"\`, \`"both"\` or
  \`"none"\`.

- scales:

  Passed to \[ggplot2::facet_wrap()\].

- ...:

  Unused.

## Value

A \`ggplot\` object.
