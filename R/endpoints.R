#' List available sports
#'
#' Fetches the sports catalog. Each row has the sport `key` (which the
#' other request functions take as their `sport` argument), a display
#' `title`, a `group`, and an `active` flag.
#'
#' @param all Logical, include inactive and out-of-season sports.
#'   Ignored in sandbox mode.
#' @param sandbox Logical or `NULL`. `TRUE` uses the keyless sandbox
#'   endpoint, `FALSE` the live endpoint, `NULL` (default) defers to the
#'   global [pa_sandbox()] toggle.
#' @return A data frame of sports.
#' @export
#' @examples
#' \donttest{
#' sports <- pa_sports(sandbox = TRUE)
#' sports$key
#' }
pa_sports <- function(all = FALSE, sandbox = NULL) {
  sandbox <- pa_sandbox_enabled(sandbox)
  query <- if (sandbox) list() else list(all = if (isTRUE(all)) TRUE)
  pa_request(pa_sports_prefix(sandbox), query, sandbox = sandbox)
}

#' Get game odds across sportsbooks
#'
#' Fetches current odds for a sport. The response uses the same event
#' shape as The Odds API v4 (events containing `bookmakers`, each with
#' `markets`, each with `outcomes`), so parsing code written for that
#' API carries over unchanged.
#'
#' In sandbox mode the endpoint is keyless and serves synthetic events;
#' sandbox prices are always American regardless of `odds_format`.
#'
#' @param sport Sport key string, e.g. `"basketball_nba"`. See
#'   [pa_sports()].
#' @param regions Comma-separated regions string or character vector,
#'   default `"us"`.
#' @param markets Markets to include, e.g. `"h2h,spreads,totals"`.
#'   Character vectors are collapsed with commas.
#' @param odds_format `"decimal"` or `"american"`.
#' @param bookmakers Optional bookmaker keys to filter to.
#' @param event_ids Optional event ids to filter to (live mode only).
#' @param commence_time_from,commence_time_to Optional ISO 8601 bounds
#'   on event start time (live mode only).
#' @inheritParams pa_sports
#' @return A data frame of events with a `bookmakers` list-column.
#' @export
#' @examples
#' \donttest{
#' events <- pa_odds("basketball_nba", markets = "h2h", sandbox = TRUE)
#' events$home_team
#' }
pa_odds <- function(sport,
                    regions = "us",
                    markets = "h2h",
                    odds_format = c("decimal", "american"),
                    bookmakers = NULL,
                    event_ids = NULL,
                    commence_time_from = NULL,
                    commence_time_to = NULL,
                    sandbox = NULL) {
  pa_check_sport(sport)
  odds_format <- match.arg(odds_format)
  sandbox <- pa_sandbox_enabled(sandbox)
  query <- list(
    regions = regions,
    markets = markets,
    oddsFormat = odds_format,
    bookmakers = bookmakers
  )
  if (!sandbox) {
    query$eventIds <- event_ids
    query$commenceTimeFrom <- commence_time_from
    query$commenceTimeTo <- commence_time_to
  }
  pa_request(
    c(pa_sports_prefix(sandbox), sport, "odds"),
    query,
    sandbox = sandbox
  )
}

