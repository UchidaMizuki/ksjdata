# Architecture

## Purpose

National Land Numerical Information (国土数値情報, KSJ), published by
the Ministry of Land, Infrastructure, Transport and Tourism, through one
catalog. Datasets are added as they are needed and become supported (see
[Supported datasets](#supported-datasets)).

- `ksj_available` is the catalog that users see: it lists every
  supported file, with its dataset, release, area, and terms of use.
  Users browse and filter it to find what they need. A file that is not
  in it is not supported.
- [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
  takes the name of one file of `ksj_available` and returns one layer of
  it. Nothing else is downloaded.

Out of scope: transformations for a particular analysis (simplifying,
dissolving, aggregating, reprojecting), harmonizing attributes across
releases, inventing names, and redistributing data.

## Principles

- **Simple, readable code.** One small function per step (scrape,
  download, read, name). Plain tibbles and `sf` objects; no tibble
  subclasses, no hidden columns or attributes.
- **`ksj_available` is the catalog.** Pages are scraped by the
  maintainer, not at run time, so users do not depend on the layout of
  the site. The scraped catalog is kept as text in `data-raw/`, not
  shipped, so that `ksj_available` can be rebuilt and checked offline,
  and every change of the site is reviewed as a diff.
- **Plain HTTP downloads.** The URL of every archive is in the download
  links of its page, so no browser automation is needed.
- **Official names only.** Names come from the attribute table that KSJ
  publishes, never typed into the package by hand.
- **Checked before trusted.** Every link between the catalog, the
  attribute table, and the data is checked, and anything unchecked keeps
  the names of the file.

## Layout

- `data-raw/update.R`: updates the files in `data-raw/` from the site
  (needs the network). It reads the attribute table into
  `data-raw/attributes.csv`, scrapes the catalog into
  `data-raw/datasets.csv` and `data-raw/catalog.csv`, and runs
  `data-raw/build.R`.
- `data-raw/build.R`: offline. Writes a pipeline for each supported
  dataset, and `data/ksj_attributes.rda` and `data/ksj_available.rda`
  from `ksj_attributes_impl()` and `ksj_available_impl()`. It is run
  alone after changing the pipelines or an `_impl()` function, without
  scraping the site again.
- `data-raw/attributes.csv`, `data-raw/datasets.csv`, and
  `data-raw/catalog.csv`: the attribute table and the catalog as read
  from the site (see [Catalog](#catalog) and [Names](#names)).
- `data-raw/catalog.R`: functions that scrape the KSJ index and download
  pages.
- `data-raw/attributes.R`: functions that read the attribute table into
  `ksj_attributes` (see [Names](#names)). They do not use the catalog.
- `data-raw/report.R`: reports shared by the scripts, including the rows
  of each data object added, removed, or changed since the saved one.
- `inst/tarchives/<code>/_targets.R`: one tarchives pipeline per
  supported dataset, for example `l01` (地価公示), `n03` (行政区域), or
  `s05-d`. `<code>` is the KSJ code of the dataset page in lower case.
  Every `_targets.R` has the same few lines and differs only in the
  code.
- `inst/tarchives/R/`: helpers shared by the pipelines (building the
  targets of a dataset from `ksj_available`, downloading, unzipping,
  reading).
- `R/`:
  [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md),
  the target factories
  [`ksj_target()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_target.md)
  and
  [`ksj_target_raw()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_target.md),
  the documentation of the data objects `ksj_available` and
  `ksj_attributes`, and `ksj_available_impl()` and
  `ksj_attributes_impl()` (unexported). `R/import-standalone-*.R` are
  rlang’s standalone files
  (`usethis::use_standalone("r-lib/rlang", ...)`): the `map()` family
  (`purrr`), used for iteration without importing purrr, and the
  `check_*()` functions (`types-check`), used to validate the arguments
  of exported functions. The names of the targets
  ([`ksj_target_name()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_target_name.md),
  exported for the pipelines), the regular expressions of the layer
  patterns (`ksj_layer_regex()`), and the comparison of dataset codes
  (`ksj_dataset_key()`) are also defined here, once, and used by the
  pipelines and `data-raw/`.
- `tests/testthat/fixtures/`: small synthetic archives that mimic the
  published layouts. The pipeline helpers are tested on these, not on
  the published files.

The scripts in `data-raw/` are run by the maintainer, never by users or
tests. `data-raw/` is not part of the built package, as is usual for raw
data and the scripts that process it.

## Catalog

`ksj_available` is a data object, a tibble with one row per supported
file. It is computed by `ksj_available_impl()`, which reads the scraped
catalog, keeps the files of the datasets that have a pipeline
(`tarchives::tar_archive_pipelines("ksjdata")`), and adds the columns of
their dataset.

The scraped catalog is two CSV files in `data-raw/`:

| File | One row per | Content |
|----|----|----|
| `datasets.csv` | dataset page | `dataset_code`, `dataset_name`, `category_name`, and the terms and URLs of the page |
| `catalog.csv` | downloadable file, supported or not | `dataset_code`, the labels of the download table, the values parsed from them (`year`, `prefecture_code`, `file_size` in MB), `file_name`, and `url` |

- The catalog is needed because `ksj_available` must be rebuilt and
  tested offline and deterministically: the tests cannot scrape the
  site. Kept as text, every change of the site is reviewed as a diff of
  these files.
- The columns of a dataset page are kept apart from its files, as they
  would otherwise be repeated on every file (in one table, the catalog
  would be about 20 MB instead of 4.4 MB).
- The labels are parsed in `data-raw/catalog.R`, not in
  `ksj_available_impl()`: parsing needs Japanese text (prefectures,
  eras, column headers), which code in `R/` can only hold as escapes.
  The CSV keeps the labels as published next to the parsed values.
- The catalog lists the files of every dataset, so a dataset is added by
  writing its pipeline and running `data-raw/build.R`, without scraping
  again.
- It is shipped as data, not computed on each use, because the catalog
  is not shipped and every pipeline’s `_targets.R` reads it.
- `ksj_available_impl()` is named with `_impl` because a function and a
  data object cannot share a name. Only the maintainer calls it, so
  `readr` is in `Suggests`.
- A test checks that `ksj_available` equals `ksj_available_impl()`, so a
  forgotten rebuild after a change of the catalog, the pipelines, or
  `ksj_available_impl()` is caught. It runs where `data-raw/` is
  available (`devtools::test()`) and is skipped by `R CMD check`, which
  tests the built package.

Columns:

| Column | Content |
|----|----|
| `dataset_code` | KSJ code of the dataset page, for example `N03` |
| `dataset_name` | Name of the dataset, as published in the title of its page (行政区域データ) |
| `category_name` | Category on the index page (国土（水・土地）, 政策区域, …) |
| `year` | Western year of the release (integer) |
| `year_name` | Release, as labeled in the download table (`2025年（令和7年）`) |
| `area_name` | Area, as labeled in the download table (全国, 北海道, a mesh code, …) |
| `prefecture_code` | Two-digit prefecture code when the area is a prefecture, otherwise `NA` |
| `datum_name` | Geodetic datum, as labeled in the download table (世界測地系, 日本測地系) |
| `file_name` | Name of the archive in its URL, for example `N03-20250101_13_GML.zip` |
| `file_size` | Size as published ([`fs::fs_bytes`](https://fs.r-lib.org/reference/fs_bytes.html); sizes in MB and KB are read as 10^6 and 10^3 bytes), or `NA` if it cannot be parsed |
| `url` | Absolute URL of the archive |
| `license_name` | Terms, as labeled on the index page (CC_BY_4.0, 商用可, 非商用, …) |
| `license_note` | Notes on the terms from the dataset page, for example that secondary use may need an application to the Geospatial Information Authority of Japan |
| `license_url` | Page of the terms |
| `page_url` | Download page of the dataset |
| `specification_url` | Product specification (製品仕様書) linked from the dataset page |

- Labels are kept as published. They are parsed only where a column
  needs a code or a number (`prefecture_code` from the area, `year` from
  the label, including Japanese era years).
- URLs are taken from the download links on each page, never built from
  patterns: file names are not predictable across releases (N03 has
  `N03-05_GML.zip`, `N03-110331_GML.zip`, and `N03-20250101_GML.zip`).
- Only the page linked from the index is scraped for each dataset; the
  pages of older versions list the same files.
- `file_name` is taken from the URL, as the label in the table can
  differ from it (A51 labels `A51-24_40_GML.zip` as
  `A51-25_40_GML.zip`). A URL listed more than once on a page (L02, A51)
  is kept once, with the row whose prefecture code is in the file name
  (L02 lists `L02-24_02_GML.zip` under both 東北地方 and 青森), or else
  the first row, and `data-raw/catalog.R` reports it.
- Commented-out markup of the pages is removed before reading them, as
  its text would otherwise be read.
- The terms are those shown for the dataset, so every file of a dataset
  has the same `license_name`. Where a page gives terms per release or
  per prefecture (A09, A10, P11), they are in `license_note`.

Column naming of the catalog and the attribute table (the data are named
as described in [Names](#names)):

- Columns are in snake_case. `_code` is a code from an official
  classification, `_id` is an arbitrary record identifier, and `_name`
  is a label.
- Words are spelled out. The one exception is counts, which are named
  `n_<things>`.
- Quantities carry their unit in their class
  ([`fs::fs_bytes`](https://fs.r-lib.org/reference/fs_bytes.html) for
  sizes), so names carry no unit suffix.

### Supported datasets

A dataset is supported when it has a pipeline, so `ksj_available` can
never list a file that the package cannot get. For now, datasets are
added as they are needed, not all at once.

- A pipeline is generated for each dataset of the catalog that the
  attribute table describes (their codes compared with
  `ksj_dataset_key()`). Datasets missing from the attribute table (for
  example L05, whose layers are listed as `L05-01` and `L05-02`) or
  without download links (A55) are postponed, and `data-raw/build.R`
  reports them.
- A pipeline has a target for every file of its dataset in
  `ksj_available`, so the catalog and the targets cannot disagree.
- Older releases of a supported dataset are included. The attribute
  table describes only the latest release, so older ones are got with
  `col_names = "raw"` (see [Coverage](#coverage)).

### Updating the catalog

The catalog is updated by running `data-raw/update.R`, weekly by the
workflow `update-catalog.yaml`, which opens a pull request when the
files changed and runs R CMD check on it. Users take in the update by
installing the package again. The data objects stay `.rda` files, the
standard of R packages: the diffs are reviewed in the CSV files of
`data-raw/`, and the `.rda` files are small (about 150 kB in all). An
update is not needed for every version: only to take in changes of the
site (new releases, moved files) or of the supported datasets. The diffs
of the CSV files and the report of the scripts show what MLIT added,
removed, or replaced. A file whose row changed (URL or size) is rebuilt
the next time it is requested; other files keep their cached data.

## Names

An archive (a row of `ksj_available`) holds one or more layers: data
files (shapefiles or GeoJSON), each read as one table. A layer holds
features (地物), one per row, and its columns are usually attribute
codes such as `N03_001`.
[`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
names the columns in Japanese by default (`col_names = "ja"`), or keeps
the names of the file (`col_names = "raw"`).

The argument is named after readr’s `col_names`, the name R users know
for column names, but it chooses a naming rather than taking the names
themselves; its documentation says so. It is not `language`, because
`"raw"` is not a language, and not `names`, which would not say which
names.

- **Japanese** names come from the attribute table,
  `https://nlftp.mlit.go.jp/ksj/gml/codelist/shape_property_table2.xlsx`
  (sheet `全データ`). For each dataset (`識別子`) and shapefile name
  pattern (`シェープファイル名`), it gives the Japanese name of each
  code: `N03_001` is `都道府県名`. The names are used as published, with
  nothing translated or matched, so they are simple to check and match
  the official documentation. Users need backticks for them in R code.
- **Names of the file** are the column names as read, without any check.
  They are usually the codes, but not always (the GeoJSON of L03-b names
  its properties in Japanese, and some layers of A55 have columns such
  as `名称`), so the option is `"raw"` rather than `"code"`: it promises
  only that nothing is renamed.

`ksj_attributes` is computed by `ksj_attributes_impl()` from
`data-raw/attributes.csv`, which `data-raw/attributes.R` reads from the
attribute table, for the same reasons as `ksj_available`: it is rebuilt
and tested offline, and every change of the attribute table is reviewed
as a diff. It has one row per attribute:

| Column | Content |
|----|----|
| `dataset_code` | KSJ code of the dataset, as written in the attribute table (`識別子`). Some are written without `-` or `_` (`G04a` for `G04-a`), so codes are compared with `ksj_dataset_key()`, which removes them |
| `version_name` | `バージョン情報` of the attribute table |
| `year` | Year of the version (`2026` for `2026年版` and `2018` for `2018年度版`), or `NA` if it has none (`第1.1版`, `2006年～2009年度版`) |
| `layer_pattern` | Shapefile name pattern of the layer |
| `feature_name` | Name of the layer, as published in the attribute table (`データ名`, for example `行政区域（ポリゴン）`) |
| `attribute_code` | Code in the data (`N03_001`) |
| `attribute_name` | Japanese name, as published in the attribute table (`都道府県名`) |
| `note` | `備考` of the attribute table |

### Coverage

The attribute table describes only the latest release of each dataset,
so older releases of a supported dataset are available with the names of
the file only. Naming them is postponed; any other source (older product
specifications, or the code lists of older releases) must pass the same
checks before it is used.

### English names (planned)

English names would come from the product specification of each dataset
(`specification_url`). Its encoding schema gives the English tag of each
feature and attribute with its Japanese name: `AdministrativeBoundary`
is `行政区域`, and `prefectureName` is `都道府県名`. The schema would be
read from the text of the PDF, and the tags linked to codes through the
Japanese names of the attribute table. Tags would be converted to
snake_case by rule (`prefectureName` becomes `prefecture_name`).

- The Japanese names of the two sources would be compared after Unicode
  normalization (NFKC) and removing spaces. They do not always agree:
  for N03, the attribute table has `群名` and `政令指定都市の行政区域名`
  where the specification has `郡名` and `政令指定都市の行政区名`. A
  pair that does not match exactly would be kept only if the maintainer
  lists it in `data-raw/matches.csv` after comparing the two documents.
- A layer would get English names only if every attribute is matched to
  one feature of the specification and the names are unique within it.
- `ksj_attributes` would gain `feature_name_en` and `attribute_name_en`,
  and `col_names` would gain `"en"`, without breaking existing code.

## Getting data

`ksj_get(file_name, layer = NULL, col_names = c("ja", "raw"))` takes the
name of one file, a value of `file_name` in `ksj_available` (for example
`"N03-20260101_13_GML.zip"`), and returns one layer of it.

- One call returns one layer of one file, so a result never mixes
  layouts: releases, areas, and formats of a dataset can differ in
  columns, types, and coordinate reference systems, and binding them
  silently would fill columns with `NA` or fail on types. Several files
  are got by iterating over their names
  (`purrr::map(files$file_name, ksj_get)`), and bound by the user when
  their layouts agree.
- `file_name` is the key: file names are unique across `ksj_available`,
  so the dataset is not needed. A name that is not in it is an error.
- A file is never mixed up with another. `ksj_available_impl()` stops
  the build unless every file name is unique, gives a unique target
  name, and is the name of the archive at its URL. The value of a target
  keeps the URL it was downloaded from, and
  [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
  errors unless it is the URL of the file in `ksj_available` (for
  example, a stale cache after reinstalling the same version in a
  session).
- Only the target of the requested file is built, so only that file is
  downloaded. It is got with
  [`tarchives::tar_get_archive_raw()`](https://uchidamizuki.github.io/tarchives/reference/tar_get_archive.html),
  which checks a target at most once per session.
- If the file holds more than one layer, `layer` names the one to
  return: its name in the archive (the file name without the extension),
  or the `layer_pattern` or `feature_name` in `ksj_attributes` of a
  layer that describes it (see [Matching layers](#matching-layers)). The
  argument is `layer`, not `feature`, because it selects a data file of
  the archive, while a feature is one row. The pattern and the feature
  name apply to every file of a dataset, but `feature_name` alone does
  not always identify a layer (the ten layers of P03 are all
  発電施設（ポイント）). A name that matches no layer or several layers
  of a file is an error that lists them.
- `col_names = "ja"` (the default) renames the columns to
  `attribute_name`. This is allowed only when the columns read are
  exactly the codes of a layer of `ksj_attributes` for the release of
  the file (its `year`), and that layer has a name for every code.
  Otherwise it is an error that names the failed check and suggests
  `col_names = "raw"`.
- `col_names = "raw"` keeps the names of the file, for any release.
- Names of the file and Japanese names are never mixed in one result.
- The first time in a session that a dataset is requested, its terms
  (`license_name`, `license_note`, `license_url`) are shown with
  [`cli::cli_inform()`](https://cli.r-lib.org/reference/cli_abort.html),
  once per session by rlang’s `.frequency = "once"` (with an id per
  dataset), so the package keeps no state of its own. Terms that forbid
  commercial use (非商用) are stated explicitly.

### Output

[`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
returns the layer as one `sf` tibble: its attributes, named as above,
and its geometry. No columns are added; the file is known to the caller,
who adds columns of `ksj_available` when needed.

`ksj_target(name, file_name, layer, col_names)` and
[`ksj_target_raw()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_target.md)
declare a target whose command is that call of
[`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md),
so a pipeline gets the same data. A target per file is declared with
[`tarchetypes::tar_eval()`](https://docs.ropensci.org/tarchetypes/reference/tar_eval.html),
which substitutes the values before the targets are created (`tar_map()`
substitutes only into commands of targets already created, so it cannot
pass a file name to
[`ksj_target()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_target.md)).
The URL and the size of the file in `ksj_available` and the installed
version of ksjdata are part of the target’s string, so the target is
rerun when an update of the catalog replaces the file or when a new
version is installed.

Values:

- Geometries are as published: not simplified, not dissolved, not made
  valid.
- The coordinate reference system is the one read from the file. It is
  not transformed, because converting between datums accurately needs
  regional corrections, not just a change of EPSG code.
- Codes are kept as published, including leading zeros.
- Rows are kept as published, including those without a name or code
  (for example 所属未定地 in N03).

## Pipelines

Each pipeline has one target per file of its dataset, declared with
[`tarchetypes::tar_eval()`](https://docs.ropensci.org/tarchetypes/reference/tar_eval.html)
over the dataset’s rows of `ksj_available`, the same way users declare a
target per file with
[`ksj_target()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_target.md).

- A target downloads its archive to a temporary directory, reads it, and
  returns a named list of layers with the names of the file as column
  names. Names are applied in
  [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md),
  so that a change of names does not rebuild any target.
- The archive is not kept, so the store holds only the parsed data.
- Target names are derived from `file_name` by
  [`ksj_target_name()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_target_name.md)
  (`N03-20250101_13_GML.zip` becomes `ksj_n03_20250101_13_gml`), so they
  stay the same when other rows of the catalog change. The prefix `ksj_`
  keeps names valid when a file name starts with a digit
  (`1km_mesh_2024_GML.zip`).
  [`ksj_target_name()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_target_name.md)
  is exported (with `@keywords internal`, so it is not in the reference
  index) because the pipelines call it; they use only exported functions
  of ksjdata, never `:::`.
- The row of `ksj_available` is part of the target’s command, so a
  change of URL or size rebuilds that target only.

## Reading files

- Archives are unzipped with
  [`zip::unzip()`](https://r-lib.github.io/zip/reference/unzip.html).
  [`utils::unzip()`](https://rdrr.io/r/utils/unzip.html) fails on member
  names in Shift_JIS (A31-12_47_GML.zip), which `zip` extracts.
- Only the members of the layers to read are extracted (the `.shp`,
  `.shx`, `.dbf`, `.prj`, and `.cpg` files of the shapefiles, or else
  the GeoJSON files), so that large archives with GML and other formats
  (A33 is 1.5 GB) do not fill the disk.
- Read the shapefiles when the archive has them, otherwise the GeoJSON.
  GML is not read. Shapefiles come first because the attribute table
  describes them (its columns are the codes of the shapefiles) and their
  `.prj` gives the datum. The GeoJSON of the same archive can differ:
  L03-b names its properties in Japanese (`細分メッシュコード`), and
  S05-d has no `crs` member, so it is read as WGS 84 (RFC 7946) while
  its shapefile is in JGD2011.
- Shapefiles are read with the encoding of their `.cpg` file. Without
  one, they are read as CP932, as KSJ shapefiles without a `.cpg` file
  are in Shift_JIS.
- A layer is named after its file without the extension and the
  directories. Member names may use backslashes as separators (A31b), so
  they are removed too. Two layers with the same name are an error.
- An archive with neither GeoJSON nor shapefiles is an error with its
  own class.

## Checks

`ksj_available` and the names are what users rely on, so every link
between the sources is checked.

### Matching the sources

`data-raw/attributes.R` reads the attribute table on its own, and
`data-raw/build.R` reports what does not match the catalog:

- Cells: the dataset, version, and pattern are given on the first row of
  their group only, and are filled down. A cell that holds only a note
  in brackets (A45 `（小班区画）`) continues the layer above it. A cell
  can list several layers, one per line (A10); each becomes a layer with
  the same attributes.
- Dataset: the identifiers of the attribute table and the codes of the
  pages are written differently (`G04a` and `G04-a`, `A18s_a` and
  `A18s-a`). The identifiers are kept as published and compared with
  `ksj_dataset_key()`, which removes `-` and `_`.
- Release: `year` is read from the version (`2026年版`, `2018年度版`).
  It is not checked against the catalog, because
  [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
  uses names only for the files whose `year` is the same. A version
  whose year has no files (`2012年度版` of A19s, whose files end
  in 2010) or that has no year (`第1.1版`) is therefore never used.
- Layer: text after the file name in the same cell (such as
  `（特別用途地区）`) is not part of the pattern. Patterns are kept as
  published, including apparent typos (`A43-YY_ Preservation...`,
  `_pp`). Layers of the data are matched to them in
  [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
  (see [Matching layers](#matching-layers)).
- Japanese names: a layer gets `attribute_name` only if the names are
  unique within it. The current attribute table repeats a name within
  three layers (A22-m `集計単位フラグ（雪害）`, A55 特別用途地区
  `種類コード`, P22b `TreeCode`); those layers are available with the
  names of the file.
- Japanese names are kept as published, including apparent typos such as
  `群名`.

### Matching layers

A layer of `ksj_attributes` (one per dataset, version, and pattern)
describes a layer of a file if its pattern matches the file name of the
layer without the extension, or if its codes are exactly the columns of
the layer. The placeholders of the pattern (`YY`, `YYYY`, `MM`, `DD`,
`PP`, `CCCCC`, `AA`, `mmmm`) are replaced by digit patterns.

- Names are given by the columns, not by the file name: the columns must
  be exactly the codes of a layer for the release of the file. The file
  name cannot be relied on alone: the nationwide file of N03 holds
  `N03-20260101`, which `N03-YYYYMMDD_PP` does not match, and some
  patterns have typos (A43).
- If the columns match several layers, the one whose pattern matches the
  file name is used. Layers that share their codes and names (the three
  layers of A10) are interchangeable. Otherwise the names are not used.
- Both kinds of match give the values that `layer` accepts.

### Tests (offline)

- `ksj_available` equals `ksj_available_impl()` (where `data-raw/` is
  available). It is a plain tibble.
- The pipelines and the datasets of `ksj_available` are the same, so a
  pipeline added or removed without running `data-raw/build.R` is
  caught, even by `R CMD check`. Every dataset of `ksj_available` is
  described by `ksj_attributes`. Every row of `ksj_available` has
  exactly one target in the pipeline of its dataset. `file_name` is
  unique within each dataset, and so are the target names derived from
  it.
- Every `year_name` parses to a `year`.
- `ksj_attributes` equals `ksj_attributes_impl()` (where `data-raw/` is
  available). Within each of its layers, `attribute_name` is unique or
  all `NA`.

### When data are named

- The columns read must be exactly the codes listed for the layer, as
  described in [Getting data](#getting-data).

## Terms of use

- The default terms of KSJ are the Public Data License 1.0
  (公共データ利用規約). Other datasets are CC BY 4.0, or follow older
  terms that allow (商用可) or forbid (非商用) commercial use.
- The package downloads data on the user’s machine and does not ship it,
  so it does not redistribute data. Complying with the terms of each
  file is up to the user, so they are shown in `ksj_available` and when
  the data are first requested.
- The documentation of
  [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
  states that published or processed data must credit the source and say
  that they were processed, as the terms require.

## Documentation

- `README.md` is in English and `README.ja.md` in Japanese; each links
  to the other. Both are rendered from Quarto files (`README.qmd` and
  `README.ja.qmd`, `format: gfm`) with `quarto render`.
- Both list the supported datasets, generated from `ksj_available` when
  rendered (code, name, releases, terms), so the list never goes out of
  date.

## Storage

targets’ default storage (rds) is used, one target per file. If targets
become too slow to read (for example nationwide mesh datasets), compare
GeoParquet through the GDAL Parquet driver (`sf`), `geoarrow`, and
duckdb spatial before switching.

## Dependencies

- `Imports`: packages that `R/` uses for users (`tarchives`, `targets`,
  `rlang`, `cli`, `sf`, `tibble`, `vctrs`, `stringr`, `fs`). `tibble`,
  `sf`, and `fs` are imported so that their print methods are available.
  Errors and messages use `cli` (`cli_abort()`, `cli_inform()`); text
  from the data is escaped before it is passed to cli.
- Code is formatted with Air (`air.toml`, set up with
  `usethis::use_air()`).
- GitHub Actions run R CMD check on the r-lib matrix
  (`R-CMD-check.yaml`), check the formatting with Air
  (`format-check.yaml`), build the pkgdown site to the `gh-pages` branch
  (`pkgdown.yaml`), and update the catalog weekly
  (`update-catalog.yaml`). Pull requests opened with `GITHUB_TOKEN` do
  not trigger workflows, so `update-catalog.yaml` dispatches
  `R-CMD-check.yaml` on its branch. The workflows come from
  `usethis::use_github_action()` and the examples of
  `posit-dev/setup-air`.
- `Suggests`: packages used only inside the pipelines (`curl`, `purrr`,
  `tarchetypes`, `zip`), by `ksj_available_impl()` (`readr`), in
  examples (`dplyr`), and in tests (`testthat`, `withr`). The scripts in
  `data-raw/` also use `rvest`, `readxl`, `tidyr`, `devtools`, and
  `usethis`.
- Code uses tidyverse and r-lib packages rather than their base
  equivalents: `stringr` for strings and regular expressions (`str_c()`
  rather than [`paste0()`](https://rdrr.io/r/base/paste.html)), `fs` for
  paths, `purrr` for iteration (the standalone `map()` family of rlang
  in `R/`, where `purrr` is not imported, and
  [`purrr::map()`](https://purrr.tidyverse.org/reference/map.html) with
  the namespace in `data-raw/`, because `devtools::load_all()` in
  `data-raw/build.R` attaches the standalone functions over purrr; not
  [`lapply()`](https://rdrr.io/r/base/lapply.html),
  [`vapply()`](https://rdrr.io/r/base/lapply.html), or
  [`Filter()`](https://rdrr.io/r/base/funprog.html)), `tibble` for data
  frames (not [`data.frame()`](https://rdrr.io/r/base/data.frame.html)
  or [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)),
  [`vctrs::vec_split()`](https://vctrs.r-lib.org/reference/vec_split.html)
  and
  [`vctrs::vec_chop()`](https://vctrs.r-lib.org/reference/vec_chop.html)
  for splitting (not [`split()`](https://rdrr.io/r/base/split.html)),
  [`vctrs::vec_rbind()`](https://vctrs.r-lib.org/reference/vec_bind.html)
  for binding rows,
  [`vctrs::vec_match()`](https://vctrs.r-lib.org/reference/vec_match.html)
  and
  [`vctrs::vec_in()`](https://vctrs.r-lib.org/reference/vec_match.html)
  for matching (not [`match()`](https://rdrr.io/r/base/match.html)),
  `dplyr` for joins, and `tidyr::replace_na()` for filling missing
  values with one value. Columns are dropped with `select(!x)`.

## Roadmap (temporary)

Move this to GitHub issues once the repository is published.

1.  Done: `data-raw/catalog.R` and the scraped catalog.
2.  Done: `data-raw/attributes.R` and `ksj_attributes`, with Japanese
    names.
3.  Done: the pipeline helpers, `data-raw/build.R` (pipelines and the
    data objects from the `_impl()` functions), and
    [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
    with `col_names = "ja"` and `"raw"`, with the offline tests.
4.  Done:
    - N03 (per prefecture), S05-d (shapefile only before 2016, two
      layers), L03-b (mesh), and A43 (a pattern with a typo) are named
      in Japanese for their latest release; older releases need
      `col_names = "raw"`.
    - N03 for Hokkaido has a second layer,
      `N03-20260101_01_subprefectures`, so getting all prefectures needs
      `layer = "行政区域（ポリゴン）"`.
    - Getting a file the first time takes about 10 seconds (download and
      one `tar_make()`), and 0.1 second from the cache. All 47
      prefectures of N03 take a few minutes the first time. To speed it
      up, build the requested targets of a pipeline in one
      [`tarchives::tar_make_archive()`](https://uchidamizuki.github.io/tarchives/reference/tar_make_archive.html)
      call; checking them once per session would then need a version of
      `tar_get_archive_raw()` for several targets in tarchives.
    - Datasets distributed as one archive per format (A31a, A31b, A33,
      A54: `_GML`, `_SHP`, `_GEOJSON`) have no format column in
      `ksj_available`, and archives of GML only cannot be read. Consider
      adding `format_name` from the 形式 column of the download table.
5.  Done: the English and Japanese READMEs.
6.  English names (see [English names
    (planned)](#english-names-planned)).

Postponed: datasets missing from the attribute table, names for older
releases, an option of
[`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
and
[`ksj_target()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_target.md)
not to cache the files (so that only the final results are stored), and
detecting files that MLIT replaces under the same URL and size (for
example with `Last-Modified`).
