# NA

## This package

ksjdata provides National Land Numerical Information (国土数値情報,
KSJ), built on tarchives. Read `ARCHITECTURE.md` before making changes,
and update it when a change alters the design it describes.

- Keep the code simple: one small function per step, plain tibbles and
  `sf` objects, no tibble subclasses or hidden attributes.
- Users reach data only through `ksj_available` and
  [`ksj_get()`](https://uchidamizuki.github.io/ksjdata/reference/ksj_get.md).
  Do not add per-dataset functions.
- `ksj_available` is the only catalog users see. It is a data object
  computed by `ksj_available_impl()`, which joins the scraped catalog in
  `data-raw/` (not shipped) with the bundled pipelines (one per
  dataset), so it lists only supported files. `ksj_attributes` is
  computed likewise by `ksj_attributes_impl()`. Scrape the site with
  `data-raw/update.R`; rebuild the pipelines and the data objects
  offline with `data-raw/build.R` whenever `inst/tarchives/`, the files
  in `data-raw/`, or an `_impl()` function changes. Build each
  pipeline’s targets from `ksj_available`.
- Take URLs from `ksj_available`. Do not build them from patterns or
  scrape pages at run time.
- Take names only from the attribute table, through `ksj_attributes`. Do
  not type names by hand.
- Name columns in Japanese by default (`col_names = "ja"`), or keep the
  names of the file (`col_names = "raw"`). Never mix them in one result,
  and never name a layer that is not fully covered.
- Return the data as published. Do not simplify, dissolve, reproject,
  filter, or aggregate.
- Keep published zeros (`0`) distinct from suppressed or blank cells
  (`NA`).
- Show the terms of use of every dataset; do not hide or drop
  non-commercial datasets.
- Unit tests use fixture files and must not use the network.
- Do not mention other repositories or local paths, except tarchives.

## Package development

### Key commands

(All these functions have been optimized for agentic use, so they can be
called directly without other arguments.)

``` r

# Executing code
devtools::load_all()
code

# Tests
devtools::test() # all tests
devtools::test(filter = "^{name}") # tests for files starting with {name}
devtools::test_active_file("R/{name}.R") # tests for R/{name}.R
devtools::test_active_file("R/{name}.R", desc = 'blah') # single test with exact description "blah" (no regexp)

# Test coverage
devtools::test_coverage() # all files
devtools::test_coverage_active_file("R/{name}.R") # coverage for R/{name}.R from tests in tests/testthat/test-{name}.R

# Documentation
devtools::document() # redocument package
pkgdown::check_pkgdown() # check website

# Run complete R CMD check
devtools::check()
```

### Running R

There are three possible ways to run code, listed in rough order of
desirability:

- If you’re running inside Posit Assistant or otherwise have an
  `executeCode()` tool available, use it to run code in a session that
  the user can also interact with.

- Otherwise, if an R REPL (e.g. `mcp__r__repl` or `btw::run_r`) is
  available, use that. Note that `mcp__r__repl` uses a sandbox that
  blocks network requests and reads/writes outside of the current
  directory.

- Otherwise, use `Rscript -e "code"`.

### Code style

- Follow the tidyverse style guide
- Always run `air format .` after generating code.
- Use the base pipe operator (`|>`), not the magrittr pipe (`%>%`).
- Use `\() ...` for single-line anonymous functions. For all other
  cases, use `function() {...}`.

### Test style

- Tests for `R/{name}.R` go in `tests/testthat/test-{name}.R`.
- All new code should have an accompanying test.
- If there are existing tests, place new tests next to similar existing
  tests.
- Strive to keep your tests minimal with few comments.
- Never put code in a `test-{name}.R` file outside of a `test_that()`
  block. Instead, use `tests/testthat/helper.R` or
  `tests/testthat/helper-{name}.R`.
- Avoid `expect_true()` and `expect_false()` in favor of a specific
  expectation with a better failure message. A few expectations in newer
  releases that you might not know about are `expect_all_true()`,
  `expect_all_equal()`, and `expect_r6_class()`.
- When testing errors and warnings:
  - Only use `expect_error()` or `expect_warning()` if the error or
    warning has a known class.
  - Generally, prefer `expect_snapshot(error = TRUE)` for errors and
    `expect_snapshot()` for warnings because these allow the user to
    review the full text of the output.
- Avoid the `.package` argument to `local_mocked_bindings()`; this
  modifies the namespace of another package, which is not good practice.
  Instead create a mockable version of the function in the current
  package. See `?local_mocked_bindings` for more details.

### Documentation

- Every user-facing function should be exported and have roxygen2
  documentation.
- Internal functions should not have roxygen documentation.
- Wrap roxygen2 comments to 80 characters.
- Whenever you add a new (non-internal) documentation topic, also add
  the topic to `_pkgdown.yml`.
- Always re-document the package after changing a roxygen2 comment.
- Use
  [`pkgdown::check_pkgdown()`](https://pkgdown.r-lib.org/reference/check_pkgdown.html)
  to check that all topics are included in the reference index.

### `NEWS.md`

- Every user-facing change should be given a bullet in `NEWS.md`.
- Changes that shouldn’t get a bullet:
  - Small documentation changes.
  - Internal refactorings.
  - Fixes to bugs introduced in the current dev version.
- Each bullet should briefly describe the change to the end user and
  mention the related issue in parentheses.
- A bullet can consist of multiple sentences but should not contain any
  newlines (i.e. DO NOT line wrap).
- If the change is related to a function, put the name of the function
  early in the bullet.
- If the change is related to an issue, include the issue number in
  parentheses.
- Only include a GitHub username if the PR was created by someone who
  isn’t an author.
- Order bullets alphabetically by function name. Put all bullets that
  don’t mention function names at the beginning.

## Specialized skills

- Do you need to deprecate a function or argument? Read the output of
  `usethis::learn_tidy_skill("deprecate")`.
- Are you adding input checking to an existing function or writing a new
  exported function? Read the output of
  `usethis::learn_tidy_skill("arg-checking")`.

## Git

- If the user asks you to commit, use markdown in the commit message,
  and don’t line wrap.
- If the commit fixes an issue, include `Fixes #num.` on its own line.
- Only push when the user explicitly requests it.

## Writing

- Use sentence case for headings.
- Use US English.

### Proofreading

If the user asks you to proofread a file, act as an expert proofreader
and editor with a deep understanding of clear, engaging, and
well-structured writing.

Work paragraph by paragraph, always starting by making a TODO list that
includes individual items for each top-level section.

Fix spelling, grammar, and other minor problems without asking the user.
Label any unclear, confusing, or ambiguous sentences with a FIXME
comment.

Only report what you have changed.
