# Results - full IBM HR Employee Attrition dataset (1,470 employees)

Run: `python run_pipeline.py --source full` on DuckDB 1.5.6 (Python 3.13), 2026-10-02.

## Headline KPIs
| KPI | Value |
|---|---|
| Employees | 1,470 |
| Leavers | 237 |
| Attrition rate | **16.12 %** |
| Avg / median monthly income | $6,502.93 / $4,919 |
| OT attrition | **30.53 %** |
| No-OT attrition | **10.44 %** |

## Key findings
1. Overtime nearly triples attrition (30.53% vs 10.44%).
2. Tenure <2y 34.88%; Sales Rep L1 42.11%; Lab Tech L1 28.0%.
3. Sales 20.63%, HR 19.05%, R&D 13.84%; Travel_Frequently 24.91% vs Non-Travel 8.0%.
4. Income <3k 28.61% vs 15k+ 3.76%; Low satisfaction 22.84% vs Very High 11.33%.

DuckDB vs Databricks: all 7 core table counts match; median income 4919 vs 4908.
**10/10 assertions PASS.**
