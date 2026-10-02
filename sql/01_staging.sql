-- 01_staging.sql
-- Land the raw CSV as an all-STRING staging table (no type inference).
-- {{RAW_DIR}} is substituted by run_pipeline.py.
-- DuckDB : read_csv(path, header = true, all_varchar = true)
-- Databricks equivalent (used in databricks/hr_pipeline_notebook.sql):
--   SELECT * FROM read_files('/Volumes/<catalog>/<schema>/raw/emp_attrition.csv', format => 'csv',
--          header => true, multiLine => true, escape => '"', inferColumnTypes => false)
CREATE OR REPLACE TABLE stg_employee AS
SELECT * FROM read_csv('{{RAW_DIR}}/emp_attrition.csv', header = true, all_varchar = true);
