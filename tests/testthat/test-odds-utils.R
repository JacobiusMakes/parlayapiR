test_that("american to decimal conversion is correct", {
  expect_equal(pa_american_to_decimal(100), 2)
  expect_equal(pa_american_to_decimal(-100), 2)
  expect_equal(pa_american_to_decimal(150), 2.5)
  expect_equal(pa_american_to_decimal(-110), 1 + 100 / 110)
  expect_equal(pa_american_to_decimal(-200), 1.5)
})

test_that("decimal to american conversion is correct", {
  expect_equal(pa_decimal_to_american(2.5), 150)
  expect_equal(pa_decimal_to_american(2), 100)
  expect_equal(pa_decimal_to_american(1.5), -200)
})

test_that("conversions round trip", {
  am <- c(-350, -110, -101, 100, 125, 900)
  expect_equal(pa_decimal_to_american(pa_american_to_decimal(am)), am)
})

test_that("implied probability is 1 over decimal odds", {
  expect_equal(pa_implied_prob(2), 0.5)
  expect_equal(pa_implied_prob(4), 0.25)
  expect_equal(
    pa_implied_prob(-110, odds_format = "american"),
    110 / 210
  )
})

test_that("conversion input validation", {
  expect_error(pa_american_to_decimal(50), "American odds")
  expect_error(pa_decimal_to_american(0.9), "greater than 1")
  expect_error(pa_implied_prob(1), "greater than 1")
  expect_error(pa_american_to_decimal("x"), "numeric")
})
