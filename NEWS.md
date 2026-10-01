# tidysd (development version)

* `autoplot()` on an `sd_diagram()` draws a laid-out diagram: material chains
  with pipes, valves and clouds for a stock-and-flow diagram; a circular layout
  with shaded, badged feedback loops for a causal loop diagram. `theme =
  "black"` (default: black ink, semibold text, continuous corners, flow names
  above their valves, a thin halo so it reads on dark pages), `"soft"`,
  `"oi"` (Okabe-Ito) or `"plain"` (the old layered plot); `initials =` puts
  start values on stocks; `colors = list(...)` overrides palette roles.
  The page is transparent unless `background =` is set; `title = TRUE` adds a
  header, `legend = FALSE` drops the key. `save_diagram()` writes it as a
  PNG at its natural size.
* `sd_diagram(type = "cld")` now links each flow to its stocks (`+` into the
  stock it fills, `-` into the one it drains), so loops through stocks close.
* `sd_diagram()` no longer needs `equations`; without them it gives the
  stock-and-flow wiring alone. It now errors clearly when given something
  other than the model layers (e.g. a whole `sd_example()`) or an empty
  structure.
* A diagram built with no device open uses plain `"sans"` unless the default
  device is ragg-capable, so it prints on `pdf()` and `png()` without errors
  or warnings; `save_diagram()` redraws it with the full fonts. `colors =`
  values are checked up front, `save_diagram()` refuses non-`.png` files, and
  diagrams of more than 30 variables warn once that text may be small.
* Stock-and-flow layouts get a repair pass: when an influence link would cross
  another link or run through a variable, that variable is moved and the links
  re-routed, keeping the change only if the diagram gets cleaner.

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
