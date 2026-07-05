# =====================================================================
# 07_lisa_clusters.R
#
# Local Indicators of Spatial Association (LISA, Anselin 1995) on the
# Arc-FH informality estimate, to detect HH / LL / HL / LH clusters
# (see the "Local indicators of spatial association - LISA" section of
# the paper). Uses a first-order queen contiguity matrix.
#
# *** REQUIRES A SHAPEFILE OF COLOMBIAN MUNICIPALITIES ***
# Place the shapefile (.shp with its .dbf/.shx/.prj) in:
#   data/external/shapefiles/MGN_MPIO/
# The Colombian "Marco Geoestadistico Nacional" (MGN) can be downloaded
# for free from DANE's geoportal: https://geoportal.dane.gov.co
# The shapefile must have a 5-digit DIVIPOLA code column (department +
# municipality) matching 'codigo' in the database.
#
# UPDATE: the shapefile was found in the project (Dropbox\
# SAE_informalidad\data\shapefiles\MGN2021_MPIO_POLITICO\) and is now
# included in this package at data/external/shapefiles/MGN_MPIO/.
#
# METHODOLOGY NOTE (fix after a real run): the original code
# (10.clusters_lisa.R) has TWO blocks ("(A) Juli" and "(B) Kari"); the
# one that actually generates the reference file
# 'clusters/resultados_cluster.dta' is block (B), which uses
# rgeoda::queen_weights() + rgeoda::local_moran() (GeoDa's LISA, with
# significance via conditional PERMUTATION, 999 permutations by
# default) -- NOT spdep::localmoran() with an analytic (asymptotic
# normal) p-value. Block (B) also explicitly excludes 3 codes before
# building neighbors: "88001" (San Andres), "88564" (Providencia) and
# "97666" (an island/exclave corregimiento in Amazonas/Vaupes) that
# have no valid land neighbors. That same block (B) ALSO computes LISA
# for 2005 (using the 2005 Census direct estimate), in addition to
# 2011/2016/2021.
#
# CRITICAL NOTE -- BALANCED PANEL (blank municipalities the same across
# every year, so maps are comparable): the original code builds
# 'data_small_combined' with an INNER JOIN across all 4 years (2005,
# 2011, 2016, 2021) before running LISA -- literally "this is done so
# all years have the same NAs" (the author's own 2018 comment), then
# "we go back to the original bases, all with the same number of
# observations". In other words: a municipality without a valid
# estimate in ANY of the 4 years is excluded from ALL 4 years, not just
# the year where it is missing. This keeps the set of "blank"
# municipalities identical across the 4 panels, so year-to-year visual
# and spatial comparisons are valid (same universe of municipalities,
# same neighbor structure). This is reproduced exactly here: the
# intersection of codes with a valid estimate in all 4 years is
# computed BEFORE running LISA, and that same intersection is used in
# 10_figures_maps.R for Figure 1.
#
# This is reproduced as faithfully as possible with the tools spdep
# offers: the same 3 codes are excluded, and spdep::localmoran_perm()
# (conditional-permutation LISA, nsim = 999, fixed seed) is used
# instead of spdep::localmoran(), reading the "Pr(folded) Sim" p-value
# (spdep's analogue of GeoDa/rgeoda's "folded" permutation
# significance).
#
# CRITICAL NOTE on the DIVIPOLA code (bug fixed after a real run:
# Antioquia was missing from every map): the shapefile stores
# 'MPIO_CDPMP' as 5-digit zero-padded text where relevant (e.g.
# "05001" for Medellin), but 'base$codigo' is numeric and comes WITHOUT
# that leading zero (5001), because that is how it already was in the
# input CSV. as.character(5001) gives "5001" (4 characters), which
# NEVER matches "05001" from the shapefile -- this silently dropped
# ALL of Antioquia (department "05") and Atlantico (department "08")
# from any spatial merge. The original code avoids this with
# sprintf("%05d", as.numeric(codigo)) before joining with the
# shapefile (see 10.clusters_lisa.R, 14-public_db_creation.R); the same
# is done here.
#
# 'base' has NO rows for anno == 2005 (the panel modeled with SAE is
# only 2011/2016/2021); so the 2005 LISA result is computed separately,
# from data/external/census2005/informalidad_2005.csv, and saved in
# the same 'lisa_resultados' (CSV + in-session object) so that
# 10_figures_maps.R can use it for Figure 3, although it is NOT merged
# back into 'base' (there is no place for it there).
#
# Uses 'base$fharcsin_est' computed by script 04 (no longer precomputed
# in the initial database, see 01_load_data.R) and adds the result as
# 'lisa_clusters_nombres' so steps 9-11 can use it (only for
# 2011/2016/2021).
# =====================================================================

shp_path <- file.path(dir$data_ext, "shapefiles", "MGN_MPIO")
census2005_path <- file.path(dir$data_ext, "census2005", "informalidad_2005.csv")

