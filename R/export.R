## ---------------------------------------------------------------------------
## Export a bound model to XMILE, the interchange format Stella / iThink and
## most other SD tools read. Only what the simulation needs is written:
## variables, equations, initial values and sim specs. No diagram layout --
## XMILE's `<views>` block is optional, and every reader auto-lays-out without
## it.
## ---------------------------------------------------------------------------

XMILE_NS <- "http://docs.oasis-open.org/xmile/ns/XMILE/v1.0"

## R call head -> XMILE function name. Anything absent is an error rather than
## a silent mistranslation.
## ponytail: no ceiling()/%/%/trunc()/matrix maths -- XMILE has no clean
## equivalent. Revisit if a reference model in MODELS.md needs one.
XMILE_FNS <- c(abs = "ABS", sqrt = "SQRT", exp = "EXP", log = "LN",
               log10 = "LOG10", sin = "SIN", cos = "COS", tan = "TAN",
               asin = "ARCSIN", acos = "ARCCOS", atan = "ARCTAN",
               sinh = "SINH", cosh = "COSH", tanh = "TANH",
               min = "MIN", max = "MAX", pmin = "MIN", pmax = "MAX",
               round = "ROUND", floor = "INT")

XMILE_OPS <- c("+" = "+", "-" = "-", "*" = "*", "/" = "/", "^" = "^",
               ">" = ">", "<" = "<", ">=" = ">=", "<=" = "<=",
               "==" = "=", "!=" = "<>",
               "&" = "AND", "&&" = "AND", "|" = "OR", "||" = "OR")

## XMILE identifiers take letters, digits and underscores; R names may hold
## dots, and the internal delay/smooth stocks start with one.
## ponytail: no collision check, so `a.b` and `a_b` in one model would clash.
## Revisit if anyone hits it.
xmile_name <- function(x) gsub("[^A-Za-z0-9_]", "_", sub("^\\.", "", x))

xmile_num <- function(x) {
  if (length(x) != 1L)
    sd_abort("`sd_export()` cannot write a non-scalar value to XMILE.")
  format(x, digits = 15L, scientific = FALSE, trim = TRUE)
}

## Translate one (already expanded) equation into XMILE's equation syntax.
xmile_expr <- function(e, lookups = character(0)) {
  rec <- function(x) xmile_expr(x, lookups)
  if (is.numeric(e)) return(xmile_num(e))
  if (is.logical(e)) return(if (isTRUE(e)) "1" else "0")
  if (is.symbol(e)) {
    nm <- as.character(e)
    return(switch(nm, t = "TIME", dt = "DT", pi = xmile_num(pi), xmile_name(nm)))
  }
  if (!is.call(e)) sd_abort(sprintf("`sd_export()` cannot write: %s", deparse1_(e)))

  fn <- if (is.symbol(e[[1]])) as.character(e[[1]]) else ""
  args <- as.list(e)[-1]

  if (fn == "(") return(sprintf("(%s)", rec(args[[1]])))
  if (fn == "!") return(sprintf("NOT (%s)", rec(args[[1]])))
  if (fn %in% c("+", "-") && length(args) == 1L)
    return(sprintf("%s(%s)", fn, rec(args[[1]])))
  if (fn %in% names(XMILE_OPS) && length(args) == 2L)
    return(sprintf("(%s) %s (%s)", rec(args[[1]]), XMILE_OPS[[fn]], rec(args[[2]])))
  if (fn %in% c("ifelse", "if") && length(args) == 3L)
    return(sprintf("(IF (%s) THEN (%s) ELSE (%s))",
                   rec(args[[1]]), rec(args[[2]]), rec(args[[3]])))
  if (fn == "%%" && length(args) == 2L)
    return(sprintf("MOD(%s, %s)", rec(args[[1]]), rec(args[[2]])))

  ## built-ins, after `expand_expr()` has threaded time in
  if (fn == ".sd_step")
    return(sprintf("STEP(%s, %s)", rec(args[[1]]), rec(args[[2]])))
  if (fn == ".sd_ramp")
    return(sprintf("RAMP(%s, %s, %s)", rec(args[[1]]), rec(args[[2]]), rec(args[[3]])))
  if (fn == ".sd_pulse")  # width-based square wave; XMILE's PULSE is volume-based
    return(sprintf("(IF (TIME >= (%s)) AND (TIME < (%s) + (%s)) THEN 1 ELSE 0)",
                   rec(args[[1]]), rec(args[[1]]), rec(args[[2]])))

  if (fn %in% lookups || fn %in% names(XMILE_FNS)) {
    out <- if (fn %in% lookups) xmile_name(fn) else XMILE_FNS[[fn]]
    return(sprintf("%s(%s)", out, paste(vapply(args, rec, character(1)), collapse = ", ")))
  }
  sd_abort(sprintf("`sd_export()` has no XMILE equivalent for `%s()`.", fn),
           i = "Rewrite the equation with arithmetic, `ifelse()` or a lookup.")
}

