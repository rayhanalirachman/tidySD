# Replace or add equations

Layers are immutable: \`update()\` returns a new \`sd_equations\` object
with the given formulas replacing (by left-hand side) or extending the
existing ones.

## Usage

``` r
# S3 method for class 'sd_equations'
update(object, ...)
```

## Arguments

- object:

  An \`sd_equations\` object.

- ...:

  Two-sided formulas.

## Value

A new \`sd_equations\` object.

## Examples

``` r
e <- sd_equations(lambda ~ beta * I, IR ~ S * lambda)
update(e, lambda ~ contact_rate * infectivity * I)
#> <sd_equations> 2 equations
#>   lambda ~ contact_rate * infectivity * I
#>   IR ~ S * lambda
```
