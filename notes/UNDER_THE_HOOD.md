# Under the hood: project notes for interview preparation

## 1. What is a time series?

A time series is a sequence of observations indexed in time. Order matters: adjacent observations often depend on each other. River discharge has strong short-term persistence and often a recurring seasonal cycle.

## 2. Data provenance and quality control

The pipeline fetches daily mean discharge for USGS site `USGS-01491000`. The raw response is retained unchanged in `data/raw/`; normalized data are written to `data/processed/`. The manifest records retrieval time and requested dates. This separation supports reproducibility and auditability.

Always check:
- whether values are provisional or approved;
- missing dates and duplicate timestamps;
- units and parameter/statistic codes;
- changes in station equipment, location, or measurement practices;
- whether a time series is continuous enough for the planned analysis.

## 3. Why aggregate to monthly and annual values?

Daily discharge is noisy and highly skewed. Monthly means expose seasonal patterns while reducing day-to-day noise. Annual means support a simpler long-term trend summary. Aggregation also discards information, especially floods and short-lived extremes, so the daily plot remains part of the analysis.

## 4. Seasonality and STL

Seasonality is a pattern that repeats on a known calendar period. Monthly data typically use frequency 12. STL decomposes a series into trend, seasonal, and remainder components. The current script interpolates missing values only for the STL visualization; those interpolated values should not be treated as observed data.

## 5. Mann–Kendall and Sen's slope

- Mann–Kendall tests for a monotonic association between time order and values without requiring normally distributed observations.
- Kendall's tau summarizes direction and strength.
- Sen's slope is the median of pairwise slopes and is robust to outliers.
- Neither automatically solves serial correlation. A serious analysis should inspect autocorrelation and consider modified Mann–Kendall methods or block-bootstrap/sensitivity approaches.

## 6. GAM

A generalized additive model (GAM) uses smooth functions instead of forcing the trend to be a straight line. This implementation fits:
- a smooth function of elapsed time;
- a cyclic smooth for month-of-year.

The cyclic smooth joins December smoothly to January. The log1p transformation reduces right skew. Inspect residuals and concurvity; the GAM is descriptive unless the model assumptions and uncertainty are assessed carefully.

## 7. Change points

PELT (Pruned Exact Linear Time) searches for segments where a statistical property, here the mean, changes. We first subtract month-specific medians to reduce recurring seasonality. The detected dates are candidate statistical breaks, not causal findings. Penalty choice and autocorrelation affect results. Sensitivity checks with other penalties and minimum segment lengths are recommended.

## 8. ARIMA / SARIMA

ARIMA models serial dependence using:
- `p`: autoregressive order;
- `d`: differencing order;
- `q`: moving-average order.

Seasonal ARIMA adds seasonal terms (`P`, `D`, `Q`) at a period such as 12 for monthly data. `auto.arima()` selects a model using information criteria within the training set. This does not guarantee the best future forecasts.

Why compare with seasonal naive? A complex model must beat a simple and credible baseline. The final months are held out in chronological order; random splitting would leak future information into training.

Current limitation: missing monthly values are interpolated/forward-filled for the demonstration. For a stronger version, examine gaps, use a model that can handle missing data or justify a carefully chosen imputation, and perform rolling-origin cross-validation.

## 9. Forecast metrics

- MAE: average absolute forecast error, easy to interpret in the data's units.
- RMSE: penalizes large errors more strongly.
- MAPE: can behave badly near zero; it is included for illustration but should not be the main metric when discharge can approach zero.

Always report the holdout period and compare all models on exactly the same observations.

## 10. Anomaly detection

The script subtracts the historical median for each calendar month and calculates a robust z-score using the median absolute deviation (MAD). A threshold of 3.5 flags unusual observations. This is a screening heuristic; high flows may be legitimate floods, and low flows may be valid drought conditions.

## 11. How to explain the project in an interview

A concise summary:

> I built a reproducible R workflow around public USGS daily discharge observations. I aggregate daily measurements to monthly and annual series, explore seasonality, estimate long-term trends with Mann–Kendall and Sen's slope, fit a GAM to separate smooth temporal behaviour from seasonal structure, screen for candidate change points, and compare SARIMA forecasts with a seasonal-naive baseline on a chronological holdout. I also document uncertainty and distinguish statistical flags from ecological causation. The next step would be to transfer the workflow to repeated eDNA/species observations and integrate environmental covariates.

Be transparent that the current dataset is hydrological rather than biodiversity data. Do not claim a result until you have run the pipeline and inspected the outputs.
