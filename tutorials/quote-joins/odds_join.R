# All example rows are synthetic. No API key, network, or packages are required.
# Scope: one snapshot per book containing point-spread outcome quotes.
# Exact numeric line equality is intentional: do not round distinct handicaps.
SPREAD_KEY <- c("event_id", "market", "period", "outcome_id", "line")

# Hexadecimal floating-point text preserves exact numeric identity in multi-key
# merge(), which otherwise constructs character keys internally. Normalize -0.
line_identity <- function(line) {
  line[line == 0] <- 0
  sprintf("%a", as.double(line))
}

validate_spread_quotes <- function(quotes, label = "quotes") {
  if (!is.data.frame(quotes)) stop(label, ": expected a data frame", call. = FALSE)
  needed <- c(SPREAD_KEY, "book", "decimal_price")
  if (anyDuplicated(names(quotes)) || !all(needed %in% names(quotes))) {
    stop(label, ": required columns must exist with unique names", call. = FALSE)
  }
  identities <- c("event_id", "market", "period", "outcome_id", "book")
  for (column in identities) {
    value <- quotes[[column]]
    if (!is.character(value) || anyNA(value) || any(!nzchar(trimws(value))) || any(grepl("[[:cntrl:]]", value))) {
      stop(label, ": ", column, " must contain nonempty character identities",
           call. = FALSE)
    }
  }
  if (any(quotes$market != "point_spread")) {
    stop(label, ": this example only accepts point_spread quotes", call. = FALSE)
  }
  if (!is.numeric(quotes$line) || anyNA(quotes$line) ||
      any(!is.finite(quotes$line))) {
    stop(label, ": spread lines must be finite numbers, never missing", call. = FALSE)
  }
  if (!is.numeric(quotes$decimal_price) || anyNA(quotes$decimal_price) ||
      any(!is.finite(quotes$decimal_price)) || any(quotes$decimal_price <= 1)) {
    stop(label, ": decimal_price must be finite and greater than one", call. = FALSE)
  }
  if (length(unique(quotes$book)) > 1L) {
    stop(label, ": supply one book per input snapshot", call. = FALSE)
  }
  identity <- quotes[SPREAD_KEY]
  identity$line <- line_identity(identity$line)
  if (anyDuplicated(identity)) {
    stop(label, ": duplicate quote identity; resolve the snapshot before joining",
         call. = FALSE)
  }
  invisible(quotes)
}

join_spread_quotes <- function(left, right) {
  validate_spread_quotes(left, "left")
  validate_spread_quotes(right, "right")
  if (nrow(left) && nrow(right) && left$book[1L] == right$book[1L]) {
    stop("Choose two different books", call. = FALSE)
  }
  # Select explicit columns so display names can never become implicit join keys.
  columns <- c(SPREAD_KEY, "book", "decimal_price")
  left_keys <- left[columns]
  right_keys <- right[columns]
  left_keys$line <- line_identity(left$line)
  right_keys$line <- line_identity(right$line)
  result <- merge(left_keys, right_keys, by = SPREAD_KEY, all = FALSE,
                  suffixes = c("_left", "_right"), sort = TRUE)
  result$line <- left$line[match(result$line, left_keys$line)]
  result
}

synthetic_quotes <- function() {
  # Fictional competitors, books, event, and prices. This is not a live dataset.
  left <- data.frame(
    event_id = rep("synthetic_event_001", 2),
    market = rep("point_spread", 2),
    period = rep("full_match", 2),
    outcome_id = rep("synthetic_team_harbor", 2),
    team_name = rep("Harbor Owls", 2),
    line = c(-3.5, -4.5),
    book = rep("Synthetic Book A", 2),
    decimal_price = c(1.91, 2.08),
    stringsAsFactors = FALSE
  )
  right <- left
  right$book <- "Synthetic Book B"
  right$decimal_price <- c(1.95, 2.12)
  list(left = left, right = right)
}

run_demo <- function() {
  quotes <- synthetic_quotes()
  naive <- merge(quotes$left, quotes$right, by = "team_name")
  exact <- join_spread_quotes(quotes$left, quotes$right)
  cat("ALL DATA SYNTHETIC\n")
  cat("Team-name join:", nrow(naive), "rows;", sum(naive$line.x != naive$line.y),
      "pair different handicaps.\n")
  cat("Exact identity join:", nrow(exact), "rows.\n")
  print(exact, row.names = FALSE)
  invisible(exact)
}

# Sourcing defines helpers without printing; Rscript odds_join.R runs the demo.
if (sys.nframe() == 0L) run_demo()
