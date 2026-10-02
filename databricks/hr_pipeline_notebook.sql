-- Databricks notebook source
-- MAGIC %md
-- MAGIC # HR employee attrition analysis - SQL pipeline (Databricks SQL)
-- MAGIC **Status: executed on Databricks** (serverless SQL warehouse).
-- MAGIC Full generated notebook with inlined SQL is produced by `python scripts/build_databricks.py --with-dashboard`.
-- MAGIC Schema: `workspace.da_learn_02`. Volume: `/Volumes/workspace/da_learn_02/raw/emp_attrition.csv`.

-- COMMAND ----------

CREATE SCHEMA IF NOT EXISTS workspace.da_learn_02;
USE CATALOG workspace;
USE SCHEMA da_learn_02;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 01 Staging

-- COMMAND ----------

CREATE OR REPLACE TABLE stg_employee AS
SELECT *
FROM read_files('/Volumes/workspace/da_learn_02/raw/emp_attrition.csv',
  format => 'csv', header => true, multiLine => true, escape => '"', inferColumnTypes => false);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 02-05 — paste / run statements from repo `sql/02_cleaning.sql`, `sql/03_model.sql`, `sql/04_analysis.sql`, `sql/05_quality_checks.sql` (Spark SQL dialect).
-- MAGIC Or regenerate the full inlined notebook locally: `python scripts/build_databricks.py --with-dashboard`.

-- COMMAND ----------

SELECT * FROM a_kpi_headline;

-- COMMAND ----------

SELECT * FROM dq_assertions ORDER BY status, check_name;
