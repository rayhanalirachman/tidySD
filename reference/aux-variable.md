# Declare an auxiliary variable

An auxiliary is computed from other variables at every step; it holds no
state of its own.

## Usage

``` r
aux(name, units = NULL, dims = NULL, label = NULL)
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

## Value

An \`sd_element\` to be passed to \[sd_structure()\].
