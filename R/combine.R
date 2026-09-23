## ---------------------------------------------------------------------------
## Stratification and composition.
##
## Both are rewrites of the three layers, not new machinery: whatever they
## return is an ordinary structure / equations / parameters triple that
## `simulate()`, `sd_diagram()`, `calibrate()` and friends already understand.
##
## Stratification rides entirely on the existing subscript mechanism: an
## arrayed model is just a model whose values are vectors, and the equations
## are unchanged because R recycles.
## ---------------------------------------------------------------------------

## The layer triple, however it was handed to us.
as_layers <- function(m, what) {
  if (inherits(m, "sd_structure")) return(list(structure = m))
  if (!is.list(m) || !inherits(m$structure, "sd_structure"))
    sd_abort(sprintf("`%s` must be a list with `structure`, `equations` and `parameters`.", what),
             i = "The shape `sd_example()` returns.")
  m
}

#' Stratify a model over a group dimension
#'
#' Turns an unsubscripted (or partly subscripted) model into one that runs the
#' same structure once per group, by declaring a new [subscripts()] dimension
#' and adding it to every stock, flow, auxiliary and input. The equations are
#' untouched -- an arrayed variable is a vector, and the arithmetic recycles --
#' so a scalar [constant()] applies to every group and a vector of one value per
#' group makes the groups differ.
#'
#' @param model An [sd_structure()], or a list with a `structure` element (what
#'   [sd_example()] returns); the other layers are passed through unchanged.
#' @param by A named list of dimensions to add, e.g.
#'   `list(region = c("north", "south"))`.
#' @param except Names of variables to leave unstratified -- typically
#'   whole-model aggregates such as `total ~ sum(I)`. [lookup()]s are always
#'   left alone.
#' @return The same kind of object that was passed in.
#' @examples
#' ex <- sd_example("sir")
#' st <- sd_stratify(ex$structure, by = list(region = c("north", "south")),
#'                   except = "beta")
#' sd_variables(st, "stock")
#' @export
sd_stratify <- function(model, by, except = NULL) {
  m <- as_layers(model, "model")
  struct <- m$structure

  if (!is.list(by)) by <- as.list(by)
  if (!length(by) || !is_named_scalar_list(by))
    sd_abort("`by` must be a named list, e.g. `by = list(region = c(\"north\", \"south\"))`.")
  by <- lapply(by, as.character)
  if (any(vapply(by, function(x) length(x) < 1L, logical(1))))
    sd_abort("Every dimension in `by` needs at least one member.")

  clash <- intersect(names(by), names(struct$dims))
  if (length(clash))
    sd_abort(sprintf("Dimension(s) already declared in the model: %s.", comma(clash)))

  unknown <- setdiff(except, names(struct$vars))
  if (length(unknown))
    sd_abort(sprintf("`except` names variable(s) the model does not declare: %s.", comma(unknown)))

  struct$dims <- c(struct$dims, by)
  ## ponytail: full cross only -- every variable gets every new dimension.
  ## Partial stratification is `except =`; a variable that needs *some* of the
  ## dimensions has to be declared by hand.
  strat <- setdiff(names(struct$vars), c(except, struct_names(struct, "lookup")))
  for (nm in strat) {
    struct$vars[[nm]]$dims <- union(struct$vars[[nm]]$dims %||% character(0), names(by))
  }

  ## ponytail: no automatic totals. Add `aux("total")` + `total ~ sum(S)` and
  ## list it in `except` if you want the aggregate back; revisit if every
  ## stratified model ends up writing the same three lines.
  if (inherits(model, "sd_structure")) return(struct)
  m$structure <- struct
  m
}

## ---- renaming ---------------------------------------------------------------

## Rewrite every symbol named in `map` (values as well as call heads, so that
## lookups called as functions move with everything else).
subst_syms <- function(e, map) {
  if (is.symbol(e)) {
    nm <- as.character(e)
    return(if (nm %in% names(map)) as.symbol(map[[nm]]) else e)
  }
  if (!is.call(e)) return(e)
  as.call(lapply(as.list(e), subst_syms, map = map))
}

