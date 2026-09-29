# Save a diagram at its natural size

Writes a PNG sized from the diagram's own layout, so that text keeps the
same size whatever the model. Uses 'ragg' when installed.

## Usage

``` r
save_diagram(p, file, dpi = 200)
```

## Arguments

- p:

  A plot from \[autoplot()\] on an \[sd_diagram()\].

- file:

  Path of the PNG to write.

- dpi:

  Resolution.

## Value

\`file\`, invisibly.

## Examples

``` r
ex <- sd_example("sir")
p <- autoplot(sd_diagram(ex$structure, ex$equations, ex$parameters))
save_diagram(p, tempfile(fileext = ".png"))
```
