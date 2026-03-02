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

#' Workload identity tokens on Posit Connect
#'
#' Request an OpenID Connect identity token suitable for workload identity
#' federation with a third-party service.
#'
#' `connect_workload_token()` handles caching automatically.
#'
#' @inheritParams httr2::oauth_flow_token_exchange
#' @inheritParams connect_service_account_token
#' @returns [connect_workload_token()] returns an [httr2::oauth_token].
#' @examples
#' integration_guid <- "891db041-22d6-4f5f-9fee-fc715a33929e"
#' token <- "default-token"
#' if (has_workload_token(audience = integration_guid)) {
#'   token <- connect_workload_token(audience = integration_guid)
#' }
#' @export
connect_workload_token <- function(
  ...,
  content_token = Sys.getenv("CONNECT_CONTENT_SESSION_TOKEN"),
  server_url = Sys.getenv("CONNECT_SERVER"),
  api_key = Sys.getenv("CONNECT_API_KEY")
) {
  check_string(content_token)
  check_string(server_url)
  check_string(api_key)

  if (!running_on_connect()) {
    cli::cli_abort(
      "Workload identity tokens are only available when running on Connect."
    )
  }

  # Older versions or certain configurations of Connect might not supply a
  # content session token.
  if (nchar(content_token) == 0) {
    cli::cli_abort(
      "Workload identity tokens are not supported by this version of Connect."
    )
  }

  client <- connect_oauth_client(server_url, api_key, call = current_env())
  try_fetch(
    oauth_token_cached(
      client,
      oauth_flow_token_exchange,
      flow_params = c(
        list(
          subject_token = content_token,
          subject_token_type = "urn:posit:connect:content-session-token",
          requested_token_type = "urn:ietf:params:oauth:token-type:id_token"
        ),
        list(...)
      ),
      # Don't use the cached token when testing.
      reauth = is_testing()
    ),
    error = function(cnd) {
      cli::cli_abort(
        "Cannot fetch workload identity token from the Connect server.",
        parent = cnd
      )
    }
  )
}

#' @param ... Further arguments passed on to [connect_workload_token()].
#' @returns [has_workload_token()] returns `TRUE` if a workload identity token
#'   is available and `FALSE` otherwise.
#' @export
#' @rdname connect_workload_token
has_workload_token <- function(...) {
  try_fetch(
    {
      connect_workload_token(...)
      TRUE
    },
    error = function(cnd) {
      debug_inform("No workload identity token found.", parent = cnd)
      FALSE
    }
  )
}
