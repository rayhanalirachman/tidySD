# Bind the layers, validate, integrate

\`simulate()\` is the single verb: it binds \[sd_structure()\],
\[sd_equations()\] and \[sd_parameters()\], validates them against each
other, resolves the equations into a dependency graph, integrates, and
returns one long-format tibble.

## Usage

``` r
simulate(
  structure,
  equations,
  parameters,
  spec = sim_spec(),
  scenarios = NULL,
  observed = NULL,
  map = NULL,
  ...
)

sd_simulate(
  structure,
  equations,
  parameters,
  spec = sim_spec(),
  scenarios = NULL,
  observed = NULL,
  map = NULL,
  ...
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

- scenarios:

  Optional \[scenarios()\] object: named lists of constant overrides,
  each run separately and tagged in a \`scenario\` column.

- observed:

  Optional data frame with a \`time\` column, stacked into the output
  tagged \`source = "observed"\` beside \`"model"\`.

- map:

  Named character vector mapping model variables to \`observed\`
  columns, e.g. \`c(I = "cases")\`. Defaults to matching column names.

- ...:

  Unused; present so that misspelled arguments are caught.

## Value

A tibble of class \`sd_result\` with columns \`scenario\` (when
scenarios were given), one column per subscript dimension, \`time\`,
\`variable\`, \`value\`, \`unit\`, \`type\`, and \`source\` (when
\`observed\` was given).

## Details

\`tidysd::simulate()\` masks \[stats::simulate()\]. \`sd_simulate()\` is
an identical, non-masking alias.

## Examples

``` r
out <- simulate(
  sd_structure(
    stock("Customers", units = "customers"),
    flow("recruits", from = .source, to = "Customers", units = "customers/year"),
    flow("losses", from = "Customers", to = .sink, units = "customers/year")
  ),
  sd_equations(
    recruits ~ Customers * growth_fraction,
    losses   ~ Customers * decline_fraction
  ),
  sd_parameters(
    constant(growth_fraction = 0.08, decline_fraction = 0.03),
    initial(Customers = 10000)
  ),
  spec = sim_spec(start = 2015, stop = 2030, dt = 0.25, time_unit = "year")
)
head(out)
#> # A tibble: 6 × 5
#>    time variable   value unit      type 
#>   <dbl> <chr>      <dbl> <chr>     <chr>
#> 1 2015  Customers 10000  customers stock
#> 2 2015. Customers 10125  customers stock
#> 3 2016. Customers 10252. customers stock
#> 4 2016. Customers 10380. customers stock
#> 5 2016  Customers 10509. customers stock
#> 6 2016. Customers 10641. customers stock
```
