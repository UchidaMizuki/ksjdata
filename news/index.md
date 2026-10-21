# Changelog

## ksjdata 0.0.0.9000

- Initial version: `ksj_available` lists the supported files of National
  Land Numerical Information with their terms of use, `ksj_attributes`
  gives the Japanese names of the attribute table,
  [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
  downloads and reads one file as an `sf` tibble, and
  [`ksj_target()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_target.md)
  declares it as a target.
- [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
  reads the archives that hold the same files in a folder `Shift-JIS`
  and in a folder `UTF-8` (N02, N05, and N06 since 2021), which failed
  with duplicated layer names: it reads the copy in `UTF-8`, as UTF-8.
