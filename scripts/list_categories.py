# -*- coding: utf-8 -*-
"""CSV의 모든 카테고리·브랜드 unique 값 추출"""
import csv
import os
import sys
from collections import OrderedDict

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

CSV_PATH = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "..", "알고파.초기시트.260512.csv"))

for enc in ('utf-8', 'cp949'):
    try:
        with open(CSV_PATH, 'r', encoding=enc, newline='') as f:
            rows = list(csv.reader(f))
        break
    except UnicodeDecodeError:
        continue

# 4번째 줄이 헤더, 5번째부터 데이터
data_rows = [r for r in rows[4:] if r and r[0].strip()]

# 브랜드 → 카테고리들 (각 브랜드가 어떤 카테고리에 분류됐는지)
brand_to_cats = OrderedDict()
for r in data_rows:
    if len(r) < 3:
        continue
    name = r[1].strip()
    cat = r[2].strip()
    if not name or not cat:
        continue
    brand_to_cats.setdefault(name, set()).add(cat)

# 모든 unique 카테고리
all_cats = sorted({c for cats in brand_to_cats.values() for c in cats})

print("=== Unique 카테고리 값 ===")
for c in all_cats:
    print(f"  '{c}'")

print()
print("=== 브랜드별 카테고리 ===")
for name, cats in brand_to_cats.items():
    print(f"  {name}: {sorted(cats)}")
