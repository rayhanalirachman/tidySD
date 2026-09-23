# Declare a stock (level)

A stock accumulates: its value changes only through the flows wired to
it.

## Usage

``` r
stock(
  name,
  units = NULL,
  dims = NULL,
  non_negative = FALSE,
  label = NULL,
  doc = NULL
)
```

## Arguments

- name:

  Name of the stock.

- units:

  Unit string, e.g. \`"people"\`. Unspecified units are not checked.

- dims:

  Character vector of subscript dimensions the stock is arrayed over.

- non_negative:

  If \`TRUE\`, the stock is clamped at zero after each step.

- label:

  Optional human-readable label.

- doc:

  Optional one-line description, surfaced by \[sd_equation_table()\].

## Value

An \`sd_element\` to be passed to \[sd_structure()\].
