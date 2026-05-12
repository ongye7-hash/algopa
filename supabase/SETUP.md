# Supabase 프로젝트 설정 가이드

이 문서는 ALGOPA MVP의 백엔드(Supabase) 1회성 셋업을 안내한다.
모두 끝나면 Flutter 앱이 anon key로 brands/discounts를 읽을 수 있는 상태가 된다.

---

## 1. Supabase 가입 및 프로젝트 생성

1. https://supabase.com 접속 → **Sign up** (GitHub 계정 권장 — 추후 CI 연동 편함)
2. 대시보드 → **New project** 클릭
3. 입력값:
   | 항목 | 값 |
   |------|-----|
   | **Organization** | (없으면) Personal 자동 생성 |
   | **Project name** | `algopa` |
   | **Database password** | 강력한 무작위 (16자+) → **반드시 1Password 등에 저장**. 분실 시 복구 불가, 재생성만 가능 |
   | **Region** | **`Northeast Asia (Seoul) — ap-northeast-2`** |
   | **Pricing plan** | Free (월 500MB DB, 5GB 대역폭 — MVP에 충분) |
4. **Create new project** → 약 1~2분 대기 (프로비저닝)

---

## 2. SQL 마이그레이션 실행 (3개 파일, 순서대로)

대시보드 좌측 사이드바 → **SQL Editor** → **+ New query** 클릭. 아래 3개 파일을 **순서대로** 붙여넣고 각각 **Run** (Ctrl+Enter).

### 2-1. `supabase/migrations/0001_init_schema.sql`
- 확장(`pgcrypto`, `pg_trgm`) + brands/discounts 테이블 + 인덱스 + RLS 정책 생성
- 결과: "Success. No rows returned"

### 2-2. `supabase/migrations/0002_seed_brands.sql`
- 카페 10개 브랜드 INSERT
- 결과: "Success. 10 rows affected"

### 2-3. `supabase/migrations/0003_seed_discounts.sql`
- 45개 할인 행 INSERT (브랜드별 평균 4.5건)
- 결과: "Success. 45 rows affected"

### 검증 (선택)
SQL Editor에 다음 실행:
```sql
select b.name, count(d.*) as discount_count
from public.brands b
left join public.discounts d on d.brand_id = b.id
group by b.name
order by b.name;
```
→ 10개 브랜드 모두 1개 이상의 할인이 잡혀야 함.

---

## 3. API 키 위치 확인 (Flutter에서 사용)

대시보드 좌측 → **Project Settings** (톱니바퀴) → **API** 탭.

| 항목 | 위치 | 용도 |
|------|------|------|
| **Project URL** | `Project URL` 필드 | `https://xxxx.supabase.co` 형식 — Flutter `Supabase.initialize`의 url |
| **anon public** | `Project API keys → anon public` | 모바일 앱에 박는 공개 키 (RLS 정책 + read-only이므로 노출 안전) |
| **service_role** | `Project API keys → service_role` | ⚠️ **절대 모바일 앱에 박지 말 것**. 서버/CI에서만 사용. RLS 우회됨 |

7단계에서 위 두 값을 `.env` 파일에 저장한다. **이 단계에서는 메모만 해두면 됨**.

---

## 4. RLS 동작 빠른 확인 (SQL Editor)

```sql
-- anon role로 SELECT 시뮬레이션
set role anon;
select count(*) from public.brands;     -- 10
select count(*) from public.discounts;  -- 45
reset role;

-- anon role로 INSERT 시도 (실패해야 함)
set role anon;
insert into public.brands (name, category) values ('해킹시도', '카페');
-- 에러: "new row violates row-level security policy for table \"brands\""
reset role;
```
RLS가 제대로 동작하면 INSERT는 막히고 SELECT만 통과한다.

---

## 5. 끝났을 때 알려줘야 할 것

위 1~3 끝내고 나에게 다음 두 값을 알려주면 7단계 이어간다.

```
SUPABASE_URL = https://xxxxxxxx.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

⚠️ anon key도 GitHub public repo에는 푸시하지 말 것 (RLS는 1차 방어선이지만, 모범사례). `.env` 통해서만 다룬다 — 7단계에서 처리.

---

## 트러블슈팅

| 증상 | 원인 / 해결 |
|------|-------------|
| `extension "pg_trgm" does not exist` | Supabase 대시보드 → Database → Extensions → `pg_trgm` 검색 후 Enable. 그 후 0001 재실행 |
| `relation "public.brands" already exists` | 이미 0001 실행됨. SQL Editor에서 `drop table public.discounts cascade; drop table public.brands cascade;` 후 재시작 |
| 0003 실행 시 `null value in column "brand_id"` | 0002를 안 돌렸음. 순서대로 0001 → 0002 → 0003 |
| 한글이 ?로 보임 | SQL Editor에 붙여넣을 때 인코딩 문제 — 파일을 메모장 X, VS Code/Sublime 등 UTF-8 인식 가능한 에디터에서 열어 복사 |
