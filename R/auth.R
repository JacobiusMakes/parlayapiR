#' Set or check the ParlayAPI key
#'
#' Stores an API key in the `PARLAY_API_KEY` environment variable for the
#' current R session. All keyed endpoints read the key from that
#' variable, so you can also set it once in your `.Renviron` file and
#' never call `pa_auth()` at all.
#'
#' Called with no arguments, `pa_auth()` reports whether a key is
#' currently set (without printing it).
#'
#' @param key Character API key from your
#'   [parlay-api.com](https://parlay-api.com) dashboard, or `NULL` to
#'   just check the current state.
#' @return Invisibly, `TRUE` if a key is set after the call, otherwise
#'   `FALSE`.
#' @seealso [pa_sandbox()] for keyless testing.
#' @export
#' @examples
#' pa_auth() # reports whether PARLAY_API_KEY is set
#' \dontrun{
#' pa_auth("your-api-key")
#' }
pa_auth <- function(key = NULL) {
  if (!is.null(key)) {
    if (!is.character(key) || length(key) != 1L || !nzchar(key)) {
      stop("`key` must be a single non-empty string.", call. = FALSE)
    }
    Sys.setenv(PARLAY_API_KEY = key)
    message("PARLAY_API_KEY set for this session.")
    return(invisible(TRUE))
  }
  has_key <- nzchar(Sys.getenv("PARLAY_API_KEY", ""))
  if (has_key) {
    message("PARLAY_API_KEY is set.")
  } else {
    message(
      "PARLAY_API_KEY is not set. Get a free key at ",
      "https://parlay-api.com (1,000 credits per month, no card), ",
      "or call pa_sandbox(TRUE) to use the keyless sandbox."
    )
  }
  invisible(has_key)
}

#' Toggle sandbox mode
#'
#' In sandbox mode, [pa_sports()], [pa_odds()], and [pa_props()] are
#' routed to ParlayAPI's keyless `/v1/sandbox/` endpoints, which serve
#' synthetic but structurally identical data. No API key is needed, so
#' examples, tests, and the package vignette all run keyless.
#'
#' Sandbox data notes:
#' * Prices are always returned in American format, whatever
#'   `odds_format` you request.
#' * [pa_historical()] and [pa_closing_odds()] have no sandbox
#'   equivalent and will error in sandbox mode.
#'
#' Every request function also accepts a `sandbox` argument that
#' overrides this global toggle for a single call.
#'
#' @param enable Logical, `TRUE` to route requests to the sandbox.
#' @return Invisibly, the previous value of the toggle.
#' @export
#' @examples
#' pa_sandbox(TRUE)
#' pa_sandbox(FALSE)
pa_sandbox <- function(enable = TRUE) {
  if (!is.logical(enable) || length(enable) != 1L || is.na(enable)) {
    stop("`enable` must be TRUE or FALSE.", call. = FALSE)
  }
  old <- getOption("parlayapiR.sandbox", FALSE)
  options(parlayapiR.sandbox = enable)
  invisible(old)
}

# Resolve the effective sandbox flag for one call.
pa_sandbox_enabled <- function(sandbox = NULL) {
  if (!is.null(sandbox)) {
    if (!is.logical(sandbox) || length(sandbox) != 1L || is.na(sandbox)) {
      stop("`sandbox` must be TRUE, FALSE, or NULL.", call. = FALSE)
    }
    return(sandbox)
  }
  isTRUE(getOption("parlayapiR.sandbox", FALSE))
}

pa_key <- function() {
  Sys.getenv("PARLAY_API_KEY", "")
}
