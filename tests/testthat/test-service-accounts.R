test_that("has_service_account_token() returns false when not on Connect", {
  expect_false(has_service_account_token())
})

test_that("connect_service_account_token() has nice errors when not on Connect", {
  expect_snapshot(connect_service_account_token(), error = TRUE)
  local_mocked_bindings(running_on_connect = function() TRUE)
  expect_snapshot(connect_service_account_token(), error = TRUE)
})

test_that("missing service_account credentials generate errors on Connect", {
  # Mock a Connect environment that *does not* support service_account-based
  # credentials.
  local_mocked_bindings(running_on_connect = function() TRUE)
  expect_false(has_service_account_token())
  expect_snapshot(connect_service_account_token(), error = TRUE)
  local_options(connectcreds_debug = TRUE)
  expect_snapshot(has_service_account_token())
})

test_that("token exchange requests to Connect look correct", {
  local_mocked_connect_responses(function(req) {
    # Snapshot relevant fields of the outgoing request.
    expect_snapshot(
      list(url = req$url, headers = req$headers, body = req$body$data)
    )
    response_json(body = list(access_token = "token"))
  })
  expect_equal(connect_service_account_token()$access_token, "token")
})

test_that("mock Connect responses work as expected", {
  with_mocked_connect_responses(
    expect_equal(connect_service_account_token()$access_token, "test"),
    token = "test"
  )

  with_mocked_connect_responses(
    expect_snapshot(connect_service_account_token(), error = TRUE),
    error = TRUE
  )

  with_mocked_connect_responses(
    expect_snapshot(connect_service_account_token(), error = TRUE),
    mock = function(req) {
      response(status_code = 500, headers = list(`content-type` = "text/plain"))
    }
  )
})

test_that("session token from file is preferred over env var", {
  token_file <- withr::local_tempfile()
  writeLines("token-from-file", token_file)
  withr::local_envvar(
    CONNECT_CONTENT_SESSION_TOKEN_FILE = token_file,
    CONNECT_CONTENT_SESSION_TOKEN = "token-from-envvar"
  )
  expect_equal(content_session_token(), "token-from-file")
})

test_that("session token falls back to env var when file is missing", {
  withr::local_envvar(
    CONNECT_CONTENT_SESSION_TOKEN_FILE = "/nonexistent/path/to/token",
    CONNECT_CONTENT_SESSION_TOKEN = "token-from-envvar"
  )
  expect_equal(content_session_token(), "token-from-envvar")
})

test_that("session token falls back to env var when file env is unset", {
  withr::local_envvar(
    CONNECT_CONTENT_SESSION_TOKEN_FILE = NA,
    CONNECT_CONTENT_SESSION_TOKEN = "token-from-envvar"
  )
  expect_equal(content_session_token(), "token-from-envvar")
})

test_that("session token is empty when neither source is available", {
  withr::local_envvar(
    CONNECT_CONTENT_SESSION_TOKEN_FILE = NA,
    CONNECT_CONTENT_SESSION_TOKEN = NA
  )
  expect_equal(content_session_token(), "")
})

test_that("connect_service_account_token() reads token from file", {
  local_mocked_connect_responses(function(req) {
    expect_equal(as.character(req$body$data$subject_token), "token-from-file")
    response_json(body = list(access_token = "exchanged"))
  })
  token_file <- withr::local_tempfile()
  writeLines("token-from-file", token_file)
  withr::local_envvar(CONNECT_CONTENT_SESSION_TOKEN_FILE = token_file)
  expect_equal(connect_service_account_token()$access_token, "exchanged")
})

test_that("connect_workload_token() reads token from file", {
  local_mocked_connect_responses(function(req) {
    expect_equal(as.character(req$body$data$subject_token), "token-from-file")
    response_json(body = list(access_token = "exchanged"))
  })
  token_file <- withr::local_tempfile()
  writeLines("token-from-file", token_file)
  withr::local_envvar(CONNECT_CONTENT_SESSION_TOKEN_FILE = token_file)
  expect_equal(
    connect_workload_token(audience = "test")$access_token,
    "exchanged"
  )
})

test_that("has_workload_token() returns false when not on Connect", {
  expect_false(has_workload_token(audience = "test"))
})

test_that("connect_workload_token() has nice errors when not on Connect", {
  expect_snapshot(connect_workload_token(audience = "test"), error = TRUE)
  local_mocked_bindings(running_on_connect = function() TRUE)
  expect_snapshot(connect_workload_token(audience = "test"), error = TRUE)
})

test_that("missing workload token credentials generate errors on Connect", {
  # Mock a Connect environment that *does not* support workload identity tokens.
  local_mocked_bindings(running_on_connect = function() TRUE)
  expect_false(has_workload_token(audience = "test"))
  expect_snapshot(connect_workload_token(audience = "test"), error = TRUE)
  local_options(connectcreds_debug = TRUE)
  expect_snapshot(has_workload_token(audience = "test"))
})

test_that("workload token exchange requests to Connect look correct", {
  local_mocked_connect_responses(function(req) {
    # Snapshot relevant fields of the outgoing request.
    expect_snapshot(
      list(url = req$url, headers = req$headers, body = req$body$data)
    )
    response_json(body = list(access_token = "token"))
  })
  expect_equal(
    connect_workload_token(audience = "test")$access_token,
    "token"
  )
})

test_that("mock Connect responses work for workload tokens", {
  with_mocked_connect_responses(
    expect_equal(
      connect_workload_token(audience = "test")$access_token,
      "test"
    ),
    token = "test"
  )

  with_mocked_connect_responses(
    expect_snapshot(connect_workload_token(audience = "test"), error = TRUE),
    error = TRUE
  )
})
