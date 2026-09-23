## ---------------------------------------------------------------------------
## The integrator. Euler and classical RK4, written here rather than delegated
## so that the stateful built-ins (pipeline delays, `previous()`) see a
## well-defined outer time grid.
## ---------------------------------------------------------------------------

make_state_store <- function(stateful) {
  ST <- new.env(parent = emptyenv())
  for (id in names(stateful)) {
    e <- new.env(parent = emptyenv())
    e$buf <- list()
    e$k <- 0L
    e$initial <- 0
    assign(id, e, envir = ST)
  }
  ST
}

make_run_env <- function(bm, ST) {
  env <- make_base_env(bm$constants, bm$lookup_funs, bm$input_funs, bm$spec)
  DT <- bm$spec$dt

  env$.sd_hist_get <- function(id, delay, time) {
    st <- get(id, envir = ST)
    if (st$k == 0L) return(st$initial)
    n <- as.numeric(delay) / DT
    n <- floor(n + 0.5)
    n[!is.finite(n) | n < 1] <- 1
    if (length(n) == 1L) {
      i <- st$k - as.integer(n) + 1L
      if (i < 1L) return(st$initial)
      return(st$buf[[i]])
    }
    ini <- st$initial
    vapply(seq_along(n), function(j) {
      i <- st$k - as.integer(n[j]) + 1L
      v <- if (i < 1L) ini else st$buf[[i]]
      if (length(v) > 1L) v[[j]] else v[[1L]]
    }, numeric(1))
  }

  env$.sd_prev_get <- function(id) {
    st <- get(id, envir = ST)
    if (st$k == 0L) st$initial else st$buf[[st$k]]
  }

  new.env(parent = env)
}

## Which outer steps to save: the step nearest each multiple of `saveat`, plus
## the last one. `saveat` need not be a whole multiple of `dt`.
save_steps <- function(nsteps, dt, saveat) {
  ntarget <- floor(nsteps * dt / saveat + 1e-9)
  j <- seq.int(0, ntarget)
  k <- as.integer(round(j * saveat / dt))
  k <- pmin(pmax(k, 0L), nsteps)
  sort(unique(c(k, nsteps)))
}

sd_run <- function(bm) {
  spec <- bm$spec
  dt <- spec$dt
  nsteps <- max(0L, as.integer(floor((spec$stop - spec$start) / dt + 1e-9)))

  ST <- make_state_store(bm$stateful)
  env <- make_run_env(bm, ST)

  node_expr <- bm$node_expr
  eval_order <- bm$eval_order
  stock_names <- bm$stock_names
  deriv <- bm$deriv
  out_vars <- bm$out_vars
  stateful_in <- vapply(bm$stateful, function(s) s$in_node, character(1))
  stateful_ids <- names(bm$stateful)
  nn_stocks <- stock_names[vapply(bm$stocks[stock_names], function(s) s$non_negative, logical(1))]

  ## ---- initialisation ------------------------------------------------------
  env$t <- spec$start
  state <- list()
  for (node in bm$init_order) {
    if (startsWith(node, "init:")) {
      nm <- substring(node, 6L)
      ex <- bm$stocks[[nm]]$init_expr
      val <- if (is.numeric(ex)) ex else drop_matrix(eval(ex, env))
      val <- as.numeric(val)
      if (bm$stocks[[nm]]$internal) bm$stocks[[nm]]$len <- length(val)
      state[[nm]] <- val
      assign(nm, val, envir = env)
    } else {
      ex <- bm$init_only[[node]]
      if (is.null(ex)) ex <- node_expr[[node]]
      val <- drop_matrix(eval(ex, env))
      assign(node, val, envir = env)
      if (node %in% stateful_ids) {
        stx <- get(node, envir = ST)
        stx$initial <- val
      }
    }
  }
  state <- state[stock_names]

  ## ---- output storage ------------------------------------------------------
  save_at <- save_steps(nsteps, dt, spec$saveat)   # 0-based step indices
  nsave <- length(save_at)
  lens <- vapply(out_vars, function(nm) length(get0(nm, envir = env, ifnotfound = 0)),
                 integer(1))
  res <- lapply(out_vars, function(nm) matrix(NA_real_, nrow = nsave, ncol = lens[[nm]]))
  names(res) <- out_vars
  tvec <- numeric(nsave)

  ## The expression set and its order never change between steps, so resolve
  ## both once here: a closure over `env` is JIT-compiled on first call, where
  ## `eval(expr, env)` re-walks the AST on every step. Deliberately not
  ## `compiler::cmpfun()` -- compiling eagerly costs more than it saves on the
  ## many-short-runs shape (`calibrate()`), and the JIT gets there anyway.
  ##
  ## ponytail: what is left is the interpreter loop itself -- `env[[name]] <-`
  ## per node per step, and the per-stock list arithmetic below. Ceiling is
  ## roughly another 2x; unlocking it means holding state as one flat numeric
  ## vector with per-variable index slices instead of a named list of vectors,
  ## which rewrites bind.R's contract as well. Not worth it at this size.
  as_thunk <- function(ex) eval(call("function", NULL, ex), env)
  node_fun <- lapply(node_expr[eval_order], as_thunk)
  deriv_fun <- lapply(deriv[stock_names], as_thunk)
  n_nodes <- length(node_fun)
  n_stocks <- length(stock_names)
  deriv_out <- vector("list", n_stocks)

  eval_all <- function(tt, st) {
    env$t <- tt
    for (i in seq_len(n_stocks)) env[[stock_names[i]]] <- st[[i]]
    for (i in seq_len(n_nodes)) {
      v <- node_fun[[i]]()
      env[[eval_order[i]]] <- if (is.matrix(v)) drop_matrix(v) else v
    }
    invisible(NULL)
  }
  get_derivs <- function() {
    for (i in seq_len(n_stocks)) {
      v <- deriv_fun[[i]]()
      deriv_out[[i]] <- if (is.matrix(v)) drop_matrix(v) else v
    }
    deriv_out
  }
  record <- function(si, tt) {
    tvec[si] <<- tt
    for (nm in out_vars) {
      v <- env[[nm]]
      res[[nm]][si, ] <<- if (length(v) == lens[[nm]]) as.numeric(v) else
        rep_len(as.numeric(v), lens[[nm]])
    }
    invisible(NULL)
  }

  si <- 1L
  method <- spec$method
  is_euler <- identical(method, "euler")
  has_stateful <- length(stateful_ids) > 0L

  if (!method %in% c("euler", "rk4")) {
    desolve_steps(bm, method, state, spec$start + save_at * dt,
                  eval_all, get_derivs, nn_stocks, record)
    return(list(time = tvec, values = res, lens = lens))
  }

  for (k in seq_len(nsteps + 1L) - 1L) {
    tk <- spec$start + k * dt
    eval_all(tk, state)
    if (si <= nsave && save_at[si] == k) { record(si, tk); si <- si + 1L }
    pending <- if (has_stateful)
      lapply(stateful_in, function(n) env[[n]]) else list()

    if (k == nsteps) break

    if (is_euler) {
      d <- get_derivs()
      for (i in seq_along(stock_names)) {
        state[[i]] <- state[[i]] + dt * d[[i]]
      }
    } else {
      y0 <- state
      k1 <- get_derivs()
      s2 <- y0; for (i in seq_along(s2)) s2[[i]] <- y0[[i]] + (dt / 2) * k1[[i]]
      eval_all(tk + dt / 2, s2); k2 <- get_derivs()
      s3 <- y0; for (i in seq_along(s3)) s3[[i]] <- y0[[i]] + (dt / 2) * k2[[i]]
      eval_all(tk + dt / 2, s3); k3 <- get_derivs()
      s4 <- y0; for (i in seq_along(s4)) s4[[i]] <- y0[[i]] + dt * k3[[i]]
      eval_all(tk + dt, s4); k4 <- get_derivs()
      for (i in seq_along(stock_names)) {
        state[[i]] <- y0[[i]] + (dt / 6) * (k1[[i]] + 2 * k2[[i]] + 2 * k3[[i]] + k4[[i]])
      }
    }
    for (nm in nn_stocks) state[[nm]][state[[nm]] < 0] <- 0

    if (has_stateful) {
      for (j in seq_along(stateful_ids)) {
        st <- get(stateful_ids[j], envir = ST)
        st$k <- st$k + 1L
        st$buf[[st$k]] <- pending[[j]]
      }
    }
  }

  list(time = tvec, values = res, lens = lens)
}

