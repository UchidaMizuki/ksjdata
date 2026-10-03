# Files available from National Land Numerical Information

`ksj_available` is the catalog of the package: it lists every file of
National Land Numerical Information (Kokudo Suuchi Joho, KSJ) that the
package can get, with its dataset, release, area, and terms of use.
Filter its rows and pass them to
[`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md).
A file that is not listed here is not supported.

## Usage

``` r
ksj_available
```

## Format

A tibble with one row per file and the columns:

- dataset_code:

  KSJ code of the dataset page, for example `N03`.

- dataset_name:

  Name of the dataset, as published.

- category_name:

  Category on the index page.

- year:

  Western year of the release.

- year_name:

  Release, as labeled in the download table.

- area_name:

  Area, as labeled in the download table.

- prefecture_code:

  Two-digit prefecture code when the area is a prefecture, otherwise
  `NA`.

- datum_name:

  Geodetic datum, as labeled in the download table.

- file_name:

  Name of the archive.

- file_size:

  Size as published
  ([`fs::fs_bytes`](https://fs.r-lib.org/reference/fs_bytes.html)).
  Sizes are published in MB and KB, read as 10^6 and 10^3 bytes.

- url:

  URL of the archive.

- license_name:

  Terms of use, as labeled on the index page.

- license_note:

  Notes on the terms from the dataset page.

- license_url:

  Page of the terms.

- page_url:

  Download page of the dataset.

- specification_url:

  Product specification of the dataset.

## Source

<https://nlftp.mlit.go.jp/ksj/>

## Details

Labels are kept as published on the KSJ download site. The catalog is
updated with new versions of the package, not at run time.

## Examples

``` r
ksj_available
#> # A tibble: 27,186 × 16
#>    dataset_code dataset_name category_name     year year_name          area_name
#>    <chr>        <chr>        <chr>            <int> <chr>              <chr>    
#>  1 C23          海岸線データ 国土（水・土地）  2006 2006年（平成18年） 北海道   
#>  2 C23          海岸線データ 国土（水・土地）  2006 2006年（平成18年） 青森     
#>  3 C23          海岸線データ 国土（水・土地）  2006 2006年（平成18年） 岩手     
#>  4 C23          海岸線データ 国土（水・土地）  2006 2006年（平成18年） 宮城     
#>  5 C23          海岸線データ 国土（水・土地）  2006 2006年（平成18年） 秋田     
#>  6 C23          海岸線データ 国土（水・土地）  2006 2006年（平成18年） 山形     
#>  7 C23          海岸線データ 国土（水・土地）  2006 2006年（平成18年） 福島     
#>  8 C23          海岸線データ 国土（水・土地）  2006 2006年（平成18年） 茨城     
#>  9 C23          海岸線データ 国土（水・土地）  2006 2006年（平成18年） 千葉     
#> 10 C23          海岸線データ 国土（水・土地）  2006 2006年（平成18年） 東京     
#> # ℹ 27,176 more rows
#> # ℹ 10 more variables: prefecture_code <chr>, datum_name <chr>,
#> #   file_name <chr>, file_size <fs::bytes>, url <chr>, license_name <chr>,
#> #   license_note <chr>, license_url <chr>, page_url <chr>,
#> #   specification_url <chr>
```
