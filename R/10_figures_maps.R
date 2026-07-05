# =====================================================================
# 10_figures_maps.R
#
# Figure 1: municipal informality maps for 2005/2011/2016/2021.
# Figure 3: LISA cluster maps for 2005/2011/2016/2021.
#
# STYLE: replicates the original scripts 9.all_maps.R (Figure 1:
# hcl.colors(5,"RdYlBu",rev=TRUE,alpha=0.7) palette, Jenks breaks per
# year via BAMMtools::getJenksBreaks(), department outline overlay,
# theme_void(), shared bottom legend via ggpubr::ggarrange) and
# 10.clusters_lisa.R block "(B) Kari" (Figure 3: colors
# HH=#FF0000/LL=#0000FF/LH=#a7adf9/HL=#f4ada8/NS=#eeeeee, includes year
# 2005, also composed with ggarrange and a shared legend). tmap/rgeoda
# are not used (not available) but the same colors and final
# composition are targeted.
#
# NOTE on Figure 1's labels (fidelity with an original inconsistency):
# 9.all_maps.R computes Jenks breaks PER YEAR (each panel is colored
# with its own breaks), but the shared legend across the 4 panels is
# labeled using the breaks of a SINGLE year (2005, or the first one
# available), forcing the first break to 0 and the first label to
# "< 55%". This means the legend labels don't exactly describe every
# individual panel's breaks -- a minor inconsistency that already
# existed in the original code and is reproduced as-is here.
#
# CRITICAL NOTE -- BALANCED PANEL (blank municipalities the same across
# every year, so maps are comparable): the original code (9.all_maps.R)
# forces a municipality to NA in ALL years if it is missing the
# estimate in ANY of them (the author's own comment: "this is done so
# all years have the same NAs"). This is reproduced the same way here:
# municipalities with a valid estimate in EVERY year of the map are
# identified, and everything else is left blank (NA) in ALL panels, not
# just the year where it's missing. Figure 3 inherits the same balanced
# panel because it uses the already-balanced results from
# 07_lisa_clusters.R.
#
# *** REQUIRES ***
#  (a) the municipality shapefile used in 07_lisa_clusters.R
#      (data/external/shapefiles/MGN_MPIO/),
#  (b) the department shapefile (data/external/shapefiles/MGN_DPTO/),
#      used only to draw the department outline (optional: if missing,
#      maps are generated without that outline), and
#  (c) for the 2005 panel, the direct Census informality estimate
#      (data/external/census2005/informalidad_2005.csv).
#
# Without (a), this script generates nothing. Without (b) or (c) it
# generates what CAN be produced with the available data and warns
# about what is missing.
# =====================================================================

shp_path <- file.path(dir$data_ext, "shapefiles", "MGN_MPIO")
dpto_path <- file.path(dir$data_ext, "shapefiles", "MGN_DPTO")
census2005_path <- file.path(dir$data_ext, "census2005", "informalidad_2005.csv")

