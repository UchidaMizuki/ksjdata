# Functions that scrape the KSJ index and download pages into the catalog:
# every downloadable file of the site, supported or not. Used by
# `data-raw/update.R`, which writes it to `data-raw/datasets.csv` and
# `data-raw/catalog.csv`.

library(rvest)
library(dplyr)
library(stringr)

index_url <- "https://nlftp.mlit.go.jp/ksj/index.html"

# Prefectures as labeled in the download tables, in the order of their codes
# (JIS X 0401).
prefecture_names <- c(
  "北海道",
  "青森",
  "岩手",
  "宮城",
  "秋田",
  "山形",
  "福島",
  "茨城",
  "栃木",
  "群馬",
  "埼玉",
  "千葉",
  "東京",
  "神奈川",
  "新潟",
  "富山",
  "石川",
  "福井",
  "山梨",
  "長野",
  "岐阜",
  "静岡",
  "愛知",
  "三重",
  "滋賀",
  "京都",
  "大阪",
  "兵庫",
  "奈良",
  "和歌山",
  "鳥取",
  "島根",
  "岡山",
  "広島",
  "山口",
  "徳島",
  "香川",
  "愛媛",
  "高知",
  "福岡",
  "佐賀",
  "長崎",
  "熊本",
  "大分",
  "宮崎",
  "鹿児島",
  "沖縄"
)

era_offsets <- c(
  "明治" = 1867L,
  "大正" = 1911L,
  "昭和" = 1925L,
  "平成" = 1988L,
  "令和" = 2018L
)

# Index ------------------------------------------------------------------------

read_index <- function(url) {
  html <- read_html(url)
  html |>
    html_elements("ul.collapsible") |>
    purrr::map(\(category) read_category(category, url)) |>
    list_rbind() |>
    filter(str_detect(page_url, "/datalist/")) |>
    distinct(page_url, .keep_all = TRUE)
}

read_category <- function(category, url) {
  links <- category |>
    html_elements("li.collection-item") |>
    purrr::map(\(item) html_elements(item, "a"))
  page_links <- purrr::map(links, \(x) x[[1]])
  license_links <- purrr::map(links, \(x) x[[length(x)]])

  tibble(
    category_name = category |>
      html_element(".collapsible-header p") |>
      html_text2() |>
      str_remove("arrow_drop_down") |>
      str_remove("^\\s*\\d+\\.\\s*") |>
      str_squish(),
    page_url = page_links |>
      purrr::map_chr(\(x) html_attr(x, "href")) |>
      url_absolute(url),
    license_name = license_links |>
      purrr::map_chr(html_text2) |>
      str_squish(),
    license_url = license_links |>
      purrr::map_chr(\(x) html_attr(x, "href")) |>
      url_absolute(url)
  )
}

parse_dataset_code <- function(page_url) {
  page_url |>
    basename() |>
    str_remove("^KsjTmplt-") |>
    str_remove("\\.html$") |>
    str_remove("-\\d{4}$")
}

# Download pages ---------------------------------------------------------------

read_page <- function(url) {
  Sys.sleep(1)
  html <- read_html(url)
  # Commented-out markup is not shown on the page, but its text would be read.
  xml2::xml_remove(html_elements(html, xpath = "//comment()"))
  tibble(
    dataset_name = html |>
      html_element("title") |>
      html_text2() |>
      str_remove("^\\s*国土数値情報\\s*\\|") |>
      str_squish(),
    license_note = read_license_note(html),
    specification_url = read_specification_url(html, url),
    files = list(read_files(html, url))
  )
}

# The terms are in the cells that follow their header. They are siblings of the
# header even where the row is not marked up (A48).
read_license_note <- function(html) {
  note <- html |>
    html_element(xpath = "//th[contains(., '使用許諾条件')]") |>
    html_elements(xpath = "following-sibling::td") |>
    html_text2() |>
    str_flatten(" ") |>
    str_squish()
  if (nzchar(note)) note else NA_character_
}

read_specification_url <- function(html, url) {
  href <- html_attr(html_elements(html, "a[href*='product_spec']"), "href")
  if (length(href) == 0) {
    return(NA_character_)
  }
  url_absolute(href[[1]], url)
}

