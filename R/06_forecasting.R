# 06_forecasting.R — seasonal ARIMA vs seasonal-naive baseline, chronological holdout
source("R/00_setup.R")
monthly <- readr::read_csv("data/processed/monthly_discharge.csv", show_col_types = FALSE) |>
  dplyr::mutate(month_start = as.Date(month_start)) |>
  dplyr::arrange(month_start)

# Forecast monthly mean flow, not the log-transformed series, for interpretability.
series <- monthly$discharge_mean
valid <- which(is.finite(series))
if (length(valid) < 72) stop("Need at least 72 valid monthly observations for this demo.")
first_i <- min(valid)
last_i <- max(valid)
series <- series[first_i:last_i]
dates <- monthly$month_start[first_i:last_i]
# Keep only a complete sequence of monthly rows; missing values are linearly interpolated
# solely to make a regular ts for this baseline demo. This choice is recorded explicitly.
series_filled <- zoo::na.approx(series, na.rm = FALSE)
series_filled <- zoo::na.locf(series_filled, na.rm = FALSE)
series_filled <- zoo::na.locf(series_filled, fromLast = TRUE, na.rm = FALSE)

h <- min(24, max(12, floor(length(series_filled) * 0.15)))
train_n <- length(series_filled) - h
train <- series_filled[seq_len(train_n)]
test <- series_filled[(train_n + 1):length(series_filled)]
test_dates <- dates[(train_n + 1):length(dates)]
start_year <- lubridate::year(dates[1])
start_month <- lubridate::month(dates[1])
train_ts <- ts(train, start = c(start_year, start_month), frequency = 12)

fit <- forecast::auto.arima(
  train_ts, seasonal = TRUE, stepwise = FALSE, approximation = FALSE
)
pred_arima <- as.numeric(forecast::forecast(fit, h = h)$mean)

# Seasonal-naive forecast repeats the value from 12 months earlier.
pred_snaive <- vapply(seq_len(h), function(i) {
  train[length(train) - 12 + ((i - 1) %% 12) + 1]
}, numeric(1))

metric_row <- function(model, pred, actual) {
  tibble::tibble(
    model = model,
    MAE = mean(abs(actual - pred), na.rm = TRUE),
    RMSE = sqrt(mean((actual - pred)^2, na.rm = TRUE)),
    MAPE_percent = mean(abs((actual - pred) / pmax(abs(actual), 1e-8)), na.rm = TRUE) * 100
  )
}
metrics <- dplyr::bind_rows(
  metric_row("Seasonal naive baseline", pred_snaive, test),
  metric_row("Auto ARIMA/SARIMA", pred_arima, test)
)
readr::write_csv(metrics, "outputs/tables/forecast_metrics.csv")
capture.output(summary(fit), file = "outputs/tables/arima_model_summary.txt")

forecast_df <- tibble::tibble(
  date = test_dates, actual = test,
  seasonal_naive = pred_snaive, arima = pred_arima
)
readr::write_csv(forecast_df, "outputs/tables/forecast_holdout_predictions.csv")

p <- ggplot(forecast_df, aes(date)) +
  geom_line(aes(y = actual, colour = "Observed"), linewidth = 0.8) +
  geom_line(aes(y = seasonal_naive, colour = "Seasonal naive"), linetype = 2) +
  geom_line(aes(y = arima, colour = "ARIMA/SARIMA"), linetype = 1) +
  labs(title = "Out-of-sample monthly discharge forecast",
       subtitle = paste0("Last ", h, " months held out; model selected using training data only"),
       x = NULL, y = "Monthly mean discharge", colour = NULL) +
  theme(legend.position = "bottom")
save_plot(p, "06_forecast_holdout.png", 11, 5)
message("Forecast comparison complete.")
