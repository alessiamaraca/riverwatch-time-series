# 05_change_points.R — candidate mean shifts after removing smooth trend/seasonality
source("R/00_setup.R")
monthly <- readr::read_csv("data/processed/monthly_discharge.csv", show_col_types = FALSE) |>
  dplyr::mutate(month_start = as.Date(month_start)) |>
  dplyr::filter(is.finite(log_discharge)) |>
  dplyr::arrange(month_start)

if (nrow(monthly) < 60) {
  warning("Fewer than 60 valid months; change-point results may be unstable.")
}

# Remove typical monthly seasonality using month-specific medians.
monthly <- monthly |>
  dplyr::group_by(month) |>
  dplyr::mutate(seasonal_median = median(log_discharge, na.rm = TRUE)) |>
  dplyr::ungroup() |>
  dplyr::mutate(anomaly = log_discharge - seasonal_median)

# PELT mean-shift screening. Penalty is conservative; this is exploratory, not causal.
cp <- changepoint::cpt.mean(
  monthly$anomaly, method = "PELT", penalty = "MBIC",
  minseglen = 24, class = TRUE
)
cp_index <- changepoint::cpts(cp)
cp_index <- cp_index[cp_index <= nrow(monthly)]
cp_table <- tibble::tibble(
  index = cp_index,
  candidate_date = if (length(cp_index)) as.character(monthly$month_start[cp_index]) else character(0),
  note = "Candidate break in seasonally adjusted log discharge; investigate data and context."
)
readr::write_csv(cp_table, "outputs/tables/change_points.csv")

p <- ggplot(monthly, aes(month_start, anomaly)) +
  geom_hline(yintercept = 0, linetype = 2, alpha = 0.5) +
  geom_line(linewidth = 0.45) +
  { if (length(cp_index)) geom_vline(xintercept = as.numeric(monthly$month_start[cp_index]),
                                      linetype = 2, alpha = 0.7) } +
  labs(title = "Candidate change points in seasonal anomalies",
       subtitle = "Vertical lines indicate PELT candidate breaks; they do not establish cause",
       x = NULL, y = "Log discharge minus month-specific median")
save_plot(p, "05_change_points.png", 11, 5)
message("Change-point screening complete.")
