# Name of the target of a file

`ksj_target_name()` gives the name of the target of a file in the
bundled pipeline of its dataset: `N03-20250101_13_GML.zip` becomes
`ksj_n03_20250101_13_gml`. It is used by the pipelines and by
[`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md).

## Usage

``` r
ksj_target_name(file_name)
```

## Arguments

- file_name:

  Names of files: values of `file_name` in
  [ksj_available](https://uchidamizuki.github.io/ksjdata/reference/ksj_available.md).

## Value

A character vector of target names.

## Examples

``` r
ksj_target_name("N03-20250101_13_GML.zip")
#> [1] "ksj_n03_20250101_13_gml"
```
