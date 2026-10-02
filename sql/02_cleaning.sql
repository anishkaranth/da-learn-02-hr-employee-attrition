-- 02_cleaning.sql  (Spark SQL dialect; runs on DuckDB via 00_duckdb_compat.sql shims)
-- Steps: trim/standardize text -> type casting -> null handling -> dedupe
--        -> derived bands / flags -> outlier flags -> integrity filters.
-- Constant columns EmployeeCount=1, Over18=Y, StandardHours=80 are dropped from the clean grain
-- (kept as dq_* evidence that they never vary).

CREATE OR REPLACE TABLE cln_employee AS
WITH typed AS (
  SELECT
    TRY_CAST(Age AS INT)                                              AS age,
    CASE WHEN lower(trim(Attrition)) IN ('yes', 'y', '1', 'true') THEN 1
         WHEN lower(trim(Attrition)) IN ('no', 'n', '0', 'false') THEN 0
         ELSE NULL END                                                AS attrition_flag,
    CASE lower(replace(trim(BusinessTravel), ' ', '_'))
         WHEN 'travel_rarely' THEN 'Travel_Rarely'
         WHEN 'travel_frequently' THEN 'Travel_Frequently'
         WHEN 'non-travel' THEN 'Non-Travel'
         WHEN 'non_travel' THEN 'Non-Travel'
         ELSE NULLIF(trim(BusinessTravel), '') END                    AS business_travel,
    TRY_CAST(DailyRate AS INT)                                        AS daily_rate,
    NULLIF(trim(Department), '')                                      AS department,
    TRY_CAST(DistanceFromHome AS INT)                                 AS distance_from_home,
    TRY_CAST(Education AS INT)                                        AS education,
    NULLIF(trim(EducationField), '')                                  AS education_field,
    TRY_CAST(EmployeeCount AS INT)                                    AS employee_count,
    TRY_CAST(EmployeeNumber AS INT)                                   AS employee_number,
    TRY_CAST(EnvironmentSatisfaction AS INT)                          AS environment_satisfaction,
    CASE WHEN lower(trim(Gender)) IN ('male', 'm') THEN 'Male'
         WHEN lower(trim(Gender)) IN ('female', 'f') THEN 'Female'
         ELSE NULLIF(trim(Gender), '') END                            AS gender,
    TRY_CAST(HourlyRate AS INT)                                       AS hourly_rate,
    TRY_CAST(JobInvolvement AS INT)                                   AS job_involvement,
    TRY_CAST(JobLevel AS INT)                                         AS job_level,
    NULLIF(trim(JobRole), '')                                         AS job_role,
    TRY_CAST(JobSatisfaction AS INT)                                  AS job_satisfaction,
    CASE WHEN lower(trim(MaritalStatus)) IN ('married', 'single', 'divorced')
         THEN concat(upper(substr(trim(MaritalStatus), 1, 1)), lower(substr(trim(MaritalStatus), 2)))
         ELSE NULLIF(trim(MaritalStatus), '') END                     AS marital_status,
    TRY_CAST(MonthlyIncome AS INT)                                    AS monthly_income,
    TRY_CAST(MonthlyRate AS INT)                                      AS monthly_rate,
    TRY_CAST(NumCompaniesWorked AS INT)                               AS num_companies_worked,
    upper(trim(Over18))                                               AS over18,
    CASE WHEN lower(trim(OverTime)) IN ('yes', 'y', '1', 'true') THEN 1
         WHEN lower(trim(OverTime)) IN ('no', 'n', '0', 'false') THEN 0
         ELSE NULL END                                                AS overtime_flag,
    TRY_CAST(PercentSalaryHike AS INT)                                AS percent_salary_hike,
    TRY_CAST(PerformanceRating AS INT)                                AS performance_rating,
    TRY_CAST(RelationshipSatisfaction AS INT)                         AS relationship_satisfaction,
    TRY_CAST(StandardHours AS INT)                                    AS standard_hours,
    TRY_CAST(StockOptionLevel AS INT)                                 AS stock_option_level,
    TRY_CAST(TotalWorkingYears AS INT)                                AS total_working_years,
    TRY_CAST(TrainingTimesLastYear AS INT)                            AS training_times_last_year,
    TRY_CAST(WorkLifeBalance AS INT)                                  AS work_life_balance,
    TRY_CAST(YearsAtCompany AS INT)                                   AS years_at_company,
    TRY_CAST(YearsInCurrentRole AS INT)                               AS years_in_current_role,
    TRY_CAST(YearsSinceLastPromotion AS INT)                          AS years_since_last_promotion,
    TRY_CAST(YearsWithCurrManager AS INT)                             AS years_with_curr_manager
  FROM stg_employee
), ranked AS (
  SELECT *, ROW_NUMBER() OVER (
    PARTITION BY employee_number
    ORDER BY attrition_flag DESC, monthly_income DESC
  ) AS rn
  FROM typed
  WHERE employee_number IS NOT NULL
), bounds AS (
  SELECT
    percentile_approx(CAST(monthly_income AS DOUBLE), 0.25) AS q1,
    percentile_approx(CAST(monthly_income AS DOUBLE), 0.75) AS q3,
    percentile_approx(CAST(monthly_income AS DOUBLE), 0.99) AS p99
  FROM ranked WHERE rn = 1 AND monthly_income IS NOT NULL AND monthly_income > 0
)
SELECT
  r.employee_number,
  r.attrition_flag,
  r.age,
  r.gender,
  r.marital_status,
  r.department,
  r.job_role,
  r.job_level,
  r.education,
  CASE r.education
    WHEN 1 THEN 'Below College' WHEN 2 THEN 'College' WHEN 3 THEN 'Bachelor'
    WHEN 4 THEN 'Master' WHEN 5 THEN 'Doctor' ELSE 'Unknown' END        AS education_label,
  r.education_field,
  r.business_travel,
  r.overtime_flag,
  r.monthly_income,
  r.hourly_rate,
  r.daily_rate,
  r.monthly_rate,
  r.percent_salary_hike,
  r.stock_option_level,
  r.distance_from_home,
  r.environment_satisfaction,
  r.job_satisfaction,
  r.relationship_satisfaction,
  r.work_life_balance,
  r.job_involvement,
  r.performance_rating,
  r.total_working_years,
  r.years_at_company,
  r.years_in_current_role,
  r.years_since_last_promotion,
  r.years_with_curr_manager,
  r.num_companies_worked,
  r.training_times_last_year,
  CASE WHEN r.age < 25 THEN '01: <25' WHEN r.age < 35 THEN '02: 25-34'
       WHEN r.age < 45 THEN '03: 35-44' WHEN r.age < 55 THEN '04: 45-54'
       ELSE '05: 55+' END                                               AS age_band,
  CASE WHEN r.years_at_company < 2 THEN '01: <2 y'
       WHEN r.years_at_company < 5 THEN '02: 2-4 y'
       WHEN r.years_at_company < 10 THEN '03: 5-9 y'
       WHEN r.years_at_company < 15 THEN '04: 10-14 y'
       ELSE '05: 15+ y' END                                             AS tenure_band,
  CASE WHEN r.monthly_income < 3000 THEN '01: <3k'
       WHEN r.monthly_income < 5000 THEN '02: 3-5k'
       WHEN r.monthly_income < 8000 THEN '03: 5-8k'
       WHEN r.monthly_income < 15000 THEN '04: 8-15k'
       ELSE '05: 15k+' END                                              AS income_band,
  CASE WHEN r.distance_from_home <= 5 THEN '01: 0-5 km'
       WHEN r.distance_from_home <= 10 THEN '02: 6-10 km'
       WHEN r.distance_from_home <= 20 THEN '03: 11-20 km'
       ELSE '04: 21+ km' END                                            AS distance_band,
  CASE WHEN CAST(r.monthly_income AS DOUBLE) > b.q3 + 3 * (b.q3 - b.q1) THEN 1 ELSE 0 END AS is_income_outlier_iqr3,
  CASE WHEN CAST(r.monthly_income AS DOUBLE) > b.p99 THEN 1 ELSE 0 END  AS is_income_top1pct,
  CASE WHEN r.years_at_company > r.total_working_years THEN 1 ELSE 0 END AS dq_tenure_gt_career,
  CASE WHEN r.years_in_current_role > r.years_at_company THEN 1 ELSE 0 END AS dq_role_gt_company,
  CASE WHEN r.years_with_curr_manager > r.years_at_company THEN 1 ELSE 0 END AS dq_manager_gt_company,
  CASE WHEN r.years_since_last_promotion > r.years_at_company THEN 1 ELSE 0 END AS dq_promo_gt_company,
  CASE WHEN r.age IS NULL OR r.age < 18 OR r.age > 70 THEN 1 ELSE 0 END AS dq_bad_age,
  CASE WHEN r.attrition_flag IS NULL THEN 1 ELSE 0 END                  AS dq_missing_attrition,
  CASE WHEN COALESCE(r.employee_count, 1) <> 1 THEN 1 ELSE 0 END        AS dq_nonconstant_employee_count,
  CASE WHEN COALESCE(r.over18, 'Y') <> 'Y' THEN 1 ELSE 0 END            AS dq_nonconstant_over18,
  CASE WHEN COALESCE(r.standard_hours, 80) <> 80 THEN 1 ELSE 0 END      AS dq_nonconstant_standard_hours
FROM ranked r CROSS JOIN bounds b
WHERE r.rn = 1
  AND r.attrition_flag IS NOT NULL
  AND r.department IS NOT NULL
  AND r.job_role IS NOT NULL
  AND r.monthly_income IS NOT NULL AND r.monthly_income > 0
  AND r.age IS NOT NULL AND r.age BETWEEN 18 AND 70;
