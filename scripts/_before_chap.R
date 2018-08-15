options(digits = 3)

suppressPackageStartupMessages({
  library(magrittr)
  library(methods)
})

knitr::opts_chunk$set(
  comment = "#>"
  , collapse = TRUE
  , cache = TRUE
  , fig.align = "center"
  , fig.show = "hold"
  , echo = TRUE
  , results = 'markup'
  , message = FALSE
  , out.width = '75%'
  , fig.width = 6
  , fig.asp = 0.618  # 1 / phi
  , tidy = FALSE
)

if ( knitr::is_html_output()) {
  fig.height = 4
}