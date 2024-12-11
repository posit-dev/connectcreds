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
  local_mocked_connect_responses(function(req) {
    # Snapshot relevant fields of the outgoing request.
    expect_snapshot(
      list(url = req$url, headers = req$headers, body = req$body$data)
    )
    response_json(body = list(access_token = "token"))
  })
  session <- example_connect_session()
  expect_equal(connect_viewer_token(session)$access_token, "token")
})

test_that("mock Connect responses work as expected", {
  session <- example_connect_session()

  with_mocked_connect_responses(
    expect_equal(connect_viewer_token(session)$access_token, "test"),
    token = "test"
  )

  with_mocked_connect_responses(
    expect_snapshot(connect_viewer_token(session), error = TRUE),
    error = TRUE
  )

  with_mocked_connect_responses(
    expect_snapshot(connect_viewer_token(session), error = TRUE),
    mock = function(req) {
      response(status_code = 500, headers = list(`content-type` = "text/plain"))
    }
  )
})
