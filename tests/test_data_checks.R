# Lightweight checks for processed data after running the pipeline.
library(testthat)
library(readr)

test_that("processed daily data has unique dates and nonnegative discharge", {
  skip_if_not(file.exists("data/processed/daily_discharge.csv"))
  d <- read_csv("data/processed/daily_discharge.csv", show_col_types = FALSE)
  expect_true(all(!is.na(d$date)))
  expect_equal(anyDuplicated(d$date), 0L)
  expect_true(all(d$discharge[!is.na(d$discharge)] >= 0))
})

test_that("monthly data contains one row per month", {
  skip_if_not(file.exists("data/processed/monthly_discharge.csv"))
  m <- read_csv("data/processed/monthly_discharge.csv", show_col_types = FALSE)
  expect_equal(anyDuplicated(m$month_start), 0L)
})
