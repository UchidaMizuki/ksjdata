test_that("ksj_get() names the columns in Japanese by default", {
  local_quiet_terms()
  named <- named_file()
  layer <- stringr::str_remove(named$file$file_name, "_GML\\.zip$")
  local_mocked_bindings(ksj_read_target = function(...) {
    rlang::set_names(list(fake_layer(named$attributes$attribute_code)), layer)
  })

  data <- ksj_get(named$file)

  expect_s3_class(data, "sf")
  expect_s3_class(data, "tbl_df")
  expect_named(
    data,
    c("dataset_code", "file_name", named$attributes$attribute_name, "geometry")
  )
  expect_equal(data$file_name, named$file$file_name)
})

test_that("ksj_get() names a layer by its columns when its name doesn't match", {
  local_quiet_terms()
  named <- named_file()
  local_mocked_bindings(ksj_read_target = function(...) {
    list(nationwide = fake_layer(rev(named$attributes$attribute_code)))
  })

  data <- ksj_get(named$file)

  expect_named(
    data,
    c(
      "dataset_code",
      "file_name",
      rev(named$attributes$attribute_name),
      "geometry"
    )
  )
})

test_that("ksj_get() keeps the names of the file with col_names = 'raw'", {
  local_quiet_terms()
  named <- named_file()
  layer <- stringr::str_remove(named$file$file_name, "_GML\\.zip$")
  local_mocked_bindings(ksj_read_target = function(...) {
    rlang::set_names(list(fake_layer(c("N03_001", "extra"))), layer)
  })

  data <- ksj_get(named$file, col_names = "raw")

  expect_named(
    data,
    c("dataset_code", "file_name", "N03_001", "extra", "geometry")
  )
})

test_that("ksj_get() doesn't name a layer that is not fully covered", {
  local_quiet_terms()
  named <- named_file()
  layer <- stringr::str_remove(named$file$file_name, "_GML\\.zip$")
  columns <- c(named$attributes$attribute_code, "extra")
  local_mocked_bindings(ksj_read_target = function(...) {
    rlang::set_names(list(fake_layer(columns)), layer)
  })

  expect_snapshot(ksj_get(named$file), error = TRUE)
})

test_that("ksj_get() doesn't name older releases", {
  local_quiet_terms()
  file <- ksj_available[
    ksj_available$dataset_code == "N03" & ksj_available$year == 2000,
  ][1, ]
  local_mocked_bindings(ksj_read_target = function(...) {
    list(layer = fake_layer("N03_001"))
  })

  expect_error(ksj_get(file), class = "ksjdata_error_names")
  expect_equal(names(ksj_get(file, col_names = "raw"))[[3]], "N03_001")
})

test_that("ksj_get() selects a layer with `layer`", {
  local_quiet_terms()
  named <- named_file()
  layer <- stringr::str_remove(named$file$file_name, "_GML\\.zip$")
  local_mocked_bindings(ksj_read_target = function(...) {
    rlang::set_names(
      list(fake_layer(named$attributes$attribute_code), fake_layer("other")),
      c(layer, "other")
    )
  })

  expect_snapshot(ksj_get(named$file), error = TRUE)
  expect_equal(
    names(ksj_get(named$file, layer = "other", col_names = "raw"))[[3]],
    "other"
  )
  pattern <- named$attributes$layer_pattern[[1]]
  expect_equal(nrow(ksj_get(named$file, layer = pattern)), 1)
  feature_name <- named$attributes$feature_name[[1]]
  expect_equal(nrow(ksj_get(named$file, layer = feature_name)), 1)
  expect_error(
    ksj_get(named$file, layer = "none"),
    class = "ksjdata_error_layer"
  )
})

test_that("ksj_get() binds files, filling missing attributes with NA", {
  local_quiet_terms()
  files <- ksj_available[
    ksj_available$dataset_code == "N03" & ksj_available$year == 2000,
  ][1:2, ]
  local_mocked_bindings(ksj_read_target = function(dataset_code, file_name) {
    columns <- if (file_name == files$file_name[[1]]) "a" else c("a", "b")
    list(layer = fake_layer(columns))
  })

  data <- ksj_get(files, col_names = "raw")

  expect_equal(data$file_name, files$file_name)
  expect_equal(data$b, c(NA, "x"))
})

test_that("ksj_get() doesn't bind files with different CRS", {
  local_quiet_terms()
  files <- ksj_available[
    ksj_available$dataset_code == "N03" & ksj_available$year == 2000,
  ][1:2, ]
  local_mocked_bindings(ksj_read_target = function(dataset_code, file_name) {
    crs <- if (file_name == files$file_name[[1]]) 6668 else 4612
    list(layer = fake_layer("a", crs = crs))
  })

  expect_error(ksj_get(files, col_names = "raw"), class = "ksjdata_error_crs")
})

test_that("ksj_get() errors on files that are not in ksj_available", {
  files <- tibble::tibble(dataset_code = "N03", file_name = "N03-unknown.zip")
  expect_snapshot(ksj_get(files), error = TRUE)
  expect_snapshot(ksj_get(tibble::tibble(x = 1)), error = TRUE)
})

test_that("ksj_get() checks its arguments", {
  file <- ksj_available[1, ]
  expect_snapshot(ksj_get(file, col_names = "code"), error = TRUE)
  expect_snapshot(ksj_get(file, layer = 1), error = TRUE)
})

test_that("ksj_get() shows the terms of a dataset once per session", {
  rlang::reset_message_verbosity(ksj_terms_id("N03"))
  withr::defer(rlang::reset_message_verbosity(ksj_terms_id("N03")))
  file <- ksj_available[ksj_available$dataset_code == "N03", ][1, ]
  local_mocked_bindings(ksj_read_target = function(...) {
    list(layer = fake_layer("a"))
  })

  expect_message(ksj_get(file, col_names = "raw"), "Terms of use of N03")
  expect_no_message(ksj_get(file, col_names = "raw"))
})

test_that("ksj_noncommercial() states that commercial use is not allowed", {
  noncommercial <- "非商用"
  expect_named(ksj_noncommercial(noncommercial, NA), "!")
  expect_match(ksj_noncommercial("CC_BY_4.0", noncommercial), "some files")
  expect_null(ksj_noncommercial("CC_BY_4.0", NA))
})

test_that("ksj_layer_regex() replaces the placeholders by digits", {
  expect_match("N03-20250101_13", ksj_layer_regex("N03-YYYYMMDD_PP.shp"))
  expect_match("A10-15_47", ksj_layer_regex("A10-YY_PP"))
  expect_match("G02-22_5339-jgd", ksj_layer_regex("G02-YY_mmmm-jgd.shp"))
  expect_no_match("N03-200101_13", ksj_layer_regex("N03-YYYYMMDD_PP.shp"))
  expect_no_match("A03-25xSYUTO", ksj_layer_regex("A03-YY.SYUTO.shp"))
})
