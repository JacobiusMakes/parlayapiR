source("replay.R")
log <- example_log()
at <- function(s, rows = log, key = "home") quote_at(rows, key, example_start() + s)

stopifnot(at(0)$state == "unseen", is.na(at(0)$price),
          at(4)$price == 1.90, at(6)$price == 2.10, at(7)$price == 2.10,
          at(9)$state == "withdrawn", is.na(at(9)$price), at(11)$price == 1.97,
          at(4, key = "away")$price == 1.80, at(12, key = "missing")$state == "unseen")

# Later arrivals cannot change an earlier decision. Arrival order in the file
# also cannot change an answer, even when source updates arrive out of order.
stopifnot(identical(at(4), at(4, log[log$received <= example_start() + 4, ])),
          identical(at(7), at(7, log[nrow(log):1, ])))
copy <- log[3, ]
copy$received <- example_start() + 7
stopifnot(identical(at(7), at(7, rbind(log, copy))))
copy$price <- 2.20
conflicting <- rbind(log, copy)
stopifnot(at(6, conflicting)$price == 2.10, at(7, conflicting)$state == "conflict",
          is.na(at(7, conflicting)$price), at(9, conflicting)$state == "withdrawn")
copy$received <- example_start() + 10
stopifnot(at(10, rbind(log, copy))$state == "withdrawn")

bad <- log
bad$received[1] <- bad$updated[1] - 1
stopifnot(inherits(try(at(4, bad), silent = TRUE), "try-error"))
bad$received[1] <- as.POSIXct(NA)
stopifnot(inherits(try(at(4, bad), silent = TRUE), "try-error"))
cat("Point-in-time replay checks passed.\n")
