# Save a diagram at its natural size

Writes a PNG sized from the diagram's own layout, so that text keeps the
same size whatever the model. Uses 'ragg' when installed, redrawing the
plot with its full fonts if it was built for a device that lacks them.
The PNG is transparent unless a background was given here or to
\[autoplot()\].

## Usage

``` r
save_diagram(p, file, dpi = 200, background = NULL)
```

## Arguments

- p:

  A plot from \[autoplot()\] on an \[sd_diagram()\].

- file:

  Path of the PNG to write; must end in \`.png\`. For PDF or SVG, open
  that device yourself and \`print(p)\`.

- dpi:

  Resolution.

- background:

  \`NULL\` to keep the plot's own (transparent by default), or a colour.

## Value

\`file\`, invisibly.

## Examples

``` r
ex <- sd_example("sir")
p <- autoplot(sd_diagram(ex$structure, ex$equations, ex$parameters))
save_diagram(p, tempfile(fileext = ".png"))
```
