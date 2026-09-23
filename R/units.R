## ---------------------------------------------------------------------------
## Light-weight unit algebra.
##
## Units are declared in `sd_structure()` only; constants carry none. So the
## checks the grammar can honestly make are the structural one -- a flow's
## units must equal the units of the stock it moves, per unit of simulation
## time -- and the arithmetic one: an equation's right-hand side must combine
## its terms consistently. Anything left unspecified is simply not checked.
## ---------------------------------------------------------------------------

## Parse a unit string ("kg*m/second^2", "widget/(person*hour)", "1") into a
## named integer vector of exponents. Returns NULL if `u` is NULL/NA/"".
parse_units <- function(u) {
  if (is.null(u) || length(u) != 1L || is.na(u) || !nzchar(trimws(u))) return(NULL)
  e <- tryCatch(str2lang(u), error = function(e) NULL)
  if (is.null(e)) {
    sd_warn(sprintf("Could not parse the unit string '%s'; it will not be checked.", u))
    return(NULL)
  }
  out <- tryCatch(unit_walk(e, 1L), error = function(err) {
    sd_warn(sprintf("Could not parse the unit string '%s'; it will not be checked.", u))
    NULL
  })
  if (is.null(out)) return(NULL)
  out <- out[out != 0]
  out[order(names(out))]
}

## Names that count as no unit at all: "1" parses as a numeric literal already,
## these are the spellings people write instead (radians are a ratio).
DIMENSIONLESS <- c("radian", "radians", "rad", "dimensionless", "Dimensionless",
                   "dmnl", "Dmnl", "unitless")

unit_walk <- function(e, sign) {
  if (is.numeric(e)) {
    if (isTRUE(e == 1)) return(stats::setNames(integer(0), character(0)))
    stop("numeric literal in units")
  }
  if (is.symbol(e)) {
    nm <- as.character(e)
    if (nm %in% DIMENSIONLESS) return(stats::setNames(integer(0), character(0)))
    return(stats::setNames(sign, nm))
  }
  if (!is.call(e)) stop("bad unit")
  op <- as.character(e[[1]])
  switch(op,
    "(" = unit_walk(e[[2]], sign),
    "*" = unit_merge(unit_walk(e[[2]], sign), unit_walk(e[[3]], sign)),
    "/" = unit_merge(unit_walk(e[[2]], sign), unit_walk(e[[3]], -sign)),
    "^" = {
      p <- e[[3]]
      if (!is.numeric(p)) stop("non-numeric exponent")
      base <- unit_walk(e[[2]], sign)
      stats::setNames(as.integer(base * p), names(base))
    },
    stop("unsupported unit operator")
  )
}

unit_merge <- function(a, b) {
  nms <- union(names(a), names(b))
  va <- ifelse(nms %in% names(a), a[nms], 0L)
  vb <- ifelse(nms %in% names(b), b[nms], 0L)
  v <- as.integer(va) + as.integer(vb)
  stats::setNames(v, nms)
}

unit_divide <- function(a, b) unit_merge(a, stats::setNames(-b, names(b)))

units_equal <- function(a, b) {
  a <- a[a != 0]; b <- b[b != 0]
  a <- a[order(names(a))]; b <- b[order(names(b))]
  identical(as.integer(a), as.integer(b)) && identical(names(a), names(b))
}

format_units <- function(u) {
  if (is.null(u)) return("<unspecified>")
  u <- u[u != 0]
  if (!length(u)) return("1")
  num <- names(u)[u > 0]; den <- names(u)[u < 0]
  fmt <- function(nms, ex) {
    paste(mapply(function(n, e) if (e == 1) n else paste0(n, "^", e), nms, ex),
          collapse = "*")
  }
  n <- if (length(num)) fmt(num, u[num]) else "1"
  if (!length(den)) return(n)
  d <- fmt(den, abs(u[den]))
  if (length(den) > 1L) d <- paste0("(", d, ")")
  paste0(n, "/", d)
}

## ---------------------------------------------------------------------------
## The same exponent vectors, propagated through an equation's right-hand side.
## NULL means "unknown, not checked": it is contagious through `*` and `/`, and
## ignored by the matching operators, so an equation that touches a unit-less
## constant or a numeric literal is simply not checked rather than flagged.
##
## ponytail: left unchecked (all yield "unknown") -- transcendental and
## statistical functions (exp/log/sqrt/trig/sd/var), comparisons and logicals,
## matrix algebra (%*%, outer, crossprod), lookup calls without `out_units`,
## step/pulse/ramp, numeric literals in `+`/`-`, and min/max/pmin/pmax, whose
## clamp idiom (`min(rate, Stock)`) is dimensionally sloppy in published models
## often enough that enforcing it would cry wolf. Extend the two tables below
## if a real model needs one of them.
## ---------------------------------------------------------------------------

