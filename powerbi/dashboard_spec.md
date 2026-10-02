# Dashboard specification (3 pages)

Validate against full-data SQL: Attrition **16.12 %**, Employees **1,470**, OT attrition **30.53 %**, No-OT **10.44 %** (`results/metrics.json`).

## Page 1 — Executive overview
* KPI cards: Employees, Leavers, Attrition %, Avg Monthly Income, OT Attrition %, No-OT Attrition %
* Bar: Attrition % by `dim_department[department_name]`
* Horizontal bar: Attrition % by `dim_job_role[job_role]` (top roles)

## Page 2 — Drivers
* Clustered bar: Attrition % by overtime (`fact_employee[overtime_flag]` → Yes/No)
* Bar: Attrition % by `fact_employee[tenure_band]` (sort by band)
* Bar: Attrition % by `fact_employee[job_satisfaction]` (1-4, use labels Low..Very High)
* Bar: Attrition % by `dim_travel[business_travel]`

## Page 3 — Segments
* Matrix: Gender × Marital Status, values = Attrition %
* Bar: Attrition % by `income_band` and by `age_band`
* Table: job_role × job_level with Employees, Leavers, Attrition %

Optional calculated column on `fact_employee`:
```DAX
Overtime Label = IF ( fact_employee[overtime_flag] = 1, "OverTime", "No OverTime" )
```
