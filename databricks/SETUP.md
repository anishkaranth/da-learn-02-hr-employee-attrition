# Databricks package

The full pipeline is intended to run on a Databricks **serverless SQL warehouse** (Unity Catalog), with a Lakeview
(AI/BI) dashboard published over the resulting tables. The warehouse should be stopped afterwards.

| Object | Workspace location |
|---|---|
| Raw CSV (full) | UC volume `/Volumes/workspace/da_learn_02/raw/` |
| Tables (stg_*, cln_*, dim_*, fact_*, a_*, dq_*) | `workspace.da_learn_02` |
| Notebook | `/Workspace/Shared/da-learn-02-hr-employee-attrition/hr_pipeline_notebook` |
| Dashboard (published) | **da-learn-02 HR employee attrition** |

## DuckDB vs Databricks
All **7 core tables have identical row counts** (stg/cln/fact_employee 1,470; dim_department 3; dim_job_role 26; dim_education 30; dim_travel 3).
`a_kpi_headline` matches except **median_monthly_income** (Databricks 4,908 vs DuckDB 4,919) because `percentile_approx` is approximate on Spark. `dq_assertions` 10/10 PASS on both. Dashboard published: **da-learn-02 HR employee attrition**.

## Files here
| File | What it is |
|---|---|
| `hr_pipeline_notebook.sql` | Databricks SQL notebook source generated from `sql/` |
| `hr_attrition_dashboard.lvdash.json` | Lakeview dashboard definition (2 pages, KPI counters + department/role/overtime/tenure/satisfaction/travel charts) |
| `run_outputs/` | Tables queried back from Databricks + `duckdb_vs_databricks.json` after a live run |

## Re-run it yourself
1. `CREATE SCHEMA IF NOT EXISTS workspace.da_learn_02; CREATE VOLUME IF NOT EXISTS workspace.da_learn_02.raw;`
2. Upload `data/raw_full/emp_attrition.csv` (`python scripts/download_full_data.py`) to the volume.
3. Workspace -> *Import* -> `hr_pipeline_notebook.sql`; attach a SQL warehouse -> *Run all*.
   Check that `dq_assertions` shows 10 x PASS.
4. Dashboards -> *Import dashboard from file* -> `hr_attrition_dashboard.lvdash.json` -> pick a warehouse -> *Publish*.

## Dialect notes (DuckDB vs Databricks)
| Topic | DuckDB run | Databricks |
|---|---|---|
| CSV load | `read_csv(path, header = true, all_varchar = true)` | `read_files(..., inferColumnTypes => false)` |
| `percentile_approx` | exact (`quantile_cont` shim) | approximate |
| Everything else used here (`TRY_CAST`, window functions, `CASE`) | same | same |
