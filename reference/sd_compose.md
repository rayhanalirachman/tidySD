# Compose two models into one

Merges two independently written models into a single three-layer model
that runs on one time base. Variables keep their own equations and
parameters; \`link\` wires an output of the first model into the second
by replacing one of its \`aux()\` or \`input()\` "ports".

## Usage

``` r
sd_compose(a, b, link = NULL, prefix = NULL)
```

## Arguments

- a, b:

  Lists with \`structure\`, \`equations\`, \`parameters\` and optionally
  \`spec\` (the shape \[sd_example()\] returns).

- link:

  Named character vector \`c(port_in_b = "variable_in_a")\`. Each named
  port must be an \`aux()\` or \`input()\` of \`b\`; its declaration,
  equation and any \`input_series()\` are dropped and every reference to
  it in \`b\` becomes the named variable of \`a\`.

- prefix:

  Optional length-2 character vector prepended to every variable and
  constant name of \`a\` and \`b\` respectively, e.g. \`c("a\_",
  "b\_")\`. Applied before \`link\`, so \`link\` names the
  already-prefixed variables.

## Value

A list with \`structure\`, \`equations\`, \`parameters\` and \`spec\`,
ready for \[simulate()\].

## Details

The two models must not share variable names – give \`prefix\` to
namespace them if they do.

## Examples

``` r
supply <- list(
  structure = sd_structure(
    stock("Inventory"),
    flow("production", from = .source, to = "Inventory"),
    aux("shipments")
  ),
  equations = sd_equations(production ~ rate, shipments ~ Inventory * 0.1),
  parameters = sd_parameters(constant(rate = 10), initial(Inventory = 100))
)
demand <- list(
  structure = sd_structure(
    stock("Backlog"),
    flow("filling", from = "Backlog", to = .sink),
    aux("deliveries")
  ),
  equations = sd_equations(filling ~ deliveries, deliveries ~ 0),
  parameters = sd_parameters(initial(Backlog = 50))
)
m <- sd_compose(supply, demand, link = c(deliveries = "shipments"))
out <- simulate(m$structure, m$equations, m$parameters,
                spec = sim_spec(0, 10, 1))
```