## Calls whose arguments must agree; the result carries that same unit.
UNIT_MATCH_FNS <- c("+", "-", "ifelse", "if",
                    "sum", "mean", "c", "cumsum", "abs", "sign", "range", "rev")
## Calls that pass their first argument's units straight through.
UNIT_FIRST_FNS <- c("(", "[", "[[", "as.numeric", "as.vector", "t", "floor",
                    "ceiling", "round", "trunc", "diag", STATEFUL_FNS)

eq_units <- function(e, env, where) {
  if (is.symbol(e)) return(env[[as.character(e)]])
  if (!is.call(e)) return(NULL)
  op <- as.character(e[[1]])
  args <- as.list(e)[-1]
  if (!length(args)) return(NULL)

  if (op %in% c("*", "/") && length(args) == 2L) {
    a <- eq_units(args[[1]], env, where)
    b <- eq_units(args[[2]], env, where)
    if (is.null(a) || is.null(b)) return(NULL)
    return(if (op == "*") unit_merge(a, b) else unit_divide(a, b))
  }
  if (op == "^") {
    a <- eq_units(args[[1]], env, where)
    p <- args[[2]]
    if (is.null(a) || !is.numeric(p) || length(p) != 1L) return(NULL)
    return(stats::setNames(as.integer(a * p), names(a)))
  }
  if (op %in% UNIT_MATCH_FNS) {
    if (op %in% c("ifelse", "if")) args <- args[-1]
    us <- lapply(args, eq_units, env = env, where = where)
    ref <- NULL; ref_arg <- NULL
    for (i in seq_along(us)) {
      if (is.null(us[[i]])) next
      if (is.null(ref)) { ref <- us[[i]]; ref_arg <- args[[i]]; next }
      if (!units_equal(ref, us[[i]]))
        sd_abort(
          sprintf("Unit mismatch in %s: `%s` is '%s' but `%s` is '%s'.",
                  where, deparse1_(ref_arg), format_units(ref),
                  deparse1_(args[[i]]), format_units(us[[i]])),
          i = sprintf("Terms combined with `%s` must share units.", op))
    }
    return(ref)
  }
  if (op %in% UNIT_FIRST_FNS) return(eq_units(args[[1]], env, where))
  env[[op]]  # a lookup called by name, if it declared `out_units`
}

## Check every equation right-hand side for internal consistency, and against
## the units declared for the variable it defines.
check_equation_units <- function(struct, eqns, time_unit) {
  env <- list()
  for (v in struct$vars) {
    u <- parse_units(if (identical(v$type, "lookup")) v$out_units else v$units)
    if (!is.null(u)) env[[v$name]] <- u
  }
  if (!is.null(time_unit) && nzchar(time_unit)) {
    env$t <- env$dt <- stats::setNames(1L, time_unit)
  }
  for (e in eqns$eqns) {
    where <- if (e$is_init) sprintf("the initial value of '%s'", e$name)
             else sprintf("the equation for '%s'", e$name)
    u <- eq_units(e$rhs, env, where)
    decl <- env[[e$name]]
    if (!is.null(u) && !is.null(decl) && !units_equal(u, decl))
      sd_abort(sprintf("Unit mismatch in %s: the right-hand side works out to '%s'.",
                       where, format_units(u)),
               x = sprintf("'%s' is declared '%s'.", e$name, format_units(decl)))
  }
  invisible(NULL)
}

## Check every flow against the stock(s) it is wired to.
check_flow_units <- function(struct, time_unit) {
  if (is.null(time_unit) || !nzchar(time_unit)) return(invisible(NULL))
  tu <- stats::setNames(1L, time_unit)
  flows <- Filter(function(v) v$type == "flow", struct$vars)
  for (f in flows) {
    fu <- parse_units(f$units)
    if (is.null(fu)) next
    for (side in c("from", "to")) {
      target <- f[[side]]
      if (is.null(target) || is_boundary(target)) next
      s <- struct$vars[[target]]
      if (is.null(s)) next
      su <- parse_units(s$units)
      if (is.null(su)) next
      expected <- unit_divide(su, tu)
      if (!units_equal(fu, expected)) {
        sd_warn(
          sprintf("Unit mismatch: flow '%s' is declared '%s'.", f$name, f$units),
          x = sprintf("Stock '%s' is '%s', so the flow should be '%s' (per %s).",
                      s$name, s$units, format_units(expected), time_unit)
        )
      }
    }
  }
  invisible(NULL)
}