read_files <- function(html, url) {
  links <- html_elements(html, "a[onclick*='DownLd']")
  rows <- xml2::xml_find_first(links, "ancestor::tr[1]")
  tables <- xml2::xml_find_first(links, "ancestor::table[1]")
  headers <- purrr::map(tables, read_header)
  cells <- purrr::map(rows, \(row) {
    str_squish(html_text(html_elements(row, xpath = "./td")))
  })
  # The cell of each row under the header `label`, or `NA` without one.
  cell <- function(label) {
    purrr::map2_chr(headers, cells, \(header, row) {
      row[vctrs::vec_match(label, header)]
    })
  }
  # The links call `DownLd()` or `DownLd_new()` with the size, the file name,
  # and the path of the archive.
  path <- html_attr(links, "onclick") |>
    str_extract_all("'[^']*'") |>
    purrr::map_chr(\(args) str_remove_all(args[[3]], "'"))

  tibble(
    area_name = cell("地域"),
    datum_name = cell("測地系"),
    year_name = coalesce(cell("年"), cell("年度")),
    file_size = cell("ファイル容量"),
    file_label = cell("ファイル名"),
    url = url_absolute(str_trim(path), url)
  )
}

read_header <- function(table) {
  table |>
    html_elements("th") |>
    html_text() |>
    str_remove_all("[\\s▲▼]+")
}

# Parsing ----------------------------------------------------------------------

parse_year <- function(year_name) {
  western <- as.integer(str_match(year_name, "^(\\d{4})年")[, 2])
  era <- str_match(year_name, "^(明治|大正|昭和|平成|令和)(\\d+|元)年")
  era_year <- era_offsets[era[, 2]] +
    if_else(era[, 3] == "元", 1L, suppressWarnings(as.integer(era[, 3])))
  coalesce(western, unname(era_year))
}

parse_prefecture_code <- function(area_name) {
  code <- vctrs::vec_match(area_name, prefecture_names)
  if_else(is.na(code), NA_character_, sprintf("%02d", code))
}

# Sizes are published in MB or KB (with thousands separators); KB are
# converted to MB with the SI factor of 1000.
parse_file_size <- function(file_size) {
  size <- str_match(str_remove_all(file_size, ","), "^([0-9.]+)\\s*(MB|KB)$")
  value <- suppressWarnings(as.numeric(size[, 2]))
  if_else(size[, 3] == "KB", value / 1000, value)
}

# Of the rows that list the same URL, keeps the one whose prefecture code is in
# the file name, or else the first one. L02 lists `L02-24_02_GML.zip` (青森)
# under both 東北地方 and 青森.
keep_one_row <- function(files) {
  files |>
    mutate(
      consistent = !is.na(prefecture_code) &
        str_detect(
          file_name,
          str_c("_", tidyr::replace_na(prefecture_code, ""), "[_.-]")
        )
    ) |>
    filter(consistent | !any(consistent), .by = c(dataset_code, url)) |>
    distinct(dataset_code, url, .keep_all = TRUE) |>
    select(!consistent)
}


# Catalog ----------------------------------------------------------------------

# The catalog as two tables: `datasets`, one row per dataset page, and `files`,
# one row per downloadable file. Labels are kept as published, next to the
# values parsed from them.
read_catalog <- function() {
  pages <- read_index(index_url) |>
    mutate(
      dataset_code = parse_dataset_code(page_url),
      page = purrr::map(page_url, read_page, .progress = TRUE)
    ) |>
    tidyr::unnest(page)

  report(
    "Pages without download links:",
    pages |> filter(purrr::map_int(files, nrow) == 0) |> select(dataset_code)
  )

  files <- pages |>
    select(dataset_code, files) |>
    tidyr::unnest(files) |>
    mutate(
      file_name = basename(url),
      year = parse_year(year_name),
      prefecture_code = parse_prefecture_code(area_name),
      file_size = parse_file_size(file_size)
    )
  report_files(files)
  stopifnot(
    !anyNA(files$year),
    !anyNA(files$datum_name),
    !anyNA(files$area_name)
  )

  list(
    datasets = pages |>
      select(
        dataset_code,
        dataset_name,
        category_name,
        license_name,
        license_note,
        license_url,
        page_url,
        specification_url
      ),
    files = files |>
      keep_one_row() |>
      select(
        dataset_code,
        year,
        year_name,
        area_name,
        prefecture_code,
        datum_name,
        file_name,
        file_size,
        url
      )
  )
}

report_files <- function(files) {
  report(
    "Files whose label differs from their URL (the URL is used):",
    files |>
      filter(file_label != file_name) |>
      select(dataset_code, file_label, url)
  )
  report(
    str_c(
      "Files listed more than once (the row whose prefecture is in the file ",
      "name is kept, or else the first one):"
    ),
    files |>
      filter(n() > 1, .by = c(dataset_code, url)) |>
      select(dataset_code, area_name, year_name, file_name)
  )
  report(
    "Sizes that could not be parsed (kept as NA):",
    files |> filter(is.na(file_size)) |> select(dataset_code, file_name)
  )
}
