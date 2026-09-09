`%||%` <- function(x, y) if (is.null(x)) y else x

sd_abort <- function(msg, ...) {
  rlang::abort(c(msg, ...), class = "tidysd_error")
}

sd_warn <- function(msg, ...) {
  rlang::warn(c(msg, ...), class = "tidysd_warning")
}

is_named_scalar_list <- function(x) {
  !is.null(names(x)) && all(nzchar(names(x)))
}

## Collapse a character vector for use in a message.
comma <- function(x, max = 8L) {
  x <- as.character(x)
  if (length(x) > max) x <- c(x[seq_len(max)], "...")
  paste(x, collapse = ", ")
}

## Does `x` look like a syntactically valid, non-reserved variable name?
is_valid_name <- function(x) {
  identical(make.names(x), x)
}

## Drop a one-column matrix (the result of `%*%`) back to a plain vector so
## that downstream element-wise arithmetic stays vector-shaped.
drop_matrix <- function(v) {
  if (is.matrix(v) && ncol(v) == 1L) {
    nm <- rownames(v)
    v <- as.vector(v)
    if (!is.null(nm)) names(v) <- nm
  }
  v
}

## Topological sort of a dependency list: `deps[[node]]` are the nodes that must
## be evaluated *before* `node`.
topo_sort <- function(deps, what = "equations") {
  nodes <- names(deps)
  state <- stats::setNames(rep(0L, length(nodes)), nodes)  # 0 new, 1 open, 2 done
  order <- character(0)
  stack_names <- character(0)

  visit <- function(n, path) {
    st <- state[[n]]
    if (identical(st, 2L)) return(invisible(NULL))
    if (identical(st, 1L)) {
      cyc <- c(path[which(path == n)[1]:length(path)], n)
      sd_abort(
        sprintf("Circular dependency among %s.", what),
        x = paste0("Loop: ", paste(cyc, collapse = " -> ")),
        i = "A simultaneous (algebraic) loop has no evaluation order; break it with a stock or a delay."
      )
    }
    state[[n]] <<- 1L
    for (d in deps[[n]]) {
      if (!is.null(deps[[d]])) visit(d, c(path, n))
    }
    state[[n]] <<- 2L
    order <<- c(order, n)
    invisible(NULL)
  }

  for (n in nodes) visit(n, character(0))
  order
}

## ---- expression walking -----------------------------------------------------

## All symbols used as *values* in an expression (call heads excluded).
expr_vars <- function(e) {
  if (is.symbol(e)) return(as.character(e))
  if (!is.call(e)) return(character(0))
  args <- as.list(e)[-1]
  unique(unlist(lapply(args, expr_vars), use.names = FALSE)) %||% character(0)
}

## All symbols used as call heads.
expr_calls <- function(e) {
  if (!is.call(e)) return(character(0))
  head <- e[[1]]
  out <- if (is.symbol(head)) as.character(head) else character(0)
  args <- as.list(e)[-1]
  unique(c(out, unlist(lapply(args, expr_calls), use.names = FALSE)))
}

## Does the expression contain a call to any of `fns`?
expr_has_call <- function(e, fns) {
  any(expr_calls(e) %in% fns)
}

deparse1_ <- function(e) paste(deparse(e, width.cutoff = 500L), collapse = " ")
