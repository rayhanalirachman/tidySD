# Declare a graphical (lookup) function

The points come from \[lookup_data()\] in the parameter layer; the
structure layer only says that the function exists, what it reads, and
how it behaves outside the tabulated range.

## Usage

``` r
lookup(
  name,
  input = NULL,
  in_units = NULL,
  out_units = NULL,
  interp = c("linear", "constant"),
  range = c("clamp", "extend", "na"),
  label = NULL
)
```

## Arguments

- name:

  Name of the lookup; it is callable on an equation right-hand side,
  e.g. \`extr_efficiency(Resource)\`.

- input:

  Name of the variable it is normally read with (documentation and
  diagramming only).

- in_units, out_units:

  Unit strings for the horizontal and vertical axes.

- interp:

  \`"linear"\` or \`"constant"\` (step) interpolation.

- range:

  \`"clamp"\` (hold the end values, the Vensim default) or \`"extend"\`
  (linear extrapolation) or \`"na"\`.

- label:

  Optional human-readable label.

## Value

An \`sd_element\` to be passed to \[sd_structure()\].
