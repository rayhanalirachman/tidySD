# Replace or add parameters

Replace or add parameters

## Usage

``` r
# S3 method for class 'sd_parameters'
update(object, ...)
```

## Arguments

- object:

  An \`sd_parameters\` object.

- ...:

  Parameter elements, or named numeric values (treated as constants).

## Value

A new \`sd_parameters\` object.

## Examples

``` r
p <- sd_parameters(constant(a = 1), initial(S = 10))
update(p, constant(a = 2))
#> <sd_parameters>
#>   constant  a                              2
#>   initial   S                              10
update(p, a = 3)
#> <sd_parameters>
#>   constant  a                              3
#>   initial   S                              10
```