## The (x, y) points behind a lookup or input closure, as built in `sd_bind()`.
gf_points <- function(f) {
  e <- environment(f)
  if (is.null(e$x) || is.null(e$y)) return(NULL)
  list(x = e$x, y = e$y, interp = e$interp, range = e$range)
}

add_node <- function(parent, name, text = NULL, ...) {
  n <- xml2::xml_add_child(parent, name, ...)
  if (!is.null(text)) xml2::xml_text(n) <- text
  n
}

add_gf <- function(parent, pts, name = NULL) {
  type <- if (identical(pts$interp, "constant")) "discrete"
          else if (identical(pts$range, "extend")) "extrapolate" else "continuous"
  g <- if (is.null(name)) xml2::xml_add_child(parent, "gf", type = type) else
    xml2::xml_add_child(parent, "gf", name = name, type = type)
  add_node(g, "xpts", paste(vapply(pts$x, xmile_num, character(1)), collapse = ","))
  add_node(g, "ypts", paste(vapply(pts$y, xmile_num, character(1)), collapse = ","))
  g
}

#' Write a bound model out as XMILE
#'
#' Writes the model to an `.xmile` file that Stella, iThink and other
#' XMILE-compatible tools can open. Only the simulation content is written --
#' variables, equations, initial values, units, graphical functions and the
#' simulation settings. No diagram layout is emitted; XMILE's `<views>` block
#' is optional and readers lay the model out themselves.
#'
#' @param model A bound model, from [sd_validate()].
#' @param path Path of the `.xmile` file to write.
#' @return `path`, invisibly.
#' @examples
#' ex <- sd_example("sir")
#' bm <- sd_validate(ex$structure, ex$equations, ex$parameters, ex$spec)
#' file <- tempfile(fileext = ".xmile")
#' sd_export(bm, file)
#' @export
sd_export <- function(model, path) {
  if (!inherits(model, "sd_bound"))
    sd_abort("`model` must come from `sd_validate()`.")
  if (!is.character(path) || length(path) != 1L || !nzchar(path))
    sd_abort("`path` must be a single file path.")

  struct <- model$struct
  vars <- struct$vars
  spec <- model$spec
  lookup_nms <- struct_names(struct, "lookup")
  input_nms <- struct_names(struct, "input")

  ## ponytail: subscripted (arrayed) models are cut -- XMILE dimensions would
  ## mean writing every element's equation out. Revisit when someone asks.
  dimmed <- names(vars)[vapply(vars, function(v) !is.null(v$dims), logical(1))]
  if (length(dimmed))
    sd_abort(sprintf("`sd_export()` does not write subscripted variable(s): %s.",
                     comma(dimmed)),
             i = "XMILE export handles scalar models only.")
  ## ponytail: `delay_fixed()` and `previous()` are cut -- they are queues over
  ## the saved grid, not stocks, so there is no faithful XMILE form. Revisit
  ## with XMILE's DELAY()/PREVIOUS() if a model needs them.
  if (length(model$stateful))
    sd_abort("`sd_export()` does not write `delay_fixed()` or `previous()`.")

  root <- xml2::xml_new_root("xmile", version = "1.0", xmlns = XMILE_NS)
  hdr <- xml2::xml_add_child(root, "header")
  add_node(hdr, "vendor", "tidysd")
  add_node(hdr, "product", "tidysd", version = as.character(utils::packageVersion("tidysd")))
  add_node(hdr, "name", struct$meta$name %||% "tidysd model")

  ss <- xml2::xml_add_child(root, "sim_specs",
                            method = if (spec$method == "rk4") "RK4" else "Euler")
  if (!is.null(spec$time_unit)) xml2::xml_set_attr(ss, "time_units", spec$time_unit)
  add_node(ss, "start", xmile_num(spec$start))
  add_node(ss, "stop", xmile_num(spec$stop))
  add_node(ss, "dt", xmile_num(spec$dt))

  v <- xml2::xml_add_child(xml2::xml_add_child(root, "model"), "variables")

  ## ---- stocks --------------------------------------------------------------
  synth <- list()   # internal (delay/smooth) stocks need a flow to carry their rate
  for (nm in model$stock_names) {
    s <- model$stocks[[nm]]
    n <- xml2::xml_add_child(v, "stock", name = xmile_name(nm))
    add_node(n, "eqn", xmile_expr(s$init_expr, lookup_nms))
    if (s$internal) {
      fnm <- paste0(xmile_name(nm), "_net")
      synth[[fnm]] <- model$deriv[[nm]]
      add_node(n, "inflow", fnm)
    } else {
      for (fn in struct_names(struct, "flow")) {
        f <- vars[[fn]]
        if (!is_boundary(f$to) && identical(f$to, nm)) add_node(n, "inflow", xmile_name(fn))
        if (!is_boundary(f$from) && identical(f$from, nm)) add_node(n, "outflow", xmile_name(fn))
      }
      if (!is.null(vars[[nm]]$units)) add_node(n, "units", vars[[nm]]$units)
      if (isTRUE(s$non_negative)) xml2::xml_add_child(n, "non_negative")
    }
  }

  ## ---- flows ---------------------------------------------------------------
  for (nm in struct_names(struct, "flow")) {
    n <- xml2::xml_add_child(v, "flow", name = xmile_name(nm))
    add_node(n, "eqn", xmile_expr(model$node_expr[[nm]], lookup_nms))
    if (!is.null(vars[[nm]]$units)) add_node(n, "units", vars[[nm]]$units)
  }
  for (nm in names(synth)) {
    n <- xml2::xml_add_child(v, "flow", name = nm)
    add_node(n, "eqn", xmile_expr(synth[[nm]], lookup_nms))
  }

  ## ---- auxiliaries: declared auxes, internal nodes, constants, inputs ------
  aux_nms <- c(struct_names(struct, "aux"),
               setdiff(names(model$node_expr),
                       c(struct_names(struct, "flow"), struct_names(struct, "aux"), input_nms)))
  for (nm in aux_nms) {
    n <- xml2::xml_add_child(v, "aux", name = xmile_name(nm))
    add_node(n, "eqn", xmile_expr(model$node_expr[[nm]], lookup_nms))
    if (!is.null(vars[[nm]]$units)) add_node(n, "units", vars[[nm]]$units)
  }
  for (nm in names(model$constants)) {
    n <- xml2::xml_add_child(v, "aux", name = xmile_name(nm))
    add_node(n, "eqn", xmile_num(model$constants[[nm]]))
  }
  for (nm in input_nms) {
    pts <- gf_points(model$input_funs[[nm]])
    n <- xml2::xml_add_child(v, "aux", name = xmile_name(nm))
    if (is.null(pts)) {
      add_node(n, "eqn", xmile_num(environment(model$input_funs[[nm]])$v0))
    } else {
      add_node(n, "eqn", "TIME")
      add_gf(n, pts)
    }
    if (!is.null(vars[[nm]]$units)) add_node(n, "units", vars[[nm]]$units)
  }

  ## ---- graphical functions --------------------------------------------------
  for (nm in lookup_nms) add_gf(v, gf_points(model$lookup_funs[[nm]]), name = xmile_name(nm))

  xml2::write_xml(root, path)
  invisible(path)
}
