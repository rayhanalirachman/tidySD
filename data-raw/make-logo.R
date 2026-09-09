## Generates man/figures/logo.png -- a hex sticker drawn with grid, no deps
## beyond base R. Run with: Rscript data-raw/make-logo.R
library(grid)

hexpts <- function(cx, cy, r) {
  a <- seq(90, 450, by = 60) * pi / 180
  list(x = cx + r * cos(a), y = cy + r * sin(a))
}

png("man/figures/logo.png", width = 1200, height = 1386, bg = "transparent", res = 300)
grid.newpage()
pushViewport(viewport(xscale = c(0, 1), yscale = c(0, 1)))

ink    <- "#12303B"
paper  <- "#F7F3EA"
accent <- "#C4552F"
mid    <- "#4E8A8B"

h <- hexpts(0.5, 0.5, 0.485)
grid.polygon(h$x, h$y, gp = gpar(fill = ink, col = NA))
h2 <- hexpts(0.5, 0.5, 0.452)
grid.polygon(h2$x, h2$y, gp = gpar(fill = paper, col = NA))

## stock-and-flow motif: source -> stock -> stock -> sink
y  <- 0.585
bw <- 0.145; bh <- 0.105
x1 <- 0.345; x2 <- 0.655
grid.rect(x = x1, y = y, width = bw, height = bh,
          gp = gpar(fill = mid, col = ink, lwd = 2.4))
grid.rect(x = x2, y = y, width = bw, height = bh,
          gp = gpar(fill = accent, col = ink, lwd = 2.4))

ar <- arrow(length = unit(0.045, "npc"), type = "closed")
grid.lines(c(0.155, x1 - bw / 2 - 0.012), c(y, y),
           gp = gpar(col = ink, lwd = 3, fill = ink), arrow = ar)
grid.lines(c(x1 + bw / 2 + 0.012, x2 - bw / 2 - 0.012), c(y, y),
           gp = gpar(col = ink, lwd = 3, fill = ink), arrow = ar)
grid.lines(c(x2 + bw / 2 + 0.012, 0.845), c(y, y),
           gp = gpar(col = ink, lwd = 3, fill = ink), arrow = ar)

## the balancing loop: an arc from the second stock back to the first
cx <- 0.5; rx <- (x2 - x1) / 2; ry <- 0.10
th <- seq(0.02 * pi, 0.97 * pi, length.out = 90)
grid.lines(cx + rx * cos(th), y + bh / 2 + 0.006 + ry * sin(th),
           gp = gpar(col = ink, lwd = 2.4, lty = "21", fill = ink),
           arrow = arrow(length = unit(0.035, "npc"), type = "open"))

grid.text("tidysd", x = 0.5, y = 0.315,
          gp = gpar(col = ink, fontsize = 34, fontface = "bold", fontfamily = "sans"))
grid.text("stocks  .  flows  .  tibbles", x = 0.5, y = 0.225,
          gp = gpar(col = mid, fontsize = 10.5, fontfamily = "sans"))
dev.off()
cat("wrote man/figures/logo.png\n")
