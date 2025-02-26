# connectcreds (development version)

* New `connect_service_account_token()` and `has_service_account_token()`
  functions allow looking up credentials from Connect-managed service accounts
  (or service principals).

* Error messages for misuse of `connect_viewer_token()` outside Connect have
  improved.

* New functions `get_product()`, `is_local()`, `running_on_connect()` (updated), and `running_on_workbench()` help detect the Posit product environment (Posit Connect, Posit Workbench, or local) via environment variables. `get_product()` checks both `POSIT_PRODUCT` and `RSTUDIO_PRODUCT` environment variables. (#2)

# connectcreds 0.1.0

* Initial release. `connectcreds` is is a toolkit for making use of credentials
  mediated by Posit Connect. It handles the details of communicating with
  Connect's API correctly, OAuth token caching, and refresh behaviour.
