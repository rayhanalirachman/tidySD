# Run a catalogue model

Run a catalogue model

## Usage

``` r
sd_example_run(id, ...)
```

## Arguments

- id:

  A number 1-22 or the model's name.

- ...:

  Passed to \[simulate()\], overriding the example's own arguments.

## Value

An \`sd_result\` tibble.

## Examples

``` r
out <- sd_example_run("teacup")
```
