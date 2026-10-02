#!/usr/bin/env python3
"""Build a reproducible raw subset in data/raw/ from data/raw_full/emp_attrition.csv.
Rule: CAST(EmployeeNumber AS INT) % 20 = 1 (~78 rows).
"""
import pathlib, duckdb
ROOT = pathlib.Path(__file__).resolve().parents[1]
FULL, OUT = ROOT / "data/raw_full", ROOT / "data/raw"
OUT.mkdir(parents=True, exist_ok=True)
src = (FULL / "emp_attrition.csv").as_posix()
dst = (OUT / "emp_attrition.csv").as_posix()
con = duckdb.connect()
con.execute(f"""COPY (SELECT * FROM read_csv('{src}', header = true, all_varchar = true) WHERE TRY_CAST(EmployeeNumber AS INT) % 20 = 1 ORDER BY TRY_CAST(EmployeeNumber AS INT)) TO '{dst}' (HEADER, DELIMITER ',')""")
n = con.execute(f"SELECT COUNT(*) FROM read_csv('{dst}', header = true, all_varchar = true)").fetchone()[0]
print(f"emp_attrition.csv {n} rows")
