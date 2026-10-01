## Drawing sd_diagram objects. Everything here is internal; the entry point is
## autoplot.sd_diagram() in diagram.R. Positions are in "data units" of
## UNIT_IN inches; every style value travels in `k` (a palette plus fonts).

UNIT_IN <- 0.75
CHAR_W  <- 0.088      # data units per character at FONT size, when no metrics
LINE_H  <- 0.19
FONT    <- 3
FONT_CHAIN <- c("Inter", "Avenir Next", "Helvetica Neue", "Helvetica", "Arial",
                "DejaVu Sans")

## ---- palettes -------------------------------------------------------------------
## Roles: *_fill/_line/_text per node type; *_lw stroke weights; loop{R,B,Q}_* are
## the ribbon hue plus badge fill/line/text; band_a = ribbon opacity.
PALETTES <- list(
  # cool slate ramp, one blue accent for material flow and feedback loops;
  # a muted green/red pair only for link polarity
  mono = list(
    bg = "#F8F9FB", ink = "#14171F", muted = "#5F6673", rule = "#E3E6EB",
    shadow = "#0F172A",
    stock_fill = "#FFFFFF", stock_line = "#434A57", stock_text = "#14171F", stock_lw = 0.6,
    chip_fill = "#F1F3F6", chip_line = "#F1F3F6", chip_text = "#4A5261",
    pipe_out = "#8FA7EC", pipe_in = "#E4EBFC", valve = "#2F5BD3", valve_fill = "#FFFFFF",
    flow_fill = "#FFFFFF", flow_line = "#D3D8E0", flow_text = "#2E3440", flow_lw = 0.4,
    aux_fill = "#EEF0F3", aux_line = "#D9DDE3", aux_text = "#2E3440", aux_lw = 0.4,
    const_fill = "#F8F9FB", const_line = "#CDD2DA", const_text = "#5A616D", const_lw = 0.45,
    cloud_fill = "#EEF0F3", cloud_line = "#CDD2DA",
    info = "#A3AAB6",
    plus_fill = "#E3F1EA", plus_text = "#1F6B45",
    minus_fill = "#FBE7E4", minus_text = "#B3261E",
    loopR = "#2F5BD3", loopR_fill = "#2F5BD3", loopR_line = "#2F5BD3", loopR_text = "#FFFFFF",
    loopB = "#2F5BD3", loopB_fill = "#E4EBFC", loopB_line = "#9DB2EE", loopB_text = "#1E43A8",
    loopL = "#8A93A3", loopL_fill = "#EEF0F3", loopL_line = "#CDD2DA", loopL_text = "#4A5261",
    band_a = 0.14),
  # Okabe-Ito, muted: stock blue, flow bluish green, variable orange, constant
  # reddish purple; loops R vermilion, B sky blue
  oi = list(
    bg = "#FAFAF8", ink = "#1A1A1A", muted = "#5E5E5E", rule = "#E5E5E0",
    shadow = "#1A1A1A",
    stock_fill = "#E8F1F8", stock_line = "#7FB2D6", stock_text = "#004A75", stock_lw = 0.55,
    chip_fill = "#FFFFFF", chip_line = "#BCD6EA", chip_text = "#005A8C",
    pipe_out = "#7CC7B0", pipe_in = "#E1F2EC", valve = "#009E73", valve_fill = "#FFFFFF",
    flow_fill = "#E6F4EF", flow_line = "#9CD3C1", flow_text = "#005E44", flow_lw = 0.4,
    aux_fill = "#FDF3DE", aux_line = "#EDC878", aux_text = "#7A4F00", aux_lw = 0.4,
    const_fill = "#FAFAF8", const_line = "#DDB0CB", const_text = "#8C3C6C", const_lw = 0.45,
    cloud_fill = "#F0F0EC", cloud_line = "#D6D6D0",
    info = "#A6A6A0",
    plus_fill = "#E3F1FA", plus_text = "#11608F",
    minus_fill = "#FBE9DE", minus_text = "#A34300",
    loopR = "#D55E00", loopR_fill = "#FBE9DE", loopR_line = "#EDB08A", loopR_text = "#A34300",
    loopB = "#56B4E9", loopB_fill = "#E3F1FA", loopB_line = "#A5D3F0", loopB_text = "#11608F",
    loopL = "#999990", loopL_fill = "#F0F0EC", loopL_line = "#D6D6D0", loopL_text = "#55554F",
    band_a = 0.16),
  # black ink: all text #000 on light fills; black outlines/pipes/links with a thin
  # white halo so they also read on dark pages. Loops and signs are told apart by
  # fill, outline weight and dashing, not hue. Extra keys (all optional elsewhere):
  # halo (NA = none), halo_w, link_lw, const_lty, sign_ring, loop{R,B,L}_lw/_lty, loopB_band_lty.
  black = list(
    bg = "#FFFFFF", ink = "#000000", muted = "#000000", rule = "#000000",
    shadow = "#000000",
    stock_fill = "#FFFFFF", stock_line = "#000000", stock_text = "#000000", stock_lw = 0.9,
    chip_fill = "#EDEDED", chip_line = "#000000", chip_text = "#000000",
    pipe_out = "#000000", pipe_in = "#FFFFFF", valve = "#000000", valve_fill = "#FFFFFF",
    flow_fill = "#FFFFFF", flow_line = "#000000", flow_text = "#000000", flow_lw = 0.8,
    aux_fill = "#E6E6E6", aux_line = "#000000", aux_text = "#000000", aux_lw = 0.6,
    const_fill = "#FFFFFF", const_line = "#000000", const_text = "#000000", const_lw = 0.8,
    cloud_fill = "#FFFFFF", cloud_line = "#000000",
    info = "#000000",
    plus_fill = "#FFFFFF", plus_text = "#000000",
    minus_fill = "#A6A6A6", minus_text = "#000000",
    loopR = "#7A7A7A", loopR_fill = "#A6A6A6", loopR_line = "#000000", loopR_text = "#000000",
    loopB = "#7A7A7A", loopB_fill = "#FFFFFF", loopB_line = "#000000", loopB_text = "#000000",
    loopL = "#7A7A7A", loopL_fill = "#FFFFFF", loopL_line = "#000000", loopL_text = "#000000",
    band_a = 0.4,
    halo = "#FFFFFF", halo_w = 1.3, link_lw = 1.1, const_lty = "22", sign_ring = "#000000",
    loopR_lw = 1.6, loopB_lw = 0.8, loopL_lw = 0.8, loopR_lty = "solid", loopB_lty = "solid",
    loopL_lty = "22", loopB_band_lty = "32",
    # style knobs (optional everywhere): text weight/size bump, continuous corners
    # ("round" for circular), pipe walls, flow name as haloed text above the valve
    font_w = "semibold", font_w_const = "medium", txt_up = 0.4,
    corner = "squircle", corner_k = 0.5, corner_max = 0.45,
    pipe_w_out = 4.0, pipe_w_in = 2.5,
    flow_above = TRUE, text_halo = "#FFFFFF", text_halo_w = 0.028))

## Validate user colour overrides (a named list) against every known palette key,
## then merge them onto the chosen palette.
apply_colors <- function(pal, colors) {
  if (is.null(colors)) return(pal)
  ok <- unique(unlist(lapply(PALETTES, names)))
  if (!is.list(colors) || is.null(names(colors)) || any(!nzchar(names(colors))))
    stop("`colors` must be a named list.", call. = FALSE)
  # aliases: text = every *_text role, link = the influence-link colour
  al <- list(text = grep("_text$", names(pal), value = TRUE), link = "info")
  for (n in intersect(names(colors), names(al))) {
    colors[al[[n]]] <- colors[n]; colors[[n]] <- NULL }
  bad <- setdiff(names(colors), ok)
  if (length(bad)) stop("Unknown colour role(s): ", paste(bad, collapse = ", "),
                        ". Known: ", paste(ok, collapse = ", "), call. = FALSE)
  # a role whose defaults are all "#RRGGBB" takes a colour; the rest (weights,
  # line types, ...) take a single value of the default's type
  for (n in names(colors)) {
    v <- colors[[n]]
    dv <- unlist(lapply(PALETTES, `[[`, n))
    is_col <- is.character(dv) && all(grepl("^#", dv))
    good <- length(v) == 1L && !is.na(v) && (if (is_col) is.character(v) &&
      !inherits(tryCatch(grDevices::col2rgb(v), error = identity), "error")
      else !is.numeric(dv) || is.numeric(v))
    if (!good) sd_abort(sprintf("`colors$%s` = %s is not a valid %s.", n,
                                paste(deparse(v), collapse = ""),
                                if (is_col) "colour" else "value"),
                        i = if (is_col) "Use one colour name or hex code, e.g. \"grey40\" or \"#FFF4D6\"."
                            else sprintf("Use a single value like the default, %s.", deparse(dv[[1]])))
  }
  pal[names(colors)] <- colors
  pal
}

## Thin halo under a path layer (no-op unless the palette sets `halo`).
halo_path <- function(p, k, data, lw, arrow = NULL, ...) {
  if (is.null(k$halo) || is.na(k$halo)) return(p)
  p + ggplot2::geom_path(data = data, xy(group = .data$id), colour = k$halo,
                         linewidth = lw + (k$halo_w %||% 0), lineend = "round",
                         linejoin = "round", arrow = arrow, ...)
}
halo_poly <- function(p, k, data, lw) {
  if (is.null(k$halo) || is.na(k$halo)) return(p)
  p + ggplot2::geom_polygon(data = data, xy(group = .data$id), fill = k$halo,
                            colour = k$halo, linewidth = lw + (k$halo_w %||% 0), linejoin = "round")
}

## Can the device the plot will be printed on see systemfonts-registered
## variants? The open device decides; with none open, the one R would open
## (getOption("device"): "RStudioGD", or a ragg/svglite/httpgd function).
ragg_device <- function() {
  dev <- names(grDevices::dev.cur())
  if (dev == "null device") {
    o <- getOption("device")
    dev <- if (is.character(o)) o else if (is.function(o)) environmentName(environment(o)) else ""
  }
  grepl("^(agg|ragg|RStudioGD|devSVG|svglite|httpgd)", dev)
}

## First installed family of FONT_CHAIN. pdf()/postscript() only know their own
## font tables (Latin-1), so an open one of those gets "sans" and ASCII glyphs,
## as does a non-UTF-8 locale, and so does a plot built with no device open
## unless the default device is ragg-capable (`ragg`).
diagram_fonts <- function(ragg = ragg_device()) {
  sf <- requireNamespace("systemfonts", quietly = TRUE)
  ps <- !ragg && names(grDevices::dev.cur()) %in% c("pdf", "postscript", "null device")
  utf8 <- isTRUE(l10n_info()[["UTF-8"]])
  fam <- "sans"
  if (sf && !ps) {
    have <- intersect(FONT_CHAIN, systemfonts::system_fonts()$family)
    if (length(have)) fam <- have[[1]]
  }
  # metrics only for a real family, and only if freetype can read it
  sf <- sf && fam != "sans" &&
    !inherits(try(systemfonts::string_width("x", family = fam), silent = TRUE), "try-error")
  list(fam = fam, sf = sf,
       minus = if (utf8 && !ps) "\u2212" else "-",
       dot = if (utf8) " \u00b7 " else " - ")
}

