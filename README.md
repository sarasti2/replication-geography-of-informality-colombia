# Replication — "The Geography of Informality: the Case of Colombia"

Replication packages of . This replicate all graphs and tables in the papers with a 95% similarity including the Small Area Estimation (SAE). It assumes `data/raw/informalidad_municipal.csv`
is already the fully processed database (geographic, demographic and
economic variables, see the "Data" section of the paper), as provided
by the user.

Note: the actual data columns in the CSV keep their original Spanish
names (e.g. `informalidad_adj`, `pregimen_subsidiado`, `codigo`,
`anno`) as they where recollected.

## What each part does

The official pipeline is in R (`R/`). 

## Execution order (R/)

| # | Script | What it produces |
|---|--------|--------------|
| 0 | `00_packages.R` | installs/loads the required packages |
| 1 | `01_load_data.R` | loads `data/raw/informalidad_municipal.csv` |
| 2 | `02_fh_arcsin_function.R` | defines `FH_arcsin()` (Schmid et al. 2017) |
| 3 | `03_variable_selection_bic.R` | BIC covariate selection (Section 5.6) |
| 4 | `04_estimation_fh_arcsin.R` | runs Arc-FH for 2011/2016/2021 → `fharcsin_est`, `Low`, `Up` |
| 5 | `05_benchmarking.R` | department-level benchmarking → `fh_benchmark` |
| 6 | `06_estimation_merf.R` | MERF estimation (SAEforest) → `MERF_resultados` |
| 7 | `07_lisa_clusters.R` | LISA clusters for 2005/2011/2016/2021 → `lisa_clusters_nombres` (uses the bundled shapefile) |
| 8 | `08_variable_importance_rf.R` | **Table 2** — variable importance (from the step 6 MERF models) |
| 9 | `09_cluster_stability_table.R` | **Table 1** — stable cluster characteristics (includes `coca_ha`) |
| 10 | `10_figures_maps.R` | **Figures 1 and 3** — maps (uses the municipality/department shapefiles and the 2005 panel, all bundled) |
| 11 | `11_figure_temporal_ranking.R` | **Figure 2** — temporal change by ranking |
| 12 | `12_graph_difference_sae_dir.R` | **Figure A2 (appendix)** — MERF vs. direct estimate by department; this is the result in the paper where MERF is explicitly used |

Each script (04, 06 and 07) adds its result back to `base` so the
following steps can use it. 

Run everything with `run_all.R` from the project root:

```r
setwd("path/to/Replicacion_SAE_Informalidad_EN")
source("run_all.R")
```

## External inputs


1. **Shapefile of Colombian municipalities** (Marco Geoestadistico
   Nacional, DANE)
2. **2005 informality estimate** (2005 Census) — 
3. **Coca-crop hectares** (UNODC/SIMCI) — 
4. **Department shapefile** 


## Folder structure

```
Replicacion_SAE_Informalidad_EN/
├── README.md
├── run_all.R
├── data/
│   ├── raw/informalidad_municipal.csv        (INITIAL database, no fharcsin_est/MERF/lisa)
│   └── external/
│       ├── shapefiles/MGN_MPIO/          (DANE municipality shapefile)
│       ├── shapefiles/MGN_DPTO/          (DANE department shapefile)
│       ├── census2005/informalidad_2005.csv   
│       └── coca/coca_hectareas.csv           
├── R/                                       (official pipeline, not run here)
├── output/{estimates,tables,figures}/       (where the R pipeline saves results)
└── original_reference/                      (REAL outputs from the original project)
    ├── informalidad_municipal_full_with_results.csv
    ├── table1/clusters_stable.xlsx
    ├── table2/importance_{2011,2016,2021}.csv
    ├── clusters/resultados_cluster.dta
    └── figures/{figure1,figure2,figure3}_original.*
```

