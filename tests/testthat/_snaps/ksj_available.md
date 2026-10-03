# ksj_check_files() errors on names that don't identify a file

    Code
      ksj_check_files(files)
    Condition
      Error in `ksj_check_files()`:
      ! Each file must have a unique name and target name, and be named after its URL.
      x Files that are not: 'A.zip', 'B-1.zip', 'B_1.zip', and 'C.zip'.

