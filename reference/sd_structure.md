# The structure layer: what exists and how it is wired

\`sd_structure()\` collects \[stock()\], \[flow()\], \[aux()\],
\[lookup()\], \[input()\], \[subscripts()\] and \[meta()\] declarations.
It carries no mathematics – only names, wiring, dimensions and units.

## Usage

``` r
sd_structure(...)
```

## Arguments

- ...:

  Structure elements.

## Value

An object of class \`sd_structure\`.

## Examples

``` r
sd_structure(
  meta(name = "Customer growth"),
  stock("Customers", units = "customers", non_negative = TRUE),
  flow("recruits", from = .source, to = "Customers", units = "customers/year"),
  flow("losses", from = "Customers", to = .sink, units = "customers/year")
)
#> <sd_structure> Customer growth
#>   stock  Customers  non-negative  [customers]
#>   flow   recruits  .source -> Customers  [customers/year]
#>   flow   losses  Customers -> .sink  [customers/year]
```
