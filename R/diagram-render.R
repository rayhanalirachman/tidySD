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
    band_a = 0.16))

## First installed family of FONT_CHAIN. pdf()/postscript() only know their own
## font tables (Latin-1), so an open one of those gets "sans" and ASCII glyphs,
## as does a non-UTF-8 locale.
diagram_fonts <- function() {
  sf <- requireNamespace("systemfonts", quietly = TRUE)
  ps <- names(grDevices::dev.cur()) %in% c("pdf", "postscript")
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

## Width (data units) of the widest line of each label.
text_w <- function(lab, k, size = FONT) {
  vapply(strsplit(lab, "\n", fixed = TRUE), function(l) max(
    if (k$sf) systemfonts::string_width(l, family = k$fam, size = size * ggplot2::.pt,
                                        res = 72) / 72 / UNIT_IN
    else nchar(l) * CHAR_W * size / FONT), 1)
}

wrap_label <- function(x, width = 14)
  vapply(x, function(s) paste(strwrap(gsub("_", " ", s), width), collapse = "\n"), "")

label_box <- function(lab, k, pad_w = 0.2, pad_h = 0.14)
  list(w = text_w(lab, k) + pad_w,
       h = lengths(strsplit(lab, "\n", fixed = TRUE)) * LINE_H + pad_h)

## ---- geometry helpers -------------------------------------------------------------

bezier <- function(p0, c, p1, n = 60) {
  t <- seq(0, 1, length.out = n)
  cbind(x = (1 - t)^2 * p0[1] + 2 * (1 - t) * t * c[1] + t^2 * p1[1],
        y = (1 - t)^2 * p0[2] + 2 * (1 - t) * t * c[2] + t^2 * p1[2])
}

inside <- function(pts, box, pad = 0.07)
  abs(pts[, 1] - box$x) <= box$w / 2 + pad & abs(pts[, 2] - box$y) <= box$h / 2 + pad

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

layout_sfd <- function(d, k) {
  nd <- as.data.frame(d$nodes, stringsAsFactors = FALSE)
  ed <- as.data.frame(d$edges, stringsAsFactors = FALSE)
  nd$label <- wrap_label(nd$name)
  bx <- label_box(nd$label, k)
  nd$w <- bx$w; nd$h <- bx$h
  st <- nd$type == "stock"
  nd$w[st] <- pmax(1.55, nd$w[st] + 0.5); nd$h[st] <- pmax(1.05, nd$h[st] + 0.5)
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

  # ---- non-material nodes: rows by graph distance, bands, barycentre x ----
  info <- ed[ed$kind == "information", ]
  other <- nd$name[!nd$type %in% c("stock", "flow")]
  nbrs <- function(n) unique(c(info$to[info$from == n], info$from[info$to == n]))
  # home row: BFS to the nearest placed node
  for (n in other) {
    seen <- n; frontier <- n; r <- NA
    while (length(frontier) && is.na(r)) {
      nx <- setdiff(unique(unlist(lapply(frontier, nbrs))), seen)
      hit <- nx[!is.na(nd[nx, "row"])]
      if (length(hit)) r <- nd[hit[1], "row"]
      seen <- c(seen, nx); frontier <- nx
    }
    nd[n, "row"] <- if (is.na(r)) 1L else r
  }
  band <- stats::setNames(rep(NA_character_, length(other)), other)
  for (n in other) {
    if (nd[n, "type"] != "constant") { band[n] <- "above"; next }
    cons <- info$to[info$from == n]
    band[n] <- if (length(cons) && all(!nd[cons, "type"] %in% c("stock", "flow"))) "top" else "below"
  }
  off <- c(above = 1.75, top = 3.0, below = -1.75)
  nd[other, "y"] <- -(nd[other, "row"] - 1) * ROW_H + off[band]
  if (!any(st)) {   # no stock-flow spine: layer by longest path from the sources
    dep <- stats::setNames(rep(0, length(other)), other)
    for (it in seq_along(other)) for (i in seq_len(nrow(info)))
      dep[info$to[i]] <- max(dep[info$to[i]], dep[info$from[i]] + 1)
    band <- stats::setNames(as.character(dep), other); nd[other, "y"] <- dep * 1.6
  }
  mean_x <- mean(nd$x, na.rm = TRUE); if (is.na(mean_x)) mean_x <- 0
  nd[other, "x"] <- mean_x
  for (it in 1:30) {
    for (n in other) {
      nb <- nbrs(n); nb <- nb[!is.na(nd[nb, "x"])]
      if (length(nb)) nd[n, "x"] <- mean(nd[nb, "x"])
    }
    nd <- spread_bands(nd, other, paste(nd[other, "row"], band))
  }
  list(nodes = nd, info = info, pipes = pipe_list,
       clouds = if (length(clouds)) do.call(rbind, clouds) else NULL)
}

## remove overlaps within each band, preserving order and centre of mass
spread_bands <- function(nd, who, key, gap = 0.35) {
  for (b in unique(key)) {
    ids <- who[key == b]; ids <- ids[order(nd[ids, "x"])]
    if (length(ids) < 2) next
    want <- nd[ids, "x"]; x <- want
    for (i in 2:length(ids)) {
      need <- x[i - 1] + (nd[ids[i - 1], "w"] + nd[ids[i], "w"]) / 2 + gap
      if (x[i] < need) x[i] <- need
    }
    nd[ids, "x"] <- x - mean(x) + mean(want)
  }
  nd
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
  bx <- label_box(nd$label, k); nd$w <- bx$w; nd$h <- bx$h
  st <- nd$type == "stock"; nd$w[st] <- nd$w[st] + 0.2; nd$h[st] <- nd$h[st] + 0.12
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

info_paths <- function(nd, info, curve_fn) {
  paths <- list(); signs <- list()
  for (i in seq_len(nrow(info))) {
    a <- nd[info$from[i], ]; b <- nd[info$to[i], ]
    if (is.na(a$x) || is.na(b$x)) next
    pts <- clip_curve(bezier(c(a$x, a$y), curve_fn(a, b, info[i, ]), c(b$x, b$y)), a, b)
    if (is.null(pts)) next
    paths[[length(paths) + 1]] <- data.frame(pts, id = i)
    dir <- pts[nrow(pts), ] - pts[max(1, nrow(pts) - 6), ]
    nrm <- c(-dir[2], dir[1]) / sqrt(sum(dir^2))
    j <- max(1, nrow(pts) - 5)
    signs[[length(signs) + 1]] <- data.frame(x = pts[j, 1] + 0.17 * nrm[1],
                                             y = pts[j, 2] + 0.17 * nrm[2],
                                             sign = info$sign[i])
  }
  list(paths = if (length(paths)) do.call(rbind, paths),
       signs = if (length(signs)) do.call(rbind, signs))
}

## ---- drawing ------------------------------------------------------------------------

xy <- function(...) ggplot2::aes(x = .data$x, y = .data$y, ...)

## rounded-rectangle polygons, one per row
rrect <- function(x, y, w, h, r, id, n = 10) {
  n_ <- length(x); w <- rep_len(w, n_); h <- rep_len(h, n_); y <- rep_len(y, n_)
  r <- rep_len(r, n_); id <- rep_len(id, n_)
  do.call(rbind, lapply(seq_along(x), function(i) {
    rr <- min(r[i], w[i] / 2, h[i] / 2)
    cx <- x[i] + c(1, -1, -1, 1) * (w[i] / 2 - rr); cy <- y[i] + c(1, 1, -1, -1) * (h[i] / 2 - rr)
    pts <- do.call(rbind, lapply(1:4, function(q) {
      th <- seq((q - 1) * pi / 2, q * pi / 2, length.out = n)
      cbind(cx[q] + rr * cos(th), cy[q] + rr * sin(th))
    }))
    data.frame(x = pts[, 1], y = pts[, 2], id = as.character(id[i]))
  }))
}

## card = two soft shadow layers + tinted rounded rect with same-hue hairline
card <- function(p, k, x, y, w, h, r, fill, line, id, lw = 0.45, shadow = TRUE) {
  if (!length(x)) return(p)
  if (shadow) p <- p +
    ggplot2::geom_polygon(data = rrect(x, y - 0.07, w + 0.1, h + 0.08, r + 0.05, id),
                          xy(group = .data$id), fill = k$shadow, alpha = 0.035) +
    ggplot2::geom_polygon(data = rrect(x, y - 0.035, w + 0.03, h + 0.02, r + 0.015, id),
                          xy(group = .data$id), fill = k$shadow, alpha = 0.06)
  df <- rrect(x, y, w, h, r, id)
  i <- match(df$id, as.character(rep_len(id, length(x))))
  df$fill <- rep_len(fill, length(x))[i]; df$line <- rep_len(line, length(x))[i]
  p + ggplot2::geom_polygon(data = df, xy(group = .data$id, fill = I(.data$fill),
                                          colour = I(.data$line)), linewidth = lw)
}

txt <- function(p, k, x, y, label, colour, size = FONT, bold = FALSE, ...)
  p + ggplot2::annotate("text", x = x, y = y, label = label, colour = colour, size = size,
                        family = k$fam, fontface = if (bold) "bold" else "plain",
                        lineheight = 0.92, ...)

fmt_num <- function(v) format(v, big.mark = ",", trim = TRUE, drop0trailing = TRUE)

draw_nodes <- function(p, k, nd, skip = "flow", initials = NULL, cld = FALSE) {
  st <- nd[nd$type == "stock", ]
  if (nrow(st)) {
    p <- card(p, k, st$x, st$y, st$w, st$h, if (cld) 0.13 else 0.17,
              k$stock_fill, k$stock_line, paste0("s_", st$name), lw = k$stock_lw)
    has0 <- !cld & st$name %in% names(initials)
    p <- txt(p, k, st$x, st$y + ifelse(has0, 0.13, 0), st$label, k$stock_text,
             size = if (cld) FONT + 0.4 else FONT + 1.3, bold = TRUE)
    if (any(has0)) {
      s0 <- st[has0, ]; lab <- paste("starts at", fmt_num(unlist(initials[s0$name])))
      cw <- text_w(lab, k, FONT - 0.6) + 0.22
      p <- card(p, k, s0$x, s0$y - 0.24, cw, 0.25, 0.125, k$chip_fill, k$chip_line,
                paste0("c_", s0$name), lw = 0.35, shadow = FALSE)
      p <- txt(p, k, s0$x, s0$y - 0.24, lab, k$chip_text, size = FONT - 0.6)
    }
  }
  pill <- nd[!nd$type %in% c("stock", "constant", skip), ]
  for (f in c(TRUE, FALSE)) {
    q <- pill[(pill$type == "flow") == f, ]; if (!nrow(q)) next
    p <- card(p, k, q$x, q$y, q$w + 0.14, q$h + 0.02, pmin(q$h / 2, 0.17),
              if (f) k$flow_fill else k$aux_fill, if (f) k$flow_line else k$aux_line,
              paste0("p_", q$name), lw = if (f) k$flow_lw else k$aux_lw)
    p <- txt(p, k, q$x, q$y, q$label, if (f) k$flow_text else k$aux_text)
  }
  cn <- nd[nd$type == "constant", ]
  if (nrow(cn)) {
    p <- card(p, k, cn$x, cn$y, cn$w + 0.06, cn$h - 0.02, pmin(cn$h / 2, 0.14), k$const_fill,
              k$const_line, paste0("k_", cn$name), lw = k$const_lw, shadow = FALSE)
    p <- txt(p, k, cn$x, cn$y, cn$label, k$const_text, size = FONT - 0.25)
  }
  p
}

## legend of mini-glyphs under the diagram, left aligned, wrapping at x_max
legend_rows <- function(p, k, x0, y, x_max, items) {
  x <- x0
  for (it in items) {
    iw <- 0.5 + text_w(it$label, k, FONT - 0.35)
    if (x > x0 && x + iw > x_max) { x <- x0; y <- y - 0.42 }
    p <- it$draw(p, x + 0.2, y)
    p <- txt(p, k, x + 0.5, y, it$label, k$muted, size = FONT - 0.35, hjust = 0)
    x <- x + iw + 0.5
  }
  list(p = p, y = y)
}

finish <- function(p, k, title, subtitle, nd, ip, extra = NULL, legend = NULL) {
  xs <- c(nd$x - nd$w / 2, nd$x + nd$w / 2, ip$paths$x, extra[, 1])
  ys <- c(nd$y - nd$h / 2 - 0.25, nd$y + nd$h / 2, ip$paths$y, extra[, 2])
  xr <- range(xs, na.rm = TRUE) + c(-0.4, 0.4); yr <- range(ys, na.rm = TRUE) + c(-0.3, 0.3)
  if (diff(xr) < 8) xr <- mean(xr) + c(-4, 4)          # small models: give the legend room
  p <- p + ggplot2::annotate("segment", x = xr[1] + 0.1, xend = xr[2] - 0.1, y = yr[1] - 0.2,
                             yend = yr[1] - 0.2, colour = k$rule, linewidth = 0.4)
  lg <- legend_rows(p, k, xr[1] + 0.1, yr[1] - 0.62, xr[2] - 0.1, legend)
  p <- lg$p; yr[1] <- lg$y - 0.33
  p <- p + ggplot2::coord_equal(xlim = xr, ylim = yr, expand = FALSE, clip = "off") +
    ggplot2::labs(title = title, subtitle = subtitle) +
    ggplot2::theme_void(base_family = k$fam) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 15, colour = k$ink,
                                         margin = ggplot2::margin(2, 0, 3, 0)),
      plot.subtitle = ggplot2::element_text(size = 9.5, colour = k$muted,
                                            margin = ggplot2::margin(0, 0, 10, 0)),
      plot.title.position = "plot",
      plot.background = ggplot2::element_rect(fill = k$bg, colour = NA),
      plot.margin = ggplot2::margin(18, 22, 14, 22))
  attr(p, "size_in") <- c(diff(xr) + 0.6, diff(yr) + 1.1) * UNIT_IN
  attr(p, "bg") <- k$bg
  p
}