if (!dir.exists(shp_path) || length(list.files(shp_path, pattern = "\\.shp$")) == 0) {

  warning("No shapefile found in '", shp_path, "': skipping the maps (Figures 1 and 3). ",
          "See instructions in 07_lisa_clusters.R.")

} else if (!requireNamespace("BAMMtools", quietly = TRUE) || !requireNamespace("ggpubr", quietly = TRUE)) {

  warning("Packages 'BAMMtools' and 'ggpubr' (see 00_packages.R) are required to reproduce ",
          "the original style of Figures 1 and 3; skipping both.")

} else {

  mpios <- sf::st_read(shp_path, quiet = TRUE)
  code_col <- intersect(c("MPIO_CDPMP", "DIVIPOLA", "codigo", "COD_MPIO"), names(mpios))[1]
  mpios$codigo <- as.character(mpios[[code_col]])

  # Department outline (drawn on top only; optional)
  if (dir.exists(dpto_path) && length(list.files(dpto_path, pattern = "\\.shp$")) > 0) {
    shape_dpto <- sf::st_read(dpto_path, quiet = TRUE)
    dpto_col <- intersect(c("DPTO_CCDGO"), names(shape_dpto))[1]
    if (!is.na(dpto_col)) {
      # exclude San Andres and Providencia from the outline, same as the original
      shape_dpto <- shape_dpto[shape_dpto[[dpto_col]] != "88", ]
    }
  } else {
    warning("Department shapefile not found at '", dpto_path, "': ",
            "maps are generated without the department outline.")
    shape_dpto <- NULL
  }

  add_dpto_outline <- function(g) {
    if (!is.null(shape_dpto)) g <- g + ggplot2::geom_sf(data = shape_dpto, fill = NA, color = "black", linewidth = 0.15, alpha = 0)
    g
  }

  # =====================================================================
  # Figure 1: informality map by year
  # =====================================================================

  map_data <- base[, c("codigo", "anno", "fharcsin_est")]
  map_data$codigo <- sprintf("%05d", as.numeric(map_data$codigo))

  has_2005 <- file.exists(census2005_path)
  if (has_2005) {
    census05 <- readr::read_csv(census2005_path, show_col_types = FALSE)
    census05 <- data.frame(codigo = sprintf("%05d", as.numeric(census05$codigo)), anno = 2005,
                            fharcsin_est = census05$informalidad_2005)
    map_data <- rbind(map_data, census05)
  } else {
    warning("File '", census2005_path, "' not found: Figure 1 is generated ONLY for ",
            "2011/2016/2021 (without the 2005 panel).")
  }

  map_years <- if (has_2005) c(2005, 2011, 2016, 2021) else c(2011, 2016, 2021)

  # --- balanced panel: a municipality missing the estimate in ANY year
  # is left blank (NA) in ALL years, so maps are comparable to each
  # other -- same as 9.all_maps.R. See the critical note above.
  wide_map <- tidyr::pivot_wider(map_data, id_cols = "codigo", names_from = "anno",
                                  values_from = "fharcsin_est", names_prefix = "year_")
  year_cols_map <- paste0("year_", map_years)
  year_cols_map <- year_cols_map[year_cols_map %in% names(wide_map)]
  balanced_codes_map <- wide_map$codigo[stats::complete.cases(wide_map[, year_cols_map])]
  map_data$fharcsin_est[!(map_data$codigo %in% balanced_codes_map)] <- NA
  message("Figure 1 balanced panel: ", length(balanced_codes_map),
          " municipalities with a valid estimate across the ", length(year_cols_map), " years shown.")

  geo_map <- merge(mpios, map_data, by = "codigo")

  # Palette identical to 9.all_maps.R
  informality_palette <- grDevices::hcl.colors(5, "RdYlBu", rev = TRUE, alpha = 0.7)

  # Jenks breaks per year (5 classes via 6 breakpoints), same as the original
  breaks_by_year <- lapply(map_years, function(yr) {
    vals <- geo_map$fharcsin_est[geo_map$anno == yr]
    BAMMtools::getJenksBreaks(vals, 6)
  })
  names(breaks_by_year) <- as.character(map_years)

  # Shared legend labels: derived from the breaks of the first available
  # year (2005 if present), with the first label forced to "< 55%",
  # same as 9.all_maps.R (breaks_time2 / labs_time_plot[1]).
  legend_breaks <- round(breaks_by_year[[as.character(map_years[1])]], 2)
  legend_labels <- paste0("(", legend_breaks[1:5], "%-", legend_breaks[2:6], "%]")
  legend_labels[1] <- "< 55%"

  make_informality_map <- function(yr) {
    breaks_yr <- breaks_by_year[[as.character(yr)]]
    breaks_yr[1] <- 0  # same as 9.all_maps.R (breaks_time2005[1] <- 0, etc.)
    d <- geo_map[geo_map$anno == yr, ]
    d$class <- cut(d$fharcsin_est, breaks = breaks_yr, dig.lab = 5, include.lowest = TRUE)
    g <- ggplot2::ggplot() +
      ggplot2::geom_sf(data = d, ggplot2::aes(fill = class), color = NA) +
      ggplot2::scale_fill_manual(values = informality_palette, drop = FALSE,
                                  na.value = "darkgray", labels = legend_labels, name = "") +
      ggplot2::labs(title = as.character(yr)) +
      ggplot2::theme_void() +
      ggplot2::theme(legend.position = "bottom",
                      legend.text = ggplot2::element_text(size = 10),
                      plot.title = ggplot2::element_text(size = 16, hjust = 0.5))
    add_dpto_outline(g)
  }

  informality_maps <- lapply(map_years, make_informality_map)

  fig1 <- ggpubr::ggarrange(
    plotlist = informality_maps, common.legend = TRUE, legend = "bottom",
    nrow = if (length(map_years) <= 2) 1 else 2,
    ncol = if (length(map_years) <= 2) length(map_years) else 2
  )

  ggplot2::ggsave(file.path(dir$figures, "figure1_informality_map.jpg"),
                   fig1, width = 9, height = if (length(map_years) > 2) 8 else 5, dpi = 300, bg = "white")

  message("Figure 1 saved to output/figures/ (palette and Jenks breaks matching the original code, balanced panel).")

  # =====================================================================
  # Figure 3: LISA cluster maps (includes 2005, balanced panel)
  # =====================================================================

  lisa_csv <- file.path(dir$estimates, "lisa_resultados.csv")
  lisa_results <- if (exists("lisa_resultados") && is.data.frame(lisa_resultados)) {
    lisa_resultados
  } else if (file.exists(lisa_csv)) {
    readr::read_csv(lisa_csv, show_col_types = FALSE)
  } else {
    NULL
  }

  if (is.null(lisa_results)) {
    warning("No LISA results available (run 07_lisa_clusters.R first); skipping Figure 3.")
  } else {

    lisa_data <- lisa_results[, c("codigo", "anno", "lisa_clusters_nombres_repro")]
    names(lisa_data)[3] <- "cluster"
    lisa_data$codigo <- sprintf("%05d", as.numeric(lisa_data$codigo))
    lisa_data$cluster[is.na(lisa_data$cluster)] <- "NS"

    geo_lisa <- merge(mpios, lisa_data, by = "codigo")
    lisa_years <- sort(unique(lisa_data$anno))

    # Exact colors from the original code (see 'grafica_dif' /
    # scale_fill_manual in 10.clusters_lisa.R block "(B) Kari").
    lisa_colors <- c(HH = "#FF0000", LL = "#0000FF", LH = "#a7adf9", HL = "#f4ada8", NS = "#eeeeee")

    make_lisa_map <- function(yr) {
      d <- geo_lisa[geo_lisa$anno == yr, ]
      g <- ggplot2::ggplot() +
        ggplot2::geom_sf(data = d, ggplot2::aes(fill = cluster), color = NA) +
        ggplot2::scale_fill_manual(values = lisa_colors, na.value = "#D3D3D3",
                                    limits = names(lisa_colors), name = "",
                                    labels = c("High-High", "Low-Low", "Low-High", "High-Low", "Not significant")) +
        ggplot2::labs(title = as.character(yr)) +
        ggplot2::theme_void() +
        ggplot2::theme(legend.position = "bottom", plot.title = ggplot2::element_text(size = 16, hjust = 0.5))
      add_dpto_outline(g)
    }

    lisa_maps <- lapply(lisa_years, make_lisa_map)

    fig3 <- ggpubr::ggarrange(
      plotlist = lisa_maps, common.legend = TRUE, legend = "bottom",
      nrow = if (length(lisa_years) <= 2) 1 else 2,
      ncol = if (length(lisa_years) <= 2) length(lisa_years) else 2
    )

    ggplot2::ggsave(file.path(dir$figures, "figure3_lisa_cluster_map.jpg"),
                     fig3, width = 9, height = if (length(lisa_years) > 2) 8 else 5, dpi = 300, bg = "white")

    message("Figure 3 saved to output/figures/ (original LISA colors, balanced panel, ",
            length(lisa_years), " years including 2005 if available).")
  }
}
