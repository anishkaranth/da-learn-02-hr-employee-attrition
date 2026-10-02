# Power BI build guide

> A `.pbix` file cannot be produced on the Linux box this project was built on (Power BI Desktop is Windows-only
> and has no headless/CLI author mode), so this folder is a **kit**: data + model + measures + layout spec.
> Estimated build time: 30-45 min. The dataset is small (1,470 rows), so `powerbi/data/` holds the **full** clean star schema.

1. **Get the data.** Use the CSVs in `powerbi/data/` (full run). Or regenerate with
   `pip install -r requirements.txt && python scripts/download_full_data.py && python run_pipeline.py --source full`.
2. **Load.** Power BI Desktop -> *Get data -> Text/CSV* for each of the 5 files (`fact_employee`, `dim_department`,
   `dim_job_role`, `dim_education`, `dim_travel`). Set types from `model.md`. Locale: English (United States).
3. **Model.** Model view -> create the 4 relationships from `model.md` (all *:1, single direction). Hide keys/flags.
4. **Measures.** Create a table `_Measures` and paste each measure from `measures.dax`. Format % measures as percentage, income as currency.
5. **Pages.** Build the 3 pages in `dashboard_spec.md`; compare with `results/charts/dashboard.svg`.
6. **Validate** against the SQL run (full data): Employees 1,470, Attrition 16.12 %, OT attrition 30.53 %, No-OT 10.44 %,
   Avg income $6,502.93 (`results/metrics.json`). Subset expected values: `results/sample/JSON.shot`.
7. Save as `hr_attrition.pbix` (not committed — binary).
