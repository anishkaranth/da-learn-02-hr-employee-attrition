# Clean sample

Regenerate with:

```bash
pip install -r requirements.txt
python run_pipeline.py --source sample
```

Writes `data/clean/cleaned/employee.csv` (78 rows) and `powerbi/data/*.csv`.
For full clean tables: `python scripts/download_full_data.py && python run_pipeline.py --source full`.
