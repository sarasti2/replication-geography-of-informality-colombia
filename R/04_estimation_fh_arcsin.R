# =====================================================================
# 04_estimation_fh_arcsin.R
#
# Runs the Arc-FH model (script 02) for 2011, 2016 and 2021, using the
# BIC-selected covariates (script 03) for each year. Produces
# 'fharcsin_est', 'Low' and 'Up' -- columns the INITIAL database no
# longer includes (removed on purpose, see 01_load_data.R) and that
# this script actually adds to 'base' so the following steps (6-11)
# can use them.
#
# Requires: 00_packages.R, 01_load_data.R, 02_fh_arcsin_function.R,
#           03_variable_selection_bic.R already run (see run_all.R).
# =====================================================================

years <- c(2011, 2016, 2021)
fh_results <- list()
fh_selection <- list()

for (yr in years) {

  message("== Arc-FH ", yr, " ==")
  dyr <- base[base$anno == yr, ]

  sel <- select_vars_bic(dyr)
  fh_selection[[as.character(yr)]] <- sel
  message("  Selected variables (BIC): ", paste(sel$selected, collapse = ", "),
          "  | R2 = ", round(sel$r2, 3), " | n = ", sel$n_used)

  covars_yr <- sel$selected
  X <- as.matrix(cbind(Intercept = 1, dyr[, covars_yr]))

  fh_out <- FH_arcsin(
    direct_pct = dyr$informalidad_adj,
    eff_n      = dyr$num_obser_freq_adj,
    X          = X,
    B          = 200
  )

  out <- data.frame(
    codigo = dyr$codigo,
    anno   = yr,
    fharcsin_est_repro = fh_out$area_est,
    Low_repro  = fh_out$Low,
    Up_repro   = fh_out$Up,
    gamma      = fh_out$gamma,
    sampled    = fh_out$is_sampled
  )
  fh_results[[as.character(yr)]] <- out
}

fh_arcsin_resultados <- do.call(rbind, fh_results)

# --- add the computed columns to 'base' for the following steps ---
base <- dplyr::left_join(
  base,
  fh_arcsin_resultados[, c("codigo", "anno", "fharcsin_est_repro", "Low_repro", "Up_repro")],
  by = c("codigo", "anno")
)
base$fharcsin_est <- base$fharcsin_est_repro
base$Low <- base$Low_repro
base$Up  <- base$Up_repro

# --- optional check against the original database (with results already computed) ---
ref_path <- file.path(dir$reference, "informalidad_municipal_full_with_results.csv")
if (file.exists(ref_path)) {
  reference <- readr::read_delim(ref_path, delim = ";", show_col_types = FALSE)
  check <- merge(fh_arcsin_resultados, reference[, c("codigo", "anno", "fharcsin_est")],
                 by = c("codigo", "anno"))
  check <- check[stats::complete.cases(check[, c("fharcsin_est_repro", "fharcsin_est")]), ]
  correlation <- stats::cor(check$fharcsin_est_repro, check$fharcsin_est)
  mae <- mean(abs(check$fharcsin_est_repro - check$fharcsin_est))
  message("Correlation reproduction vs. original database (original_reference/): ", round(correlation, 3),
          " | MAE = ", round(mae, 2), " pp")
} else {
  message("File '", ref_path, "' not found: skipping the comparison against the original database.")
}

readr::write_csv(fh_arcsin_resultados, file.path(dir$estimates, "fh_arcsin_resultados.csv"))
saveRDS(fh_selection, file.path(dir$estimates, "fh_arcsin_variable_selection.rds"))
