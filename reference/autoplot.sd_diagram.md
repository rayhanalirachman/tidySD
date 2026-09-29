# Plot a model diagram

Stocks and flows run left to right in material chains, with the
variables that set each rate above and constants below. A causal loop
diagram is laid out on a circle ordered to keep each feedback loop on
consecutive positions, with loops shaded and badged \`R\` (reinforcing),
\`B\` (balancing) or \`?\` (polarity unknown).

## Usage

``` r
# S3 method for class 'sd_diagram'
autoplot(object, theme = c("soft", "oi", "plain"), initials = NULL, ...)

# S3 method for class 'sd_diagram'
plot(x, ...)
```

## Arguments

- object:

  An \[sd_diagram()\].

- theme:

  \`"soft"\` (a restrained slate palette with one blue accent), \`"oi"\`
  (Okabe-Ito, colour-blind safe) or \`"plain"\` (a bare layered layout
  for quick reading).

- initials:

  Optional named numeric (or list) of stock start values, shown as a
  chip on each stock of a stock-and-flow diagram, e.g.
  \`parameters\$initials\`.

- ...:

  Unused.

- x:

  An \[sd_diagram()\].

## Value

A \`ggplot\` object; see \[save_diagram()\] to write it at its natural
size.

## Details

Text uses the first installed of Inter, Avenir Next, Helvetica Neue,
Helvetica, Arial and DejaVu Sans when 'systemfonts' is installed, and
\`"sans"\` otherwise, or when the open device is \`pdf()\` or
\`postscript()\`.

## Examples

``` r
ex <- sd_example("sir")
d <- sd_diagram(ex$structure, ex$equations, ex$parameters, type = "cld")
p <- autoplot(d)
```
