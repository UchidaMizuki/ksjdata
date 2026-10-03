#' Get National Land Numerical Information
#'
#' `ksj_get()` downloads and reads the files given by rows of [ksj_available],
#' and returns their data in one `sf` tibble. Only the requested files are
#' downloaded. Each file is read once and cached by the bundled 'targets'
#' pipelines (see the tarchives package), so later calls read the cache.
#'
#' The first time in a session that a dataset is requested, its terms of use
#' are shown, and they are also in the `license_*` columns of [ksj_available].
#' Complying with them is up to you: published or processed data must credit
#' the source (National Land Numerical Information, with the name of the
#' dataset, by the Ministry of Land, Infrastructure, Transport and Tourism),
#' and processed data must say that they were processed.
#'
#' @param files A data frame of rows of [ksj_available]. Rows are matched by
#'   `dataset_code` and `file_name`.
#' @param layer If the files hold more than one layer (data file), the layer to
#'   return: its name in the archive (the file name without the extension), or
#'   its `layer_pattern` or `feature_name` in [ksj_attributes]. The pattern and
#'   the feature name apply to every file of a dataset, but a feature name can
#'   be shared by several layers.
#' @param col_names How to name the columns. Unlike in readr, it chooses a
#'   naming, not the names themselves:
#'   * `"ja"` (the default): Japanese names of the attribute table
#'     ([ksj_attributes]). They are used only if the columns of the layer are
#'     exactly the codes that the attribute table lists for the release of the
#'     file, which it does only for the latest release of a dataset.
#'   * `"raw"`: the names of the file, usually attribute codes such as
#'     `N03_001`. Use it for older releases.
#' @returns An `sf` tibble with `dataset_code` and `file_name`, followed by the
#'   attributes and the geometry, as published. Attributes missing from a file
#'   are `NA`.
#' @export
#' @examples
#' \dontrun{
#' files <- ksj_available |>
#'   dplyr::filter(dataset_code == "N03", year == 2026, prefecture_code == "13")
#' ksj_get(files)
#' }
ksj_get <- function(files, layer = NULL, col_names = c("ja", "raw")) {
  check_data_frame(files)
  check_string(layer, allow_null = TRUE)
  col_names <- rlang::arg_match(col_names)
  files <- ksj_match_files(files)
  ksj_inform_terms(files)

  call <- rlang::current_env()
  data <- map(vctrs::vec_chop(files), \(file) {
    ksj_get_file(file, layer = layer, col_names = col_names, call = call)
  })
  ksj_bind(data, files)
}

ksj_get_file <- function(file, layer, col_names, call = rlang::caller_env()) {
  layers <- ksj_read_target(file$dataset_code, file$file_name)
  name <- ksj_select_layer(layers, file, layer, call = call)
  data <- layers[[name]]
  if (col_names == "ja") {
    data <- ksj_name_columns(data, file, name, call = call)
  }
  tibble(
    dataset_code = file$dataset_code,
    file_name = file$file_name,
    tibble::as_tibble(data)
  )
}

# Builds the target of a file, if needed, and returns its named list of layers.
ksj_read_target <- function(dataset_code, file_name) {
  tarchives::tar_get_archive_raw(
    name = ksj_target_name(file_name),
    package = "ksjdata",
    pipeline = stringr::str_to_lower(dataset_code)
  )
}

# Files ------------------------------------------------------------------------

ksj_match_files <- function(files, call = rlang::caller_env()) {
  keys <- c("dataset_code", "file_name")
  if (!all(keys %in% names(files))) {
    cli::cli_abort(
      c(
        "{.arg files} must have columns {.field dataset_code} and {.field file_name}.",
        i = "Use rows of {.code ksj_available}."
      ),
      call = call
    )
  }
  if (nrow(files) == 0) {
    cli::cli_abort("{.arg files} must have at least one row.", call = call)
  }

  available <- ksjdata::ksj_available
  index <- vctrs::vec_match(tibble::as_tibble(files[keys]), available[keys])
  if (anyNA(index)) {
    missing <- files$file_name[is.na(index)]
    cli::cli_abort(
      "Can't find {.file {missing}} in {.code ksj_available}.",
      class = "ksjdata_error_file",
      call = call
    )
  }
  available[unique(index), ]
}

