# Derived initial value

\`init()\` is only meaningful on the left-hand side of a formula inside
\[sd_equations()\]: \`init(S) ~ population - I0\`. Calling it directly
is an error.

## Usage

``` r
init(x)
```

## Arguments

- x:

  A stock name (unquoted).

## Value

Nothing; \`init()\` is syntax, not a function.
