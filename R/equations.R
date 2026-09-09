#' The equation layer: functional forms
#'
#' Each argument is a two-sided formula. The left-hand side is the name of a
#' flow or auxiliary declared in [sd_structure()], or `init(Stock)` to give a
#' stock a *derived* initial value. The right-hand side is an ordinary R
#' expression over other variables, constants, lookups, the built-ins
#' ([sd_builtins]) and numeric literals.
#'
#' Order does not matter: equations are resolved into a dependency graph when
#' [simulate()] binds the layers.
#'
#' @param ... Two-sided formulas.
#' @return An object of class `sd_equations`.
#' @examples
#' sd_equations(
#'   beta   ~ contact_rate * infectivity / total_population,
#'   lambda ~ beta * I,
#'   IR     ~ S * lambda,
#'   RR     ~ I / recovery_time
#' )
#' @export
sd_equations <- function(...) {
  fs <- list(...)
  fs <- unlist(lapply(fs, function(f) if (inherits(f, "sd_equations")) f$eqns else list(f)),
               recursive = FALSE)
  eqns <- lapply(fs, parse_equation)
  names(eqns) <- vapply(eqns, function(e) e$key, character(1))
  dup <- names(eqns)[duplicated(names(eqns))]
  if (length(dup))
    sd_abort(sprintf("Duplicate equation(s) for: %s.", comma(unique(dup))))
  structure(list(eqns = eqns), class = "sd_equations")
}

parse_equation <- function(f) {
  if (!rlang::is_formula(f) || length(f) != 3L)
    sd_abort("Every argument to `sd_equations()` must be a two-sided formula, `lhs ~ rhs`.")
  lhs <- rlang::f_lhs(f)
  rhs <- rlang::f_rhs(f)
  if (is.symbol(lhs)) {
    nm <- as.character(lhs)
    return(list(name = nm, key = nm, is_init = FALSE, rhs = rhs, env = rlang::f_env(f)))
  }
  if (is.call(lhs) && identical(as.character(lhs[[1]]), "init") && length(lhs) == 2L &&
      is.symbol(lhs[[2]])) {
    nm <- as.character(lhs[[2]])
    return(list(name = nm, key = paste0("init:", nm), is_init = TRUE, rhs = rhs,
                env = rlang::f_env(f)))
  }
  sd_abort(sprintf("Unsupported equation left-hand side: `%s`.", deparse1_(lhs)),
           i = "Use `name ~ ...` or `init(Stock) ~ ...`.")
}

#' Replace or add equations
#'
#' Layers are immutable: `update()` returns a new `sd_equations` object with the
#' given formulas replacing (by left-hand side) or extending the existing ones.
#'
#' @param object An `sd_equations` object.
#' @param ... Two-sided formulas.
#' @return A new `sd_equations` object.
#' @examples
#' e <- sd_equations(lambda ~ beta * I, IR ~ S * lambda)
#' update(e, lambda ~ contact_rate * infectivity * I)
#' @export
update.sd_equations <- function(object, ...) {
  new <- sd_equations(...)
  merged <- object$eqns
  for (k in names(new$eqns)) merged[[k]] <- new$eqns[[k]]
  structure(list(eqns = merged), class = "sd_equations")
}

#' Derived initial value
#'
#' `init()` is only meaningful on the left-hand side of a formula inside
#' [sd_equations()]: `init(S) ~ population - I0`. Calling it directly is an
#' error.
#'
#' @param x A stock name (unquoted).
#' @return Nothing; `init()` is syntax, not a function.
#' @export
init <- function(x) {
  sd_abort("`init()` may only be used on the left-hand side of an equation.")
}