rename_layers <- function(m, map) {
  ren <- function(x) if (is.character(x) && length(x) == 1L && x %in% names(map)) map[[x]] else x

  vars <- m$structure$vars
  for (nm in names(vars)) {
    v <- vars[[nm]]
    for (f in c("name", "from", "to", "input")) if (!is.null(v[[f]])) v[[f]] <- ren(v[[f]])
    vars[[nm]] <- v
  }
  names(vars) <- vapply(names(vars), ren, character(1))
  m$structure$vars <- vars

  if (!is.null(m$equations)) {
    ee <- lapply(m$equations$eqns, function(e) {
      e$name <- ren(e$name)
      e$key <- if (e$is_init) paste0("init:", e$name) else e$name
      e$rhs <- subst_syms(e$rhs, map)
      e
    })
    names(ee) <- vapply(ee, function(e) e$key, character(1))
    m$equations$eqns <- ee
  }

  if (!is.null(m$parameters)) {
    for (f in c("constants", "initials", "lookups", "inputs")) {
      if (length(m$parameters[[f]]))
        names(m$parameters[[f]]) <- vapply(names(m$parameters[[f]]), ren, character(1))
    }
  }
  m
}

prefix_layers <- function(m, p) {
  if (!nzchar(p)) return(m)
  nms <- unique(c(names(m$structure$vars), names(m$parameters$constants)))
  map <- stats::setNames(paste0(p, nms), nms)
  bad <- map[!vapply(map, is_valid_name, logical(1))]
  if (length(bad))
    sd_abort(sprintf("Prefix '%s' makes invalid name(s): %s.", p, comma(unname(bad))))
  rename_layers(m, map)
}

## ---- composition ------------------------------------------------------------

