#!/usr/bin/env python3
"""Download the full IBM HR Employee Attrition CSV into data/raw_full/ and verify SHA-256.

Canonical Kaggle: https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset
Public mirror (IBM AIF360): https://raw.githubusercontent.com/IBM/employee-attrition-aif360/master/data/emp_attrition.csv
Licence (per IBM AIF360 notes): Open Database License (ODbL) + Database Contents License (DbCL).
A UTF-8 BOM present on the mirror is stripped so the first column is named Age.
"""
import hashlib, pathlib, urllib.request

MIRROR = "https://raw.githubusercontent.com/IBM/employee-attrition-aif360/master/data/emp_attrition.csv"
# SHA-256 of the file AFTER stripping a leading UTF-8 BOM (if present)
SHA256 = "df7985d643392e2a09fd66a1833d9bb1fc4a6525ffd3934cb61926b4590201e2"
NAME = "emp_attrition.csv"

out = pathlib.Path(__file__).resolve().parents[1] / "data" / "raw_full"
out.mkdir(parents=True, exist_ok=True)
p = out / NAME
if not p.exists():
    print("downloading", NAME)
    urllib.request.urlretrieve(MIRROR, p)
data = p.read_bytes()
if data.startswith(b"\xef\xbb\xbf"):
    p.write_bytes(data[3:])
    print("stripped UTF-8 BOM")
got = hashlib.sha256(p.read_bytes()).hexdigest()
print(f"{NAME:42s} {'OK' if got == SHA256 else 'CHECKSUM MISMATCH ' + got}")
if got != SHA256:
    raise SystemExit(1)
