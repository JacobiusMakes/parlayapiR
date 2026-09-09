# Prevent accidental many-to-many joins in R with synthetic sports odds

**Every event, team, bookmaker, and price below is synthetic.** This tutorial runs offline with base R. It needs no API key, package installation, or downloaded dataset.

A join can succeed technically and still create comparisons that make no sense. Imagine two bookmakers quoting the Harbor Owls at both -3.5 and -4.5 points. Joining on the team name produces four combinations. Two pair different handicaps. A later calculation that selects the highest price can then present an attractive number for the wrong selection.

This is a data identity problem before it is a calculation problem. The same mistake appears when joining product variants, laboratory measurements, or repeated survey responses using an incomplete identifier.

## Reproduce the mistake

Save [odds_join.R](odds_join.R) and [test_odds_join.R](test_odds_join.R) together. Run:

```sh
Rscript odds_join.R
Rscript test_odds_join.R
```

Or explore the example interactively:

```r
source("odds_join.R")
q <- synthetic_quotes()

bad <- merge(q$left, q$right, by = "team_name")
bad[c("team_name", "line.x", "line.y")]
```

Both inputs contain two rows for the same display name, so this join produces four rows. Compare `line.x` with `line.y`: two combinations disagree. The row count grew because the key was duplicated on both sides. Nothing in `merge()` knows whether that multiplication was intended.

Do not repair this by taking the first row or calling `unique()` afterward. Neither operation establishes which two selections describe the same thing.

## Define the comparison before joining

For this deliberately narrow point-spread example, the key is:

```r
SPREAD_KEY <- c("event_id", "market", "period", "outcome_id", "line")
```

Each component earns its place. The event distinguishes repeat meetings. The market distinguishes a point spread from a set handicap. The period distinguishes a full match from its first period. The outcome identifies the selected competitor. The signed line distinguishes -3.5 from -4.5, and -3.5 from +3.5.

These identifiers must already refer to the same entities across the two inputs. Source-local event IDs cannot simply be assumed equivalent. Entity resolution is a separate prerequisite, not something a stricter join magically supplies.

Bookmaker identifies the input snapshot rather than the cross-book match key. The helper therefore accepts one book on each side and rejects mixing books within an input.

```r
good <- join_spread_quotes(q$left, q$right)
good[c("line", "decimal_price_left", "decimal_price_right")]
```

The two matching handicaps now produce two rows. The synthetic -3.5 selection pairs 1.91 with 1.95; the -4.5 selection pairs 2.08 with 2.12. Changing a display name does not break the match because display names are not keys.

## Make ambiguity an error

`validate_spread_quotes()` rejects missing identifiers, missing or nonfinite spread lines, invalid decimal prices, and repeated complete keys. Even two duplicate rows with identical prices fail: silently choosing one would conceal an upstream snapshot problem.

This matters because R can match missing join values. Two unknown handicaps are not evidence of the same selection. Reject them before joining. Other market families need their own rules; this helper intentionally rejects anything other than `point_spread`.

There is also a subtle numeric issue: multi-column joins can construct character keys internally. The script encodes finite handicap values as exact hexadecimal floating-point text for matching, then restores the original numeric line. It does not round near-equal lines into equality. Normalize externally only when a documented source contract justifies it.

## Keep the boundary visible

The accompanying tests exercise duplicate keys, opposite signs, nearly equal lines, missing values, different events, different outcomes, and mismatched periods. An inner join omits unmatched selections; an empty result means no exact matches, not that either book has no quotes. Monitor unmatched rows separately when adapting this pattern to a pipeline.

Correct identity establishes comparability only. It does not establish quote availability, recency, execution, or profitability. This example makes no timing claims and carries no real sportsbook data.

Written and reviewed with AI assistance by the ParlayAPI team. For an optional connection to your own account, see the [API documentation](https://parlay-api.com/docs). Private research must use your own credentials and applicable account permissions. This tutorial grants no permission to redistribute API data publicly.
