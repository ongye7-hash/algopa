# ALGOPA 진행 상태

마지막 업데이트: 2026-05-13

## 현재 마일스톤
- **v0.2.0 출시** (https://github.com/ongye7-hash/algopa/releases/tag/v0.2.0)
- 브랜드 시스템 + 출시 인프라 정비 완료
- v0.1.0-mvp(검색→결과 사이클) 위에 디자인·아이콘·스플래시·legal 추가

## 완료된 작업
- 환경: Flutter 3.41.9 + Android Studio + cmdline-tools (auto install)
- Supabase 프로젝트 (Seoul) + brands(10) + discounts(59) + brand_requests
- Flutter app: 검색·결과·추가 요청 화면 + Supabase 연결 + shared_preferences
- 디자인: Material 3 (#4263EB Indigo), Pretendard 4 weight, Card/Input/CTA 일괄 테마
- UX: url_launcher (외부 브라우저), 네트워크 에러 친화 메시지 + 재시도, 빈 결과 안내 강화
- 출시 자산: app_icon (1024 Indigo+A) + flutter_launcher_icons + flutter_native_splash 적용
- legal: docs/legal/{privacy-policy,terms-of-service}.md (시행일 2026-05-15)
- git/GitHub: tag v0.1.0-mvp, v0.2.0 + GitHub release 둘 다 등록

## 지금 해야 할 것 (다음 세션 후보)
1. **GitHub Pages 활성화** — Settings → Pages → Source: main / docs
   • 결과 URL: https://ongye7-hash.github.io/algopa/legal/{privacy-policy,terms-of-service}
2. **Android release build + 서명** — `flutter build appbundle --release` + key.properties
3. **Play Console 등록 준비** — 스크린샷·설명문·카테고리·콘텐츠 등급
4. **외식 외 카테고리 시트 확장** — 별도 트랙 (Claude.ai 웹에서 시트 작업)
5. **iOS 빌드** (Mac 환경 필요)

## 주요 파일/경로
- 프로젝트 루트: `c:\Users\user\Desktop\ALGOPA\`
- Flutter 코드: `lib/{main,db,error,theme,search_screen,result_screen,request_screen}.dart`
- 마이그레이션: `supabase/migrations/0001~0004_*.sql`
- 시드 CSV: `알고파.초기시트.260512.csv` (UTF-8 또는 CP949 자동 감지)
- 자산: `assets/fonts/Pretendard-*.otf`, `assets/icon/app_icon{,_foreground}.png`
- legal: `docs/legal/*.md`
- bundle id: `kr.algopa.algopa`, version: `0.1.0+1`

## 환경변수/키 상태
- `.env` (gitignored): `SUPABASE_URL`, `SUPABASE_ANON_KEY` (sb_publishable_*)
- `JAVA_HOME` = Android Studio JBR, `ANDROID_HOME` = AppData/Local/Android/Sdk

## 외부 시스템
- Supabase 대시보드 — anon key는 코드, service_role은 운영자 (brand_requests 처리)
- GitHub: `ongye7-hash/algopa` (private), tag v0.1.0-mvp / v0.2.0

## 알려진 미해결 사항
- `is_stackable` NULL 일괄 (Phase 2에서 brands.overlap_note로 이전 예정)
- 자동 알림 X — brand_requests 처리는 운영자가 Supabase 대시보드 + 수동 contact
- iOS 미검증 (Mac 환경 필요)
- GitHub Pages 활성화는 사용자가 GitHub 웹에서 직접 설정 (마지막 미완)
