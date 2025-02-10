# connect_service_account_token() has nice errors when not on Connect

    Code
      connect_service_account_token()
    Condition
      Error in `connect_service_account_token()`:
      ! Service account credentials are only available when running on Connect.

---

    Code
      connect_service_account_token()
    Condition
      Error in `connect_service_account_token()`:
      ! Service account credentials are not supported by this version of Connect.

# missing service_account credentials generate errors on Connect

    Code
      connect_service_account_token()
    Condition
      Error in `connect_service_account_token()`:
      ! Service account credentials are not supported by this version of Connect.

---

    Code
      has_service_account_token()
    Message
      No service account credentials found.
      Caused by error in `connect_service_account_token()`:
      ! Service account credentials are not supported by this version of Connect.
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
      [1] "session-token"
      
      $body$subject_token_type
      [1] "urn%3Aposit%3Aconnect%3Acontent-session-token"
      
      

# mock Connect responses work as expected

    Code
      connect_service_account_token()
    Condition
      Error in `connect_service_account_token()`:
      ! Cannot fetch service account credentials from the Connect server.
      Caused by error:
      ! Failed to parse response from `client$token_url` OAuth url.
      * Did not contain `access_token`, `device_code`, or `error` field.

---

    Code
      connect_service_account_token()
    Condition
      Error in `connect_service_account_token()`:
      ! Cannot fetch service account credentials from the Connect server.
      Caused by error:
      ! Failed to parse response from `client$token_url` OAuth url.
      Caused by error in `resp_body_json()`:
      ! Unexpected content type "text/plain".
      * Expecting type "application/json" or suffix "json".