## Register the palette's text weights as font variants (ragg/systemfonts only);
## k$fam_r / k$fam_c are the families for plain and constant text. Base devices
## (png(), quartz(), knitr's default) cannot see registered variants, so those
## keep the regular weight.
font_weights <- function(k, ragg = ragg_device()) {
  k$fam_r <- k$fam_c <- k$fam
  if (!k$sf || !ragg) return(k)
  reg <- function(w) { if (is.null(w) || w == "normal") return(k$fam)
    nm <- paste0("tidysd_", k$fam, "_", w)
    systemfonts::register_variant(nm, k$fam, weight = w); nm }
  k$fam_r <- reg(k$font_w); k$fam_c <- reg(k$font_w_const %||% k$font_w)
  k
}

## Width (data units) of the widest line of each label.
text_w <- function(lab, k, size = FONT) {
  size <- size + (k$txt_up %||% 0)
  ls <- strsplit(lab, "\n", fixed = TRUE); sz <- rep_len(size, length(ls))
  # note: the metrics branch passes the whole `size` vector (recycled by
  # systemfonts); kept as is because the released look depends on it
  vapply(seq_along(ls), function(i) max(
    if (k$sf) systemfonts::string_width(ls[[i]], family = k$fam_r %||% k$fam, size = size * ggplot2::.pt,
                                        res = 72) / 72 / UNIT_IN
    else nchar(ls[[i]]) * CHAR_W * sz[i] / FONT), 1)
}

## Greedy wrap at spaces, underscores and CamelCase joins (the join itself is
## dropped, so "TotalCumulativeSales" becomes "TotalCumulative\nSales").
wrap_label <- function(x, width = 14) unname(mapply(function(s, width) {
  s <- gsub("([a-z0-9])([A-Z])", "\\1\r\\2", gsub("_", " ", s))
  tok <- regmatches(s, gregexpr("[^ \r]+[ \r]?", s))[[1]]
  out <- character(); cur <- ""
  for (t in tok) if (nzchar(cur) && nchar(trimws(paste0(cur, t))) > width) {
    out <- c(out, cur); cur <- t } else cur <- paste0(cur, t)
  paste(gsub("\r", "", trimws(c(out, cur))), collapse = "\n")
}, x, width))

label_box <- function(lab, k, pad_w = 0.2, pad_h = 0.14, size = FONT)
  list(w = text_w(lab, k, size) + pad_w,
       h = lengths(strsplit(lab, "\n", fixed = TRUE)) * LINE_H * (size + (k$txt_up %||% 0)) / FONT + pad_h)

## ---- geometry helpers -------------------------------------------------------------

bez3 <- function(p0, c1, c2, p1, n = 80) {
  t <- seq(0, 1, length.out = n); u <- 1 - t
  cbind(x = u^3 * p0[1] + 3 * u^2 * t * c1[1] + 3 * u * t^2 * c2[1] + t^3 * p1[1],
        y = u^3 * p0[2] + 3 * u^2 * t * c1[2] + 3 * u * t^2 * c2[2] + t^3 * p1[2])
}

## uniform Catmull-Rom spline through the rows of P
crom <- function(P, n = 30) {
  Q <- rbind(P[1, ], P, P[nrow(P), ])
  do.call(rbind, lapply(2:(nrow(Q) - 2), function(i) bez3(Q[i, ], Q[i, ] + (Q[i + 1, ] - Q[i - 1, ]) / 6,
                                                         Q[i + 1, ] - (Q[i + 2, ] - Q[i, ]) / 6, Q[i + 1, ], n)))
}

inside <- function(pts, box, pad = 0.07)
  abs(pts[, 1] - box$x) <= box$w / 2 + pad & abs(pts[, 2] - box$y) <= box$h / 2 + pad

## rows of `bx` that the polyline enters, in the order it enters them
box_first <- function(pts, bx, pad = 0) {
  if (!NROW(bx) || !nrow(pts)) return(integer())
  hw <- bx$w / 2 + pad; hh <- bx$h / 2 + pad; xr <- range(pts[, 1]); yr <- range(pts[, 2])
  hit <- which(bx$x + hw >= xr[1] & bx$x - hw <= xr[2] & bx$y + hh >= yr[1] & bx$y - hh <= yr[2])
  if (!length(hit)) return(integer())   # boxes off the curve's bounding box cannot be hit
  n <- nrow(pts)
  m <- abs(outer(pts[, 1], bx$x[hit], "-")) <= rep(hw[hit], each = n) &
    abs(outer(pts[, 2], bx$y[hit], "-")) <= rep(hh[hit], each = n)
  k <- which(colSums(m) > 0)
  hit[k][order(apply(m[, k, drop = FALSE], 2, which.max))]
}
box_hits <- function(pts, bx, pad = 0) length(box_first(pts, bx, pad))

## which segments A[i, ] -> B[i, ] miss every box (Liang-Barsky clipping)
seg_clear <- function(A, B, bx, pad) {
  ok <- rep(TRUE, nrow(A)); D <- B - A; D[abs(D) < 1e-9] <- 1e-9
  for (j in seq_len(nrow(bx))) {
    tx <- cbind(bx$x[j] - bx$w[j] / 2 - pad - A[, 1], bx$x[j] + bx$w[j] / 2 + pad - A[, 1]) / D[, 1]
    ty <- cbind(bx$y[j] - bx$h[j] / 2 - pad - A[, 2], bx$y[j] + bx$h[j] / 2 + pad - A[, 2]) / D[, 2]
    lo <- pmax(pmin(tx[, 1], tx[, 2]), pmin(ty[, 1], ty[, 2]), 0)
    hi <- pmin(pmax(tx[, 1], tx[, 2]), pmax(ty[, 1], ty[, 2]), 1)
    ok <- ok & lo >= hi
  }
  ok
}

## Shortest route between the centres of boxes `a` and `b` over the visibility
## graph of the padded corners of the other boxes; `G` caches corner-to-corner
## visibility for one set of boxes. Returns the waypoints, or NULL.
vis_route <- function(a, b, obs, G) {
  V <- rbind(c(a$x, a$y), c(b$x, b$y), G$V); n <- nrow(V)
  W <- matrix(Inf, n, n); W[-(1:2), -(1:2)] <- G$W
  e <- function(from, skip) {   # edges out of an endpoint, ignoring its own box
    k <- seq_len(n)[-from]
    ok <- seg_clear(V[rep(from, length(k)), , drop = FALSE], V[k, , drop = FALSE],
                    obs[!obs$name %in% skip, ], 0.15)
    W[from, k[ok]] <<- W[k[ok], from] <<- sqrt(rowSums((V[k[ok], , drop = FALSE] -
                                                        V[rep(from, sum(ok)), , drop = FALSE])^2))
  }
  e(1, c(a$name, b$name)); e(2, c(a$name, b$name))
  dist <- rep(Inf, n); prev <- integer(n); dist[1] <- 0; open <- rep(TRUE, n)
  repeat {                                  # Dijkstra, dense
    u <- which(open)[which.min(dist[open])]
    if (!length(u) || !is.finite(dist[u]) || u == 2) break
    open[u] <- FALSE; nd <- dist[u] + W[u, ]; up <- open & nd < dist
    dist[up] <- nd[up]; prev[up] <- u
  }
  if (!is.finite(dist[2])) return(NULL)
  path <- 2; while (path[1] != 1) path <- c(prev[path[1]], path)
  V[path, , drop = FALSE]
}

vis_graph <- function(bx, pad = 0.35) {
  n <- nrow(bx)
  V <- cbind(rep(bx$x, 4) + rep(c(-1, 1, -1, 1), each = n) * (bx$w / 2 + pad),
             rep(bx$y, 4) + rep(c(1, 1, -1, -1), each = n) * (bx$h / 2 + pad))
  V <- V[vapply(seq_len(nrow(V)), function(i) !length(box_first(V[i, , drop = FALSE], bx, 0.2)), TRUE), ,
         drop = FALSE]
  m <- nrow(V); W <- matrix(Inf, m, m)
  if (m > 1) {
    ij <- which(upper.tri(W), arr.ind = TRUE)
    ok <- seg_clear(V[ij[, 1], , drop = FALSE], V[ij[, 2], , drop = FALSE], bx, 0.15)
    W[ij[ok, , drop = FALSE]] <- sqrt(rowSums((V[ij[ok, 1], , drop = FALSE] - V[ij[ok, 2], , drop = FALSE])^2))
    W[ij[ok, 2:1, drop = FALSE]] <- W[ij[ok, , drop = FALSE]]
  }
  list(V = V, W = W)
}

## polyline -> segment matrix (x1, y1, x2, y2), every `by`-th point
segs <- function(pts, by = 1) {
  pts <- pts[unique(c(seq(1, nrow(pts), by), nrow(pts))), , drop = FALSE]
  n <- nrow(pts); cbind(pts[-n, 1], pts[-n, 2], pts[-1, 1], pts[-1, 2])
}

## proper crossings between two segment sets
n_cross <- function(A, B) {
  if (!NROW(A) || !NROW(B)) return(0)
  if (max(A[, c(1, 3)]) < min(B[, c(1, 3)]) || max(B[, c(1, 3)]) < min(A[, c(1, 3)]) ||
      max(A[, c(2, 4)]) < min(B[, c(2, 4)]) || max(B[, c(2, 4)]) < min(A[, c(2, 4)])) return(0)
  o <- function(P, cx, cy)   # side of each point (cx, cy) of each segment of P
    (P[, 3] - P[, 1]) * outer(-P[, 2], cy, "+") - (P[, 4] - P[, 2]) * outer(-P[, 1], cx, "+")
  o1 <- o(A, B[, 1], B[, 2]); o2 <- o(A, B[, 3], B[, 4])
  o3 <- t(o(B, A[, 1], A[, 2])); o4 <- t(o(B, A[, 3], A[, 4]))
  sum(o1 * o2 < 0 & o3 * o4 < 0)
}

## Keep the stretch of the curve between leaving the source and entering the
## target, so arrowheads land on box edges instead of under the box.
clip_curve <- function(pts, from, to) {
  out_from <- which(!inside(pts, from)); out_to <- which(!inside(pts, to))
  if (!length(out_from) || !length(out_to)) return(NULL)
  i0 <- min(out_from)
  i1 <- max(out_to[out_to >= i0], i0)
  if (i1 - i0 < 2) return(NULL)
  pts[i0:i1, , drop = FALSE]
}

