# =====================================================================
# 05_benchmarking.R
#
# Benchmarking of the Arc-FH estimates so that, weighted by population,
# they match the direct estimator at the department level (column
# 'fh_benchmark' in the database). Uses ratio benchmarking (see Rao &
# Molina 2015, ch. 7): within each department-year, each municipal
# estimate is rescaled by the ratio between the department-level
# direct estimate and the population-weighted average of the Arc-FH
# estimates for that department.
#
# Requires: 04_estimation_fh_arcsin.R already run.
# =====================================================================

dep_direct <- base %>%
  dplyr::filter(!is.na(informalidad_adj)) %>%
  dplyr::group_by(codigo_depto, anno) %>%
  dplyr::summarise(
    direct_dept = stats::weighted.mean(informalidad_adj, w = pob_total, na.rm = TRUE),
    .groups = "drop"
  )

fh_with_pop <- fh_arcsin_resultados %>%
  dplyr::left_join(base[, c("codigo", "anno", "codigo_depto", "pob_total")],
                    by = c("codigo", "anno"))

bench <- fh_with_pop %>%
  dplyr::left_join(dep_direct, by = c("codigo_depto", "anno")) %>%
  dplyr::group_by(codigo_depto, anno) %>%
  dplyr::mutate(
    fh_dept_weighted = stats::weighted.mean(fharcsin_est_repro, w = pob_total, na.rm = TRUE),
    bench_factor = ifelse(is.na(direct_dept) | fh_dept_weighted == 0, 1,
                           direct_dept / fh_dept_weighted),
    fh_benchmark_repro = pmin(pmax(fharcsin_est_repro * bench_factor, 0), 100)
  ) %>%
  dplyr::ungroup()

readr::write_csv(
  bench[, c("codigo", "anno", "fharcsin_est_repro", "fh_benchmark_repro")],
  file.path(dir$estimates, "fh_benchmark_resultados.csv")
)

message("Department-level benchmarking applied. Example factors (2021):")
print(utils::head(bench[bench$anno == 2021, c("codigo_depto", "bench_factor")] %>% dplyr::distinct()))
