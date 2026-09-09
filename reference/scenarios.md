# Named constant overrides for a multi-scenario run

Named constant overrides for a multi-scenario run

## Usage

``` r
scenarios(...)
```

## Arguments

- ...:

  Named lists of constant overrides; an empty list is the base run.

## Value

An object of class \`sd_scenarios\`.

## Examples

``` r
scenarios(base = list(), aggressive = list(fraction_reinvested = 0.14))
#> <sd_scenarios> 2 runs
#>   base           (base)
#>   aggressive     fraction_reinvested = 0.14
```
