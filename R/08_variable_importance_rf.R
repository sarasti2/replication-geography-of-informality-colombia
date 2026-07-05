# =====================================================================
# 08_variable_importance_rf.R
#
# Paper's Table 2: relevance of auxiliary variables for estimating
# municipal informality.
#
# IMPORTANT NOTE (corrected methodology): in the original code
# (1-Estimation_and_results.R, section "3.2 Graficas de importancia de
# las variables"), Table 2 is NOT computed with a fresh randomForest
# trained on fharcsin_est -- it is extracted DIRECTLY from the MERF
# models already fit in section 2 of the original script:
#   feature_importance <- as.numeric(model$MERFmodel$Forest$variable.importance)
#   feature_names <- attr(model$MERFmodel$Forest$variable.importance, "names")
# for model2011, model2016 and model2021 (the same objects used to
# generate 'MERF_resultados').
#
# This is replicated exactly here: the MERF models fit by
# 06_estimation_merf.R are reused (object 'merf_models_by_year',
# available in the same run_all.R session, or loaded from
# output/estimates/merf_models_by_year.rds if this script is run on
# its own). The importance measure used is "impurity" (the same one
# the models were fit with in step 6).
# =====================================================================

if (!exists("merf_models_by_year") || length(merf_models_by_year) == 0) {
  rds_path <- file.path(dir$estimates, "merf_models_by_year.rds")
  if (file.exists(rds_path)) {
    merf_models_by_year <- readRDS(rds_path)
    message("MERF models loaded from ", rds_path)
  } else {
    stop("No MERF models available ('merf_models_by_year'). ",
         "Run 06_estimation_merf.R first (same session, or saving the .rds).")
  }
}

table2_importance <- list()

for (yr in c(2011, 2016, 2021)) {
  yr_chr <- as.character(yr)

  if (is.null(merf_models_by_year[[yr_chr]])) {
    warning("No fitted MERF model for year ", yr, "; skipping it from Table 2.")
    next
  }

  model_yr <- merf_models_by_year[[yr_chr]]
  imp <- model_yr$Forest$variable.importance

  if (is.null(imp)) {
    warning("The MERF model for ", yr, " has no 'variable.importance' ",
            "(check that 06_estimation_merf.R used importance = 'impurity').")
    next
  }

  imp_df <- data.frame(
    anno = yr,
    variable = names(imp),
    importance = as.numeric(imp)
  )
  imp_df <- imp_df[order(-imp_df$importance), ]
  imp_df$ranking <- seq_len(nrow(imp_df))
  table2_importance[[yr_chr]] <- utils::head(imp_df, 10)
}

table2_importance <- do.call(rbind, table2_importance)
readr::write_csv(table2_importance, file.path(dir$tables, "table2_variable_importance.csv"))
message("Table 2 (variable importance, from the MERF models) saved to output/tables/.")
print(table2_importance)
