# Built-in functions on an equation right-hand side

These names are recognised inside \[sd_equations()\]. They are rewritten
when the model is bound, so they are not ordinary R functions you can
call directly.

## Details

- \`step(height, time)\`:

  0 before \`time\`, \`height\` from \`time\` on.

- \`pulse(start, width)\`:

  1 during \`\[start, start + width)\`, else 0.

- \`ramp(slope, start, end)\`:

  0, then a linear rise of \`slope\`, held flat after \`end\`.

- \`delayN(x, delay, order, initial)\`:

  Exponential (material) delay of \`x\`: a cascade of \`order\` stocks.
  \`initial\` is the delay's \*output\* level at \`t = start\`,
  defaulting to \`x\` there. \`order\` defaults to 1 and is read once,
  at initialisation.

- \`smoothN(x, time, order, initial)\`:

  Information smoothing of \`x\` with adjustment time \`time\`, at any
  \`order\` (1 by default). \`initial\` defaults to \`x\` at \`t =
  start\`.

- \`delay_fixed(x, delay, initial)\`:

  Pipeline delay: whatever goes in comes out unchanged, exactly
  \`delay\` later. \`delay\` may vary and is rounded to the nearest
  whole \`dt\`.

- \`forecast(x, average_time, horizon)\`:

  Trend extrapolation, sugar over \`smoothN\`: \`x \* (1 + horizon \*
  (x - s) / (s \* average_time))\`.

- \`previous(x, init)\`:

  The value \`x\` held at the previous saved step.

- \`t\`, \`dt\`:

  Current time and the integration step.

Base-R maths (\`ifelse\`, \`min\`, \`max\`, \`sqrt\`, \`sin\`, \`exp\`,
\`log\`, \`sum\`, \`
