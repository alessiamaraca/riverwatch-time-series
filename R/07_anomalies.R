# 07_anomalies.R — robust screening of unusual seasonally adjusted observations
source("R/00_setup.R")
monthly <- readr::read_csv("data/processed/monthly_discharge.csv", show_col_types = FALSE) |>
  dplyr::mutate(month_start = as.Date(month_start)) |>
  dplyr::filter(is.finite(log_discharge)) |>
  dplyr::group_by(month) |>
  dplyr::mutate(seasonal_median = median(log_discharge, na.rm = TRUE)) |>
  dplyr::ungroup() |>
  dplyr::mutate(anomaly = log_discharge - seasonal_median)

mad_value <- mad(monthly$anomaly, constant = 1.4826, na.rm = TRUE)
if (!is.finite(mad_value) || mad_value == 0) mad_value <- sd(monthly$anomaly, na.rm = TRUE)
monthly <- monthly |>
  dplyr::mutate(robust_z = (anomaly - median(anomaly, na.rm = TRUE)) / mad_value,
                flagged = abs(robust_z) >= 3.5)

anomalies <- monthly |>
  dplyr::filter(flagged) |>
  dplyr::select(month_start, discharge_mean, anomaly, robust_z)
readr::write_csv(anomalies, "outputs/tables/anomalies.csv")

p <- ggplot(monthly, aes(month_start, anomaly)) +
  geom_hline(yintercept = 0, linetype = 2, alpha = 0.5) +
  geom_line(alpha = 0.7) +
  geom_point(data = dplyr::filter(monthly, flagged), aes(y = anomaly), size = 2) +
  labs(title = "Potential anomalies in monthly discharge",
       subtitle = "Robust z-score threshold |z| ≥ 3.5 after month-specific seasonal adjustment",
       x = NULL, y = "Log discharge anomaly")
save_plot(p, "07_anomalies.png", 11, 5)
message(nrow(anomalies), " candidate anomalies flagged.")
