-- 04_analysis.sql  Business KPI queries (Spark SQL dialect). Each result is materialised as a_* table
-- and exported by run_pipeline.py to results/tables/<name>.csv.
-- Attrition rate = 100 * SUM(attrition_flag) / COUNT(*).

-- Q1 Headline KPIs
CREATE OR REPLACE TABLE a_kpi_headline AS
SELECT
  COUNT(*)                                                                  AS employees_total,
  SUM(attrition_flag)                                                       AS leavers,
  COUNT(*) - SUM(attrition_flag)                                            AS stayers,
  ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2)                          AS attrition_pct,
  ROUND(AVG(monthly_income), 2)                                             AS avg_monthly_income,
  ROUND(percentile_approx(CAST(monthly_income AS DOUBLE), 0.5), 2)          AS median_monthly_income,
  ROUND(AVG(age), 2)                                                        AS avg_age,
  ROUND(AVG(years_at_company), 2)                                           AS avg_years_at_company,
  ROUND(AVG(CAST(job_satisfaction AS DOUBLE)), 3)                           AS avg_job_satisfaction,
  ROUND(AVG(CAST(environment_satisfaction AS DOUBLE)), 3)                   AS avg_environment_satisfaction,
  ROUND(AVG(CAST(work_life_balance AS DOUBLE)), 3)                          AS avg_work_life_balance,
  ROUND(100.0 * SUM(overtime_flag) / COUNT(*), 2)                           AS overtime_pct,
  ROUND(100.0 * SUM(CASE WHEN overtime_flag = 1 THEN attrition_flag ELSE 0 END)
        / NULLIF(SUM(overtime_flag), 0), 2)                                 AS attrition_pct_overtime,
  ROUND(100.0 * SUM(CASE WHEN overtime_flag = 0 THEN attrition_flag ELSE 0 END)
        / NULLIF(SUM(CASE WHEN overtime_flag = 0 THEN 1 ELSE 0 END), 0), 2) AS attrition_pct_no_overtime,
  ROUND(AVG(CASE WHEN attrition_flag = 1 THEN monthly_income END), 2)       AS avg_income_leavers,
  ROUND(AVG(CASE WHEN attrition_flag = 0 THEN monthly_income END), 2)       AS avg_income_stayers,
  ROUND(AVG(CASE WHEN attrition_flag = 1 THEN years_at_company END), 2)     AS avg_tenure_leavers,
  ROUND(AVG(CASE WHEN attrition_flag = 0 THEN years_at_company END), 2)     AS avg_tenure_stayers
FROM fact_employee;

-- Q2 Attrition by department
CREATE OR REPLACE TABLE a_attrition_by_department AS
SELECT
  d.department_name,
  COUNT(*) AS employees,
  SUM(f.attrition_flag) AS leavers,
  ROUND(100.0 * SUM(f.attrition_flag) / COUNT(*), 2) AS attrition_pct,
  ROUND(AVG(f.monthly_income), 2) AS avg_monthly_income,
  ROUND(AVG(CAST(f.job_satisfaction AS DOUBLE)), 3) AS avg_job_satisfaction,
  ROUND(100.0 * SUM(f.overtime_flag) / COUNT(*), 2) AS overtime_pct,
  ROUND(AVG(f.years_at_company), 2) AS avg_years_at_company
FROM fact_employee f
JOIN dim_department d ON f.department_key = d.department_key
GROUP BY d.department_name;

-- Q3 Attrition by job role
CREATE OR REPLACE TABLE a_attrition_by_job_role AS
SELECT
  j.job_role,
  j.job_level,
  COUNT(*) AS employees,
  SUM(f.attrition_flag) AS leavers,
  ROUND(100.0 * SUM(f.attrition_flag) / COUNT(*), 2) AS attrition_pct,
  ROUND(AVG(f.monthly_income), 2) AS avg_monthly_income,
  ROUND(AVG(CAST(f.job_satisfaction AS DOUBLE)), 3) AS avg_job_satisfaction,
  ROUND(100.0 * SUM(f.overtime_flag) / COUNT(*), 2) AS overtime_pct
