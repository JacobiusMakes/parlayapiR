# Live tests against the keyless sandbox endpoints. Skipped on CRAN
# and whenever the machine is offline, per CRAN policy on network use.

test_that("sandbox sports catalog is reachable and shaped", {
  skip_on_cran()
  skip_if_offline("parlay-api.com")
  sports <- pa_sports(sandbox = TRUE)
  expect_s3_class(sports, "data.frame")
  expect_true(all(c("key", "title", "active") %in% names(sports)))
  expect_true("basketball_nba" %in% sports$key)
})

test_that("sandbox odds return TOA-shaped events", {
  skip_on_cran()
  skip_if_offline("parlay-api.com")
  events <- pa_odds("basketball_nba", markets = "h2h", sandbox = TRUE)
  expect_s3_class(events, "data.frame")
  expect_true(all(
    c("home_team", "away_team", "commence_time", "bookmakers") %in%
      names(events)
  ))
  books <- events$bookmakers[[1]]
  expect_true(all(c("key", "markets") %in% names(books)))
})

test_that("sandbox props return a flat quote table", {
  skip_on_cran()
  skip_if_offline("parlay-api.com")
  props <- pa_props("basketball_nba", sandbox = TRUE)
  expect_s3_class(props, "data.frame")
  expect_true(all(
    c("bookmaker", "player_name", "market_key", "line", "over_price",
      "under_price") %in% names(props)
  ))
  expect_gt(nrow(props), 0)
})