cloud_poly <- function(x, y, r = 0.26, id) {
  th <- seq(0, 2 * pi, length.out = 120)
  rr <- r * (0.82 + 0.25 * abs(sin(3.5 * th)))
  data.frame(x = x + rr * cos(th), y = y + 0.75 * rr * sin(th), id = id)
}

arrow_head <- function(tip, dir, len = 0.26, wid = 0.3, id) {
  dir <- dir / sqrt(sum(dir^2)); nrm <- c(-dir[2], dir[1])
  base <- tip - len * dir
  data.frame(x = c(tip[1], base[1] + nrm[1] * wid / 2, base[1] - nrm[1] * wid / 2),
             y = c(tip[2], base[2] + nrm[2] * wid / 2, base[2] - nrm[2] * wid / 2),
             id = id)
}

## ---- SFD layout -------------------------------------------------------------------

layout_sfd <- function(d, k, initials = NULL) {
  nd <- as.data.frame(d$nodes, stringsAsFactors = FALSE)
  ed <- as.data.frame(d$edges, stringsAsFactors = FALSE)
  st <- nd$type == "stock"
  nd$label <- wrap_label(nd$name, ifelse(st, 16, 14))
  bx <- label_box(nd$label, k)
  nd$w <- bx$w; nd$h <- bx$h
  sb <- label_box(nd$label[st], k, size = FONT + 1.3)   # stock text is larger
  nd$w[st] <- pmax(1.55, sb$w + 0.4); nd$h[st] <- pmax(1.05, sb$h + 0.6)
  s0 <- st & nd$name %in% names(initials)     # room for the "starts at" chip
  nd$w[s0] <- pmax(nd$w[s0], text_w(chip_lab(initials, nd$name[s0]), k, FONT - 0.6) + 0.6)
  nd$x <- NA_real_; nd$y <- NA_real_; nd$row <- NA_integer_
  rownames(nd) <- nd$name

  flows <- nd$name[nd$type == "flow"]
  src <- stats::setNames(rep(NA_character_, length(flows)), flows); dst <- src
  for (i in which(ed$kind == "outflow")) src[ed$to[i]] <- ed$from[i]
  for (i in which(ed$kind == "inflow"))  dst[ed$from[i]] <- ed$to[i]
  stocks <- nd$name[st]

  # material components (union-find over stock-to-stock flows)
  comp <- stats::setNames(seq_along(stocks), stocks)
  find <- function(s) { while (comp[[s]] != match(s, stocks)) s <- stocks[comp[[s]]]; s }
  for (f in flows) if (!is.na(src[f]) && !is.na(dst[f])) {
    a <- find(src[f]); b <- find(dst[f]); if (a != b) comp[b] <- match(a, stocks)
  }
  roots <- vapply(stocks, find, "")
  groups <- split(stocks, factor(roots, unique(roots)))
  groups <- groups[order(-lengths(groups))]

  clouds <- list()
  GAP <- 1.0; ROW_H <- 6.5

  for (g in seq_along(groups)) {
    y0 <- -(g - 1) * ROW_H
    ss <- groups[[g]]
    # DFS order following stock -> stock flows
    kids <- function(s) unname(dst[flows[!is.na(src[flows]) & src[flows] == s &
                                     !is.na(dst[flows]) & dst[flows] %in% ss]])
    has_parent <- vapply(ss, function(s) any(!is.na(dst[flows]) & dst[flows] == s &
                                               !is.na(src[flows]) & src[flows] %in% ss), TRUE)
    order_s <- character()
    visit <- function(s) { if (s %in% order_s) return(); order_s <<- c(order_s, s)
                           for (kk in kids(s)) visit(kk) }
    for (s in c(ss[!has_parent], ss)) visit(s)

    cursor <- 0; prev <- NULL
    for (s in order_s) {
      sw <- nd[s, "w"]
      inline <- if (!is.null(prev)) flows[!is.na(src[flows]) & src[flows] == prev &
                                            !is.na(dst[flows]) & dst[flows] == s][1] else NA
      srcs <- flows[is.na(src[flows]) & !is.na(dst[flows]) & dst[flows] == s]
      if (!is.na(inline)) {
        fw <- max(0.5, nd[inline, "w"])
        vx <- cursor + GAP + fw / 2
        nd[inline, c("x", "y")] <- c(vx, y0)
        cursor <- vx + fw / 2 + GAP
      } else if (length(srcs)) {
        f <- srcs[1]; fw <- max(0.5, nd[f, "w"])
        cx <- cursor + (if (is.null(prev)) 0 else GAP) + 0.3
        clouds[[length(clouds) + 1]] <- c(cx, y0, g)
        nd[f, c("x", "y")] <- c(cx + 0.3 + GAP * 0.6 + fw / 2, y0)
        cursor <- nd[f, "x"] + fw / 2 + GAP * 0.6
        srcs <- srcs[-1]
      } else if (!is.null(prev)) cursor <- cursor + 2 * GAP
      nd[s, c("x", "y")] <- c(cursor + sw / 2, y0)
      nd[s, "row"] <- g
      cursor <- cursor + sw
      # extra boundary inflows come down from above
      for (i in seq_along(srcs)) {
        f <- srcs[i]; fx <- nd[s, "x"] + (i - (length(srcs) + 1) / 2) * 0.5
        nd[f, c("x", "y")] <- c(fx, y0 + 1.25)
        clouds[[length(clouds) + 1]] <- c(fx, y0 + 2.1, g)
      }
      prev <- s
    }
    # sinks: first goes out to the right if the stock ends the row, else down
    for (s in order_s) {
      sinks <- flows[!is.na(src[flows]) & src[flows] == s & is.na(dst[flows])]
      last <- s == utils::tail(order_s, 1)
      for (i in seq_along(sinks)) {
        f <- sinks[i]; fw <- max(0.5, nd[f, "w"])
        if (last && i == 1) {
          vx <- nd[s, "x"] + nd[s, "w"] / 2 + GAP * 0.6 + fw / 2
          nd[f, c("x", "y")] <- c(vx, y0)
          clouds[[length(clouds) + 1]] <- c(vx + fw / 2 + GAP * 0.6 + 0.3, y0, g)
        } else {
          fx <- nd[s, "x"] + (i - (length(sinks) + !last) / 2 - 0.5) * 0.5
          nd[f, c("x", "y")] <- c(fx, y0 - 1.25)
          clouds[[length(clouds) + 1]] <- c(fx, y0 - 2.1, g)
        }
      }
    }
    nd[c(order_s, flows[src[flows] %in% order_s | dst[flows] %in% order_s]), "row"] <- g
  }
  # flows with no stock at all: cloud -> valve -> cloud on a row of their own
  lone <- flows[is.na(nd[flows, "x"])]
  for (i in seq_along(lone)) {
    g <- length(groups) + i; y0 <- -(g - 1) * ROW_H
    nd[lone[i], c("x", "y", "row")] <- c(1.2, y0, g)
    clouds[[length(clouds) + 1]] <- c(0, y0, g); clouds[[length(clouds) + 1]] <- c(2.4, y0, g)
  }

  # pack chains into shelves: short chains share a row instead of stacking
  ng <- length(groups) + length(lone)
  if (ng > 1) {
    cm <- do.call(rbind, clouds); mat <- !is.na(nd$row)
    ext <- t(vapply(seq_len(ng), function(g) {
      xs <- c(nd$x[mat & nd$row == g], cm[cm[, 3] == g, 1]); range(xs) + c(-0.6, 0.6) }, c(0, 0)))
    W <- max(16, ext[, 2] - ext[, 1]); shelf <- 1; cur <- 0; dx <- numeric(ng); newrow <- integer(ng)
    for (g in seq_len(ng)) {
      w <- ext[g, 2] - ext[g, 1]
      if (cur > 0 && cur + w > W) { shelf <- shelf + 1; cur <- 0 }
      dx[g] <- cur - ext[g, 1]; newrow[g] <- shelf; cur <- cur + w + 1.2
    }
    g0 <- nd$row[mat]
    nd$x[mat] <- nd$x[mat] + dx[g0]
    nd$y[mat] <- nd$y[mat] + (g0 - newrow[g0]) * ROW_H
    nd$row[mat] <- newrow[g0]
    for (i in seq_along(clouds)) { g <- clouds[[i]][3]
      clouds[[i]] <- c(clouds[[i]][1] + dx[g], clouds[[i]][2] + (g - newrow[g]) * ROW_H, newrow[g]) }
  }

  # pipes: geometry from endpoints now that everything material is placed
  pipe_list <- list()
  end_pt <- function(s, toward) {         # point on stock edge facing `toward`
    b <- nd[s, ]
    if (abs(toward[2] - b$y) < 1e-6) c(b$x + sign(toward[1] - b$x) * b$w / 2, b$y)
    else c(toward[1], b$y + sign(toward[2] - b$y) * b$h / 2)
  }
  cloud_near <- function(p) { cc <- do.call(rbind, clouds)
    cc[which.min((cc[, 1] - p[1])^2 + (cc[, 2] - p[2])^2), 1:2] }
  for (f in flows) {
    v <- unlist(nd[f, c("x", "y")])
    a <- if (!is.na(src[f])) end_pt(src[f], v) else cloud_near(v)
    b <- if (!is.na(dst[f])) end_pt(dst[f], v) else cloud_near(v)
    back <- !is.na(src[f]) && !is.na(dst[f]) &&
      (nd[dst[f], "x"] < nd[src[f], "x"] || abs(nd[dst[f], "y"] - nd[src[f], "y"]) > 1e-6 ||
         abs(v[2] - nd[src[f], "y"]) > 1e-6)
    if (back) {   # route under the row: down, across, up
      s0 <- nd[src[f], ]; t0 <- nd[dst[f], ]
      yb <- min(s0$y - s0$h / 2, t0$y - t0$h / 2) - 1.0
      path <- rbind(c(s0$x, s0$y - s0$h / 2), c(s0$x, yb), c(t0$x, yb), c(t0$x, t0$y - t0$h / 2))
      nd[f, c("x", "y")] <- c((s0$x + t0$x) / 2, yb)
    } else path <- rbind(a, b)
    pipe_list[[f]] <- list(path = path, into_stock = !is.na(dst[f]))
  }

  # flow labels sit under the valve, or beside it on a vertical pipe
  fl <- flows[!is.na(nd[flows, "x"])]
  vert <- vapply(fl, function(f) { pa <- pipe_list[[f]]$path
    nrow(pa) == 2 && abs(pa[2, 1] - pa[1, 1]) < 1e-6 }, TRUE)
  nd$lx <- nd$x; nd$ly <- nd$y
  nd[fl, "lx"] <- nd[fl, "x"] + ifelse(vert, 0.3 + nd[fl, "w"] / 2, 0)
  nd[fl, "ly"] <- nd[fl, "y"] - ifelse(vert, 0, 0.42 + nd[fl, "h"] / 2 - 0.02)
  flat <- fl[vapply(fl, function(f) { pa <- pipe_list[[f]]$path
    nrow(pa) == 2 && abs(pa[2, 2] - pa[1, 2]) < 1e-6 }, TRUE)]
  if (isTRUE(k$flow_above)) nd[flat, "ly"] <- nd[flat, "y"] + 0.3
  nd$flat <- nd$name %in% flat
  cm <- if (length(clouds)) do.call(rbind, clouds)
  fixed <- sfd_boxes(nd[nd$type %in% c("stock", "flow"), ], cm)

  # ---- non-material nodes: each goes to the lane (a horizontal band above,
  # between or below the material rows) nearest the barycentre of its
  # material neighbours (else one lane beyond its variable neighbours), at the
  # mean x of all its neighbours; overlaps are then pushed apart along the lane
  info <- ed[ed$kind == "information", ]
  other <- nd$name[!nd$type %in% c("stock", "flow")]
  nbrs <- function(n) unique(c(info$to[info$from == n], info$from[info$to == n]))
  lanes <- NULL
  if (any(st)) {
    yr <- -(seq_len(max(nd$row, na.rm = TRUE)) - 1) * ROW_H; nr <- length(yr)
    lanes <- sort(c(yr[1] + 3, yr + 1.75, yr - 1.75, yr[-nr] - ROW_H / 2, yr[nr] - 3))
    nd[other, "y"] <- yr[1] + 1.75
  } else {          # no stock-flow spine: layer by longest path from the sources
    dep <- stats::setNames(rep(0, length(other)), other)
    for (it in seq_along(other)) for (i in seq_len(nrow(info)))
      dep[info$to[i]] <- max(dep[info$to[i]], dep[info$from[i]] + 1)
    nd[other, "y"] <- dep * 1.6
  }
  mean_x <- mean(nd$x, na.rm = TRUE); if (is.na(mean_x)) mean_x <- 0
  nd[other, "x"] <- mean_x
  for (it in 1:30) {
    for (n in other) {
      nb <- nbrs(n); if (!length(nb)) next
      nd[n, "x"] <- mean(nd[nb, "x"])
      if (is.null(lanes) || it > 20) next   # lanes freeze before x settles
      m <- nb[nd[nb, "type"] %in% c("stock", "flow")]   # material neighbours decide
      i <- which.min(abs(lanes - mean(nd[if (length(m)) m else nb, "y"])) - 1e-6 * lanes)
      if (!length(m))   # only variables around: one lane further out from the rows
        i <- min(max(i + if (lanes[i] > yr[which.min(abs(yr - lanes[i]))]) 1 else -1, 1), length(lanes))
      nd[n, "y"] <- lanes[i]
    }
    nd <- spread_bands(nd, other, nd[other, "y"], if (it > 20) fixed)
  }
  chan <- sort(unique(c(lanes, if (any(st)) yr)))
  chan <- c(chan, (chan[-1] + chan[-length(chan)]) / 2)   # lanes and the gaps between
  list(nodes = nd, info = info, pipes = pipe_list, clouds = cm,
       boxes = sfd_boxes(nd, cm), chan = chan, lanes = lanes)
}

