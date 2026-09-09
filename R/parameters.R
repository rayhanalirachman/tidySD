#' The parameter layer: the numbers and the data
#'
#' `sd_parameters()` collects [constant()], [reference()], [initial()],
#' [lookup_data()] and [input_series()] declarations.
#'
#' @param ... Parameter elements.
#' @return An object of class `sd_parameters`.
#' @examples
#' sd_parameters(
#'   constant(contact_rate = 6, infectivity = 0.2),
#'   initial(S = 999, I = 1, R = 0)
#' )
#' @export
sd_parameters <- function(...) {
  els <- list(...)
  els <- unlist(lapply(els, function(e) if (inherits(e, "sd_element")) list(e) else e),
                recursive = FALSE)
  bad <- !vapply(els, inherits, logical(1), "sd_element")
  if (any(bad))
    sd_abort("Every argument to `sd_parameters()` must be a parameter element.",
             x = "constant(), reference(), initial(), lookup_data() or input_series().")

  p <- list(constants = list(), references = character(0), initials = list(),
            lookups = list(), inputs = list())
  for (e in els) p <- merge_parameter(p, e)
  structure(p, class = "sd_parameters")
}

merge_parameter <- function(p, e) {
  switch(e$kind,
    constant = {
      p$constants <- utils::modifyList(p$constants, e$values)
      if (isTRUE(e$reference)) p$references <- union(p$references, names(e$values))
    },
    initial = { p$initials <- utils::modifyList(p$initials, e$values) },
    lookup_data = { p$lookups[[e$name]] <- list(x = e$x, y = e$y) },
    input_series = {
      p$inputs[[e$name]] <- list(data = e$data, interp = e$interp, range = e$range,
                                 value_col = e$value_col)
    },
    sd_abort(sprintf("`%s()` does not belong in `sd_parameters()`.", e$kind))
  )
  p
}

check_values <- function(values, what) {
  if (!length(values)) sd_abort(sprintf("`%s()` needs at least one named value.", what))
  if (!is_named_scalar_list(values))
    sd_abort(sprintf("Every value in `%s()` must be named.", what))
  for (nm in names(values)) {
    v <- values[[nm]]
    if (!is.numeric(v))
      sd_abort(sprintf("`%s` in `%s()` must be numeric.", nm, what))
  }
  values
}

#' Constants
#'
#' Numeric constants available on any equation right-hand side. A value may be
#' a scalar, a (named) vector over a subscript dimension, or a matrix.
#'
#' @param ... Named numeric values.
#' @return An `sd_element` to be passed to [sd_parameters()].
#' @export
constant <- function(...) {
  new_element("constant", values = check_values(list(...), "constant"), reference = FALSE)
}

#' Normalising reference values
#'
#' Identical to [constant()] in behaviour; the separate name records that the
#' value is a normalising reference rather than a policy lever, and it is
#' reported as such by `print()`.
#'
#' @param ... Named numeric values.
#' @return An `sd_element` to be passed to [sd_parameters()].
#' @export
reference <- function(...) {
  new_element("constant", values = check_values(list(...), "reference"), reference = TRUE)
}

#' Stock initial values
#'
#' @param ... Named numeric values, one per stock. A scalar given for a
#'   subscripted stock is broadcast over every member of its dimension.
#' @return An `sd_element` to be passed to [sd_parameters()].
#' @export
initial <- function(...) {
  new_element("initial", values = check_values(list(...), "initial"))
}

#' Points for a graphical (lookup) function
#'
#' @param name Name of the [lookup()] these points belong to.
#' @param x,y Numeric vectors of equal length, `x` strictly increasing.
#' @return An `sd_element` to be passed to [sd_parameters()].
#' @export
lookup_data <- function(name, x, y) {
  if (!is.numeric(x) || !is.numeric(y) || length(x) != length(y) || !length(x))
    sd_abort(sprintf("`lookup_data(\"%s\")` needs numeric `x` and `y` of equal length.", name))
  if (is.unsorted(x, strictly = TRUE))
    sd_abort(sprintf("`x` in `lookup_data(\"%s\")` must be strictly increasing.", name))
  new_element("lookup_data", name = name, x = as.numeric(x), y = as.numeric(y))
}

#' An exogenous data series for an input()
#'
#' @param name Name of the [input()] the series drives.
#' @param data A data frame with a `time` column (numeric, or `Date` -- resolved
#'   against `sim_spec(start = )`) and one value column. If it has more than two
#'   columns, name the value column with `value_col`.
#' @param value_col Name of the value column; defaults to the single non-time
#'   column, or to `name` when present.
#' @param interp `"linear"` or `"constant"` interpolation onto the solver grid.
#' @param range `"hold"` (hold the first/last value outside the data range),
#'   `"extend"` (linear extrapolation) or `"na"`.
#' @return An `sd_element` to be passed to [sd_parameters()].
#' @export
input_series <- function(name, data, value_col = NULL,
                         interp = c("linear", "constant"),
                         range = c("hold", "extend", "na")) {
  interp <- match.arg(interp)
  range <- match.arg(range)
  if (!is.data.frame(data))
    sd_abort(sprintf("`input_series(\"%s\", data = )` must be a data frame.", name))
  new_element("input_series", name = name, data = as.data.frame(data),
              value_col = value_col, interp = interp, range = range)
}

#' Replace or add parameters
#'
#' @param object An `sd_parameters` object.
#' @param ... Parameter elements, or named numeric values (treated as constants).
#' @return A new `sd_parameters` object.
#' @examples
#' p <- sd_parameters(constant(a = 1), initial(S = 10))
#' update(p, constant(a = 2))
#' update(p, a = 3)
#' @export
update.sd_parameters <- function(object, ...) {
  els <- list(...)
  out <- unclass(object)
  for (i in seq_along(els)) {
    e <- els[[i]]
    if (inherits(e, "sd_element")) {
      out <- merge_parameter(out, e)
    } else if (nzchar(names(els)[i] %||% "")) {
      out <- merge_parameter(out, constant2(names(els)[i], e))
    } else {
      sd_abort("`update()` on parameters takes parameter elements or named numeric values.")
    }
  }
  structure(out, class = "sd_parameters")
}

constant2 <- function(nm, value) {
  v <- stats::setNames(list(value), nm)
  new_element("constant", values = check_values(v, "constant"), reference = FALSE)
}
