# =====================================================================
# 03_variable_selection_bic.R
#
# Covariate selection for the Arc-FH model, following Section 5.6
# "Pre-selection of auxiliary variables" of the paper:
#   1) restrict the sample to the 50% of municipalities with the
#      largest sample size (to reduce noise in variable selection);
#   2) regress nu = asin(sqrt(informalidad_adj/100)) on the candidate
#      covariates;
#   3) stepwise selection using BIC (k = log(n)).
#
# Run independently for each year (2011, 2016, 2021).
# Note: 'vacancy_rate' is not available for 2011 (see Section 5.5 of
# the paper) and is automatically excluded for that year.
# =====================================================================

# Universe of candidate covariates present in the processed database.
# Adjust this vector if the final database includes more/fewer variables.
covars_candidatas <- c(
  "pregimen_subsidiado", "formal_rate", "vacancy_rate",
  "psecondary", "pterciary", "pprimary",
  "salario_bas", "vabpc",
  "disbogota", "dismdo", "distancia_mercado",
  "pruralpet", "pmujerpet", "pdependiente", "ruralidad",
  "t_crea", "altura", "areakm2",
  "gandina", "gcaribe", "gpacifica", "gorinoquia", "gamazonia"
)

select_vars_bic <- function(data_year, covars = covars_candidatas) {

  covars <- covars[covars %in% names(data_year)]
  # variables with no variation or entirely NA are excluded
  covars <- covars[sapply(data_year[covars], function(x) {
    !all(is.na(x)) && stats::sd(x, na.rm = TRUE) > 0
  })]

  # 1) restrict to the 50% with the largest sample size, among the SAMPLED areas
  sampled <- data_year[!is.na(data_year$informalidad_adj), ]
  n_keep <- ceiling(nrow(sampled) / 2)
  sampled <- sampled[order(-sampled$num_obser_freq_adj), ][seq_len(n_keep), ]

  # 2) transformed dependent variable
  sampled$nu <- asin(sqrt(pmin(pmax(sampled$informalidad_adj, 0), 100) / 100))

  form_full <- stats::as.formula(paste("nu ~", paste(covars, collapse = " + ")))
  dat_reg <- sampled[, c("nu", covars)]
  dat_reg <- dat_reg[stats::complete.cases(dat_reg), ]

  fit_null <- stats::lm(nu ~ 1, data = dat_reg)
  fit_full <- stats::lm(form_full, data = dat_reg)

  # 3) bidirectional stepwise selection with BIC penalty (k = log(n))
  fit_bic <- stats::step(
    fit_null,
    scope = list(lower = fit_null, upper = fit_full),
    direction = "both",
    k = log(nrow(dat_reg)),
    trace = 0
  )

  list(
    selected = setdiff(names(stats::coef(fit_bic)), "(Intercept)"),
    model    = fit_bic,
    r2       = summary(fit_bic)$r.squared,
    n_used   = nrow(dat_reg)
  )
}
