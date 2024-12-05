
<!-- README.md is generated from README.Rmd. Please edit that file -->

# connectcreds

<!-- badges: start -->

[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![R-CMD-check](https://github.com/posit-dev/connectcreds/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/posit-dev/connectcreds/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

`connectcreds` provides low-level utilities for Shiny developers and R
package authors building tools that make use of Posit Connect’s
[viewer-based
credentials](https://docs.posit.co/connect/admin/integrations/oauth-integrations/).

## Installation

You can install the development version of `connectcreds` from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("posit-dev/connectcreds")
```

## Usage

`connectcreds` includes helper functions for implementing Posit
Connect’s viewer-based credentials in Shiny applications. These helpers
are meant to be called in the context of a Shiny server function, as
follows:

``` r
server <- function(input, output, session) {
  token <- "PAT for local development"
  if (connectcreds::has_viewer_token(session)) {
    token <- connectcreds::connect_viewer_token(session)
  }

  # ...
}
```

Usually, though, these helpers will be used internally by packages that
authenticate with various services. For example, here is a simplified
version of `gh::gh_token()` that returns a GitHub OAuth token for the
viewer on Connect but uses a GitHub personal access token when testing
locally:

``` r
gh_token <- function(session = NULL) {
  if (!is.null(session)) {
    rlang::check_installed("connectcreds", "for viewer-based authentication")
    if (connectcreds::has_viewer_token(session, "https://github.com")) {
      token <- connectcreds::connect_viewer_token(session, "https://github.com")
      return(token)
    }
  }
  Sys.getenv("GITHUB_PAT")
}

server <- function(input, output, session) {
  # A Shiny output that shows the user's GitHub username:
  output$gh_handle <- renderText({
    resp <- gh::gh_whoami(.token = gh_token(session = session))
    resp$login
  })

  # ...
}
```

## License

MIT (c) [Posit Software, PBC](https://posit.co)
