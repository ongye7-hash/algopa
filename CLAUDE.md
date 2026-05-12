# ALGOPA Project Context

## What
모바일 앱. 매장명 검색 → 해당 매장에서 사용 가능한 모든 할인(카드사/통신사/쿠폰사/자체 멤버십) 표시.
슬로건: "오늘 어디가세요? 알고파로 확인하자"
사용 모먼트: "어디 갈까?" 결정 직전 (5분~24시간 전). 1회 평균 3~10초.

## Tech Stack (LOCKED — 대안 제안 금지)
- Framework: Flutter (iOS + Android 동시)
- Backend: Supabase (PostgreSQL)
- 추가 패키지/라이브러리 도입 전 반드시 사용자 승인 받을 것

## Database Schema (LOCKED)
brands(id, name, category)
discounts(id, brand_id, provider, type, rate, limit_amount, conditions, source_url, updated_at)

## Data Scope
- 5 카테고리: 외식, 카페, 쇼핑/생활, 문화/레저, 미용/생활서비스
- ~350 프랜차이즈/체인 브랜드 × 평균 5할인 = ~1,750행
- 브랜드 단위만 (지점별 데이터 X)
- 동네 가게/소상공인 X
- 공식 홈페이지 정보만, 월 1회 갱신

## MVP — 화면 3개 고정
1. 검색 화면: 검색창 + 최근 검색 + 추천 검색어
2. 결과 화면: 매장명 + 할인 리스트(provider/type/rate/limit/conditions) + 출처 링크
3. 추가 요청 화면: 없는 매장 신청 + 24시간 알림 약속

(Note: 중복 여부 표시는 Phase 2로 미룸 — brands.overlap_note 컬럼 추가 시 도입.
 이유: 시트 "중복여부" 컬럼이 자유 메모로 운영되어 자동 매핑 false positive 다수.
 §9 거짓 정보 금지 원칙에 따라 MVP에서는 표시하지 않음.)

## NEVER DO
- 다른 아이디어 제안 (피벗 거부 결정 완료)
- 매장 광고비/유료 입점/프리미엄 구독/데이터 판매
- MVP에 SNS·결제·다른 매장 추천 추가
- 임의로 라이브러리 추가
- 아키텍처 결정을 묻지 않고 진행
- 디자인 다듬기에 시간 소모 (동작 우선)

## Business Model (참고)
1순위: 카드 신규 발급 제휴 마케팅
보조: 통신사 멤버십, 간편결제 가입 유도

## Communication Rules
- 각 단계 끝나면 결과 보여주고 다음 진행 여부 묻고 멈출 것
- 의심 가는 부분은 추측하지 말고 질문할 것
- 에러는 그대로 보여줄 것 (추측 수정 금지)
- 한국어 응답 선호

## User Context
- 1인 창업가, Phase 3 시작 (2026-05-12)
- Claude Max 20x (토큰 여유 OK)
- 약점: 분석 과잉/실행 지연 → 푸시 필요
