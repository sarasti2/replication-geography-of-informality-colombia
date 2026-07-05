# =====================================================================
# 12_graph_difference_sae_dir.R
#
# Compares, at the department level, the Random Forest SAE estimate
# (MERF, computed in script 06) against the direct GEIH estimator. This
# is the equivalent of the original script
# 'Dropbox/SAE_informalidad/codigo/12-graph_difference_sae_dir.r' and
# of Figure A2 in the paper's appendix ("we compared aggregated SAE
# results with direct estimates at the department level").
#
# This is the result in the paper where MERF (not Arc-FH) is explicitly
# used as the comparison SAE estimator.
#
# Requires: 01_load_data.R and 06_estimation_merf.R already run
# (MERF_resultados must exist in 'base').
# =====================================================================

if (!"MERF_resultados" %in% names(base)) {

  warning("'MERF_resultados' is not in 'base' (run 06_estimation_merf.R first). ",
          "Skipping 12_graph_difference_sae_dir.R.")

} else {

  # --- population-weighted department average ---
  dpt_direct <- base %>%
    dplyr::filter(!is.na(informalidad_adj)) %>%
    dplyr::group_by(codigo_depto, departamento, anno) %>%
    dplyr::summarise(direct_dpto = stats::weighted.mean(informalidad_adj, w = pob_total, na.rm = TRUE),
                      .groups = "drop")

  dpt_merf <- base %>%
    dplyr::filter(!is.na(MERF_resultados)) %>%
    dplyr::group_by(codigo_depto, departamento, anno) %>%
    dplyr::summarise(merf_dpto = stats::weighted.mean(MERF_resultados, w = pob_total, na.rm = TRUE),
                      .groups = "drop")

  dpto_comparison <- dplyr::inner_join(dpt_direct, dpt_merf, by = c("codigo_depto", "departamento", "anno"))

  readr::write_csv(dpto_comparison, file.path(dir$estimates, "dpto_direct_vs_merf_comparison.csv"))

  for (yr in c(2011, 2016, 2021)) {

    dat_yr <- dpto_comparison[dpto_comparison$anno == yr, ]
    if (nrow(dat_yr) == 0) next

    dat_long <- tidyr::pivot_longer(dat_yr, cols = c("direct_dpto", "merf_dpto"),
                                     names_to = "estimator", values_to = "informality")
    dat_long$estimator <- factor(dat_long$estimator,
                                  levels = c("direct_dpto", "merf_dpto"),
                                  labels = c("Direct (GEIH)", "SAE - MERF"))

    dept_order <- dat_yr$departamento[order(dat_yr$direct_dpto)]
    dat_long$departamento <- factor(dat_long$departamento, levels = dept_order)

    fig <- ggplot2::ggplot(dat_long, ggplot2::aes(x = departamento, y = informality,
                                                    color = estimator, shape = estimator)) +
      ggplot2::geom_point(size = 2.4) +
      ggplot2::coord_flip() +
      ggplot2::labs(title = paste0(yr, ": direct vs. SAE (MERF) informality, by department"),
                    x = NULL, y = "Informality (%)", color = NULL, shape = NULL) +
      ggplot2::theme_minimal()

    ggplot2::ggsave(file.path(dir$figures, paste0(yr, "dpt_direct_vs_merf.png")),
                     fig, width = 7, height = 8, dpi = 300)
  }

  message("Direct vs. MERF department-level comparison saved to output/estimates/ and output/figures/.")
}
