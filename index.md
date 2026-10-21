# ksjdata

English \| [日本語](https://uchidamizuki.github.io/ksjdata/README.ja.md)

ksjdata provides National Land Numerical Information (国土数値情報,
KSJ), published by the Ministry of Land, Infrastructure, Transport and
Tourism of Japan.

- `ksj_available` is the catalog: it lists every supported file, with
  its dataset, release, area, and the page of its dataset. Filter it to
  choose files.
- [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
  downloads and reads one file, and returns one layer as an `sf` tibble.
  To get several files, iterate over their names, for example with
  [`purrr::map()`](https://purrr.tidyverse.org/reference/map.html). Each
  file is cached by the
  [tarchives](https://github.com/UchidaMizuki/tarchives) package, so it
  is downloaded only once.
- Columns are named in Japanese after the official attribute table. Use
  `col_names = "raw"` to keep the names of the file (usually attribute
  codes such as `N03_001`), for example for older releases.

## Installation

You can install the development version of ksjdata from GitHub with:

``` r

# install.packages("pak")
pak::pak("UchidaMizuki/ksjdata")
```

## Usage

Filter `ksj_available` to find files. Each row is one file, identified
by its `file_name` (the name of the archive on the KSJ download site).

``` r

library(ksjdata)
library(dplyr)

files <- ksj_available |>
  filter(
    dataset_code == "N03",
    year == 2026,
    prefecture_code %in% c("13", "14")
  )
files |>
  select(dataset_name, year_name, area_name, file_name, file_size)
#> # A tibble: 2 × 5
#>   dataset_name   year_name         area_name file_name                 file_size
#>   <chr>          <chr>             <chr>     <chr>                   <fs::bytes>
#> 1 行政区域データ 2026年（令和8年） 東京      N03-20260101_13_GML.zip      11.96M
#> 2 行政区域データ 2026年（令和8年） 神奈川    N03-20260101_14_GML.zip       4.88M
```

Pass a `file_name` to
[`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md)
to get that file. The first time a dataset is requested in a session,
the pages that state its terms of use are shown.

``` r

ksj_get("N03-20260101_13_GML.zip")
#> Check the terms of use of N03 (行政区域データ) for this release on its page.
#> ! Terms can differ by release and by area; some older releases cannot be used
#>   commercially.
#> ℹ <https://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-N03-2026.html>
#> ℹ <https://nlftp.mlit.go.jp/ksj/other/agreement.html>
#> This message is displayed once per session.
#> Simple feature collection with 6904 features and 6 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 136.0695 ymin: 20.42275 xmax: 153.9867 ymax: 35.89842
#> Geodetic CRS:  JGD2011
#> # A tibble: 6,904 × 7
#>    都道府県名 北海道の振興局名 群名  市区町村名 政令指定都市の行政区域名
#>    <chr>      <chr>            <chr> <chr>      <chr>                   
#>  1 東京都     <NA>             <NA>  所属未定地 <NA>                    
#>  2 東京都     <NA>             <NA>  所属未定地 <NA>                    
#>  3 東京都     <NA>             <NA>  所属未定地 <NA>                    
#>  4 東京都     <NA>             <NA>  所属未定地 <NA>                    
#>  5 東京都     <NA>             <NA>  所属未定地 <NA>                    
#>  6 東京都     <NA>             <NA>  所属未定地 <NA>                    
#>  7 東京都     <NA>             <NA>  所属未定地 <NA>                    
#>  8 東京都     <NA>             <NA>  所属未定地 <NA>                    
#>  9 東京都     <NA>             <NA>  所属未定地 <NA>                    
#> 10 東京都     <NA>             <NA>  所属未定地 <NA>                    
#> # ℹ 6,894 more rows
#> # ℹ 2 more variables: 全国地方公共団体コード <chr>, geometry <POLYGON [°]>
```

To get several files, iterate over their names:

``` r

purrr::map(files$file_name, ksj_get)
```

In a [targets](https://docs.ropensci.org/targets/) pipeline,
[`ksj_target()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_target.md)
declares a target that gets one file. Use
[`tarchetypes::tar_eval()`](https://docs.ropensci.org/tarchetypes/reference/tar_eval.html)
to declare one per file.

``` r

tarchetypes::tar_eval(
  ksj_target(name, file_name),
  values = list(
    name = rlang::syms(stringr::str_c("n03_", files$prefecture_code)),
    file_name = files$file_name
  )
)
```

The data are returned as published: geometries and coordinate reference
systems are not changed, codes keep their leading zeros, and published
zeros stay distinct from blank cells (`NA`).

## Terms of use

Each release of a dataset has its own terms, stated on the KSJ site: on
the page of the dataset (`page_url` of `ksj_available`) and the pages of
its versions, which it links to. The first time a dataset is requested
in a session, these pages are shown. Published or processed data must
credit the source, and processed data must say that they were processed.

- Terms can differ by release or by area within a dataset: older
  releases of some datasets cannot be used commercially (非商用) even
  where the latest is open data, and some areas have their own
  conditions. Check the terms of the release you use.
- The package does not copy the terms, as the site does not state them
  in a form that can be read reliably for each file.
- Complying with the terms is up to you. This package does not give
  legal advice.
- The MIT license of this package applies to its code only, not to the
  data.

## Supported datasets

| Code | Name | Releases |
|:---|:---|:---|
| A03 | 三大都市圏計画区域データ | 2003–2025 |
| A09 | 都市地域データ | 2006–2018 |
| A10 | 自然公園地域データ | 2006–2015 |
| A11 | 自然保全地域データ | 2006–2015 |
| A12 | 農業地域データ | 2006–2015 |
| A13 | 森林地域データ | 2006–2015 |
| A15 | 鳥獣保護区データ | 2009–2015 |
| A16 | 人口集中地区データ | 1960–2020 |
| A17 | 過疎地域データ | 1970–2017 |
| A18 | 半島振興対策実施地域データ | 1986–2016 |
| A18s-a | 半島振興対策実施地域統計情報 | 1995–2010 |
| A19 | 離島振興対策実施地域データ | 1953–2017 |
| A19s | 離島振興対策実施地域統計情報 | 1995–2010 |
| A20 | 奄美群島データ | 1954–2007 |
| A20s | 奄美群島統計情報 | 1995–2010 |
| A21 | 小笠原諸島データ | 1969–2007 |
| A21s | 小笠原諸島統計情報 | 1995–2010 |
| A22 | 豪雪地帯データ | 1963–2016 |
| A22-m | 豪雪地帯（気象データ等） | 2014–2014 |
| A22s | 豪雪地帯統計情報 | 1995–2010 |
| A23 | 特殊土壌地帯データ | 1952–2016 |
| A24 | 振興山村データ | 1966–2016 |
| A25 | 特定農山村地域データ | 1993–2016 |
| A27 | 小学校区データ | 2010–2023 |
| A28 | 世界自然遺産データ | 2010–2022 |
| A30a5 | 土砂災害・雪崩メッシュデータ | 2011–2011 |
| A30b | 竜巻等の突風データ | 2011–2011 |
| A31a | 洪水浸水想定区域データ | 2012–2025 |
| A31b | 洪水浸水想定区域（1次メッシュ単位）データ | 2022–2025 |
| A32 | 中学校区データ | 2013–2023 |
| A33 | 土砂災害警戒区域データ | 2013–2025 |
| A34 | 世界文化遺産データ | 2015–2022 |
| A35a | 景観計画区域データ | 2014–2014 |
| A35b | 景観地区・準景観地区データ | 2014–2014 |
| A35c | 景観重要建造物・樹木データ | 2014–2014 |
| A37 | 半島循環道路データ | 2015–2015 |
| A38 | 医療圏データ | 2014–2020 |
| A39 | 密集市街地データ | 2015–2015 |
| A40 | 津波浸水想定データ | 2016–2024 |
| A42 | 歴史的風土保存区域データ | 2018–2018 |
| A43 | 伝統的建造物群保存地区データ | 2018–2018 |
| A44 | 歴史的風致維持向上計画の重点地区データ | 2018–2018 |
| A45 | 国有林野データ | 2018–2024 |
| A46 | 地すべり防止区域データ | 2020–2021 |
| A47 | 急傾斜地崩壊危険区域データ | 2020–2021 |
| A48 | 災害危険区域データ | 2020–2021 |
| A49 | 高潮浸水想定区域データ | 2020–2024 |
| A50 | 立地適正化計画区域データ | 2020–2020 |
| A51 | 雨水出水（内水）浸水想定区域データ | 2024–2025 |
| A52 | 砂防指定地データ | 2023–2023 |
| A53 | 多段階浸水想定データ | 2023–2025 |
| A54 | 大規模盛土造成地データ | 2023–2023 |
| A56 | 宅地造成等工事規制区域・特定盛土等規制区域データ | 2025–2025 |
| C02 | 港湾データ | 2006–2014 |
| C09 | 漁港データ | 2006–2006 |
| C23 | 海岸線データ | 2006–2006 |
| C28 | 空港データ | 2004–2021 |
| G02 | 平年値メッシュデータ | 2012–2022 |
| G04-a | 標高・傾斜度3次メッシュデータ | 2011–2011 |
| G04-c | 標高・傾斜度4次メッシュデータ | 2011–2011 |
| G04-d | 標高・傾斜度5次メッシュデータ | 2011–2011 |
| G08 | 低位地帯データ | 2015–2015 |
| L01 | 地価公示データ | 1983–2026 |
| L02 | 都道府県地価調査データ | 1983–2026 |
| L03-a | 土地利用3次メッシュデータ | 1976–2021 |
| L03-b | 土地利用細分メッシュデータ | 1976–2021 |
| L03-b-c | 土地利用詳細メッシュデータ | 2016–2021 |
| L03-b-u | 都市地域土地利用細分メッシュデータ | 2009–2021 |
| N02 | 鉄道データ | 2005–2025 |
| N03 | 行政区域データ | 1920–2026 |
| N04 | 道路密度・道路延長メッシュデータ | 1978–2010 |
| N05 | 鉄道時系列データ | 2011–2025 |
| N06 | 高速道路時系列データ | 2011–2025 |
| N07 | バスルート | 2011–2022 |
| N08 | 空港時系列データ | 2011–2021 |
| N09 | 定期旅客航路データ | 2012–2012 |
| N10 | 緊急輸送道路 | 2013–2024 |
| N11 | ヘリポート | 2013–2013 |
| N12 | 重要物流道路 | 2021–2021 |
| N13 | 道路データ | 2024–2024 |
| P02 | 公共施設データ | 1990–2006 |
| P03 | 発電施設 | 1995–2013 |
| P04 | 医療機関データ | 2010–2020 |
| P05 | 市町村役場等及び公的集会施設データ | 2010–2022 |
| P07 | 燃料給油所データ | 2010–2015 |
| P09 | 宿泊容量メッシュデータ | 2010–2010 |
| P11 | バス停留所データ | 2010–2022 |
| P12 | 観光資源データ | 2010–2014 |
| P13 | 都市公園データ | 2011–2011 |
| P14 | 福祉施設データ | 2011–2023 |
| P15 | 廃棄物処理施設データ | 2012–2012 |
| P16 | 研究機関データ | 2012–2012 |
| P17 | 消防署データ | 2012–2012 |
| P18 | 警察署データ | 2012–2012 |
| P19 | 地域資源データ | 2012–2012 |
| P20 | 避難施設データ | 2012–2012 |
| P21 | 上水道関連施設データ | 2012–2012 |
| P22 | 下水道関連施設データ | 2012–2012 |
| P23 | 海岸保全施設データ | 2012–2012 |
| P24 | 地場産業関連施設データ | 2012–2012 |
| P26 | ニュータウンデータ | 2013–2013 |
| P27 | 文化施設データ | 2013–2013 |
| P28 | 国・都道府県の機関データ | 2013–2022 |
| P29 | 学校データ | 2013–2023 |
| P30 | 郵便局データ | 2013–2013 |
| P31 | 物流拠点 | 2013–2013 |
| P32 | 都道府県指定文化財データ | 2014–2014 |
| P33 | 集客施設データ | 2014–2014 |
| P34 | 市区町村役場データ | 2014–2014 |
| P35 | 道の駅データ | 2018–2018 |
| P36 | 高速バス停留所データ | 2023–2023 |
| S05-a | 交通流動量 パーソントリップ発生・集中量データ | 2010–2013 |
| S05-b | 交通流動量 パーソントリップOD量データ | 2010–2013 |
| S05-c | 交通流動量 駅別乗降数データ | 2010–2012 |
| S05-d | 交通流動量 貨物・旅客地域流動量データ | 2001–2018 |
| S10a | 港湾間流通量・海上経路データ | 2011–2016 |
| S10b | 空港間流通量 | 2011–2014 |
| S12 | 駅別乗降客数データ | 2011–2024 |
| W01 | ダムデータ | 2005–2014 |
| W05 | 河川データ | 2006–2009 |
| W07 | 流域メッシュデータ | 2009–2009 |
| W09 | 湖沼データ | 2005–2005 |
| mesh1000 | 1kmメッシュ別将来推計人口データ（H29国政局推計）（shape形式版） | 2017–2017 |
| mesh1000h30 | 1kmメッシュ別将来推計人口データ（H30国政局推計）（shape形式版） | 2018–2018 |
| mesh1000r6 | 1kmメッシュ別将来推計人口データ（R6国政局推計） | 2024–2024 |
| mesh250r6 | 250mメッシュ別将来推計人口データ（R6国政局推計） | 2024–2024 |
| mesh500 | 500mメッシュ別将来推計人口データ（H29国政局推計）（shape形式版） | 2017–2017 |
| mesh500h30 | 500mメッシュ別将来推計人口データ（H30国政局推計）（shape形式版） | 2018–2018 |
| mesh500r6 | 500mメッシュ別将来推計人口データ（R6国政局推計） | 2024–2024 |
