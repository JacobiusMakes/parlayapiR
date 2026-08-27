#' Remove the bookmaker margin from quoted odds
#'
#' Takes the quoted odds for all outcomes of a single market (for
#' example both sides of a total, or the three outcomes of a soccer
#' match) and estimates the fair, margin-free probabilities.
#'
#' Methods:
#' * `"multiplicative"` (default): divides each raw implied probability
#'   by their sum. Simple and the standard baseline.
#' * `"additive"`: subtracts an equal share of the overround from each
#'   outcome. Can produce non-positive probabilities for long shots, in
#'   which case a warning is issued.
#' * `"power"`: finds the exponent `k` such that the raw implied
#'   probabilities raised to `k` sum to 1. Shrinks long shots more than
#'   favorites, which better matches the favorite-longshot bias
#'   documented in betting markets.
#'
#' @param odds Numeric vector of quoted odds for all outcomes of one
#'   market. Supply either `odds` or `probs`, not both.
#' @param probs Numeric vector of raw implied probabilities (must sum to
#'   more than is fair, i.e. contain the margin) as an alternative to
#'   `odds`.
#' @param method `"multiplicative"`, `"additive"`, or `"power"`.
#' @param odds_format `"decimal"` or `"american"`, for `odds`.
#' @return A data frame with one row per outcome and columns `implied`
#'   (raw implied probability), `fair_prob` (devigged probability), and
#'   `fair_decimal` (the corresponding fair decimal odds). The overround
#'   (the amount by which raw implied probabilities exceeded 1) is
#'   attached as attribute `"overround"`.
#' @export
#' @examples
#' # A symmetric -110 / -110 total devigs to 50/50 under every method
#' pa_devig(c(-110, -110), odds_format = "american")
#'
#' # Three-way soccer market, power method
#' pa_devig(c(2.45, 3.40, 3.10), method = "power")
pa_devig <- function(odds = NULL,
                     probs = NULL,
                     method = c("multiplicative", "additive", "power"),
                     odds_format = c("decimal", "american")) {
  method <- match.arg(method)
  odds_format <- match.arg(odds_format)
  if (is.null(odds) == is.null(probs)) {
    stop("Supply exactly one of `odds` or `probs`.", call. = FALSE)
  }
  if (!is.null(odds)) {
    probs <- pa_implied_prob(odds, odds_format = odds_format)
  }
  if (!is.numeric(probs) || length(probs) < 2L) {
    stop(
      "Devigging needs the probabilities of at least two outcomes ",
      "covering one full market.",
      call. = FALSE
    )
  }
  if (anyNA(probs) || any(probs <= 0) || any(probs >= 1)) {
    stop("All implied probabilities must be strictly between 0 and 1.",
      call. = FALSE
    )
  }
  total <- sum(probs)
  fair <- switch(method,
    multiplicative = probs / total,
    additive = {
      out <- probs - (total - 1) / length(probs)
      if (any(out <= 0)) {
        warning(
          "Additive devigging produced non-positive probabilities; ",
          "consider method = \"power\" for markets with long shots.",
          call. = FALSE
        )
      }
      out
    },
    power = {
      k <- uniroot(
        function(k) sum(probs^k) - 1,
        interval = c(1e-4, 100),
        tol = .Machine$double.eps^0.5
      )$root
      probs^k
    }
  )
  out <- data.frame(
    implied = probs,
    fair_prob = fair,
    fair_decimal = ifelse(fair > 0, 1 / fair, NA_real_)
  )
  attr(out, "overround") <- total - 1
  out
}
