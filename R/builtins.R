#' Built-in functions on an equation right-hand side
#'
#' These names are recognised inside [sd_equations()]. They are rewritten when
#' the model is bound, so they are not ordinary R functions you can call
#' directly.
#'
#' \describe{
#'   \item{`step(height, time)`}{0 before `time`, `height` from `time` on.}
#'   \item{`pulse(start, width)`}{1 during `[start, start + width)`, else 0.}
#'   \item{`ramp(slope, start, end)`}{0, then a linear rise of `slope`, held flat
#'     after `end`.}
#'   \item{`delayN(x, delay, order, initial)`}{Exponential (material) delay of
#'     `x`: a cascade of `order` stocks. `initial` is the delay's *output* level
#'     at `t = start`, defaulting to `x` there. `order` defaults to 1 and is read
#'     once, at initialisation.}
#'   \item{`smoothN(x, time, order, initial)`}{Information smoothing of `x` with
#'     adjustment time `time`, at any `order` (1 by default). `initial` defaults
#'     to `x` at `t = start`.}
#'   \item{`delay_fixed(x, delay, initial)`}{Pipeline delay: whatever goes in
#'     comes out unchanged, exactly `delay` later. `delay` may vary and is
#'     rounded to the nearest whole `dt`.}
#'   \item{`forecast(x, average_time, horizon)`}{Trend extrapolation, sugar over
#'     `smoothN`: `x * (1 + horizon * (x - s) / (s * average_time))`.}
#'   \item{`previous(x, init)`}{The value `x` held at the previous saved step.}
#'   \item{`t`, `dt`}{Current time and the integration step.}
#' }
#'
#' Base-R maths (`ifelse`, `min`, `max`, `sqrt`, `sin`, `exp`, `log`, `sum`,
#' `%*%`, ...) is available unchanged.
#'
#' @name sd_builtins
NULL

## Runtime implementations. `time` is threaded in explicitly by the rewriter so
## that user equations never have to mention it.
.sd_step <- function(height, when, time) height * as.numeric(time >= when)
.sd_pulse <- function(start, width, time) {
  if (length(width) == 1L && isTRUE(width <= 0)) return(0 * start)
  as.numeric(time >= start & time < start + width)
}
.sd_ramp <- function(slope, start, end, time) {
  x <- pmin(pmax(time - start, 0), pmax(end - start, 0))
  slope * x
}

## Names the rewriter knows about.
STATEFUL_FNS <- c("delayN", "smoothN", "delay_fixed", "forecast", "previous")
SHAPING_FNS <- c("step", "pulse", "ramp")

## Functions allowed as call heads in an equation, beyond lookups and built-ins.
ALLOWED_CALLS <- c(
  "(", "+", "-", "*", "/", "^", "%%", "%/%", "%*%", "%o%", "[", "[[",
  "ifelse", "if", "min", "max", "pmin", "pmax", "sum", "prod", "mean",
  "cumsum", "abs", "sign", "sqrt", "exp", "log", "log2", "log10", "log1p",
  "expm1", "sin", "cos", "tan", "asin", "acos", "atan", "atan2", "sinh",
  "cosh", "tanh", "floor", "ceiling", "round", "trunc", "rev", "c", "length",
  "seq_len", "seq_along", "rep", "as.numeric", "as.vector", "matrix", "diag",
  "crossprod", "outer", "which", "which.max", "which.min", "range", "sd",
  "var", "!", "&", "|", "&&", "||", ">", "<", ">=", "<=", "==", "!=",
  "is.na", "xor", "colSums", "rowSums", "colMeans", "rowMeans", "t",
  STATEFUL_FNS, SHAPING_FNS
)
