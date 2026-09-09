## ---------------------------------------------------------------------------
## Rewriting equations into an integrable form.
##
## `delayN()` and `smoothN()` are cascades of stocks; they are expanded into
## real internal stocks so that the chosen integrator sees them. `delay_fixed()`
## and `previous()` are queues over the outer time grid and become stateful
## nodes. Shaping functions get the current time threaded in.
##
## Internal names all start with a dot, and are dropped from the output.
## ---------------------------------------------------------------------------

new_expand_ctx <- function(const_env) {
  e <- new.env(parent = emptyenv())
  e$stocks <- list()      # name -> list(init_expr = <lang|numeric>)
  e$derivs <- list()      # internal stock name -> derivative expression
  e$nodes <- list()       # internal aux name -> expression
  e$init_nodes <- list()  # internal aux name -> expression used only at t = start
  e$stateful <- list()    # id -> list(kind, in_node)
  e$counter <- 0L
  e$const_env <- const_env
  e
}

new_id <- function(ctx, owner, what) {
  ctx$counter <- ctx$counter + 1L
  sprintf(".%s_%s_%d", owner, what, ctx$counter)
}

## Positional/named argument matching for the built-ins.
match_builtin_args <- function(e, formals_) {
  args <- as.list(e)[-1]
  nms <- names(args)
  if (is.null(nms)) nms <- rep("", length(args))
  out <- stats::setNames(vector("list", length(formals_)), formals_)
  filled <- rep(FALSE, length(formals_))
  used <- rep(FALSE, length(args))
  for (i in seq_along(args)) {
    if (!nzchar(nms[i])) next
    m <- pmatch(nms[i], formals_)
    if (is.na(m))
      sd_abort(sprintf("`%s()` has no argument '%s'.", deparse1_(e[[1]]), nms[i]),
               i = sprintf("Arguments are: %s.", comma(formals_)))
    out[[m]] <- args[[i]]; filled[m] <- TRUE; used[i] <- TRUE
  }
  free <- which(!filled)
  pos <- which(!used)
  if (length(pos) > length(free))
    sd_abort(sprintf("Too many arguments to `%s()`.", deparse1_(e[[1]])))
  for (k in seq_along(pos)) {
    out[[free[k]]] <- args[[pos[k]]]; filled[free[k]] <- TRUE
  }
  out
}

## `order` is read once, at initialisation, so it must be computable from
## constants and time alone.
eval_static <- function(expr, ctx, what) {
  if (is.null(expr)) return(NULL)
  v <- tryCatch(eval(expr, ctx$const_env), error = function(e) NULL)
  if (is.null(v) || !is.numeric(v) || length(v) != 1L || is.na(v))
    sd_abort(sprintf("`%s` must resolve to a single number at initialisation.", what),
             x = sprintf("Got: %s", deparse1_(expr)),
             i = "It may use constants, numeric literals and the shaping functions only.")
  v
}

expand_expr <- function(e, ctx, owner) {
  if (!is.call(e)) return(e)
  head <- e[[1]]
  fn <- if (is.symbol(head)) as.character(head) else ""

  ## expand arguments first
  args <- as.list(e)[-1]
  args <- lapply(args, expand_expr, ctx = ctx, owner = owner)
  e2 <- as.call(c(list(head), args))
  names(e2) <- c("", names(as.list(e)[-1]) %||% rep("", length(args)))

  if (fn %in% SHAPING_FNS) {
    return(rewrite_shaping(e2, fn))
  }
  if (fn %in% STATEFUL_FNS) {
    return(expand_stateful(e2, fn, ctx, owner))
  }
  e2
}

rewrite_shaping <- function(e, fn) {
  a <- switch(fn,
    step  = match_builtin_args(e, c("height", "time")),
    pulse = match_builtin_args(e, c("start", "width")),
    ramp  = match_builtin_args(e, c("slope", "start", "end"))
  )
  miss <- names(a)[vapply(a, is.null, logical(1))]
  if (length(miss))
    sd_abort(sprintf("`%s()` is missing argument(s): %s.", fn, comma(miss)))
  switch(fn,
    step  = bquote(.sd_step(.(a$height), .(a$time), t)),
    pulse = bquote(.sd_pulse(.(a$start), .(a$width), t)),
    ramp  = bquote(.sd_ramp(.(a$slope), .(a$start), .(a$end), t))
  )
}

