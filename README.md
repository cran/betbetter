# betbetter

An R client for the [Bet Better open sports model API](https://betbetter.world/api/) —
free, no API key, no registration.

For each upcoming fixture the API publishes a statistical model's estimated
probability that a selection occurs, and the decimal odds that probability
implies. Fifteen competitions are covered across eight sports.

## Installation

```r
# install.packages("remotes")
remotes::install_github("edushinka/betbetter-r")
```

## Usage

```r
library(betbetter)

bb_leagues()
#>  [1] "afl" "mlb" "nba" "nfl" "nhl" "ncaaf" "ufc" "wnba" "wta" "epl"
#> [11] "laliga" "seriea" "bundesliga" "ligue1" "worldcup"

afl <- bb_picks("afl")
head(afl[, c("game", "selection", "model_probability", "fair_odds", "confidence")])
```

| Argument | Purpose |
|---|---|
| `league` | League slug, e.g. `"afl"`, `"nba"`, `"epl"` |
| `feed` | `"picks"` (all), `"games"` (match markets), `"props"` (player markets) |
| `min_probability` | Drop selections estimated below this, 0–1 |
| `limit` | Maximum rows returned |

## Returned columns

| Column | Meaning |
|---|---|
| `game` | Fixture, `Away @ Home` |
| `start_time` | Scheduled start, UTC |
| `market` | Head to Head, Spread, Total Points, player markets… |
| `selection` | The team, player or outcome estimated |
| `line` | Handicap or total the selection is measured against |
| `model_probability` | Estimated chance the selection occurs, 0–1 |
| `fair_odds` | Decimal odds implied by `model_probability` |
| `confidence` | `HIGH`, `LEAN` or `LONG-SHOT` |
| `verdict` | One-sentence plain-English summary |

## What this package cannot do

**It returns no bookmaker prices.** There is no bookmaker identity, market price
or market-implied probability in the API, and none can be added — the upstream
odds licence permits publishing derived work but not redistribution of the price
feed. Everything here is the model's own output.

## Behaviour you should expect

- A league outside its season returns a **zero-row data frame**. That is normal.
- If the API is unreachable, `bb_picks()` emits a message and returns `NULL`
  rather than raising an error, so unattended scripts degrade gracefully.
- Responses are cached upstream for 15 minutes.

## Interpreting the estimates

These are model estimates, not statements of certainty. A selection estimated at
70% is expected to fail roughly three times in ten. Treat a losing run at that
probability as ordinary variance rather than evidence of a broken model.

## Licence

MIT for this package. Data retrieved through it is published under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) and requires
attribution to Bet Better (<https://betbetter.world>) when redistributed.
