#' Target of National Land Numerical Information
#'
#' `ksj_target()` and `ksj_target_raw()` declare a target of a 'targets'
#' pipeline whose value is `ksj_get(file_name, layer, col_names)`. The target
#' is rerun when the arguments, the URL or the size of the file in
#' [ksj_available], or the installed version of ksjdata change. To declare a
#' target per file, use `tarchetypes::tar_eval()`.
#'
#' @param name Name of the target: a symbol for `ksj_target()`, a string for
#'   `ksj_target_raw()`.
#' @inheritParams ksj_get
#' @param ... Other arguments passed to [targets::tar_target_raw()].
#' @returns A target object.
#' @export
#' @examplesIf rlang::is_installed("tarchetypes")
#' ksj_target(municipalities, "N03-20260101_13_GML.zip")
#'
#' # A target per file
#' files <- ksj_available[
#'   ksj_available$dataset_code == "N03" &
#'     ksj_available$year == 2026 &
#'     ksj_available$prefecture_code %in% c("13", "14"),
#' ]
#' tarchetypes::tar_eval(
#'   ksj_target(name, file_name),
#'   values = list(
#'     name = rlang::syms(stringr::str_c("n03_", files$prefecture_code)),
#'     file_name = files$file_name
#'   )
#' )
ksj_target <- function(
  name,
  file_name,
  layer = NULL,
  col_names = c("ja", "raw"),
  ...
) {
  name <- targets::tar_deparse_language(substitute(name))
  ksj_target_raw(
    name = name,
    file_name = file_name,
    layer = layer,
    col_names = col_names,
    ...
  )
}

#' @rdname ksj_target
#' @export
ksj_target_raw <- function(
  name,
  file_name,
  layer = NULL,
  col_names = c("ja", "raw"),
  ...
) {
  check_string(name)
  check_string(file_name)
  check_string(layer, allow_null = TRUE)
  col_names <- rlang::arg_match(col_names)
  file <- ksj_find_file(file_name)

  command <- rlang::call2(
    "ksj_get",
    file_name = file_name,
    layer = layer,
    col_names = col_names,
    .ns = "ksjdata"
  )
  # The URL and the size of the file rerun the target when an update of the
  # catalog replaces the file, even if the version of ksjdata is unchanged.
  string <- stringr::str_flatten(
    c(
      deparse(command),
      file$url,
      format(as.numeric(file$file_size), scientific = FALSE),
      as.character(utils::packageVersion("ksjdata"))
    ),
    "\n"
  )
  targets::tar_target_raw(name = name, command = command, string = string, ...)
}

#' Name of the target of a file
#'
#' `ksj_target_name()` gives the name of the target of a file in the bundled
#' pipeline of its dataset: `N03-20250101_13_GML.zip` becomes
#' `ksj_n03_20250101_13_gml`. It is used by the pipelines and by [ksj_get()].
#'
#' @param file_name Names of files: values of `file_name` in [ksj_available].
#' @returns A character vector of target names.
#' @keywords internal
#' @export
#' @examples
#' ksj_target_name("N03-20250101_13_GML.zip")
ksj_target_name <- function(file_name) {
  check_character(file_name)
  # The prefix keeps names valid when a file name starts with a digit
  # (`1km_mesh_2024_GML.zip`).
  suffix <- file_name |>
    stringr::str_remove(stringr::regex("\\.zip$", ignore_case = TRUE)) |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("[^a-z0-9]+", "_")
  stringr::str_c("ksj_", suffix)
}
