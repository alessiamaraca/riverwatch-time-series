# RiverWatch: Reproducible Time-Series Analysis of USGS River Discharge

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

## Interpretation cautions

- A detected trend is not automatically an ecological impact.
- Monthly and annual averages can hide extremes; daily discharge has a skewed distribution.
- Trend tests can be sensitive to autocorrelation. The report includes this limitation and encourages sensitivity checks.
- Change points are candidate statistical breaks, not proof of a specific event or cause.
- Forecast performance is evaluated out of sample. Do not select a model based only on in-sample fit.
- This is hydrological time-series practice. To make the next version directly biodiversity-focused, repeat the workflow on a suitable repeated-sampling eDNA/species dataset and include sampling effort and detection limitations.

## Suggested GitHub description

> Reproducible R workflow for USGS river-discharge time series: seasonality, trend estimation, change-point screening, anomaly detection, and SARIMA forecasting against a baseline.

## Suggested next steps

1. Run the pipeline and inspect every figure and result.
2. Read `notes/UNDER_THE_HOOD.md` before presenting any conclusion.
3. Replace this README's placeholder summary with the actual results produced by your run.
4. Add a biodiversity/eDNA dataset only after confirming that it has repeated observations over enough dates and that the sampling design is understood.
