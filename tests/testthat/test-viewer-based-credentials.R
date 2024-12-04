test_that("the session parameter is ignored when not on Connect", {
  session <- structure(list(request = list()), class = "ShinySession")
  expect_snapshot(has_viewer_token(session))
  local_options(connectcreds_debug = TRUE)
  expect_snapshot(has_viewer_token(session))
})

test_that("missing viewer credentials generate errors on Connect", {
  # Mock a Connect environment that *does not* support viewer-based credentials.
  local_mocked_bindings(running_on_connect = function() TRUE)
  session <- structure(list(request = list()), class = "ShinySession")
  expect_snapshot(has_viewer_token(session))
  expect_snapshot(connect_viewer_token(session), error = TRUE)
  local_options(connectcreds_debug = TRUE)
  expect_snapshot(has_viewer_token(session))
})

test_that("token exchange requests to Connect look correct", {
  # Mock a Connect environment that supports viewer-based credentials.
  withr::local_envvar(
    RSTUDIO_PRODUCT = "CONNECT",
    CONNECT_SERVER = "localhost:3030",
    CONNECT_API_KEY = "key"
  )
  local_mocked_responses(function(req) {
    # Snapshot relevant fields of the outgoing request.
    expect_snapshot(
      list(url = req$url, headers = req$headers, body = req$body$data)
    )
    response_json(body = list(access_token = "token"))
  })
  session <- structure(
    list(request = list(HTTP_POSIT_CONNECT_USER_SESSION_TOKEN = "user-token")),
    class = "ShinySession"
  )
  expect_equal(connect_viewer_token(session), "token")
})
