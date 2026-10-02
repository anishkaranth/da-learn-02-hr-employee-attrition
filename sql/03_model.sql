-- 03_model.sql  Star schema (Spark SQL dialect)
CREATE OR REPLACE TABLE dim_department AS
SELECT CAST(ROW_NUMBER() OVER (ORDER BY department) AS INT) AS department_key, department AS department_name
FROM (SELECT DISTINCT department FROM cln_employee) d;

CREATE OR REPLACE TABLE dim_job_role AS
SELECT CAST(ROW_NUMBER() OVER (ORDER BY job_role, job_level) AS INT) AS job_role_key, job_role, job_level
FROM (SELECT DISTINCT job_role, job_level FROM cln_employee) j;

CREATE OR REPLACE TABLE dim_education AS
SELECT CAST(ROW_NUMBER() OVER (ORDER BY education, education_field) AS INT) AS education_key, education AS education_level, education_label, education_field
FROM (SELECT DISTINCT education, education_label, education_field FROM cln_employee) e;

CREATE OR REPLACE TABLE dim_travel AS
SELECT CAST(ROW_NUMBER() OVER (ORDER BY business_travel) AS INT) AS travel_key, business_travel
FROM (SELECT DISTINCT business_travel FROM cln_employee WHERE business_travel IS NOT NULL) t;

CREATE OR REPLACE TABLE fact_employee AS
SELECT e.employee_number, d.department_key, j.job_role_key, ed.education_key, t.travel_key, e.attrition_flag, e.age, e.age_band, e.gender, e.marital_status, e.overtime_flag, e.monthly_income, e.income_band, e.hourly_rate, e.daily_rate, e.monthly_rate, e.percent_salary_hike, e.stock_option_level, e.distance_from_home, e.distance_band, e.environment_satisfaction, e.job_satisfaction, e.relationship_satisfaction, e.work_life_balance, e.job_involvement, e.performance_rating, e.total_working_years, e.years_at_company, e.tenure_band, e.years_in_current_role, e.years_since_last_promotion, e.years_with_curr_manager, e.num_companies_worked, e.training_times_last_year, e.is_income_outlier_iqr3, e.is_income_top1pct, e.dq_tenure_gt_career, e.dq_role_gt_company, e.dq_manager_gt_company, e.dq_promo_gt_company, e.dq_bad_age, e.dq_missing_attrition
FROM cln_employee e
JOIN dim_department d ON e.department = d.department_name
JOIN dim_job_role j ON e.job_role = j.job_role AND e.job_level = j.job_level
JOIN dim_education ed ON e.education = ed.education_level AND e.education_field = ed.education_field
LEFT JOIN dim_travel t ON e.business_travel = t.business_travel;
