# Declare an auxiliary variable

An auxiliary is computed from other variables at every step; it holds no
state of its own.

## Usage

``` r
aux(name, units = NULL, dims = NULL, label = NULL, doc = NULL)
```

## Arguments

- name:

  Name of the auxiliary.

- units:

  Unit string.

- dims:

  Character vector of subscript dimensions.

- label:

  Optional human-readable label.

- doc:

  Optional one-line description, surfaced by \[sd_equation_table()\].

## Value

An \`sd_element\` to be passed to \[sd_structure()\].