FROM fact_employee f
JOIN dim_job_role j ON f.job_role_key = j.job_role_key
GROUP BY j.job_role, j.job_level;

-- Q4 Overtime x attrition
CREATE OR REPLACE TABLE a_overtime_attrition AS
SELECT
  CASE WHEN overtime_flag = 1 THEN 'OverTime' ELSE 'No OverTime' END AS overtime_status,
  COUNT(*) AS employees,
  SUM(attrition_flag) AS leavers,
  ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_pct,
  ROUND(AVG(monthly_income), 2) AS avg_monthly_income,
  ROUND(AVG(CAST(job_satisfaction AS DOUBLE)), 3) AS avg_job_satisfaction,
  ROUND(AVG(CAST(work_life_balance AS DOUBLE)), 3) AS avg_work_life_balance
FROM fact_employee
GROUP BY 1;

-- Q5 Tenure band vs attrition
CREATE OR REPLACE TABLE a_tenure_attrition AS
SELECT
  tenure_band,
  COUNT(*) AS employees,
  SUM(attrition_flag) AS leavers,
  ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_pct,
  ROUND(AVG(monthly_income), 2) AS avg_monthly_income,
  ROUND(AVG(CAST(job_satisfaction AS DOUBLE)), 3) AS avg_job_satisfaction
FROM fact_employee
GROUP BY tenure_band;

-- Q6 Satisfaction (job) vs attrition
CREATE OR REPLACE TABLE a_satisfaction_attrition AS
SELECT
  job_satisfaction,
  CASE job_satisfaction
    WHEN 1 THEN 'Low' WHEN 2 THEN 'Medium' WHEN 3 THEN 'High' WHEN 4 THEN 'Very High'
    ELSE 'Unknown' END AS job_satisfaction_label,
  COUNT(*) AS employees,
  SUM(attrition_flag) AS leavers,
  ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_pct,
  ROUND(AVG(monthly_income), 2) AS avg_monthly_income
FROM fact_employee
GROUP BY job_satisfaction;

-- Q7 Travel frequency vs attrition
CREATE OR REPLACE TABLE a_travel_attrition AS
SELECT
  COALESCE(t.business_travel, 'Unknown') AS business_travel,
  COUNT(*) AS employees,
  SUM(f.attrition_flag) AS leavers,
  ROUND(100.0 * SUM(f.attrition_flag) / COUNT(*), 2) AS attrition_pct,
  ROUND(AVG(f.monthly_income), 2) AS avg_monthly_income,
  ROUND(100.0 * SUM(f.overtime_flag) / COUNT(*), 2) AS overtime_pct
FROM fact_employee f
LEFT JOIN dim_travel t ON f.travel_key = t.travel_key
GROUP BY 1;

-- Q8 Income band vs attrition
CREATE OR REPLACE TABLE a_income_attrition AS
SELECT
  income_band,
  COUNT(*) AS employees,
  SUM(attrition_flag) AS leavers,
  ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_pct,
  ROUND(AVG(years_at_company), 2) AS avg_years_at_company,
  ROUND(AVG(CAST(job_satisfaction AS DOUBLE)), 3) AS avg_job_satisfaction
FROM fact_employee
GROUP BY income_band;

-- Q9 Age band / demographics rollup
CREATE OR REPLACE TABLE a_age_attrition AS
SELECT
  age_band,
  COUNT(*) AS employees,
  SUM(attrition_flag) AS leavers,
  ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_pct,
  ROUND(AVG(monthly_income), 2) AS avg_monthly_income,
  ROUND(AVG(years_at_company), 2) AS avg_years_at_company
FROM fact_employee
GROUP BY age_band;

CREATE OR REPLACE TABLE a_gender_marital_attrition AS
SELECT
  gender,
  marital_status,
  COUNT(*) AS employees,
  SUM(attrition_flag) AS leavers,
  ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_pct
FROM fact_employee
GROUP BY gender, marital_status;
