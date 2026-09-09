#' Boarding-school influenza, England, 1978
#'
#' Daily count of boys confined to bed during the influenza outbreak at an
#' English boarding school, reported in the *British Medical Journal*,
#' 4 March 1978. 763 boys, one index case, about two weeks of counts. This is
#' the series fitted in `sd_example("boarding_school_flu")`.
#'
#' @format A data frame with 15 rows and 2 columns:
#' \describe{
#'   \item{time}{Day of the outbreak, 0 = the index case.}
#'   \item{sInfected}{Boys confined to bed.}
#' }
#' @source Anonymous (1978) "Influenza in a boarding school",
#'   *British Medical Journal* 1:587.
"boarding_school_flu"

#' Synthetic town populations
#'
#' A deterministic, synthetic stand-in for the 351 Massachusetts town
#' populations in the Vensim subscripted-population sample, which is not
#' redistributed with tidysd. Same shape and scale (351 members, ~618,000 in the
#' largest town, ~6.55 M in total), invented names.
#'
#' @format A named numeric vector of length 351.
#' @seealso `sd_example("town_population")`
"town_population"

#' Synthetic global emissions series
#'
#' A deterministic, synthetic stand-in for the CDIAC global fossil-fuel and
#' cement emissions series (Boden, Marland and Andres, 1751-2011), which is not
#' redistributed with tidysd. Same shape and scale: near-zero through the 18th
#' century, industrial-era exponential growth, a mid-20th-century acceleration.
#'
#' @format A data frame with 261 rows and 2 columns:
#' \describe{
#'   \item{time}{Year.}
#'   \item{emissions}{Emissions, MtC/year.}
#' }
#' @seealso `sd_example("carbon_bathtub")`
"global_emissions_synthetic"
