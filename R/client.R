# Internal HTTP plumbing. All request functions funnel through
# pa_request(), which handles base URL, auth header, query assembly,
# error reporting, and JSON parsing.

pa_base_url <- function() {
  url <- Sys.getenv("PARLAY_API_BASE_URL", "")
  if (nzchar(url)) {
    return(url)
  }
  getOption("parlayapiR.base_url", "https://parlay-api.com")
}

pa_user_agent <- function() {
  "parlayapiR/0.1.0 (https://github.com/JacobiusMakes/parlayapiR)"
}

# Drop NULL query params and collapse vectors to comma-separated
# strings, which is what the API expects for list-like params such as
# markets and bookmakers.
pa_clean_query <- function(query) {
  query <- query[!vapply(query, is.null, logical(1))]
  lapply(query, function(x) {
    if (is.logical(x)) {
      return(tolower(as.character(x)))
    }
    paste(as.character(x), collapse = ",")
  })
}

pa_error_body <- function(resp) {
  msg <- tryCatch(
    {
      parsed <- jsonlite::fromJSON(
        httr2::resp_body_string(resp),
        simplifyVector = FALSE
      )
      detail <- parsed$detail
      if (is.list(detail) && !is.null(detail$message)) {
        detail$message
      } else if (is.character(detail)) {
        detail
      } else if (!is.null(parsed$message)) {
        parsed$message
      } else {
        NULL
      }
    },
    error = function(e) NULL
  )
  status <- httr2::resp_status(resp)
  out <- character(0)
  if (!is.null(msg)) {
    out <- c(out, paste0("ParlayAPI said: ", msg))
  }
  if (status == 401L) {
    out <- c(
      out,
      paste0(
        "Set a key with pa_auth(\"...\") or the PARLAY_API_KEY ",
        "environment variable, or call pa_sandbox(TRUE) to use the ",
        "keyless sandbox endpoints."
      )
    )
  }
  out
}

# path: character vector of URL path segments (already ordered).
# query: named list of query parameters; NULLs are dropped.
# sandbox: logical, resolved sandbox flag for this call.
# Returns parsed JSON (data frames where the payload is tabular).
pa_request <- function(path, query = list(), sandbox = FALSE) {
  req <- httr2::request(pa_base_url())
  req <- httr2::req_url_path_append(req, paste(path, collapse = "/"))
  query <- pa_clean_query(query)
  if (length(query)) {
    req <- do.call(httr2::req_url_query, c(list(req), query))
  }
  key <- pa_key()
  if (nzchar(key) && !sandbox) {
    req <- httr2::req_headers(req, `X-API-Key` = key, .redact = "X-API-Key")
  }
  req <- httr2::req_user_agent(req, pa_user_agent())
  req <- httr2::req_timeout(req, 30)
  req <- httr2::req_retry(req, max_tries = 2)
  req <- httr2::req_error(req, body = pa_error_body)
  resp <- httr2::req_perform(req)
  jsonlite::fromJSON(
    httr2::resp_body_string(resp),
    simplifyVector = TRUE,
    simplifyDataFrame = TRUE
  )
}

# Path prefix for live vs sandbox sport endpoints.
pa_sports_prefix <- function(sandbox) {
  if (sandbox) {
    c("v1", "sandbox", "sports")
  } else {
    c("v1", "sports")
  }
}

pa_check_sport <- function(sport) {
  if (!is.character(sport) || length(sport) != 1L || !nzchar(sport)) {
    stop(
      "`sport` must be a single sport key string, e.g. \"basketball_nba\". ",
      "See pa_sports() for the full list.",
      call. = FALSE
    )
  }
  invisible(sport)
}