leg_card <- function(k, label, fill, line, w = 0.4, h = 0.2, r = 0.1, lw = 0.4) {
  force(list(fill, line, w, h, r, lw))
  list(label = label, draw = function(p, x, y)
    card(p, k, x, y, w, h, r, fill, line, paste0("lg_", label), lw = lw, shadow = FALSE))
}

leg_sign <- function(k, label, s, fill, colour)
  list(label = label, draw = function(p, x, y)
    txt(p + ggplot2::annotate("point", x = x, y = y, shape = 21, size = 4.2, fill = fill,
                              colour = k$bg), k, x, y, s, colour, size = FONT + 0.4, bold = TRUE))

render_sfd <- function(d, k, initials = NULL) {
  L <- layout_sfd(d, k); nd <- L$nodes
  curve_fn <- function(a, b, e) {
    a <- nd[e$from, ]; b <- nd[e$to, ]
    m <- (c(a$x, a$y) + c(b$x, b$y)) / 2; v <- c(b$x - a$x, b$y - a$y)
    len <- sqrt(sum(v^2)); nrm <- c(-v[2], v[1]) / len
    if (abs(v[2]) < 0.3) return(m + c(0, 0.45 * len))
    m + 0.12 * len * nrm
  }
  cl <- nd; f_ <- cl$type == "flow"
  top <- cl$y[f_] + 0.22; bot <- cl$y[f_] - 0.42 - cl$h[f_] + 0.1
  cl$y[f_] <- (top + bot) / 2; cl$h[f_] <- top - bot; cl$w[f_] <- 0.5
  cl$w[!f_] <- cl$w[!f_] + 0.1                       # pills are a touch wider than label boxes
  ip <- info_paths(cl, L$info, curve_fn)
  pipe_df <- do.call(rbind, lapply(names(L$pipes), function(f) {
    pa <- L$pipes[[f]]$path
    if (L$pipes[[f]]$into_stock) {
      n <- nrow(pa); dir <- pa[n, ] - pa[n - 1, ]; pa[n, ] <- pa[n, ] - 0.3 * dir / sqrt(sum(dir^2))
    }
    data.frame(x = pa[, 1], y = pa[, 2], id = f)
  }))
  heads <- do.call(rbind, lapply(names(L$pipes), function(f) {
    pa <- L$pipes[[f]]$path; if (!L$pipes[[f]]$into_stock) return(NULL)
    n <- nrow(pa); dir <- pa[n, ] - pa[n - 1, ]
    arrow_head(pa[n, ] - 0.03 * dir / sqrt(sum(dir^2)), dir, len = 0.3, wid = 0.34, id = f)
  }))
  fl <- nd[nd$type == "flow", ]
  vert <- vapply(fl$name, function(f) { pa <- L$pipes[[f]]$path; n <- nrow(pa)
    abs(pa[n, 1] - pa[n - 1, 1]) < 1e-6 && nrow(pa) == 2 }, TRUE)
  fl$lx <- fl$x + ifelse(vert, 0.3 + fl$w / 2, 0)
  fl$ly <- fl$y - ifelse(vert, 0, 0.42 + fl$h / 2 - 0.02)
  clouds <- if (!is.null(L$clouds)) do.call(rbind, lapply(seq_len(nrow(L$clouds)), function(i)
    cloud_poly(L$clouds[i, 1], L$clouds[i, 2], r = 0.24, id = i)))
  nd$w[nd$type == "flow"] <- 0.4; nd$h[nd$type == "flow"] <- 0.4

  p <- ggplot2::ggplot()
  if (!is.null(ip$paths)) p <- p + ggplot2::geom_path(data = ip$paths, xy(group = .data$id),
      colour = k$info, linewidth = 0.42, lineend = "round",
      arrow = ggplot2::arrow(length = ggplot2::unit(0.075, "inches"), type = "closed", angle = 24))
  if (!is.null(pipe_df)) p <- p +
    ggplot2::geom_path(data = pipe_df, xy(group = .data$id), colour = k$pipe_out,
                       linewidth = 4.6, lineend = "round", linejoin = "round") +
    ggplot2::geom_path(data = pipe_df, xy(group = .data$id), colour = k$pipe_in,
                       linewidth = 2.7, lineend = "round", linejoin = "round")
  if (!is.null(heads)) p <- p + ggplot2::geom_polygon(data = heads, xy(group = .data$id),
      fill = k$pipe_out, colour = k$pipe_out, linewidth = 0.6, linejoin = "round")
  if (!is.null(clouds)) p <- p + ggplot2::geom_polygon(data = clouds, xy(group = .data$id),
      fill = k$cloud_fill, colour = k$cloud_line, linewidth = 0.45)
  if (nrow(fl)) p <- p +                                  # valve knob: shadow, ring, hub
    ggplot2::annotate("point", x = fl$x, y = fl$y - 0.035, size = 8.4,
                      colour = ggplot2::alpha(k$shadow, 0.07)) +
    ggplot2::annotate("point", x = fl$x, y = fl$y, shape = 21, size = 7.2, fill = k$valve_fill,
                      colour = k$valve, stroke = 1.1) +
    ggplot2::annotate("point", x = fl$x, y = fl$y, size = 2.1, colour = k$valve)
  p <- draw_nodes(p, k, nd, initials = initials)
  if (nrow(fl)) {
    lw <- fl$w + 0.16; lh <- fl$h - 0.02
    p <- card(p, k, fl$lx, fl$ly, lw, lh, pmin(lh / 2, 0.16), k$flow_fill, k$flow_line,
              paste0("fl_", fl$name), lw = 0.4, shadow = FALSE)
    p <- txt(p, k, fl$lx, fl$ly, fl$label, k$flow_text)
  }
  leg <- list(
    leg_card(k, "Stock", k$stock_fill, k$stock_line, w = 0.36, h = 0.24, r = 0.07),
    list(label = "Flow", draw = function(p, x, y) p +
      ggplot2::annotate("segment", x = x - 0.2, xend = x + 0.2, y = y, yend = y,
                        colour = k$pipe_out, linewidth = 2.6) +
      ggplot2::annotate("segment", x = x - 0.2, xend = x + 0.2, y = y, yend = y,
                        colour = k$pipe_in, linewidth = 1.5) +
      ggplot2::annotate("point", x = x, y = y, shape = 21, size = 3, fill = k$valve_fill,
                        colour = k$valve, stroke = 0.9)),
    leg_card(k, "Variable", k$aux_fill, k$aux_line),
    leg_card(k, "Constant", k$const_fill, k$const_line, lw = 0.45),
    list(label = "Influence", draw = function(p, x, y) p +
      ggplot2::annotate("segment", x = x - 0.22, xend = x + 0.2, y = y, yend = y,
                        colour = k$info, linewidth = 0.45,
                        arrow = ggplot2::arrow(length = ggplot2::unit(0.06, "inches"),
                                               type = "closed", angle = 24))))
  finish(p, k, gsub("_", " ", d$name %||% ""),
         sprintf("Stock-and-flow diagram%s%d stocks%s%d flows", k$dot,
                 sum(nd$type == "stock"), k$dot, nrow(fl)),
         nd, ip, L$clouds, legend = leg)
}

