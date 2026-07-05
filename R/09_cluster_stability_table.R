# =====================================================================
# 09_cluster_stability_table.R
#
# Paper's Table 1: general characteristics of municipalities depending
# on whether they keep the SAME LISA cluster type (HH/LL/HL/LH) across
# ALL available years (2011, 2016, 2021), compared against the "NA"
# group (not significant, or changes cluster type over the period).
#
# =====================================================================

table1_vars <- c(
  "t_crea", "promleccri", "prommatema", "promglobal",
  "dismdo", "disbogota", "pdependiente", "coca_ha"
  # add here once available: "ubn", "mpi", "moderate_poverty", "extreme_poverty"
)

coca_path <- file.path(dir$data_ext, "coca", "coca_hectareas.csv")
if (file.exists(coca_path)) {
  coca <- readr::read_csv(coca_path, show_col_types = FALSE)
  base <- dplyr::left_join(base, coca, by = c("codigo", "anno"))
  base$coca_ha[is.na(base$coca_ha) & base$anno %in% c(2011, 2016, 2021)] <- 0
  message("Coca hectares merged from ", coca_path)
} else {
  message("File '", coca_path, "' not found: 'coca_ha' is omitted from Table 1.")
}

table1_vars <- table1_vars[table1_vars %in% names(base)]

cluster_col <- if ("lisa_clusters_nombres_repro" %in% names(base)) {
  "lisa_clusters_nombres_repro"
} else {
  "lisa_clusters_nombres"
}

wide_cluster <- base %>%
  dplyr::select(codigo, anno, dplyr::all_of(cluster_col)) %>%
  tidyr::pivot_wider(names_from = anno, values_from = dplyr::all_of(cluster_col),
                      names_prefix = "cl_")

wide_cluster <- wide_cluster %>%
  dplyr::mutate(
    n_types = apply(dplyr::across(dplyr::starts_with("cl_")), 1,
                     function(x) length(unique(stats::na.omit(x)))),
    has_na = apply(dplyr::across(dplyr::starts_with("cl_")), 1,
                    function(x) any(is.na(x)) || any(x %in% c("NS", NA))),
    stable_class = dplyr::case_when(
      n_types == 1 & !has_na & cl_2011 == "HH" ~ "HH",
      n_types == 1 & !has_na & cl_2011 == "LL" ~ "LL",
      n_types == 1 & !has_na & cl_2011 == "HL" ~ "HL",
      n_types == 1 & !has_na & cl_2011 == "LH" ~ "LH",
      TRUE ~ "NA"
    )
  )

stable_data <- base %>%
  dplyr::filter(anno == 2021) %>%
  dplyr::select(codigo, dplyr::all_of(table1_vars)) %>%
  dplyr::left_join(wide_cluster[, c("codigo", "stable_class")], by = "codigo")

summary_tbl <- stable_data %>%
  dplyr::group_by(stable_class) %>%
  dplyr::summarise(dplyr::across(dplyr::all_of(table1_vars), ~ mean(., na.rm = TRUE)),
                    n = dplyr::n(), .groups = "drop")

# t-test of each group (HH/LL/HL/LH) against the NA group for each variable
t_test_vs_na <- function(var) {
  na_vals <- stable_data[[var]][stable_data$stable_class == "NA"]
  sapply(c("HH", "LL", "HL", "LH"), function(cl) {
    grp_vals <- stable_data[[var]][stable_data$stable_class == cl]
    if (length(grp_vals) < 2 || length(na_vals) < 2) return(NA_real_)
    tryCatch(stats::t.test(grp_vals, na_vals)$p.value, error = function(e) NA_real_)
  })
}
pvalues <- sapply(table1_vars, t_test_vs_na)

readr::write_csv(summary_tbl, file.path(dir$tables, "table1_stable_clusters_means.csv"))
saveRDS(pvalues, file.path(dir$tables, "table1_stable_clusters_pvalues.rds"))

message("Table 1 (means by stable cluster type) saved to output/tables/.")
print(summary_tbl)