## Post-placement repair: route the links, then try small moves of the
## variables (never stocks or flows) that touch a bad link (enters a node,
## touches a pipe, crosses another link, or detours), re-routing just the
## links a move affects. A move is kept when it improves (nodes hit, pipes
## touched, crossings, length) lexicographically; constants that feed only the
## moved node move along with it; each unit gained may cost at
## most `len_per_cross` extra length (2.5x that for a node hit). The re-
## routed links are used as they are (each move only ever improved the score).
## ponytail: first-improvement hill climb under an evaluation budget; a real
## crossing-minimising placement if dense models still tangle.
repair_sfd <- function(L, soft, rounds = 4, len_per_cross = 4) {
  info <- L$info; bx <- L$boxes
  ip0 <- ip <- route_links(bx, info, L$chan, soft = soft)
  if (!nrow(info)) return(list(L = L, ip = ip0))
  score <- function(res, bx) {
    q <- link_quality(lapply(res, `[[`, "pts"), bx, info, soft)
    q$v <- c(sum(q$node), sum(q$pipe), q$link, sum(q$len)); q }
  better <- function(a, b) {        # is score a an improvement on b?
    d <- a - b; k <- which(d[1:3] != 0)[1]
    if (is.na(k)) return(d[4] < -0.5)
    d[k] < 0 && d[4] <= -len_per_cross * c(2.5, 1, 1)[k] * d[k]   # capped stretch
  }
  q0 <- q <- score(ip$res, bx)
  mov <- L$nodes$name[!L$nodes$type %in% c("stock", "flow")]
  budget <- min(16, 4 + nrow(info) %/% 3); moved <- FALSE   # budget: route evaluations
  for (r in seq_len(rounds)) {
    bad <- which(q$node > 0 | q$pipe > 0 | q$len > 1.6 * q$dist + 2 |
                   seq_along(q$len) %in% q$xp)
    who <- c(info$from[bad], info$to[bad])
    who <- who[who %in% mov]
    if (!length(who) || budget <= 0) break
    tab <- table(factor(who, unique(who))); who <- names(tab)[order(-tab)]
    improved <- FALSE
    for (n in who) {
      b <- bx[n, ]
      nb <- c(info$to[info$from == n], info$from[info$to == n])
      # variables hanging off n alone (its constants) travel with it
      leaf <- nb[nb %in% mov & vapply(nb, function(v) all(c(info$to[info$from == v],
                                                             info$from[info$to == v]) == n), TRUE)]
      g <- c(n, unique(leaf)); oth <- bx[!rownames(bx) %in% g, ]
      near <- oth[abs(oth$y - b$y) < 1.5 & abs(oth$x - b$x) < 5, ]
      mat <- nb[L$nodes[nb, "type"] %in% c("stock", "flow")]
      cand <- data.frame(x = c(mean(bx[nb, "x"]), mean(bx[mat, "x"]),
                               near$x - (near$w + b$w) / 2 - 0.5, near$x + (near$w + b$w) / 2 + 0.5,
                               b$x + c(-1, 1, -2, 2, -3, 3)), y = b$y)
      li <- which.min(abs(L$lanes - b$y))
      for (l in intersect(li + c(-1, 1), seq_along(L$lanes)))
        cand <- rbind(cand, data.frame(x = c(b$x, mean(bx[nb, "x"])), y = L$lanes[l]))
      cand$dx <- cand$x - b$x; cand$dy <- cand$y - b$y
      ok <- vapply(seq_len(nrow(cand)), function(j) {
        if (is.na(cand$dx[j]) || (abs(cand$dx[j]) < 0.3 && !cand$dy[j])) return(FALSE)
        m <- bx[g, ]; m$x <- m$x + cand$dx[j]; m$y[1] <- m$y[1] + cand$dy[j]
        !any(abs(outer(oth$x, m$x, "-")) < outer(oth$w, m$w, "+") / 2 + 0.4 &
               abs(outer(oth$y, m$y, "-")) < outer(oth$h, m$h, "+") / 2 + 0.3) }, TRUE)
      cand <- cand[ok, ]; cand <- utils::head(cand[!duplicated(round(cand[, 1:2], 1)), ], 5)
      for (j in seq_len(nrow(cand))) {
        if (budget <= 0) break
        budget <- budget - 1
        bx2 <- bx; bx2[g, "x"] <- bx2[g, "x"] + cand$dx[j]; bx2[n, "y"] <- cand$y[j]
        hit <- vapply(ip$res, function(z) !is.null(z) && box_hits(z$pts, bx2[g, ], 0.08) > 0, TRUE)
        redo <- which(info$from %in% g | info$to %in% g | hit)
        ip2 <- route_links(bx2, info, L$chan, soft = soft, keep = ip$res, redo = redo)
        q2 <- score(ip2$res, bx2)
        if (better(q2$v, q$v)) { bx <- bx2; ip <- ip2; q <- q2; moved <- improved <- TRUE; break }
      }
    }
    if (!improved) break
  }
  if (!moved) return(list(L = L, ip = ip0))
  m <- intersect(mov, rownames(bx))
  L$nodes[m, c("x", "y")] <- bx[m, c("x", "y")]; L$boxes <- bx
  list(L = L, ip = ip)
}

## Drawn extent of every node, flow label (`lab`) and cloud, as boxes. A flow's
## own row is its valve; links end there and go around its label.
sfd_boxes <- function(nd, cm = NULL) {
  pad <- c(stock = 0, flow = 0, constant = 0.06)[nd$type]; pad[is.na(pad)] <- 0.14
  f <- nd$type == "flow"
  b <- data.frame(name = nd$name, x = nd$x, y = nd$y, w = ifelse(f, 0.5, nd$w + pad),
                  h = ifelse(f, 0.5, nd$h + ifelse(nd$type == "constant", -0.02, 0.02) *
                               (nd$type != "stock")), lab = f & FALSE)
  b <- rbind(b, data.frame(name = nd$name[f], x = nd$lx[f], y = nd$ly[f], w = nd$w[f] + 0.16,
                           h = nd$h[f] - 0.02, lab = rep(TRUE, sum(f))))
  if (!is.null(cm)) b <- rbind(b, data.frame(name = "", x = cm[, 1], y = cm[, 2], w = 0.6,
                                             h = 0.45, lab = FALSE))
  rownames(b) <- make.unique(as.character(ifelse(nzchar(b$name), b$name, "cloud")))
  b
}

## Remove overlaps within each lane, preserving order and centre of mass, then
## step clear of any fixed (material) box that shares the lane.
spread_bands <- function(nd, who, key, fixed = NULL, gap = 0.5) {
  for (b in unique(key)) {
    ids <- who[key == b]; ids <- ids[order(nd[ids, "x"])]
    w <- nd[ids, "w"] + 0.14; want <- nd[ids, "x"]
    x <- pack(want, w, NULL, gap); x <- x - mean(x) + mean(want)
    if (!is.null(fixed)) {
      f <- fixed[abs(fixed$y - b) < fixed$h / 2 + max(nd[ids, "h"]) / 2 + 0.1, ]
      x <- pack(x, w, f, gap)
    }
    nd[ids, "x"] <- x
  }
  nd
}

