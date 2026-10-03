# Reports of the scripts in `data-raw/`.

library(dplyr)
library(stringr)

report <- function(message, rows) {
  if (nrow(rows) > 0) {
    message(message)
    print(rows, n = Inf)
  }
}

# Rows of a data object added, removed, or changed since the saved one,
# counted by dataset.
report_changes <- function(name, new, keys) {
  path <- fs::path("data", name, ext = "rda")
  if (!fs::file_exists(path)) {
    return(invisible())
  }
  env <- new.env()
  load(path, envir = env)
  plain <- function(data) {
    mutate(data, across(where(\(x) inherits(x, "units")), as.numeric))
  }
  old <- plain(env[[name]])
  new <- plain(new)
  changes <- bind_rows(
    added = anti_join(new, old, by = keys),
    removed = anti_join(old, new, by = keys),
    changed = new |>
      semi_join(old, by = keys) |>
      anti_join(old, by = names(new)),
    .id = "change"
  )
  report(
    str_c("Changes of `", name, "`:"),
    count(changes, dataset_code, change)
  )
}
