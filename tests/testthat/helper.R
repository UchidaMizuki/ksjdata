# Environment with the helpers shared by the bundled pipelines.
pipeline_helpers <- function() {
  env <- new.env()
  tarchives::tar_source_archive("ksjdata", envir = env)
  env
}

# A layer with the given columns, all character.
fake_layer <- function(columns, n = 1, crs = 6668) {
  values <- rep(list(rep("x", n)), length(columns))
  names(values) <- columns
  geometry <- sf::st_sfc(rep(list(sf::st_point(c(139, 35))), n), crs = crs)
  sf::st_sf(tibble::as_tibble(values), geometry = geometry)
}

# A file of `ksj_available` whose layer is fully described by `ksj_attributes`
# in Japanese.
named_file <- function() {
  latest <- max(ksj_available$year[ksj_available$dataset_code == "N03"])
  attributes <- ksj_attributes[
    ksj_attributes$dataset_code == "N03" & ksj_attributes$year %in% latest,
  ]
  files <- ksj_available[
    ksj_available$dataset_code == "N03" &
      ksj_available$year == attributes$year[[1]] &
      ksj_available$prefecture_code %in% "13",
  ]
  list(file = files[1, ], attributes = attributes)
}

# Hides the terms of use, which rlang shows once per session.
local_quiet_terms <- function(env = parent.frame()) {
  withr::local_options(rlang_message_verbosity = "quiet", .local_envir = env)
}
