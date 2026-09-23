# Declare a flow (rate)

A flow moves material between stocks, or across the model boundary
(\[.source\] / \[.sink\]). A flow whose value goes negative simply runs
backwards – a biflow.

## Usage

``` r
flow(
  name,
  from = .source,
  to = .sink,
  units = NULL,
  dims = NULL,
  label = NULL,
  doc = NULL
)
```

## Arguments

- name:

  Name of the flow.

- from, to:

  Either a stock name or \[.source\] / \[.sink\].

- units:

  Unit string, e.g. \`"people/day"\`.

- dims:

  Character vector of subscript dimensions.

- label:

  Optional human-readable label.

- doc:

  Optional one-line description, surfaced by \[sd_equation_table()\].

## Value

An \`sd_element\` to be passed to \[sd_structure()\].
