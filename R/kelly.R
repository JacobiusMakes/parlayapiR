#' Kelly criterion bet sizing
#'
#' Computes the Kelly stake fraction for a bet: the share of bankroll
#' that maximizes long-run log growth given your estimated win
#' probability and the quoted odds. Negative Kelly fractions (no edge)
#' are clamped to 0. Matches the semantics of ParlayAPI's keyless
#' `/v1/calc/kelly` endpoint.
#'
#' Full Kelly is aggressive and assumes your probability estimate is
#' exactly right; fractional Kelly (for example `fraction = 0.25`) is
#' the common practical choice for noisy model estimates.
#'
#' @param prob Numeric vector of estimated win probabilities in (0, 1).
#' @param odds Numeric vector of quoted odds for the bet.
#' @param odds_format `"decimal"` or `"american"`.
#' @param fraction Kelly multiplier, e.g. `1` for full Kelly, `0.5` for
#'   half Kelly.
#' @param bankroll Optional bankroll amount. When supplied, the return
#'   value is the recommended stake instead of the fraction.
#' @return Numeric vector: the applied Kelly fraction of bankroll, or
#'   the stake amount when `bankroll` is given.
#' @export
#' @examples
#' # 55% win probability at +110
#' pa_kelly(0.55, +110, odds_format = "american")
#'
#' # Quarter Kelly stake from a 1000 unit bankroll
#' pa_kelly(0.55, 2.1, fraction = 0.25, bankroll = 1000)
#'
#' # No edge: clamped to zero
#' pa_kelly(0.40, 2.0)
pa_kelly <- function(prob,
                     odds,
                     odds_format = c("decimal", "american"),
                     fraction = 1,
                     bankroll = NULL) {
  odds_format <- match.arg(odds_format)
  if (!is.numeric(prob) || anyNA(prob) || any(prob <= 0) || any(prob >= 1)) {
    stop("`prob` must be numeric win probabilities strictly in (0, 1).",
      call. = FALSE
    )
  }
  if (!is.numeric(fraction) || length(fraction) != 1L || is.na(fraction) ||
    fraction <= 0 || fraction > 1) {
    stop("`fraction` must be a single number in (0, 1].", call. = FALSE)
  }
  if (odds_format == "american") {
    odds <- pa_american_to_decimal(odds)
  }
  if (!is.numeric(odds) || anyNA(odds) || any(odds <= 1)) {
    stop("Decimal odds must be greater than 1.", call. = FALSE)
  }
  full <- (odds * prob - 1) / (odds - 1)
  applied <- pmax(full, 0) * fraction
  if (is.null(bankroll)) {
    return(applied)
  }
  if (!is.numeric(bankroll) || length(bankroll) != 1L || is.na(bankroll) ||
    bankroll <= 0) {
    stop("`bankroll` must be a single positive number.", call. = FALSE)
  }
  applied * bankroll
}
