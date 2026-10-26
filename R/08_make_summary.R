# 08_make_summary.R — machine-generated result summary after the pipeline runs
source("R/00_setup.R")
needed <- c("outputs/tables/data_manifest.csv", "outputs/tables/trend_results.csv",
            "outputs/tables/forecast_metrics.csv", "outputs/tables/change_points.csv")
if (!all(file.exists(needed))) stop("Run the full pipeline before generating the summary.")

manifest <- readr::read_csv(needed[1], show_col_types = FALSE)
trend <- readr::read_csv(needed[2], show_col_types = FALSE)
metrics <- readr::read_csv(needed[3], show_col_types = FALSE)
cp <- readr::read_csv(needed[4], show_col_types = FALSE)

lines <- c(
  "# Run summary",
  "",
  paste0("- Data retrieved: ", manifest$retrieved_at_utc[1]),
  paste0("- Site: ", manifest$site_id[1]),
  paste0("- Observations downloaded: ", manifest$rows_downloaded[1]),
  paste0("- Requested period: ", manifest$requested_start[1], " to ", manifest$requested_end[1]),
  "",
  "## Trend test",
  "",
  paste0("- Mann–Kendall tau: ", signif(trend$estimate[1], 4),
         "; p-value: ", signif(trend$p_value[1], 4)),
  paste0("- Sen's slope: ", signif(trend$estimate[2], 5),
         " discharge units per year; p-value: ", signif(trend$p_value[2], 4)),
  "",
  "## Forecast holdout",
  "",
  paste(capture.output(print(metrics)), collapse = "\n"),
  "",
  "## Candidate change points",
  "",
  if (nrow(cp)) paste0("- ", paste(cp$candidate_date, collapse = "\n- ")) else "- No candidate breaks selected by this run.",
  "",
  "## Caution",
  "",
  "These are hydrological results for one monitoring site, not direct biodiversity findings. Interpret trend tests with attention to autocorrelation, data completeness, and station history. Change points and anomalies are exploratory flags, not causal explanations."
)
writeLines(lines, "outputs/RUN_SUMMARY.md")
message("Wrote outputs/RUN_SUMMARY.md")