#' Get player props as a flat table
#'
#' Fetches player props as a flat data frame of paired over/under
#' quotes: one row per bookmaker, player, and market, with `line`,
#' `over_price`, `under_price`, and implied probabilities. This is a
#' ParlayAPI extension endpoint (The Odds API has no flat-props shape).
#'
#' @inheritParams pa_odds
#' @param markets Optional prop market keys, e.g.
#'   `"player_points,player_rebounds"`.
#' @param player Optional player name filter (live mode only).
#' @param event_id Optional event id filter (live mode only).
#' @param limit,offset Pagination controls (live mode only).
#' @return A data frame of prop quotes.
#' @export
#' @examples
#' \donttest{
#' props <- pa_props("basketball_nba", sandbox = TRUE)
#' head(props[, c("bookmaker", "player_name", "market_key", "line")])
#' }
pa_props <- function(sport,
                     markets = NULL,
                     bookmakers = NULL,
                     player = NULL,
                     event_id = NULL,
                     odds_format = c("american", "decimal"),
                     limit = NULL,
                     offset = NULL,
                     sandbox = NULL) {
  pa_check_sport(sport)
  odds_format <- match.arg(odds_format)
  sandbox <- pa_sandbox_enabled(sandbox)
  query <- list(markets = markets, bookmakers = bookmakers)
  if (!sandbox) {
    query$player <- player
    query$eventId <- event_id
    query$oddsFormat <- odds_format
    query$limit <- limit
    query$offset <- offset
  }
  out <- pa_request(
    c(pa_sports_prefix(sandbox), sport, "props"),
    query,
    sandbox = sandbox
  )
  # The endpoint wraps rows in {sport_key, count, props}; return rows.
  if (is.list(out) && !is.null(out$props)) {
    return(out$props)
  }
  out
}

#' Get a historical odds snapshot
#'
#' Fetches the odds board for a sport as it stood at a past timestamp.
#' Requires an API key; ParlayAPI's odds history reaches back to 2005.
#' There is no sandbox equivalent, so this function errors in sandbox
#' mode.
#'
#' @inheritParams pa_odds
#' @param date ISO 8601 timestamp string for the snapshot, e.g.
#'   `"2024-10-19T12:00:00Z"`.
#' @return Parsed snapshot data.
#' @export
#' @examples
#' \dontrun{
#' snap <- pa_historical(
#'   "basketball_nba",
#'   date = "2024-10-19T12:00:00Z",
#'   markets = "h2h"
#' )
#' }
pa_historical <- function(sport,
                          date,
                          regions = "us",
                          markets = "h2h",
                          odds_format = c("decimal", "american"),
                          sandbox = NULL) {
  pa_check_sport(sport)
  odds_format <- match.arg(odds_format)
  if (pa_sandbox_enabled(sandbox)) {
    stop(
      "Historical endpoints have no sandbox equivalent. ",
      "Call pa_historical() with sandbox = FALSE and an API key.",
      call. = FALSE
    )
  }
  pa_request(
    c("v1", "historical", "sports", sport, "odds"),
    list(
      date = date,
      regions = regions,
      markets = markets,
      oddsFormat = odds_format
    )
  )
}

#' Get historical closing odds
#'
#' Fetches closing lines (the final pre-game price, the sharpest single
#' reference point for model calibration and CLV analysis). ParlayAPI
#' carries more than 30 million player prop closing lines since 2022 on
#' top of game closing lines. Requires an API key; errors in sandbox
#' mode.
#'
#' @inheritParams pa_odds
#' @param season Optional season filter, e.g. `"2023"`.
#' @param date Optional single date filter (`"YYYY-MM-DD"`).
#' @param date_from,date_to Optional date range filters.
#' @param player Optional player name filter for prop closing lines.
#' @return Parsed closing-lines data.
#' @export
#' @examples
#' \dontrun{
#' closes <- pa_closing_odds(
#'   "basketball_nba",
#'   markets = "h2h",
#'   date_from = "2024-01-01",
#'   date_to = "2024-01-07"
#' )
#' }
pa_closing_odds <- function(sport,
                            markets = "h2h",
                            bookmakers = NULL,
                            season = NULL,
                            date = NULL,
                            date_from = NULL,
                            date_to = NULL,
                            player = NULL,
                            odds_format = c("american", "decimal"),
                            sandbox = NULL) {
  pa_check_sport(sport)
  odds_format <- match.arg(odds_format)
  if (pa_sandbox_enabled(sandbox)) {
    stop(
      "Historical endpoints have no sandbox equivalent. ",
      "Call pa_closing_odds() with sandbox = FALSE and an API key.",
      call. = FALSE
    )
  }
  pa_request(
    c("v1", "historical", "sports", sport, "closing-odds"),
    list(
      markets = markets,
      bookmakers = bookmakers,
      season = season,
      date = date,
      dateFrom = date_from,
      dateTo = date_to,
      player = player,
      oddsFormat = odds_format
    )
  )
}
