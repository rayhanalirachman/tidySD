# tidysd 0.1.0

First release.

* Three independent model layers -- `sd_structure()`, `sd_equations()`,
  `sd_parameters()` -- bound and validated inside a single `simulate()` verb.
* `stock()`, `flow()`, `aux()`, `lookup()`, `input()`, `subscripts()`, `meta()`
  in the structure layer; `.source` and `.sink` for boundary flows.
* Equations are order-independent: they resolve into a dependency graph at run
  time, and a simultaneous loop is reported with the cycle that caused it.
* Built-ins on an equation right-hand side: `delayN()`, `smoothN()`,
  `delay_fixed()`, `forecast()`, `previous()`, `step()`, `pulse()`, `ramp()`,
  `t` and `dt`, alongside base-R maths.
* Subscripted (arrayed) models over named dimensions, including matrix
  constants and `%*%` contraction; subscripts come back as output columns.
* Euler and RK4 integrators, `saveat` thinning, `non_negative` stocks, and a
  flow-versus-stock unit check.
* `sd_import()` reads an XMILE file (`.xmile`, `.stmx`) into the three layers
  plus a `sim_spec()`.
* Real data: `input_series()` drivers, `observed =` overlays, and `calibrate()`
  for bounded least-squares estimation of free constants.
* Tidy long-format output with `autoplot()`, `summary()` and `print()` methods,
  plus `sd_diagram()` for stock-and-flow and causal-loop diagrams read out of
  the model.
* A catalogue of 22 worked models, `sd_example()` / `sd_example_run()`, each
  verified against an independently hand-coded integration of the original.
