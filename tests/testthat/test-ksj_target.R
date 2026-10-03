test_that("ksj_target() declares a target that calls ksj_get()", {
  file_name <- ksj_available$file_name[[1]]

  target <- ksj_target(municipalities, file_name, col_names = "raw")

  expect_equal(target$settings$name, "municipalities")
  expect_equal(
    target$command$expr[[1]],
    rlang::call2(
      "ksj_get",
      file_name = file_name,
      layer = NULL,
      col_names = "raw",
      .ns = "ksjdata"
    )
  )
})

test_that("ksj_target_raw() errors on files that are not in ksj_available", {
  expect_error(
    ksj_target_raw("x", "N03-unknown.zip"),
    class = "ksjdata_error_file"
  )
})

test_that("ksj_target_name() is derived from the file name", {
  expect_equal(
    ksj_target_name(c("N03-20250101_13_GML.zip", "1km_mesh_2024_GML.zip")),
    c("ksj_n03_20250101_13_gml", "ksj_1km_mesh_2024_gml")
  )
})
