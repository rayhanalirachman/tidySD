#' Diagrams as functions of the model
#'
#' `sd_diagram()` reads the wiring out of the bound model rather than asking
#' you to draw it. `type = "sfd"` gives the stock-and-flow diagram (stocks,
#' flows, and the variables that set each rate); `type = "cld"` gives the causal
#' loop diagram (every variable, one edge per dependency, signed where the sign
#' is unambiguous). In a CLD each flow also links to the stocks it moves:
#' `+` into the stock it fills, `-` into the stock it drains, so loops through
#' stocks close.
#'
#' @param structure An [sd_structure()] object.
#' @param equations An [sd_equations()] object. Defaults to an empty layer,
#'   which gives the stock-and-flow wiring alone.
#' @param parameters An [sd_parameters()] object; needed only so that lookups
#'   and inputs resolve. Defaults to an empty layer.
#' @param type `"sfd"` or `"cld"`.
#' @return An object of class `sd_diagram`: a list of `nodes` and `edges`
#'   tibbles, with [autoplot()] and `plot()` methods.
#' @export
sd_diagram <- function(structure, equations = sd_equations(),
                       parameters = sd_parameters(),
                       type = c("sfd", "cld")) {
  type <- match.arg(type)
  struct <- structure
  vars <- struct$vars
  eq <- equations$eqns

  nodes <- tibble::tibble(
    name = names(vars),
    type = vapply(vars, function(v) v$type, character(1)),
    units = vapply(vars, function(v) v$units %||% NA_character_, character(1))
  )
  consts <- setdiff(names(parameters$constants), nodes$name)
  if (length(consts))
    nodes <- rbind(nodes, tibble::tibble(name = consts, type = "constant",
                                         units = NA_character_))

  edges <- list()
  add <- function(from, to, kind, sign = NA_character_) {
    edges[[length(edges) + 1L]] <<- tibble::tibble(from = from, to = to,
                                                   kind = kind, sign = sign)
  }

  if (type == "sfd") {
    for (v in vars) {
      if (v$type != "flow") next
      if (!is_boundary(v$from)) add(v$from, v$name, "outflow")
      if (!is_boundary(v$to)) add(v$name, v$to, "inflow")
    }
  }
  for (e in eq) {
    if (e$is_init) next
    deps <- intersect(expr_vars(e$rhs), nodes$name)
    heads <- intersect(expr_calls(e$rhs), nodes$name[nodes$type == "lookup"])
    for (d in unique(c(deps, heads))) {
      if (identical(d, e$name)) next
      if (type == "sfd" && !d %in% nodes$name[nodes$type %in%
            c("stock", "aux", "lookup", "input", "constant")]) next
      add(d, e$name, "information", edge_sign(e$rhs, d))
    }
  }
  if (type == "cld") {
    for (v in vars) {
      if (v$type != "flow") next
      if (!is_boundary(v$from)) add(v$name, v$from, "information", "-")
      if (!is_boundary(v$to)) add(v$name, v$to, "information", "+")
    }
  }
  out <- list(nodes = nodes,
              edges = if (length(edges)) tibble::as_tibble(do.call(rbind, edges)) else
                tibble::tibble(from = character(), to = character(),
                               kind = character(), sign = character()),
              type = type, name = struct$meta$name %||% NULL)
  class(out) <- "sd_diagram"
  out
}

## A crude but honest polarity read: "+" when the variable appears only in
## positive positions, "-" when only in a denominator or behind a unary minus,
## NA when it is genuinely ambiguous.
edge_sign <- function(expr, var) {
  s <- sign_walk(expr, var, 1L)
  if (length(s) != 1L || is.na(s)) NA_character_ else if (s > 0) "+" else "-"
}

