# Sweep constants: Monte Carlo draws or a full-factorial grid

A thin wrapper around the \[scenarios()\] runner for sensitivity
analysis. Each \`...\` argument names a constant and says how to vary
it:

## Usage

``` r
sd_sweep(
  structure,
  equations,
  parameters,
  spec = sim_spec(),
  ...,
  n = 100,
  method = c("random", "grid")
)
```

## Arguments

- structure:

  An \[sd_structure()\] object.

- equations:

  An \[sd_equations()\] object.

- parameters:

  An \[sd_parameters()\] object.

- spec:

  A \[sim_spec()\] object.

- ...:

  Named constants to sweep, as described above.

- n:

  Number of draws (\`"random"\`), or levels per range (\`"grid"\`).

- method:

  \`"random"\` for Monte Carlo, \`"grid"\` for full factorial.

## Value

A tibble of class \`sd_result\` in the usual long format, with a
\`.run\` column identifying the draw and one column per swept constant
holding the value used in that run.

## Details

\* a \*\*function\*\*, called as \`f(n)\` – e.g. \`function(n) rnorm(n,
0.08, 0.01)\` (\`method = "random"\` only); \* a \*\*length-2
numeric\*\*, a range – drawn with \[stats::runif()\] when \`method =
"random"\`, or cut into \`n\` levels with \[seq()\] when \`method =
"grid"\`; \* \*\*any other vector\*\*, a set of values – sampled with
replacement when \`method = "random"\`, or used as the grid levels as
given.

\`method = "grid"\` runs every combination (\[expand.grid()\]), so the
number of runs is the product of the level counts, not \`n\`.

## Examples

``` r
ex <- sd_example("customer_growth")
mc <- sd_sweep(ex$structure, ex$equations, ex$parameters, spec = ex$spec,
               growth_fraction = c(0.05, 0.11), n = 20)
head(mc)
#> # Customer growth
#> # A tibble: 6 × 7
#>    .run growth_fraction  time variable   value unit      type 
#>   <int>           <dbl> <dbl> <chr>      <dbl> <chr>     <chr>
#> 1     1          0.0548 2015  Customers 10000  customers stock
#> 2     1          0.0548 2015. Customers 10062. customers stock
#> 3     1          0.0548 2016. Customers 10125. customers stock
#> 4     1          0.0548 2016. Customers 10187. customers stock
#> 5     1          0.0548 2016  Customers 10251. customers stock
#> 6     1          0.0548 2016. Customers 10314. customers stock

grid <- sd_sweep(ex$structure, ex$equations, ex$parameters, spec = ex$spec,
                 growth_fraction = c(0.05, 0.11),
                 decline_fraction = c(0.02, 0.03, 0.04),
                 n = 3, method = "grid")
length(unique(grid$.run))
#> [1] 9
```
