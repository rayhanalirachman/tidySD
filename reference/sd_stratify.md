# Stratify a model over a group dimension

Turns an unsubscripted (or partly subscripted) model into one that runs
the same structure once per group, by declaring a new \[subscripts()\]
dimension and adding it to every stock, flow, auxiliary and input. The
equations are untouched – an arrayed variable is a vector, and the
arithmetic recycles – so a scalar \[constant()\] applies to every group
and a vector of one value per group makes the groups differ.

## Usage

``` r
sd_stratify(model, by, except = NULL)
```

## Arguments

- model:

  An \[sd_structure()\], or a list with a \`structure\` element (what
  \[sd_example()\] returns); the other layers are passed through
  unchanged.

- by:

  A named list of dimensions to add, e.g. \`list(region = c("north",
  "south"))\`.

- except:

  Names of variables to leave unstratified – typically whole-model
  aggregates such as \`total ~ sum(I)\`. \[lookup()\]s are always left
  alone.

## Value

The same kind of object that was passed in.

## Examples

``` r
ex <- sd_example("sir")
st <- sd_stratify(ex$structure, by = list(region = c("north", "south")),
                  except = "beta")
sd_variables(st, "stock")
#> # A tibble: 3 × 7
#>   name  type  units  dims   from  to    doc  
#>   <chr> <chr> <chr>  <chr>  <chr> <chr> <chr>
#> 1 S     stock people region NA    NA    NA   
#> 2 I     stock people region NA    NA    NA   
#> 3 R     stock people region NA    NA    NA   
```
