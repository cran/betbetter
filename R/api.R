# Internal constants -----------------------------------------------------

# League slug -> path segment on the upstream service.
.bb_leagues <- c(
  afl         = "afl",
  mlb         = "mlb",
  nba         = "nba",
  nfl         = "nfl",
  nhl         = "nhl",
  ncaaf       = "ncaaf",
  ufc         = "ufc",
  wnba        = "wnba",
  wta         = "tennis/wta",
  epl         = "soccer/epl",
  laliga      = "soccer/la-liga",
  seriea      = "soccer/serie-a",
  bundesliga  = "soccer/bundesliga",
  ligue1      = "soccer/ligue-1",
  worldcup    = "soccer/world-cup"
)

# Feed kind -> page name.
.bb_feeds <- c(
  picks = "picks",      # game lines and player props, ranked
  games = "best-bets",  # game lines only
  props = "prop-bets"   # player props only
)

.bb_base <- function() {
  getOption("betbetter.base_url", default = "https://betbetter.world")
}

.bb_empty_result <- function() {
  data.frame(
    game              = character(0),
    start_time        = as.POSIXct(character(0), tz = "UTC"),
    market            = character(0),
    selection         = character(0),
    line              = numeric(0),
    model_probability = numeric(0),
    fair_odds         = numeric(0),
    confidence        = character(0),
    verdict           = character(0),
    stringsAsFactors  = FALSE
  )
}

# Perform the request. Per CRAN policy for packages using Internet resources,
# any failure produces an informative message and NULL rather than an error.
.bb_get <- function(url, timeout = 30) {
  parsed <- tryCatch(
    {
      resp <- httr2::req_perform(
        httr2::req_timeout(
          httr2::req_user_agent(
            httr2::request(url),
            "betbetter R package (https://betbetter.world/api/)"
          ),
          timeout
        )
      )
      jsonlite::fromJSON(
        httr2::resp_body_string(resp),
        simplifyVector = TRUE
      )
    },
    error = function(e) {
      message("betbetter: could not reach the API (", conditionMessage(e), ").")
      NULL
    }
  )

  if (is.null(parsed)) {
    return(NULL)
  }
  if (!is.null(parsed$error)) {
    message("betbetter: the API reported a problem (", parsed$error, ").")
    return(NULL)
  }
  parsed
}

.bb_column <- function(df, name, mode = "character") {
  if (!is.null(df[[name]])) {
    return(df[[name]])
  }
  rep(if (mode == "numeric") NA_real_ else NA_character_, nrow(df))
}

# Exported ---------------------------------------------------------------

#' League slugs recognised by the API
#'
#' @return A character vector of league slugs accepted by [bb_picks()].
#' @export
#' @examples
#' bb_leagues()
bb_leagues <- function() {
  names(.bb_leagues)
}

#' Feed types recognised by the API
#'
#' @return A character vector of feed types accepted by [bb_picks()].
#'   `"games"` covers match-level markets, `"props"` covers individual player
#'   markets, and `"picks"` combines both.
#' @export
#' @examples
#' bb_feeds()
bb_feeds <- function() {
  names(.bb_feeds)
}

#' Retrieve model estimates for a league
#'
#' Downloads the model's currently published estimates for upcoming fixtures
#' in one league.
#'
#' @param league A league slug; see [bb_leagues()].
#' @param feed Which markets to retrieve; see [bb_feeds()]. Defaults to
#'   `"picks"`.
#' @param min_probability Optional lower bound, between 0 and 1. Selections the
#'   model estimates below this probability are dropped.
#' @param limit Optional maximum number of rows to return.
#'
#' @return A data frame with one row per rated selection and the columns
#'   `game`, `start_time` (UTC), `market`, `selection`, `line`,
#'   `model_probability` (a proportion between 0 and 1), `fair_odds`
#'   (decimal odds implied by `model_probability`), `confidence` and `verdict`.
#'   A zero-row data frame is returned when the league has no upcoming
#'   fixtures, which is normal outside its season. `NULL` is returned, with a
#'   message, if the API cannot be reached.
#'
#' @details
#' `fair_odds` is the break-even price implied by the model's own probability.
#' It is not a bookmaker price, and no bookmaker price is available through
#' this package.
#'
#' @export
#' @examples
#' \donttest{
#' afl <- bb_picks("afl", limit = 5)
#' if (!is.null(afl) && nrow(afl) > 0) {
#'   afl[, c("game", "selection", "model_probability", "confidence")]
#' }
#' }
bb_picks <- function(league,
                     feed = "picks",
                     min_probability = NULL,
                     limit = NULL) {
  if (!is.character(league) || length(league) != 1L || is.na(league)) {
    stop("`league` must be a single league slug; see bb_leagues().", call. = FALSE)
  }
  if (!league %in% names(.bb_leagues)) {
    stop("Unknown league \"", league, "\". See bb_leagues() for valid values.",
         call. = FALSE)
  }
  feed <- match.arg(feed, names(.bb_feeds))
  if (!is.null(min_probability)) {
    if (!is.numeric(min_probability) || length(min_probability) != 1L ||
        is.na(min_probability) || min_probability < 0 || min_probability > 1) {
      stop("`min_probability` must be a single number between 0 and 1.",
           call. = FALSE)
    }
  }
  if (!is.null(limit)) {
    if (!is.numeric(limit) || length(limit) != 1L || is.na(limit) || limit < 1) {
      stop("`limit` must be a single positive number.", call. = FALSE)
    }
  }

  url <- paste0(
    .bb_base(), "/", .bb_leagues[[league]], "/", .bb_feeds[[feed]],
    ".aspx?format=json"
  )
  parsed <- .bb_get(url)
  if (is.null(parsed)) {
    return(NULL)
  }

  # The combined and game feeds return "picks"; the prop-only feed returns
  # "props". Either may be absent when nothing is scheduled.
  rows <- parsed$picks
  if (is.null(rows) || length(rows) == 0L) {
    rows <- parsed$props
  }
  if (is.null(rows) || length(rows) == 0L) {
    return(.bb_empty_result())
  }
  rows <- as.data.frame(rows, stringsAsFactors = FALSE)

  pct <- suppressWarnings(as.numeric(.bb_column(rows, "modelProbabilityPct", "numeric")))
  out <- data.frame(
    game              = .bb_column(rows, "game"),
    start_time        = as.POSIXct(.bb_column(rows, "gameTimeUtc"),
                                   format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC"),
    market            = .bb_column(rows, "market"),
    selection         = .bb_column(rows, "selection"),
    line              = suppressWarnings(as.numeric(.bb_column(rows, "line", "numeric"))),
    model_probability = pct / 100,
    fair_odds         = suppressWarnings(as.numeric(.bb_column(rows, "fairOdds", "numeric"))),
    confidence        = .bb_column(rows, "confidence"),
    verdict           = .bb_column(rows, "verdict"),
    stringsAsFactors  = FALSE
  )

  if (!is.null(min_probability)) {
    keep <- !is.na(out$model_probability) & out$model_probability >= min_probability
    out <- out[keep, , drop = FALSE]
  }
  out <- out[order(-out$model_probability), , drop = FALSE]
  if (!is.null(limit) && nrow(out) > limit) {
    out <- out[seq_len(limit), , drop = FALSE]
  }
  rownames(out) <- NULL
  out
}
