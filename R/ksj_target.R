#' Target of National Land Numerical Information
#'
#' `ksj_target()` and `ksj_target_raw()` declare a target of a 'targets'
#' pipeline whose value is `ksj_get(files, layer, col_names)`. The target is
#' rerun when the files, the arguments, or the installed version of ksjdata
#' change.
#'
#' @param name Name of the target: a symbol for `ksj_target()`, a string for
#'   `ksj_target_raw()`.
#' @inheritParams ksj_get
#' @param ... Other arguments passed to [targets::tar_target_raw()].
#' @returns A target object.
#' @export
#' @examples
#' files <- ksj_available[ksj_available$dataset_code == "N03", ][1, ]
#' ksj_target(municipalities, files)
ksj_target <- function(
  name,
  files,
  layer = NULL,
  col_names = c("ja", "raw"),
  ...
) {
  name <- targets::tar_deparse_language(substitute(name))
  ksj_target_raw(
    name = name,
    files = files,
    layer = layer,
    col_names = col_names,
    ...
  )
}

#' @rdname ksj_target
#' @export
ksj_target_raw <- function(
  name,
  files,
  layer = NULL,
  col_names = c("ja", "raw"),
  ...
) {
  check_string(name)
  check_data_frame(files)
  check_string(layer, allow_null = TRUE)
  col_names <- rlang::arg_match(col_names)
  files <- ksj_match_files(files)

  command <- rlang::call2(
    "ksj_get",
    files = rlang::call2(
      "tibble",
      dataset_code = files$dataset_code,
      file_name = files$file_name,
      .ns = "tibble"
    ),
    layer = layer,
    col_names = col_names,
    .ns = "ksjdata"
  )
  string <- stringr::str_c(
    stringr::str_flatten(deparse(command), "\n"),
    as.character(utils::packageVersion("ksjdata"))
  )
  targets::tar_target_raw(name = name, command = command, string = string, ...)
}

# Name of the target of a file in the pipeline of its dataset:
# `N03-20250101_13_GML.zip` becomes `ksj_n03_20250101_13_gml`.
ksj_target_name <- function(file_name) {
  stringr::str_c("ksj_", ksj_target_suffix(file_name))
}

ksj_target_suffix <- function(file_name) {
  file_name |>
    stringr::str_remove(stringr::regex("\\.zip$", ignore_case = TRUE)) |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("[^a-z0-9]+", "_")
}