pack <- function(x, w, f, gap) {
  for (i in seq_along(x)) {
    lo <- if (i > 1) x[i - 1] + (w[i - 1] + w[i]) / 2 + gap else -Inf
    x[i] <- max(x[i], lo)
    for (it in seq_len(if (is.null(f)) 0 else 10)) {
      hit <- abs(f$x - x[i]) < (f$w + w[i]) / 2 + gap / 2
      if (!any(hit)) break
      r <- max(f$x[hit] + f$w[hit] / 2) + w[i] / 2 + gap / 2
      l <- min(f$x[hit] - f$w[hit] / 2) - w[i] / 2 - gap / 2
      x[i] <- if (l >= lo && x[i] - l < r - x[i]) l else r
    }
  }
  x
}

## ---- CLD layout -------------------------------------------------------------------

## Elementary cycles as node vectors, each starting at its smallest node.
find_cycles <- function(ed, max_n = 50) {
  adj <- split(ed$to, ed$from); out <- list()
  nodes <- sort(unique(c(ed$from, ed$to)), method = "radix")  # C collation: same in every locale
  rk <- stats::setNames(seq_along(nodes), nodes)
  for (s in nodes) {                      # cycles whose smallest node is s
    stack <- list(list(s, s))
    while (length(stack) && length(out) < max_n) {
      top <- stack[[length(stack)]]; stack[[length(stack)]] <- NULL
      for (nx in adj[[top[[1]]]]) {
        if (nx == s) out[[length(out) + 1]] <- top[[2]]
        else if (rk[[nx]] > rk[[s]] && !nx %in% top[[2]]) stack[[length(stack) + 1]] <- list(nx, c(top[[2]], nx))
      }
    }
  }
  out   # ponytail: exhaustive DFS, capped at max_n; Johnson's algorithm if models get dense
}

## Loops of a CLD edge list, longest first, with polarity R / B / L (unknown).
cld_loops <- function(ed) {
  cyc <- find_cycles(ed)
  cyc <- cyc[order(-lengths(cyc))]
  pair <- paste(ed$from, ed$to)
  edges <- lapply(cyc, function(cy) match(paste(cy, c(cy[-1], cy[1])), pair))
  pol <- vapply(edges, function(e) { s <- ed$sign[e]
    if (anyNA(s)) "L" else if (sum(s == "-") %% 2) "B" else "R" }, "")
  list(cycles = cyc, edges = edges, pol = pol)
}

## Circular order cost: chord crossings dominate, then total circular edge span
## (so loops sit on consecutive positions and ride the rim).
circ_cost <- function(ord, ed) {
  n <- length(ord); i <- match(ed$from, ord); j <- match(ed$to, ord)
  ok <- !is.na(i) & !is.na(j); i <- i[ok]; j <- j[ok]
  a <- pmin(i, j); b <- pmax(i, j)
  span <- pmin(b - a, n - (b - a))
  cross <- 0
  for (e in seq_along(a)) {
    inn <- (a > a[e] & a < b[e]) != (b > a[e] & b < b[e])
    cross <- cross + sum(inn & a != a[e] & a != b[e] & b != a[e] & b != b[e])
  }
  cross / 2 * 10 + sum(span)
}

untangle <- function(ord, ed) {
  # ponytail: greedy pairwise-swap hill climb, O(n^2 E^2) per pass; fine to ~40 nodes
  best <- circ_cost(ord, ed); improved <- TRUE
  while (improved) {
    improved <- FALSE
    for (i in seq_along(ord)) for (j in seq_along(ord)) if (i < j) {
      o <- ord; o[c(i, j)] <- o[c(j, i)]; cst <- circ_cost(o, ed)
      if (cst < best - 1e-9) { ord <- o; best <- cst; improved <- TRUE }
    }
  }
  ord
}

layout_cld <- function(d, k) {
  nd <- as.data.frame(d$nodes, stringsAsFactors = FALSE)
  ed <- as.data.frame(d$edges, stringsAsFactors = FALSE)
  nd <- nd[nd$type != "constant", ]
  ed <- ed[ed$from %in% nd$name & ed$to %in% nd$name, ]
  nd$label <- wrap_label(nd$name)
  st <- nd$type == "stock"
  bx <- label_box(nd$label, k, size = ifelse(st, FONT + 0.4, FONT)); nd$w <- bx$w; nd$h <- bx$h
  nd$w[st] <- nd$w[st] + 0.2; nd$h[st] <- nd$h[st] + 0.12
  fn <- nd$type == "flow"
  if (isTRUE(k$flow_above)) { nd$w[fn] <- nd$w[fn] + 0.5; nd$h[fn] <- nd$h[fn] + 0.3 }
  rownames(nd) <- nd$name
  loops <- cld_loops(ed)
  ord <- character()
  for (cy in loops$cycles) {
    new <- cy[!cy %in% ord]
    if (!length(new)) next
    if (!length(ord)) { ord <- cy; next }
    # splice the new stretch in after the placed node it follows in the loop
    anchor <- cy[max(which(cy %in% ord & seq_along(cy) < match(new[1], cy)), 0)]
    at <- if (length(anchor)) match(anchor, ord) else length(ord)
    ord <- append(ord, new, after = at)
  }
  rest <- setdiff(nd$name, ord)
  for (n in rest[order(-vapply(rest, function(r) sum(ed$from == r | ed$to == r), 1))]) {
    nb <- intersect(c(ed$to[ed$from == n], ed$from[ed$to == n]), ord)
    ord <- if (length(nb)) append(ord, n, after = match(nb[1], ord) - (n %in% ed$from[ed$to == nb[1]])) else c(ord, n)
  }
  ord <- untangle(ord, ed)
  size <- pmax(nd[ord, "w"], nd[ord, "h"]) + 0.9
  perim <- sum(size)
  R <- max(1.6, perim / (2 * pi))
  ang <- pi / 2 - 2 * pi * (cumsum(size) - size / 2) / perim
  nd[ord, "x"] <- R * cos(ang); nd[ord, "y"] <- R * sin(ang); nd[ord, "ang"] <- ang; nd[ord, "idx"] <- seq_along(ord)
  list(nodes = nd, info = ed, R = R, loops = loops)
}

## Influence links, each a smooth curve between box centres clipped to the two
## box edges. Candidates: straight and bowed chords, elbows leaving and entering
## along each side, U-shapes through each horizontal channel `chan`, and the
## shortest way round the other boxes (visibility graph), as a spline and as a
## polyline; `pref` (a quadratic control point) is tried first. Scored greedily, shortest link
## first, twice over: boxes entered, then `soft` boxes (pipes) touched, then
## crossings with links already routed, then length.
## ponytail: greedy candidate search, not a real router; a visibility-graph
## router if dense models still show crossings.
## `keep` (a previous `$res`) with `redo` re-routes only those links against the
## others as they were, in one pass (used by repair_sfd()).
route_links <- function(bx, info, chan = NULL, pref = NULL, soft = NULL, keep = NULL, redo = NULL) {
  res <- keep %||% vector("list", nrow(info)); lab <- bx[["lab"]] %||% logical(nrow(bx))
  res[redo] <- list(NULL)
  d <- sqrt((bx[info$from, "x"] - bx[info$to, "x"])^2 + (bx[info$from, "y"] - bx[info$to, "y"])^2)
  d[is.na(d)] <- 0
  dirs <- list(c(0, 1), c(0, -1), c(1, 0), c(-1, 0))
  G <- vis_graph(bx)
  todo <- order(d); if (!is.null(redo)) todo <- todo[todo %in% redo]
  for (pass in seq_len(2 - !is.null(redo))) for (i in todo) {
    a <- bx[info$from[i], ]; if (is.na(a$x)) next
    own <- which(bx$name == a$name & !lab)
    done <- do.call(rbind, lapply(res[-i], `[[`, "seg"))
    best <- list(sc = Inf)
    for (ib in which(bx$name == info$to[i])) {   # a flow: its valve, else its label
      b <- bx[ib, ]; if (is.na(b$x)) next
      p0 <- c(a$x, a$y); p1 <- c(b$x, b$y); len <- sqrt(sum((p1 - p0)^2))
      obs <- bx[-c(own, ib), ]
      try_path <- function(full, pen) {
        pts <- clip_curve(full, a, b); if (is.null(pts)) return()
        l <- sum(sqrt(rowSums(diff(pts)^2))) + pen + 1.5 * lab[ib]
        hits <- box_hits(pts, obs, 0.08) + any(inside(pts, a, -0.03)) + any(inside(pts, b, -0.03)) +
          if (!is.null(soft)) box_hits(pts, soft) * 0.015 else 0
        if (1000 * hits + l >= best$sc) return()      # cannot win: skip the crossing count
        sc <- 1000 * hits + 10 * n_cross(segs(pts, 3), done) + l + 300 * (l < 0.3)
        if (sc < best$sc) best <<- list(sc = sc, pts = pts, full = full, seg = segs(pts, 3))
      }
      cb <- function(c1, c2, pen) try_path(bez3(p0, c1, c2, p1), pen)
      q <- function(cc, pen) cb(p0 + 2 / 3 * (cc - p0), p1 + 2 / 3 * (cc - p1), pen)
      nrm <- c(p0[2] - p1[2], p1[1] - p0[1]) / len
      if (!is.null(pref)) q(pref(a, b, info[i, ]), -1)
      for (t in c(0, .15, -.15, .3, -.3, .5, -.5)) q((p0 + p1) / 2 + t * len * nrm, abs(t))
      ext <- function(z, v) abs(v[1]) * z$w / 2 + abs(v[2]) * z$h / 2
      for (d1 in dirs) for (d2 in dirs) for (s in c(0.3, 0.6) * len + 0.4)
        cb(p0 + d1 * (ext(a, d1) + s), p1 + d2 * (ext(b, d2) + s), 0.5)
      for (y in chan) cb(c(p0[1], p0[2] + 4 / 3 * (y - p0[2])), c(p1[1], p1[2] + 4 / 3 * (y - p1[2])), 0.5)
      vr <- vis_route(a, b, obs, G)            # shortest way round, smoothed or not
      if (!is.null(vr)) {
        try_path(crom(vr), 1)
        try_path(do.call(rbind, lapply(seq_len(nrow(vr) - 1), function(j)
          bez3(vr[j, ], vr[j, ], vr[j + 1, ], vr[j + 1, ], 30))), 2)
      }
    }
    res[i] <- list(if (is.finite(best$sc)) best)
  }
  route_draw(res, info)
}

