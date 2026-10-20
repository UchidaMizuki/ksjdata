# Helpers shared by the pipelines of ksjdata, sourced by
# `tarchives::tar_source_archive("ksjdata")`.

# Targets of a dataset: one per file of the dataset in `ksj_available`. The URL
# and the size are part of the command, so a change of either rebuilds that
# target only.
ksj_pipeline <- function(code) {
  files <- ksjdata::ksj_available
  files <- files[stringr::str_to_lower(files$dataset_code) == code, ]
  tarchetypes::tar_eval(
    targets::tar_target(name, ksj_build_file(url, file_size)),
    values = list(
      name = rlang::syms(ksjdata::ksj_target_name(files$file_name)),
      url = files$url,
      file_size = as.numeric(files$file_size)
    )
  )
}

# Downloads an archive to a temporary directory and reads its layers. The
# archive is not kept. The value keeps the URL, which `ksj_get()` checks
# against `ksj_available`. `file_size` is unused: it is an argument so that the
# published size is part of the command.
ksj_build_file <- function(url, file_size) {
  dir <- fs::dir_create(fs::file_temp("ksjdata"))
  on.exit(fs::dir_delete(dir), add = TRUE)
  archive <- fs::path(dir, "archive.zip")
  curl::curl_download(url, archive, quiet = TRUE)
  list(url = url, layers = ksj_read_archive(archive, fs::path(dir, "files")))
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
  members <- ksj_drop_encoding_copies(members)
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

# Since 2021, some archives (N02, N05, N06) hold the same files twice, in a
# folder `Shift-JIS` and in a folder `UTF-8`. The copies in `Shift-JIS` are
# dropped when the same file is also in `UTF-8`, so that each layer is read
# once, in UTF-8.
ksj_drop_encoding_copies <- function(members) {
  folders <- ksj_encoding_folder(members)
  files <- fs::path_file(stringr::str_replace_all(
    members,
    stringr::fixed("\\"),
    "/"
  ))
  utf8 <- files[folders %in% "UTF-8"]
  members[!(folders %in% "Shift-JIS" & files %in% utf8)]
}

# The encoding folder (`UTF-8` or `Shift-JIS`) of each path, or `NA`.
ksj_encoding_folder <- function(paths) {
  parts <- stringr::str_split(paths, "[/\\\\]")
  purrr::map_chr(parts, \(parts) {
    folder <- intersect(c("UTF-8", "Shift-JIS"), parts)
    if (length(folder) == 1) folder else NA_character_
  })
}

# Paths of the extracted layers.
ksj_layer_paths <- function(dir) {
  files <- fs::dir_ls(dir, recurse = TRUE, type = "file")
  extensions <- stringr::str_to_lower(fs::path_ext(files))
  paths <- files[extensions %in% c("shp", "geojson")]
  unname(sort(paths))
}

# Member names may use backslashes as separators, which fs treats as
# separators on Windows only, so they are replaced first.
ksj_layer_names <- function(paths) {
  names <- paths |>
    stringr::str_replace_all(stringr::fixed("\\"), "/") |>
    fs::path_file() |>
    fs::path_ext_remove() |>
    as.character()
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

# Shapefiles are read with the encoding of their `.cpg` file. Without one, they
# are read as UTF-8 in a folder `UTF-8`, and as CP932 (Shift_JIS) otherwise.
ksj_read_layer <- function(path) {
  options <- character()
  if (stringr::str_to_lower(fs::path_ext(path)) == "shp") {
    cpg <- fs::path_ext_set(path, c("cpg", "CPG"))
    if (!any(fs::file_exists(cpg))) {
      encoding <- if (ksj_encoding_folder(path) %in% "UTF-8") {
        "UTF-8"
      } else {
        "CP932"
      }
      options <- paste0("ENCODING=", encoding)
    }
  }
  sf::read_sf(path, options = options)
}
