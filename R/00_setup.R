# 00_setup.R — packages, folders, reproducibility helpers

required <- c(
  "dataRetrieval", "dplyr", "tidyr", "readr", "lubridate", "ggplot2",
  "forecast", "Kendall", "trend", "mgcv", "changepoint", "broom",
  "scales", "zoo", "testthat"
)
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}
invisible(lapply(required, library, character.only = TRUE))

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

theme_set(theme_minimal(base_size = 12))

SITE_ID <- "USGS-01491000"
PARAMETER_CODE <- "00060"  # Discharge
STATISTIC_ID <- "00003"    # Mean
START_DATE <- "1948-01-01"
END_DATE <- Sys.Date()

save_plot <- function(plot, filename, width = 10, height = 6) {
  ggsave(
    filename = file.path("outputs", "figures", filename),
    plot = plot, width = width, height = height, dpi = 160,
    bg = "white"
  )
}

message("Setup complete. USGS site: ", SITE_ID)