route_draw <- function(res, info) {
  paths <- list(); signs <- list()
  for (i in seq_along(res)) {
    pts <- res[[i]]$pts; if (is.null(pts)) next
    paths[[length(paths) + 1]] <- data.frame(pts, id = i)
    dir <- pts[nrow(pts), ] - pts[max(1, nrow(pts) - 6), ]
    nrm <- c(-dir[2], dir[1]) / sqrt(sum(dir^2))
    j <- max(1, nrow(pts) - 5)
    signs[[length(signs) + 1]] <- data.frame(x = pts[j, 1] + 0.17 * nrm[1],
                                             y = pts[j, 2] + 0.17 * nrm[2], sign = info$sign[i])
  }
  list(paths = if (length(paths)) do.call(rbind, paths),
       signs = if (length(signs)) do.call(rbind, signs),
       full = lapply(res, `[[`, "full"), res = res)
}

## Objective layout score of a rendered diagram: link segments running through
## a node box other than their own two ends, and link-link crossings (ends
## trimmed by 0.2 so links meeting at a shared node do not count).
layout_quality <- function(p) {
  g <- attr(p, "geom")
  if (is.null(g$paths)) return(c(node = 0, link = 0))
  ps <- lapply(split(g$paths[, c("x", "y")], g$paths$id), as.matrix)
  q <- link_quality(ps, g$boxes, g$info[as.integer(names(ps)), ], g$soft)
  c(node = sum(q$node), link = q$link, pipe = sum(q$pipe), length = sum(q$len))
}

## Per-link scores for a list of link polylines `ps` (row i of `info` each):
## nodes entered, pipe (`soft`) boxes touched, length, straight-line distance,
## and the crossing pairs (`xp`, rows i < j) with their total `link`.
link_quality <- function(ps, boxes, info, soft = NULL) {
  bx <- boxes[nzchar(boxes$name), ]; n <- length(ps)
  node <- pipe <- len <- numeric(n)
  sg <- vector("list", n)
  for (i in seq_len(n)) { z <- ps[[i]]; if (is.null(z)) next
    node[i] <- box_hits(z, bx[!bx$name %in% c(info$from[i], info$to[i]), ])
    pipe[i] <- if (!is.null(soft)) box_hits(z, soft) else 0
    len[i] <- sum(sqrt(rowSums(diff(z)^2)))
    keep <- sqrt((z[, 1] - z[1, 1])^2 + (z[, 2] - z[1, 2])^2) > 0.2 &
      sqrt((z[, 1] - z[nrow(z), 1])^2 + (z[, 2] - z[nrow(z), 2])^2) > 0.2
    if (sum(keep) > 1) sg[[i]] <- segs(z[keep, , drop = FALSE]) }
  xp <- matrix(0L, 0, 2); link <- 0
  for (i in seq_len(n)) for (j in seq_len(n)) if (i < j) {
    c0 <- n_cross(sg[[i]], sg[[j]])
    if (c0) { link <- link + c0; xp <- rbind(xp, c(i, j)) }
  }
  list(node = node, pipe = pipe, len = len, link = link, xp = xp,
       dist = sqrt((boxes[info$from, "x"] - boxes[info$to, "x"])^2 +
                     (boxes[info$from, "y"] - boxes[info$to, "y"])^2))
}

## ---- drawing ------------------------------------------------------------------------

xy <- function(...) ggplot2::aes(x = .data$x, y = .data$y, ...)

## rounded-rectangle polygons, one per row. Each corner is a quarter superellipse
## |x|^e + |y|^e = rr^e: e = 2 is a circular arc; e > 2 has zero curvature where it
## meets the straight sides, i.e. Apple's "continuous" corner (squircle).
rrect <- function(x, y, w, h, r, id, n = 10, e = 2) {
  n_ <- length(x); w <- rep_len(w, n_); h <- rep_len(h, n_); y <- rep_len(y, n_)
  r <- rep_len(r, n_); id <- rep_len(id, n_)
  if (e > 2) n <- max(n, 18)
  do.call(rbind, lapply(seq_along(x), function(i) {
    rr <- min(r[i], w[i] / 2, h[i] / 2)
    cx <- x[i] + c(1, -1, -1, 1) * (w[i] / 2 - rr); cy <- y[i] + c(1, 1, -1, -1) * (h[i] / 2 - rr)
    pts <- do.call(rbind, lapply(1:4, function(q) {
      th <- seq((q - 1) * pi / 2, q * pi / 2, length.out = n)
      cs <- cos(th); sn <- sin(th)
      cbind(cx[q] + rr * sign(cs) * abs(cs)^(2 / e), cy[q] + rr * sign(sn) * abs(sn)^(2 / e))
    }))
    data.frame(x = pts[, 1], y = pts[, 2], id = as.character(id[i]))
  }))
}

## card = two soft shadow layers + tinted rounded rect with same-hue hairline
card <- function(p, k, x, y, w, h, r, fill, line, id, lw = 0.45, shadow = TRUE, lty = "solid",
                 adapt = TRUE) {
  if (!length(x)) return(p)
  e <- 2
  if (identical(k$corner, "squircle")) {
    # radius adapts to the box: a share of the short side, capped
    if (adapt) r <- pmin(k$corner_k * pmin(w, h), k$corner_max)
    e <- 5 }
  if (shadow) p <- p +
    ggplot2::geom_polygon(data = rrect(x, y - 0.07, w + 0.1, h + 0.08, r + 0.05, id, e = e),
                          xy(group = .data$id), fill = k$shadow, alpha = 0.035) +
    ggplot2::geom_polygon(data = rrect(x, y - 0.035, w + 0.03, h + 0.02, r + 0.015, id, e = e),
                          xy(group = .data$id), fill = k$shadow, alpha = 0.06)
  df <- rrect(x, y, w, h, r, id, e = e)
  i <- match(df$id, as.character(rep_len(id, length(x))))
  df$fill <- rep_len(fill, length(x))[i]; df$line <- rep_len(line, length(x))[i]
  df$lty <- rep_len(lty, length(x))[i]
  lw <- rep_len(lw, length(x))[i]; df$lw <- lw
  p + ggplot2::geom_polygon(data = df, xy(group = .data$id, fill = I(.data$fill),
                                          colour = I(.data$line), linetype = I(.data$lty),
                                          linewidth = I(.data$lw)))
}

## Text in the palette's weights; `halo` rings it in k$text_halo (16 offset copies,
## ponytail: no halo grob in base ggplot; shadowtext if this ever needs to be exact).
txt <- function(p, k, x, y, label, colour, size = FONT, bold = FALSE, const = FALSE,
                halo = FALSE, ...) {
  size <- size + (k$txt_up %||% 0)
  fam <- if (bold) k$fam else if (const) k$fam_c %||% k$fam else k$fam_r %||% k$fam
  one <- function(p, x, y, colour) p + ggplot2::annotate("text", x = x, y = y, label = label,
    colour = colour, size = size, family = fam, fontface = if (bold) "bold" else "plain",
    lineheight = 0.92, ...)
  if (halo && !is.null(k$text_halo) && !is.na(k$text_halo)) {
    th <- seq(0, 2 * pi, length.out = 25)[-25]; hw <- k$text_halo_w %||% 0.028
    for (a in th) p <- one(p, x + hw * cos(a), y + hw * sin(a), k$text_halo)
  }
  one(p, x, y, colour)
}

## Pipe with a halo, then its outer wall and inner channel.
draw_pipe <- function(p, k, df, lineend = "round") {
  ws <- c(k$pipe_w_out %||% 4.6, k$pipe_w_in %||% 2.7); p <- halo_path(p, k, df, ws[1])
  p + ggplot2::geom_path(data = df, xy(group = .data$id), colour = k$pipe_out,
                         linewidth = ws[1], lineend = lineend, linejoin = "round") +
    ggplot2::geom_path(data = df, xy(group = .data$id), colour = k$pipe_in,
                       linewidth = ws[2], lineend = lineend, linejoin = "round")
}
valve <- function(p, k, x, y, size = 7.2, hub = 2.1, stroke = 1.1) {
  if (!is.null(k$halo) && !is.na(k$halo)) p <- p + ggplot2::annotate("point", x = x, y = y,
    size = size + 1.4, colour = k$halo)
  p + ggplot2::annotate("point", x = x, y = y, shape = 21, size = size, fill = k$valve_fill,
                        colour = k$valve, stroke = stroke) +
    ggplot2::annotate("point", x = x, y = y, size = hub, colour = k$valve)
}
## Horizontal pipe x0..x1 at y, valve at cx, bold haloed name just above it.
flow_glyph <- function(p, k, x0, x1, y, cx, label) {
  p <- draw_pipe(p, k, data.frame(x = c(x0, x1), y = y, id = paste0("fg", x0, y)))
  txt(valve(p, k, cx, y, 6, 1.8, 1), k, cx, y + 0.3, label, k$flow_text, bold = TRUE, halo = TRUE)
}

fmt_num <- function(v) format(v, big.mark = ",", trim = TRUE, drop0trailing = TRUE)

## "starts at" chip text per stock; a vector of starts shows its range
chip_lab <- function(initials, stocks) paste("starts at", vapply(initials[stocks], function(v)
  paste(fmt_num(unique(range(unlist(v)))), collapse = " to "), ""))

draw_nodes <- function(p, k, nd, skip = "flow", initials = NULL, cld = FALSE) {
  st <- nd[nd$type == "stock", ]
  if (nrow(st)) {
    p <- card(p, k, st$x, st$y, st$w, st$h, if (cld) 0.13 else 0.17,
              k$stock_fill, k$stock_line, paste0("s_", st$name), lw = k$stock_lw)
    has0 <- !cld & st$name %in% names(initials)
    p <- txt(p, k, st$x, st$y + ifelse(has0, 0.15, 0), st$label, k$stock_text,
             size = if (cld) FONT + 0.4 else FONT + 1.3, bold = TRUE)
    if (any(has0)) {    # chip under the (possibly wrapped) name
      s0 <- st[has0, ]; lab <- chip_lab(initials, s0$name)
      cw <- text_w(lab, k, FONT - 0.6) + 0.22
      cy <- s0$y + 0.15 - lengths(strsplit(s0$label, "\n")) * LINE_H * (FONT + 1.3) / FONT / 2 - 0.2
      p <- card(p, k, s0$x, cy, cw, 0.25 + 0.07 * (k$txt_up %||% 0), 0.125, k$chip_fill, k$chip_line,
                paste0("c_", s0$name), lw = 0.35, shadow = FALSE)
      p <- txt(p, k, s0$x, cy, lab, k$chip_text, size = FONT - 0.6)
    }
  }
  pill <- nd[!nd$type %in% c("stock", "constant", skip), ]
  for (f in c(TRUE, FALSE)) {
    q <- pill[(pill$type == "flow") == f, ]; if (!nrow(q)) next
    if (f && isTRUE(k$flow_above)) {     # CLD flow node: a short pipe, no card
      for (i in seq_len(nrow(q)))
        p <- flow_glyph(p, k, q$x[i] - q$w[i] / 2, q$x[i] + q$w[i] / 2, q$y[i] - 0.14,
                        q$x[i], q$label[i])
      next
    }
    p <- card(p, k, q$x, q$y, q$w + 0.14, q$h + 0.02, pmin(q$h / 2, 0.17),
              if (f) k$flow_fill else k$aux_fill, if (f) k$flow_line else k$aux_line,
              paste0("p_", q$name), lw = if (f) k$flow_lw else k$aux_lw)
    p <- txt(p, k, q$x, q$y, q$label, if (f) k$flow_text else k$aux_text)
  }
  cn <- nd[nd$type == "constant", ]
  if (nrow(cn)) {
    p <- card(p, k, cn$x, cn$y, cn$w + 0.06, cn$h - 0.02, pmin(cn$h / 2, 0.14), k$const_fill,
              k$const_line, paste0("k_", cn$name), lw = k$const_lw, shadow = FALSE,
              lty = k$const_lty %||% "solid")
    p <- txt(p, k, cn$x, cn$y, cn$label, k$const_text, size = FONT - 0.25, const = TRUE)
  }
  p
}

