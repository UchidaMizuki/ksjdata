test_that("ksj_attributes is up to date with the attribute table", {
  dir <- test_path("..", "..", "data-raw")
  skip_if_not(fs::file_exists(fs::path(dir, "attributes.csv")), "No data-raw/")
  expect_equal(ksj_attributes, ksj_attributes_impl(dir))
})

test_that("names are unique or all NA within each layer", {
  layers <- vctrs::vec_split(
    ksj_attributes,
    ksj_attributes[c("dataset_code", "version_name", "layer_pattern")]
  )$val
  for (layer in layers) {
    if (anyNA(layer$attribute_name)) {
      expect_all_true(is.na(layer$attribute_name))
    } else {
      expect_equal(anyDuplicated(layer$attribute_name), 0)
    }
  }
})

test_that("every dataset of ksj_available is described by ksj_attributes", {
  expect_in(
    ksj_dataset_key(ksj_available$dataset_code),
    ksj_dataset_key(ksj_attributes$dataset_code)
  )
})
