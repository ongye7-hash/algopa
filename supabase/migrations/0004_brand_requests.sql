-- MVP 화면 #3 "추가 요청" 백엔드
-- 작성: 2026-05-13
--
-- 익명 사용자가 미등록 매장 추가를 요청. 운영자는 Supabase 대시보드에서
-- service_role로 직접 조회하여 처리 (앱은 INSERT만 가능, SELECT 불가).

create table public.brand_requests (
  id          uuid        primary key default gen_random_uuid(),
  brand_name  text        not null check (length(trim(brand_name)) >= 2),
  category    text        check (category in
                ('외식','카페','쇼핑/생활','문화/레저','미용/생활서비스')),
  contact     text,
  status      text        not null default 'pending'
                check (status in
                ('pending','reviewing','added','rejected','duplicate')),
  created_at  timestamptz not null default now()
);

-- 운영자 조회용 인덱스
create index brand_requests_created_at_idx
  on public.brand_requests (created_at desc);
create index brand_requests_status_idx
  on public.brand_requests (status);

-- =========================================
-- RLS: anon INSERT 만 허용
-- (RLS enabled + 다른 정책 없음 = SELECT/UPDATE/DELETE 자동 차단)
-- =========================================
alter table public.brand_requests enable row level security;

create policy "brand_requests_anon_insert"
  on public.brand_requests
  for insert
  to anon
  with check (true);
