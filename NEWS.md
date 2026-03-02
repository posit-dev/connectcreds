# connectcreds 0.2.0

* New `connect_service_account_token()` and `has_service_account_token()`
  functions allow looking up credentials from Connect-managed service accounts
  (or service principals).

* New `connect_workload_token()` and `has_workload_token()` functions allow
  manual retrieval of workload identity tokens on a Connect server.

* Error messages for misuse of `connect_viewer_token()` outside Connect have
  improved.

# connectcreds 0.1.0

* Initial release. `connectcreds` is is a toolkit for making use of credentials
  mediated by Posit Connect. It handles the details of communicating with
  Connect's API correctly, OAuth token caching, and refresh behaviour.
