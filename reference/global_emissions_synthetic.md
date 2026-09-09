# Synthetic global emissions series

A deterministic, synthetic stand-in for the CDIAC global fossil-fuel and
cement emissions series (Boden, Marland and Andres, 1751-2011), which is
not redistributed with tidysd. Same shape and scale: near-zero through
the 18th century, industrial-era exponential growth, a mid-20th-century
acceleration.

## Usage

``` r
global_emissions_synthetic
```

## Format

A data frame with 261 rows and 2 columns:

- time:

  Year.

- emissions:

  Emissions, MtC/year.

## See also

\`sd_example("carbon_bathtub")\`
