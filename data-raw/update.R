# Updates the files in `data-raw/` from the KSJ site, and builds the data of
# the package from them. Run from the root of the package; it needs the
# network:
#
# 1. reads the attribute table into `data-raw/attributes.csv`,
# 2. scrapes the catalog into `data-raw/datasets.csv` and
#    `data-raw/catalog.csv`,
# 3. runs `data-raw/build.R`, which builds the pipelines and the data objects
#    from them, offline.

source("data-raw/report.R")
source("data-raw/attributes.R")
source("data-raw/catalog.R")

readr::write_csv(read_attributes(), "data-raw/attributes.csv", na = "")

catalog <- read_catalog()
readr::write_csv(catalog$datasets, "data-raw/datasets.csv", na = "")
readr::write_csv(catalog$files, "data-raw/catalog.csv", na = "")

source("data-raw/build.R")
