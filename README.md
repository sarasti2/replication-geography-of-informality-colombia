# Replication — "The Geography of Informality: the Case of Colombia"

Replication package for **"The Geography of Informality: the Case of
Colombia"**, by Karina Acosta, Juliana Jaramillo-Echeverri, Daniel
Lasso-Jaramillo & Alejandro Sarasti-Sierra, published in *Spatial
Economic Analysis* (Vol. 20, No. 4, pp. 664-682). Received 02 Jul
2024, published online 23 Jul 2025. DOI:
[10.1080/17421772.2025.2522807](https://doi.org/10.1080/17421772.2025.2522807).

This package covers the part of the paper that this replication
focuses on: the Small Area Estimation (SAE) step and the resulting
figures/tables. It replicates all graphs and tables in the paper with
close (95% similarity, not pixel-perfect, but methodologically faithful) fidelity,
including the SAE estimation itself. It assumes
`data/raw/informalidad_municipal.csv` is already the fully processed
database (geographic, demographic and economic variables, see the
"Data" section of the paper), as provided by the user.

Note: the actual data columns in the CSV keep their original Spanish
names (e.g. `informalidad_adj`, `pregimen_subsidiado`, `codigo`,
`anno`) as they were collected. Only the code comments, messages and
object names were translated to English.

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
2. **2005 informality estimate** (2005 Census) 
3. **Coca-crop hectares** (UNODC/SIMCI) 
4. **Department shapefile**

## Original database variable dictionary

Translation/documentation of every column in
`data/raw/informalidad_municipal.csv`, in the same order they appear
in the CSV. Variable names are kept in their original Spanish as they where collected.

| Variable | Description |
|---|---|
| `codigo_depto` | DANE code of the department. |
| `codigo_provincia` | DANE code of the province. |
| `departamento` | Department name. |
| `municipio` | Municipality name. |
| `codigo` | DANE code of the municipality (5 digits; departments 05 -Antioquia- and 08 -Atlantico- carry a leading zero). |
| `anno` | Observation year (2005, 2011, 2016 or 2021). |
| `pob_total` | Total population of the municipality. |
| `formal_rate` | Ratio between the number of people in the Integrated Payroll and Contributions Form (PILA) and the municipal population. |
| `vacancy_rate` | Ratio between the number of job postings in the Public Employment Service (SPE) and the municipal population. |
| `ruralidad` | Share of the population in rural areas (outside the municipal seat) over the municipal population. |
| `t_crea` | Years elapsed since the municipality's founding date. |
| `altura` | Elevation above sea level of the municipality (meters). |
| `areakm2` | Area of the municipality in square kilometers. |
| `gandina` | Dummy: 1 if the municipality is in the Andean region. |
| `gcaribe` | Dummy: 1 if the municipality is in the Caribbean region. |
| `gpacifica` | Dummy: 1 if the municipality is in the Pacific region. |
| `gorinoquia` | Dummy: 1 if the municipality is in the Orinoquia region. |
| `gamazonia` | Dummy: 1 if the municipality is in the Amazon region. |
| `pruralpet` | Share of the rural working-age population over the total working-age population of the municipality. |
| `pmujerpet` | Share of women of working age over the total working-age population of the municipality. |
| `pdependiente` | Ratio of dependent persons (under 12 or over 65, per DANE's definition) over the total independent population. |
| `salario_bas` | Average wage in the municipality (Colombian pesos). |
| `pregimen_subsidiado` | Share of the population enrolled in the subsidized health regime over the municipality's total population. |
| `regimen_subsidiado` | Number of people in the municipality enrolled in the subsidized health regime. |
| `promleccri` | Municipal average Critical Reading score in the Saber 11 (ICFES) exam. |
| `prommatema` | Municipal average Mathematics score in the Saber 11 (ICFES) exam. |
| `promglobal` | Municipal average overall score in the Saber 11 (ICFES) exam. |
| `vab` | Municipal value added (billions of Colombian pesos). |
| `va_actividad_primaria` | Value added of the primary sector at the municipal level (billions of Colombian pesos). |
| `va_actividad_secundaria` | Value added of the secondary sector at the municipal level (billions of Colombian pesos). |
| `va_actividad_terciaria` | Value added of the tertiary sector at the municipal level (billions of Colombian pesos). |
| `vabpc` | Value added per capita: ratio between value added and the municipality's population. |
| `pprimary` | Share of primary-sector value added over the municipality's total value added. |
| `psecondary` | Share of secondary-sector value added over the municipality's total value added. |
| `pterciary` | Share of tertiary-sector value added over the municipality's total value added. |
| `distancia_mercado` | Linear distance to other nearby markets (kilometers). |
| `disbogota` | Linear distance between the municipality and Bogota (kilometers). |
| `dismdo` | Linear distance to the department's main wholesale food market (kilometers). |
| `pgroup1` | Share of men aged 14-24 in the municipality. |
| `pgroup2` | Share of men aged 25-54 in the municipality. |
| `pgroup3` | Share of men over 54 in the municipality. |
| `pgroup4` | Share of women aged 14-24 in the municipality. |
| `pgroup5` | Share of women aged 25-54 in the municipality. |
| `pgroup6` | Share of women over 54 in the municipality. |
| `num_obser_freq` * | Number of GEIH survey observations (sample size) used for the direct estimate of the municipality-year. |
| `num_obser_freq_adj` * | Effective number of GEIH observations, adjusted for the survey design effect. |
| `informales_freq` * | Raw count of informal workers in the GEIH sample for the municipality-year. |
| `informales_freq_adj` * | Adjusted/weighted (design-corrected) count of informal workers in the GEIH sample. |
| `ocupados_freq` * | Raw count of employed persons in the GEIH sample for the municipality-year. |
| `ocupados_freq_adj` * | Adjusted/weighted count of employed persons in the GEIH sample. |
| `informalidad` | Direct GEIH estimate of informality, for municipalities where the survey is representative. |
| `informalidad_adj` * | Direct GEIH estimate of informality computed from the adjusted counts (`informales_freq_adj` / `ocupados_freq_adj`). |
| `informalidad_adj_var` | Variance of the `informalidad_adj` direct estimator. |
| `fharcsin_est` (computed in step 4) | Small Area Estimation estimate using arcsine-transformed Fay-Herriot. |
| `Low` / `Up` (step 4) * | Lower/upper confidence interval bounds of `fharcsin_est`. |
| `fh_benchmark` (step 5) | SAE estimate using Fay-Herriot with department-level benchmarking applied. |
| `MERF_resultados` (step 6) | Informality estimate from the mixed-effects random forest (MERF). |
| `lisa_clusters` (step 7) | Code of the LISA cluster the municipality-year belongs to. |
| `lisa_clusters_nombres` (step 7) | Name/label of the LISA cluster (HH, LL, HL, LH or NA) the municipality-year belongs to. |



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
