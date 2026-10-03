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

test_that("every file is identified by its name", {
  expect_no_error(ksj_check_files(ksj_available))
})

test_that("ksj_check_files() errors on names that don't identify a file", {
  url <- "https://nlftp.mlit.go.jp/ksj/gml/data/N03/"
  files <- tibble::tibble(
    file_name = c("A.zip", "A.zip", "B-1.zip", "B_1.zip", "C.zip"),
    url = stringr::str_c(
      url,
      c("A.zip", "A.zip", "B-1.zip", "B_1.zip", "D.zip")
    )
  )
  expect_snapshot(ksj_check_files(files), error = TRUE)
})

test_that("every release has a year", {
  expect_false(anyNA(ksj_available$year))
  expect_all_true(ksj_available$year >= 1900)
})
