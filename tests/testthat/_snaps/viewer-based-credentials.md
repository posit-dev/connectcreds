# the session parameter is ignored when not on Connect

    Code
      . <- has_viewer_token(session)
    Message
      ! Ignoring the `session` parameter.
      i Viewer-based credentials are only available when running on Connect.

# missing viewer credentials generate errors on Connect

    Code
      . <- has_viewer_token(session)
    Condition
      Error in `has_viewer_token()`:
      ! Cannot fetch viewer-based credentials for the current Shiny session.
      Caused by error in `connect_viewer_token()`:
      ! Viewer-based credentials are not supported by this version of Connect.

# token exchange requests to Connect look correct

    Code
      list(url = req$url, headers = req$headers, body = req$body$data)
    Output
      $url
      [1] "localhost:3030/__api__/v1/oauth/integrations/credentials"
      
      $headers
      $headers$Authorization
      [1] "Key key"
      
      $headers$Accept
      [1] "application/json"
      
      attr(,"redact")
      [1] "Authorization"
      
      $body
      $body$grant_type
      [1] "urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Atoken-exchange"
      
      $body$subject_token
      [1] "user-token"
      
      $body$subject_token_type
      [1] "urn%3Aposit%3Aconnect%3Auser-session-token"
      
      

