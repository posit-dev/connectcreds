#' Service account credentials on Posit Connect
#'
#' Request an OAuth access token for a third-party resource from Posit Connect.
#' The OAuth token will belong to the client (usually a "service principal" or
#' "service account") managed by Connect, not the publisher.
#'
#' `connect_service_account_token()` handles caching automatically.
#'
#' @inheritParams httr2::oauth_flow_token_exchange
#' @inheritParams connect_viewer_token
#' @param content_token A token that uniquely identifies this content session.
#'   Defaults to the value of the `CONNECT_CONTENT_SESSION_TOKEN` environment
#'   variable, which is set automatically when running on Connect.
#' @returns [connect_service_account_token()] returns an [httr2::oauth_token].
#' @examples
#' token <- "default-token"
#' if (has_service_account_token()) {
#'   token <- connect_service_account_token()
#' }
#' @export
connect_service_account_token <- function(
  resource = NULL,
  scope = NULL,
  content_token = Sys.getenv("CONNECT_CONTENT_SESSION_TOKEN"),
  server_url = Sys.getenv("CONNECT_SERVER"),
  api_key = Sys.getenv("CONNECT_API_KEY")
) {
  check_string(resource, allow_null = TRUE)
  check_string(scope, allow_null = TRUE)
  check_string(content_token)
  check_string(server_url)
  check_string(api_key)

  if (!running_on_connect()) {
    cli::cli_abort(
      "Service account credentials are only available when running on Connect."
    )
  }

  # Older versions or certain configurations of Connect might not supply a
  # content session token.
  if (nchar(content_token) == 0) {
    cli::cli_abort(
      "Service account credentials are not supported by this version of Connect."
    )
  }

  client <- connect_oauth_client(server_url, api_key, call = current_env())
  try_fetch(
    oauth_token_cached(
      client,
      oauth_flow_token_exchange,
      flow_params = list(
        subject_token = content_token,
        subject_token_type = "urn:posit:connect:content-session-token",
        resource = resource,
        scope = scope
      ),
      # Don't use the cached token when testing.
      reauth = is_testing()
    ),
    error = function(cnd) {
      cli::cli_abort(
        "Cannot fetch service account credentials from the Connect server.",
        parent = cnd
      )
    }
  )
}

#' @param ... Further arguments passed on to [connect_service_account_token()].
#' @returns [has_service_account_token()] returns `TRUE` if there is a
#'   Connect-managed service account avaiable and `FALSE` otherwise.
#' @export
#' @rdname connect_service_account_token
has_service_account_token <- function(...) {
  try_fetch(
    {
      connect_service_account_token(...)
      TRUE
    },
    error = function(cnd) {
      debug_inform("No service account credentials found.", parent = cnd)
      FALSE
    }
  )
}
