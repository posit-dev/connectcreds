#' Viewer-based credentials on Posit Connect
#'
#' Request an OAuth access token for a third-party resource belonging to the
#' user associated with a given Shiny session. This works by exchanging a
#' short-lived session credential for OAuth tokens issued to the client managed
#' by the Connect server, without the Shiny app in question having to manage the
#' user's authentication flow (or the associated client credentials) itself.
#'
#' `connect_viewer_token()` handles caching automatically.
#'
#' @inheritParams httr2::oauth_flow_token_exchange
#' @param session A Shiny session object. By default, this grabs the Shiny
#'   session of the parent environment (if any), provided we are also running on
#'   Connect.
#' @param server_url The Connect server to exchange credentials with. Defaults
#'   to the value of the `CONNECT_SERVER` environment variable, which is set
#'   automatically when running on Connect.
#' @param api_key An API key for the Connect server. Defaults to the value of
#'   the `CONNECT_API_KEY` environment variable, which is set automatically when
#'   running on Connect.
#' @returns [connect_viewer_token()] returns an [httr2::oauth_token].
#' @examples
#' token <- "default-token"
#' if (has_viewer_token()) {
#'   token <- connect_viewer_token()
#' }
#' @export
connect_viewer_token <- function(
  resource = NULL,
  scope = NULL,
  session = get_connect_session(),
  server_url = Sys.getenv("CONNECT_SERVER"),
  api_key = Sys.getenv("CONNECT_API_KEY")
) {
  check_shiny_session(session, arg = substitute(session))
  check_string(resource, allow_null = TRUE)
  check_string(scope, allow_null = TRUE)
  check_string(server_url)
  check_string(api_key)

  # Older versions or certain configurations of Connect might not supply a user
  # session token.
  session_token <- session$request$HTTP_POSIT_CONNECT_USER_SESSION_TOKEN
  if (is.null(session_token)) {
    cli::cli_abort(
      "Viewer-based credentials are not supported by this version of Connect."
    )
  }

  client <- connect_oauth_client(server_url, api_key, call = current_env())
  try_fetch(
    oauth_token_cached(
      client,
      oauth_flow_token_exchange,
      flow_params = list(
        subject_token = session_token,
        subject_token_type = "urn:posit:connect:user-session-token",
        resource = resource,
        scope = scope
      ),
      # Important: we need to keep a separate cache for each session.
      cache_key = session_token,
      # Don't use the cached token when testing.
      reauth = is_testing()
    ),
    httr2_oauth_parse = function(cnd) {
      # The original implementation of viewer-based credentials returned a
      # regular Connect error response, which httr2 doesn't understand. Try to
      # turn it into a useful message in that case.
      body <- try(resp_body_json(cnd$resp), TRUE)
      if (inherits(body, "try-error") || !has_name(body, "error_message")) {
        # Re-throw errors we don't expect.
        stop(cnd)
      }
      # Emulate httr2:::oauth_flow_abort().
      cli::cli_abort(c(
          "OAuth failure [invalid_request]",
          "*" = body$error_message,
          i = if (body$error_code == 212) "Learn more at \
          {.url https://docs.posit.co/connect/user/oauth-integrations/#adding-oauth-integrations-to-deployed-content}."
      ), call = NULL)
    },
    error = function(cnd) {
      cli::cli_abort(
        "Cannot fetch viewer-based credentials for the current Shiny session.",
        parent = cnd
      )
    }
  )
}

#' @param ... Further arguments passed on to [connect_viewer_token()].
#' @returns [has_viewer_token()] returns `TRUE` if the session has a viewer
#'   token and `FALSE` otherwise.
#' @export
#' @rdname connect_viewer_token
has_viewer_token <- function(..., session = get_connect_session()) {
  if (is.null(session)) {
    return(FALSE)
  }

  if (!running_on_connect()) {
    debug_inform(c(
      "No viewer-based credentials found.",
      "i" = "Viewer-based credentials are only available when running on Connect."
    ))
    return(FALSE)
  }

  # If viewer-based authentication is enabled, check whether we can actually get
  # credentials before continuing. Better to fail early.
  try_fetch({
    connect_viewer_token(..., session = session)
    TRUE
  }, error = function(cnd) {
    debug_inform("No viewer-based credentials found.", parent = cnd)
    FALSE
  })
}

connect_oauth_client <- function(server_url = Sys.getenv("CONNECT_SERVER"),
                                 api_key = Sys.getenv("CONNECT_API_KEY"),
                                 call = current_env()) {
  if (!nzchar(server_url)) {
    cli::cli_abort(c(
      "A Connect server URL is required to retrieve credentials.",
      "i" = "Pass an explicit {.arg server_url} argument or set the
             {.envvar CONNECT_SERVER} environment variable."
    ), call = call)
  }
  if (!nzchar(api_key)) {
    cli::cli_abort(c(
      "A valid Connect API key is required to retrieve credentials.",
      "i" = "Pass an explicit {.arg api_key} argument or set the
             {.envvar CONNECT_API_KEY} environment variable."
    ), call = call)
  }
  server_url <- sub("/$", "", server_url)
  oauth_client(
    "posit-connect",
    token_url = paste0(
      server_url, "/__api__/v1/oauth/integrations/credentials"
    ),
    auth = oauth_client_req_auth_connect,
    auth_params = list(api_key = api_key)
  )
}

# Custom client authentication function for Connect.
oauth_client_req_auth_connect <- function(req, client, api_key) {
  req_headers(
    req,
    Authorization = paste("Key", api_key),
    .redact = "Authorization"
  )
}

check_shiny_session <- function(x,
                                allow_null = FALSE,
                                arg = caller_arg(x),
                                call = caller_env()) {
  if (!missing(x) && inherits(x, "ShinySession")) {
    return(invisible(x))
  }
  stop_input_type(
    x,
    "a Shiny session object",
    allow_null = allow_null,
    arg = as_string(arg),
    call = call
  )
}

running_on_connect <- function() {
  identical(Sys.getenv("RSTUDIO_PRODUCT"), "CONNECT")
}

is_testing <- function() {
  identical(Sys.getenv("TESTTHAT"), "true")
}

debug_inform <- function(..., .envir = caller_env()) {
  if (!getOption("connectcreds_debug", FALSE)) {
    return()
  }
  cli::cli_inform(..., .envir = .envir)
}

#' Return the current Shiny session object if we're on Posit Connect.
#' @noRd
get_connect_session <- function() {
  if (!running_on_connect()) {
    return(NULL)
  }
  if (is_mocking()) {
    # This allows with_mocked_connect_response() et al. to work seamlessly in
    # third-party package tests.
    return(mock_connect_session())
  }
  if (!isNamespaceLoaded("shiny")) {
    return(NULL)
  }
  # Avoid taking a dependency on Shiny, which is otherwise irrelevant to most
  # packages.
  f <- utils::getFromNamespace("getDefaultReactiveDomain", "shiny")
  f()
}
