test_that("has_viewer_token() returns false when not in a Shiny session", {
  expect_false(has_viewer_token())
})

test_that("has_viewer_token() returns false when not on Connect", {
  session <- structure(list(request = list()), class = "ShinySession")
  expect_snapshot(has_viewer_token(session = session))
  local_options(connectcreds_debug = TRUE)
  expect_snapshot(has_viewer_token(session = session))
})

test_that("connect_viewer_token() has nice errors when not on Connect", {
  expect_snapshot(connect_viewer_token(), error = TRUE)
  local_mocked_bindings(running_on_connect = function() TRUE)
  expect_snapshot(connect_viewer_token(), error = TRUE)
})

test_that("missing viewer credentials generate errors on Connect", {
  # Mock a Connect environment that *does not* support viewer-based credentials.
  local_mocked_bindings(
    running_on_connect = function() TRUE,
    get_connect_session = function() {
      structure(list(request = list()), class = "ShinySession")
    }
  )
  expect_snapshot(has_viewer_token())
  expect_snapshot(connect_viewer_token(), error = TRUE)
  local_options(connectcreds_debug = TRUE)
  expect_snapshot(has_viewer_token())
})

test_that("token exchange requests to Connect look correct", {
  local_mocked_connect_responses(function(req) {
    # Snapshot relevant fields of the outgoing request.
    expect_snapshot(
      list(url = req$url, headers = req$headers, body = req$body$data)
    )
    response_json(body = list(access_token = "token"))
  })
  expect_equal(connect_viewer_token()$access_token, "token")
})

test_that("mock Connect responses work as expected", {
  with_mocked_connect_responses(
    expect_equal(connect_viewer_token()$access_token, "test"),
    token = "test"
  )

  with_mocked_connect_responses(
    expect_snapshot(connect_viewer_token(), error = TRUE),
    error = TRUE
  )

  with_mocked_connect_responses(
    expect_snapshot(connect_viewer_token(), error = TRUE),
    mock = function(req) {
      response(status_code = 500, headers = list(`content-type` = "text/plain"))
    }
  )
})