sign_walk <- function(e, var, pol) {
  if (is.symbol(e)) return(if (identical(as.character(e), var)) pol else NA_integer_)
  if (!is.call(e)) return(NA_integer_)
  op <- if (is.symbol(e[[1]])) as.character(e[[1]]) else ""
  args <- as.list(e)[-1]
  res <- switch(op,
    "(" = sign_walk(args[[1]], var, pol),
    "+" = if (length(args) == 1L) sign_walk(args[[1]], var, pol) else
      merge_sign(sign_walk(args[[1]], var, pol), sign_walk(args[[2]], var, pol)),
    "-" = if (length(args) == 1L) sign_walk(args[[1]], var, -pol) else
      merge_sign(sign_walk(args[[1]], var, pol), sign_walk(args[[2]], var, -pol)),
    "*" = merge_sign(sign_walk(args[[1]], var, pol), sign_walk(args[[2]], var, pol)),
    "/" = merge_sign(sign_walk(args[[1]], var, pol), sign_walk(args[[2]], var, -pol)),
    {
      hits <- lapply(args, sign_walk, var = var, pol = pol)
      hits <- Filter(function(h) !is.na(h), hits)
      if (!length(hits)) NA_integer_ else NA_integer_
    }
  )
  res
}

merge_sign <- function(a, b) {
  if (is.na(a)) return(b)
  if (is.na(b)) return(a)
  if (identical(a, b)) a else NA_integer_
}

#' @export
print.sd_diagram <- function(x, ...) {
  cat(sprintf("<sd_diagram: %s>%s\n", x$type,
              if (!is.null(x$name)) paste0(" ", x$name) else ""))
  cat(sprintf("  %d nodes, %d edges\n", nrow(x$nodes), nrow(x$edges)))
  invisible(x)
}

#' Plot a model diagram
#'
#' Stocks and flows run left to right in material chains, with the variables
#' that set each rate above and constants below. A causal loop diagram is laid
#' out on a circle ordered to keep each feedback loop on consecutive positions,
#' with loops shaded and badged `R` (reinforcing), `B` (balancing) or `?`
#' (polarity unknown).
#'
#' Text uses the first installed of Inter, Avenir Next, Helvetica Neue,
#' Helvetica, Arial and DejaVu Sans when 'systemfonts' is installed, and
#' `"sans"` otherwise, or when the open device is `pdf()` or `postscript()`.
#'
#' @param object An [sd_diagram()].
#' @param theme `"soft"` (a restrained slate palette with one blue accent),
#'   `"oi"` (Okabe-Ito, colour-blind safe) or `"plain"` (a bare layered
#'   layout for quick reading).
#' @param initials Optional named numeric (or list) of stock start values,
#'   shown as a chip on each stock of a stock-and-flow diagram, e.g.
#'   `parameters$initials`.
#' @param ... Unused.
#' @return A `ggplot` object; see [save_diagram()] to write it at its natural
#'   size.
#' @examples
#' ex <- sd_example("sir")
#' d <- sd_diagram(ex$structure, ex$equations, ex$parameters, type = "cld")
#' p <- autoplot(d)
#' @method autoplot sd_diagram
#' @export
autoplot.sd_diagram <- function(object, theme = c("soft", "oi", "plain"),
                                initials = NULL, ...) {
  theme <- match.arg(theme)
  if (theme == "plain") return(plot_plain(object))
  k <- c(PALETTES[[c(soft = "mono", oi = "oi")[[theme]]]], diagram_fonts())
  if (identical(object$type, "cld")) render_cld(object, k) else
    render_sfd(object, k, initials)
}

#' @rdname autoplot.sd_diagram
#' @param x An [sd_diagram()].
#' @export
plot.sd_diagram <- function(x, ...) {
  if (grDevices::dev.cur() == 1L) grDevices::dev.new()
  print(autoplot(x, ...))
}

#' Save a diagram at its natural size
#'
#' Writes a PNG sized from the diagram's own layout, so that text keeps the
#' same size whatever the model. Uses 'ragg' when installed.
#'
#' @param p A plot from [autoplot()] on an [sd_diagram()].
#' @param file Path of the PNG to write.
#' @param dpi Resolution.
#' @return `file`, invisibly.
#' @examples
#' ex <- sd_example("sir")
#' p <- autoplot(sd_diagram(ex$structure, ex$equations, ex$parameters))
#' save_diagram(p, tempfile(fileext = ".png"))
#' @export
save_diagram <- function(p, file, dpi = 200) {
  s <- attr(p, "size_in") %||% c(7, 5)
  dev <- if (requireNamespace("ragg", quietly = TRUE)) ragg::agg_png else grDevices::png
  ggplot2::ggsave(file, p, width = max(s[1], 5), height = max(s[2], 3), dpi = dpi,
                  bg = attr(p, "bg") %||% "white", device = dev)
  invisible(file)
}
