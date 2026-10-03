#' Files available from National Land Numerical Information
#'
#' `ksj_available` is the catalog of the package: it lists every file of
#' National Land Numerical Information (Kokudo Suuchi Joho, KSJ) that the
#' package can get, with its dataset, release, area, and terms of use. Filter
#' its rows and pass them to [ksj_get()]. A file that is not listed here is not
#' supported.
#'
#' Labels are kept as published on the KSJ download site. The catalog is
#' updated with new versions of the package, not at run time.
#'
#' @format A tibble with one row per file and the columns:
#' \describe{
#'   \item{dataset_code}{KSJ code of the dataset page, for example `N03`.}
#'   \item{dataset_name}{Name of the dataset, as published.}
#'   \item{category_name}{Category on the index page.}
#'   \item{year}{Western year of the release.}
#'   \item{year_name}{Release, as labeled in the download table.}
#'   \item{area_name}{Area, as labeled in the download table.}
#'   \item{prefecture_code}{Two-digit prefecture code when the area is a
#'     prefecture, otherwise `NA`.}
#'   \item{datum_name}{Geodetic datum, as labeled in the download table.}
#'   \item{file_name}{Name of the archive.}
#'   \item{file_size}{Size as published (`fs::fs_bytes`). Sizes are published
#'     in MB and KB, read as 10^6 and 10^3 bytes.}
#'   \item{url}{URL of the archive.}
#'   \item{license_name}{Terms of use, as labeled on the index page.}
#'   \item{license_note}{Notes on the terms from the dataset page.}
#'   \item{license_url}{Page of the terms.}
#'   \item{page_url}{Download page of the dataset.}
#'   \item{specification_url}{Product specification of the dataset.}
#' }
#' @source <https://nlftp.mlit.go.jp/ksj/>
#' @examples
#' ksj_available
"ksj_available"

# Computes `ksj_available` from the scraped catalog in `data-raw/`, which is
# not shipped: the files of the datasets that have a pipeline, with the columns
# of their dataset. It runs offline, so that a test can check that
# `ksj_available` is up to date. Only the maintainer runs it
# (`data-raw/build.R`).
ksj_available_impl <- function(dir = "data-raw") {
  rlang::check_installed("readr")
  datasets <- read_scraped(
    fs::path(dir, "datasets.csv"),
    readr::cols(.default = readr::col_character())
  )
  files <- read_scraped(
    fs::path(dir, "catalog.csv"),
    readr::cols(
      .default = readr::col_character(),
      year = readr::col_integer(),
      file_size = readr::col_double()
    )
  )

  pipelines <- tarchives::tar_archive_pipelines("ksjdata")
  files <- files[
    vctrs::vec_in(stringr::str_to_lower(files$dataset_code), pipelines),
  ]
  files$file_size <- fs::as_fs_bytes(round(files$file_size * 1e6))
  dataset <- datasets[
    vctrs::vec_match(files$dataset_code, datasets$dataset_code),
  ]

  ksj_check_files(files)
  tibble(
    files["dataset_code"],
    dataset[c("dataset_name", "category_name")],
    files[c(
      "year",
      "year_name",
      "area_name",
      "prefecture_code",
      "datum_name",
      "file_name",
      "file_size",
      "url"
    )],
    dataset[c(
      "license_name",
      "license_note",
      "license_url",
      "page_url",
      "specification_url"
    )]
  )
}

# A file name must identify one file and one target: `ksj_get()` finds a file
# by its name and reads the target named after it. The name must also be the
# name of the archive at the URL, so that it never points to another file.
ksj_check_files <- function(files) {
  targets <- ksj_target_name(files$file_name)
  wrong <- vctrs::vec_duplicate_detect(files$file_name) |
    vctrs::vec_duplicate_detect(targets) |
    files$file_name != fs::path_file(files$url)
  if (any(wrong)) {
    cli::cli_abort(
      c(
        "Each file must have a unique name and target name, and be named after its URL.",
        x = "Files that are not: {.file {unique(files$file_name[wrong])}}."
      ),
      class = "ksjdata_error_catalog"
    )
  }
  invisible(files)
}

read_scraped <- function(path, col_types) {
  data <- readr::read_csv(
    path,
    col_types = col_types,
    na = "",
    progress = FALSE
  )
  tibble::as_tibble(data)
}
