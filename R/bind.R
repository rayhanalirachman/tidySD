## ---------------------------------------------------------------------------
## Binding: structure + equations + parameters + spec -> a runnable model.
## There is no user-facing compile step; `simulate()` calls this.
## ---------------------------------------------------------------------------

make_lookup_fun <- function(nm, x, y, interp, range) {
  method <- if (identical(interp, "linear")) "linear" else "constant"
  rule <- if (identical(range, "na")) 1 else 2
  base <- stats::approxfun(x, y, method = method, rule = rule, f = 0, ties = "ordered")
  if (!identical(range, "extend")) {
    force(base)
    return(function(v) base(as.numeric(v)))
  }
  n <- length(x)
  sl <- if (n >= 2L) c((y[2] - y[1]) / (x[2] - x[1]),
                       (y[n] - y[n - 1L]) / (x[n] - x[n - 1L])) else c(0, 0)
  function(v) {
    v <- as.numeric(v)
    out <- base(v)
    lo <- v < x[1]; hi <- v > x[n]
    if (any(lo)) out[lo] <- y[1] + sl[1] * (v[lo] - x[1])
    if (any(hi)) out[hi] <- y[n] + sl[2] * (v[hi] - x[n])
    out
  }
}

make_input_fun <- function(nm, series, spec) {
  d <- series$data
  cols <- names(d)
  tcol <- cols[tolower(cols) == "time"]
  if (!length(tcol)) tcol <- cols[1]
  tcol <- tcol[1]
  vcol <- series$value_col
  if (is.null(vcol)) {
    cand <- setdiff(cols, tcol)
    if (nm %in% cand) vcol <- nm
    else if (length(cand) == 1L) vcol <- cand
    else sd_abort(sprintf("`input_series(\"%s\")` has %d candidate value columns.",
                          nm, length(cand)),
                  i = "Name one with `value_col = `.")
  }
  if (!vcol %in% cols)
    sd_abort(sprintf("`input_series(\"%s\", value_col = \"%s\")`: no such column.", nm, vcol))

  tt <- d[[tcol]]
  if (inherits(tt, "Date") || inherits(tt, "POSIXct")) {
    tt <- as.numeric(difftime(tt, min(tt), units = "days")) + spec$start
  }
  tt <- as.numeric(tt)
  vv <- as.numeric(d[[vcol]])
  keep <- !is.na(tt) & !is.na(vv)
  tt <- tt[keep]; vv <- vv[keep]
  o <- order(tt); tt <- tt[o]; vv <- vv[o]
  if (!length(tt)) sd_abort(sprintf("`input_series(\"%s\")` has no usable rows.", nm))
  if (length(tt) == 1L) {
    v0 <- vv[1]
    return(function(time) rep(v0, length(time)))
  }
  make_lookup_fun(nm, tt, vv, series$interp,
                  switch(series$range, hold = "clamp", extend = "extend", na = "na"))
}

## Build the environment that holds constants, lookups and inputs.
make_base_env <- function(constants, lookup_funs, input_funs, spec) {
  env <- new.env(parent = asNamespace("tidysd"))
  for (nm in names(constants)) assign(nm, constants[[nm]], envir = env)
  for (nm in names(lookup_funs)) assign(nm, lookup_funs[[nm]], envir = env)
  for (nm in names(input_funs)) assign(paste0(".inp_", nm), input_funs[[nm]], envir = env)
  env$dt <- spec$dt
  env
}

