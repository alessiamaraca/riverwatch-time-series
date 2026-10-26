# 01_download_data.R — fetch daily mean discharge from the modern USGS API
source("R/00_setup.R")

message("Downloading USGS daily mean discharge. This may take a minute...")
raw <- dataRetrieval::read_waterdata_daily(
  monitoring_location_id = SITE_ID,
  parameter_code = PARAMETER_CODE,
  statistic_id = STATISTIC_ID,
  time = c(START_DATE, as.character(END_DATE))
)

if (is.null(raw) || nrow(raw) == 0) {
  stop("USGS returned no observations. Check API availability, site ID, and date range.")
}

# Modern dataRetrieval output uses `time` and `value`; preserve source fields.
readr::write_csv(raw, "data/raw/usgs_daily_discharge.csv", na = "")

time_col <- intersect(c("time", "date", "datetime"), names(raw))[1]
value_col <- intersect(c("value", "result"), names(raw))[1]
if (is.na(time_col) || is.na(value_col)) {
  stop("Unexpected USGS response schema. Inspect names(raw) and update column mapping.")
}

manifest <- tibble::tibble(
  source = "USGS Water Data API via dataRetrieval",
  site_id = SITE_ID,
  parameter_code = PARAMETER_CODE,
  statistic_id = STATISTIC_ID,
  requested_start = START_DATE,
  requested_end = as.character(END_DATE),
  retrieved_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  rows_downloaded = nrow(raw),
  first_observation = as.character(min(as.Date(raw[[time_col]]), na.rm = TRUE)),
  last_observation = as.character(max(as.Date(raw[[time_col]]), na.rm = TRUE)),
  raw_file = "data/raw/usgs_daily_discharge.csv"
)
readr::write_csv(manifest, "outputs/tables/data_manifest.csv")
message("Saved ", nrow(raw), " rows to data/raw/usgs_daily_discharge.csv")
