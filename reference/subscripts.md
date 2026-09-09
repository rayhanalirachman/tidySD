# Declare a subscript (array) dimension

Declare a subscript (array) dimension

## Usage

``` r
subscripts(...)
```

## Arguments

- ...:

  Named character vectors: \`cohort = c("young", "adult")\`. Each
  becomes a dimension whose members label the array positions and which
  appears as a column in the simulation output.

## Value

An \`sd_element\` to be passed to \[sd_structure()\].

## Examples

``` r
subscripts(cohort = c("young", "adult", "elderly"))
#> $kind
#> [1] "subscripts"
#> 
#> $dims
#> $dims$cohort
#> [1] "young"   "adult"   "elderly"
#> 
#> 
#> attr(,"class")
#> [1] "sd_subscripts" "sd_element"   
```
