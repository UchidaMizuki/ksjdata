# Attributes of National Land Numerical Information

`ksj_attributes` gives the name of each attribute code of the layers of
National Land Numerical Information, as published in the attribute table
(`shape_property_table2.xlsx`).
[`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
uses it to name the columns of the data.

## Usage

``` r
ksj_attributes
```

## Format

A tibble with one row per attribute and the columns:

- dataset_code:

  KSJ code of the dataset, as written in the attribute table. Some codes
  are written without `-` or `_` (`G04a` for `G04-a` in
  [ksj_available](https://uchidamizuki.github.io/ksjdata/reference/ksj_available.md)),
  so they are compared without them.

- version_name:

  Version, as published in the attribute table.

- year:

  Year of the version, or `NA` if the version is not a year (a version
  number such as 1.1).

- layer_pattern:

  Shapefile name pattern of the layer.

- feature_name:

  Name of the layer, as published in the attribute table.

- attribute_code:

  Code of the attribute in the data.

- attribute_name:

  Japanese name, as published in the attribute table, or `NA`.

- note:

  Note of the attribute table.

## Source

<https://nlftp.mlit.go.jp/ksj/gml/codelist/shape_property_table2.xlsx>

## Details

The attribute table describes only the latest release of each dataset,
so names are used only for the files of
[ksj_available](https://uchidamizuki.github.io/ksjdata/reference/ksj_available.md)
whose `year` is the year of the version. A layer whose codes or names
are not unique has no names (`NA`).

## Examples

``` r
ksj_attributes
#> # A tibble: 6,302 × 8
#>    dataset_code version_name  year layer_pattern    feature_name  attribute_code
#>    <chr>        <chr>        <int> <chr>            <chr>         <chr>         
#>  1 A03          2025年度版    2025 A03-YY_SYUTO.shp 三大都市圏計画区域（ポリ… A03_001       
#>  2 A03          2025年度版    2025 A03-YY_SYUTO.shp 三大都市圏計画区域（ポリ… A03_002       
#>  3 A03          2025年度版    2025 A03-YY_SYUTO.shp 三大都市圏計画区域（ポリ… A03_003       
#>  4 A03          2025年度版    2025 A03-YY_SYUTO.shp 三大都市圏計画区域（ポリ… A03_004       
#>  5 A03          2025年度版    2025 A03-YY_SYUTO.shp 三大都市圏計画区域（ポリ… A03_005       
#>  6 A03          2025年度版    2025 A03-YY_SYUTO.shp 三大都市圏計画区域（ポリ… A03_006       
#>  7 A03          2025年度版    2025 A03-YY_SYUTO.shp 三大都市圏計画区域（ポリ… A03_007       
#>  8 A03          2025年度版    2025 A03-YY_SYUTO.shp 三大都市圏計画区域（ポリ… A03_008       
#>  9 A09          2018年度版    2018 A09-YY_PP_GML    都市地域（ポリゴン）…… prefec_cd     
#> 10 A09          2018年度版    2018 A09-YY_PP_GML    都市地域（ポリゴン）…… area_cd       
#> # ℹ 6,292 more rows
#> # ℹ 2 more variables: attribute_name <chr>, note <chr>
```