ksj_inform_terms <- function(files) {
  columns <- c(
    "dataset_code",
    "dataset_name",
    "license_name",
    "license_note",
    "license_url"
  )
  datasets <- vctrs::vec_unique(files[columns])

  # rlang shows each message once per session, by the id of its dataset.
  walk(vctrs::vec_chop(datasets), \(dataset) {
    cli::cli_inform(
      c(
        "Terms of use of {dataset$dataset_code} ({dataset$dataset_name}): {dataset$license_name}",
        ksj_noncommercial(dataset$license_name, dataset$license_note),
        i = "{dataset$license_note}",
        i = "{.url {dataset$license_url}}"
      ),
      .frequency = "once",
      .frequency_id = ksj_terms_id(dataset$dataset_code)
    )
  })
  invisible()
}

ksj_terms_id <- function(dataset_code) {
  stringr::str_c("ksjdata_terms_", dataset_code)
}

# The terms of a dataset forbid commercial use if its label on the index page
# says so; its note may also forbid it for some files (A16 before 1995).
ksj_noncommercial <- function(license_name, license_note) {
  # "Non-commercial" in Japanese, written with code points so that the R code
  # stays ASCII.
  noncommercial <- stringr::fixed(intToUtf8(c(0x975e, 0x5546, 0x7528)))
  if (stringr::str_detect(license_name, noncommercial)) {
    c("!" = "Commercial use is not allowed.")
  } else if (isTRUE(stringr::str_detect(license_note, noncommercial))) {
    c("!" = "Commercial use of some files is not allowed; see the note.")
  }
}

# Layers -----------------------------------------------------------------------

# Layers of `ksj_attributes` (one per version and pattern) that describe a
# layer of a file: their pattern matches its name, or their codes are exactly
# its columns.
ksj_described_layers <- function(name, columns, dataset_code) {
  attributes <- ksjdata::ksj_attributes
  attributes <- attributes[
    ksj_dataset_key(attributes$dataset_code) == ksj_dataset_key(dataset_code),
  ]
  layers <- vctrs::vec_split(
    attributes,
    attributes[c("version_name", "layer_pattern")]
  )$val
  keep(layers, \(layer) {
    ksj_matches_pattern(name, layer) || setequal(layer$attribute_code, columns)
  })
}

# The attribute table and the download pages write the codes of some datasets
# differently (`G04a` and `G04-a`, `A18s_a` and `A18s-a`), so they are compared
# without `-` and `_`.
ksj_dataset_key <- function(dataset_code) {
  stringr::str_remove_all(dataset_code, "[-_]")
}

ksj_matches_pattern <- function(name, layer) {
  stringr::str_detect(name, ksj_layer_regex(layer$layer_pattern[[1]]))
}

# Regular expression of a shapefile name pattern of the attribute table. The
# placeholders stand for digits: `YY` and `YYYY` for years, `MM` for months,
# `DD` for days, `PP` for prefecture codes, `CCCCC` for municipality codes,
# `AA` for subprefecture codes, and `mmmm` for mesh codes.
ksj_layer_regex <- function(pattern) {
  placeholders <- c(
    YYYY = "[0-9]{4}",
    CCCCC = "[0-9]{5}",
    mmmm = "[0-9]{4}",
    YY = "[0-9]{2}",
    MM = "[0-9]{2}",
    DD = "[0-9]{2}",
    PP = "[0-9]{2}",
    AA = "[0-9]{2}"
  )
  regex <- pattern |>
    stringr::str_remove(stringr::regex("\\.shp$", ignore_case = TRUE)) |>
    stringr::str_escape() |>
    stringr::str_replace_all(
      stringr::str_flatten(names(placeholders), "|"),
      \(x) unname(placeholders[x])
    )
  stringr::str_c("^", regex, "$")
}

ksj_columns <- function(data) {
  setdiff(names(data), attr(data, "sf_column"))
}

# Values of `layer` that select each layer of a file.
ksj_layer_labels <- function(layers, dataset_code) {
  map(names(layers), \(name) {
    columns <- ksj_columns(layers[[name]])
    described <- ksj_described_layers(name, columns, dataset_code)
    described <- vctrs::vec_rbind(!!!described)
    unique(c(name, described$layer_pattern, described$feature_name))
  })
}

