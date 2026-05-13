# -*- coding: utf-8 -*-
"""discounts INSERT SQL 파일에서 provider/type 분포 추출."""
import os, re, sys
from collections import Counter

try: sys.stdout.reconfigure(encoding='utf-8')
except: pass

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SQL = os.path.join(ROOT, "supabase", "migrations", "0003_seed_discounts.sql")

with open(SQL, encoding='utf-8') as f:
    text = f.read()

# 각 row 패턴: ((SELECT id FROM public.brands WHERE name = 'X'), 'provider', 'type', ...
# single-quoted 값들을 순서대로 추출 (escape '' 처리)
row_re = re.compile(
    r"\(\(SELECT id FROM public\.brands WHERE name = '((?:[^']|'')*)'\), "
    r"'((?:[^']|'')*)', "  # provider
    r"'((?:[^']|'')*)', "  # type
    , re.MULTILINE
)

providers = Counter()
types = Counter()
combos = Counter()

for m in row_re.finditer(text):
    brand, provider, dtype = m.group(1), m.group(2), m.group(3)
    providers[provider] += 1
    types[dtype] += 1
    combos[(provider, dtype)] += 1

print("=== provider 분포 ===")
for p, c in providers.most_common():
    print(f"  {c:3d}  {p}")

print("\n=== type 분포 ===")
for t, c in types.most_common():
    print(f"  {c:3d}  {t}")

print(f"\n=== 총 행: {sum(providers.values())} ===")
