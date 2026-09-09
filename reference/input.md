# Declare an exogenous data driver

An \`input()\` is an auxiliary whose values come from data rather than
from a formula. The series itself is supplied by \[input_series()\] in
the parameter layer.

## Usage

``` r
input(name, units = NULL, dims = NULL, label = NULL)
```

## Arguments

- name:

  Name of the driver.

- units:

  Unit string.

- dims:

  Character vector of subscript dimensions.

- label:

  Optional human-readable label.

## Value

An \`sd_element\` to be passed to \[sd_structure()\].
