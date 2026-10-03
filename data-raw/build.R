# Builds the data of the package from the files in `data-raw/`, offline: the
# pipelines, `data/ksj_attributes.rda`, and `data/ksj_available.rda`. Run from
# the root of the package, by `data-raw/update.R` or alone after changing the
# pipelines, `ksj_attributes_impl()`, or `ksj_available_impl()`.

devtools::load_all()
source("data-raw/report.R")

ksj_attributes <- ksj_attributes_impl()
files <- readr::read_csv(
  "data-raw/catalog.csv",
  col_types = readr::cols(.default = "c")
)
datasets <- readr::read_csv(
  "data-raw/datasets.csv",
  col_types = readr::cols(.default = "c")
)

# Pipelines --------------------------------------------------------------------

# A pipeline for each dataset with files that the attribute table describes.
codes <- files$dataset_code[
  ksj_dataset_key(files$dataset_code) %in%
    ksj_dataset_key(ksj_attributes$dataset_code)
]
codes <- sort(unique(str_to_lower(codes)))

pipeline_script <- function(code) {
  c(
    "library(targets)",
    "",
    "tarchives::tar_source_archive(\"ksjdata\")",
    "",
    str_c("ksj_pipeline(\"", code, "\")")
  )
}
for (code in codes) {
  dir <- fs::dir_create(fs::path("inst/tarchives", code))
  writeLines(pipeline_script(code), fs::path(dir, "_targets.R"))
}

report(
  "Pipelines of datasets that are no longer supported (delete them):",
  tibble(
    pipeline = setdiff(
      fs::path_file(fs::dir_ls("inst/tarchives", type = "directory")),
      c(codes, "R")
    )
  )
)
report(
  "Datasets without a pipeline:",
  datasets |>
    filter(!str_to_lower(dataset_code) %in% codes) |>
    select(dataset_code, dataset_name)
)
report(
  "Datasets of the attribute table not in the catalog:",
  ksj_attributes |>
    filter(
      !ksj_dataset_key(dataset_code) %in% ksj_dataset_key(files$dataset_code)
    ) |>
    distinct(dataset_code, feature_name)
)

# Data -------------------------------------------------------------------------

ksj_available <- ksj_available_impl()

report_changes(
  "ksj_attributes",
  ksj_attributes,
  c("dataset_code", "version_name", "layer_pattern", "attribute_code")
)
report_changes("ksj_available", ksj_available, c("dataset_code", "file_name"))
usethis::use_data(
  ksj_attributes,
  ksj_available,
  overwrite = TRUE,
  compress = "xz"
)
