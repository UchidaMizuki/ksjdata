test_that("ksj_get() names the columns in Japanese by default", {
  local_quiet_terms()
  named <- named_file()
  layer <- stringr::str_remove(named$file$file_name, "_GML\\.zip$")
  local_mocked_bindings(ksj_read_target = function(...) {
    rlang::set_names(list(fake_layer(named$attributes$attribute_code)), layer)
  })

  data <- ksj_get(named$file$file_name)

  expect_s3_class(data, "sf")
  expect_s3_class(data, "tbl_df")
  expect_named(data, c(named$attributes$attribute_name, "geometry"))
})

test_that("ksj_get() names a layer by its columns when its name doesn't match", {
  local_quiet_terms()
  named <- named_file()
  local_mocked_bindings(ksj_read_target = function(...) {
    list(nationwide = fake_layer(rev(named$attributes$attribute_code)))
  })

  data <- ksj_get(named$file$file_name)

  expect_named(data, c(rev(named$attributes$attribute_name), "geometry"))
})

test_that("ksj_get() keeps the names of the file with col_names = 'raw'", {
  local_quiet_terms()
  named <- named_file()
  layer <- stringr::str_remove(named$file$file_name, "_GML\\.zip$")
  local_mocked_bindings(ksj_read_target = function(...) {
    rlang::set_names(list(fake_layer(c("N03_001", "extra"))), layer)
  })

  data <- ksj_get(named$file$file_name, col_names = "raw")

  expect_named(data, c("N03_001", "extra", "geometry"))
})

test_that("ksj_get() doesn't name a layer that is not fully covered", {
  local_quiet_terms()
  named <- named_file()
  layer <- stringr::str_remove(named$file$file_name, "_GML\\.zip$")
  columns <- c(named$attributes$attribute_code, "extra")
  local_mocked_bindings(ksj_read_target = function(...) {
    rlang::set_names(list(fake_layer(columns)), layer)
  })

  expect_snapshot(ksj_get(named$file$file_name), error = TRUE)
})

test_that("ksj_get() doesn't name older releases", {
  local_quiet_terms()
  file <- ksj_available[
    ksj_available$dataset_code == "N03" & ksj_available$year == 2000,
  ][1, ]
  local_mocked_bindings(ksj_read_target = function(...) {
    list(layer = fake_layer("N03_001"))
  })

  expect_error(ksj_get(file$file_name), class = "ksjdata_error_names")
  expect_named(
    ksj_get(file$file_name, col_names = "raw"),
    c("N03_001", "geometry")
  )
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

  expect_snapshot(ksj_get(named$file$file_name), error = TRUE)
  expect_equal(
    names(ksj_get(named$file$file_name, layer = "other", col_names = "raw")),
    c("other", "geometry")
  )
  pattern <- named$attributes$layer_pattern[[1]]
  expect_equal(nrow(ksj_get(named$file$file_name, layer = pattern)), 1)
  feature_name <- named$attributes$feature_name[[1]]
  expect_equal(nrow(ksj_get(named$file$file_name, layer = feature_name)), 1)
  expect_error(
    ksj_get(named$file$file_name, layer = "none"),
    class = "ksjdata_error_layer"
  )
})

test_that("ksj_get() errors on files that are not in ksj_available", {
  expect_snapshot(ksj_get("N03-unknown.zip"), error = TRUE)
})

test_that("ksj_get() checks its arguments", {
  file_name <- ksj_available$file_name[[1]]
  expect_snapshot(ksj_get(ksj_available[1, ]), error = TRUE)
  expect_snapshot(ksj_get(file_name, col_names = "code"), error = TRUE)
  expect_snapshot(ksj_get(file_name, layer = 1), error = TRUE)
})

test_that("ksj_get() shows the terms of a dataset once per session", {
  rlang::reset_message_verbosity(ksj_terms_id("N03"))
  withr::defer(rlang::reset_message_verbosity(ksj_terms_id("N03")))
  file_name <- ksj_available$file_name[ksj_available$dataset_code == "N03"][[1]]
  local_mocked_bindings(ksj_read_target = function(...) {
    list(layer = fake_layer("a"))
  })

  expect_message(ksj_get(file_name, col_names = "raw"), "Terms of use of N03")
  expect_no_message(ksj_get(file_name, col_names = "raw"))
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

test_that("ksj_get() reads the target named after the file", {
  file <- named_file()$file
  local_mocked_bindings(ksj_get_archive = function(name, pipeline) {
    list(url = file$url, layers = list(name = name, pipeline = pipeline))
  })

  expect_equal(
    ksj_read_target(file),
    list(name = ksj_target_name(file$file_name), pipeline = "n03")
  )
})

test_that("ksj_get() errors on cached data that are not from the file's URL", {
  local_quiet_terms()
  file <- named_file()$file
  local_mocked_bindings(ksj_get_archive = function(...) {
    list(url = "https://nlftp.mlit.go.jp/ksj/gml/data/N03/other.zip")
  })

  expect_snapshot(ksj_get(file$file_name), error = TRUE)
})
