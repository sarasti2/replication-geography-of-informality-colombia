# =====================================================================
# run_all.R  -- master script
#
# Runs the whole replication pipeline in the correct order. ALWAYS run
# with the working directory set to the root of this project
# (Replicacion_SAE_Informalidad_EN/), e.g.:
#
#   setwd("path/to/Replicacion_SAE_Informalidad_EN")
#   source("run_all.R")
#
# Steps that require external inputs not included in this package
# (municipality shapefile, 2005 estimate) are automatically skipped
# with a warning if those inputs are not present in data/external/.
# See README.md for instructions.
# =====================================================================

step <- function(msg) message("\n===== ", msg, " =====")

step("0. Packages")
source("R/00_packages.R")

step("1. Load data")
source("R/01_load_data.R")

step("2. Arc-FH function")
source("R/02_fh_arcsin_function.R")

step("3. Variable selection (BIC)")
source("R/03_variable_selection_bic.R")

step("4. Arc-FH estimation (2011, 2016, 2021)")
source("R/04_estimation_fh_arcsin.R")

step("5. Department-level benchmarking")
tryCatch(source("R/05_benchmarking.R"), error = function(e) warning(e))

step("6. MERF estimation")
tryCatch(source("R/06_estimation_merf.R"), error = function(e) warning(e))

step("7. LISA clusters (requires shapefile)")
tryCatch(source("R/07_lisa_clusters.R"), error = function(e) warning(e))

step("8. Variable importance -- Table 2")
source("R/08_variable_importance_rf.R")

step("9. Cluster stability table -- Table 1")
tryCatch(source("R/09_cluster_stability_table.R"), error = function(e) warning(e))

step("10. Maps -- Figures 1 and 3 (require shapefile)")
tryCatch(source("R/10_figures_maps.R"), error = function(e) warning(e))

step("11. Figure 2 (temporal ranking)")
source("R/11_figure_temporal_ranking.R")

step("12. MERF vs. direct by department -- Figure A2 (appendix)")
tryCatch(source("R/12_graph_difference_sae_dir.R"), error = function(e) warning(e))

message("\nDone. Check output/estimates, output/tables and output/figures.")
