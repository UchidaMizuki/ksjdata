# ksjdata 0.0.0.9000

* Initial version: `ksj_available` lists the supported files of National Land Numerical Information with the pages of their datasets, `ksj_attributes` gives the Japanese names of the attribute table, `ksj_get()` downloads and reads one file as an `sf` tibble, and `ksj_target()` declares it as a target.
* `ksj_get()` reads the archives that hold the same files in a folder `Shift-JIS` and in a folder `UTF-8` (N02, N05, and N06 since 2021), which failed with duplicated layer names: it reads the copy in `UTF-8`, as UTF-8.
* `ksj_available` no longer has the columns `license_name`, `license_note`, and `license_url`. They gave the terms of the latest version for every file of a dataset, which were wrong for older releases that cannot be used commercially (非商用, for example P04 of 2010 and 2014). `ksj_get()` now points to the page of the dataset and the terms of the site instead.
