test_that("ksj_available is up to date with the scraped catalog", {
  dir <- test_path("..", "..", "data-raw")
  skip_if_not(fs::file_exists(fs::path(dir, "catalog.csv")), "No data-raw/")
  expect_equal(ksj_available, ksj_available_impl(dir))
})

test_that("ksj_available is a plain tibble", {
  expect_identical(class(ksj_available), c("tbl_df", "tbl", "data.frame"))
  expect_named(
    attributes(ksj_available),
    c("names", "row.names", "class"),
    ignore.order = TRUE
  )
})

test_that("every pipeline has files, and every file has a pipeline", {
  expect_setequal(
    tarchives::tar_archive_pipelines("ksjdata"),
    unique(stringr::str_to_lower(ksj_available$dataset_code))
  )
})

test_that("file names and target names are unique within each dataset", {
  expect_equal(
    anyDuplicated(ksj_available[c("dataset_code", "file_name")]),
    0
  )
  targets <- tibble::tibble(
    dataset_code = ksj_available$dataset_code,
    name = ksj_target_name(ksj_available$file_name)
  )
  expect_equal(anyDuplicated(targets), 0)
})

test_that("every release has a year", {
  expect_false(anyNA(ksj_available$year))
  expect_all_true(ksj_available$year >= 1900)
})
