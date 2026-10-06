test_that("league and feed vocabularies are exposed", {
  expect_type(bb_leagues(), "character")
  expect_true("afl" %in% bb_leagues())
  expect_true("wta" %in% bb_leagues())
  expect_setequal(bb_feeds(), c("picks", "games", "props"))
})

test_that("invalid arguments are rejected before any request is made", {
  expect_error(bb_picks("quidditch"), "Unknown league")
  expect_error(bb_picks(c("afl", "nba")), "single league slug")
  expect_error(bb_picks("afl", feed = "nonsense"))
  expect_error(bb_picks("afl", min_probability = 7), "between 0 and 1")
  expect_error(bb_picks("afl", limit = 0), "positive number")
})

test_that("an unreachable API yields a message and NULL, not an error", {
  # CRAN policy requires graceful degradation when a remote resource is down.
  withr_base <- getOption("betbetter.base_url")
  options(betbetter.base_url = "https://betbetter.invalid")
  on.exit(options(betbetter.base_url = withr_base), add = TRUE)

  expect_message(result <- bb_picks("afl"), "could not reach the API")
  expect_null(result)
})

test_that("live feed returns the documented shape", {
  skip_on_cran()
  skip_if_offline()

  result <- bb_picks("afl", limit = 5)
  skip_if(is.null(result), "API unreachable")

  expect_s3_class(result, "data.frame")
  expect_named(
    result,
    c("game", "start_time", "market", "selection", "line",
      "model_probability", "fair_odds", "confidence", "verdict")
  )

  if (nrow(result) > 0) {
    expect_lte(nrow(result), 5)
    expect_true(all(result$model_probability >= 0, na.rm = TRUE))
    expect_true(all(result$model_probability <= 1, na.rm = TRUE))
    expect_s3_class(result$start_time, "POSIXct")
  }
})

test_that("min_probability filters and limit truncates", {
  skip_on_cran()
  skip_if_offline()

  result <- bb_picks("afl", min_probability = 0.6, limit = 3)
  skip_if(is.null(result), "API unreachable")

  expect_lte(nrow(result), 3)
  if (nrow(result) > 0) {
    expect_true(all(result$model_probability >= 0.6))
  }
})
