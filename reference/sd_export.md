# Write a bound model out as XMILE

Writes the model to an \`.xmile\` file that Stella, iThink and other
XMILE-compatible tools can open. Only the simulation content is written
– variables, equations, initial values, units, graphical functions and
the simulation settings. No diagram layout is emitted; XMILE's
\`\<views\>\` block is optional and readers lay the model out
themselves.

## Usage

``` r
sd_export(model, path)
```

## Arguments

- model:

  A bound model, from \[sd_validate()\].

- path:

  Path of the \`.xmile\` file to write.

## Value

\`path\`, invisibly.

## Examples

``` r
ex <- sd_example("sir")
bm <- sd_validate(ex$structure, ex$equations, ex$parameters, ex$spec)
file <- tempfile(fileext = ".xmile")
sd_export(bm, file)
```
