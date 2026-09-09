# Offline, base-R tests. Run: Rscript test_odds_join.R
arguments <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", arguments[grepl("^--file=", arguments)])
if (length(script) != 1L) stop("Run this file with Rscript")
source(file.path(dirname(normalizePath(script)), "odds_join.R"))

checks <- 0L
check <- function(condition) {
  stopifnot(isTRUE(condition))
  checks <<- checks + 1L
}
expect_error <- function(expression, pattern) {
  message <- tryCatch({ force(expression); NULL }, error = conditionMessage)
  check(!is.null(message) && grepl(pattern, message, fixed = TRUE))
}
q <- synthetic_quotes()
naive <- merge(q$left, q$right, by = "team_name")
check(nrow(naive) == 4L)
check(sum(naive$line.x != naive$line.y) == 2L)
joined <- join_spread_quotes(q$left, q$right)
check(nrow(joined) == 2L)
check(identical(sort(joined$line), c(-4.5, -3.5)))
check(joined$decimal_price_right[joined$line == -3.5] == 1.95)
check(joined$decimal_price_left[joined$line == -4.5] == 2.08)

# Display text is irrelevant when stable identities agree.
changed <- q$right
changed$team_name <- "H. Owls"
check(nrow(join_spread_quotes(q$left, changed)) == 2L)

# Same display names never rescue a mismatched identity.
for (column in c("event_id", "period", "outcome_id")) {
  changed <- q$right
  changed[[column]] <- paste0("different_", changed[[column]])
  check(nrow(join_spread_quotes(q$left, changed)) == 0L)
}
changed <- q$right
changed$line <- c(3.5, 4.5)
check(nrow(join_spread_quotes(q$left, changed)) == 0L)
changed$line <- q$right$line + .Machine$double.eps * 4
check(nrow(join_spread_quotes(q$left, changed)) == 0L)
changed <- q$right
changed$market <- "set_handicap"
expect_error(join_spread_quotes(q$left, changed), "only accepts point_spread")

# Never let missing values match missing values as if they were valid lines.
for (bad_line in list(NA_real_, NaN, Inf, -Inf, "-3.5")) {
  left <- q$left
  right <- q$right
  left$line[1L] <- bad_line
  right$line[1L] <- bad_line
  expect_error(join_spread_quotes(left, right), "spread lines")
}
for (column in c("event_id", "market", "period", "outcome_id", "book")) {
  changed <- q$right
  changed[[column]][1L] <- NA_character_
  expect_error(join_spread_quotes(q$left, changed), "nonempty character identities")
}
changed <- q$right
changed$period[1L] <- " "
expect_error(join_spread_quotes(q$left, changed), "nonempty character identities")

# Multi-column merge uses a control-character separator internally.
changed <- q$right
changed$event_id[1L] <- "event\rperiod"
expect_error(join_spread_quotes(q$left, changed), "character identities")

# Duplicate identical or conflicting prices are both ambiguous snapshot rows.
for (side in c("left", "right")) {
  for (price in c(1.95, 9.99)) {
    copy <- q
    duplicate <- copy[[side]][1L, ]
    duplicate$decimal_price <- price
    copy[[side]] <- rbind(copy[[side]], duplicate)
    expect_error(join_spread_quotes(copy$left, copy$right), "duplicate quote identity")
  }
}
changed <- q$right
changed$book[1L] <- "Synthetic Book C"
expect_error(join_spread_quotes(q$left, changed), "one book per input")
expect_error(join_spread_quotes(q$left, q$left), "two different books")
for (bad_price in c(NA_real_, Inf, 1, 0, -1)) {
  changed <- q$right
  changed$decimal_price[1L] <- bad_price
  expect_error(join_spread_quotes(q$left, changed), "decimal_price")
}
changed <- q$right
changed$line <- NULL
expect_error(join_spread_quotes(q$left, changed), "required columns")
changed <- q$right
names(changed)[names(changed) == "team_name"] <- "line"
expect_error(join_spread_quotes(q$left, changed), "required columns")
left_zero <- q$left[1L, ]
right_zero <- q$right[1L, ]
left_zero$line <- 0
right_zero$line <- -0
check(nrow(join_spread_quotes(left_zero, right_zero)) == 1L)
check(nrow(join_spread_quotes(q$left[FALSE, ], q$right)) == 0L)
check(nrow(join_spread_quotes(q$left, q$right[2:1, ])) == 2L)
cat(checks, "checks passed; all fixtures synthetic; no network used.\n")
