# Target of National Land Numerical Information

`ksj_target()` and `ksj_target_raw()` declare a target of a 'targets'
pipeline whose value is `ksj_get(file_name, layer, col_names)`. The
target is rerun when the arguments or the installed version of ksjdata
change. To declare a target per file, use
[`tarchetypes::tar_eval()`](https://docs.ropensci.org/tarchetypes/reference/tar_eval.html).

## Usage

``` r
ksj_target(name, file_name, layer = NULL, col_names = c("ja", "raw"), ...)

ksj_target_raw(name, file_name, layer = NULL, col_names = c("ja", "raw"), ...)
```

## Arguments

- name:

  Name of the target: a symbol for `ksj_target()`, a string for
  `ksj_target_raw()`.

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

- ...:

  Other arguments passed to
  [`targets::tar_target_raw()`](https://docs.ropensci.org/targets/reference/tar_target.html).

## Value

A target object.

## Examples

``` r
ksj_target(municipalities, "N03-20260101_13_GML.zip")
#> <tar_stem> 
#>   name: municipalities 
#>   description:  
#>   command:
#>     ksjdata::ksj_get(file_name = "N03-20260101_13_GML.zip", layer = NULL, 
#>         col_names = "ja")0.0.0.9000 
#>   format: rds 
#>   repository: local 
#>   iteration method: vector 
#>   error mode: stop 
#>   memory mode: auto 
#>   storage mode: worker 
#>   retrieval mode: auto 
#>   deployment mode: worker 
#>   priority: 0 
#>   resources:
#>     list() 
#>   cue:
#>     seed: TRUE
#>     file: TRUE
#>     iteration: TRUE
#>     repository: TRUE
#>     format: TRUE
#>     depend: TRUE
#>     command: TRUE
#>     mode: thorough 
#>   packages:
#>     ksjdata
#>     stats
#>     graphics
#>     grDevices
#>     utils
#>     datasets
#>     methods
#>     base 
#>   library:
#>     NULL

# A target per file
files <- ksj_available[
  ksj_available$dataset_code == "N03" &
    ksj_available$year == 2026 &
    ksj_available$prefecture_code %in% c("13", "14"),
]
tarchetypes::tar_eval(
  ksj_target(name, file_name),
  values = list(
    name = rlang::syms(stringr::str_c("n03_", files$prefecture_code)),
    file_name = files$file_name
  )
)
#> [[1]]
#> <tar_stem> 
#>   name: n03_13 
#>   description:  
#>   command:
#>     ksjdata::ksj_get(file_name = "N03-20260101_13_GML.zip", layer = NULL, 
#>         col_names = "ja")0.0.0.9000 
#>   format: rds 
#>   repository: local 
#>   iteration method: vector 
#>   error mode: stop 
#>   memory mode: auto 
#>   storage mode: worker 
#>   retrieval mode: auto 
#>   deployment mode: worker 
#>   priority: 0 
#>   resources:
#>     list() 
#>   cue:
#>     seed: TRUE
#>     file: TRUE
#>     iteration: TRUE
#>     repository: TRUE
#>     format: TRUE
#>     depend: TRUE
#>     command: TRUE
#>     mode: thorough 
#>   packages:
#>     ksjdata
#>     stats
#>     graphics
#>     grDevices
#>     utils
#>     datasets
#>     methods
#>     base 
#>   library:
#>     NULL
#> [[2]]
#> <tar_stem> 
#>   name: n03_14 
#>   description:  
#>   command:
#>     ksjdata::ksj_get(file_name = "N03-20260101_14_GML.zip", layer = NULL, 
#>         col_names = "ja")0.0.0.9000 
#>   format: rds 
#>   repository: local 
#>   iteration method: vector 
#>   error mode: stop 
#>   memory mode: auto 
#>   storage mode: worker 
#>   retrieval mode: auto 
#>   deployment mode: worker 
#>   priority: 0 
#>   resources:
#>     list() 
#>   cue:
#>     seed: TRUE
#>     file: TRUE
#>     iteration: TRUE
#>     repository: TRUE
#>     format: TRUE
#>     depend: TRUE
#>     command: TRUE
#>     mode: thorough 
#>   packages:
#>     ksjdata
#>     stats
#>     graphics
#>     grDevices
#>     utils
#>     datasets
#>     methods
#>     base 
#>   library:
#>     NULL
```
