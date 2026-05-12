# ALGOPA 진행 상태

마지막 업데이트: 2026-05-13

## 현재 마일스톤
- **v0.1.0-mvp 출시** (https://github.com/ongye7-hash/algopa/releases/tag/v0.1.0-mvp)
- MVP 화면 3개 모두 동작 검증 (Chrome web + Z Flip3 5G 실기기)

## 완료된 작업
- 환경: Flutter 3.41.9 + Android Studio + cmdline-tools (auto install) + JAVA_HOME/ANDROID_HOME
- Supabase 프로젝트 (Seoul ap-northeast-2) + brands(10) + discounts(59) + brand_requests
- Flutter app: 검색·결과·추가 요청 화면 + Supabase 연결 + shared_preferences
- git/GitHub: private repo `ongye7-hash/algopa` (main), tag `v0.1.0-mvp`

## 지금 해야 할 것 (다음 세션 후보)
1. **Android release build + 서명** — `flutter build apk --release` + key.properties 셋업
2. **외식/쇼핑/문화/미용 카테고리 시트 확장** — 별도 트랙 (Claude.ai 웹에서 시트 작업 → CSV export → `python scripts/csv_to_sql.py` → 0002/0003 재생성 → Supabase TRUNCATE+재적재)
3. **iOS 빌드** (Mac 클라우드 또는 macOS 환경 필요)
4. **디자인 시스템 적용** — `C:\Users\user\Downloads\design-system-showcase.jsx` 참고

## 주요 파일/경로
- 프로젝트 루트: `c:\Users\user\Desktop\ALGOPA\`
- Flutter 코드: `lib/{main,db,search_screen,result_screen,request_screen}.dart`
- 마이그레이션: `supabase/migrations/0001~0004_*.sql`
- CSV→SQL 스크립트: `scripts/csv_to_sql.py` (UTF-8/CP949 자동 감지)
- 시드 CSV: `알고파.초기시트.260512.csv`
- Supabase 가이드: `supabase/SETUP.md`
- bundle id: `kr.algopa.algopa`

## 환경변수/키 상태
- `.env` (gitignored): `SUPABASE_URL`, `SUPABASE_ANON_KEY` (publishable 형식)
- `.env.example` (committed): 자리표시자 템플릿
- 시스템: `JAVA_HOME` = Android Studio JBR, `ANDROID_HOME` = `~/AppData/Local/Android/Sdk`

## 외부 시스템
- Supabase 대시보드 (anon key는 코드/UI에 노출, service_role은 운영자만 — brand_requests 조회용)
- GitHub: `ongye7-hash/algopa` (private)

## 알려진 미해결 사항
- `is_stackable` 컬럼: 모든 행 NULL (Phase 2에서 brands.overlap_note로 이전 예정)
- 자동 알림 X — brand_requests 처리는 운영자가 Supabase 대시보드 + 수동 contact 발송
- Web/Android만 검증, iOS 미검증
