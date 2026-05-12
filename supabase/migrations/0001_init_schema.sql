-- ALGOPA MVP 초기 스키마
-- 작성일: 2026-05-12
-- 변경사항: discounts.is_stackable 추가 (MVP 화면 #2 "중복 여부" 표시용)

-- =========================================
-- 0. 확장
-- =========================================
create extension if not exists "pgcrypto";  -- gen_random_uuid
create extension if not exists "pg_trgm";   -- 한글 부분 검색 GIN 인덱스

-- =========================================
-- 1. brands (매장/브랜드)
-- =========================================
create table public.brands (
  id          uuid        primary key default gen_random_uuid(),
  name        text        not null unique,
  category    text        not null
                check (category in ('외식','카페','쇼핑/생활','문화/레저','미용/생활서비스')),
  created_at  timestamptz not null default now()
);

create index brands_name_trgm_idx
  on public.brands using gin (name gin_trgm_ops);

-- =========================================
-- 2. discounts (할인 정보)
-- =========================================
create table public.discounts (
  id            uuid        primary key default gen_random_uuid(),
  brand_id      uuid        not null references public.brands(id) on delete cascade,
  provider      text        not null,
  type          text        not null,
  rate          text,
  limit_amount  text,
  conditions    text,
  is_stackable  boolean,
  source_url    text,
  updated_at    timestamptz not null default now()
);

create index discounts_brand_id_idx on public.discounts(brand_id);

-- =========================================
-- 3. RLS — 익명 읽기 허용 (MVP는 read-only public)
-- =========================================
alter table public.brands    enable row level security;
alter table public.discounts enable row level security;

create policy "brands_anon_read"    on public.brands    for select to anon using (true);
create policy "discounts_anon_read" on public.discounts for select to anon using (true);