sd_bind <- function(struct, eqns, pars, spec, overrides = list()) {
  if (!inherits(struct, "sd_structure")) sd_abort("`structure` must come from `sd_structure()`.")
  if (!inherits(eqns, "sd_equations")) sd_abort("`equations` must come from `sd_equations()`.")
  if (!inherits(pars, "sd_parameters")) sd_abort("`parameters` must come from `sd_parameters()`.")
  if (!inherits(spec, "sim_spec")) sd_abort("`spec` must come from `sim_spec()`.")

  vars <- struct$vars
  stock_nms  <- struct_names(struct, "stock")
  flow_nms   <- struct_names(struct, "flow")
  aux_nms    <- struct_names(struct, "aux")
  lookup_nms <- struct_names(struct, "lookup")
  input_nms  <- struct_names(struct, "input")

  ## ---- constants (with scenario overrides) --------------------------------
  constants <- pars$constants
  if (length(overrides)) {
    unknown <- setdiff(names(overrides), names(constants))
    if (length(unknown))
      sd_abort(sprintf("Scenario override(s) for unknown constant(s): %s.", comma(unknown)),
               i = "Only constants declared in `sd_parameters()` can be overridden.")
    constants <- utils::modifyList(constants, overrides)
  }

  ## ---- lookups and inputs -------------------------------------------------
  missing_lk <- setdiff(lookup_nms, names(pars$lookups))
  if (length(missing_lk))
    sd_abort(sprintf("No `lookup_data()` for lookup(s): %s.", comma(missing_lk)))
  extra_lk <- setdiff(names(pars$lookups), lookup_nms)
  if (length(extra_lk))
    sd_abort(sprintf("`lookup_data()` given for undeclared lookup(s): %s.", comma(extra_lk)),
             i = "Declare them with `lookup()` in `sd_structure()`.")
  lookup_funs <- lapply(lookup_nms, function(nm) {
    d <- pars$lookups[[nm]]
    make_lookup_fun(nm, d$x, d$y, vars[[nm]]$interp, vars[[nm]]$range)
  })
  names(lookup_funs) <- lookup_nms

  missing_in <- setdiff(input_nms, names(pars$inputs))
  if (length(missing_in))
    sd_abort(sprintf("No `input_series()` for input(s): %s.", comma(missing_in)))
  extra_in <- setdiff(names(pars$inputs), input_nms)
  if (length(extra_in))
    sd_abort(sprintf("`input_series()` given for undeclared input(s): %s.", comma(extra_in)),
             i = "Declare them with `input()` in `sd_structure()`.")
  input_funs <- lapply(input_nms, function(nm) make_input_fun(nm, pars$inputs[[nm]], spec))
  names(input_funs) <- input_nms

  ## ---- equations belong to declared flows / auxes --------------------------
  computed_nms <- c(flow_nms, aux_nms)
  eq_named <- Filter(function(e) !e$is_init, eqns$eqns)
  eq_init <- Filter(function(e) e$is_init, eqns$eqns)

  have <- vapply(eq_named, function(e) e$name, character(1))
  unknown <- setdiff(have, computed_nms)
  if (length(unknown)) {
    hint <- intersect(unknown, c(stock_nms, lookup_nms, input_nms))
    sd_abort(sprintf("Equation(s) for undeclared variable(s): %s.", comma(unknown)),
             i = if (length(hint))
               sprintf("%s %s declared, but not as a flow or aux.",
                       comma(hint), if (length(hint) > 1) "are" else "is")
             else "Declare them with `flow()` or `aux()` in `sd_structure()`.")
  }
  missing_eq <- setdiff(computed_nms, have)
  if (length(missing_eq))
    sd_abort(sprintf("No equation for: %s.", comma(missing_eq)))

  bad_init <- setdiff(vapply(eq_init, function(e) e$name, character(1)), stock_nms)
  if (length(bad_init))
    sd_abort(sprintf("`init()` given for something that is not a stock: %s.", comma(bad_init)))

  ## ---- expand the built-ins ------------------------------------------------
  const_env <- new.env(parent = asNamespace("tidysd"))
  for (nm in names(constants)) assign(nm, constants[[nm]], envir = const_env)
  const_env$t <- spec$start
  const_env$dt <- spec$dt
  ctx <- new_expand_ctx(const_env)

  node_expr <- list()
  for (nm in input_nms) {
    node_expr[[nm]] <- bquote(.(as.symbol(paste0(".inp_", nm)))(t))
  }
  for (e in eq_named) {
    node_expr[[e$name]] <- expand_expr(e$rhs, ctx, e$name)
  }
  init_only <- list()
  for (nm in names(ctx$nodes)) node_expr[[nm]] <- ctx$nodes[[nm]]
  for (nm in names(ctx$init_nodes)) init_only[[nm]] <- ctx$init_nodes[[nm]]

  ## ---- stocks --------------------------------------------------------------
  stocks <- list()
  for (nm in stock_nms) {
    v <- vars[[nm]]
    len <- var_length(struct, v)
    has_num <- nm %in% names(pars$initials)
    ie <- Filter(function(e) e$name == nm, eq_init)
    if (has_num && length(ie))
      sd_abort(sprintf("Stock '%s' has both a numeric `initial()` and an `init()` equation.", nm),
               i = "Each stock's initial value comes from exactly one place.")
    if (!has_num && !length(ie))
      sd_abort(sprintf("Stock '%s' has no initial value.", nm),
               i = "Give it a number in `initial()` or a formula with `init()`.")
    init_expr <- if (has_num) broadcast(pars$initials[[nm]], len, nm, struct, v) else
      expand_expr(ie[[1]]$rhs, ctx, nm)
    stocks[[nm]] <- list(name = nm, len = len, dims = v$dims,
                         non_negative = isTRUE(v$non_negative),
                         internal = FALSE, init_expr = init_expr)
  }
  for (nm in names(ctx$stocks)) {
    stocks[[nm]] <- list(name = nm, len = NA_integer_, dims = NULL,
                         non_negative = FALSE, internal = TRUE,
                         init_expr = ctx$stocks[[nm]]$init_expr)
  }

  unused_init <- setdiff(names(pars$initials), stock_nms)
  if (length(unused_init))
    sd_abort(sprintf("`initial()` given for something that is not a stock: %s.",
                     comma(unused_init)))

  ## ---- stock derivatives ---------------------------------------------------
  deriv <- list()
  for (nm in stock_nms) {
    terms <- list()
    for (fn in flow_nms) {
      f <- vars[[fn]]
      if (!is_boundary(f$to) && identical(f$to, nm)) terms <- c(terms, list(as.symbol(fn)))
      if (!is_boundary(f$from) && identical(f$from, nm))
        terms <- c(terms, list(bquote(-.(as.symbol(fn)))))
    }
    deriv[[nm]] <- if (!length(terms)) 0 else Reduce(function(a, b) bquote(.(a) + .(b)), terms)
  }
  for (nm in names(ctx$derivs)) deriv[[nm]] <- ctx$derivs[[nm]]

  ## ---- validate every symbol -----------------------------------------------
  known_vals <- c(names(stocks), names(node_expr), names(constants), "t", "dt", "pi")
  known_calls <- c(ALLOWED_CALLS, lookup_nms, ".sd_step", ".sd_pulse", ".sd_ramp",
                   ".sd_hist_get", ".sd_prev_get", paste0(".inp_", input_nms))
  check_syms <- function(ex, where) {
    if (is.numeric(ex)) return(invisible())
    v <- setdiff(expr_vars(ex), known_vals)
    v <- setdiff(v, known_calls)
    if (length(v)) {
      sd_abort(sprintf("Unknown variable(s) in %s: %s.", where, comma(v)),
               i = "Declare it in `sd_structure()`, or give it a value in `sd_parameters()`.")
    }
    cl <- setdiff(expr_calls(ex), known_calls)
    if (length(cl))
      sd_abort(sprintf("Unknown function(s) in %s: %s.", where, comma(cl)))
    invisible()
  }
  for (nm in names(node_expr)) check_syms(node_expr[[nm]], sprintf("the equation for '%s'", nm))
  for (nm in names(init_only)) check_syms(init_only[[nm]], sprintf("the initial value of '%s'", nm))
  for (nm in names(stocks)) {
    if (!is.numeric(stocks[[nm]]$init_expr))
      check_syms(stocks[[nm]]$init_expr, sprintf("the initial value of stock '%s'", nm))
  }

  ## ---- dependency graphs ---------------------------------------------------
  stock_set <- names(stocks)
  run_deps <- lapply(node_expr, function(ex) {
    setdiff(intersect(expr_vars(ex), names(node_expr)), character(0))
  })
  names(run_deps) <- names(node_expr)
  eval_order <- topo_sort(run_deps, "equations")

  init_deps <- list()
  for (nm in names(node_expr)) {
    ex <- if (!is.null(init_only[[nm]])) init_only[[nm]] else node_expr[[nm]]
    v <- expr_vars(ex)
    init_deps[[nm]] <- c(intersect(v, names(node_expr)),
                         paste0("init:", intersect(v, stock_set)))
  }
  for (nm in stock_set) {
    ex <- stocks[[nm]]$init_expr
    v <- if (is.numeric(ex)) character(0) else expr_vars(ex)
    init_deps[[paste0("init:", nm)]] <-
      c(intersect(v, names(node_expr)), paste0("init:", intersect(v, stock_set)))
  }
  init_order <- topo_sort(init_deps, "initial values")

  if (isTRUE(spec$check_units)) check_flow_units(struct, spec$time_unit)

  out_vars <- c(stock_nms, flow_nms, aux_nms, input_nms)

  structure(list(
    struct = struct, spec = spec,
    constants = constants,
    lookup_funs = lookup_funs, input_funs = input_funs,
    stocks = stocks, stock_names = names(stocks), explicit_stocks = stock_nms,
    deriv = deriv, node_expr = node_expr, init_only = init_only,
    eval_order = eval_order, init_order = init_order,
    stateful = ctx$stateful, out_vars = out_vars
  ), class = "sd_bound")
}

## Broadcast an `initial()` value over a stock's dimensions.
broadcast <- function(value, len, nm, struct, v) {
  value <- as.numeric(value)
  if (length(value) == len) return(unname(value))
  if (length(value) == 1L) return(rep(unname(value), len))
  sd_abort(sprintf("`initial(%s = )` has length %d but '%s' has %d element(s).",
                   nm, length(value), nm, len),
           i = if (!is.null(v$dims))
             sprintf("It is declared over: %s.", comma(v$dims)) else NULL)
}