#' Compose two models into one
#'
#' Merges two independently written models into a single three-layer model that
#' runs on one time base. Variables keep their own equations and parameters;
#' `link` wires an output of the first model into the second by replacing one of
#' its `aux()` or `input()` "ports".
#'
#' The two models must not share variable names -- give `prefix` to namespace
#' them if they do.
#'
#' @param a,b Lists with `structure`, `equations`, `parameters` and optionally
#'   `spec` (the shape [sd_example()] returns).
#' @param link Named character vector `c(port_in_b = "variable_in_a")`. Each
#'   named port must be an `aux()` or `input()` of `b`; its declaration,
#'   equation and any `input_series()` are dropped and every reference to it in
#'   `b` becomes the named variable of `a`.
#' @param prefix Optional length-2 character vector prepended to every variable
#'   and constant name of `a` and `b` respectively, e.g. `c("a_", "b_")`.
#'   Applied before `link`, so `link` names the already-prefixed variables.
#' @return A list with `structure`, `equations`, `parameters` and `spec`, ready
#'   for [simulate()].
#' @examples
#' supply <- list(
#'   structure = sd_structure(
#'     stock("Inventory"),
#'     flow("production", from = .source, to = "Inventory"),
#'     aux("shipments")
#'   ),
#'   equations = sd_equations(production ~ rate, shipments ~ Inventory * 0.1),
#'   parameters = sd_parameters(constant(rate = 10), initial(Inventory = 100))
#' )
#' demand <- list(
#'   structure = sd_structure(
#'     stock("Backlog"),
#'     flow("filling", from = "Backlog", to = .sink),
#'     aux("deliveries")
#'   ),
#'   equations = sd_equations(filling ~ deliveries, deliveries ~ 0),
#'   parameters = sd_parameters(initial(Backlog = 50))
#' )
#' m <- sd_compose(supply, demand, link = c(deliveries = "shipments"))
#' out <- simulate(m$structure, m$equations, m$parameters,
#'                 spec = sim_spec(0, 10, 1))
#' @export
sd_compose <- function(a, b, link = NULL, prefix = NULL) {
  a <- as_layers(a, "a")
  b <- as_layers(b, "b")
  for (m in list(a, b)) {
    if (!inherits(m$equations, "sd_equations") || !inherits(m$parameters, "sd_parameters"))
      sd_abort("Both models need an `sd_equations()` and an `sd_parameters()` layer.")
  }

  if (!is.null(prefix)) {
    if (!is.character(prefix) || length(prefix) != 2L)
      sd_abort("`prefix` must be two strings, e.g. `c(\"a_\", \"b_\")`.")
    a <- prefix_layers(a, prefix[[1]])
    b <- prefix_layers(b, prefix[[2]])
  }

  if (length(link)) {
    link <- unlist(link)
    if (!is.character(link) || !is_named_scalar_list(as.list(link)))
      sd_abort("`link` must be named: `c(port_in_b = \"variable_in_a\")`.")
    for (port in names(link)) {
      v <- b$structure$vars[[port]]
      if (is.null(v))
        sd_abort(sprintf("`link`: '%s' is not a variable of the second model.", port))
      ## ponytail: a port is an aux() or input() only. Linking onto a stock or a
      ## flow would mean rewiring, not substitution; revisit if anyone asks.
      if (!v$type %in% c("aux", "input"))
        sd_abort(sprintf("`link`: '%s' is a %s; only an aux() or input() can be a port.",
                         port, v$type))
      if (is.null(a$structure$vars[[link[[port]]]]))
        sd_abort(sprintf("`link`: '%s' is not a variable of the first model.", link[[port]]))
      b$structure$vars[[port]] <- NULL
      b$equations$eqns[[port]] <- NULL
      b$parameters$inputs[[port]] <- NULL
    }
    b <- rename_layers(b, link)
  }

  dupes <- intersect(names(a$structure$vars), names(b$structure$vars))
  if (length(dupes))
    sd_abort(sprintf("Both models declare: %s.", comma(dupes)),
             i = "Give `prefix = c(\"a_\", \"b_\")` to namespace them, or `link` them.")

  dim_clash <- Filter(function(d) !identical(a$structure$dims[[d]], b$structure$dims[[d]]),
                      intersect(names(a$structure$dims), names(b$structure$dims)))
  if (length(dim_clash))
    sd_abort(sprintf("The models give different members for dimension(s): %s.",
                     comma(unlist(dim_clash))))

  ## ponytail: one time base only. Two specs that disagree would need
  ## resampling or nested integration; revisit when a real multi-rate model
  ## turns up.
  spec <- a$spec %||% b$spec
  if (!is.null(a$spec) && !is.null(b$spec) && !identical(a$spec, b$spec))
    sd_abort("The two models have different `sim_spec()`s.",
             i = "Compose models on one time base, and pass `spec = ` to `simulate()`.")

  const_clash <- Filter(function(k) !identical(a$parameters$constants[[k]],
                                               b$parameters$constants[[k]]),
                        intersect(names(a$parameters$constants), names(b$parameters$constants)))
  if (length(const_clash))
    sd_abort(sprintf("Both models set constant(s) to different values: %s.",
                     comma(unlist(const_clash))),
             i = "Give `prefix = c(\"a_\", \"b_\")` to namespace them.")

  struct <- a$structure
  struct$dims <- utils::modifyList(struct$dims, b$structure$dims)
  struct$vars <- c(struct$vars, b$structure$vars)
  if (is.null(struct$meta)) struct$meta <- b$structure$meta

  eqns <- structure(list(eqns = c(a$equations$eqns, b$equations$eqns)),
                    class = "sd_equations")

  pars <- unclass(a$parameters)
  bp <- unclass(b$parameters)
  for (f in c("constants", "initials", "lookups", "inputs"))
    pars[[f]] <- utils::modifyList(pars[[f]], bp[[f]])
  pars$references <- union(pars$references, bp$references)

  list(structure = struct, equations = eqns,
       parameters = structure(pars, class = "sd_parameters"), spec = spec)
}
