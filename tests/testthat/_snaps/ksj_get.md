# ksj_get() doesn't name a layer that is not fully covered

    Code
      ksj_get(named$file$file_name)
    Condition
      Error in `ksj_get()`:
      ! Can't name the columns of layer "N03-20260101_13" of 'N03-20260101_13_GML.zip'.
      x Columns not in the attribute table: extra.
      i Use `col_names = "raw"` to keep the names of the file.

# ksj_get() selects a layer with `layer`

    Code
      ksj_get(named$file$file_name)
    Condition
      Error in `ksj_get()`:
      ! 'N03-20260101_13_GML.zip' holds more than one layer.
      i Choose one with `layer`:
      * N03-20260101_13, N03-YYYYMMDD_PP.shp, 行政区域（ポリゴン）
      * other

# ksj_get() errors on files that are not in ksj_available

    Code
      ksj_get("N03-unknown.zip")
    Condition
      Error in `ksj_get()`:
      ! Can't find 'N03-unknown.zip' in `ksj_available`.
      i Use a value of file_name in `ksj_available`.

# ksj_get() checks its arguments

    Code
      ksj_get(ksj_available[1, ])
    Condition
      Error in `ksj_get()`:
      ! `file_name` must be a single string, not a <tbl_df> object.

---

    Code
      ksj_get(file_name, col_names = "code")
    Condition
      Error in `ksj_get()`:
      ! `col_names` must be one of "ja" or "raw", not "code".

---

    Code
      ksj_get(file_name, layer = 1)
    Condition
      Error in `ksj_get()`:
      ! `layer` must be a single string or `NULL`, not the number 1.

# ksj_get() errors on cached data that are not from the file's URL

    Code
      ksj_get(file$file_name)
    Condition
      Error in `ksj_get()`:
      ! The cached data of 'N03-20260101_13_GML.zip' are not from its URL in `ksj_available`.
      i Restart R to rebuild them, for example after reinstalling ksjdata.

