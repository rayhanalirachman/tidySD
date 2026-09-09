# The parameter layer: the numbers and the data

\`sd_parameters()\` collects \[constant()\], \[reference()\],
\[initial()\], \[lookup_data()\] and \[input_series()\] declarations.

## Usage

``` r
sd_parameters(...)
```

## Arguments

- ...:

  Parameter elements.

## Value

An object of class \`sd_parameters\`.

## Examples

``` r
sd_parameters(
  constant(contact_rate = 6, infectivity = 0.2),
  initial(S = 999, I = 1, R = 0)
)
#> <sd_parameters>
#>   constant  contact_rate                   6
#>   constant  infectivity                    0.2
#>   initial   S                              999
#>   initial   I                              1
#>   initial   R                              0
```
