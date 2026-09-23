# Changelog

## tidysd 0.1.0

First release.

- Three independent model layers –
  [`sd_structure()`](https://rayhanalirachman.github.io/tidySD/reference/sd_structure.md),
  [`sd_equations()`](https://rayhanalirachman.github.io/tidySD/reference/sd_equations.md),
  [`sd_parameters()`](https://rayhanalirachman.github.io/tidySD/reference/sd_parameters.md)
  – bound and validated inside a single
  [`simulate()`](https://rayhanalirachman.github.io/tidySD/reference/simulate.md)
  verb.
- [`stock()`](https://rayhanalirachman.github.io/tidySD/reference/stock.md),
  [`flow()`](https://rayhanalirachman.github.io/tidySD/reference/flow.md),
  [`aux()`](https://rayhanalirachman.github.io/tidySD/reference/aux-variable.md),
  [`lookup()`](https://rayhanalirachman.github.io/tidySD/reference/lookup.md),
  [`input()`](https://rayhanalirachman.github.io/tidySD/reference/input.md),
  [`subscripts()`](https://rayhanalirachman.github.io/tidySD/reference/subscripts.md),
  [`meta()`](https://rayhanalirachman.github.io/tidySD/reference/meta.md)
  in the structure layer; `.source` and `.sink` for boundary flows.
- Equations are order-independent: they resolve into a dependency graph
  at run time, and a simultaneous loop is reported with the cycle that
  caused it.
- Built-ins on an equation right-hand side: `delayN()`, `smoothN()`,
  `delay_fixed()`, `forecast()`, `previous()`,
  [`step()`](https://rdrr.io/r/stats/step.html), `pulse()`, `ramp()`,
  `t` and `dt`, alongside base-R maths.
- Subscripted (arrayed) models over named dimensions, including matrix
  constants and `%*%` contraction; subscripts come back as output
  columns.
- Euler and RK4 integrators, `saveat` thinning, `non_negative` stocks,
  and a flow-versus-stock unit check.
- [`sd_import()`](https://rayhanalirachman.github.io/tidySD/reference/sd_import.md)
  reads an XMILE file (`.xmile`, `.stmx`) into the three layers plus a
  [`sim_spec()`](https://rayhanalirachman.github.io/tidySD/reference/sim_spec.md).
- Real data:
  [`input_series()`](https://rayhanalirachman.github.io/tidySD/reference/input_series.md)
  drivers, `observed =` overlays, and
  [`calibrate()`](https://rayhanalirachman.github.io/tidySD/reference/calibrate.md)
  for bounded least-squares estimation of free constants.
- Tidy long-format output with
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html),
  [`summary()`](https://rdrr.io/r/base/summary.html) and
  [`print()`](https://rdrr.io/r/base/print.html) methods, plus
  [`sd_diagram()`](https://rayhanalirachman.github.io/tidySD/reference/sd_diagram.md)
  for stock-and-flow and causal-loop diagrams read out of the model.
- A catalogue of 22 worked models,
  [`sd_example()`](https://rayhanalirachman.github.io/tidySD/reference/sd_example.md)
  /
  [`sd_example_run()`](https://rayhanalirachman.github.io/tidySD/reference/sd_example_run.md),
  each verified against an independently hand-coded integration of the
  original.
