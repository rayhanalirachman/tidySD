#' Boundary of the model
#'
#' Sentinels for a flow that comes from outside the model boundary
#' (`.source`) or leaves it (`.sink`).
#'
#' @format Objects of class `sd_boundary`.
#' @examples
#' flow("births", from = .source, to = "Population")
#' @export
.source <- structure(list(which = "source"), class = "sd_boundary")

#' @rdname dot-source
#' @export
.sink <- structure(list(which = "sink"), class = "sd_boundary")

is_boundary <- function(x) inherits(x, "sd_boundary")

new_element <- function(kind, ...) {
  structure(list(kind = kind, ...), class = c(paste0("sd_", kind), "sd_element"))
}

#' Model metadata
#'
#' @param name Model name, used in printing and as the default plot title.
#' @param ... Further free-form metadata (author, notes, source, ...).
#' @return An `sd_element` to be passed to [sd_structure()].
#' @export
meta <- function(name = NULL, ...) {
  new_element("meta", name = name, extra = list(...))
}

#' Declare a subscript (array) dimension
#'
#' @param ... Named character vectors: `cohort = c("young", "adult")`.
#'   Each becomes a dimension whose members label the array positions and
#'   which appears as a column in the simulation output.
#' @return An `sd_element` to be passed to [sd_structure()].
#' @examples
#' subscripts(cohort = c("young", "adult", "elderly"))
#' @export
subscripts <- function(...) {
  dims <- list(...)
  if (!length(dims)) sd_abort("`subscripts()` needs at least one named dimension.")
  if (!is_named_scalar_list(dims)) sd_abort("Every dimension in `subscripts()` must be named.")
  dims <- lapply(dims, as.character)
  new_element("subscripts", dims = dims)
}

#' Declare a stock (level)
#'
#' A stock accumulates: its value changes only through the flows wired to it.
#'
#' @param name Name of the stock.
#' @param units Unit string, e.g. `"people"`. Unspecified units are not checked.
#' @param dims Character vector of subscript dimensions the stock is arrayed over.
#' @param non_negative If `TRUE`, the stock is clamped at zero after each step.
#' @param label Optional human-readable label.
#' @param doc Optional one-line description, surfaced by [sd_equation_table()].
#' @return An `sd_element` to be passed to [sd_structure()].
#' @export
stock <- function(name, units = NULL, dims = NULL, non_negative = FALSE, label = NULL,
                  doc = NULL) {
  new_element("stock", name = name, units = units, dims = dims,
              non_negative = isTRUE(non_negative), label = label, doc = doc)
}

#' Declare a flow (rate)
#'
#' A flow moves material between stocks, or across the model boundary
#' ([.source] / [.sink]). A flow whose value goes negative simply runs
#' backwards -- a biflow.
#'
#' @param name Name of the flow.
#' @param from,to Either a stock name or [.source] / [.sink].
#' @param units Unit string, e.g. `"people/day"`.
#' @param dims Character vector of subscript dimensions.
#' @param label Optional human-readable label.
#' @param doc Optional one-line description, surfaced by [sd_equation_table()].
#' @return An `sd_element` to be passed to [sd_structure()].
#' @export
flow <- function(name, from = .source, to = .sink, units = NULL, dims = NULL,
                 label = NULL, doc = NULL) {
  chk <- function(x, what) {
    if (is_boundary(x)) return(x)
    if (!is.character(x) || length(x) != 1L)
      sd_abort(sprintf("`%s` of flow '%s' must be a stock name or .source / .sink.", what, name))
    x
  }
  new_element("flow", name = name, from = chk(from, "from"), to = chk(to, "to"),
              units = units, dims = dims, label = label, doc = doc)
}

#' Declare an auxiliary variable
#'
#' An auxiliary is computed from other variables at every step; it holds no
#' state of its own.
#'
#' @param name Name of the auxiliary.
#' @param units Unit string.
#' @param dims Character vector of subscript dimensions.
#' @param label Optional human-readable label.
#' @param doc Optional one-line description, surfaced by [sd_equation_table()].
#' @return An `sd_element` to be passed to [sd_structure()].
#' @rdname aux-variable
#' @export
aux <- function(name, units = NULL, dims = NULL, label = NULL, doc = NULL) {
  new_element("aux", name = name, units = units, dims = dims, label = label, doc = doc)
}

