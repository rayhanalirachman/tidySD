#' @importFrom ggplot2 autoplot
#' @export
ggplot2::autoplot

#' Plot a simulation result
#'
#' The tidy output means the plot comes free. By default every variable gets a
#' panel; give `x` and `y` for a phase portrait instead.
#'
#' @param object An `sd_result` from [simulate()].
#' @param vars Character vector of variables to keep. Defaults to every stock
#'   and flow when the model has any stocks, otherwise every variable.
#' @param x,y For `autoplot()`, variable names for a phase portrait; when given,
#'   `vars` is ignored. For `plot()`, `x` is the `sd_result` itself.
#' @param facet One of `"variable"` (default), `"scenario"`, `"both"` or
#'   `"none"`.
#' @param scales Passed to [ggplot2::facet_wrap()].
#' @param ... Unused.
#' @return A `ggplot` object.
#' @method autoplot sd_result
#' @export
autoplot.sd_result <- function(object, vars = NULL, x = NULL, y = NULL,
                               facet = c("variable", "scenario", "both", "none"),
                               scales = "free_y", ...) {
  facet <- match.arg(facet)
  meta <- attr(object, "sd_meta")
  d <- as.data.frame(object)
  has_scen <- "scenario" %in% names(d)
  has_src <- "source" %in% names(d)
  dims <- intersect(meta$dims %||% character(0), names(d))

  tlab <- if (!is.null(meta$time_unit)) paste0("time (", meta$time_unit, ")") else "time"

  if (!is.null(x) && !is.null(y)) {
    keys <- c(if (has_scen) "scenario", dims, "time")
    dx <- d[d$variable == x, c(keys, "value"), drop = FALSE]
    dy <- d[d$variable == y, c(keys, "value"), drop = FALSE]
    if (!nrow(dx) || !nrow(dy))
      sd_abort(sprintf("`%s` or `%s` is not in the result.", x, y))
    names(dx)[names(dx) == "value"] <- ".x"
    names(dy)[names(dy) == "value"] <- ".y"
    dd <- merge(dx, dy, by = keys)
    dd <- dd[order(dd$time), , drop = FALSE]
    p <- ggplot2::ggplot(dd, ggplot2::aes(x = .data$.x, y = .data$.y)) +
      ggplot2::labs(x = x, y = y, title = meta$name)
    p <- p + if (has_scen)
      ggplot2::geom_path(ggplot2::aes(colour = .data$scenario)) else
      ggplot2::geom_path()
    return(p + ggplot2::theme_minimal())
  }

  if (is.null(vars)) {
    st <- unique(d$variable[d$type %in% c("stock", "flow")])
    vars <- if (length(st)) st else unique(d$variable[d$type != "observed"])
  }
  d <- d[d$variable %in% vars, , drop = FALSE]
  if (!nrow(d)) sd_abort("Nothing left to plot after filtering by `vars`.")
  d$variable <- factor(d$variable, levels = intersect(vars, unique(d$variable)))

  model <- if (has_src) d[d$source == "model", , drop = FALSE] else d
  obs <- if (has_src) d[d$source == "observed", , drop = FALSE] else d[0, , drop = FALSE]

  colour_by <- if (has_scen) "scenario" else if (length(dims) &&
    any(!is.na(model[[dims[1]]]))) dims[1] else NULL

  p <- ggplot2::ggplot(model, ggplot2::aes(x = .data$time, y = .data$value))
  p <- p + if (!is.null(colour_by))
    ggplot2::geom_line(ggplot2::aes(colour = .data[[colour_by]])) else
    ggplot2::geom_line()
  if (nrow(obs))
    p <- p + ggplot2::geom_point(data = obs, size = 1.4, alpha = 0.8,
                                 ggplot2::aes(x = .data$time, y = .data$value))

  p <- p + switch(facet,
    variable = ggplot2::facet_wrap(~variable, scales = scales),
    scenario = if (has_scen) ggplot2::facet_wrap(~scenario, scales = scales) else NULL,
    both = if (has_scen) ggplot2::facet_grid(variable ~ scenario, scales = scales) else
      ggplot2::facet_wrap(~variable, scales = scales),
    none = NULL
  )
  p + ggplot2::labs(x = tlab, y = NULL, title = meta$name) + ggplot2::theme_minimal()
}

#' @rdname autoplot.sd_result
#' @export
plot.sd_result <- function(x, ...) print(autoplot(x, ...))
