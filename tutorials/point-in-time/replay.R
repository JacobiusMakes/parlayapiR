# A stream identifies one fixture, bookmaker, market, period and selection.
# All observations in this example are invented. Times are UTC.
example_start <- function() as.POSIXct("2026-10-01 14:00:00", tz = "UTC")

example_log <- function() {
  t0 <- example_start()
  data.frame(
    stream = c("home", "away", "home", "home", "home", "home"),
    updated = t0 + c(1, 2, 3, 2, 8, 10),
    received = t0 + c(2, 3, 6, 7, 9, 11),
    state = c("quoted", "quoted", "quoted", "quoted", "withdrawn", "quoted"),
    price = c(1.90, 1.80, 2.10, 1.85, NA_real_, 1.97),
    stringsAsFactors = FALSE
  )
}

quote_at <- function(log, stream, cutoff) {
  stopifnot(is.data.frame(log),
            all(c("stream", "updated", "received", "state", "price") %in% names(log)),
            is.character(stream), length(stream) == 1L, !is.na(stream), nzchar(stream),
            inherits(cutoff, "POSIXct"), length(cutoff) == 1L, is.finite(cutoff),
            inherits(log$updated, "POSIXct"), inherits(log$received, "POSIXct"),
            all(is.finite(log$updated)), all(is.finite(log$received)),
            all(log$received >= log$updated), !anyNA(log$stream),
            all(nzchar(log$stream)), all(log$state %in% c("quoted", "withdrawn")),
            is.numeric(log$price))
  quoted <- log$state == "quoted"
  stopifnot(all(is.finite(log$price[quoted]) & log$price[quoted] > 1),
            all(is.na(log$price[!quoted])))

  known <- log[log$stream == stream & log$received <= cutoff, , drop = FALSE]
  result <- data.frame(stream = stream, cutoff = cutoff, state = "unseen",
                       updated = as.POSIXct(NA_real_, origin = "1970-01-01", tz = "UTC"),
                       price = NA_real_, stringsAsFactors = FALSE)
  if (!nrow(known)) return(result)

  result$updated <- max(known$updated)
  latest <- known[known$updated == result$updated, , drop = FALSE]
  states <- unique(latest[c("state", "price")])
  if (nrow(states) > 1L) {
    result$state <- "conflict"
    return(result)
  }
  result$state <- states$state
  result$price <- states$price
  result
}

if (sys.nframe() == 0L) {
  log <- example_log()
  replay <- lapply(c(0, 4, 6, 7, 9, 11), function(s) {
    quote_at(log, "home", example_start() + s)
  })
  print(do.call(rbind, replay), row.names = FALSE)
}