if (dir.exists(shp_path) && length(list.files(shp_path, pattern = "\\.shp$")) > 0) {

  mpios <- sf::st_read(shp_path, quiet = TRUE)
  # Adjust the DIVIPOLA code column name according to the actual shapefile
  code_col <- intersect(c("MPIO_CDPMP", "DIVIPOLA", "codigo", "COD_MPIO"), names(mpios))[1]
  stopifnot(!is.na(code_col))
  mpios$codigo <- as.character(mpios[[code_col]])

  # Municipalities/islands without valid land neighbors, excluded by
  # the original code before computing the neighbors matrix.
  codes_to_exclude <- c("88001", "88564", "97666")

  # --- gather the informality estimate for all 4 years (2005 + 2011/2016/2021) ---
  values_by_year <- list()
  for (yr in c(2011, 2016, 2021)) {
    d <- base[base$anno == yr, c("codigo", "fharcsin_est")]
    d$codigo <- sprintf("%05d", as.numeric(d$codigo))
    values_by_year[[as.character(yr)]] <- d
  }
  has_2005 <- file.exists(census2005_path)
  if (has_2005) {
    census05 <- readr::read_csv(census2005_path, show_col_types = FALSE)
    values_by_year[["2005"]] <- data.frame(
      codigo = sprintf("%05d", as.numeric(census05$codigo)),
      fharcsin_est = census05$informalidad_2005
    )
  } else {
    message("File '", census2005_path, "' not found: skipping the 2005 panel of the LISA map (Figure 3).")
  }

  # --- balanced panel: intersection of codes with a valid estimate in ALL years ---
  # (same as the original code's 'data_small_combined <- inner_join(...)',
  # see the critical note above: "so all years have the same NAs")
  valid_codes_by_year <- lapply(values_by_year, function(d) d$codigo[!is.na(d$fharcsin_est)])
  balanced_codes <- Reduce(intersect, valid_codes_by_year)
  balanced_codes <- setdiff(balanced_codes, codes_to_exclude)
  message("LISA balanced panel: ", length(balanced_codes),
          " municipalities with a valid estimate across the ", length(values_by_year), " available years.")

  # --- helper: computes LISA for a codigo/fharcsin_est data.frame ---
  compute_lisa <- function(dyr, year_lbl) {
    geo_yr <- merge(mpios, dyr, by = "codigo")
    geo_yr <- geo_yr[!is.na(geo_yr$fharcsin_est), ]
    if (nrow(geo_yr) < 10) {
      warning("Too few geo-referenced observations for year ", year_lbl, "; skipping LISA.")
      return(NULL)
    }

    nb <- spdep::poly2nb(geo_yr, queen = TRUE)
    # islands / municipalities without neighbors are excluded from the test
    # (spdep leaves them with 0 neighbors)
    lw <- spdep::nb2listw(nb, style = "W", zero.policy = TRUE)

    # Conditional-permutation LISA (999 simulations), matching block
    # (B) of the original code via rgeoda::local_moran(); see the
    # methodology note above.
    local_i <- spdep::localmoran_perm(
      geo_yr$fharcsin_est, lw, nsim = 999,
      zero.policy = TRUE, iseed = 12345
    )

    z_val   <- scale(geo_yr$fharcsin_est)[, 1]
    z_lag   <- spdep::lag.listw(lw, geo_yr$fharcsin_est, zero.policy = TRUE)
    z_lag_s <- scale(z_lag)[, 1]
    p_col   <- grep("folded", colnames(local_i), value = TRUE)[1]
    p_val   <- local_i[, p_col]

    cluster_type <- dplyr::case_when(
      p_val >= 0.05          ~ "NS",
      z_val >= 0 & z_lag_s >= 0 ~ "HH",
      z_val < 0  & z_lag_s < 0  ~ "LL",
      z_val >= 0 & z_lag_s < 0  ~ "HL",
      z_val < 0  & z_lag_s >= 0 ~ "LH",
      TRUE ~ NA_character_
    )

    data.frame(codigo = geo_yr$codigo, anno = year_lbl, lisa_clusters_nombres_repro = cluster_type)
  }

  lisa_by_year <- list()
  for (year_name in names(values_by_year)) {
    dyr <- values_by_year[[year_name]]
    dyr <- dyr[dyr$codigo %in% balanced_codes, ]
    result <- compute_lisa(dyr, as.numeric(year_name))
    if (!is.null(result)) lisa_by_year[[year_name]] <- result
  }

  lisa_resultados <- do.call(rbind, lisa_by_year)
  readr::write_csv(lisa_resultados, file.path(dir$estimates, "lisa_resultados.csv"))
  message("LISA computed for ", nrow(lisa_resultados), " municipality-year observations ",
          "(balanced panel, includes 2005 if the census panel was available).")

  # --- add the computed column to 'base' for the following steps ---
  # (only 2011/2016/2021: 'base' has no 2005 rows, those stay only in
  # 'lisa_resultados' for direct use in 10_figures_maps.R)
  lisa_for_base <- lisa_resultados[lisa_resultados$anno != 2005, ]
  lisa_for_base$codigo <- as.numeric(lisa_for_base$codigo)
  base <- dplyr::left_join(base, lisa_for_base, by = c("codigo", "anno"))
  base$lisa_clusters_nombres <- base$lisa_clusters_nombres_repro

  # --- optional check against the original database (with results already computed) ---
  ref_path <- file.path(dir$reference, "informalidad_municipal_full_with_results.csv")
  if (file.exists(ref_path)) {
    reference <- readr::read_delim(ref_path, delim = ";", show_col_types = FALSE)
    lisa_check <- merge(lisa_for_base, reference[, c("codigo", "anno", "lisa_clusters_nombres")],
                         by = c("codigo", "anno"))
    lisa_check <- lisa_check[stats::complete.cases(lisa_check), ]
    if (nrow(lisa_check) > 10) {
      match_rate <- mean(lisa_check$lisa_clusters_nombres_repro == lisa_check$lisa_clusters_nombres)
      message("LISA agreement reproduced vs. original database (original_reference/, 2011/2016/2021): ",
              round(100 * match_rate, 1), "%")
    }
  } else {
    message("File '", ref_path, "' not found: skipping the comparison against the original database.")
  }

} else {
  warning(
    "No shapefile found in '", shp_path, "'. \n",
    "Skipping the LISA computation (07_lisa_clusters.R) and the cluster map (Figure 3). \n",
    "Download the DANE municipality MGN shapefile and place it in that folder to enable this step."
  )
}
