# =====================================================================
# 06_estimation_merf.R
#
# Small area estimation via Mixed Effects Random Forest (MERF),
# following Krennmair & Schmid (2022) and the SAEforest package, as
# cited in the paper ("Limitation of the FH family models" section).
# MERF replaces the linear "synthetic" part (X*beta) of the Fay-Herriot
# model with a random forest, allowing non-linear relationships between
# informality and the covariates.
#
# NOTE: in the original code (1-Estimation_and_results.R), MERF is
# also trained directly on the aggregated municipal database
# (base_final_sin_outlayers.xlsx, the same covariate table that feeds
# the FH model) -- NOT on unit-level GEIH microdata (person/household).
# There it calls
# SAEforest_model(Y = inform_2011, X = X_covar_2011, dName = "municipio",
#                 smp_data = base_2011, pop_data = base_2011)
# with smp_data and pop_data both equal to the same municipality-year
# table, and the results are saved per year
# (2011/2016/2021_resultados_merf.dta).
#
# IMPORTANT (low-level function): SAEforest_model() is a wrapper around
# SAEforest::MERFranger(), but MERFranger() does NOT have the
# 'formula'/'dName'/'OOsample' arguments (those only exist in the
# SAEforest_model wrapper, which expects a 'smp_data'/'pop_data' object
# with domain columns). The real signature of MERFranger() is:
#   MERFranger(Y, X, random, data, importance = "none",
#              initialRandomEffects = 0, ErrorTolerance = 1e-04,
#              MaxIterations = 25, na.rm = TRUE, ...)
# where 'random' follows lme4::lmer's random-effects syntax.
#
# CRITICAL NOTE on the random-effects group: within each year, the
# database only has ONE row per municipality with a valid direct
# estimate (~436-445 out of 1103-1120), and 'codigo' (DIVIPOLA) is
# unique per row. lme4 cannot estimate a per-domain random intercept
# if the number of group levels equals the number of observations
# ("number of levels of each grouping factor must be < number of
# observations"). The original code avoids this error because it uses
# dName = "municipio" (the NAME, not the DIVIPOLA code) as the grouping
# variable, and several municipalities from different departments
# share the same name (e.g. more than one "La Union" in Colombia):
# ~12 of the ~436-445 sampled municipalities per year have a duplicate
# name, which is just barely enough for 'levels < observations' to
# hold. This looks like an accidental side effect of using the name
# instead of the unique code as the domain (it wrongly pools unrelated
# municipalities that happen to share a name), not a deliberate design
# choice -- but for the purposes of this replication, this EXACTLY
# reproduces that behavior of the original code: it groups by
# 'municipio' (name), not by 'codigo'.
#
# Requires: 00_packages.R, 01_load_data.R.
# =====================================================================

covars_merf_full <- c(
  "t_crea", "gandina", "gcaribe", "gpacifica", "gorinoquia", "gamazonia",
  "altura", "dismdo", "disbogota", "distancia_mercado",
  "va_actividad_primaria", "va_actividad_secundaria", "va_actividad_terciaria",
  "formal_rate", "pprimary", "psecondary", "pterciary",
  "ruralidad", "vacancy_rate", "pmujerpet", "salario_bas",
  "pgroup1", "pgroup2", "pgroup3", "pgroup4", "pgroup5", "pgroup6",
  "areakm2", "pregimen_subsidiado",
  "promleccri", "promglobal", "prommatema"
)
covars_merf_full <- covars_merf_full[covars_merf_full %in% names(base)]

merf_by_year <- list()
merf_models_by_year <- list()

if (requireNamespace("SAEforest", quietly = TRUE)) {

  for (yr in c(2011, 2016, 2021)) {

    # Same year-specific covariate drops as the original code
    covars_yr <- covars_merf_full
    if (yr %in% c(2011, 2016)) {
      covars_yr <- setdiff(covars_yr, c("promleccri", "promglobal", "prommatema"))
    }
    if (yr == 2011) {
      covars_yr <- setdiff(covars_yr, "vacancy_rate")
    }

    dyr <- base[base$anno == yr, c("codigo", "municipio", "informalidad_adj", covars_yr)]
    dyr <- dyr[stats::complete.cases(dyr), ]
    # Random-effects group = municipality NAME, same as the original
    # code (dName = "municipio"); see the note above.
    dyr$municipio <- factor(dyr$municipio)

    model_yr <- tryCatch(
      SAEforest::MERFranger(
        Y        = dyr$informalidad_adj,
        X        = dyr[, covars_yr],
        random   = "(1 | municipio)",
        data     = dyr,
        importance = "impurity"
      ),
      error = function(e) {
        warning("SAEforest::MERFranger failed for year ", yr, ": ",
                conditionMessage(e), ". Check the package version / specification.")
        NULL
      }
    )

    if (!is.null(model_yr)) {
      pred_yr <- as.numeric(stats::predict(model_yr, dyr))
      merf_by_year[[as.character(yr)]] <- data.frame(
        codigo = as.character(dyr$codigo),
        anno   = yr,
        MERF_resultados_repro = pmin(pmax(pred_yr, 0), 100)
      )
      # The fitted model itself is kept (not just the predictions):
      # Table 2 (08_variable_importance_rf.R) directly reuses the
      # variable importance from this MERF model's forest, matching
      # the original code (model$MERFmodel$Forest$variable.importance).
      merf_models_by_year[[as.character(yr)]] <- model_yr
      message("MERF ", yr, ": model fit with ", length(covars_yr),
              " covariates over ", nrow(dyr), " municipalities (",
              length(unique(dyr$municipio)), " unique municipality names).")
    }
  }

} else {
  warning("SAEforest package not available: 06_estimation_merf.R is skipped. ",
          "Install with devtools::install_github('krennpa/SAEforest') (see 00_packages.R).")
}

if (length(merf_models_by_year) > 0) {
  saveRDS(merf_models_by_year, file.path(dir$estimates, "merf_models_by_year.rds"))
}

merf_resultados <- NULL
if (length(merf_by_year) > 0) {
  merf_resultados <- do.call(rbind, merf_by_year)
  merf_resultados$codigo <- as.numeric(merf_resultados$codigo)
}

if (!is.null(merf_resultados)) {
  readr::write_csv(merf_resultados, file.path(dir$estimates, "merf_resultados.csv"))

  # --- add the computed column to 'base' for the following steps ---
  base <- dplyr::left_join(base, merf_resultados, by = c("codigo", "anno"))
  base$MERF_resultados <- base$MERF_resultados_repro

  # --- optional check against the original database (with results already computed) ---
  ref_path <- file.path(dir$reference, "informalidad_municipal_full_with_results.csv")
  if (file.exists(ref_path)) {
    reference <- readr::read_delim(ref_path, delim = ";", show_col_types = FALSE)
    merf_check <- merge(merf_resultados, reference[, c("codigo", "anno", "MERF_resultados")],
                         by = c("codigo", "anno"))
    merf_check <- merf_check[stats::complete.cases(merf_check), ]
    if (nrow(merf_check) > 10) {
      message("Correlation reproduced MERF vs. original database (original_reference/): ",
              round(stats::cor(merf_check$MERF_resultados_repro, merf_check$MERF_resultados), 3))
    }
  } else {
    message("File '", ref_path, "' not found: skipping the comparison against the original database.")
  }
}
