test_that("kelly matches the closed form", {
  # d = 2.1, p = 0.55: (2.1 * 0.55 - 1) / 1.1 = 0.1409...
  expect_equal(pa_kelly(0.55, 2.1), (2.1 * 0.55 - 1) / 1.1)
  expect_equal(
    pa_kelly(0.55, 110, odds_format = "american"),
    (2.1 * 0.55 - 1) / 1.1
  )
})

test_that("kelly clamps negative edge to zero", {
  expect_equal(pa_kelly(0.40, 2.0), 0)
})

test_that("fractional kelly and bankroll scaling", {
  full <- pa_kelly(0.55, 2.1)
  expect_equal(pa_kelly(0.55, 2.1, fraction = 0.25), full * 0.25)
  expect_equal(
    pa_kelly(0.55, 2.1, fraction = 1, bankroll = 1000),
    full * 1000
  )
})

test_that("kelly is vectorized", {
  out <- pa_kelly(c(0.55, 0.40), c(2.1, 2.0))
  expect_length(out, 2)
  expect_equal(out[2], 0)
})

test_that("kelly input validation", {
  expect_error(pa_kelly(1.1, 2.0), "strictly in")
  expect_error(pa_kelly(0.55, 0.9), "greater than 1")
  expect_error(pa_kelly(0.55, 2.0, fraction = 0), "fraction")
  expect_error(pa_kelly(0.55, 2.0, bankroll = -5), "bankroll")
})