render_cld <- function(d, k) {
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
  ip <- info_paths(cl, ed, curve_fn)

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
    band <- do.call(rbind, lapply(c(kR, kB), function(i) {
      a <- nd[ed$from[i], ]; b <- nd[ed$to[i], ]
      data.frame(bezier(c(a$x, a$y), curve_fn(a, b, ed[i, ]), c(b$x, b$y)), id = i,
                 pol = if (i %in% kR) "R" else "B")
    }))
    if (!is.null(band)) p <- p +
      ggplot2::geom_path(data = band, xy(group = .data$id, colour = .data$pol),
                         linewidth = 6.5, alpha = k$band_a, lineend = "butt", linejoin = "round") +
      ggplot2::scale_colour_manual(values = c(R = k$loopR, B = k$loopB), guide = "none")
  }
  if (!is.null(ip$paths)) p <- p + ggplot2::geom_path(data = ip$paths, xy(group = .data$id),
      colour = k$info, linewidth = 0.5, lineend = "round",
      arrow = ggplot2::arrow(length = ggplot2::unit(0.08, "inches"), type = "closed", angle = 24))
  p <- draw_nodes(p, k, nd, skip = character(), cld = TRUE)
  sg <- ip$signs[!is.na(ip$signs$sign), ]
  if (!is.null(sg) && nrow(sg)) {
    pos <- sg$sign == "+"
    p <- p + ggplot2::annotate("point", x = sg$x, y = sg$y, shape = 21, size = 4.6, stroke = 0.6,
                               fill = ifelse(pos, k$plus_fill, k$minus_fill), colour = k$bg)
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
    p <- card(p, k, lp$x, lp$y, 0.52, 0.32, 0.16, role("_fill"), role("_line"),
              paste0("lp", seq_len(nrow(lp))), lw = 0.45)
    p <- txt(p, k, lp$x, lp$y, lp$lab, role("_text"), size = FONT, bold = TRUE)
  }
  leg <- list(
    leg_card(k, "Stock", k$stock_fill, k$stock_line, w = 0.36, h = 0.24, r = 0.07),
    leg_card(k, "Variable", k$aux_fill, k$aux_line),
    leg_sign(k, "Same direction", "+", k$plus_fill, k$plus_text),
    leg_sign(k, "Opposite direction", k$minus, k$minus_fill, k$minus_text))
  lg_loop <- c(R = "Reinforcing loop", B = "Balancing loop", L = "Loop, polarity unknown")
  for (pl in intersect(c("R", "B", "L"), lp$pol))
    leg[[length(leg) + 1]] <- leg_card(k, lg_loop[[pl]], k[[paste0("loop", pl, "_fill")]],
                                       k[[paste0("loop", pl, "_line")]], h = 0.24, r = 0.12)
  p <- finish(p, k, gsub("_", " ", d$name %||% ""),
              sprintf("Causal loop diagram%s%d feedback loops", k$dot, length(lo$cycles)),
              nd, ip, legend = leg)
  attr(p, "loops") <- data.frame(
    label = lp$lab %||% character(),
    polarity = unname(c(R = "reinforcing", B = "balancing", L = "unknown")[lo$pol]),
    path = vapply(lo$cycles, function(cy) paste(c(cy, cy[1]), collapse = " -> "), ""))
  p
}

## The plain layered fallback: stocks on the spine, everything else around them.
plot_plain <- function(object) {
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
    ggplot2::labs(title = object$name, x = NULL, y = NULL) +
    ggplot2::theme_void()
}
