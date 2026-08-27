#' Convert American odds to decimal odds
#'
#' @param odds Numeric vector of American odds, e.g. `c(-110, 120)`.
#'   Values must be `<= -100` or `>= 100`.
#' @return Numeric vector of decimal odds.
#' @export
#' @examples
#' pa_american_to_decimal(c(-110, +150, 100))
pa_american_to_decimal <- function(odds) {
  if (!is.numeric(odds)) {
    stop("`odds` must be numeric American odds.", call. = FALSE)
  }
  bad <- !is.na(odds) & abs(odds) < 100
  if (any(bad)) {
    stop(
      "American odds must be <= -100 or >= 100; got: ",
      paste(odds[bad], collapse = ", "),
      call. = FALSE
    )
  }
  ifelse(odds > 0, 1 + odds / 100, 1 + 100 / abs(odds))
}

#' Convert decimal odds to American odds
#'
#' @param odds Numeric vector of decimal odds, all greater than 1.
#' @return Numeric vector of American odds.
#' @export
#' @examples
#' pa_decimal_to_american(c(1.909091, 2.5, 2))
pa_decimal_to_american <- function(odds) {
  if (!is.numeric(odds)) {
    stop("`odds` must be numeric decimal odds.", call. = FALSE)
  }
  bad <- !is.na(odds) & odds <= 1
  if (any(bad)) {
    stop(
      "Decimal odds must be greater than 1; got: ",
      paste(odds[bad], collapse = ", "),
      call. = FALSE
    )
  }
  ifelse(odds >= 2, (odds - 1) * 100, -100 / (odds - 1))
}

#' Implied probability of quoted odds
#'
#' Converts quoted odds to their raw implied probability, `1 / decimal`.
#' Note that raw implied probabilities across the outcomes of one market
#' sum to more than 1 because they still contain the bookmaker margin;
#' use [pa_devig()] to remove it.
#'
#' @param odds Numeric vector of odds.
#' @param odds_format `"decimal"` or `"american"`.
#' @return Numeric vector of implied probabilities in (0, 1).
#' @export
#' @examples
#' pa_implied_prob(c(-110, -110), odds_format = "american")
pa_implied_prob <- function(odds, odds_format = c("decimal", "american")) {
  odds_format <- match.arg(odds_format)
  if (odds_format == "american") {
    odds <- pa_american_to_decimal(odds)
  }
  if (!is.numeric(odds)) {
    stop("`odds` must be numeric.", call. = FALSE)
  }
  bad <- !is.na(odds) & odds <= 1
  if (any(bad)) {
    stop("Decimal odds must be greater than 1.", call. = FALSE)
  }
  1 / odds
}
