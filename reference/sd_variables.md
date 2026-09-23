# The variables a structure declares

A tidy view of the structure layer: one row per declared stock, flow,
auxiliary, lookup or input.

## Usage

``` r
sd_variables(structure, type = NULL)
```

## Arguments

- structure:

  An \[sd_structure()\] object.

- type:

  Optional character vector to filter by (\`"stock"\`, \`"flow"\`,
  \`"aux"\`, \`"lookup"\`, \`"input"\`).

## Value

A tibble with columns \`name\`, \`type\`, \`units\`, \`dims\`, \`from\`,
\`to\`, \`doc\`.

## Examples

``` r
sd_variables(sd_example("sir")$structure)
#> # A tibble: 7 × 7
#>   name   type  units          dims  from  to    doc  
#>   <chr>  <chr> <chr>          <chr> <chr> <chr> <chr>
#> 1 S      stock people         NA    NA    NA    NA   
#> 2 I      stock people         NA    NA    NA    NA   
#> 3 R      stock people         NA    NA    NA    NA   
#> 4 beta   aux   1/(people*day) NA    NA    NA    NA   
#> 5 lambda aux   1/day          NA    NA    NA    NA   
#> 6 IR     flow  people/day     NA    S     I     NA   
#> 7 RR     flow  people/day     NA    I     R     NA   
sd_variables(sd_example("sir")$structure, "stock")
#> # A tibble: 3 × 7
#>   name  type  units  dims  from  to    doc  
#>   <chr> <chr> <chr>  <chr> <chr> <chr> <chr>
#> 1 S     stock people NA    NA    NA    NA   
#> 2 I     stock people NA    NA    NA    NA   
#> 3 R     stock people NA    NA    NA    NA   
```
