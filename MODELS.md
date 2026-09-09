# tidysd — principles and model catalogue

`tidysd` is a proposed R grammar for tidy system dynamics modelling. This file is
the single reference: the design philosophy first, then Jim Duggan's worked
models expressed in it next to their original `deSolve` code.

Nothing is implemented. These are grammar specimens — the philosophy sets the
direction, the models show it meeting reality. Duggan's code is from
[`JimDuggan/SDMR`](https://github.com/JimDuggan/SDMR), MIT © 2016 Jim Duggan;
only unrelated plotting is trimmed.

---

## Philosophy

Specify a stock-and-flow model as **three independent layers**, simulate with one
verb. Design DNA from [`seminr`](https://github.com/sem-in-r/seminr): constructor
functions named after domain terms, models that are plain inspectable data,
sub-models declared separately and bound only at run time.

```
sd_structure()    what exists, how it is wired      (no math)
sd_equations()    functional forms                  (symbolic)
sd_parameters()   the numbers and data

simulate(structure, equations, parameters, spec = sim_spec())
    -> binds, validates, integrates, returns one long tibble
```

No compile step — binding and validation happen inside `simulate()`. The "model"
is just the three layer objects.

### Principles

- **Readable** — a model reads as a specification, not a build script.
- **Layered** — swap or reuse any one layer without touching the others.
- **Tidy output** — one long-format tibble per run; `ggplot2` methods come free.
- **No hidden state** — layers are immutable; a variant is a new object.
- **Diagrams from the model** — the stock-and-flow and causal-loop diagrams are
  functions of the model, not drawn separately.
- **Domain vocabulary** — `stock()`, `flow()`, `aux()`; never matrix builders.
- **Order-independent** — equations resolve to a dependency graph at run time.

### What goes in which layer

| Item | Structure | Equations | Parameters |
|---|:--:|:--:|:--:|
| Stock / flow / aux / lookup / input exists; its units | ✅ | | |
| Flow `from` / `to` wiring | ✅ | | |
| Flow-rate and auxiliary formulas | | ✅ | |
| Choice of functional form | | ✅ | |
| Derived initial-value form (`init(S) ~ pop - I0`) | | ✅ | |
| Constant and stock-initial values | | | ✅ |
| Lookup point data; input series / driver function | | | ✅ |
| `dt`, method, `start`, `stop` | — `sim_spec()` — |

- Each stock's initial comes from exactly one place — a number in
  `sd_parameters()` or a formula via `init()` in `sd_equations()`.
- Units are declared in structure; unspecified units are simply not checked.
- Numeric literals are allowed on an equation RHS — a `1 - x/K` or an `ifelse`
  threshold is structure, not a parameter.

### Built-ins on an equation RHS

Delays and smoothing — `delayN(x, delay, order, initial)` and
`smoothN(x, time, order, initial)` (`order` / `initial` optional; `order` is
fixed at initialisation), the pipeline delay `delay_fixed(x, delay, initial)`,
and `forecast(x, average_time, horizon)` (trend extrapolation, sugar over
`smoothN`). Shaping functions `step`, `pulse`, `ramp`. `previous(x, init)`,
`t`, `dt`. Base-R math (`ifelse`, `min` / `max`, `sqrt`, `sin`, `exp`, `log`, …).
A model may be aux-only when a delay / smooth carries all the state.

### Real data

Three ways data enters a model, all additive to the three layers:

- **Exogenous driver** — `input("x")` in structure; `input_series("x", data =
  df, interp = "linear", range = "hold")` in parameters. `df` has a `time`
  column (numeric, or a `Date` resolved against `sim_spec(start = )`) and one
  value column per driver; the solver interpolates onto its own grid. (§17)
- **Observed series for comparison** — `simulate(..., observed = df)` stacks the
  observed columns into the output tibble tagged `source = "observed"` beside
  `"model"`, so `autoplot()` overlays them. Use `map = c(I = "cases")` when the
  column names differ from the model's. (§22)
- **Calibration** — `calibrate(structure, equations, parameters, spec, observed,
  target, free, lower, upper)` returns fitted `parameters` (least-squares point
  estimation over the `free` constants). One verb, not a sweep or optimisation
  framework. (§22)

### Scope

The grammar covers stock-and-flow system dynamics, including subscripted /
arrayed models (§7). It is deliberately not a parameter-sweep engine, an
agent-based framework, or a GUI; calibration is a single verb (`calibrate()`),
not the focus.

---

## Catalogue

| # | Model | Behaviour | Grammar it exercises |
|---|---|---|---|
| 1 | Customer growth | exponential | boundary flows, constant fractions, time-varying `aux` |
| 2 | S-shaped growth | logistic | RHS literal, `reference()` |
| 3 | Overshoot & collapse | overshoot then decay | `lookup()` with `range = "clamp"`, `min()` |
| 4 | Solow growth | goal-seeking | `sqrt`, unspecified units |
| 5 | SIR | epidemic | the core grammar |
| 6 | Bass diffusion | S-curve + pulse | two coupled stocks, aux chain, `update()` form-swap |
| 7 | Cohort SIR | 3 coupled waves | `subscripts()`, matrix `constant()`, `%*%`, `sum()` |
| 8 | Material delay | lag, exponential approach | `step()`, `delayN()`, first-order delay as a stock |
| 9 | Teacup | exponential decay to a goal | the minimal one-stock model |
| 10 | Lotka–Volterra | limit cycle | two stocks, nonlinear coupling, `reference()` |
| 11 | Town population | exponential growth, aged outflow | `subscripts()` over 351 members, `delayN(order = 8)` |
| 12 | SMOOTH | first/third-order information delay | `smoothN()` at every order, aux-only model |
| 13 | FORECAST | trend extrapolation | `forecast()`, `ramp()`, `step()`, `delay_fixed()` |
| 14 | Fixed (pipeline) delay | exact translation in time | `delay_fixed()`, variable delay time |
| 15 | Workforce and backlog | damped oscillation | 3 stocks, aging chain, `lookup()`, `min()` |
| 16 | Manufacturing defects | pulse shock, self-worsening | `pulse()`, two `lookup()`s on one stock, a rate that degrades itself |
| 17 | Atmospheric carbon bathtub | accumulation with slow decay | `input()` + `input_series()` — an exogenous data driver |
| 18 | Rössler attractor | chaos | three signed net flows, `method = "rk4"`, no lookups at all |
| 19 | Single pendulum | conservative oscillation | second-order system as two stocks, `sin()`, integrator choice |
| 20 | Sales agent motivation | collapse after a subsidy ends | `ifelse` employment gate, accumulator stocks, `lookup()`, `scenarios()` |
| 21 | Capability trap | irreversible erosion | lookups multiplied together, `min()`, `step()` inside a flow |
| 22 | Boarding-school flu | SIR fitted to real case data | `simulate(observed = )`, `calibrate()` — parameter estimation |

Models 9–15 are reproduced from
[`SDXorg/test-models`](https://github.com/SDXorg/test-models) (the PySD
conformance corpus — no stated licence; tiny canonical interoperability-test
models). Models 16–21 are from the
[`SDXorg/PySD-Cookbook`](https://github.com/SDXorg/PySD-Cookbook) sample models
(`source/models/`, © 2014–2022 James Houghton and Eneko Martin-Martinez; the
repository ships no LICENSE file). In both cases the equations are reproduced
for reference; the `tidysd` versions are reimplementations.

---

## 1. Customer / population growth

Single stock, one inflow and one outflow, each a constant fraction of the stock —
the canonical first-order feedback loop, exponential growth.

**Duggan** — `SDMR/models/02 Chapter/R/Customers.R`

```r
library(deSolve)

START <- 2015; FINISH <- 2030; STEP <- 0.25
simtime <- seq(START, FINISH, by = STEP)

stocks <- c(sCustomers = 10000)
auxs   <- c(aGrowthFraction = 0.08, aDeclineFraction = 0.03)

model <- function(time, stocks, auxs){
  with(as.list(c(stocks, auxs)), {
    fRecruits <- sCustomers * aGrowthFraction
    fLosses   <- sCustomers * aDeclineFraction
    dC_dt     <- fRecruits - fLosses
    list(c(dC_dt), Recruits = fRecruits, Losses = fLosses)
  })
}

o <- data.frame(ode(y = stocks, times = simtime, func = model,
                    parms = auxs, method = "euler"))
```

**tidysd**

```r
pop_struct <- sd_structure(
  meta(name = "Customer growth"),
  stock("Customers", units = "customers", non_negative = TRUE),
  flow("recruits", from = .source,     to = "Customers", units = "customers/year"),
  flow("losses",   from = "Customers", to = .sink,       units = "customers/year")
)

pop_eqns <- sd_equations(
  recruits ~ Customers * growth_fraction,
  losses   ~ Customers * decline_fraction
)

pop_pars <- sd_parameters(
  constant(growth_fraction = 0.08, decline_fraction = 0.03),
  initial(Customers = 10000)
)

spec <- sim_spec(start = 2015, stop = 2030, dt = 0.25,
                 method = "euler", time_unit = "year")

out <- simulate(pop_struct, pop_eqns, pop_pars, spec = spec)
autoplot(out)
```

**Ch. 1 variant** — `SDMR/models/01 Chapter/R/01 Customers.R` makes the growth
fraction piecewise in time (`if (time < 2020) gf <- 0.07 ...`). In `tidysd` this
is a time-dependent aux — `ifelse` thresholds are structural, so it goes straight
on the equation RHS:

```r
pop_struct2 <- sd_structure(
  stock("Customers", units = "customers", non_negative = TRUE),
  aux("growth_fraction", units = "1/year"),
  flow("recruits", from = .source,     to = "Customers", units = "customers/year"),
  flow("losses",   from = "Customers", to = .sink,       units = "customers/year")
)

pop_eqns2 <- sd_equations(
  growth_fraction ~ ifelse(t < 2020, 0.07, ifelse(t < 2025, 0.03, 0.02)),
  recruits        ~ Customers * growth_fraction,
  losses          ~ Customers * decline_fraction
)

pop_pars2 <- sd_parameters(
  constant(decline_fraction = 0.03),
  initial(Customers = 10000)
)
```

---

## 2. S-shaped growth (logistic)

One stock; a fractional growth rate scaled by an "effect of availability" that
falls linearly to zero as the stock fills its carrying capacity. Reinforcing loop
dominant early, balancing loop dominant late.

**Duggan** — `SDMR/models/03 Chapter/R/01 S Shaped Growth.R`

```r
library(deSolve)

START <- 0; FINISH <- 100; STEP <- 0.25
simtime <- seq(START, FINISH, by = STEP)
stocks  <- c(sStock = 100)
auxs    <- c(aCapacity = 10000, aRef.Availability = 1, aRef.GrowthRate = 0.10)

model <- function(time, stocks, auxs){
  with(as.list(c(stocks, auxs)), {
    aAvailability <- 1 - sStock / aCapacity
    aEffect       <- aAvailability / aRef.Availability
    aGrowth.Rate  <- aRef.GrowthRate * aEffect
    fNet.Flow     <- sStock * aGrowth.Rate
    d_sStock_dt   <- fNet.Flow
    list(c(d_sStock_dt), NetFlow = fNet.Flow, GrowthRate = aGrowth.Rate,
         Effect = aEffect, Availability = aAvailability)
  })
}

o <- data.frame(ode(y = stocks, times = simtime, func = model,
                    parms = auxs, method = "euler"))
```

**tidysd**

```r
ss_struct <- sd_structure(
  meta(name = "S-shaped growth"),
  stock("Stock", units = "widgets", non_negative = TRUE),
  aux("availability", units = "1"),
  aux("effect",       units = "1"),
  aux("growth_rate",  units = "1/time"),
  flow("net_flow", from = .source, to = "Stock", units = "widgets/time")
)

ss_eqns <- sd_equations(
  availability ~ 1 - Stock / capacity,          # literal 1 is structural
  effect       ~ availability / ref_availability,
  growth_rate  ~ ref_growth_rate * effect,
  net_flow     ~ Stock * growth_rate
)

ss_pars <- sd_parameters(
  constant(capacity = 10000, ref_growth_rate = 0.10),
  reference(ref_availability = 1),               # normalising reference, not a lever
  initial(Stock = 100)
)

spec <- sim_spec(start = 0, stop = 100, dt = 0.25, method = "euler")
out  <- simulate(ss_struct, ss_eqns, ss_pars, spec = spec)
```

---

## 3. Overshoot and collapse

`Capital` reinvests a fraction of its profit; `Resource` is a finite pool that
only drains. Extraction efficiency is a **graphical function** of the remaining
resource — flat while abundant, collapsing as it depletes.

**Duggan** — `SDMR/models/03 Chapter/R/03 Overshoot.R`

```r
library(deSolve)

START <- 0; FINISH <- 200; STEP <- 0.125
simtime <- seq(START, FINISH, by = STEP)
stocks  <- c(sCapital = 5, sResource = 1000)
auxs    <- c(aDesired.Growth = 0.07, aDepreciation = 0.05,
            aCost.Per.Investment = 2.0, aFraction.Reinvested = 0.12,
            aRevenue.Per.Unit = 3)

x.Resource   <- seq(0, 1000, by = 100)
y.Efficiency <- c(0, 0.25, 0.45, 0.63, 0.75, 0.85, 0.92, 0.96, 0.98, 0.99, 1.0)
func.Efficiency <- approxfun(x = x.Resource, y = y.Efficiency, method = "linear",
                             yleft = 0, yright = 1.0)

model <- function(time, stocks, auxs){
  with(as.list(c(stocks, auxs)), {
    aExtr.Efficiency    <- func.Efficiency(sResource)
    fExtraction         <- aExtr.Efficiency * sCapital
    aTotal.Revenue      <- aRevenue.Per.Unit * fExtraction
    aCapital.Costs      <- sCapital * 0.10
    aProfit             <- aTotal.Revenue - aCapital.Costs
    aCapital.Funds      <- aFraction.Reinvested * aProfit
    aMaximum.Investment <- aCapital.Funds / aCost.Per.Investment
    aDesired.Investment <- sCapital * aDesired.Growth
    fInvestment         <- min(aMaximum.Investment, aDesired.Investment)
    fDepreciation       <- sCapital * aDepreciation
    dS_dt <- fInvestment - fDepreciation
    dR_dt <- -fExtraction
    list(c(dS_dt, dR_dt))
  })
}

o <- data.frame(ode(y = stocks, times = simtime, func = model,
                    parms = auxs, method = "euler"))
```

**tidysd**

```r
os_struct <- sd_structure(
  meta(name = "Overshoot and collapse"),
  stock("Capital",  units = "units", non_negative = TRUE),
  stock("Resource", units = "units", non_negative = TRUE),

  lookup("extr_efficiency", input = "Resource",
         in_units = "units", out_units = "1/year",
         interp = "linear", range = "clamp"),

  aux("total_revenue"),  aux("capital_costs"),  aux("profit"),
  aux("capital_funds"),  aux("maximum_investment"),  aux("desired_investment"),

  flow("extraction",   from = "Resource", to = .sink,     units = "units/year"),
  flow("investment",   from = .source,    to = "Capital", units = "units/year"),
  flow("depreciation", from = "Capital",  to = .sink,     units = "units/year")
)

os_eqns <- sd_equations(
  extraction         ~ extr_efficiency(Resource) * Capital,
  total_revenue      ~ revenue_per_unit * extraction,
  capital_costs      ~ Capital * capital_cost_fraction,
  profit             ~ total_revenue - capital_costs,
  capital_funds      ~ fraction_reinvested * profit,
  maximum_investment ~ capital_funds / cost_per_investment,
  desired_investment ~ Capital * desired_growth,
  investment         ~ min(maximum_investment, desired_investment),
  depreciation       ~ Capital * depreciation_fraction
)

os_pars <- sd_parameters(
  constant(desired_growth = 0.07, depreciation_fraction = 0.05,
           cost_per_investment = 2.0, fraction_reinvested = 0.12,
           revenue_per_unit = 3, capital_cost_fraction = 0.10),
  initial(Capital = 5, Resource = 1000),
  lookup_data("extr_efficiency",
    x = seq(0, 1000, by = 100),
    y = c(0, 0.25, 0.45, 0.63, 0.75, 0.85, 0.92, 0.96, 0.98, 0.99, 1.0))
)

spec <- sim_spec(start = 0, stop = 200, dt = 0.125, method = "euler", time_unit = "year")

out <- simulate(os_struct, os_eqns, os_pars, spec = spec,
  scenarios = scenarios(
    base = list(),
    fr13 = list(fraction_reinvested = 0.13),
    fr14 = list(fraction_reinvested = 0.14),
    dg15 = list(fraction_reinvested = 0.14, desired_growth = 0.15),
    dg16 = list(fraction_reinvested = 0.14, desired_growth = 0.16)
  ))
```

---

## 4. Solow economic growth

One capital stock. Output is concave in capital (`labour * sqrt(Machines)`); a
fixed fraction is reinvested, capital depreciates linearly. Converges to a steady
state where investment equals depreciation.

**Duggan** — `SDMR/models/03 Chapter/R/02 Solow.R`

```r
library(deSolve)

START <- 0; FINISH <- 100; STEP <- 0.25
simtime <- seq(START, FINISH, by = STEP)
stocks  <- c(sMachines = 100)
auxs    <- c(aDepFraction = 0.1, aLabour = 100, aReinvestFraction = 0.20)

model <- function(time, stocks, auxs){
  with(as.list(c(stocks, auxs)), {
    aEconomicOutput <- aLabour * sqrt(sMachines)
    fInvestment     <- aEconomicOutput * aReinvestFraction
    fDiscards       <- sMachines * aDepFraction
    d_sMachines_dt  <- fInvestment - fDiscards
    list(c(d_sMachines_dt), Investment = fInvestment, Discards = fDiscards,
         EconomicOutput = aEconomicOutput)
  })
}

o <- data.frame(ode(y = stocks, times = simtime, func = model,
                    parms = auxs, method = "euler"))
```

**tidysd** — `economic_output` and `labour` are left unit-unspecified, so the
deliberately non-homogeneous Cobb–Douglas form runs without unit warnings.

```r
solow_struct <- sd_structure(
  meta(name = "Solow economic growth"),
  stock("Machines", units = "machines", non_negative = TRUE),
  aux("economic_output"),                        # units unspecified — skip the check
  flow("investment", from = .source,    to = "Machines", units = "machines/year"),
  flow("discards",   from = "Machines", to = .sink,      units = "machines/year")
)

solow_eqns <- sd_equations(
  economic_output ~ labour * sqrt(Machines),
  investment      ~ economic_output * reinvest_fraction,
  discards        ~ Machines * dep_fraction
)

solow_pars <- sd_parameters(
  constant(dep_fraction = 0.1, labour = 100, reinvest_fraction = 0.20),
  initial(Machines = 100)
)

spec <- sim_spec(start = 0, stop = 100, dt = 0.25, method = "euler", time_unit = "year")
out  <- simulate(solow_struct, solow_eqns, solow_pars, spec = spec)
```

---

## 5. SIR

Three stocks, two flows. Frequency-dependent transmission, constant recovery
rate. The grammar's reference case.

**Duggan** — `SDMR/models/05 Chapter/R/01 SIR Aggregate.R`

```r
library(deSolve)

START <- 0; FINISH <- 100; STEP <- 0.125
simtime <- seq(START, FINISH, by = STEP)
stocks  <- c(sSusceptible = 999, sInfected = 1, sRecovered = 0)
auxs    <- c(aTotalPopulation = 1000,
            aContactRate = 6, aInfectivity = 0.20, aRecoveryTime = 5)

model <- function(time, stocks, auxs){
  with(as.list(c(stocks, auxs)), {
    aBeta          <- aContactRate * aInfectivity / aTotalPopulation
    aLambda        <- aBeta * sInfected
    fIR            <- sSusceptible * aLambda
    fRR            <- sInfected / aRecoveryTime
    dS_dt <- -fIR
    dI_dt <- fIR - fRR
    dR_dt <- fRR
    list(c(dS_dt, dI_dt, dR_dt), IR = fIR, RR = fRR)
  })
}

o <- data.frame(ode(y = stocks, times = simtime, func = model,
                    parms = auxs, method = "euler"))
```

**tidysd**

```r
sir_struct <- sd_structure(
  meta(name = "SIR"),
  stock("S", units = "people", non_negative = TRUE),
  stock("I", units = "people", non_negative = TRUE),
  stock("R", units = "people", non_negative = TRUE),
  aux("beta",   units = "1/(people*day)"),
  aux("lambda", units = "1/day"),
  flow("IR", from = "S", to = "I", units = "people/day"),
  flow("RR", from = "I", to = "R", units = "people/day")
)

sir_eqns <- sd_equations(
  beta   ~ contact_rate * infectivity / total_population,
  lambda ~ beta * I,
  IR     ~ S * lambda,
  RR     ~ I / recovery_time
)

sir_pars <- sd_parameters(
  constant(contact_rate = 6, infectivity = 0.20,
           total_population = 1000, recovery_time = 5),
  initial(S = 999, I = 1, R = 0)
)

spec <- sim_spec(start = 0, stop = 100, dt = 0.125, method = "euler", time_unit = "day")
out  <- simulate(sir_struct, sir_eqns, sir_pars, spec = spec)

# swap to density-dependent transmission — structure and parameters untouched
sir_eqns_dd <- update(sir_eqns, lambda ~ contact_rate * infectivity * I)
```

---

## 6. Bass diffusion (scalar)

Two stocks, one flow. Adoption driven by word of mouth only: `rho = beta *
Adopters`, `adoption_rate = PotentialAdopters * rho`. S-shaped cumulative
adoption, bell-shaped adoption rate.

**Duggan** — `SDMR/models/08 Additional/01 SD Delft 2016/Aggregate.R`

```r
library(deSolve)

START <- 0; FINISH <- 20; STEP <- 0.01
simtime <- seq(START, FINISH, by = STEP)
stocks  <- c(sPotentialAdopters = 99999, sAdopters = 1)
auxs    <- c(aTotalPopulation = 100000, aContact.Rate = 6, aInfectivity = 0.25)

model <- function(time, stocks, auxs){
  with(as.list(c(stocks, auxs)), {
    aBeta <- aContact.Rate * aInfectivity / aTotalPopulation
    aRho  <- aBeta * sAdopters
    fAR   <- sPotentialAdopters * aRho
    dPA_dt <- -fAR
    dA_dt  <-  fAR
    list(c(dPA_dt, dA_dt), AR = fAR, Rho = aRho)
  })
}

o <- data.frame(ode(y = stocks, times = simtime, func = model,
                    parms = auxs, method = "euler"))
```

**tidysd**

```r
bass_struct <- sd_structure(
  meta(name = "Bass diffusion (aggregate)"),
  stock("PotentialAdopters", units = "people", non_negative = TRUE),
  stock("Adopters",          units = "people", non_negative = TRUE),
  aux("beta", units = "1/(people*week)"),
  aux("rho",  units = "1/week"),
  flow("adoption_rate", from = "PotentialAdopters", to = "Adopters",
       units = "people/week")
)

bass_eqns <- sd_equations(
  beta          ~ contact_rate * infectivity / total_population,
  rho           ~ beta * Adopters,
  adoption_rate ~ PotentialAdopters * rho
)

bass_pars <- sd_parameters(
  constant(contact_rate = 6, infectivity = 0.25, total_population = 100000),
  initial(PotentialAdopters = 99999, Adopters = 1)
)

spec <- sim_spec(start = 0, stop = 20, dt = 0.01, method = "euler",
                 time_unit = "week", saveat = 0.25)
out  <- simulate(bass_struct, bass_eqns, bass_pars, spec = spec)

# full Bass (adds an innovation coefficient) — one equation edit
bass_eqns_full <- update(bass_eqns,
  adoption_rate ~ PotentialAdopters * (rho + innovation))   # `innovation` = new slot
```

---

## 7. Cohort SIR

The Ch. 5 disaggregated SIR: the population is split into 3 cohorts, each with its
own S/I/R. Cross-cohort transmission is a 3×3 contact matrix; the force of
infection is a matrix–vector product. This is where `subscripts()` earns its
place — one `S→I→R` chain declared once over a `cohort` dimension.

**Duggan** — `SDMR/models/05 Chapter/R/02 SIR Vectorised.R`

```r
library(deSolve)

START <- 0; FINISH <- 20000; STEP <- 0.125
NUM_COHORTS <- 3; NUM_STATES <- 3
simtime <- seq(START, FINISH, by = STEP)

CE <- matrix(c(3.0, 2.0, 1.0,
               2.0, 2.0, 1.0,
               1.0, 1.0, 0.5), nrow = 3, ncol = 3, byrow = TRUE)

CohortPopulatons <- c(25000, 50000, 25000)
beta <- CE / CohortPopulatons

stocks <- c(SusceptibleY = 24999, SusceptibleA = 50000, SusceptibleE = 25000,
            InfectedY = 1,        InfectedA = 0,         InfectedE = 0,
            RecoveredY = 0,       RecoveredA = 0,        RecoveredE = 0)

delays <- c(Young = 2.0, Adult = 2.0, Elderly = 2.0)

model <- function(time, stocks, auxs){
  with(as.list(c(stocks, auxs)), {
    states      <- matrix(stocks, nrow = NUM_COHORTS, ncol = NUM_STATES)
    Susceptible <- states[, 1]
    Infected    <- states[, 2]
    Recovered   <- states[, 3]

    Lambda <- beta %*% Infected
    IR     <- Lambda * Susceptible
    RR     <- Infected / delays

    dS_dt <- -IR
    dI_dt <-  IR - RR
    dR_dt <-  RR
    list(c(dS_dt, dI_dt, dR_dt))
  })
}

o <- data.frame(ode(y = stocks, times = simtime, func = model,
                    parms = NULL, method = "euler"))
o$TotalInfected <- o$InfectedY + o$InfectedA + o$InfectedE
```

**tidysd**

```r
coh_struct <- sd_structure(
  meta(name = "Cohort SIR"),
  subscripts(cohort = c("young", "adult", "elderly")),

  stock("S", dims = "cohort", units = "people", non_negative = TRUE),
  stock("I", dims = "cohort", units = "people", non_negative = TRUE),
  stock("R", dims = "cohort", units = "people", non_negative = TRUE),

  aux("lambda",         dims = "cohort", units = "1/day"),
  aux("total_infected",                  units = "people"),   # reduces over cohort

  flow("IR", from = "S", to = "I", dims = "cohort", units = "people/day"),
  flow("RR", from = "I", to = "R", dims = "cohort", units = "people/day")
)

coh_eqns <- sd_equations(
  lambda         ~ (CE %*% I) / pop,     # CE is cohort x cohort; %*% contracts against I
  IR             ~ lambda * S,           # element-wise over cohort
  RR             ~ I / recovery_time,
  total_infected ~ sum(I)                # reduce the cohort dim -> scalar
)

coh_pars <- sd_parameters(
  constant(
    CE = matrix(c(3, 2, 1,
                  2, 2, 1,
                  1, 1, 0.5), nrow = 3, byrow = TRUE),
    pop = c(young = 25000, adult = 50000, elderly = 25000),
    recovery_time = 2
  ),
  initial(
    S = c(young = 24999, adult = 50000, elderly = 25000),
    I = c(young = 1,     adult = 0,     elderly = 0),
    R = 0                                 # scalar broadcasts to every cohort
  )
)

spec <- sim_spec(start = 0, stop = 20000, dt = 0.125, method = "euler", time_unit = "day")
out  <- simulate(coh_struct, coh_eqns, coh_pars, spec = spec)

autoplot(out, vars = "I") + ggplot2::facet_wrap(~cohort)
```

Output stays long: `tibble(cohort, time, variable, value, unit)`, with `cohort =
NA` for the scalar `total_infected`.

---

## 8. Material delay

A stock of material in transit: a step increase in the inflow, an outflow equal
to the stock divided by a fixed delay time. The outflow lags the inflow and
approaches it exponentially — a first-order material delay, the canonical delay
teaching model.

**Duggan** — `SDMR/archive 2015/10 Lecture/R/Delay.R` (Vensim intent:
`Inflow = 100 + step(100, 4)`, `Outflow = Stock / Time Delay`,
`Stock = INTEG(Inflow - Outflow, 400)`, `Time Delay = 4`)

```r
library(deSolve)

START <- 0; FINISH <- 25; STEP <- 0.125
simtime <- seq(START, FINISH, by = STEP)

# step input, precomputed as a table (Duggan's teaching style avoids step())
input <- rep(NA, length(simtime))
input[1:(4 / STEP)]                     <- 100
input[((4 / STEP) + 1):length(simtime)] <- 200
simData <- data.frame(time = simtime, aInput = input)

model <- function(time, stocks, auxs){
  with(as.list(c(stocks, auxs)), {
    fInflow  <- simData$aInput[which(simData$time == time)]
    fOutflow <- sStock / aTimeDelay
    dS_dt    <- fInflow - fOutflow
    list(c(dS_dt), Inflow = fInflow, Outflow = fOutflow)
  })
}

stocks <- c(sStock = 400)
auxs   <- c(aTimeDelay = 4)

o <- data.frame(ode(y = stocks, times = simtime, func = model,
                    parms = auxs, method = "euler"))
```

**tidysd**

```r
delay_struct <- sd_structure(
  meta(name = "First-order material delay"),
  stock("Material", units = "units", non_negative = TRUE),
  flow("inflow",  from = .source,    to = "Material", units = "units/week"),
  flow("outflow", from = "Material", to = .sink,      units = "units/week")
)

delay_eqns <- sd_equations(
  inflow  ~ 100 + step(100, 4),          # step up at week 4
  outflow ~ Material / delay_time
)

delay_pars <- sd_parameters(
  constant(delay_time = 4),
  initial(Material = 400)                # = inflow x delay_time: starts in equilibrium
)

spec <- sim_spec(start = 0, stop = 25, dt = 0.125, method = "euler", time_unit = "week")
out  <- simulate(delay_struct, delay_eqns, delay_pars, spec = spec)
```

`outflow ~ Material / delay_time` is a first-order delay written as a stock. The
`delayN()` built-in packages the same structure at any order, for delaying a
signal elsewhere without adding buffer stocks by hand:

```r
# third-order delay of an ordered quantity into arrivals:
#   arrivals ~ delayN(orders, lead_time, order = 3)
```

---

## 9. Teacup

The PySD tutorial model, and the smallest complete stock-and-flow model there
is: one stock, one outflow proportional to the gap between the stock and a
constant goal. `output.csv` cools 180 °F tea toward a 70 °F room with a
10-minute characteristic time — 110.212 °F at minute 10, 75.374 °F at minute 30,
one `1/e` of the remaining gap per characteristic time.

**Vensim** — `samples/teacup/teacup.mdl`

```
Characteristic Time = 10                                    ~ Minutes
Room Temperature    = 70                                    ~ Degrees Fahrenheit
Heat Loss to Room   = (Teacup Temperature - Room Temperature) / Characteristic Time
                                                            ~ Degrees Fahrenheit/Minute
Teacup Temperature  = INTEG(-Heat Loss to Room, 180)        ~ Degrees Fahrenheit
INITIAL TIME = 0   FINAL TIME = 30   TIME STEP = 0.125
```

**tidysd**

```r
teacup_struct <- sd_structure(
  meta(name = "Teacup cooling"),
  stock("TeacupTemperature", units = "degF"),
  flow("heat_loss_to_room", from = "TeacupTemperature", to = .sink,
       units = "degF/minute")
)

teacup_eqns <- sd_equations(
  heat_loss_to_room ~ (TeacupTemperature - room_temperature) / characteristic_time
)

teacup_pars <- sd_parameters(
  constant(room_temperature = 70, characteristic_time = 10),
  initial(TeacupTemperature = 180)
)

spec <- sim_spec(start = 0, stop = 30, dt = 0.125, method = "euler",
                 time_unit = "minute")
out  <- simulate(teacup_struct, teacup_eqns, teacup_pars, spec = spec)
```

---

## 10. Lotka–Volterra

Two stocks with reciprocal nonlinear coupling: prey deaths rise with predators,
predator births rise with prey. Both fractional rates are written as a reference
value scaled by the *other* stock relative to its reference level, so every
constant is dimensionally interpretable. The fixed point is 100 hares / 300
foxes; starting at 1000 / 20 gives one large closed orbit of about 47 years —
prey peaking near 6,500 and predators near 1,350 with an exact integrator. The
`.mdl` asks for Euler at `dt = 0.0625`, which inflates the peaks (≈7,670 hares)
and drives prey to numerical zero; the entry keeps the file's settings.

**Vensim** — `samples/Lotka_Volterra/Lotka_Volterra.mdl`

```
Prey      = INTEG(Prey Births - Prey Deaths, Initial Prey Population)          ~ Hares
Predators = INTEG(Predator Births - Predator Deaths, Initial Predator Population)
                                                                               ~ Foxes
Prey Births     = Prey * Prey Reproduction Ratio                               ~ Hares/Year
Prey Deaths     = Prey * Fractional Predation Rate                             ~ Hares/Year
Predator Births = Predators * Predator Reproduction Ratio                      ~ Foxes/Year
Predator Deaths = Predators / Predator Lifespan                                ~ Foxes/Year

Fractional Predation Rate =
    Reference Fractional Predation Rate * Predators / Reference Predators
Predator Reproduction Ratio =
    Reference Predator Reproduction Ratio * Prey / Reference Prey Population

Prey Reproduction Ratio = 3     Predator Lifespan = 10
Reference Fractional Predation Rate = 0.2      Reference Predators = 20
Reference Predator Reproduction Ratio = 1      Reference Prey Population = 1000
Initial Prey Population = 1000                 Initial Predator Population = 20
INITIAL TIME = 0   FINAL TIME = 50   TIME STEP = 0.0625
```

**tidysd**

```r
lv_struct <- sd_structure(
  meta(name = "Lotka-Volterra"),
  stock("Prey",      units = "hares", non_negative = TRUE),
  stock("Predators", units = "foxes", non_negative = TRUE),
  aux("fractional_predation_rate",   units = "1/year"),
  aux("predator_reproduction_ratio", units = "1/year"),
  flow("prey_births",     from = .source,      to = "Prey",      units = "hares/year"),
  flow("prey_deaths",     from = "Prey",       to = .sink,       units = "hares/year"),
  flow("predator_births", from = .source,      to = "Predators", units = "foxes/year"),
  flow("predator_deaths", from = "Predators",  to = .sink,       units = "foxes/year")
)

lv_eqns <- sd_equations(
  fractional_predation_rate   ~ ref_predation_rate * Predators / ref_predators,
  predator_reproduction_ratio ~ ref_predator_reproduction * Prey / ref_prey_population,
  prey_births     ~ Prey * prey_reproduction_ratio,
  prey_deaths     ~ Prey * fractional_predation_rate,
  predator_births ~ Predators * predator_reproduction_ratio,
  predator_deaths ~ Predators / predator_lifespan
)

lv_pars <- sd_parameters(
  constant(prey_reproduction_ratio = 3, predator_lifespan = 10,
           ref_predation_rate = 0.2, ref_predator_reproduction = 1),
  reference(ref_predators = 20, ref_prey_population = 1000),
  initial(Prey = 1000, Predators = 20)
)

spec <- sim_spec(start = 0, stop = 50, dt = 0.0625, method = "euler",
                 time_unit = "year")
out  <- simulate(lv_struct, lv_eqns, lv_pars, spec = spec)
```

---

## 11. Town population with an aged death outflow

One `Population` stock replicated over all 351 Massachusetts towns. Births are a
flat 10 %/month of the local population; deaths are the *same* birth flow pushed
through an eighth-order delay of one lifespan — an aging chain written as one
`delayN` rather than eight hand-built cohort stocks. With a 0.1/month birthrate
against a 70-month lifespan the outflow never catches up, so every town grows
exponentially: the 6,547,695 initial residents reach about 38.7 M by month 20,
Boston alone starting at 617,660.

**Vensim** — `samples/Population/Subscripted Population Model.mdl`

```
Towns: Abington, Acton, Acushnet, ... , Wrentham, Yarmouth     (351 members)

Population[Towns]         = INTEG(Births[Towns] - Deaths[Towns],
                                  Initial Population[Towns])
Births[Towns]             = Birthrate[Towns] * Population[Towns]
Deaths[Towns]             = DELAY N(Births[Towns], Lifespan,
                                    Population[Towns]/Lifespan, 8)
Birthrate[Towns]          = 0.1
Lifespan                  = 70
Initial Population[Towns] = 15985, 21924, 10303, ... , 10955, 23793
INITIAL TIME = 0   FINAL TIME = 20   TIME STEP = 1
```

**tidysd** — the town names and the 351 initial values are data, so they live in
`sd_parameters()` as plain R vectors; nothing about the model text changes when
the dimension grows.

```r
town_pop <- c(Abington = 15985, Acton = 21924, Acushnet = 10303, ... )  # 351 named

pop_struct <- sd_structure(
  meta(name = "Subscripted town population"),
  subscripts(town = names(town_pop)),
  stock("Population", dims = "town", units = "people", non_negative = TRUE),
  flow("births", from = .source,      to = "Population", dims = "town",
       units = "people/month"),
  flow("deaths", from = "Population", to = .sink,        dims = "town",
       units = "people/month")
)

pop_eqns <- sd_equations(
  births ~ birthrate * Population,
  deaths ~ delayN(births, lifespan, order = 8, initial = Population / lifespan)
)

pop_pars <- sd_parameters(
  constant(birthrate = 0.1, lifespan = 70),   # scalars broadcast over `town`
  initial(Population = town_pop)
)

spec <- sim_spec(start = 0, stop = 20, dt = 1, method = "euler",
                 time_unit = "month")
out  <- simulate(pop_struct, pop_eqns, pop_pars, spec = spec)
```

`delayN(..., initial =)` sets the delay's *output* level at `t = 0` (here
`Population / lifespan`, so the chain starts in demographic equilibrium) — the
same third argument Vensim's `DELAY N` takes.

---

## 12. SMOOTH

A pure information-delay model: no stocks are declared by hand, only auxiliaries,
because every smooth *is* the stock. One input steps from −1 to 4 at month 5 and
the adjustment time itself steps from 2 to 4 at month 10, so the smooths chase a
moving target through a moving time constant. `output.tab` at month 10 shows the
order separating cleanly: 3.65396 first-order, 3.96633 third-order, 3.8793 for
the `SMOOTH N` case.

**Vensim** — `tests/smooth/test_smooth.mdl`

```
Input           = -1 + STEP(5, 5)
Adjustment Time = 2 + STEP(2, 10)
Initial Value   = 5
Variable Order  = 2 + STEP(1, 10)

Smooth output    = SMOOTH(Input, Adjustment Time)
SmoothI output   = SMOOTHI(Input, Adjustment Time, Initial Value)
Smooth3 output   = SMOOTH3(Input, Adjustment Time)
Smooth3I output  = SMOOTH3I(Input, Adjustment Time, Initial Value)
Smooth N output  = SMOOTH N(Input, Adjustment Time, Initial Value, Variable Order)
INITIAL TIME = 0   FINAL TIME = 20   TIME STEP = 0.25
```

**tidysd** — Vensim's five spellings collapse into one built-in with two optional
arguments; `initial` defaults to the input's value at `t = 0`, `order` to 1.

```r
smooth_struct <- sd_structure(
  meta(name = "Information smoothing"),
  aux("input"), aux("adjustment_time"),
  aux("smooth_1"), aux("smooth_1i"),
  aux("smooth_3"), aux("smooth_3i"), aux("smooth_n")
)

smooth_eqns <- sd_equations(
  input           ~ -1 + step(5, 5),
  adjustment_time ~ 2 + step(2, 10),
  smooth_1  ~ smoothN(input, adjustment_time),
  smooth_1i ~ smoothN(input, adjustment_time, initial = initial_value),
  smooth_3  ~ smoothN(input, adjustment_time, order = 3),
  smooth_3i ~ smoothN(input, adjustment_time, initial = initial_value, order = 3),
  smooth_n  ~ smoothN(input, adjustment_time, initial = initial_value,
                      order = 2 + step(1, 10))
)

smooth_pars <- sd_parameters(constant(initial_value = 5))

spec <- sim_spec(start = 0, stop = 20, dt = 0.25, method = "euler",
                 time_unit = "month")
out  <- simulate(smooth_struct, smooth_eqns, smooth_pars, spec = spec)
```

`order` is read once at initialisation, so `smooth_n` stays second-order for the
whole run even though its expression steps to 3 at month 10 — that is exactly
what the reference output shows. `tests/smooth_and_stock/` adds the companion
check that a smooth of a *stock* (`SMOOTH(Input, 2)` where `Input = INTEG(0, 4)`)
resolves in the right order; the grammar's run-time dependency graph (a stock's
value is known before any aux) handles it without special-casing.

---

## 13. FORECAST

Trend extrapolation: smooth the input, read the growth rate implied by the gap
between the input and its own smooth, and project that rate forward by a
horizon. It is deliberately naive — it overshoots turning points, which is the
point of the test. In `output.tab` the input `R Delayed` is 61 at month 80 while
the 10-month forecast reads 64.3028; by month 120 the sine wave has turned and
the forecast reads 57.911 against an actual 60.035.

**Vensim** — `tests/forecast/test_forecast.mdl` (scalar half; the file repeats
the same structure subscripted over `Dim1 x Dim2`)

```
R = 10 + RAMP(1, 10, 60) + STEP(1, 70)*(1 - STEP(1, 90))
      + STEP(2*SIN(6.28*Time/period), 100)                  ~ widgets/Month
period              = 20
Delay time          = 10
R Delayed           = DELAY FIXED(R, Delay time, R)
Fcst smoothing time = 5
Fcst horizon        = 10
R forecast          = FORECAST(R Delayed, Fcst smoothing time, Fcst horizon)
INITIAL TIME = 0   FINAL TIME = 120   TIME STEP = 0.5   SAVEPER = 1
```

**tidysd**

```r
fc_struct <- sd_structure(
  meta(name = "Trend forecast"),
  aux("R", units = "widgets/month"),
  aux("R_delayed",  units = "widgets/month"),
  aux("R_forecast", units = "widgets/month")
)

fc_eqns <- sd_equations(
  R          ~ 10 + ramp(1, 10, 60) + step(1, 70) * (1 - step(1, 90)) +
               step(2 * sin(6.28 * t / period), 100),
  R_delayed  ~ delay_fixed(R, delay_time, initial = R),
  R_forecast ~ forecast(R_delayed, smoothing_time, horizon)
)

fc_pars <- sd_parameters(
  constant(period = 20, delay_time = 10, smoothing_time = 5, horizon = 10)
)

spec <- sim_spec(start = 0, stop = 120, dt = 0.5, method = "euler",
                 time_unit = "month", saveat = 1)
out  <- simulate(fc_struct, fc_eqns, fc_pars, spec = spec)
```

`forecast(x, average_time, horizon)` is a new built-in, spelled like `delayN` /
`smoothN`, defined as `x * (1 + horizon * (x - smoothN(x, average_time)) /
(smoothN(x, average_time) * average_time))` — i.e. Vensim's `FORECAST`, and
expressible in the grammar already, so it is sugar rather than new semantics.

---

## 14. Fixed (pipeline) delay

`delayN` is an *exponential* delay: material spreads out as it passes through.
A fixed delay is a conveyor — whatever goes in comes out unchanged, exactly
`delay` later. The test drives `Time^2` through eight fixed delays at `dt = 1`
and checks the translation is exact: at month 6, a 2-month delay reads 16, which
is `(6 - 2)^2`. Delay times that are not whole multiples of `dt` are rounded to
the nearest step (1.5 → 2 steps, 1.2 → 1), and the delay may itself be a
variable.

**Vensim** — `tests/delay_fixed/test_delay_fixed.mdl`

```
time squared = Time^2
DF05 = DELAY FIXED(time squared, 0.5, -10)
DF1  = DELAY FIXED(time squared, 1,    10)
DF12 = DELAY FIXED(time squared, 1.2,  -4)
DF15 = DELAY FIXED(time squared, 1.5,  20)
DF2  = DELAY FIXED(time squared, 2,    -3)
DF37 = DELAY FIXED(time squared, 3.7,   4)
DST  = DELAY FIXED(time squared, 2 + 2*SIN(Time), 7)
DT2  = DELAY FIXED(time squared, Time/2, 4)
INITIAL TIME = 0   FINAL TIME = 50   TIME STEP = 1
```

**tidysd**

```r
df_struct <- sd_structure(
  meta(name = "Fixed pipeline delay"),
  aux("time_squared"),
  aux("DF05"), aux("DF1"), aux("DF12"), aux("DF15"),
  aux("DF2"),  aux("DF37"), aux("DST"), aux("DT2")
)

df_eqns <- sd_equations(
  time_squared ~ t^2,
  DF05 ~ delay_fixed(time_squared, 0.5, initial = -10),
  DF1  ~ delay_fixed(time_squared, 1,   initial =  10),
  DF12 ~ delay_fixed(time_squared, 1.2, initial =  -4),
  DF15 ~ delay_fixed(time_squared, 1.5, initial =  20),
  DF2  ~ delay_fixed(time_squared, 2,   initial =  -3),
  DF37 ~ delay_fixed(time_squared, 3.7, initial =   4),
  DST  ~ delay_fixed(time_squared, 2 + 2 * sin(t), initial = 7),
  DT2  ~ delay_fixed(time_squared, t / 2, initial = 4)
)

spec <- sim_spec(start = 0, stop = 50, dt = 1, method = "euler",
                 time_unit = "month")
out  <- simulate(df_struct, df_eqns, sd_parameters(), spec = spec)
```

`delay_fixed(x, delay, initial)` is the second new built-in — a separate name
rather than an `order = Inf` argument to `delayN`, because it is a different
mechanism (a queue, not a cascade of stocks) and because the returned value is
never a mixture of past inputs. `tests/delay_pipeline/` puts the two side by
side on the same step input, which is the clearest statement of the difference.

---

## 15. Workforce and task backlog

Three stocks: an aging chain of `Rookies` maturing into `Experts`, and a
`TaskBacklog` they work off. Rookies consume expert supervision hours, so hiring
in response to a backlog makes the backlog *worse* before it gets better — the
classic capacity-acquisition oscillation. From a backlog of 500 tasks against
230 arriving per week, the backlog overshoots to about 1,082 at week 13, is
cleared by week 25 as the workforce peaks near 166 experts, then swings again to
about 1,273 near week 112 as the over-hired cohort ages out.

**Vensim** — `samples/Workforce/workforce.mdl`

```
Rookies     = INTEG(Hiring - Maturation, 5)
Experts     = INTEG(Maturation - Departure, 50)
Task Backlog = INTEG(Task Arrival - Task Completion, 500)                ~ Tasks

Hiring     = Effect of Pressure on Hiring(Pressure to Hire)              ~ Persons/Week
Maturation = Rookies / Maturation Time                                   ~ Persons/Week
Departure  = Experts / Average Tenure                                    ~ Persons/Week
Pressure to Hire = (Task Backlog - Target Backlog) / Target Backlog
Effect of Pressure on Hiring(
    [(-1,0)-(3,30)],(-1,0),(-0.25,0),(0,2.5),(0.5,15),(1,20),(2,25),(3,25))

"Expert-Hours on Task per Week" =
    Experts*Expert Workweek - Hours of Supervision Required per Rookie Per Week*Rookies
"Rookie-Hours on Task per Week" = Rookie Workweek * Rookies
Expert Task Completion = "Expert-Hours on Task per Week" / Expert Time per Task
Rookie Task Completion = "Rookie-Hours on Task per Week" / Rookie Time per Task
Task Completion = MIN(Expert Task Completion + Rookie Task Completion, Task Backlog)
Task Arrival    = 230                                                    ~ Tasks/Week

Maturation Time = 15   Average Tenure = 35   Target Backlog = 500
Expert Workweek = 40   Rookie Workweek = 40
Expert Time per Task = 10   Rookie Time per Task = 30
Hours of Supervision Required per Rookie Per Week = 20
INITIAL TIME = 0   FINAL TIME = 150   TIME STEP = 0.03125
```

**tidysd** — `task_completion` is left unit-unspecified: the original `MIN`
compares a rate against a level, a deliberate Vensim idiom that no unit checker
should have to bless.

```r
wf_struct <- sd_structure(
  meta(name = "Workforce and task backlog"),
  stock("Rookies",     units = "person", non_negative = TRUE),
  stock("Experts",     units = "person", non_negative = TRUE),
  stock("TaskBacklog", units = "task",   non_negative = TRUE),

  lookup("effect_of_pressure_on_hiring", input = "pressure_to_hire",
         out_units = "person/week", interp = "linear", range = "clamp"),

  aux("pressure_to_hire"),
  aux("expert_hours_on_task", units = "person*hour/week"),
  aux("rookie_hours_on_task", units = "person*hour/week"),
  aux("expert_task_completion", units = "task/week"),
  aux("rookie_task_completion", units = "task/week"),

  flow("hiring",     from = .source,   to = "Rookies", units = "person/week"),
  flow("maturation", from = "Rookies", to = "Experts", units = "person/week"),
  flow("departure",  from = "Experts", to = .sink,     units = "person/week"),
  flow("task_arrival",    from = .source,       to = "TaskBacklog", units = "task/week"),
  flow("task_completion", from = "TaskBacklog", to = .sink)          # units unspecified
)

wf_eqns <- sd_equations(
  expert_hours_on_task   ~ Experts * expert_workweek -
                           supervision_hours_per_rookie * Rookies,
  rookie_hours_on_task   ~ Rookies * rookie_workweek,
  expert_task_completion ~ expert_hours_on_task / expert_time_per_task,
  rookie_task_completion ~ rookie_hours_on_task / rookie_time_per_task,

  task_arrival     ~ arrival_rate,
  task_completion  ~ min(expert_task_completion + rookie_task_completion, TaskBacklog),

  pressure_to_hire ~ (TaskBacklog - target_backlog) / target_backlog,
  hiring           ~ effect_of_pressure_on_hiring(pressure_to_hire),
  maturation       ~ Rookies / maturation_time,
  departure        ~ Experts / average_tenure
)

wf_pars <- sd_parameters(
  constant(maturation_time = 15, average_tenure = 35, target_backlog = 500,
           expert_workweek = 40, rookie_workweek = 40,
           expert_time_per_task = 10, rookie_time_per_task = 30,
           supervision_hours_per_rookie = 20, arrival_rate = 230),
  initial(Rookies = 5, Experts = 50, TaskBacklog = 500),
  lookup_data("effect_of_pressure_on_hiring",
    x = c(-1, -0.25, 0,   0.5, 1,  2,  3),
    y = c( 0,  0,    2.5, 15,  20, 25, 25))
)

spec <- sim_spec(start = 0, stop = 150, dt = 0.03125, method = "euler",
                 time_unit = "week")
out  <- simulate(wf_struct, wf_eqns, wf_pars, spec = spec)
```

---

## 16. Manufacturing defects

One `Backlog` stock, and two graphical functions of it that both push in the
wrong direction: a bigger backlog makes people *work faster* (less time allowed
per unit) and *work longer* (a longer workday), and the defect rate is the ratio
of the two — so the extra output is partly scrap. A pulse of extra arrivals
between days 20 and 30 lifts the backlog from its equilibrium 12.03 units to
29.5 and the defect rate from 5.3 % to 11.9 %, which is why the backlog takes
until about day 35 to clear (values from my own Euler integration at the file's
`dt`).

**Vensim** — `source/models/Manufacturing_Defects/Defects.mdl`

```
Influence of Backlog on Speed(
    [(0,0)-(80,0.1)],(0,0.1),(5,0.1),(10,0.09),(15,0.05),(20,0.04),(80,0.04))
Influence of Backlog on Workday(
    [(0,0)-(60,0.5)],(0,0.1),(2.76986,0.128571),(5.53971,0.188095),(10.3462,0.347619),
    (13.1161,0.416667),(16.5377,0.452381),(20.5295,0.469048),(60,0.5))

Time allocated per unit = Influence of Backlog on Speed(Backlog)
Length of workday       = Influence of Backlog on Workday(Backlog)
Defect Rate             = 0.01 * Length of workday / Time allocated per unit
Fulfillment Rate = Number of Employees * Length of workday / Time allocated per unit
                   * (1 - Defect Rate)
Arrival Rate     = 10 + 12 * PULSE(20, 10)
Number of Employees = 2
Backlog = INTEG(Arrival Rate - Fulfillment Rate, 11.7)
INITIAL TIME = 0   FINAL TIME = 50   TIME STEP = 0.015625
```

**tidysd**

```r
def_struct <- sd_structure(
  meta(name = "Manufacturing defects"),
  stock("Backlog", units = "unit", non_negative = TRUE),

  lookup("influence_of_backlog_on_speed",   input = "Backlog",
         in_units = "unit", out_units = "day/unit",
         interp = "linear", range = "clamp"),
  lookup("influence_of_backlog_on_workday", input = "Backlog",
         in_units = "unit", out_units = "1",
         interp = "linear", range = "clamp"),

  aux("time_allocated_per_unit", units = "day/unit"),
  aux("length_of_workday",       units = "1"),
  aux("defect_rate",             units = "1"),

  flow("arrival_rate",     from = .source,  to = "Backlog", units = "unit/day"),
  flow("fulfillment_rate", from = "Backlog", to = .sink,    units = "unit/day")
)

def_eqns <- sd_equations(
  time_allocated_per_unit ~ influence_of_backlog_on_speed(Backlog),
  length_of_workday       ~ influence_of_backlog_on_workday(Backlog),
  defect_rate             ~ 0.01 * length_of_workday / time_allocated_per_unit,
  arrival_rate            ~ base_arrivals + pulse_size * pulse(20, 10),
  fulfillment_rate        ~ number_of_employees * length_of_workday /
                            time_allocated_per_unit * (1 - defect_rate)
)

def_pars <- sd_parameters(
  constant(number_of_employees = 2, base_arrivals = 10, pulse_size = 12),
  initial(Backlog = 11.7),
  lookup_data("influence_of_backlog_on_speed",
    x = c(0, 5, 10, 15, 20, 80),
    y = c(0.1, 0.1, 0.09, 0.05, 0.04, 0.04)),
  lookup_data("influence_of_backlog_on_workday",
    x = c(0, 2.76986, 5.53971, 10.3462, 13.1161, 16.5377, 20.5295, 60),
    y = c(0.1, 0.128571, 0.188095, 0.347619, 0.416667, 0.452381, 0.469048, 0.5))
)

spec <- sim_spec(start = 0, stop = 50, dt = 0.015625, method = "euler",
                 time_unit = "day")
out  <- simulate(def_struct, def_eqns, def_pars, spec = spec)
```

`pulse(start, width)` follows Vensim's argument order, as `step(height, time)`
and `ramp(slope, start, end)` already do in §8 and §13; the height is multiplied
on, so it stays a parameter rather than an argument.

---

## 17. Atmospheric carbon bathtub

The smallest possible climate model, and the cookbook's example of driving a
model from a file: excess atmospheric carbon accumulates emissions and loses 1 %
of itself per year. It exists to make the bathtub point — with emissions rising
and removal proportional to the *stock*, the stock cannot stabilise while
emissions grow. Driven by the CDIAC global fossil-fuel and cement emissions
series it reaches about 269,000 MtC of excess carbon by 2011 (my own Euler
integration at `dt = 1`).

The driver is `source/data/Climate/global_emissions.csv` — Boden, Marland and
Andres' global emissions estimates, 1751–2011, one row per year; the data is not
reproduced here.

**Vensim** — `source/models/Climate/Atmospheric_Bathtub.mdl`

```
Emissions                = 0
Natural Removal          = Excess Atmospheric Carbon * Removal Constant
Removal Constant         = 0.01
Excess Atmospheric Carbon = INTEG(Emissions - Natural Removal, 0)
INITIAL TIME = 0   FINAL TIME = 100   TIME STEP = 1
```

**tidysd** — the `.mdl` hard-codes `Emissions = 0` and PySD overrides it at run
time with a `params=` argument. In `tidysd` the *structure* says there is an
exogenous driver called `emissions`; which series fills it is a parameter, so
swapping "total" for "solid fuel only" never touches the model text.

```r
carbon_struct <- sd_structure(
  meta(name = "Atmospheric carbon bathtub"),
  stock("ExcessAtmosphericCarbon", units = "MtC", non_negative = TRUE),
  input("emissions", units = "MtC/year"),
  flow("emission_flow",  from = .source, to = "ExcessAtmosphericCarbon",
       units = "MtC/year"),
  flow("natural_removal", from = "ExcessAtmosphericCarbon", to = .sink,
       units = "MtC/year")
)

carbon_eqns <- sd_equations(
  emission_flow   ~ emissions,
  natural_removal ~ ExcessAtmosphericCarbon * removal_constant
)

# two columns: time, value
global_emissions <- readr::read_csv("global_emissions.csv", skip = 2)[, 1:2]

carbon_pars <- sd_parameters(
  constant(removal_constant = 0.01),
  initial(ExcessAtmosphericCarbon = 0),
  input_series("emissions", data = global_emissions, interp = "linear")
)

spec <- sim_spec(start = 1751, stop = 2011, dt = 1, method = "euler",
                 time_unit = "year")
out  <- simulate(carbon_struct, carbon_eqns, carbon_pars, spec = spec)

# counterfactual: emissions frozen at their 1990 level
carbon_pars_flat <- update(carbon_pars, input_series("emissions", data = flat_1990))
```

An `input()` is an aux whose values come from data rather than a formula. It is
declared in structure like anything else, so the dependency graph and the unit
check see it; only the series itself is a parameter.

---

## 18. Rössler attractor

Three stocks, no lookups, no parameters beyond three constants — the minimum
structure that produces deterministic chaos. Each flow is a *signed net rate*,
so the stocks move in both directions. With `a = b = 0.2`, `c = 5.7` the
trajectory spirals outward in the `x`–`y` plane and is periodically thrown up
the `z` axis: RK4 at the file's `dt` gives `x` in about [−9.1, 11.4] with `z`
spiking to ≈22.6 and a mean spiral-peak spacing of ≈5.95 time units (my own
integration). Euler at the same `dt` is not accurate enough — it inflates the
`z` spikes to ≈35.9 — which makes this the entry where `method` matters.

**Vensim** — `source/models/Roessler_Chaos/roessler_chaos.mdl`

```
a = 0.2      b = 0.2      c = 5.7
dxdt = -y - z
dydt = x + a*y
dzdt = b + z*(x - c)
x = INTEG(dxdt, 0.5)
y = INTEG(dydt, 0.5)
z = INTEG(dzdt, 0.4)
INITIAL TIME = 0   FINAL TIME = 100   TIME STEP = 0.03125
```

**tidysd** — the units are left unspecified throughout: these are abstract state
variables, so there is nothing for a unit checker to bless.

```r
roessler_struct <- sd_structure(
  meta(name = "Roessler attractor"),
  stock("x"), stock("y"), stock("z"),          # no non_negative: all three go negative
  flow("dxdt", from = .source, to = "x"),      # net rates, signed
  flow("dydt", from = .source, to = "y"),
  flow("dzdt", from = .source, to = "z")
)

roessler_eqns <- sd_equations(
  dxdt ~ -y - z,
  dydt ~ x + a * y,
  dzdt ~ b + z * (x - c)
)

roessler_pars <- sd_parameters(
  constant(a = 0.2, b = 0.2, c = 5.7),
  initial(x = 0.5, y = 0.5, z = 0.4)
)

spec <- sim_spec(start = 0, stop = 100, dt = 0.03125, method = "rk4")
out  <- simulate(roessler_struct, roessler_eqns, roessler_pars, spec = spec)

autoplot(out, x = "x", y = "y")                # phase portrait, not a time series
```

A flow declared `from = .source` whose value is negative simply runs backwards —
a biflow. Nothing in the grammar forbids it; `non_negative = TRUE` on a stock is
the opt-in that would.

---

## 19. Single pendulum

A second-order mechanical system written the SD way: two stocks in a chain,
where the flow into position *is* the other stock. Undamped, so it should
conserve energy — a 10 m, 10 kg pendulum released at 1 radian has a period of
6.768 s against the small-angle 2π√(L/g) = 6.347 s (my own RK4 integration).
Euler at the file's `dt` pumps energy in instead: the amplitude climbs from 1.00
to 1.40 rad by t = 100 and the period stretches with it.

**Vensim** — `source/models/Pendulum/Single_Pendulum.mdl`

```
Acceleration due to Gravity = -9.8                  ~ Meters/Second/Second
Mass of Pendulum            = 10                    ~ Kilogram
Length of Pendulum          = 10                    ~ Meter
Force of Gravity            = Acceleration due to Gravity * Mass of Pendulum
Angular component of Gravity = Force of Gravity * SIN(Angular Position)
Torque                      = Angular component of Gravity * Length of Pendulum
Pendulum Moment of Inertia  = Mass of Pendulum * Length of Pendulum^2
Change in Angular Velocity  = Torque / Pendulum Moment of Inertia
Change in Angular Position  = Angular Velocity
Angular Velocity = INTEG(Change in Angular Velocity, 0)
Angular Position = INTEG(Change in Angular Position, 1)     ~ radians
INITIAL TIME = 0   FINAL TIME = 100   TIME STEP = 0.0078125   SAVEPER = 0.1
```

**tidysd**

```r
pend_struct <- sd_structure(
  meta(name = "Single pendulum"),
  stock("AngularPosition", units = "radian"),
  stock("AngularVelocity", units = "radian/second"),
  aux("force_of_gravity",            units = "kg*m/second^2"),
  aux("angular_component_of_gravity", units = "kg*m/second^2"),
  aux("torque",                      units = "kg*m^2/second^2"),
  aux("moment_of_inertia",           units = "kg*m^2"),
  flow("change_in_angular_position", from = .source, to = "AngularPosition",
       units = "radian/second"),
  flow("change_in_angular_velocity", from = .source, to = "AngularVelocity",
       units = "radian/second^2")
)

pend_eqns <- sd_equations(
  force_of_gravity             ~ gravity * mass,
  angular_component_of_gravity ~ force_of_gravity * sin(AngularPosition),
  torque                       ~ angular_component_of_gravity * length,
  moment_of_inertia            ~ mass * length^2,
  change_in_angular_velocity   ~ torque / moment_of_inertia,
  change_in_angular_position   ~ AngularVelocity
)

pend_pars <- sd_parameters(
  constant(gravity = -9.8, mass = 10, length = 10),
  initial(AngularPosition = 1, AngularVelocity = 0)
)

spec <- sim_spec(start = 0, stop = 100, dt = 0.0078125, method = "rk4",
                 time_unit = "second", saveat = 0.1)
out  <- simulate(pend_struct, pend_eqns, pend_pars, spec = spec)
```

Both flows are signed, as in §18. The model is also the clean case for a
`method` warning: an undamped oscillator integrated with Euler drifts in a
direction the modeller can see, and `sim_spec(method = )` is the only place to
fix it — no equation changes.

---

## 20. Sales agent motivation

A new insurance agent's motivation is a stock adjusting toward their income;
income depends on sales, sales on effort, and effort on motivation through a
sharply convex graphical function — a reinforcing loop that runs either way. A
start-up subsidy holds income near 1.02 months-of-expenses per month for the
first 6 months; when it stops, income falls to 0.47 and the loop reverses.
Motivation crosses the quitting threshold at month 16.75, after 22.8 cumulative
sales, and a subsidy three times larger buys only about three extra months of
tenure (my own integration).

**Vensim** — `source/models/Sales_Agents/Sales_Agent_Motivation_Dynamics.mdl`

```
Impact of Motivation on Effort(
    [(0,0)-(10,1)],(0,0),(0.285132,0.0616114),(0.448065,0.232228),(0.570265,0.492891),
    (0.733198,0.772512),(0.95723,0.862559),(1.4664,0.914692),(3.19756,0.952607),
    (4.03259,0.957346))

Still Employed        = IF THEN ELSE(Motivation > Motivation Threshold, 1, 0)
Sales Effort Available= IF THEN ELSE(Still Employed > 0,
                          Total Effort Available * Fraction of Effort for Sales, 0)
Effort                = Sales Effort Available * Impact of Motivation on Effort(Motivation)
Sales                 = Effort / Effort Required to Make a Sale * Success Rate
Income                = Months of Expenses per Sale * Sales
                        + IF THEN ELSE(Time < Startup Subsidy Length, Startup Subsidy, 0)
Motivation Adjustment = (Income - Motivation) / Motivation Adjustment Time
Motivation            = INTEG(Motivation Adjustment, 1)

Tenure               = INTEG(Still Employed, 0)
Total Cumulative Sales  = INTEG(Sales, 0)
Total Cumulative Income = INTEG(Income, 0)

Motivation Threshold = 0.1    Total Effort Available = 200
Fraction of Effort for Sales = 0.25   Effort Required to Make a Sale = 4
Success Rate = 0.2   Months of Expenses per Sale = 12/50
Motivation Adjustment Time = 3   Startup Subsidy = 0.5   Startup Subsidy Length = 6
INITIAL TIME = 0   FINAL TIME = 200   TIME STEP = 0.0625
```

**tidysd** — `Tenure`, `Total Cumulative Sales` and `Total Cumulative Income` are
pure accumulators: a stock whose inflow is an existing variable and which nothing
feeds back on. They are still stocks, so they stay in `sd_structure()`.

```r
sa_struct <- sd_structure(
  meta(name = "Sales agent motivation"),
  stock("Motivation",           units = "1"),
  stock("Tenure",               units = "month"),
  stock("TotalCumulativeSales", units = "person"),
  stock("TotalCumulativeIncome", units = "month"),

  lookup("impact_of_motivation_on_effort", input = "Motivation",
         out_units = "1", interp = "linear", range = "clamp"),

  aux("still_employed",         units = "1"),
  aux("sales_effort_available", units = "hour/month"),
  aux("effort",                 units = "hour/month"),
  aux("sales",                  units = "person/month"),
  aux("income",                 units = "month/month"),

  flow("motivation_adjustment", from = .source, to = "Motivation", units = "1/month"),
  flow("accumulating_tenure",   from = .source, to = "Tenure",     units = "month/month"),
  flow("accumulating_sales",    from = .source, to = "TotalCumulativeSales",
       units = "person/month"),
  flow("accumulating_income",   from = .source, to = "TotalCumulativeIncome",
       units = "month/month")
)

sa_eqns <- sd_equations(
  still_employed         ~ ifelse(Motivation > motivation_threshold, 1, 0),
  sales_effort_available ~ total_effort_available * fraction_of_effort_for_sales *
                           still_employed,
  effort                 ~ sales_effort_available *
                           impact_of_motivation_on_effort(Motivation),
  sales                  ~ effort / effort_required_per_sale * success_rate,
  income                 ~ months_of_expenses_per_sale * sales +
                           ifelse(t < startup_subsidy_length, startup_subsidy, 0),
  motivation_adjustment  ~ (income - Motivation) / motivation_adjustment_time,
  accumulating_tenure    ~ still_employed,
  accumulating_sales     ~ sales,
  accumulating_income    ~ income
)

sa_pars <- sd_parameters(
  constant(motivation_threshold = 0.1, total_effort_available = 200,
           fraction_of_effort_for_sales = 0.25, effort_required_per_sale = 4,
           success_rate = 0.2, months_of_expenses_per_sale = 12 / 50,
           motivation_adjustment_time = 3,
           startup_subsidy = 0.5, startup_subsidy_length = 6),
  initial(Motivation = 1, Tenure = 0,
          TotalCumulativeSales = 0, TotalCumulativeIncome = 0),
  lookup_data("impact_of_motivation_on_effort",
    x = c(0, 0.285132, 0.448065, 0.570265, 0.733198, 0.95723, 1.4664, 3.19756, 4.03259),
    y = c(0, 0.0616114, 0.232228, 0.492891, 0.772512, 0.862559, 0.914692,
          0.952607, 0.957346))
)

spec <- sim_spec(start = 0, stop = 200, dt = 0.0625, method = "euler",
                 time_unit = "month")

out <- simulate(sa_struct, sa_eqns, sa_pars, spec = spec,
  scenarios = scenarios(
    base    = list(),
    bigger  = list(startup_subsidy = 1.5),
    longer  = list(startup_subsidy_length = 12),
    both    = list(startup_subsidy = 1.5, startup_subsidy_length = 12)
  ))
```

The original multiplies `Sales Effort Available` by `Still Employed` inside an
`IF THEN ELSE`; the `tidysd` version multiplies by the 0/1 flag directly, which
is the same thing and reads better. `Still Employed` is a latch in the original's
intent but not in its equations — an agent whose motivation recovered would be
re-hired. Faithfully copied, latch and all left out.

---

## 21. Capability trap

Repenning and Sterman's archetype. `Capability` is built by time spent
improving and erodes on a 20-week timescale; two pressure stocks chase the
"stretch" between desired and actual performance. Pressure to do work buys
output now (a longer workday) but *shortens* improvement time — the second
lookup multiplies the first — so the fast loop starves the slow one. At the
shipped defaults the model sits in exact equilibrium (`Stretch = 1`, capability
100, performance 3000/week); a `Pressure Step` of −0.05 at week 10 drives
capability to ≈61 and performance to ≈2075 by week 40 and it never recovers
(≈66 / 2194 at week 100), while +0.1 escapes upward to ≈137 / 3518 (my own
integration).

**Vensim** — `source/models/Capability_Trap/Capability Trap.mdl`

```
Influence of Work Pressure on Improvement Time(
    [(0,0)-(10,10)],(0,1),(1,1),(1.5,0.75),(2,0.25),(5,0))
Influence of Capability Pressure on Improvement Time(
    [(-1,-1)-(10,10)],(0,0),(0.5,0),(0.75,0.5),(1,1),(2,1.5),(5,1.5))
Influence of Pressure on Work Time(
    [(0,0)-(10,2)],(0,0.75),(0.75,0.75),(1,1),(1.25,1.25),(2,1.5),(10,1.5))

Time Spend on Improvement = Normal Time Spent on Improvement
    * Influence of Capability Pressure on Improvement Time(Pressure to Improve Capability)
    * Influence of Work Pressure on Improvement Time(Pressure to Do Work)
Time Spent Working = MIN(Normal Time Spent Working
    * Influence of Pressure on Work Time(Pressure to Do Work),
    Maximum Work Time - Time Spend on Improvement)
Actual Performance  = Capability * Time Spent Working
Desired Performance = 3000 + STEP(Performance Step, 10)
Stretch             = Desired Performance / Actual Performance

Investment in Capability = Time Spend on Improvement * Capability improvement per investment
Capability Erosion       = Capability / Erosion Timescale
Capability = INTEG(Investment in Capability - Capability Erosion, 100)

Exogenous Capability Pressure = STEP(Pressure Step, 10)
Change in Pressure to Do Work = (Stretch - Pressure to Do Work) / Work Harder Adjustment Time
Change in Pressure to Improve Capability =
    (Stretch - Pressure to Improve Capability) / Improve Capability Adjustment Time
    + Exogenous Capability Pressure
Pressure to Do Work           = INTEG(Change in Pressure to Do Work, 1)
Pressure to Improve Capability = INTEG(Change in Pressure to Improve Capability, 1)

Normal Time Spent on Improvement = 10   Normal Time Spent Working = 30
Maximum Work Time = 40   Erosion Timescale = 20
Capability improvement per investment = 0.5
Work Harder Adjustment Time = 3   Improve Capability Adjustment Time = 9
Performance Step = 0   Pressure Step = 0
INITIAL TIME = 0   FINAL TIME = 100   TIME STEP = 0.0625
```

**tidysd** — the two pressures are stocks whose only flow is a signed adjustment,
so they are written the same way as `Motivation` in §20.

```r
ct_struct <- sd_structure(
  meta(name = "Capability trap"),
  stock("Capability",                  units = "widget/(person*hour)"),
  stock("PressureToDoWork",            units = "1"),
  stock("PressureToImproveCapability", units = "1"),

  lookup("influence_of_work_pressure_on_improvement", input = "PressureToDoWork",
         out_units = "1", interp = "linear", range = "clamp"),
  lookup("influence_of_capability_pressure_on_improvement",
         input = "PressureToImproveCapability",
         out_units = "1", interp = "linear", range = "clamp"),
  lookup("influence_of_pressure_on_work_time", input = "PressureToDoWork",
         out_units = "1", interp = "linear", range = "clamp"),

  aux("time_spent_on_improvement", units = "person*hour/week"),
  aux("time_spent_working",        units = "person*hour/week"),
  aux("actual_performance",        units = "widget/week"),
  aux("desired_performance",       units = "widget/week"),
  aux("stretch",                   units = "1"),
  aux("exogenous_capability_pressure", units = "1/week"),

  flow("investment_in_capability", from = .source,      to = "Capability"),
  flow("capability_erosion",       from = "Capability", to = .sink),
  flow("change_in_pressure_to_do_work", from = .source,
       to = "PressureToDoWork", units = "1/week"),
  flow("change_in_pressure_to_improve", from = .source,
       to = "PressureToImproveCapability", units = "1/week")
)

ct_eqns <- sd_equations(
  time_spent_on_improvement ~ normal_time_on_improvement *
    influence_of_capability_pressure_on_improvement(PressureToImproveCapability) *
    influence_of_work_pressure_on_improvement(PressureToDoWork),
  time_spent_working ~ min(normal_time_working *
                             influence_of_pressure_on_work_time(PressureToDoWork),
                           maximum_work_time - time_spent_on_improvement),

  actual_performance  ~ Capability * time_spent_working,
  desired_performance ~ 3000 + step(performance_step, 10),
  stretch             ~ desired_performance / actual_performance,

  investment_in_capability ~ time_spent_on_improvement * capability_per_investment,
  capability_erosion       ~ Capability / erosion_timescale,

  exogenous_capability_pressure ~ step(pressure_step, 10),
  change_in_pressure_to_do_work ~ (stretch - PressureToDoWork) /
                                  work_harder_adjustment_time,
  change_in_pressure_to_improve ~ (stretch - PressureToImproveCapability) /
                                  improve_capability_adjustment_time +
                                  exogenous_capability_pressure
)

ct_pars <- sd_parameters(
  constant(normal_time_on_improvement = 10, normal_time_working = 30,
           maximum_work_time = 40, erosion_timescale = 20,
           capability_per_investment = 0.5,
           work_harder_adjustment_time = 3, improve_capability_adjustment_time = 9,
           performance_step = 0, pressure_step = 0),
  initial(Capability = 100, PressureToDoWork = 1, PressureToImproveCapability = 1),
  lookup_data("influence_of_work_pressure_on_improvement",
    x = c(0, 1, 1.5,  2,    5),
    y = c(1, 1, 0.75, 0.25, 0)),
  lookup_data("influence_of_capability_pressure_on_improvement",
    x = c(0, 0.5, 0.75, 1, 2,   5),
    y = c(0, 0,   0.5,  1, 1.5, 1.5)),
  lookup_data("influence_of_pressure_on_work_time",
    x = c(0,    0.75, 1, 1.25, 2,   10),
    y = c(0.75, 0.75, 1, 1.25, 1.5, 1.5))
)

spec <- sim_spec(start = 0, stop = 100, dt = 0.0625, method = "euler",
                 time_unit = "week")

out <- simulate(ct_struct, ct_eqns, ct_pars, spec = spec,
  scenarios = scenarios(
    equilibrium = list(),
    trap        = list(pressure_step = -0.05),
    escape      = list(pressure_step =  0.1),
    demand      = list(performance_step = 500)
  ))
```

`investment_in_capability` and `capability_erosion` are left unit-unspecified:
the original's `Capability improvement per investment` carries
`Widgets/Person Hour/Person Hour`, which makes the flow's units the stock's
units per *week* only by convention, not by algebra. The `step()` calls sit
directly in the equations while their heights stay parameters, so the whole
policy space is a `scenarios()` list.

---

## 22. Boarding-school flu — SIR fitted to real data

The 1978 English boarding-school influenza outbreak (*BMJ*, 4 March 1978): 763
boys, one index case, daily counts of boys confined to bed over about two weeks.
An SIR model with mass-action transmission is fitted to those counts —
`calibrate()` estimates the contact rate and the infectious period against the
observed `I`. Duggan's `FME::modFit` returns `beta ≈ 2.18e-3` day⁻¹ and an
infectious period ≈ 2.02 days, i.e. `R0 = beta · S(0) · period ≈ 3.4`.

**Duggan** — `SDMR/models/07 Chapter/R/04 BoardingSchool.R`; data
`BoardingSchool.xlsx` (columns `time`, `sInfected`)

```r
library(deSolve); library(FME)

inf_data <- read.xls("BoardingSchool.xlsx")          # time, sInfected
simtime  <- seq(0, 20, by = 0.125)

model <- function(time, stocks, auxs){
  with(as.list(c(stocks, auxs)), {
    aLambda <- aBeta * sInfected
    fIR <- sSusceptible * aLambda
    fRR <- sInfected / aDelay
    list(c(-fIR, fIR - fRR, fRR))
  })
}

solveSIR <- function(pars){
  stocks <- c(sSusceptible = 762, sInfected = 1, sRecovered = 0)
  auxs   <- c(aBeta = pars["aBeta"], aDelay = pars["aDelay"])
  data.frame(ode(stocks, simtime, model, auxs, method = "rk4"))
}

getCost <- function(p) modCost(obs = inf_data, model = solveSIR(p))

Fit <- modFit(p = c(aBeta = 0.001, aDelay = 2.0), f = getCost,
              lower = c(0.0, 1.0), upper = c(0.01, 5.0))
Fit$par                                              # aBeta ~ 2.18e-3, aDelay ~ 2.02
```

**tidysd** — the structure and equations are §5's SIR (mass-action variant); only
the parameters change, because they are what the fit produces.

```r
bsflu <- readxl::read_excel("BoardingSchool.xlsx")   # columns: time, sInfected

bs_struct <- sd_structure(
  meta(name = "Boarding-school flu"),
  stock("S", units = "boys", non_negative = TRUE),
  stock("I", units = "boys", non_negative = TRUE),
  stock("R", units = "boys", non_negative = TRUE),
  aux("lambda", units = "1/day"),
  flow("IR", from = "S", to = "I", units = "boys/day"),
  flow("RR", from = "I", to = "R", units = "boys/day")
)

bs_eqns <- sd_equations(
  lambda ~ beta * I,                 # mass-action (absolute) contact rate
  IR     ~ S * lambda,
  RR     ~ I / infectious_period
)

bs_pars <- sd_parameters(
  constant(beta = 0.001, infectious_period = 2),     # starting guesses
  initial(S = 762, I = 1, R = 0)
)

spec <- sim_spec(start = 0, stop = 20, dt = 0.125, method = "rk4", time_unit = "day")

fit <- calibrate(bs_struct, bs_eqns, bs_pars,
                 spec     = spec,
                 observed = bsflu,
                 target   = c(I = "sInfected"),      # model var -> observed column
                 free     = c("beta", "infectious_period"),
                 lower    = c(beta = 0,    infectious_period = 1),
                 upper    = c(beta = 0.01, infectious_period = 5))

fit$parameters      # beta ~ 2.18e-3, infectious_period ~ 2.02  — matches Duggan
fit$fit             # SSE, convergence

out <- simulate(bs_struct, bs_eqns, fit$parameters, spec = spec, observed = bsflu)
autoplot(out, vars = "I")            # fitted curve + observed points, one panel
```

`calibrate()` takes the same three layers as `simulate()`, plus the observed
frame, a `target` map from model variable to data column, the `free` constants,
and bounds; it returns a fitted `sd_parameters` you pass straight back to
`simulate()`. `observed =` on `simulate()` is independent of the fit — it just
carries the data through to the output tibble (`source = "observed"`) so
`autoplot()` can overlay it.

---

## Appendix A — how other tools handle cohorts / subscripts

Two families. The **index** family adds a named dimension to variables, writes
each equation once (element-wise), and uses a reduction operator for the matrix
sum `Lambda[c] = Σⱼ beta[c,j]·I[j]`:

| Tool | how that sum is written |
|---|---|
| Vensim | `SUM(beta[cohort, cohort2!] * Infected[cohort2!])` — `!` marks the summed axis |
| Stella / iThink | `SUM(beta[Cohort, *] * Infected[*])` — `*` wildcard |
| PySD (xarray) | `(beta * Infected).sum("cohort2")` — align by dimension name |
| ModelingToolkit.jl | `CE * I` — plain broadcasting |
| **tidysd (proposed)** | `(CE %*% I) / pop`, or `sum(CE * I[c2], over = "c2")` for the general case |

The **composition** family (StockFlow.jl) never writes an index: build the base
SIR and a small model of the age structure, then `stratify(sir, age_model)`
replicates and rewires every stock and flow automatically — the contact matrix
lives in the gluing, not in a parameter.

`tidysd`'s proposal sits with the index family (closest to PySD / MTK), with the
payoff that a subscript is just another column in the output tibble:
`autoplot(out) + facet_wrap(~cohort)`.

---

## Appendix B — prior art

- **seminr** (R) — the layered constructor-DSL this design follows.
- **sdbuildR** (R) — pipe-chain builder; deSolve or Julia backend.
- **readsdr** (R) — XMILE (Stella / Vensim) import to deSolve / Stan / igraph.
- **deSolve** (R) — the raw ODE substrate; Duggan's book style.
- **PySD**, **BPTK-Py** (Python) — import-first and OO-builder approaches.
- **StockFlow.jl** (Julia) — categorical composition and stratification.
- **sfcr** (R) — formula-list DSL for stock-flow-consistent macro models.
- **XMILE** — the interchange standard behind every GUI tool.
