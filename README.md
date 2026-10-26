# RiverWatch: Reproducible Time-Series Analysis of USGS River Discharge

[![R project checks](https://github.com/alessiamaraca/riverwatch-time-series/actions/workflows/r-check.yml/badge.svg)](https://github.com/alessiamaraca/riverwatch-time-series/actions/workflows/r-check.yml)

**A portfolio project in R covering ecological time-series methods, trend detection, change points, anomaly screening, and forecasting.**

> **Scope note:** This first version analyses river discharge, not biodiversity. Discharge is an important hydrological variable, but it is not a direct measure of species richness or ecological condition. The workflow is designed to be reusable later with a real biodiversity/eDNA time series.

## Research questions

1. What seasonal pattern is visible in mean monthly river discharge?
2. Is there evidence of a long-term trend in annual mean discharge?
3. Are there candidate shifts in seasonally adjusted monthly discharge?
4. Can a seasonal ARIMA model forecast monthly discharge better than a seasonal-naive baseline?
5. Which months look unusual relative to a smooth trend and seasonal pattern?

## Public data

- **Provider:** U.S. Geological Survey (USGS)
- **Site:** Choptank River near Greensboro, Maryland
- **USGS monitoring location ID:** `USGS-01491000`
- **Parameter:** mean daily discharge (`00060`, statistic `00003`)
- **Units:** USGS-reported discharge units; typically cubic feet per second (`ft^3/s`)
- **Access:** modern USGS Water Data API through the USGS-maintained R package `dataRetrieval`
- **API documentation:** https://api.waterdata.usgs.gov/
- **R package documentation:** https://doi-usgs.github.io/dataRetrieval/

The script downloads the latest available record when you run it. The exact date range, retrieval timestamp, and row counts are written to `outputs/tables/data_manifest.csv`.

## Quick start

1. Install R (4.3 or later recommended) and RStudio.
2. Open this folder as an RStudio project, or set it as your working directory.
3. Run:

```r
source("R/00_setup.R")
source("R/01_download_data.R")
source("R/02_prepare_data.R")
source("R/03_exploration.R")
source("R/04_trend_analysis.R")
source("R/05_change_points.R")
source("R/06_forecasting.R")
source("R/07_anomalies.R")
source("R/08_make_summary.R")
```

Or run the entire pipeline:

```r
source("run_all.R")
```

The first run requires internet access to the public USGS API and may install missing R packages. No API key should be needed for this modest, single-site request, although USGS rate limits and service availability can change.

## Main outputs

- `outputs/figures/01_daily_discharge.png`
- `outputs/figures/02_monthly_seasonality.png`
- `outputs/figures/03_annual_trend.png`
- `outputs/figures/04_gam_trend_seasonality.png`
- `outputs/figures/05_change_points.png`
- `outputs/figures/06_forecast_holdout.png`
- `outputs/figures/07_anomalies.png`
- `outputs/tables/trend_results.csv`
- `outputs/tables/change_points.csv`
- `outputs/tables/forecast_metrics.csv`
- `outputs/tables/anomalies.csv`
- `outputs/tables/data_manifest.csv`
- `report/analysis_report.html` (after rendering the Quarto report)

## Methods

- Data-quality checks and monthly/annual aggregation
- Exploratory time-series plots
- Seasonal summaries and STL decomposition
- Mann–Kendall trend test and Sen's slope on annual means
- Generalized additive model (GAM) for smooth long-term trend plus cyclic seasonality
- PELT change-point screening on seasonally adjusted anomalies
- Seasonal ARIMA forecast compared with seasonal-naive baseline using a chronological holdout
- Robust anomaly screening using median absolute deviation
  
## Results from the October 2026 analysis

The workflow was successfully executed using publicly available daily discharge observations from USGS monitoring site `01491000` (Choptank River near Greensboro, Maryland).

**Data coverage:** 28,788 daily observations were retrieved for the period January 1, 1948, to October 26, 2026. The final year is incomplete and should be interpreted accordingly.

### Seasonal patterns

River discharge exhibits pronounced seasonality, with generally higher monthly discharge in late winter and early spring and lower discharge during late summer and early autumn. Daily observations also show substantial variability and occasional high-flow events.

### Long-term trend

The Mann–Kendall test on annual mean discharge produced a positive but statistically non-significant trend at the 5% significance level:

- Mann–Kendall tau: **0.1282**
- p-value: **0.09533**
- Sen's slope: **+0.45115 discharge units per year**

These results suggest a weak positive tendency, but do not provide sufficient evidence to conclude that a statistically significant monotonic trend exists at the conventional 5% threshold.

### Change-point screening

The PELT-based screening procedure did not select any candidate change points in the seasonally adjusted monthly series under the settings used. This does not rule out gradual changes or shifts detectable using alternative methods.

### Forecast evaluation

A seasonal ARIMA model was evaluated against a seasonal-naive baseline using a chronological holdout period.

| Model | MAE | RMSE | MAPE |
|---|---:|---:|---:|
| Seasonal-naive baseline | 145.0 | 225.0 | 368% |
| Auto ARIMA/SARIMA | 70.5 | 81.2 | 249% |

The ARIMA/SARIMA model achieved lower prediction errors than the baseline, although forecast accuracy remained limited during periods of strong discharge variability. Percentage-based errors should be interpreted cautiously when observed discharge is close to zero.

### Anomaly screening

Robust anomaly screening highlighted a small number of unusual monthly observations relative to the estimated seasonal and long-term patterns. These observations are statistical flags requiring further investigation, not confirmed flood events or evidence of particular environmental causes.

### Scientific scope

This analysis demonstrates reproducible hydrological time-series methods using one USGS monitoring location. The findings should not be interpreted as direct evidence of biodiversity change, ecological degradation, or climate-change causation. Further analyses would require appropriate environmental covariates, station-history checks, and biodiversity observations.

## Selected visualizations

### Monthly seasonality

![Monthly seasonality](outputs/figures/02_monthly_seasonality.png)

### Annual discharge trend

![Annual discharge trend](outputs/figures/03_annual_trend.png)

### Forecast evaluation

![Forecast comparison](outputs/figures/06_forecast_holdout.png)

## Interpretation cautions

- A detected trend is not automatically an ecological impact.
- Monthly and annual averages can hide extremes; daily discharge has a skewed distribution.
- Trend tests can be sensitive to autocorrelation. The report includes this limitation and encourages sensitivity checks.
- Change points are candidate statistical breaks, not proof of a specific event or cause.
- Forecast performance is evaluated out of sample. Do not select a model based only on in-sample fit.
- This is hydrological time-series practice. To make the next version directly biodiversity-focused, repeat the workflow on a suitable repeated-sampling eDNA/species dataset and include sampling effort and detection limitations.
