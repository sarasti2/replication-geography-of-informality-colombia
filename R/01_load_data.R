# =====================================================================
# 01_load_data.R
# Loads the INITIAL database (informalidad_municipal.csv) and sets paths.
#
# The provided database is already fully processed
# in terms of geographic, demographic and economic variables (see the
# "Data" section of the paper), and includes the DIRECT estimators of
# informality (informalidad, informalidad_adj) that come from the
# GEIH. What is missing -and is exactly what this pipeline computes- is:
#   (a) the SAE estimation (Arc-FH in step 4, MERF in step 6),
#   (b) the LISA clusters (step 7), and
#   (c) the results figures/tables (steps 8-11).
#
#
# To compare your results against the original project's, the FULL
# database (with those columns already computed) is at
# original_reference/informalidad_municipal_full_with_results.csv
#
# =====================================================================

dir <- list(
  root      = getwd(),
  data_raw  = file.path(getwd(), "data", "raw"),
  data_ext  = file.path(getwd(), "data", "external"),
  reference = file.path(getwd(), "original_reference"),
  output    = file.path(getwd(), "output"),
  estimates = file.path(getwd(), "output", "estimates"),
  figures   = file.path(getwd(), "output", "figures"),
  tables    = file.path(getwd(), "output", "tables")
)

lapply(dir[c("estimates", "figures", "tables")], function(d) dir.create(d, showWarnings = FALSE, recursive = TRUE))

base <- readr::read_delim(
  file.path(dir$data_raw, "informalidad_municipal.csv"),
  delim = ";", locale = readr::locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

# Quick check of the expected structure (input variables only;
# fharcsin_est/MERF_resultados/lisa_clusters are computed later on)
stopifnot(all(c("codigo", "anno", "informalidad", "informalidad_adj",
                 "informalidad_adj_var", "num_obser_freq_adj") %in% names(base)))

message("Initial database loaded: ", nrow(base), " rows (municipality-year), ",
        length(unique(base$codigo)), " municipalities, years: ",
        paste(sort(unique(base$anno)), collapse = ", "))
