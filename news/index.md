# Changelog

## ksjdata 0.0.0.9000

- Initial version: `ksj_available` lists the supported files of National
  Land Numerical Information with the pages of their datasets,
  `ksj_attributes` gives the Japanese names of the attribute table,
  [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
  downloads and reads one file as an `sf` tibble, and
  [`ksj_target()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_target.md)
  declares it as a target.
- [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
  reads the archives that hold the same files in a folder `Shift-JIS`
  and in a folder `UTF-8` (N02, N05, and N06 since 2021), which failed
  with duplicated layer names: it reads the copy in `UTF-8`, as UTF-8.
- `ksj_available` no longer has the columns `license_name`,
  `license_note`, and `license_url`. They gave the terms of the latest
  version for every file of a dataset, which were wrong for older
  releases that cannot be used commercially (非商用, for example P04 of
  2010 and 2014).
  [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
  now points to the page of the dataset and the terms of the site
  instead.
- [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
  reads the national files that are archives of the archives of the
  prefectures (P05 and P11 since 2022), which failed with an error that
  the archive has neither shapefiles nor GeoJSON.
- [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
  reads shapefiles whose `.cpg` file says Shift_JIS (`SJIS`) as CP932,
  so that characters of the extension by Microsoft, such as circled
  numbers, are no longer replaced (for example 池袋駅東口（⑩のりば） of
  P11 was read as 池袋駅東口（Iのりば）). Cached files are read again on
  their next call.
