# tidysd: a tidy grammar for system dynamics

Specify a stock-and-flow model as three independent layers and simulate
it with one verb:

## Details


    sd_structure()    what exists, how it is wired      (no math)
    sd_equations()    functional forms                  (symbolic)
    sd_parameters()   the numbers and data

    simulate(structure, equations, parameters, spec = sim_spec())

There is no compile step: binding and validation happen inside
\[simulate()\]. The "model" is just the three layer objects.

## See also

Useful links:

- <https://rayhanalirachman.github.io/tidySD/>

- <https://github.com/rayhanalirachman/tidySD>

- Report bugs at <https://github.com/rayhanalirachman/tidySD/issues>

## Author

**Maintainer**: Rayhan Ali Rachman <rayhanalirachman@gmail.com>

Authors:

- Rayhan Ali Rachman <rayhanalirachman@gmail.com>