#' Declare a graphical (lookup) function
#'
#' The points come from [lookup_data()] in the parameter layer; the structure
#' layer only says that the function exists, what it reads, and how it behaves
#' outside the tabulated range.
#'
#' @param name Name of the lookup; it is callable on an equation right-hand
#'   side, e.g. `extr_efficiency(Resource)`.
#' @param input Name of the variable it is normally read with (documentation
#'   and diagramming only).
#' @param in_units,out_units Unit strings for the horizontal and vertical axes.
#' @param interp `"linear"` or `"constant"` (step) interpolation.
#' @param range `"clamp"` (hold the end values, the Vensim default) or
#'   `"extend"` (linear extrapolation) or `"na"`.
#' @param label Optional human-readable label.
#' @param doc Optional one-line description, surfaced by [sd_equation_table()].
#' @return An `sd_element` to be passed to [sd_structure()].
#' @export
lookup <- function(name, input = NULL, in_units = NULL, out_units = NULL,
                   interp = c("linear", "constant"),
                   range = c("clamp", "extend", "na"), label = NULL, doc = NULL) {
  interp <- match.arg(interp)
  range <- match.arg(range)
  new_element("lookup", name = name, input = input, in_units = in_units,
              out_units = out_units, interp = interp, range = range, label = label,
              doc = doc)
}

#' Declare an exogenous data driver
#'
#' An `input()` is an auxiliary whose values come from data rather than from a
#' formula. The series itself is supplied by [input_series()] in the parameter
#' layer.
#'
#' @param name Name of the driver.
#' @param units Unit string.
#' @param dims Character vector of subscript dimensions.
#' @param label Optional human-readable label.
#' @param doc Optional one-line description, surfaced by [sd_equation_table()].
#' @return An `sd_element` to be passed to [sd_structure()].
#' @export
input <- function(name, units = NULL, dims = NULL, label = NULL, doc = NULL) {
  new_element("input", name = name, units = units, dims = dims, label = label, doc = doc)
}

#' The structure layer: what exists and how it is wired
#'
#' `sd_structure()` collects [stock()], [flow()], [aux()], [lookup()],
#' [input()], [subscripts()] and [meta()] declarations. It carries no
#' mathematics -- only names, wiring, dimensions and units.
#'
#' @param ... Structure elements.
#' @return An object of class `sd_structure`.
#' @examples
#' sd_structure(
#'   meta(name = "Customer growth"),
#'   stock("Customers", units = "customers", non_negative = TRUE),
#'   flow("recruits", from = .source, to = "Customers", units = "customers/year"),
#'   flow("losses", from = "Customers", to = .sink, units = "customers/year")
#' )
#' @export
sd_structure <- function(...) {
  els <- list(...)
  els <- unlist(lapply(els, function(e) if (inherits(e, "sd_element")) list(e) else e),
                recursive = FALSE)
  bad <- !vapply(els, inherits, logical(1), "sd_element")
  if (any(bad)) {
    sd_abort("Every argument to `sd_structure()` must be a structure element.",
             x = "stock(), flow(), aux(), lookup(), input(), subscripts() or meta().")
  }

  meta_el <- NULL
  dims <- list()
  vars <- list()

  for (e in els) {
    switch(e$kind,
      meta = { meta_el <- e },
      subscripts = { dims <- utils::modifyList(dims, e$dims) },
      {
        nm <- e$name
        if (!is.character(nm) || length(nm) != 1L || !nzchar(nm))
          sd_abort("Every structure element needs a single, non-empty name.")
        if (!is_valid_name(nm))
          sd_abort(sprintf("'%s' is not a valid R name; rename it.", nm))
        if (!is.null(vars[[nm]]))
          sd_abort(sprintf("'%s' is declared twice in `sd_structure()`.", nm))
        vars[[nm]] <- e
      }
    )
  }

  ## dimensions referenced must exist
  for (v in vars) {
    if (!is.null(v$dims)) {
      miss <- setdiff(v$dims, names(dims))
      if (length(miss))
        sd_abort(sprintf("'%s' is declared over unknown dimension(s): %s.",
                         v$name, comma(miss)),
                 i = "Declare them with `subscripts()`.")
    }
  }

  ## flow wiring must point at declared stocks
  for (v in vars) {
    if (v$kind != "flow") next
    for (side in c("from", "to")) {
      tgt <- v[[side]]
      if (is_boundary(tgt)) next
      if (is.null(vars[[tgt]]) || vars[[tgt]]$kind != "stock")
        sd_abort(sprintf("Flow '%s' has %s = \"%s\", which is not a declared stock.",
                         v$name, side, tgt))
    }
  }

  structure(
    list(meta = meta_el, dims = dims,
         vars = lapply(vars, function(v) { v$type <- v$kind; v })),
    class = "sd_structure"
  )
}

