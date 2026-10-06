## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>", eval = FALSE)

## ----setup--------------------------------------------------------------------
# library(betbetter)

## -----------------------------------------------------------------------------
# bb_leagues()

## -----------------------------------------------------------------------------
# afl <- bb_picks("afl")
# head(afl[, c("game", "market", "selection", "model_probability", "fair_odds")])

## -----------------------------------------------------------------------------
# strong <- bb_picks("afl", min_probability = 0.7, limit = 10)

## -----------------------------------------------------------------------------
# lines <- bb_picks("afl", feed = "games")
# props <- bb_picks("afl", feed = "props")

## -----------------------------------------------------------------------------
# nrow(bb_picks("nfl"))  # 0 during the off-season

## -----------------------------------------------------------------------------
# result <- bb_picks("afl")
# if (is.null(result)) {
#   message("API unavailable, skipping")
# }

