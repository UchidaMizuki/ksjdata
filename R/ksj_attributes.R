#' Attributes of National Land Numerical Information
#'
#' `ksj_attributes` gives the name of each attribute code of the layers of
#' National Land Numerical Information, as published in the attribute table
#' (`shape_property_table2.xlsx`). [ksj_get()] uses it to name the columns of
#' the data.
#'
#' The attribute table describes only the latest release of each dataset, so
#' names are used only for the files of [ksj_available] whose `year` is the
#' year of the version. A layer whose codes or names are not unique has no names
#' (`NA`).
#'
#' @format A tibble with one row per attribute and the columns:
#' \describe{
#'   \item{dataset_code}{KSJ code of the dataset, as written in the attribute
#'     table. Some codes are written without `-` or `_` (`G04a` for `G04-a` in
#'     [ksj_available]), so they are compared without them.}
#'   \item{version_name}{Version, as published in the attribute table.}
#'   \item{year}{Year of the version, or `NA` if the version is not a year
#'     (a version number such as 1.1).}
#'   \item{layer_pattern}{Shapefile name pattern of the layer.}
#'   \item{feature_name}{Name of the layer, as published in the attribute
#'     table.}
#'   \item{attribute_code}{Code of the attribute in the data.}
#'   \item{attribute_name}{Japanese name, as published in the attribute table,
#'     or `NA`.}
#'   \item{note}{Note of the attribute table.}
#' }
#' @source <https://nlftp.mlit.go.jp/ksj/gml/codelist/shape_property_table2.xlsx>
#' @examples
#' ksj_attributes
"ksj_attributes"

# Computes `ksj_attributes` from the attribute table read into `data-raw/`,
# which is not shipped. It runs offline, so that a test can check that
# `ksj_attributes` is up to date. Only the maintainer runs it
# (`data-raw/build.R`).
ksj_attributes_impl <- function(dir = "data-raw") {
  rlang::check_installed("readr")
  read_scraped(
    fs::path(dir, "attributes.csv"),
    readr::cols(.default = readr::col_character(), year = readr::col_integer())
  )
}
