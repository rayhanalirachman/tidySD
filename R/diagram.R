#' Diagrams as functions of the model
#'
#' `sd_diagram()` reads the wiring out of the bound model rather than asking
#' you to draw it. `type = "sfd"` gives the stock-and-flow diagram (stocks,
#' flows, and the variables that set each rate); `type = "cld"` gives the causal
#' loop diagram (every variable, one edge per dependency, signed where the sign
#' is unambiguous).
#'
#' @param structure An [sd_structure()] object.
#' @param equations An [sd_equations()] object.
#' @param parameters An [sd_parameters()] object; needed only so that lookups
#'   and inputs resolve. Defaults to an empty layer.
#' @param type `"sfd"` or `"cld"`.
#' @return An object of class `sd_diagram`: a list of `nodes` and `edges`
#'   tibbles, with [autoplot()] and `plot()` methods.
#' @export
sd_diagram <- function(structure, equations, parameters = sd_parameters(),
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
#' A deliberately plain layered layout: stocks on the spine, everything else
#' arranged around them. It is meant for reading a model, not for publication.
#'
#' @param object An [sd_diagram()].
#' @param ... Unused.
#' @return A `ggplot` object.
#' @method autoplot sd_diagram
#' @export
autoplot.sd_diagram <- function(object, ...) {
  nd <- object$nodes
  rank <- c(stock = 1, flow = 2, aux = 3, lookup = 4, input = 4, constant = 5)
  nd$layer <- unname(rank[nd$type])
  nd$layer[is.na(nd$layer)] <- 3
  nd <- nd[order(nd$layer, nd$name), ]
  nd$x <- unlist(lapply(split(nd$name, nd$layer), function(z) seq_along(z) - mean(seq_along(z))))
  nd$y <- -nd$layer
  pos <- stats::setNames(seq_len(nrow(nd)), nd$name)

  ed <- object$edges
  if (nrow(ed)) {
    ed$x <- nd$x[pos[ed$from]]; ed$y <- nd$y[pos[ed$from]]
    ed$xend <- nd$x[pos[ed$to]]; ed$yend <- nd$y[pos[ed$to]]
    ed <- ed[stats::complete.cases(ed[c("x", "y", "xend", "yend")]), , drop = FALSE]
  }

  p <- ggplot2::ggplot()
  if (nrow(ed))
    p <- p + ggplot2::geom_segment(
      data = ed,
      ggplot2::aes(x = .data$x, y = .data$y, xend = .data$xend, yend = .data$yend,
                   linetype = .data$kind),
      colour = "grey55",
      arrow = ggplot2::arrow(length = ggplot2::unit(0.12, "cm"), type = "closed"))
  p + ggplot2::geom_label(data = nd,
        ggplot2::aes(x = .data$x, y = .data$y, label = .data$name, fill = .data$type),
        size = 2.6, linewidth = 0.15) +
    ggplot2::labs(title = object$name, x = NULL, y = NULL) +
    ggplot2::theme_void()
}

#' @rdname autoplot.sd_diagram
#' @param x An [sd_diagram()].
#' @export
plot.sd_diagram <- function(x, ...) print(autoplot(x, ...))
