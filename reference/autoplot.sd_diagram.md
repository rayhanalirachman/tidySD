# Plot a model diagram

Stocks and flows run left to right in material chains, with the
variables that set each rate above and constants below. A causal loop
diagram is laid out on a circle ordered to keep each feedback loop on
consecutive positions, with loops shaded and badged \`R\` (reinforcing),
\`B\` (balancing) or \`?\` (polarity unknown).

## Usage

``` r
# S3 method for class 'sd_diagram'
autoplot(
  object,
  theme = c("black", "soft", "oi", "plain"),
  initials = NULL,
  title = FALSE,
  legend = TRUE,
  background = NULL,
  colors = NULL,
  ...
)

# S3 method for class 'sd_diagram'
plot(x, ...)
```

## Arguments

- object:

  An \[sd_diagram()\].

- theme:

  \`"black"\` (the default: black ink on light cards, semibold text,
  flow names above their valves, a thin white halo so it also reads on
  dark pages), \`"soft"\` (a restrained slate palette with one blue
  accent), \`"oi"\` (Okabe-Ito, colour-blind safe) or \`"plain"\` (a
  bare layered layout for quick reading).

- initials:

  Optional named numeric (or list) of stock start values, shown as a
  chip on each stock of a stock-and-flow diagram, e.g.
  \`parameters\$initials\`.

- title:

  If \`TRUE\`, a header panel with the model name and a one-line
  summary.

- legend:

  If \`TRUE\` (the default), a key of the glyphs used, on its own small
  panel under the diagram.

- background:

  \`NULL\` (the default) for a transparent page, or a colour. Nodes,
  legend and title carry their own opaque fills, so the diagram reads on
  light and dark pages alike.

- colors:

  Optional named list of overrides merged onto the palette, e.g.
  \`list(stock_fill = "#FFF4D6", link = "grey40")\`. Names are palette
  roles (\`stock_fill\`, \`stock_line\`, \`stock_lw\`, \`info\`, ...);
  \`text\` sets every text colour and \`link\` the influence links.
  Unknown names are an error.

- ...:

  Unused.

- x:

  An \[sd_diagram()\].

## Value

A \`ggplot\` object (also of class \`sd_diagram_plot\`); see
\[save_diagram()\] to write it at its natural size. Printed on a smaller
device or viewport (a plot pane, a knitr chunk), text, lines and arrow
heads shrink with the drawing (to at most half size), so it reads as a
scaled-down copy; at or above the natural size it is drawn as is.

## Details

Text uses the first installed of Inter, Avenir Next, Helvetica Neue,
Helvetica, Arial and DejaVu Sans when 'systemfonts' is installed, and
\`"sans"\` otherwise, or when the open device is \`pdf()\` or
\`postscript()\`. Semibold weights need a 'ragg' (or RStudio, 'svglite',
'httpgd') device. With no device open, the default device decides; if it
is not one of those, the plot uses plain \`"sans"\` so it prints
anywhere, and \[save_diagram()\] redraws it with the full fonts.
Diagrams of more than 30 variables warn once per session that text may
be small.

## Examples

``` r
ex <- sd_example("sir")
d <- sd_diagram(ex$structure, ex$equations, ex$parameters, type = "cld")
p <- autoplot(d)
p2 <- autoplot(d, theme = "soft", colors = list(link = "grey40"))
```