struct_names <- function(struct, type) {
  nms <- vapply(struct$vars, function(v) v$type, character(1))
  names(struct$vars)[nms %in% type]
}

var_length <- function(struct, v) {
  if (is.null(v$dims)) return(1L)
  prod(vapply(v$dims, function(d) length(struct$dims[[d]]), integer(1)))
}

#' The variables a structure declares
#'
#' A tidy view of the structure layer: one row per declared stock, flow,
#' auxiliary, lookup or input.
#'
#' @param structure An [sd_structure()] object.
#' @param type Optional character vector to filter by
#'   (`"stock"`, `"flow"`, `"aux"`, `"lookup"`, `"input"`).
#' @return A tibble with columns `name`, `type`, `units`, `dims`, `from`, `to`,
#'   `doc`.
#' @examples
#' sd_variables(sd_example("sir")$structure)
#' sd_variables(sd_example("sir")$structure, "stock")
#' @export
sd_variables <- function(structure, type = NULL) {
  struct <- structure
  if (!inherits(struct, "sd_structure")) sd_abort("`structure` must come from `sd_structure()`.")
  v <- struct$vars
  if (!is.null(type)) v <- v[vapply(v, function(z) z$type %in% type, logical(1))]
  tibble::tibble(
    name = vapply(v, function(z) z$name, character(1)),
    type = vapply(v, function(z) z$type, character(1)),
    units = vapply(v, function(z) z$units %||% NA_character_, character(1)),
    dims = vapply(v, function(z) if (is.null(z$dims)) NA_character_ else
      paste(z$dims, collapse = ","), character(1)),
    from = vapply(v, function(z) if (is.null(z$from)) NA_character_ else
      fmt_target(z$from), character(1)),
    to = vapply(v, function(z) if (is.null(z$to)) NA_character_ else
      fmt_target(z$to), character(1)),
    doc = vapply(v, function(z) z$doc %||% NA_character_, character(1))
  )
}

#' The equation table: every variable with its formula
#'
#' One row per declared variable (plus any constant the parameter layer adds),
#' with the equation deparsed back to text, its units and its `doc =` string.
#' It is [sd_variables()] with the equation layer joined on.
#'
#' @param structure An [sd_structure()] object.
#' @param equations An [sd_equations()] object.
#' @param parameters An [sd_parameters()] object; supplies stock initial values
#'   and constants. Defaults to an empty layer.
#' @return A tibble: the [sd_variables()] columns plus `equation`.
#' @examples
#' ex <- sd_example("sir")
#' sd_equation_table(ex$structure, ex$equations, ex$parameters)
#' @export
sd_equation_table <- function(structure, equations, parameters = sd_parameters()) {
  if (!inherits(equations, "sd_equations"))
    sd_abort("`equations` must come from `sd_equations()`.")
  out <- sd_variables(structure)
  eq <- equations$eqns
  ## ponytail: doc strings are plain text only -- no markdown rendering, no
  ## i18n. Richer docs would go in the element itself (`doc = ` in stock() etc.)
  ## as a list, and be formatted here.
  out$equation <- vapply(out$name, function(n) {
    e <- eq[[n]] %||% eq[[paste0("init:", n)]]
    if (!is.null(e)) return(deparse1_(e$rhs))
    v <- parameters$initials[[n]]
    if (!is.null(v)) return(deparse1_(v))
    NA_character_
  }, character(1), USE.NAMES = FALSE)

  consts <- setdiff(names(parameters$constants), out$name)
  if (length(consts)) {
    out <- rbind(out, tibble::tibble(
      name = consts, type = "constant", units = NA_character_, dims = NA_character_,
      from = NA_character_, to = NA_character_, doc = NA_character_,
      equation = vapply(parameters$constants[consts], deparse1_, character(1),
                        USE.NAMES = FALSE)))
  }
  out[] <- lapply(out, unname)
  out[c("name", "type", "equation", "units", "doc", "dims", "from", "to")]
}