ksj_select_layer <- function(layers, file, layer, call = rlang::caller_env()) {
  layer_names <- names(layers)
  labels <- ksj_layer_labels(layers, file$dataset_code)
  listed <- rlang::set_names(
    cli_escape(map_chr(labels, stringr::str_flatten_comma)),
    "*"
  )

  if (is.null(layer)) {
    if (length(layer_names) == 1) {
      return(layer_names)
    }
    cli::cli_abort(
      c(
        "{.file {file$file_name}} holds more than one layer.",
        i = "Choose one with {.arg layer}:",
        listed
      ),
      class = "ksjdata_error_layer",
      call = call
    )
  }

  selected <- layer_names[map_lgl(labels, \(x) layer %in% x)]
  if (length(selected) != 1) {
    problem <- if (length(selected) == 0) {
      "{.file {file$file_name}} has no layer {.val {layer}}."
    } else {
      "{.val {layer}} matches more than one layer of {.file {file$file_name}}."
    }
    cli::cli_abort(
      c(problem, i = "Its layers are:", listed),
      class = "ksjdata_error_layer",
      call = call
    )
  }
  selected
}

# Names ------------------------------------------------------------------------

# Renames the columns of a layer to the Japanese names of the attribute table.
# The columns must be exactly the codes of a layer of the attribute table for
# the release of the file. If several layers have these codes, the one whose
# pattern matches the name is used; layers that share codes and names (A10)
# are interchangeable.
ksj_name_columns <- function(data, file, name, call = rlang::caller_env()) {
  fail <- function(problem) {
    cli::cli_abort(
      c(
        "Can't name the columns of layer {.val {name}} of {.file {file$file_name}}.",
        x = cli_escape(problem),
        i = "Use {.code col_names = \"raw\"} to keep the names of the file."
      ),
      class = "ksjdata_error_names",
      call = call
    )
  }

  columns <- ksj_columns(data)
  described <- ksj_described_layers(name, columns, file$dataset_code) |>
    keep(\(layer) layer$year[[1]] %in% file$year)
  if (length(described) == 0) {
    fail(cli::format_inline(
      "The attribute table doesn't describe this layer for the release of {file$year}."
    ))
  }

  same <- keep(described, \(layer) {
    setequal(layer$attribute_code, columns) &&
      !anyDuplicated(layer$attribute_code)
  })
  if (length(same) == 0) {
    fail(ksj_column_differences(columns, described[[1]]$attribute_code))
  }
  if (length(same) > 1) {
    by_pattern <- keep(same, \(layer) ksj_matches_pattern(name, layer))
    if (length(by_pattern) > 0) {
      same <- by_pattern
    }
  }
  named <- map(same, \(layer) layer$attribute_name[order(layer$attribute_code)])
  if (length(unique(named)) > 1) {
    fail("The columns match several layers of the attribute table.")
  }

  attributes <- same[[1]]
  if (anyNA(attributes$attribute_name)) {
    fail("The attribute table doesn't give unique names to this layer.")
  }
  index <- vctrs::vec_match(attributes$attribute_code, names(data))
  names(data)[index] <- attributes$attribute_name
  data
}

ksj_column_differences <- function(columns, codes) {
  unexpected <- setdiff(columns, codes)
  missing <- setdiff(codes, columns)
  if (length(unexpected) == 0 && length(missing) == 0) {
    return("The attribute table lists a code of this layer more than once.")
  }
  stringr::str_flatten(
    c(
      if (length(unexpected) > 0) {
        cli::format_inline(
          "Columns not in the attribute table: {.field {unexpected}}."
        )
      },
      if (length(missing) > 0) {
        cli::format_inline("Columns missing from the data: {.field {missing}}.")
      }
    ),
    " "
  )
}

# Binding ----------------------------------------------------------------------

ksj_bind <- function(data, files, call = rlang::caller_env()) {
  crs <- map(data, \(x) {
    sf::st_crs(keep(x, \(column) inherits(column, "sfc"))[[1]])
  })
  if (!all(map_lgl(crs, \(x) x == crs[[1]]))) {
    inputs <- stringr::str_replace_na(map_chr(crs, \(x) x$input), "unknown")
    cli::cli_abort(
      c(
        "Can't bind files with different coordinate reference systems.",
        rlang::set_names(
          cli_escape(stringr::str_c(files$file_name, ": ", inputs)),
          "x"
        ),
        i = "Get them separately."
      ),
      class = "ksjdata_error_crs",
      call = call
    )
  }
  sf::st_as_sf(vctrs::vec_rbind(!!!data))
}

# Utilities --------------------------------------------------------------------

# Text from the data, escaped so that cli shows it as it is.
cli_escape <- function(x) {
  stringr::str_replace_all(x, c("\\{" = "{{", "\\}" = "}}"))
}
