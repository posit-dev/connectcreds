#' Mock responses from the Posit Connect server
#'
#' These functions can be used to temporarily mock responses from the Connect
#' server, which is useful for writing tests that verify the behaviour of
#' viewer-based credentials.
#'
#' @param token When not `NULL`, return this token from the Connect server.
#' @param error When `TRUE`, return an error from the Connect server.
#' @inheritParams httr2::with_mocked_responses
#' @returns [with_mocked_connect_responses()] returns the result of evaluating
#'   `code`.
#' @examples
#' with_mocked_connect_responses(
#'   connect_viewer_token(),
#'   token = "test"
#' )
#' @export
with_mocked_connect_responses <- function(code, mock = NULL, token = NULL, error = FALSE, env = caller_env()) {
  check_string(token, allow_empty = FALSE, allow_null = TRUE)
  check_bool(error)
  check_exclusive(mock, token, error)
  mock <- mock %||% connect_mock_fn(token, error)
  withr::with_envvar(
    c(
      RSTUDIO_PRODUCT = "CONNECT",
      CONNECT_SERVER = "localhost:3030",
      CONNECT_API_KEY = "key",
      CONNECTCREDS_MOCKING = "1",
      .local_envir = env
    ),
    with_mocked_responses(mock, code)
  )
}

#' @inheritParams httr2::local_mocked_responses
#' @rdname with_mocked_connect_responses
#' @export
local_mocked_connect_responses <- function(mock = NULL, token = NULL, error = FALSE, env = caller_env()) {
  check_string(token, allow_empty = FALSE, allow_null = TRUE)
  check_bool(error)
  check_exclusive(mock, token, error)
  mock <- mock %||% connect_mock_fn(token, error)
  withr::local_envvar(
    RSTUDIO_PRODUCT = "CONNECT",
    CONNECT_SERVER = "localhost:3030",
    CONNECT_API_KEY = "key",
    CONNECTCREDS_MOCKING = "1",
    .local_envir = env
  )
  local_mocked_responses(mock, env = env)
}

connect_mock_fn <- function(token = NULL, error = FALSE) {
  function(req) {
    if (!grepl("localhost:3030", req$url, fixed = TRUE)) {
      return(NULL)
    }
    if (!error) {
      body <- list(
        access_token = token,
        issued_token_type = "urn:ietf:params:oauth:token-type:access_token",
        token_type =  "Bearer"
      )
    } else {
      body <- list(
        error_code = 212,
        error_message = "No OAuth integrations have been associated with this content item."
      )
    }
    response_json(
      status_code = if (!error) 200L else 400L,
      url = req$url,
      method = req$method %||% "GET",
      body = body
    )
  }
}

mock_connect_session <- function() {
  structure(
    list(request = list(HTTP_POSIT_CONNECT_USER_SESSION_TOKEN = "user-token")),
    class = "ShinySession"
  )
}

is_mocking <- function() {
  identical(Sys.getenv("CONNECTCREDS_MOCKING"), "1")
}
