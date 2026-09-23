# Import a model from an XMILE or Vensim file

Reads an XMILE model (\`.xmile\`, \`.stmx\`, \`.itmx\`, \`.xml\` – the
interchange format written by Stella, Vensim, InsightMaker and friends)
or a Vensim text model (\`.mdl\`) and returns the three tidysd layers
plus a \[sim_spec()\], ready for \[simulate()\].

## Usage

``` r
sd_import(path)
```

## Arguments

- path:

  Path to the file. The format is taken from the extension.

## Value

A list with \`structure\`, \`equations\`, \`parameters\` and \`spec\`,
to be passed to \[simulate()\] or \[sd_validate()\].

## Details

Stocks, flows, auxiliaries, graphical (lookup) functions, initial
values, units and the simulation specs are read. Diagram information is
not. An auxiliary whose equation is a bare number becomes a
\[constant()\]; every other auxiliary becomes an \[aux()\] with an
equation.

Arrayed (subscripted) models, submodules and conveyors/queues are
rejected rather than silently mis-translated.

## Examples

``` r
m <- sd_import(system.file("extdata", "sir.xmile", package = "tidysd"))
sd_variables(m$structure)
#> # A tibble: 8 × 7
#>   name               type  units       dims  from        to        doc  
#>   <chr>              <chr> <chr>       <chr> <chr>       <chr>     <chr>
#> 1 Susceptible        stock people      NA    NA          NA        NA   
#> 2 Infected           stock people      NA    NA          NA        NA   
#> 3 Recovered          stock people      NA    NA          NA        NA   
#> 4 infection_rate     flow  people/Days NA    Susceptible Infected  NA   
#> 5 recovery_rate      flow  people/Days NA    Infected    Recovered NA   
#> 6 force_of_infection aux   NA          NA    NA          NA        NA   
#> 7 total_population   aux   people      NA    NA          NA        NA   
#> 8 recovery_time      aux   Days        NA    NA          NA        NA   
out <- simulate(m$structure, m$equations, m$parameters, spec = m$spec)
head(out)
#> # SIR
#> # A tibble: 6 × 5
#>    time variable    value unit   type 
#>   <dbl> <chr>       <dbl> <chr>  <chr>
#> 1  0    Susceptible  999  people stock
#> 2  0.25 Susceptible  999. people stock
#> 3  0.5  Susceptible  998. people stock
#> 4  0.75 Susceptible  998. people stock
#> 5  1    Susceptible  997. people stock
#> 6  1.25 Susceptible  996. people stock
```
