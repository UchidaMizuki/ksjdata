# Writes the synthetic archives used by the tests. Run from the package root:
# source("tests/testthat/fixtures/make-fixtures.R")

library(sf)

fixtures <- "tests/testthat/fixtures"

square <- function(x, y) {
  st_polygon(list(rbind(
    c(x, y),
    c(x + 1, y),
    c(x + 1, y + 1),
    c(x, y + 1),
    c(x, y)
  )))
}

write_archive <- function(zipfile, write) {
  dir <- tempfile()
  dir.create(dir)
  write(dir)
  zipfile <- normalizePath(zipfile, mustWork = FALSE)
  unlink(zipfile)
  zip::zip(zipfile, files = list.files(dir), root = dir)
}

# An archive with GeoJSON and shapefiles, like N03 since 2017. The GeoJSON
# holds other names and values, so that a test can tell which one was read.
write_archive(file.path(fixtures, "geojson-and-shapefile.zip"), function(dir) {
  shapefile <- st_sf(
    N03_001 = "東京都",
    N03_007 = "13101",
    geometry = st_sfc(square(139, 35), crs = 6668)
  )
  write_sf(
    shapefile,
    file.path(dir, "N03-20250101_13.shp"),
    layer_options = "ENCODING=UTF-8"
  )
  geojson <- st_sf(
    "都道府県名" = "geojson",
    geometry = st_sfc(square(139, 35), crs = 4326)
  )
  write_sf(geojson, file.path(dir, "N03-20250101_13.geojson"))
  writeLines("<gml/>", file.path(dir, "N03-20250101_13.xml"))
})

# An archive with GeoJSON only.
write_archive(file.path(fixtures, "geojson.zip"), function(dir) {
  geojson <- st_sf(
    N03_001 = "東京都",
    N03_007 = "13101",
    geometry = st_sfc(square(139, 35), crs = 6668)
  )
  write_sf(geojson, file.path(dir, "N03-20250101_13.geojson"))
})

# An archive with two shapefiles in Shift_JIS without `.cpg` files, like S05-d
# before 2016. Counts include a published zero and a blank cell.
write_archive(file.path(fixtures, "shapefile.zip"), function(dir) {
  cargo <- st_sf(
    S05d_001 = c("北海道", "沖縄"),
    S05d_002 = c(0, NA),
    geometry = st_sfc(square(141, 43), square(127, 26), crs = 4612)
  )
  passenger <- st_sf(
    S05d_044 = "東京",
    geometry = st_sfc(st_point(c(139, 35)), crs = 4612)
  )
  write_sf(
    cargo,
    file.path(dir, "S05-d-10-g_CargoRegionFlow.shp"),
    layer_options = "ENCODING=CP932"
  )
  write_sf(
    passenger,
    file.path(dir, "S05-d-10-g_PassengerRegionFlow.shp"),
    layer_options = "ENCODING=CP932"
  )
  unlink(list.files(dir, "\\.cpg$", full.names = TRUE))
  writeLines("<gml/>", file.path(dir, "S05-d-10-g.xml"))
})

# An archive with GML only.
write_archive(file.path(fixtures, "gml.zip"), function(dir) {
  writeLines("<gml/>", file.path(dir, "N03-20250101_13.xml"))
})
