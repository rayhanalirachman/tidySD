# Boundary of the model

Sentinels for a flow that comes from outside the model boundary
(\`.source\`) or leaves it (\`.sink\`).

## Usage

``` r
.source

.sink
```

## Format

Objects of class \`sd_boundary\`.

## Examples

``` r
flow("births", from = .source, to = "Population")
#> $kind
#> [1] "flow"
#> 
#> $name
#> [1] "births"
#> 
#> $from
#> $which
#> [1] "source"
#> 
#> attr(,"class")
#> [1] "sd_boundary"
#> 
#> $to
#> [1] "Population"
#> 
#> $units
#> NULL
#> 
#> $dims
#> NULL
#> 
#> $label
#> NULL
#> 
#> attr(,"class")
#> [1] "sd_flow"    "sd_element"
```
