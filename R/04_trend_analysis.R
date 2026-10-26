# 04_trend_analysis.R — annual trend test and GAM for monthly trend + seasonality
source("R/00_setup.R")
annual <- readr::read_csv("data/processed/annual_discharge.csv", show_col_types = FALSE) |>
  dplyr::filter(is.finite(discharge_mean))
monthly <- readr::read_csv("data/processed/monthly_discharge.csv", show_col_types = FALSE) |>
  dplyr::mutate(month_start = as.Date(month_start)) |>
  dplyr::filter(is.finite(discharge_mean))

if (nrow(annual) < 10) stop("Not enough annual observations for trend analysis.")

mk <- Kendall::MannKendall(annual$discharge_mean)
sen <- trend::sens.slope(annual$discharge_mean)

trend_table <- tibble::tibble(
  method = c("Mann-Kendall", "Sen's slope"),
  estimate = c(unname(mk$tau), unname(sen$estimates)),
  p_value = c(unname(mk$sl), unname(sen$p.value)),
  interpretation = c(
    "Kendall tau: direction/strength of monotonic association with time index",
    "Sen slope: median pairwise slope in discharge units per year"
  )
)
readr::write_csv(trend_table, "outputs/tables/trend_results.csv")

p <- ggplot(annual, aes(year, discharge_mean)) +
  geom_line(alpha = 0.65) + geom_point(size = 1.5) +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE, linewidth = 0.8) +
  labs(title = "Annual mean discharge and linear trend",
       subtitle = "Descriptive linear fit; Mann–Kendall and Sen's slope reported separately",
       x = "Year", y = "Annual mean discharge")
save_plot(p, "03_annual_trend.png", 10, 5)

# GAM: smooth long-term time effect plus cyclic seasonal effect.
monthly <- monthly |>
  dplyr::mutate(
    time_index = as.numeric(month_start - min(month_start)) / 365.25,
    month_factor = factor(month, levels = 1:12),
    month_num = month
  )
gam_fit <- mgcv::gam(
  log1p(discharge_mean) ~ s(time_index, k = min(30, max(5, floor(nrow(monthly) / 12)))) +
    s(month_num, bs = "cc", k = 12),
  data = monthly, method = "REML",
  knots = list(month_num = c(0.5, 12.5))
)
monthly$gam_fitted <- as.numeric(predict(gam_fit, newdata = monthly))
p_gam <- ggplot(monthly, aes(month_start)) +
  geom_line(aes(y = log1p(discharge_mean)), alpha = 0.45, linewidth = 0.35) +
  geom_line(aes(y = gam_fitted), linewidth = 0.9) +
  labs(title = "GAM: smooth long-term pattern plus cyclic seasonality",
       subtitle = "Response is log(1 + monthly mean discharge); fitted values are on log scale",
       x = NULL, y = "log(1 + monthly mean discharge)")
save_plot(p_gam, "04_gam_trend_seasonality.png", 11, 5)

capture.output(summary(gam_fit), file = "outputs/tables/gam_summary.txt")
message("Trend analysis complete.")
