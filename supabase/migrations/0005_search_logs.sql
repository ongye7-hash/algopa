-- 검색 로깅 — 익명 집계 (데이터 확장 우선순위 + 운영 신호)
-- 작성: 2026-05-14
--
-- 수집 정책:
--   • 검색어 + 결과 카운트 + 시각만 저장
--   • IP/User-Agent/디바이스 ID 저장 X (Supabase 클라이언트가 보내지 않음)
--   • 사용자 식별 정보 결합 키 없음 → 익명
--   • 운영자(나)는 service_role로만 조회 (anon SELECT/UPDATE/DELETE 차단)

create table public.search_logs (
  id                uuid        primary key default gen_random_uuid(),
  query             text        not null check (length(query) > 0),
  result_count      integer     not null check (result_count >= 0),
  matched_brand_id  uuid        references public.brands(id) on delete set null,
  created_at        timestamptz not null default now()
);

create index idx_search_logs_query on public.search_logs (query);
create index idx_search_logs_created_at on public.search_logs (created_at desc);

-- =========================================
-- RLS: anon INSERT만 허용
-- =========================================
alter table public.search_logs enable row level security;

create policy "search_logs_anon_insert"
  on public.search_logs for insert to anon
  with check (true);

-- =========================================
-- 운영자 분석 SQL (Supabase 대시보드 SQL Editor에서 service_role로 실행)
-- =========================================

-- 인기 검색어 TOP 20 (지난 7일)
-- select query, count(*) as cnt
-- from public.search_logs
-- where created_at > now() - interval '7 days'
-- group by query
-- order by cnt desc
-- limit 20;

-- 데이터 없는 검색어 TOP 20 (시드 확장 우선순위)
-- select query, count(*) as cnt
-- from public.search_logs
-- where result_count = 0
--   and created_at > now() - interval '7 days'
-- group by query
-- order by cnt desc
-- limit 20;

-- 일자별 검색량 (지난 30일)
-- select date_trunc('day', created_at) as day, count(*) as searches
-- from public.search_logs
-- where created_at > now() - interval '30 days'
-- group by day
-- order by day;