## ---------------------------------------------------------------------------
## Optional adaptive / stiff integration, delegated to deSolve. Everything the
## model needs already exists above: `eval_all()` puts the run environment at
## (t, state) and `get_derivs()` reads dState/dt back out. All this does is pack
## that pair into the `function(t, state, parms)` that `deSolve::ode()` wants,
## and unpack the state grid it returns back through `record()`.
##
## ponytail: no event or root handling. Lookup-table breakpoints, the MIN/MAX
## kinks and `step()`/`pulse()` of R/builtins.R are discontinuities the adaptive
## steppers will step straight over (or chatter on), and `non_negative` stocks
## are clamped only at the saved times, never inside a step. Revisit here: pass
## `events = ` / `rootfunc = ` through to `ode()`, and have the rewriter in
## R/bind.R report the breakpoint times, if this ever matters.
## ---------------------------------------------------------------------------

## User-facing method name -> deSolve's own.
desolve_method <- function(method) if (identical(method, "rk45")) "ode45" else method

desolve_steps <- function(bm, method, state0, times, eval_all, get_derivs,
                          nn_stocks, record) {
  if (length(bm$stateful))
    sd_abort(sprintf(
      paste("Method '%s' cannot run a model that uses `delay_fixed()` or",
            "`previous()`: those built-ins are queues over the fixed `dt` grid.",
            "Use method = \"euler\" or \"rk4\"."), method))

  lens <- vapply(state0, length, integer(1))
  idx <- split(seq_len(sum(lens)), factor(rep(seq_along(lens), lens),
                                          levels = seq_along(lens)))
  unpack <- function(y) stats::setNames(lapply(idx, function(i) unname(y[i])),
                                        names(state0))

  if (length(times) > 1L) {
    out <- deSolve::ode(
      y = unlist(state0, use.names = FALSE), times = times, parms = NULL,
      method = desolve_method(method),
      func = function(t, y, parms) {
        eval_all(t, unpack(y))
        list(unlist(get_derivs(), use.names = FALSE))
      })
    if (nrow(out) < length(times))
      sd_abort(sprintf("`deSolve::ode()` stopped at t = %g with method '%s'.",
                       out[nrow(out), 1L], method))
  } else {
    out <- matrix(c(times, unlist(state0, use.names = FALSE)), nrow = 1L)
  }

  for (i in seq_along(times)) {
    st <- unpack(out[i, -1L])
    for (nm in nn_stocks) st[[nm]][st[[nm]] < 0] <- 0
    eval_all(times[i], st)
    record(i, times[i])
  }
  invisible(NULL)
}
