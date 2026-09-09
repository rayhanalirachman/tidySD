fmt_target <- function(x) if (is_boundary(x)) paste0(".", x$which) else x

#' @export
print.sd_structure <- function(x, ...) {
  nm <- x$meta$name
  cat("<sd_structure>", if (!is.null(nm)) paste0(" ", nm) else "", "\n", sep = "")
  if (length(x$dims)) {
    for (d in names(x$dims)) {
      m <- x$dims[[d]]
      cat(sprintf("  dim   %s [%d]: %s\n", d, length(m), comma(m, 6)))
    }
  }
  for (v in x$vars) {
    u <- if (is.null(v$units)) "" else sprintf("  [%s]", v$units)
    dd <- if (is.null(v$dims)) "" else sprintf("<%s>", paste(v$dims, collapse = ","))
    extra <- switch(v$type,
      flow = sprintf("  %s -> %s", fmt_target(v$from), fmt_target(v$to)),
      lookup = if (!is.null(v$input)) sprintf("  of %s", v$input) else "",
      stock = if (isTRUE(v$non_negative)) "  non-negative" else "",
      "")
    cat(sprintf("  %-6s %s%s%s%s\n", v$type, v$name, dd, extra, u))
  }
  invisible(x)
}

#' @export
print.sd_equations <- function(x, ...) {
  cat("<sd_equations>", length(x$eqns), "equations\n")
  for (e in x$eqns) {
    lhs <- if (e$is_init) sprintf("init(%s)", e$name) else e$name
    cat(sprintf("  %s ~ %s\n", lhs, deparse1_(e$rhs)))
  }
  invisible(x)
}

#' @export
print.sd_parameters <- function(x, ...) {
  cat("<sd_parameters>\n")
  show <- function(v) {
    if (is.matrix(v)) return(sprintf("<%d x %d matrix>", nrow(v), ncol(v)))
    if (length(v) > 4L) return(sprintf("<%d values: %s ...>", length(v),
                                       paste(signif(v[1:3], 4), collapse = ", ")))
    paste(signif(v, 6), collapse = ", ")
  }
  for (nm in names(x$constants)) {
    tag <- if (nm %in% x$references) "reference" else "constant"
    cat(sprintf("  %-9s %-30s %s\n", tag, nm, show(x$constants[[nm]])))
  }
  for (nm in names(x$initials))
    cat(sprintf("  %-9s %-30s %s\n", "initial", nm, show(x$initials[[nm]])))
  for (nm in names(x$lookups))
    cat(sprintf("  %-9s %-30s %d points\n", "lookup", nm, length(x$lookups[[nm]]$x)))
  for (nm in names(x$inputs))
    cat(sprintf("  %-9s %-30s %d rows\n", "series", nm, nrow(x$inputs[[nm]]$data)))
  invisible(x)
}

#' @export
print.sim_spec <- function(x, ...) {
  cat(sprintf("<sim_spec> %s -> %s, dt = %s, %s%s\n",
              format(x$start), format(x$stop), format(x$dt), x$method,
              if (!is.null(x$time_unit)) paste0(" (", x$time_unit, ")") else ""))
  invisible(x)
}

#' @export
print.sd_scenarios <- function(x, ...) {
  cat("<sd_scenarios>", length(x), "runs\n")
  for (nm in names(x)) {
    o <- x[[nm]]
    cat(sprintf("  %-14s %s\n", nm,
                if (!length(o)) "(base)" else
                  paste(sprintf("%s = %s", names(o), vapply(o, function(v)
                    paste(signif(v, 6), collapse = ","), character(1))), collapse = ", ")))
  }
  invisible(x)
}

#' @export
print.sd_bound <- function(x, ...) {
  cat("<sd_bound>", x$struct$meta$name %||% "", "\n")
  cat("  stocks       ", comma(x$explicit_stocks), "\n")
  hidden <- setdiff(x$stock_names, x$explicit_stocks)
  if (length(hidden)) cat("  internal     ", length(hidden), "delay/smooth stage stocks\n")
  cat("  eval order   ", comma(Filter(function(n) !startsWith(n, "."), x$eval_order), 12), "\n")
  invisible(x)
}

#' @export
print.sd_result <- function(x, ...) {
  meta <- attr(x, "sd_meta")
  if (!is.null(meta$name)) cat("# ", meta$name, "\n", sep = "")
  y <- x
  class(y) <- setdiff(class(y), "sd_result")
  print(y, ...)
  invisible(x)
}

#' @export
summary.sd_result <- function(object, ...) {
  d <- as.data.frame(object)
  if ("source" %in% names(d)) d <- d[d$source == "model", , drop = FALSE]
  sp <- split(d$value, d$variable)
  out <- tibble::tibble(
    variable = names(sp),
    min = vapply(sp, function(v) min(v, na.rm = TRUE), numeric(1)),
    max = vapply(sp, function(v) max(v, na.rm = TRUE), numeric(1)),
    final = vapply(split(d, d$variable), function(z)
      mean(z$value[z$time == max(z$time)], na.rm = TRUE), numeric(1))
  )
  out[order(match(out$variable, unique(d$variable))), ]
}