expand_stateful <- function(e, fn, ctx, owner) {
  switch(fn,
    smoothN     = expand_smooth(e, ctx, owner),
    delayN      = expand_delayn(e, ctx, owner),
    delay_fixed = expand_delay_fixed(e, ctx, owner),
    forecast    = expand_forecast(e, ctx, owner),
    previous    = expand_previous(e, ctx, owner)
  )
}

expand_smooth <- function(e, ctx, owner) {
  a <- match_builtin_args(e, c("x", "time", "order", "initial"))
  if (is.null(a$x) || is.null(a$time))
    sd_abort("`smoothN()` needs at least `x` and `time`.")
  n <- as.integer(round(eval_static(a$order, ctx, "smoothN(order = )") %||% 1))
  if (n < 1L) sd_abort("`smoothN(order = )` must be at least 1.")
  init <- a$initial %||% a$x
  id <- new_id(ctx, owner, "smooth")
  stage <- sprintf("%s_%d", id, seq_len(n))
  for (i in seq_len(n)) {
    ctx$stocks[[stage[i]]] <- list(init_expr = init)
    inp <- if (i == 1L) a$x else as.symbol(stage[i - 1L])
    ctx$derivs[[stage[i]]] <-
      bquote((.(inp) - .(as.symbol(stage[i]))) / (.(a$time) / .(n)))
  }
  as.symbol(stage[n])
}

expand_delayn <- function(e, ctx, owner) {
  a <- match_builtin_args(e, c("x", "delay", "order", "initial"))
  if (is.null(a$x) || is.null(a$delay))
    sd_abort("`delayN()` needs at least `x` and `delay`.")
  n <- as.integer(round(eval_static(a$order, ctx, "delayN(order = )") %||% 1))
  if (n < 1L) sd_abort("`delayN(order = )` must be at least 1.")
  init_out <- a$initial %||% a$x
  id <- new_id(ctx, owner, "delay")
  lev <- sprintf("%s_%d", id, seq_len(n))
  out <- sprintf("%s_out_%d", id, seq_len(n))
  for (i in seq_len(n)) {
    ctx$stocks[[lev[i]]] <- list(init_expr = bquote(.(init_out) * (.(a$delay) / .(n))))
    ctx$nodes[[out[i]]] <- bquote(.(as.symbol(lev[i])) / (.(a$delay) / .(n)))
    inp <- if (i == 1L) a$x else as.symbol(out[i - 1L])
    ctx$derivs[[lev[i]]] <- bquote(.(inp) - .(as.symbol(out[i])))
  }
  as.symbol(out[n])
}

expand_forecast <- function(e, ctx, owner) {
  a <- match_builtin_args(e, c("x", "average_time", "horizon"))
  if (any(vapply(a, is.null, logical(1))))
    sd_abort("`forecast()` needs `x`, `average_time` and `horizon`.")
  s <- expand_smooth(bquote(smoothN(.(a$x), .(a$average_time))), ctx, owner)
  bquote(.(a$x) * (1 + .(a$horizon) * (.(a$x) - .(s)) / (.(s) * .(a$average_time))))
}

expand_delay_fixed <- function(e, ctx, owner) {
  a <- match_builtin_args(e, c("x", "delay", "initial"))
  if (is.null(a$x) || is.null(a$delay))
    sd_abort("`delay_fixed()` needs at least `x` and `delay`.")
  id <- new_id(ctx, owner, "fixed")
  in_id <- paste0(id, "_in")
  ctx$nodes[[in_id]] <- a$x
  ctx$nodes[[id]] <- bquote(.sd_hist_get(.(id), .(a$delay), t))
  ctx$init_nodes[[id]] <- a$initial %||% a$x
  ctx$stateful[[id]] <- list(kind = "delay_fixed", in_node = in_id)
  as.symbol(id)
}

expand_previous <- function(e, ctx, owner) {
  a <- match_builtin_args(e, c("x", "init"))
  if (is.null(a$x)) sd_abort("`previous()` needs `x`.")
  id <- new_id(ctx, owner, "prev")
  in_id <- paste0(id, "_in")
  ctx$nodes[[in_id]] <- a$x
  ctx$nodes[[id]] <- bquote(.sd_prev_get(.(id)))
  ctx$init_nodes[[id]] <- a$init %||% a$x
  ctx$stateful[[id]] <- list(kind = "previous", in_node = in_id)
  as.symbol(id)
}
