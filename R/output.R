## ---------------------------------------------------------------------------
## One long-format tibble per run.
## ---------------------------------------------------------------------------

## Labels for every element of a variable, as a data frame of dimension columns
## (or NULL when the variable is a scalar).
dim_labels <- function(struct, dims) {
  if (is.null(dims) || !length(dims)) return(NULL)
  lv <- lapply(dims, function(d) struct$dims[[d]])
  names(lv) <- dims
  g <- expand.grid(lv, stringsAsFactors = FALSE, KEEP.OUT.ATTRS = FALSE)
  g[dims]
}

build_output <- function(bm, run, scenario = NULL) {
  struct <- bm$struct
  all_dims <- names(struct$dims)
  vars <- struct$vars
  pieces <- list()

  for (nm in bm$out_vars) {
    v <- vars[[nm]]
    m <- run$values[[nm]]
    nt <- length(run$time)
    ne <- ncol(m)
    lab <- dim_labels(struct, v$dims)
    if (is.null(lab) && ne > 1L) {
      lab <- data.frame(.element = as.character(seq_len(ne)), stringsAsFactors = FALSE)
    }
    d <- list(
      time = rep(run$time, times = ne),
      variable = rep(nm, nt * ne),
      value = as.numeric(m),
      unit = rep(v$units %||% NA_character_, nt * ne),
      type = rep(v$type, nt * ne)
    )
    for (dn in all_dims) {
      d[[dn]] <- if (!is.null(lab) && dn %in% names(lab))
        rep(lab[[dn]], each = nt) else rep(NA_character_, nt * ne)
    }
    pieces[[nm]] <- tibble::as_tibble(d)
  }

  out <- do.call(rbind, pieces)
  out <- tibble::as_tibble(out)
  if (!is.null(scenario)) out$scenario <- scenario
  order_output_cols(out, all_dims)
}

order_output_cols <- function(out, all_dims) {
  first <- intersect(c("scenario", all_dims), names(out))
  rest <- intersect(c("time", "variable", "value", "unit", "type", "source"), names(out))
  out[c(first, rest, setdiff(names(out), c(first, rest)))]
}

## Stack an observed data frame into the same long shape.
observed_long <- function(observed, map = NULL, all_dims = character(0),
                          scenario = NULL, model_vars = character(0)) {
  if (is.null(observed)) return(NULL)
  if (!is.data.frame(observed)) sd_abort("`observed` must be a data frame.")
  cols <- names(observed)
  tcol <- cols[tolower(cols) == "time"]
  if (!length(tcol)) sd_abort("`observed` needs a `time` column.")
  tcol <- tcol[1]
  vcols <- setdiff(cols, tcol)

  if (is.null(map)) {
    map <- stats::setNames(vcols, vcols)
  } else {
    if (is.null(names(map)) || any(!nzchar(names(map))))
      sd_abort("`map` must be named: `c(model_variable = \"observed_column\")`.")
    miss <- setdiff(unname(map), cols)
    if (length(miss))
      sd_abort(sprintf("`observed` has no column(s): %s.", comma(miss)))
  }
  bad <- setdiff(names(map), model_vars)
  if (length(bad) && length(model_vars))
    sd_warn(sprintf("Observed series for variable(s) not in the model: %s.", comma(bad)))

  pieces <- lapply(names(map), function(mv) {
    d <- list(
      time = as.numeric(observed[[tcol]]),
      variable = mv,
      value = as.numeric(observed[[map[[mv]]]]),
      unit = NA_character_,
      type = "observed"
    )
    for (dn in all_dims) d[[dn]] <- NA_character_
    tibble::as_tibble(d)
  })
  out <- tibble::as_tibble(do.call(rbind, pieces))
  if (!is.null(scenario)) out$scenario <- scenario
  out
}

new_sd_result <- function(tbl, bm, observed_tbl = NULL) {
  if (!is.null(observed_tbl)) {
    tbl$source <- "model"
    observed_tbl$source <- "observed"
    miss <- setdiff(names(tbl), names(observed_tbl))
    for (m in miss) observed_tbl[[m]] <- NA
    observed_tbl <- observed_tbl[names(tbl)]
    tbl <- tibble::as_tibble(rbind(tbl, observed_tbl))
  }
  tbl <- order_output_cols(tbl, names(bm$struct$dims))
  class(tbl) <- c("sd_result", class(tbl))
  attr(tbl, "sd_meta") <- list(
    name = bm$struct$meta$name %||% NULL,
    spec = bm$spec,
    dims = names(bm$struct$dims),
    time_unit = bm$spec$time_unit
  )
  tbl
}