## legend of mini-glyphs under the diagram, left aligned, wrapping at x_max
legend_rows <- function(p, k, x0, y, x_max, items) {
  x <- x0; right <- x0
  for (it in items) {
    iw <- 0.5 + text_w(it$label, k, FONT - 0.35)
    if (x > x0 && x + iw > x_max) { x <- x0; y <- y - 0.42 }
    p <- it$draw(p, x + 0.2, y)
    p <- txt(p, k, x + 0.5, y, it$label, k$muted, size = FONT - 0.35, hjust = 0)
    right <- max(right, x + iw); x <- x + iw + 0.5
  }
  list(p = p, y = y, right = right)
}

## Frame the drawing. The page stays transparent unless `o$background` is set,
## so the legend and the optional title sit on small opaque panels of their own.
finish <- function(p, k, o, title, subtitle, nd, ip, legend = NULL) {
  xs <- c(nd$x - nd$w / 2, nd$x + nd$w / 2, ip$paths$x)
  ys <- c(nd$y - nd$h / 2, nd$y + nd$h / 2, ip$paths$y)
  xr <- range(xs, na.rm = TRUE) + c(-0.3, 0.3); yr <- range(ys, na.rm = TRUE) + c(-0.3, 0.3)
  if (!isFALSE(o$legend)) {
    if (diff(xr) < 8) xr <- mean(xr) + c(-4, 4)          # small models: give the legend room
    y0 <- yr[1] - 0.55
    lg <- legend_rows(p, k, xr[1] + 0.3, y0, xr[2] - 0.3, legend)   # dry run: extent
    p <- card(p, k, (xr[1] + lg$right + 0.3) / 2, (y0 + lg$y) / 2, lg$right + 0.2 - xr[1],
              y0 - lg$y + 0.5, 0.18, k$bg, k$rule, "legend", lw = 0.4, shadow = FALSE)
    p <- legend_rows(p, k, xr[1] + 0.3, y0, xr[2] - 0.3, legend)$p
    yr[1] <- lg$y - 0.4
  }
  if (isTRUE(o$title)) {
    y <- yr[2] + 0.65
    p <- card(p, k, mean(xr), y, diff(xr) - 0.2, 0.9, 0.18, k$bg, k$rule, "title",
              lw = 0.4, shadow = FALSE)
    p <- txt(p, k, xr[1] + 0.3, y + 0.14, title, k$ink, size = FONT + 2.2, bold = TRUE, hjust = 0)
    p <- txt(p, k, xr[1] + 0.3, y - 0.2, subtitle, k$muted, size = FONT - 0.2, hjust = 0)
    yr[2] <- y + 0.55
  }
  p <- p + ggplot2::coord_equal(xlim = xr, ylim = yr, expand = FALSE, clip = "off") +
    ggplot2::theme_void(base_family = k$fam) +
    ggplot2::theme(plot.background = ggplot2::element_rect(fill = o$background %||% NA, colour = NA),
                   plot.margin = ggplot2::margin(8, 8, 8, 8))
  attr(p, "size_in") <- c(diff(xr), diff(yr)) * UNIT_IN + 16 / 72
  attr(p, "bg") <- o$background %||% "transparent"
  p
}

leg_card <- function(k, label, fill, line, w = 0.4, h = 0.2, r = 0.1, lw = 0.4, lty = "solid") {
  force(list(fill, line, w, h, r, lw, lty))
  list(label = label, draw = function(p, x, y)
    card(p, k, x, y, w, h, r, fill, line, paste0("lg_", label), lw = lw, shadow = FALSE, lty = lty))
}

leg_sign <- function(k, label, s, fill, colour)
  list(label = label, draw = function(p, x, y)
    txt(p + ggplot2::annotate("point", x = x, y = y, shape = 21, size = 4.2, fill = fill,
                              colour = k$sign_ring %||% k$bg), k, x, y, s, colour, size = FONT + 0.4, bold = TRUE))

render_sfd <- function(d, k, initials = NULL, o = list()) {
  L <- layout_sfd(d, k, initials); nd <- L$nodes
  soft <- do.call(rbind, lapply(L$pipes, function(pp) { pa <- pp$path; n <- nrow(pa)
    data.frame(x = (pa[-1, 1] + pa[-n, 1]) / 2, y = (pa[-1, 2] + pa[-n, 2]) / 2,
               w = abs(diff(pa[, 1])) + 0.24, h = abs(diff(pa[, 2])) + 0.24) }))
  R <- repair_sfd(L, soft); L <- R$L; ip <- R$ip; nd <- L$nodes
  inpipe <- isTRUE(k$flow_above)
  glyph <- if (inpipe) nd$name[nd$flat] else character()   # flows drawn by flow_glyph()
  pipe_ends <- list()
  pipe_df <- do.call(rbind, lapply(names(L$pipes), function(f) {
    pa <- L$pipes[[f]]$path
    if (L$pipes[[f]]$into_stock) {
      n <- nrow(pa); dir <- pa[n, ] - pa[n - 1, ]; pa[n, ] <- pa[n, ] - 0.3 * dir / sqrt(sum(dir^2))
    }
    if (f %in% glyph) { pipe_ends[[f]] <<- pa; return(NULL) }
    data.frame(x = pa[, 1], y = pa[, 2], id = f)
  }))
  heads <- do.call(rbind, lapply(names(L$pipes), function(f) {
    pa <- L$pipes[[f]]$path; if (!L$pipes[[f]]$into_stock) return(NULL)
    n <- nrow(pa); dir <- pa[n, ] - pa[n - 1, ]
    arrow_head(pa[n, ] - 0.03 * dir / sqrt(sum(dir^2)), dir, len = 0.3, wid = 0.34, id = f)
  }))
  fl <- nd[nd$type == "flow", ]
  clouds <- if (!is.null(L$clouds)) do.call(rbind, lapply(seq_len(nrow(L$clouds)), function(i)
    cloud_poly(L$clouds[i, 1], L$clouds[i, 2], r = 0.24, id = i)))
  nd$w[nd$type == "flow"] <- 0.4; nd$h[nd$type == "flow"] <- 0.4

  p <- ggplot2::ggplot()
  if (!is.null(pipe_df)) p <- draw_pipe(p, k, pipe_df)
  if (!is.null(heads)) p <- halo_poly(p, k, heads, 0.6)
  if (!is.null(heads)) p <- p + ggplot2::geom_polygon(data = heads, xy(group = .data$id),
      fill = k$pipe_out, colour = k$pipe_out, linewidth = 0.6, linejoin = "round")
  if (!is.null(ip$paths)) p <- halo_path(p, k, ip$paths, k$link_lw %||% 0.42,
      arrow = ggplot2::arrow(length = ggplot2::unit(0.075, "inches"), type = "closed", angle = 24))
  if (!is.null(ip$paths)) p <- p + ggplot2::geom_path(data = ip$paths, xy(group = .data$id),
      colour = k$info, linewidth = k$link_lw %||% 0.42, lineend = "round",
      arrow = ggplot2::arrow(length = ggplot2::unit(0.075, "inches"), type = "closed", angle = 24))
  if (!is.null(clouds)) p <- halo_poly(p, k, clouds, 0.45)
  if (!is.null(clouds)) p <- p + ggplot2::geom_polygon(data = clouds, xy(group = .data$id),
      fill = k$cloud_fill, colour = k$cloud_line, linewidth = 0.45)
  for (f in glyph) {                 # pipe, valve and name in one piece
    pa <- pipe_ends[[f]]; r <- fl[fl$name == f, ]
    p <- flow_glyph(p, k, min(pa[, 1]), max(pa[, 1]), pa[1, 2], r$x, r$label)
  }
  if (length(glyph) && !is.null(heads)) p <- p + ggplot2::geom_polygon(data = heads,   # over the glyph pipes
      xy(group = .data$id), fill = k$pipe_out, colour = k$pipe_out, linewidth = 0.6, linejoin = "round")
  fv <- fl[!fl$name %in% glyph, ]
  if (nrow(fv) && !inpipe) p <- p + ggplot2::annotate("point", x = fv$x, y = fv$y - 0.035,
    size = 8.4, colour = ggplot2::alpha(k$shadow, 0.07))  # valve shadow
  if (nrow(fv)) p <- valve(p, k, fv$x, fv$y)
  p <- draw_nodes(p, k, nd, initials = initials)
  if (nrow(fv) && inpipe)             # bent/vertical pipes: name beside, no card
    p <- txt(p, k, fv$lx, fv$ly, fv$label, k$flow_text, bold = TRUE, halo = TRUE)
  if (nrow(fl) && !inpipe) {
    lw <- fl$w + 0.16; lh <- fl$h - 0.02
    p <- card(p, k, fl$lx, fl$ly, lw, lh, pmin(lh / 2, 0.16), k$flow_fill, k$flow_line,
              paste0("fl_", fl$name), lw = max(0.4, k$flow_lw), shadow = FALSE)
    p <- txt(p, k, fl$lx, fl$ly, fl$label, k$flow_text)
  }
  leg <- list(
    leg_card(k, "Stock", k$stock_fill, k$stock_line, w = 0.36, h = 0.24, r = 0.07, lw = max(0.4, k$stock_lw - 0.4)),
    list(label = "Flow", draw = function(p, x, y) p +
      ggplot2::annotate("segment", x = x - 0.2, xend = x + 0.2, y = y, yend = y,
                        colour = k$pipe_out, linewidth = 2.6) +
      ggplot2::annotate("segment", x = x - 0.2, xend = x + 0.2, y = y, yend = y,
                        colour = k$pipe_in, linewidth = 1.5) +
      ggplot2::annotate("point", x = x, y = y, shape = 21, size = 3, fill = k$valve_fill,
                        colour = k$valve, stroke = 0.9)),
    leg_card(k, "Variable", k$aux_fill, k$aux_line, lw = max(0.4, k$aux_lw)),
    leg_card(k, "Constant", k$const_fill, k$const_line, lw = 0.45, lty = k$const_lty %||% "solid"),
    list(label = "Influence", draw = function(p, x, y) p +
      ggplot2::annotate("segment", x = x - 0.22, xend = x + 0.2, y = y, yend = y,
                        colour = k$info, linewidth = min(k$link_lw %||% 0.45, 0.8),
                        arrow = ggplot2::arrow(length = ggplot2::unit(0.06, "inches"),
                                               type = "closed", angle = 24))))
  p <- finish(p, k, o, gsub("_", " ", d$name %||% ""),
              sprintf("Stock-and-flow diagram%s%d stocks%s%d flows", k$dot,
                      sum(nd$type == "stock"), k$dot, nrow(fl)),
              L$boxes, ip, legend = leg)
  attr(p, "geom") <- list(paths = ip$paths, boxes = L$boxes, info = L$info, soft = soft)
  p
}

