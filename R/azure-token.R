#' Convert a token to the AzureAuth format
#'
#' Wraps an [httr2::oauth_token] in an [AzureAuth::AzureToken] for use with the
#' AzureR package ecosystem.
#'
#' @param token An [httr2::oauth_token].
#' @param scope The Azure scope(s) this token is associated with, or `NULL` if
#'   this is unknown.
#' @returns An R6 class that inherits from `AzureToken`.
#' @examplesIf FALSE
#' token <- NULL
#' if (has_viewer_token()) {
#'   token <- as_azure_token(connect_viewer_token())
#' }
#'
#' # For example, when using the Microsoft365R package:
#' # Microsoft365R::list_sharepoint_sites(token = token)
#' @export
as_azure_token <- function(token, scope = NULL) {
  rlang::check_installed("AzureAuth", reason = "for AzureR compatibility")
  ConnectAzureToken$new(token, scope = scope)
}

# An AzureR-interoperable token class.
ConnectAzureToken <- R6Class(
  "ConnectAzureToken",
  inherit = AzureAuth::AzureToken,
  public = list(
    initialize = function(token, scope = NULL) {
      self$credentials <- unclass(token)
      self$auth_type <- "external"
      scope <- scope %||%
        token$scope %||%
        # Inaccurate but necessary to avoid errors in verify_v2_scope().
        "https://graph.microsoft.com/.default"
      resource <- strsplit(scope, " ")[[1]]
      super$initialize(
        resource = resource,
        app = "Posit Connect",
        # Inaccurate but necessary to avoid errors in normalize_tenant().
        tenant = "common",
        version = 2,
        aad_host = NA,
        token_args = list(),
        # This triggers the "dummy" workflow that skips calling out to Azure.
        use_cache = NA
      )
    },

    # Tokens must be refreshed via connectcreds library calls instead.
    can_refresh = function() FALSE,

    # Custom validation.
    validate = function() {
      if (is.null(self$credentials$expires_at)) {
        TRUE
      } else {
        (as.integer(Sys.time()) + 5) > self$credentials$expires_at
      }
    }
  ),
  private = list(
    # Necessary to avoid "Do not call this constructor directly" errors.
    initfunc = function(...) {}
  )
)
