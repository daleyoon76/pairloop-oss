# pairloop — 알고리즘 가이드

이 문서는 pairloop의 핵심 판단 로직 세 가지를 설명합니다.

---

## 1. 3-way 분류 엔진 (pair-watch 내장)

E2E 실패가 발생하면 창A(`/pair-watch`)는 자동으로 실패를 세 가지 유형 중 하나로 분류합니다.

### 분류 기준표

| 유형 | 마커 | 판단 기준 | 창B 처리 |
| --- | --- | --- | --- |
| **A형 — 실제 버그** | 🔴 | 프로덕션 코드가 깨진 경우. 이전 커밋에서는 통과했는데 지금 실패. | 코드 수정 후 커밋 (`git commit`) |
| **B형 — 스펙 변경** | 🟡 | UI/동작이 의도적으로 바뀐 경우. 코드는 맞는데 테스트가 낡음. | 테스트 파일 업데이트 (프로덕션 코드 금지) |
| **C형 — 테스트 불안정** | 🔵 | 타이밍/네트워크/환경 이슈. 재실행 시 통과하는 경우. | 3회 재시도 → 2+/3 실패 시 🔴로 격상 |

### 판단 흐름

```
E2E 실패 발생
    │
    ├─ 최근 커밋에서 관련 프로덕션 파일 변경됨?
    │   YES → 🔴 A형 (코드 수정 필요)
    │
    ├─ 최근 커밋에서 UI/동작 스펙이 변경됨? (의도적 변경)
    │   YES → 🟡 B형 (테스트 업데이트 필요)
    │
    └─ 위 둘 다 아님 → 🔵 C형 (재시도 후 판정)
```

### 항목 포맷

```
🔴/🟡/🔵 [YYYY-MM-DD HH:MM] <시나리오 이름> — <증상 한 줄>
```

예:
```
🔴 [2025-06-15 14:32] 로그인 플로우 — /api/auth/login 500 오류
🟡 [2025-06-15 15:01] 상품 목록 페이지 — "전체보기" 버튼 셀렉터 변경됨
🔵 [2025-06-15 15:44] 결제 완료 리다이렉트 — 간헐적 타임아웃 (3000ms)
```

---

## 2. pair-hand 품질 보장 알고리즘 (pair-hand 내장)

세션 종료 시 `/pair-hand` 를 실행하면 4블록 구조를 강제합니다.

### 4블록 구조

```markdown
## YYYY-MM-DD HH:MM — <한 줄 요약> [<작업영역>]

### 완료한 것
- <동사 원형> <구체적 파일/함수명> (5개 이하)

### 다음 세션 후보
1. <태스크> (막힌 이유 있으면 명시)
2. <태스크>
3. <태스크> (3개 이하)

### 주의사항
- pairloop/known-pitfalls.md에서 현재 작업 영역 관련 항목 자동 참조
- 단기 주의사항 (이 세션 한정)

### 현재 상태 스냅샷
- 마지막 성공 빌드: <커밋 해시> (<날짜>)
- 열린 BUG: BUG-1 (<내용>), BUG-2 (<내용>)
```

### 보존 규칙

- 최근 **10개 블록**만 유지(`pairloop/handoff.md`)
- 11번째 이후 블록은 `## Archive` 섹션으로 자동 이동
- `git add pairloop/handoff.md pairloop/to-do.md pairloop/known-pitfalls.md` 후 커밋·푸시

---

## 3. known-pitfalls 중복 방지 + ID 부여 규칙

### 신규 항목 추가 조건

1. 동일 현상이 **이미 등재**되어 있으면 → 새 항목 추가 금지, 기존 항목 `재발` 줄에 `YYYY-MM-DD {커밋 해시}` 추가
2. **2회 이상 발생**한 항목에만 공식 ID 부여
3. **6개월 이상 재발 없음** → `[해결됨]` 상태로 변경 제안

### ID 형식

```
[{bugPrefix}-{N}] <현상 한 줄>
```

`bugPrefix`는 `pairloop/pairloop.config.json`의 `project.bugPrefix` 값 (기본값: `BUG`).

예: `BUG-1`, `BUG-2`, `BUG-3` (프로젝트 전체에서 순번 공유)

### 항목 예시

```markdown
### [BUG-1] 로그인 후 리다이렉트 루프 발생

- **현상**: 로그인 성공 후 /dashboard 대신 /login으로 돌아옴
- **원인**: middleware.ts에서 세션 쿠키 도메인 불일치 (localhost vs 127.0.0.1)
- **수정**: middleware.ts:23 — `domain` 옵션 제거
- **첫 발생**: 2025-06-10 a1b2c3d
- **재발**: 2025-06-24 e4f5g6h (환경 변수 초기화 후 재현)
- **예방 체크**: 새 환경에서 로그인 테스트 시 쿠키 도메인 설정 확인
```

---

## 4. 커스터마이징 포인트

### 폴링 간격 변경

`pairloop/pairloop.config.json`의 `intervals` 섹션:
```json
"intervals": {
  "pingSec": 30,   // 기본 30초. 서버 부하가 우려되면 60으로 변경
  "gitSec": 180    // 기본 3분. 빠른 커밋 감지가 필요하면 60으로 변경
}
```

### 테스트 명령 변경

```json
"test": {
  "command": "npx playwright test e2e/critical.spec.ts --workers=1",
  "headless": true,
  "captureOnFailure": true
}
```

변경 후 `/pair-watch-stop` → `/pair-watch` 으로 재시작하면 반영됩니다.

### bugPrefix 프로젝트별 설정

```json
"project": {
  "name": "shop-api",
  "bugPrefix": "SHOP"  // known-pitfalls ID가 SHOP-1, SHOP-2, ... 형식으로 생성됨
}
```
