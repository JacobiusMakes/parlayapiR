test_that("symmetric market devigs to 50/50 under every method", {
  for (m in c("multiplicative", "additive", "power")) {
    out <- pa_devig(c(-110, -110), odds_format = "american", method = m)
    expect_equal(out$fair_prob, c(0.5, 0.5), tolerance = 1e-8)
    expect_equal(out$fair_decimal, c(2, 2), tolerance = 1e-8)
  }
})

test_that("fair probabilities sum to 1", {
  odds <- c(2.45, 3.40, 3.10)
  for (m in c("multiplicative", "additive", "power")) {
    out <- pa_devig(odds, method = m)
    expect_equal(sum(out$fair_prob), 1, tolerance = 1e-8)
  }
})

test_that("multiplicative method matches hand computation", {
  probs <- c(0.55, 0.52)
  out <- pa_devig(probs = probs)
  expect_equal(out$fair_prob, probs / sum(probs))
  expect_equal(attr(out, "overround"), 0.07, tolerance = 1e-12)
})

test_that("additive method subtracts equal shares", {
  probs <- c(0.55, 0.52)
  out <- pa_devig(probs = probs, method = "additive")
  expect_equal(out$fair_prob, probs - 0.035, tolerance = 1e-12)
})

test_that("power method shrinks long shots more than multiplicative", {
  odds <- c(1.30, 11.0)
  mult <- pa_devig(odds, method = "multiplicative")
  pow <- pa_devig(odds, method = "power")
  # The long shot (second outcome) gets a smaller fair probability
  # under the power method.
  expect_lt(pow$fair_prob[2], mult$fair_prob[2])
  expect_gt(pow$fair_prob[1], mult$fair_prob[1])
})

test_that("additive warns on non-positive probabilities", {
  expect_warning(
    pa_devig(probs = c(0.90, 0.60, 0.02), method = "additive"),
    "non-positive"
  )
})

test_that("devig input validation", {
  expect_error(pa_devig(), "exactly one")
  expect_error(pa_devig(odds = 2, probs = 0.5), "exactly one")
  expect_error(pa_devig(probs = 0.5), "at least two")
  expect_error(pa_devig(probs = c(0.5, 1.2)), "between 0 and 1")
})
