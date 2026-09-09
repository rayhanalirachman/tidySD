# Bind the three layers without integrating

Runs exactly the validation and graph resolution that \[simulate()\]
does, and returns the bound model. Useful for checking a model, or for
inspecting the evaluation order.

## Usage

``` r
sd_validate(structure, equations, parameters, spec = sim_spec())
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

## Value

An object of class \`sd_bound\`.
