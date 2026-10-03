# Get National Land Numerical Information

`ksj_get()` downloads and reads one file of
[ksj_available](https://uchidamizuki.github.io/ksjdata/reference/ksj_available.md),
and returns one of its layers as an `sf` tibble. Only that file is
downloaded. Each file is read once and cached by the bundled 'targets'
pipelines (see the tarchives package), so later calls read the cache. To
get several files, iterate over their names, for example with
[`purrr::map()`](https://purrr.tidyverse.org/reference/map.html).

## Usage

``` r
ksj_get(file_name, layer = NULL, col_names = c("ja", "raw"))
```

## Arguments

- file_name:

  Name of a file: a value of `file_name` in
  [ksj_available](https://uchidamizuki.github.io/ksjdata/reference/ksj_available.md).

- layer:

  If the file holds more than one layer (data file), the layer to
  return: its name in the archive (the file name without the extension),
  or its `layer_pattern` or `feature_name` in
  [ksj_attributes](https://uchidamizuki.github.io/ksjdata/reference/ksj_attributes.md).

- col_names:

  How to name the columns. Unlike in readr, it chooses a naming, not the
  names themselves:

  - `"ja"` (the default): Japanese names of the attribute table
    ([ksj_attributes](https://uchidamizuki.github.io/ksjdata/reference/ksj_attributes.md)).
    They are used only if the columns of the layer are exactly the codes
    that the attribute table lists for the release of the file, which it
    does only for the latest release of a dataset.

  - `"raw"`: the names of the file, usually attribute codes such as
    `N03_001`. Use it for older releases.

## Value

An `sf` tibble with the attributes and the geometry of the layer, as
published.

## Details

The first time in a session that a dataset is requested, its terms of
use are shown, and they are also in the `license_*` columns of
[ksj_available](https://uchidamizuki.github.io/ksjdata/reference/ksj_available.md).
Complying with them is up to you: published or processed data must
credit the source (National Land Numerical Information, with the name of
the dataset, by the Ministry of Land, Infrastructure, Transport and
Tourism), and processed data must say that they were processed.

## Examples

``` r
if (FALSE) { # \dontrun{
ksj_get("N03-20260101_13_GML.zip")

# Several files
files <- ksj_available |>
  dplyr::filter(
    dataset_code == "N03",
    year == 2026,
    prefecture_code %in% c("13", "14")
  )
purrr::map(files$file_name, ksj_get)
} # }
```
