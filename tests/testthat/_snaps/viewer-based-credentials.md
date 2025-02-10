# has_viewer_token() returns false when not on Connect

    Code
      has_viewer_token(session = session)
    Output
      [1] FALSE

---

    Code
      has_viewer_token(session = session)
    Message
      No viewer-based credentials found.
      i Viewer-based credentials are only available when running on Connect.
    Output
      [1] FALSE

# connect_viewer_token() has nice errors when not on Connect

    Code
      connect_viewer_token()
    Condition
      Error in `connect_viewer_token()`:
      ! Viewer-based credentials are only available when running on Connect.

---

    Code
      connect_viewer_token()
    Condition
      Error in `connect_viewer_token()`:
      ! Viewer-based credentials are only available in Shiny sessions.

# missing viewer credentials generate errors on Connect

    Code
      has_viewer_token()
    Output
      [1] FALSE

---

    Code
      connect_viewer_token()
    Condition
      Error in `connect_viewer_token()`:
      ! Viewer-based credentials are not supported by this version of Connect.

---

    Code
      has_viewer_token()
    Message
      No viewer-based credentials found.
      Caused by error in `connect_viewer_token()`:
      ! Viewer-based credentials are not supported by this version of Connect.
    Output
      [1] FALSE

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
      
      

# mock Connect responses work as expected

    Code
      connect_viewer_token()
    Condition
      Error in `connect_viewer_token()`:
      ! Cannot fetch viewer-based credentials for the current Shiny session.
      Caused by error:
      ! OAuth failure [invalid_request]
      * No OAuth integrations have been associated with this content item.
      i Learn more at <https://docs.posit.co/connect/user/oauth-integrations/#adding-oauth-integrations-to-deployed-content>.

---

    Code
      connect_viewer_token()
    Condition
      Error in `connect_viewer_token()`:
      ! Cannot fetch viewer-based credentials for the current Shiny session.
      Caused by error:
      ! Failed to parse response from `client$token_url` OAuth url.
      Caused by error in `resp_body_json()`:
      ! Unexpected content type "text/plain".
      * Expecting type "application/json" or suffix "json".

