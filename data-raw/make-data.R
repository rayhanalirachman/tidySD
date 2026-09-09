## Regenerates the three datasets shipped with tidysd. Run with:
##   Rscript data-raw/make-data.R

## 1. Boarding-school influenza, England, 1978 --------------------------------
## Daily count of boys confined to bed during the outbreak reported in the
## British Medical Journal, 4 March 1978 (Anonymous, "Influenza in a boarding
## school", BMJ 1:587). 763 boys, one index case. This is the series Duggan
## fits in SDMR chapter 7.
boarding_school_flu <- data.frame(
  time = 0:14,
  sInfected = c(1, 3, 8, 26, 76, 225, 298, 258, 233, 189, 128, 68, 29, 14, 4)
)

## 2. Synthetic stand-in for the 351 Massachusetts towns ----------------------
## The Vensim sample's town names and 1990-census populations are not
## redistributed here. This is a deterministic synthetic replacement with the
## same shape: 351 members, one dominant town, a long tail of small ones.
## A Zipf-like size distribution scaled so that the largest town and the total
## match the orders of magnitude of the original (~618k and ~6.55M).
n_towns <- 351L
r <- seq_len(n_towns)
target_max <- 617660
target_total <- 6547695
p <- stats::uniroot(function(p) target_max * sum(r^-p) - target_total,
                    interval = c(0.1, 3))$root
sizes <- round(target_max * r^-p)
town_population <- stats::setNames(as.numeric(sizes), sprintf("Town%03d", r))

## 3. Synthetic stand-in for the CDIAC global emissions series ----------------
## Boden, Marland & Andres' global fossil-fuel and cement emissions, 1751-2011,
## are not redistributed here. This is a deterministic synthetic replacement
## with the same shape: near-zero through the 18th century, industrial-era
## exponential growth, a mid-20th-century acceleration.
yr <- 1751:2011
z <- (yr - 1751) / (2011 - 1751)
value <- 3 * exp(4.2 * z) + 9450 * z^4.5
global_emissions_synthetic <- data.frame(time = yr, emissions = round(value, 3))

usethis_available <- requireNamespace("usethis", quietly = TRUE)
save(boarding_school_flu, file = "data/boarding_school_flu.rda", version = 2)
save(town_population, file = "data/town_population.rda", version = 2)
save(global_emissions_synthetic, file = "data/global_emissions_synthetic.rda", version = 2)
cat("wrote 3 datasets\n")
