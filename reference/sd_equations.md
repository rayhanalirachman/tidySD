# The equation layer: functional forms

Each argument is a two-sided formula. The left-hand side is the name of
a flow or auxiliary declared in \[sd_structure()\], or \`init(Stock)\`
to give a stock a \*derived\* initial value. The right-hand side is an
ordinary R expression over other variables, constants, lookups, the
built-ins (\[sd_builtins\]) and numeric literals.

## Usage

``` r
sd_equations(...)
```

## Arguments

- ...:

  Two-sided formulas.

## Value

An object of class \`sd_equations\`.

## Details

Order does not matter: equations are resolved into a dependency graph
when \[simulate()\] binds the layers.

## Examples

``` r
sd_equations(
  beta   ~ contact_rate * infectivity / total_population,
  lambda ~ beta * I,
  IR     ~ S * lambda,
  RR     ~ I / recovery_time
)
#> <sd_equations> 4 equations
#>   beta ~ contact_rate * infectivity/total_population
#>   lambda ~ beta * I
#>   IR ~ S * lambda
#>   RR ~ I/recovery_time
```