render_cld <- function(d, k, o = list()) {
  L <- layout_cld(d, k); nd <- L$nodes; ed <- L$info; lo <- L$loops
  pair <- paste(ed$from, ed$to)
  curve_fn <- function(a, b, e) {
    m <- (c(a$x, a$y) + c(b$x, b$y)) / 2
    n <- nrow(nd); di <- abs(a$idx - b$idx); adj <- min(di, n - di) == 1
    u <- m / max(sqrt(sum(m^2)), 1e-9)
    if (adj) {
      rev_exists <- paste(e$to, e$from) %in% pair
      return(if (rev_exists && sort(c(e$from, e$to), method = "radix")[1] == e$to) 2 * 0.72 * L$R * u - m else 2 * L$R * u - m)
    }
    m * 0.55
  }
  cl <- nd; cl$w <- cl$w + 0.16; cl$h <- cl$h + 0.04
  ip <- route_links(cl, ed, pref = curve_fn)

  # loops: polarity, badge start position, and the edge ids they run along
  lp <- NULL
  if (length(lo$cycles)) {
    th <- vapply(lo$cycles, function(cy) atan2(mean(sin(nd[cy, "ang"])), mean(cos(nd[cy, "ang"]))), 1)
    r <- L$R * pmax(0.2, 0.75 - 0.08 * lengths(lo$cycles))
    lp <- data.frame(x = r * cos(th), y = r * sin(th), pol = lo$pol)
    lp$lab <- paste0(c(R = "R", B = "B", L = "?")[lp$pol],
                     stats::ave(seq_len(nrow(lp)), lp$pol, FUN = seq_along))
  }
  p <- ggplot2::ggplot()
  if (!is.null(lp) && !is.null(ip$paths)) {
    # one band per edge: reinforcing wins over balancing (overlaps would muddy)
    kR <- unique(unlist(lo$edges[lo$pol == "R"]))
    kB <- setdiff(unique(unlist(lo$edges[lo$pol == "B"])), kR)
    # bands run centre-to-centre (unclipped) so they flow under the opaque nodes
    band <- do.call(rbind, lapply(c(kR, kB), function(i)
      if (!is.null(ip$full[[i]])) data.frame(ip$full[[i]], id = i, pol = if (i %in% kR) "R" else "B")))
    if (!is.null(band)) p <- p +
      ggplot2::geom_path(data = band, xy(group = .data$id, colour = .data$pol, linetype = .data$pol),
                         linewidth = 6.5, alpha = k$band_a, lineend = "butt", linejoin = "round") +
      ggplot2::scale_colour_manual(values = c(R = k$loopR, B = k$loopB), guide = "none") +
      ggplot2::scale_linetype_manual(values = c(R = "solid", B = k$loopB_band_lty %||% "solid"), guide = "none")
  }
  if (!is.null(ip$paths)) p <- halo_path(p, k, ip$paths, k$link_lw %||% 0.5,
      arrow = ggplot2::arrow(length = ggplot2::unit(0.08, "inches"), type = "closed", angle = 24))
  if (!is.null(ip$paths)) p <- p + ggplot2::geom_path(data = ip$paths, xy(group = .data$id),
      colour = k$info, linewidth = k$link_lw %||% 0.5, lineend = "round",
      arrow = ggplot2::arrow(length = ggplot2::unit(0.08, "inches"), type = "closed", angle = 24))
  p <- draw_nodes(p, k, nd, skip = character(), cld = TRUE)
  sg <- ip$signs[!is.na(ip$signs$sign), ]
  if (!is.null(sg) && nrow(sg)) {
    pos <- sg$sign == "+"
    p <- p + ggplot2::annotate("point", x = sg$x, y = sg$y, shape = 21, size = 4.6, stroke = 0.6,
                               fill = ifelse(pos, k$plus_fill, k$minus_fill), colour = k$sign_ring %||% k$bg)
    p <- txt(p, k, sg$x, sg$y + 0.005, ifelse(pos, "+", k$minus),
             ifelse(pos, k$plus_text, k$minus_text), size = FONT + 0.6, bold = TRUE)
  }
  if (!is.null(lp)) {
    # place each badge at the nearest spot (spiral search from its loop centre)
    # clear of link lines, sign dots, node cards and already-placed badges
    bw <- 0.26; bh <- 0.16
    pts <- rbind(data.frame(ip$paths[, c("x", "y")], m = rep(0.07, NROW(ip$paths))),
                 data.frame(ip$signs[, c("x", "y")], m = rep(0.16, NROW(ip$signs))))
    boxes <- data.frame(x = cl$x, y = cl$y, w = cl$w / 2 + 0.1, h = cl$h / 2 + 0.1)
    ok <- function(x, y) all(pmax(abs(pts$x - x) - bw, abs(pts$y - y) - bh) >= pts$m) &&
      !any(abs(boxes$x - x) < boxes$w + bw & abs(boxes$y - y) < boxes$h + bh)
    th <- seq(0, 2 * pi, length.out = 33)[-33]
    cand <- do.call(rbind, lapply(seq(0, 2, by = 0.04), function(r) cbind(r * cos(th), r * sin(th))))
    for (i in seq_len(nrow(lp))) {
      for (j in seq_len(nrow(cand))) {
        x <- lp$x[i] + cand[j, 1]; y <- lp$y[i] + cand[j, 2]
        if (ok(x, y)) { lp$x[i] <- x; lp$y[i] <- y; break }
      }
      boxes <- rbind(boxes, data.frame(x = lp$x[i], y = lp$y[i], w = bw + 0.08, h = bh + 0.08))
    }
    role <- function(s) unlist(k[paste0("loop", lp$pol, s)])
    opt <- function(s, d) vapply(lp$pol, function(z) k[[paste0("loop", z, s)]] %||% d, d)
    p <- card(p, k, lp$x, lp$y, 0.52, 0.32, 0.16, role("_fill"), role("_line"),
              paste0("lp", seq_len(nrow(lp))), lw = opt("_lw", 0.45), lty = opt("_lty", "solid"))
    p <- txt(p, k, lp$x, lp$y, lp$lab, role("_text"), size = FONT, bold = TRUE)
  }
  leg <- list(
    leg_card(k, "Stock", k$stock_fill, k$stock_line, w = 0.36, h = 0.24, r = 0.07, lw = max(0.4, k$stock_lw - 0.4)),
    leg_card(k, "Variable", k$aux_fill, k$aux_line, lw = max(0.4, k$aux_lw)),
    leg_sign(k, "Same direction", "+", k$plus_fill, k$plus_text),
    leg_sign(k, "Opposite direction", k$minus, k$minus_fill, k$minus_text))
  lg_loop <- c(R = "Reinforcing loop", B = "Balancing loop", L = "Loop, polarity unknown")
  for (pl in intersect(c("R", "B", "L"), lp$pol))
    leg[[length(leg) + 1]] <- leg_card(k, lg_loop[[pl]], k[[paste0("loop", pl, "_fill")]],
                                       k[[paste0("loop", pl, "_line")]], h = 0.24, r = 0.12,
                                       lw = k[[paste0("loop", pl, "_lw")]] %||% 0.4,
                                       lty = k[[paste0("loop", pl, "_lty")]] %||% "solid")
  p <- finish(p, k, o, gsub("_", " ", d$name %||% ""),
              sprintf("Causal loop diagram%s%d feedback loops", k$dot, length(lo$cycles)),
              nd, ip, legend = leg)
  attr(p, "geom") <- list(paths = ip$paths, boxes = cl, info = ed)
  attr(p, "loops") <- data.frame(
    label = lp$lab %||% character(),
    polarity = unname(c(R = "reinforcing", B = "balancing", L = "unknown")[lo$pol]),
    path = vapply(lo$cycles, function(cy) paste(c(cy, cy[1]), collapse = " -> "), ""))
  p
}

## The plain layered fallback: stocks on the spine, everything else around them.
plot_plain <- function(object, o = list()) {
  nd <- object$nodes
  rank <- c(stock = 1, flow = 2, aux = 3, lookup = 4, input = 4, constant = 5)
  nd$layer <- unname(rank[nd$type])
  nd$layer[is.na(nd$layer)] <- 3
  nd <- nd[order(nd$layer, nd$name), ]
  nd$x <- unlist(lapply(split(nd$name, nd$layer), function(z) seq_along(z) - mean(seq_along(z))))
  nd$y <- -nd$layer
  pos <- stats::setNames(seq_len(nrow(nd)), nd$name)

  ed <- object$edges
  if (nrow(ed)) {
    ed$x <- nd$x[pos[ed$from]]; ed$y <- nd$y[pos[ed$from]]
    ed$xend <- nd$x[pos[ed$to]]; ed$yend <- nd$y[pos[ed$to]]
    ed <- ed[stats::complete.cases(ed[c("x", "y", "xend", "yend")]), , drop = FALSE]
  }

  p <- ggplot2::ggplot()
  if (nrow(ed))
    p <- p + ggplot2::geom_segment(
      data = ed,
      ggplot2::aes(x = .data$x, y = .data$y, xend = .data$xend, yend = .data$yend,
                   linetype = .data$kind),
      colour = "grey55",
      arrow = ggplot2::arrow(length = ggplot2::unit(0.12, "cm"), type = "closed"))
  p + ggplot2::geom_label(data = nd,
        ggplot2::aes(x = .data$x, y = .data$y, label = .data$name, fill = .data$type),
        size = 2.6, linewidth = 0.15) +
    ggplot2::labs(title = if (isTRUE(o$title)) object$name, x = NULL, y = NULL) +
    ggplot2::theme_void() +
    ggplot2::theme(plot.background = ggplot2::element_rect(fill = o$background %||% NA, colour = NA))
}
