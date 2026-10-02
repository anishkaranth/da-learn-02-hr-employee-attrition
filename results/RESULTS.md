# Results - full IBM HR Employee Attrition dataset (1,470 employees)

Run: `python run_pipeline.py --source full` on DuckDB 1.5.6 (Python 3.13), 2026-10-02. Every number below is copied from `results/tables/*.csv` / `metrics.json` produced by that run.

![dashboard](charts/dashboard.svg)

## Headline KPIs
| KPI | Value |
|---|---|
| Employees | 1,470 |
| Leavers (Attrition = Yes) | 237 |
| Stayers | 1,233 |
| Attrition rate | **16.12 %** |
| Avg / median monthly income | $6,502.93 / $4,919 |
| Avg age | 36.92 years |
| Avg years at company | 7.01 |
| Avg job satisfaction (1-4) | 2.729 |
| Overtime share | 28.30 % of employees |
| Attrition among OverTime = Yes | **30.53 %** |
| Attrition among OverTime = No | **10.44 %** |
| Avg income leavers / stayers | $4,787.09 / $6,832.74 |
| Avg tenure leavers / stayers | 5.13 / 7.37 years |

## Key findings
1. **Overtime nearly triples attrition.** Employees on overtime leave at **30.53 %** vs **10.44 %** without overtime (416 OT / 1,054 non-OT).
2. **Early tenure and junior sales/lab roles are hottest.** Tenure < 2 years: **34.88 %** attrition (75/215). Sales Representatives at job level 1: **42.11 %** (32/76). Laboratory Technicians level 1: **28.0 %** (56/200).
3. **Department & travel.** Sales **20.63 %**, Human Resources **19.05 %**, Research & Development **13.84 %**. Frequent travellers leave at **24.91 %** vs Non-Travel **8.0 %**.
4. **Pay and satisfaction protect retention.** Income < $3k: **28.61 %** attrition vs 15k+: **3.76 %**. Low job satisfaction: **22.84 %** vs Very High: **11.33 %**. Under-25s leave at **39.18 %**.

## Data quality
| Entity | Raw rows | Clean rows |
|---|---|---|
| employee | 1,470 | 1,470 |
| fact_employee | — | 1,470 |
| dims (dept / job_role / education / travel) | — | 3 / 26 / 30 / 3 |

Integrity: 0 orphan FKs; 0 duplicate EmployeeNumber; **10/10 assertions PASS**.

Cross-engine: Databricks serverless SQL warehouse row counts match all 7 core tables. Headline KPIs match except `median_monthly_income` (Databricks `percentile_approx` **4,908** vs DuckDB exact **4,919**). See `../databricks/run_outputs/duckdb_vs_databricks.json`.
