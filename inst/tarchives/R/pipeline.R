# Helpers shared by the pipelines of ksjdata, sourced by
# `tarchives::tar_source_archive("ksjdata")`.

# Targets of a dataset: one static branch per file of the dataset in
# `ksj_available`. The URL and the size are part of the command, so a change of
# either rebuilds that target only.
ksj_pipeline <- function(code) {
  files <- ksjdata::ksj_available
  files <- files[stringr::str_to_lower(files$dataset_code) == code, ]
  values <- tibble::tibble(
    suffix = ksjdata:::ksj_target_suffix(files$file_name),
    url = files$url,
    file_size = as.numeric(files$file_size)
  )
  tarchetypes::tar_map(
    values = values,
    names = "suffix",
    targets::tar_target(ksj, ksj_build_file(url, file_size))
  )
}

# Downloads an archive to a temporary directory and reads its layers. The
# archive is not kept. `file_size` is unused: it is an argument so that the
# published size is part of the command.
ksj_build_file <- function(url, file_size) {
  dir <- fs::dir_create(fs::file_temp("ksjdata"))
  on.exit(fs::dir_delete(dir), add = TRUE)
  archive <- fs::path(dir, "archive.zip")
  curl::curl_download(url, archive, quiet = TRUE)
  ksj_read_archive(archive, fs::path(dir, "files"))
}

# Named list of the layers of an archive, with the column names of the files.
# The names are the file names of the layers without the extension. Only the
# members of the layers are extracted.
ksj_read_archive <- function(archive, exdir) {
  members <- ksj_layer_members(zip::zip_list(archive)$filename)
  # zip::unzip() extracts member names in Shift_JIS, which utils::unzip()
  # fails on.
  zip::unzip(archive, files = members, exdir = exdir)
  paths <- ksj_layer_paths(exdir)
  layers <- purrr::map(paths, ksj_read_layer)
  names(layers) <- ksj_layer_names(paths)
  layers
}

# Members of the layers: the files of the shapefiles when the archive has
# them, otherwise the GeoJSON files. The attribute table describes the
# shapefiles, whose columns are the codes and whose `.prj` gives the datum;
# GeoJSON may name its properties otherwise (L03-b) and is read as WGS 84
# without a `crs` member (S05-d). GML is not read.
ksj_layer_members <- function(members) {
  extensions <- stringr::str_to_lower(fs::path_ext(members))
  layers <- fs::path_ext_remove(members)
  shapefiles <- layers[extensions == "shp"]
  if (length(shapefiles) > 0) {
    parts <- c("shp", "shx", "dbf", "prj", "cpg")
    return(members[layers %in% shapefiles & extensions %in% parts])
  }
  geojson <- members[extensions == "geojson"]
  if (length(geojson) > 0) {
    return(geojson)
  }
  rlang::abort(
    "The archive has neither shapefiles nor GeoJSON.",
    class = "ksjdata_error_no_layers"
  )
}

# Paths of the extracted layers.
ksj_layer_paths <- function(dir) {
  files <- fs::dir_ls(dir, recurse = TRUE, type = "file")
  extensions <- stringr::str_to_lower(fs::path_ext(files))
  paths <- files[extensions %in% c("shp", "geojson")]
  unname(sort(paths))
}

# Member names may use backslashes as separators.
ksj_layer_names <- function(paths) {
  names <- stringr::str_remove(
    fs::path_ext_remove(fs::path_file(paths)),
    "^.*\\\\"
  )
  duplicated <- unique(names[duplicated(names)])
  if (length(duplicated) > 0) {
    rlang::abort(
      stringr::str_c(
        "The archive has more than one layer named ",
        stringr::str_flatten_comma(duplicated),
        "."
      ),
      class = "ksjdata_error_layer_names"
    )
  }
  names
}

# Shapefiles are read with the encoding of their `.cpg` file, or as CP932
# (Shift_JIS) without one.
ksj_read_layer <- function(path) {
  options <- character()
  if (stringr::str_to_lower(fs::path_ext(path)) == "shp") {
    cpg <- fs::path_ext_set(path, c("cpg", "CPG"))
    if (!any(fs::file_exists(cpg))) {
      options <- "ENCODING=CP932"
    }
  }
  sf::read_sf(path, options = options)
}
