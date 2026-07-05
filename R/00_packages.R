# =====================================================================
# 00_packages.R
# Installs (if needed) and loads the packages used across the pipeline.
# =====================================================================

required_packages <- c(
  "dplyr", "tidyr", "readr", "stringr", "forcats",   # data handling
  "ggplot2", "scales",                                # plots
  "randomForest",                                     # Table 2 (variable importance)
  "SAEforest",                                         # MERF (step 6)
  "spdep", "sf",                                       # LISA and maps (steps 7 and 10, require a shapefile)
  "broom",
  "BAMMtools",                                         # Jenks breaks for Figure 1 (matching 9.all_maps.R)
  "ggpubr"                                             # ggarrange() to compose maps with a shared legend
)

# SAEforest is installed from GitHub (not always available on CRAN with
# the version/MERFranger() function this pipeline uses).
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools", repos = "https://cloud.r-project.org")
}
if (!requireNamespace("SAEforest", quietly = TRUE)) {
  message("Installing SAEforest from GitHub (krennpa/SAEforest)...")
  devtools::install_github("krennpa/SAEforest")
}

# The rest of the packages install normally from CRAN (SAEforest is
# excluded from this step since it is already handled above via GitHub).
installed <- rownames(installed.packages())
to_install <- setdiff(required_packages, c(installed, "SAEforest"))

if (length(to_install) > 0) {
  message("Installing missing packages: ", paste(to_install, collapse = ", "))
  install.packages(to_install, repos = "https://cloud.r-project.org")
}

invisible(lapply(required_packages, function(p) {
  ok <- suppressWarnings(suppressMessages(require(p, character.only = TRUE)))
  if (!ok) warning("Could not load package: ", p,
                    " (check the installation; steps requiring it will be skipped).")
}))
