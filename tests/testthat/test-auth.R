test_that("pa_auth sets and reports the key", {
  old <- Sys.getenv("PARLAY_API_KEY", unset = NA)
  on.exit({
    if (is.na(old)) {
      Sys.unsetenv("PARLAY_API_KEY")
    } else {
      Sys.setenv(PARLAY_API_KEY = old)
    }
  })
  Sys.unsetenv("PARLAY_API_KEY")
  expect_message(res <- pa_auth(), "not set")
  expect_false(res)
  expect_message(pa_auth("test-key-123"), "set for this session")
  expect_message(res <- pa_auth(), "is set")
  expect_true(res)
  expect_error(pa_auth(42), "single non-empty string")
})

test_that("pa_sandbox toggles and restores", {
  old <- pa_sandbox(TRUE)
  expect_true(getOption("parlayapiR.sandbox"))
  pa_sandbox(FALSE)
  expect_false(getOption("parlayapiR.sandbox"))
  options(parlayapiR.sandbox = old)
  expect_error(pa_sandbox("yes"), "TRUE or FALSE")
})

test_that("historical functions refuse sandbox mode", {
  expect_error(
    pa_historical("basketball_nba", date = "2024-01-01", sandbox = TRUE),
    "no sandbox equivalent"
  )
  expect_error(
    pa_closing_odds("basketball_nba", sandbox = TRUE),
    "no sandbox equivalent"
  )
})

test_that("sport key validation", {
  expect_error(pa_odds(""), "sport key")
  expect_error(pa_props(NULL), "sport key")
})
