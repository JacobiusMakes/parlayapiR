#' parlayapiR: Client for the ParlayAPI Sports Odds API
#'
#' Query real-time and historical sports betting odds from
#' [ParlayAPI](https://parlay-api.com). The package mirrors the core of
#' the official Python SDK (`pip install parlay-api`):
#'
#' * [pa_sports()] lists available sports.
#' * [pa_odds()] fetches game odds (moneyline, spreads, totals) across
#'   sportsbooks in the same event shape used by The Odds API v4, so
#'   existing parsing code carries over.
#' * [pa_props()] fetches player props as a flat data frame of paired
#'   over/under quotes.
#' * [pa_historical()] and [pa_closing_odds()] retrieve historical
#'   snapshots and closing lines.
#' * [pa_devig()] removes the bookmaker margin from a set of quoted
#'   prices by the multiplicative, additive, or power method.
#' * [pa_kelly()] sizes a bet with the Kelly criterion.
#'
#' Authentication uses the `PARLAY_API_KEY` environment variable or
#' [pa_auth()]. Without a key, enable [pa_sandbox()] mode: every request
#' is routed to keyless synthetic endpoints with the same response
#' shapes, so all examples and the vignette run without signing up.
#'
#' @importFrom stats uniroot
#' @keywords internal
"_PACKAGE"
