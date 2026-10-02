-- 05_quality_checks.sql  Data-quality evidence (Spark SQL dialect)

CREATE OR REPLACE TABLE dq_row_counts AS
SELECT 'employee' AS entity,
       (SELECT COUNT(*) FROM stg_employee) AS raw_rows,
       (SELECT COUNT(DISTINCT TRY_CAST(EmployeeNumber AS INT)) FROM stg_employee) AS distinct_keys,
       (SELECT COUNT(*) FROM cln_employee) AS clean_rows,
       'employee_number' AS grain
UNION ALL SELECT 'fact_employee', NULL, NULL, (SELECT COUNT(*) FROM fact_employee), 'employee'
UNION ALL SELECT 'dim_department', NULL, NULL, (SELECT COUNT(*) FROM dim_department), 'department'
UNION ALL SELECT 'dim_job_role', NULL, NULL, (SELECT COUNT(*) FROM dim_job_role), 'job_role + job_level'
UNION ALL SELECT 'dim_education', NULL, NULL, (SELECT COUNT(*) FROM dim_education), 'education + field'
UNION ALL SELECT 'dim_travel', NULL, NULL, (SELECT COUNT(*) FROM dim_travel), 'business_travel';

CREATE OR REPLACE TABLE dq_null_rates AS
SELECT 'employee' AS entity, 'Attrition' AS column_name,
  (SELECT ROUND(100.0 * SUM(CASE WHEN Attrition IS NULL OR trim(Attrition) = '' THEN 1 ELSE 0 END) / COUNT(*), 3) FROM stg_employee) AS raw_null_pct,
  (SELECT ROUND(100.0 * SUM(CASE WHEN attrition_flag IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3) FROM cln_employee) AS clean_null_pct,
  'required; rows with missing attrition dropped' AS treatment
UNION ALL SELECT 'employee', 'MonthlyIncome',
  (SELECT ROUND(100.0 * SUM(CASE WHEN MonthlyIncome IS NULL OR trim(MonthlyIncome) = '' THEN 1 ELSE 0 END) / COUNT(*), 3) FROM stg_employee),
  (SELECT ROUND(100.0 * SUM(CASE WHEN monthly_income IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3) FROM cln_employee),
  'required; non-positive dropped'
UNION ALL SELECT 'employee', 'BusinessTravel',
  (SELECT ROUND(100.0 * SUM(CASE WHEN BusinessTravel IS NULL OR trim(BusinessTravel) = '' THEN 1 ELSE 0 END) / COUNT(*), 3) FROM stg_employee),
  (SELECT ROUND(100.0 * SUM(CASE WHEN business_travel IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3) FROM cln_employee),
  'standardised labels; NULL kept if unrecognised'
UNION ALL SELECT 'employee', 'EducationField',
  (SELECT ROUND(100.0 * SUM(CASE WHEN EducationField IS NULL OR trim(EducationField) = '' THEN 1 ELSE 0 END) / COUNT(*), 3) FROM stg_employee),
  (SELECT ROUND(100.0 * SUM(CASE WHEN education_field IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3) FROM cln_employee),
  'trimmed; NULL dropped via RI on dim_education join';

CREATE OR REPLACE TABLE dq_issues AS
SELECT 'employee: duplicate EmployeeNumber (extras dropped)' AS check_name,
       (SELECT COUNT(*) FROM stg_employee) - (SELECT COUNT(DISTINCT TRY_CAST(EmployeeNumber AS INT)) FROM stg_employee) AS affected_rows
UNION ALL SELECT 'employee: rows dropped in cleaning',
       (SELECT COUNT(*) FROM stg_employee) - (SELECT COUNT(*) FROM cln_employee)
UNION ALL SELECT 'employee: income outlier (> Q3 + 3*IQR)', (SELECT SUM(is_income_outlier_iqr3) FROM cln_employee)
UNION ALL SELECT 'employee: income in top 1%', (SELECT SUM(is_income_top1pct) FROM cln_employee)
UNION ALL SELECT 'employee: years_at_company > total_working_years', (SELECT SUM(dq_tenure_gt_career) FROM cln_employee)
UNION ALL SELECT 'employee: years_in_current_role > years_at_company', (SELECT SUM(dq_role_gt_company) FROM cln_employee)
UNION ALL SELECT 'employee: years_with_curr_manager > years_at_company', (SELECT SUM(dq_manager_gt_company) FROM cln_employee)
UNION ALL SELECT 'employee: years_since_last_promotion > years_at_company', (SELECT SUM(dq_promo_gt_company) FROM cln_employee)
UNION ALL SELECT 'employee: non-constant EmployeeCount', (SELECT SUM(dq_nonconstant_employee_count) FROM cln_employee)
UNION ALL SELECT 'employee: non-constant Over18', (SELECT SUM(dq_nonconstant_over18) FROM cln_employee)
UNION ALL SELECT 'employee: non-constant StandardHours', (SELECT SUM(dq_nonconstant_standard_hours) FROM cln_employee)
UNION ALL SELECT 'employee: overtime Yes', (SELECT SUM(overtime_flag) FROM cln_employee)
UNION ALL SELECT 'employee: attrition Yes', (SELECT SUM(attrition_flag) FROM cln_employee)
UNION ALL SELECT 'RI: fact without department', (SELECT COUNT(*) FROM fact_employee WHERE department_key IS NULL)
UNION ALL SELECT 'RI: fact without job_role', (SELECT COUNT(*) FROM fact_employee WHERE job_role_key IS NULL)
UNION ALL SELECT 'RI: fact without education', (SELECT COUNT(*) FROM fact_employee WHERE education_key IS NULL)
UNION ALL SELECT 'RI: fact without travel', (SELECT COUNT(*) FROM fact_employee WHERE travel_key IS NULL);

CREATE OR REPLACE TABLE dq_assertions AS
WITH c AS (
  SELECT 'fact_employee.employee_number unique' AS check_name,
         (SELECT COUNT(*) - COUNT(DISTINCT employee_number) FROM fact_employee) AS failed_rows
  UNION ALL SELECT 'fact_employee.department_key -> dim_department',
         (SELECT COUNT(*) FROM fact_employee WHERE department_key NOT IN (SELECT department_key FROM dim_department))
  UNION ALL SELECT 'fact_employee.job_role_key -> dim_job_role',
         (SELECT COUNT(*) FROM fact_employee WHERE job_role_key NOT IN (SELECT job_role_key FROM dim_job_role))
  UNION ALL SELECT 'fact_employee.education_key -> dim_education',
         (SELECT COUNT(*) FROM fact_employee WHERE education_key NOT IN (SELECT education_key FROM dim_education))
  UNION ALL SELECT 'fact_employee.travel_key -> dim_travel',
         (SELECT COUNT(*) FROM fact_employee WHERE travel_key IS NOT NULL AND travel_key NOT IN (SELECT travel_key FROM dim_travel))
  UNION ALL SELECT 'attrition_flag in {0,1}',
         (SELECT COUNT(*) FROM fact_employee WHERE attrition_flag NOT IN (0, 1))
  UNION ALL SELECT 'monthly_income > 0',
         (SELECT COUNT(*) FROM fact_employee WHERE monthly_income <= 0)
  UNION ALL SELECT 'age between 18 and 70',
         (SELECT COUNT(*) FROM fact_employee WHERE age < 18 OR age > 70)
  UNION ALL SELECT 'job_satisfaction in 1..4',
         (SELECT COUNT(*) FROM fact_employee WHERE job_satisfaction NOT BETWEEN 1 AND 4)
  UNION ALL SELECT 'no NULL employee_number',
         (SELECT COUNT(*) FROM fact_employee WHERE employee_number IS NULL)
)
SELECT check_name, failed_rows, CASE WHEN failed_rows = 0 THEN 'PASS' ELSE 'FAIL' END AS status FROM c;
