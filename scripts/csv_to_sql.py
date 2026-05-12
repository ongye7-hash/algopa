# -*- coding: utf-8 -*-
"""
CSV → Supabase INSERT SQL 변환기 (v2: 외식+카페 통합 시트, 13컬럼)

- 입력 : ../알고파.초기시트.260512.csv  (UTF-8 또는 CP949 자동 감지)
- 출력 : ../supabase/migrations/0002_seed_brands.sql
         ../supabase/migrations/0003_seed_discounts.sql
         ../supabase/migrations/_sample_first10.sql
         ../supabase/migrations/_skipped_rows.log (skip된 행 있을 때)

CSV 컬럼 (위치 기반, 헤더 텍스트 무시):
  0 No. / 1 브랜드 / 2 카테고리 / 3 할인 제공처 / 4 할인유형 / 5 혜택 상세
  6 대상·조건 / 7 한도·횟수 / 8 중복 적용(무시→NULL) / 9 적용 기간
  10 출처 URL / 11 수집일 / 12 비고(무시)

처리 룰:
  - 빈값 마커 ('', '—', '-', 'ㅡ', '?', 'N/A') → NULL
  - 핵심 컬럼(브랜드/카테고리/출처URL) 중 하나라도 NULL → 행 SKIP + log
  - 카테고리는 5개 enum으로 매핑. 모르는 값 만나면 abort + 사용자 알림
  - is_stackable: 모든 행 NULL 일괄 (자유 메모 컬럼 false positive 회피)
  - conditions = 대상·조건 + ' | 기간: ' + 적용기간 (있는 것만)
"""
import csv
import os
import sys
from datetime import datetime

# Windows 콘솔에서 한글 print 깨짐 방지
try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CSV_PATH = os.path.join(ROOT, "알고파.초기시트.260512.csv")
OUT_DIR = os.path.join(ROOT, "supabase", "migrations")
SKIP_LOG = os.path.join(OUT_DIR, "_skipped_rows.log")

# === 카테고리 매핑 — 모르는 값 만나면 raise (사용자 결정 필요) ===
CATEGORY_MAP = {
    '카페': '카페',
}
FOOD_CATEGORIES = {
    '패밀리레스토랑', '한식', '분식', '죽', '햄버거', '양식', '이탈리안',
    '아시안', '중식', '일식', '베이커리', '간식', '뷔페', '치킨', '피자',
    '한식 (죽)', '한식 (죽) - 본몰',
}

EMPTY_MARKERS = {'', '—', '-', 'ㅡ', '?', '–', 'N/A', 'n/a'}


def normalize(s):
    if s is None:
        return None
    s = s.strip()
    return None if s in EMPTY_MARKERS else s


def map_category(raw):
    s = raw.strip()
    if s in CATEGORY_MAP:
        return CATEGORY_MAP[s]
    if s in FOOD_CATEGORIES:
        return '외식'
    raise ValueError(
        f"Unknown category '{s}'. "
        f"Add it to CATEGORY_MAP or FOOD_CATEGORIES in csv_to_sql.py."
    )


def read_csv_auto(path):
    """UTF-8 → CP949 자동 감지."""
    for enc in ('utf-8', 'cp949'):
        try:
            with open(path, 'r', encoding=enc, newline='') as f:
                rows = list(csv.reader(f))
            print(f"[INFO] CSV decoded as: {enc}")
            return rows
        except UnicodeDecodeError:
            continue
    raise RuntimeError(f"Could not decode {path} as UTF-8 or CP949")


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


