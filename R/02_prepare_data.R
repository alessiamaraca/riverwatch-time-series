# 02_prepare_data.R — normalize fields, quality checks, aggregate to month/year
source("R/00_setup.R")

raw_path <- "data/raw/usgs_daily_discharge.csv"
if (!file.exists(raw_path)) stop("Raw data not found. Run R/01_download_data.R first.")
raw <- readr::read_csv(raw_path, show_col_types = FALSE)

time_col <- intersect(c("time", "date", "datetime"), names(raw))[1]
value_col <- intersect(c("value", "result"), names(raw))[1]
if (is.na(time_col) || is.na(value_col)) {
  stop("Could not find a date and value column in raw data. Inspect the USGS CSV schema.")
}

daily <- raw |>
  dplyr::transmute(
    date = as.Date(.data[[time_col]]),
    discharge = suppressWarnings(as.numeric(.data[[value_col]]))
  ) |>
  dplyr::filter(!is.na(date)) |>
  dplyr::arrange(date) |>
  dplyr::distinct(date, .keep_all = TRUE) |>
  dplyr::mutate(
    year = lubridate::year(date),
    month = lubridate::month(date),
    month_start = lubridate::floor_date(date, "month")
  )

# Negative discharge is physically implausible for this site and treated as missing.
daily <- daily |>
  dplyr::mutate(discharge = dplyr::if_else(discharge < 0, NA_real_, discharge))

monthly <- daily |>
  dplyr::group_by(month_start) |>
  dplyr::summarise(
    discharge_mean = if (all(is.na(discharge))) NA_real_ else mean(discharge, na.rm = TRUE),
    discharge_median = if (all(is.na(discharge))) NA_real_ else median(discharge, na.rm = TRUE),
    n_daily = sum(!is.na(discharge)),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    year = lubridate::year(month_start),
    month = lubridate::month(month_start),
    log_discharge = log1p(discharge_mean)
  )

annual <- daily |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    discharge_mean = if (all(is.na(discharge))) NA_real_ else mean(discharge, na.rm = TRUE),
    discharge_median = if (all(is.na(discharge))) NA_real_ else median(discharge, na.rm = TRUE),
    n_daily = sum(!is.na(discharge)),
    .groups = "drop"
  ) |>
  dplyr::filter(n_daily > 0)

readr::write_csv(daily, "data/processed/daily_discharge.csv")
readr::write_csv(monthly, "data/processed/monthly_discharge.csv")
readr::write_csv(annual, "data/processed/annual_discharge.csv")

qc <- tibble::tibble(
  metric = c("daily_rows", "missing_discharge", "negative_values_set_missing",
             "monthly_rows", "annual_rows", "duplicate_dates_after_deduplication"),
  value = c(
    nrow(daily), sum(is.na(daily$discharge)),
    sum(!is.na(raw[[value_col]]) & suppressWarnings(as.numeric(raw[[value_col]])) < 0, na.rm = TRUE),
    nrow(monthly), nrow(annual), sum(duplicated(daily$date))
  )
)
readr::write_csv(qc, "outputs/tables/quality_checks.csv")
message("Prepared daily, monthly, and annual datasets.")
