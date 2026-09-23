# The equation table: every variable with its formula

One row per declared variable (plus any constant the parameter layer
adds), with the equation deparsed back to text, its units and its \`doc
=\` string. It is \[sd_variables()\] with the equation layer joined on.

## Usage

``` r
sd_equation_table(structure, equations, parameters = sd_parameters())
```

## Arguments

- structure:

  An \[sd_structure()\] object.

- equations:

  An \[sd_equations()\] object.

- parameters:

  An \[sd_parameters()\] object; supplies stock initial values and
  constants. Defaults to an empty layer.

## Value

A tibble: the \[sd_variables()\] columns plus \`equation\`.

## Examples

``` r
ex <- sd_example("sir")
sd_equation_table(ex$structure, ex$equations, ex$parameters)
#> # A tibble: 11 × 8
#>    name             type     equation              units doc   dims  from  to   
#>    <chr>            <chr>    <chr>                 <chr> <chr> <chr> <chr> <chr>
#>  1 S                stock    999                   peop… NA    NA    NA    NA   
#>  2 I                stock    1                     peop… NA    NA    NA    NA   
#>  3 R                stock    0                     peop… NA    NA    NA    NA   
#>  4 beta             aux      contact_rate * infec… 1/(p… NA    NA    NA    NA   
#>  5 lambda           aux      beta * I              1/day NA    NA    NA    NA   
#>  6 IR               flow     S * lambda            peop… NA    NA    S     I    
#>  7 RR               flow     I/recovery_time       peop… NA    NA    I     R    
#>  8 contact_rate     constant 6                     NA    NA    NA    NA    NA   
#>  9 infectivity      constant 0.2                   NA    NA    NA    NA    NA   
#> 10 total_population constant 1000                  NA    NA    NA    NA    NA   
#> 11 recovery_time    constant 5                     NA    NA    NA    NA    NA   
```
