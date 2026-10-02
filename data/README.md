# Data

| Folder | Content | In git? |
|---|---|---|
| `raw/` | **Reproducible subset** of the raw IBM HR CSV (original columns, values copied verbatim) | yes |
| `clean/cleaned/` | Cleaned employee table from `sql/02_cleaning.sql`, run on the subset | yes |
| `raw_full/` | Full CSV (~228 KB) - `python scripts/download_full_data.py` | no (`.gitignore`) |
| `clean_full/` | Cleaned + star-schema tables from the full run (`--source full`) | no (`.gitignore`) |

The star-schema tables from the full run (dataset is small) are also in `../powerbi/data/`.

## Source
* Original: **IBM HR Analytics Employee Attrition & Performance** - https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset
* Also known as `WA_Fn-UseC_-HR-Employee-Attrition.csv` (~1,470 rows, ~35 columns)
* Licence (per IBM AIF360 notes): **Open Database License (ODbL)** for the database + **Database Contents License (DbCL)** for the contents
* Mirror used: https://raw.githubusercontent.com/IBM/employee-attrition-aif360/master/data/emp_attrition.csv (UTF-8 BOM stripped on download; SHA-256 pinned in `scripts/download_full_data.py`)

## Why a subset in git
The full file is only ~228 KB, but this series publishes through a text-oriented GitHub API and keeps a documented sample + download script for consistency with larger projects. **All numbers in `results/` come from the FULL dataset** (1,470 employees).

## Subset rule (`scripts/make_sample.py`, deterministic)
Keep rows where `CAST(EmployeeNumber AS INT) % 20 = 1` → **78 employees** (~5.3% of the population).
