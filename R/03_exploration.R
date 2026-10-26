# 03_exploration.R — time-series overview and seasonal structure
source("R/00_setup.R")
if (!file.exists("data/processed/monthly_discharge.csv")) source("R/02_prepare_data.R")
daily <- readr::read_csv("data/processed/daily_discharge.csv", show_col_types = FALSE)
monthly <- readr::read_csv("data/processed/monthly_discharge.csv", show_col_types = FALSE) |>
  dplyr::mutate(month_start = as.Date(month_start))

p1 <- ggplot(daily, aes(date, discharge)) +
  geom_line(linewidth = 0.25, alpha = 0.7) +
  scale_y_continuous(labels = scales::label_number(big.mark = ",")) +
  labs(title = "Daily mean discharge", subtitle = "USGS site 01491000 — raw daily variability",
       x = NULL, y = "Discharge (USGS-reported units)")
save_plot(p1, "01_daily_discharge.png", 11, 5)

seasonal <- monthly |>
  dplyr::filter(!is.na(discharge_mean)) |>
  dplyr::group_by(month) |>
  dplyr::summarise(
    median_flow = median(discharge_mean),
    q25 = quantile(discharge_mean, 0.25),
    q75 = quantile(discharge_mean, 0.75),
    .groups = "drop"
  )
p2 <- ggplot(seasonal, aes(month, median_flow)) +
  geom_ribbon(aes(ymin = q25, ymax = q75), alpha = 0.2) +
  geom_line(linewidth = 0.8) + geom_point(size = 2) +
  scale_x_continuous(breaks = 1:12, labels = month.abb) +
  labs(title = "Seasonal pattern in monthly discharge",
       subtitle = "Median across years; ribbon shows interquartile range",
       x = NULL, y = "Monthly mean discharge")
save_plot(p2, "02_monthly_seasonality.png", 10, 5)

# STL requires a regular monthly series. Interpolate only for decomposition,
# and keep the original monthly observations for all primary statistical tests.
stl_data <- monthly |>
  dplyr::arrange(month_start) |>
  dplyr::mutate(log_discharge = ifelse(is.finite(log_discharge), log_discharge, NA_real_))
if (sum(!is.na(stl_data$log_discharge)) > 36) {
  stl_data$log_for_stl <- zoo::na.approx(stl_data$log_discharge, na.rm = FALSE)
  stl_data$log_for_stl <- zoo::na.locf(stl_data$log_for_stl, na.rm = FALSE)
  stl_data$log_for_stl <- zoo::na.locf(stl_data$log_for_stl, fromLast = TRUE, na.rm = FALSE)
  start_year <- lubridate::year(min(stl_data$month_start))
  start_month <- lubridate::month(min(stl_data$month_start))
  ts_flow <- ts(stl_data$log_for_stl, start = c(start_year, start_month), frequency = 12)
  dec <- stl(ts_flow, s.window = "periodic", robust = TRUE)
  png("outputs/figures/03_stl_decomposition.png", width = 1400, height = 900, res = 140)
  plot(dec, main = "STL decomposition of log(1 + monthly mean discharge)")
  dev.off()
}
message("Exploration figures saved.")
