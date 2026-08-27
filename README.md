# parlayapiR

<!-- badges: start -->
[![R-CMD-check](https://github.com/JacobiusMakes/parlayapiR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/JacobiusMakes/parlayapiR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

R client for [ParlayAPI](https://parlay-api.com), a real-time sports
odds API covering 30+ sportsbooks, with player props, historical odds
from 2005, and 30M+ prop closing lines since 2022. The package mirrors
the core of the official Python SDK (`pip install parlay-api`) and adds
the two local calculations every betting model needs: devigging and
Kelly sizing.

Built for the R modeling community: everything returns plain data
frames, the math functions are pure R with no network dependency, and a
sandbox mode lets you run every example, test, and the vignette without
an API key.

## Installation

Not on CRAN yet (see [CRAN.md](CRAN.md) for the submission runbook).
Install from GitHub:

```r
# install.packages("pak")
pak::pak("JacobiusMakes/parlayapiR")

# or
# install.packages("remotes")
remotes::install_github("JacobiusMakes/parlayapiR")
```

## Quickstart, no key needed

Sandbox mode routes requests to keyless `/v1/sandbox/` endpoints that
serve synthetic but structurally identical data:

```r
library(parlayapiR)

pa_sports(sandbox = TRUE)

events <- pa_odds("basketball_nba", markets = "h2h", sandbox = TRUE)
events$home_team

props <- pa_props("basketball_nba", sandbox = TRUE)
head(props[, c("bookmaker", "player_name", "market_key", "line",
               "over_price", "under_price")])
```

The math functions never touch the network at all:

```r
# Remove the bookmaker margin from a -110 / -110 market
pa_devig(c(-110, -110), odds_format = "american")
#>     implied fair_prob fair_decimal
#> 1 0.5238095       0.5            2
#> 2 0.5238095       0.5            2

# Three-way market, power method (shrinks long shots harder)
pa_devig(c(2.45, 3.40, 3.10), method = "power")

# Kelly stake: 55% win probability at +110, quarter Kelly, 1000 bankroll
pa_kelly(0.55, +110, odds_format = "american", fraction = 0.25,
         bankroll = 1000)
```

## Going live

Get a free key at [parlay-api.com](https://parlay-api.com) (1,000
credits per month, no card required; paid tiers are listed at
[parlay-api.com/pricing](https://parlay-api.com/pricing)). Then:

```r
pa_auth("your-api-key")   # or set PARLAY_API_KEY in .Renviron

events <- pa_odds("basketball_nba", markets = "h2h,spreads,totals")
props  <- pa_props("baseball_mlb", markets = "player_strikeouts")

# Historical snapshot of the board (history back to 2005)
snap <- pa_historical("basketball_nba", date = "2024-10-19T12:00:00Z")

# Closing lines, the calibration target for backtests
closes <- pa_closing_odds("basketball_nba", season = "2024")
```

## Functions

| Function | What it does |
|---|---|
| `pa_sports()` | List available sports |
| `pa_odds()` | Game odds across books, The Odds API v4 event shape |
| `pa_props()` | Player props as a flat over/under quote table |
| `pa_historical()` | Historical odds snapshot at a timestamp |
| `pa_closing_odds()` | Historical closing lines, including prop closes |
| `pa_devig()` | Remove the vig: multiplicative, additive, or power |
| `pa_kelly()` | Kelly criterion stake sizing (vectorized, clamped at 0) |
| `pa_implied_prob()`, `pa_american_to_decimal()`, `pa_decimal_to_american()` | Odds conversions |
| `pa_auth()`, `pa_sandbox()` | Key management and sandbox toggle |

The vignette walks through a full workflow on sandbox data:

```r
vignette("line-shopping-and-devigging", package = "parlayapiR")
```

## The Odds API compatibility

`pa_odds()` returns the same event shape as The Odds API v4 (events
containing `bookmakers`, then `markets`, then `outcomes`) and takes the
same query parameters (`regions`, `markets`, `oddsFormat`,
`bookmakers`). TOA's v4 shape is the de facto standard for odds data
and their documentation is excellent, so parsing code written against
it, including code written for CRAN's `oddsapiR` package, carries over
with minimal changes. If you already have a TOA pipeline in R, the
migration is the base URL and the key.

## Notes for modelers

- `pa_devig()` implements the multiplicative, additive, and power
  methods and returns the overround as an attribute. For a broader set
  of devigging methods (Shin, odds ratio, and others), see the
  `implied` package on CRAN; the two compose fine since `pa_devig()`
  accepts raw probabilities too.
- `pa_kelly()` matches the semantics of the keyless
  `/v1/calc/kelly` endpoint, including clamping negative-edge stakes
  to zero.
- WebSocket streaming exists on the API (Business tier and up) but is
  not wrapped here; this package is deliberately plain HTTP.

## License

MIT. R packages are often GPL-licensed by tradition, but MIT is fully
CRAN-compatible (via the standard `MIT + file LICENSE` template) and
matches the rest of the ParlayAPI SDK family.
