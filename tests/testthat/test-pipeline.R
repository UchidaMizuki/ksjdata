test_that("ksj_read_archive() reads shapefiles when the archive has them", {
  helpers <- pipeline_helpers()
  layers <- helpers$ksj_read_archive(
    test_path("fixtures", "geojson-and-shapefile.zip"),
    withr::local_tempdir()
  )

  expect_named(layers, "N03-20250101_13")
  expect_named(layers[[1]], c("N03_001", "N03_007", "geometry"))
  expect_equal(layers[[1]]$N03_001, "東京都")
  expect_equal(layers[[1]]$N03_007, "13101")
  expect_equal(sf::st_crs(layers[[1]])$epsg, 6668L)
  expect_s3_class(layers[[1]], "sf")
})

test_that("ksj_read_archive() extracts only the members of the layers", {
  helpers <- pipeline_helpers()
  exdir <- withr::local_tempdir()
  helpers$ksj_read_archive(
    test_path("fixtures", "geojson-and-shapefile.zip"),
    exdir
  )

  expect_setequal(
    fs::path_ext(fs::dir_ls(exdir)),
    c("shp", "shx", "dbf", "prj", "cpg")
  )
})

test_that("ksj_read_archive() reads GeoJSON without shapefiles", {
  helpers <- pipeline_helpers()
  layers <- helpers$ksj_read_archive(
    test_path("fixtures", "geojson.zip"),
    withr::local_tempdir()
  )

  expect_named(layers, "N03-20250101_13")
  expect_equal(layers[[1]]$N03_007, "13101")
})

test_that("ksj_read_archive() reads shapefiles without .cpg as CP932", {
  helpers <- pipeline_helpers()
  layers <- helpers$ksj_read_archive(
    test_path("fixtures", "shapefile.zip"),
    withr::local_tempdir()
  )

  expect_named(
    layers,
    c("S05-d-10-g_CargoRegionFlow", "S05-d-10-g_PassengerRegionFlow")
  )
  cargo <- layers[["S05-d-10-g_CargoRegionFlow"]]
  expect_equal(cargo$S05d_001, c("北海道", "沖縄"))
  expect_equal(cargo$S05d_002, c(0, NA))
  expect_equal(sf::st_crs(cargo)$epsg, 4612L)
})

test_that("ksj_read_archive() errors without GeoJSON or shapefiles", {
  helpers <- pipeline_helpers()
  expect_error(
    helpers$ksj_read_archive(
      test_path("fixtures", "gml.zip"),
      withr::local_tempdir()
    ),
    class = "ksjdata_error_no_layers"
  )
})

test_that("ksj_layer_names() drops directories, including backslashes", {
  helpers <- pipeline_helpers()
  expect_equal(
    helpers$ksj_layer_names(c("a/10_x\\A31b-10.geojson", "b/A31b-20.geojson")),
    c("A31b-10", "A31b-20")
  )
  expect_error(
    helpers$ksj_layer_names(c("a/x.shp", "b/x.shp")),
    class = "ksjdata_error_layer_names"
  )
})

test_that("ksj_build_file() downloads and reads an archive", {
  helpers <- pipeline_helpers()
  path <- fs::path_abs(test_path("fixtures", "geojson.zip"))
  url <- stringr::str_c("file://", if (!startsWith(path, "/")) "/", path)

  layers <- helpers$ksj_build_file(url, 0.01)

  expect_named(layers, "N03-20250101_13")
})

test_that("every pipeline has one target per file of its dataset", {
  helpers <- pipeline_helpers()
  for (pipeline in tarchives::tar_archive_pipelines("ksjdata")) {
    files <- ksj_available[
      stringr::str_to_lower(ksj_available$dataset_code) == pipeline,
    ]
    targets <- unlist(helpers$ksj_pipeline(pipeline))
    names <- map_chr(targets, \(x) x$settings$name)
    expect_setequal(names, ksj_target_name(files$file_name))
    expect_length(names, nrow(files))
  }
})

test_that("every pipeline script differs only in its code", {
  for (pipeline in tarchives::tar_archive_pipelines("ksjdata")) {
    script <- tarchives::tar_archive_script("ksjdata", pipeline)
    expect_equal(
      readLines(script),
      c(
        "library(targets)",
        "",
        "tarchives::tar_source_archive(\"ksjdata\")",
        "",
        stringr::str_c("ksj_pipeline(\"", pipeline, "\")")
      )
    )
  }
})
