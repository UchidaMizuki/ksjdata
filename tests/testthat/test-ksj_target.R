test_that("ksj_target() declares a target that calls ksj_get()", {
  files <- ksj_available[ksj_available$dataset_code == "N03", ][1:2, ]

  target <- ksj_target(municipalities, files, col_names = "raw")

  expect_equal(target$settings$name, "municipalities")
  command <- target$command$expr[[1]]
  expect_equal(command[[1]], quote(ksjdata::ksj_get))
  expect_equal(eval(command$files)$file_name, files$file_name)
  expect_equal(command$col_names, "raw")
})

test_that("ksj_target_raw() errors on files that are not in ksj_available", {
  files <- tibble::tibble(dataset_code = "N03", file_name = "N03-unknown.zip")
  expect_error(ksj_target_raw("x", files), class = "ksjdata_error_file")
})

test_that("ksj_target_name() is derived from the file name", {
  expect_equal(
    ksj_target_name(c("N03-20250101_13_GML.zip", "1km_mesh_2024_GML.zip")),
    c("ksj_n03_20250101_13_gml", "ksj_1km_mesh_2024_gml")
  )
})
