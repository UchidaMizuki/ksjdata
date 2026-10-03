# Functions that read the attribute table of KSJ into `ksj_attributes`. Used by
# `data-raw/update.R`.

library(dplyr)
library(stringr)
library(tidyr)

attribute_table_url <- "https://nlftp.mlit.go.jp/ksj/gml/codelist/shape_property_table2.xlsx"

read_attributes <- function() {
  table <- read_attribute_table(attribute_table_url) |>
    fill_cells() |>
    split_patterns()

  report(
    "Layers without a shapefile name pattern (dropped):",
    table |>
      filter(is.na(layer_pattern)) |>
      distinct(dataset_code, feature_name)
  )
  table <- table |>
    filter(!is.na(layer_pattern)) |>
    mutate(year = parse_version_year(version_name))
  report(
    "Versions without a year (their names are not used):",
    table |> filter(is.na(year)) |> distinct(dataset_code, version_name)
  )

  table |>
    name_unique_layers() |>
    select(
      dataset_code,
      version_name,
      year,
      layer_pattern,
      feature_name,
      attribute_code,
      attribute_name,
      note
    )
}

read_attribute_table <- function(url) {
  path <- tempfile(fileext = ".xlsx")
  curl::curl_download(url, path)
  readxl::read_excel(path, sheet = "全データ", skip = 3, col_types = "text") |>
    set_names(c(
      "category_name",
      "subcategory_name",
      "feature_name",
      "version_name",
      "year_name",
      "layer_pattern",
      "attribute_name",
      "attribute_code",
      "dataset_code",
      "note"
    ))
}

# Cells are merged: the dataset, the layer, and the version are given on the
# first row of their group only. A cell that holds only a note in brackets,
# such as `（小班区画）`, continues the layer above it.
fill_cells <- function(table) {
  table |>
    mutate(
      layer_pattern = if_else(
        str_detect(layer_pattern, "^\\s*[（(]"),
        NA_character_,
        layer_pattern
      )
    ) |>
    fill(dataset_code) |>
    fill(feature_name, version_name, layer_pattern, .by = dataset_code)
}

# A cell can list several layers, one per line. Text after the file name in
# the same line (such as `（特別用途地区）`) is not part of the pattern.
split_patterns <- function(table) {
  table |>
    mutate(layer_pattern = str_split(layer_pattern, "\\r?\\n")) |>
    unnest_longer(layer_pattern) |>
    mutate(layer_pattern = str_trim(str_remove(layer_pattern, "[（(].*$"))) |>
    filter(is.na(layer_pattern) | nzchar(layer_pattern))
}

parse_version_year <- function(version_name) {
  as.integer(str_match(version_name, "^(\\d{4})年(?:度)?版$")[, 2])
}

# A layer gets Japanese names only if its codes and names are unique within
# it.
name_unique_layers <- function(table) {
  keys <- c("dataset_code", "version_name", "layer_pattern")
  unique_layer <- function(attribute_code, attribute_name) {
    !anyDuplicated(attribute_code) && !anyDuplicated(attribute_name)
  }
  table <- table |>
    mutate(
      unique = unique_layer(attribute_code, attribute_name),
      .by = all_of(keys)
    )

  report(
    "Layers whose codes or names are not unique (names are not used):",
    table |>
      filter(!unique) |>
      filter(n() > 1, .by = c(all_of(keys), attribute_name)) |>
      distinct(dataset_code, layer_pattern, attribute_name)
  )
  table |>
    mutate(attribute_name = if_else(unique, attribute_name, NA_character_)) |>
    select(!unique)
}
