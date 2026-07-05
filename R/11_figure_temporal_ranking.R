# =====================================================================
# 11_figure_temporal_ranking.R
#
# Paper's Figure 2: changes in municipal informality 2005-2021, ranking
# municipalities by their 2021 informality level and fitting a local
# polynomial (loess) per year, with 95% confidence bands.
#
# =====================================================================

fig2_data <- base[, c("codigo", "anno", "fharcsin_est")]

census2005_path <- file.path(dir$data_ext, "census2005", "informalidad_2005.csv")
if (file.exists(census2005_path)) {
  census05 <- readr::read_csv(census2005_path, show_col_types = FALSE)
  fig2_data <- rbind(fig2_data, data.frame(codigo = census05$codigo, anno = 2005,
                                            fharcsin_est = census05$informalidad_2005))
} else {
  message("Note: Figure 2 is generated ONLY for 2011/2016/2021 (the 2005 input was not found).")
}

ranking_2021 <- base[base$anno == 2021, c("codigo", "fharcsin_est")]
ranking_2021 <- ranking_2021[order(ranking_2021$fharcsin_est), ]
ranking_2021$rank <- seq_len(nrow(ranking_2021))

fig2_data <- merge(fig2_data, ranking_2021[, c("codigo", "rank")], by = "codigo")
fig2_data <- fig2_data[!is.na(fig2_data$fharcsin_est), ]
fig2_data$anno <- factor(fig2_data$anno)

fig2 <- ggplot2::ggplot(fig2_data, ggplot2::aes(x = rank, y = fharcsin_est, color = anno, fill = anno)) +
  ggplot2::geom_smooth(method = "loess", se = TRUE, alpha = 0.15) +
  ggplot2::labs(
    x = "Municipal ranking (ordered by 2021 informality)",
    y = "Estimated informality (%)",
    color = "Year", fill = "Year",
    title = "Changes in municipal labor informality"
  ) +
  ggplot2::theme_minimal()

ggplot2::ggsave(file.path(dir$figures, "figure2_temporal_change_ranking.jpg"),
                 fig2, width = 8, height = 5.5, dpi = 300)

message("Figure 2 saved to output/figures/figure2_temporal_change_ranking.jpg")
