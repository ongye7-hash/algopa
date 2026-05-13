# -*- coding: utf-8 -*-
"""
문화/레저 카테고리 시드 SQL 생성기 (마이그레이션 0007).

입력 : ../data/culture_leisure_cleaned.csv (UTF-8 BOM, 13컬럼)
출력 : ../supabase/migrations/0007_seed_culture_leisure.sql
정책 : generate_shopping_life.py와 동일 (정제 룰 + ON CONFLICT)
"""
import csv
import os
import sys
from datetime import datetime

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CSV_PATH = os.path.join(ROOT, "data", "culture_leisure_cleaned.csv")
OUT_SQL = os.path.join(
    ROOT, "supabase", "migrations", "0007_seed_culture_leisure.sql"
)
SKIP_LOG = os.path.join(
    ROOT, "supabase", "migrations", "_skipped_culture_leisure.log"
)

CATEGORY = '문화/레저'
EMPTY_MARKERS = {'', '—', '-', 'ㅡ', '?', '–', 'N/A', 'n/a'}


def normalize(s):
    if s is None:
        return None
    s = s.strip()
    return None if s in EMPTY_MARKERS else s


def sql_str(s):
    if s is None:
        return 'NULL'
    return "'" + s.replace("'", "''") + "'"


def sql_date(s):
    if s is None:
        return 'NULL'
    try:
        d = datetime.strptime(s, '%Y-%m-%d')
        return f"'{d.strftime('%Y-%m-%d')}T00:00:00+09:00'"
    except ValueError:
        return 'NULL'


def read_csv_auto(path):
    for enc in ('utf-8-sig', 'utf-8', 'cp949'):
        try:
            with open(path, 'r', encoding=enc, newline='') as f:
                rows = list(csv.reader(f))
            print(f"[INFO] decoded as {enc}")
            return rows
        except UnicodeDecodeError:
            continue
    raise RuntimeError(f"Could not decode {path}")


def main():
    rows = read_csv_auto(CSV_PATH)

    header_idx = None
    for i, r in enumerate(rows):
        if r and r[0].strip() == 'No.':
            header_idx = i
            break
    if header_idx is None:
        raise RuntimeError("Header row 'No.' not found")

    data_rows = [
        r for r in rows[header_idx + 1:]
        if r and normalize(r[0]) is not None
    ]
    print(f"[INFO] header at row {header_idx + 1}, data rows: {len(data_rows)}")

    skipped = []
    valid = []

    for r in data_rows:
        if len(r) < 12:
            skipped.append((r[0] if r else '?', f"too few columns ({len(r)})"))
            continue
        no = r[0].strip()
        name = normalize(r[1])
        dtype = normalize(r[4]) or ''
        rate = normalize(r[5])
        target = normalize(r[6])
        limit_amt = normalize(r[7])
        period = normalize(r[9])
        src = normalize(r[10])
        note = normalize(r[12]) if len(r) > 12 else None

        if name is None:
            skipped.append((no, "missing 브랜드"))
            continue
        if src is None:
            skipped.append((no, "missing 출처 URL"))
            continue
        if '미게재' in dtype or (note is not None and '미게재' in note):
            skipped.append((no, f"미게재: {name} / dtype={dtype} / note={note}"))
            continue
        if rate is None and target is None and limit_amt is None and period is None:
            skipped.append((no, f"실질 정보 0: {name} / {dtype}"))
            continue
        valid.append((r, name))

    brands_seen = []
    for _, name in valid:
        if name not in brands_seen:
            brands_seen.append(name)

    out = []
    out.append("-- 문화/레저 카테고리 시드 (0007)")
    out.append("-- 작성: 2026-05-14")
    out.append("-- 원본: data/culture_leisure_cleaned.csv")
    out.append("-- 정책: brands ON CONFLICT (name) DO NOTHING — 중복 SKIP")
    out.append("")
    out.append("INSERT INTO public.brands (name, category) VALUES")
    brand_vals = [f"  ({sql_str(name)}, {sql_str(CATEGORY)})" for name in brands_seen]
    out.append(",\n".join(brand_vals))
    out.append("ON CONFLICT (name) DO NOTHING;")
    out.append("")
    out.append("INSERT INTO public.discounts "
               "(brand_id, provider, type, rate, limit_amount, conditions, "
               "is_stackable, source_url, updated_at) VALUES")

    disc_vals = []
    for r, name in valid:
        provider = normalize(r[3]) or ''
        dtype = normalize(r[4]) or ''
        rate = normalize(r[5])
        target_cond = normalize(r[6])
        limit_amt = normalize(r[7])
        period = normalize(r[9])
        source_url = normalize(r[10])
        updated_at = normalize(r[11])

        parts = []
        if target_cond is not None:
            parts.append(target_cond)
        if period is not None:
            parts.append(f"기간: {period}")
        conditions = ' | '.join(parts) if parts else None

        disc_vals.append(
            f"  ((SELECT id FROM public.brands WHERE name = {sql_str(name)}), "
            f"{sql_str(provider)}, {sql_str(dtype)}, {sql_str(rate)}, "
            f"{sql_str(limit_amt)}, {sql_str(conditions)}, NULL, "
            f"{sql_str(source_url)}, {sql_date(updated_at)})"
        )
    out.append(",\n".join(disc_vals) + ";")

    with open(OUT_SQL, 'w', encoding='utf-8') as f:
        f.write("\n".join(out) + "\n")

    if skipped:
        with open(SKIP_LOG, 'w', encoding='utf-8') as f:
            for no, reason in skipped:
                f.write(f"No.{no}: {reason}\n")

    print()
    print("=== Done ===")
    print(f"brands     : {len(brands_seen)}")
    for b in brands_seen:
        print(f"  - {b}")
    print(f"discount   : {len(valid)}")
    print(f"skipped    : {len(skipped)}")
    if skipped:
        print(f"  see: {SKIP_LOG}")


if __name__ == '__main__':
    main()
