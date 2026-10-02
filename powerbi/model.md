# Power BI model

## Tables (from `powerbi/data/`)
| Table | Grain | Key columns |
|---|---|---|
| `fact_employee` | one employee | `employee_number` (unique), `department_key`, `job_role_key`, `education_key`, `travel_key`, `attrition_flag` |
| `dim_department` | department | `department_key`, `department_name` |
| `dim_job_role` | job role x level | `job_role_key`, `job_role`, `job_level` |
| `dim_education` | education level x field | `education_key`, `education_level`, `education_label`, `education_field` |
| `dim_travel` | travel frequency | `travel_key`, `business_travel` |

## Relationships (*:1, single direction)
1. `fact_employee[department_key]` -> `dim_department[department_key]`
2. `fact_employee[job_role_key]` -> `dim_job_role[job_role_key]`
3. `fact_employee[education_key]` -> `dim_education[education_key]`
4. `fact_employee[travel_key]` -> `dim_travel[travel_key]`

## Suggested data types
* Keys / flags / Likert scores / years / rates: Whole number
* `monthly_income`, averages used in measures: Decimal number
* Band / label / name columns: Text
* No date table (source has no calendar dates)

Hide key and `dq_*` / outlier flag columns from report view.
