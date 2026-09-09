## ---------------------------------------------------------------------------
## Light-weight unit algebra.
##
## Units are declared in `sd_structure()` only; constants carry none. So the
## only check the grammar can honestly make is the structural one: a flow's
## units must equal the units of the stock it moves, per unit of simulation
## time. Anything left unspecified is simply not checked.
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

unit_walk <- function(e, sign) {
  if (is.numeric(e)) {
    if (isTRUE(e == 1)) return(stats::setNames(integer(0), character(0)))
    stop("numeric literal in units")
  }
  if (is.symbol(e)) {
    nm <- as.character(e)
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