def main():
    rows = read_csv_auto(CSV_PATH)

    # 첫 3줄(제목/부연/빈줄) 건너뛰고 4번째가 헤더, 5번째부터 데이터
    header = rows[3]
    print(f"[INFO] Header column count: {len(header)}")
    data_rows = [r for r in rows[4:] if r and normalize(r[0]) is not None]
    print(f"[INFO] Data rows (non-empty No.): {len(data_rows)}")

    skipped = []
    valid = []  # list of (row, name, mapped_category)

    for r in data_rows:
        if len(r) < 12:
            skipped.append((r[0] if r else '?', f"too few columns ({len(r)})"))
            continue
        no = r[0].strip()
        name = normalize(r[1])
        cat_raw = normalize(r[2])
        src = normalize(r[10])
        if name is None:
            skipped.append((no, "missing 브랜드"))
            continue
        if cat_raw is None:
            skipped.append((no, "missing 카테고리"))
            continue
        if src is None:
            skipped.append((no, "missing 출처 URL"))
            continue
        try:
            cat = map_category(cat_raw)
        except ValueError as e:
            print(f"[ABORT] Row No.{no} ({name}): {e}", file=sys.stderr)
            sys.exit(2)
        valid.append((r, name, cat))

    # ---------- brands ----------
    brands = {}  # name -> category (마지막 등장 기준)
    for _, name, cat in valid:
        brands[name] = cat

    brand_lines = [
        "-- 자동 생성: scripts/csv_to_sql.py",
        "-- 원본: 알고파.초기시트.260512.csv (외식+카페 10개)",
        "",
        "INSERT INTO public.brands (name, category) VALUES",
    ]
    brand_values = [
        f"  ({sql_str(name)}, {sql_str(cat)})"
        for name, cat in brands.items()
    ]
    brand_lines.append(",\n".join(brand_values) + ";")
    with open(os.path.join(OUT_DIR, "0002_seed_brands.sql"), 'w',
              encoding='utf-8') as f:
        f.write("\n".join(brand_lines) + "\n")

    # ---------- discounts ----------
    def row_to_values(r, name):
        provider = normalize(r[3]) or ''
        dtype = normalize(r[4]) or ''
        rate = normalize(r[5])
        target_cond = normalize(r[6])
        limit_amt = normalize(r[7])
        # r[8] 중복 적용 → NULL 일괄
        period = normalize(r[9])
        source_url = normalize(r[10])
        updated_at = normalize(r[11])

        parts = []
        if target_cond is not None:
            parts.append(target_cond)
        if period is not None:
            parts.append(f"기간: {period}")
        conditions = ' | '.join(parts) if parts else None

        return (
            f"  ((SELECT id FROM public.brands WHERE name = {sql_str(name)}), "
            f"{sql_str(provider)}, {sql_str(dtype)}, {sql_str(rate)}, "
            f"{sql_str(limit_amt)}, {sql_str(conditions)}, NULL, "
            f"{sql_str(source_url)}, {sql_date(updated_at)})"
        )

    all_values = [row_to_values(r, name) for r, name, _ in valid]
    sample_values = all_values[:10]

    disc_header = [
        "-- 자동 생성: scripts/csv_to_sql.py",
        "-- 원본: 알고파.초기시트.260512.csv",
        "",
        "INSERT INTO public.discounts "
        "(brand_id, provider, type, rate, limit_amount, conditions, "
        "is_stackable, source_url, updated_at) VALUES",
    ]
    with open(os.path.join(OUT_DIR, "0003_seed_discounts.sql"), 'w',
              encoding='utf-8') as f:
        f.write("\n".join(disc_header) + "\n")
        f.write(",\n".join(all_values) + ";\n")

    sample_header = [
        "-- 사용자 검토용 샘플 (처음 10행). 검토 후 0003_seed_discounts.sql 실행.",
        "",
        "INSERT INTO public.discounts "
        "(brand_id, provider, type, rate, limit_amount, conditions, "
        "is_stackable, source_url, updated_at) VALUES",
    ]
    with open(os.path.join(OUT_DIR, "_sample_first10.sql"), 'w',
              encoding='utf-8') as f:
        f.write("\n".join(sample_header) + "\n")
        f.write(",\n".join(sample_values) + ";\n")

    # ---------- skipped log ----------
    if skipped:
        with open(SKIP_LOG, 'w', encoding='utf-8') as f:
            for no, reason in skipped:
                f.write(f"No.{no}: {reason}\n")

    # ---------- summary ----------
    print()
    print("=== Done ===")
    print(f"Valid discount rows: {len(all_values)}")
    print(f"Brands             : {len(brands)}")
    for name, cat in brands.items():
        print(f"  - {name} ({cat})")
    print(f"Skipped rows       : {len(skipped)}")
    if skipped:
        print(f"  See {SKIP_LOG} for details")


if __name__ == '__main__':
    main()
