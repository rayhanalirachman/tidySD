# Diagrams as functions of the model

\`sd_diagram()\` reads the wiring out of the bound model rather than
asking you to draw it. \`type = "sfd"\` gives the stock-and-flow diagram
(stocks, flows, and the variables that set each rate); \`type = "cld"\`
gives the causal loop diagram (every variable, one edge per dependency,
signed where the sign is unambiguous).

## Usage

``` r
sd_diagram(
  structure,
  equations,
  parameters = sd_parameters(),
  type = c("sfd", "cld")
)
```

## Arguments

- structure:

  An \[sd_structure()\] object.

- equations:

  An \[sd_equations()\] object.

- parameters:

  An \[sd_parameters()\] object; needed only so that lookups and inputs
  resolve. Defaults to an empty layer.

- type:

  \`"sfd"\` or \`"cld"\`.

## Value

An object of class \`sd_diagram\`: a list of \`nodes\` and \`edges\`
tibbles, with \[autoplot()\] and \`plot()\` methods.
