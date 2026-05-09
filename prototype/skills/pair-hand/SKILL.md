---
name: pair-hand
description: "세션 종료용 — pairloop/handoff.md(4블록), pairloop/to-do.md, pairloop/known-pitfalls.md를 갱신하고 커밋·푸시한다. /pair-hand 로 실행."
user_invocable: true
---

세션 종료 시 단순 요약이 아니라 **구조화된 4블록**을 강제해서 다음 세션 Claude가 바로 이어 일할 수 있게 만든다.

이 스킬은 **종료 절차 전체를 통합**한다. 사용자는 더 이상 `/pair-watch-stop`이나 `/pair-fix-stop`을 따로 호출할 필요가 없다 — 두 개의 창 모두에서 `/pair-hand`만 부르면 된다.

---

## 실행 절차

### 0. 활성 루프 종료 + 중단 마커 생성 (먼저 실행)

**가장 먼저 `pairloop/.pairloop-stop` 파일을 생성한다.** TaskStop은 현재 창의 Task를 종료하지만 다른 창의 ScheduleWakeup 예약은 취소할 수 없다. 마커 파일이 있으면 `/pair-fix`·`/pair-watch`가 ScheduleWakeup으로 재발화되더라도 루프 진입 즉시 빠져나온다.

이 창에서 `/pair-watch` 또는 `/pair-fix` 루프가 돌고 있다면 **즉시 TaskStop을 호출해 종료한다.**

- TaskStop 호출 후 사용자에게 보고:
  ```
  이 창의 감시/수정 루프를 종료했습니다 (.pairloop-stop 마커 생성). handoff를 진행합니다.
  ```
- 진행 중인 E2E 사이클이 있다면 강제로 끊지 않는다 — 사이클 완료(분류·기록까지)를 기다린 뒤 TaskStop을 호출한다. 4분 대기 중인 ScheduleWakeup은 그대로 TaskStop으로 종료해도 무방하다.
- 같은 파일을 동시에 수정해서 충돌이 나는 것을 막기 위해, 두 개의 창에서 **동시에** `/pair-hand`를 실행하지 않도록 사용자에게 한 번만 안내한다 (창 A 먼저 → 완료 후 창 B).

### 0-b. handoff 동기화 마커 처리 (몇 번째 창인지 판단)

`pairloop/.handoff-state` 파일을 사용해 두 개의 창 중 **이번이 첫 번째 handoff인지 두 번째인지** 판단한다. 6단계 통합 리포트 출력 여부를 결정하는 데 사용된다.

먼저 이번 호출 창의 작업영역을 판단한다 — 이 창에서 `/pair-watch` 루프가 돌고 있었으면 `감시`, `/pair-fix` 루프였으면 `수정`. 이 값을 `this-window`로 사용한다.

- 마커 파일이 **없으면** → 상태를 **first**로 둔다. 다음 두 줄을 적어 마커를 만든다:
  ```
  first-at: <YYYY-MM-DDTHH:MM>
  first-window: <this-window 값>
  ```
- 마커 파일이 **있으면** 마커 내 `first-window` 값을 읽어 `this-window`와 비교한다:
  - **다른 창**이면 (예: 첫 번째가 `감시`, 이번이 `수정`) → 상태를 **second**로 둔다. 마커 내용을 컨텍스트에 보관(6단계에서 사용)한 뒤 마커 파일을 삭제한다.
  - **같은 창**이면 → **같은 창에서 두 번째 호출이 들어온 실수**다. 상태를 **duplicate**로 두고 사용자에게 다음 안내를 출력한다. 마커는 **그대로 둔다** (다른 창의 정상적인 호출이 나중에 들어올 수 있음):
    ```
    이미 이 창(<this-window>)에서 /pair-hand 가 실행됐습니다. 통합 리포트는 다른 창에서 /pair-hand 를 실행할 때 생성됩니다. 이번 호출은 4블록·to-do 갱신만 진행합니다.
    ```

이 상태(`first` / `second` / `duplicate`)를 6단계에서 참조한다.

이 마커는 git 추적에서 제외한다 — 7단계의 `git add`는 명시적 파일만 add하므로 자동으로 제외된다. 다만 사용자의 `git status`에 untracked로 보일 수 있어 무해.

### 1. 기존 파일 읽기

먼저 다음 파일을 읽는다 (없으면 빈 상태로 가정):
- `pairloop/handoff.md`
- `pairloop/to-do.md`
- `pairloop/known-pitfalls.md`
- `pairloop/result.md` (현재 열린 🔴 목록 추출용)

기존 세션 블록과 중복되지 않도록 최상단 블록의 타임스탬프·작업영역을 확인한다.

### 2. 이번 세션 작업을 4블록으로 정리

아래 4블록 구조를 **반드시** 만든다.

#### 블록 1 — 완료한 것

- 5개 이하
- 동사 원형으로 시작
- 구체적 파일명·함수명 포함
- 예: `pair-watch/SKILL.md에서 프로젝트 특화 URL 3개 제거`

#### 블록 2 — 다음 세션 후보

- 3개 이하
- 우선순위 순서로 나열
- 막혀있는 이유가 있으면 명시 (예: "X API 응답 포맷 확인 필요 — 미니프로젝트 팀 답변 대기 중")

#### 블록 3 — 주의사항

- `pairloop/known-pitfalls.md`에서 **현재 작업 영역과 관련된 항목**을 자동 참조한다.
- 다음 세션 Claude가 "이미 알고 있는 함정"을 무시하고 같은 실수를 반복하지 않도록 ID/제목을 옮겨 적는다.
- 예: `[BUG-{prefix}-3] Playwright headless 모드에서 dialog 자동 dismiss됨 — accept 핸들러 등록 필수`

#### 블록 4 — 현재 상태 스냅샷

- 마지막으로 성공한 빌드 커밋 해시 (`git log --oneline -1` 결과)
- 열려 있는 🔴 목록 (`pairloop/result.md`에서 ✅ 처리되지 않은 🔴 줄 그대로)
- 예:
  ```
  마지막 빌드: abc1234 "feat: ..."
  열린 🔴: 없음 / 또는 목록
  ```

### 3. pairloop/handoff.md 최상단에 새 블록 삽입

블록 헤더 포맷:
```
## YYYY-MM-DD HH:MM — <한줄 요약> [<작업영역>]
```

작업영역은 예: `prototype/skills`, `lib`, `docs`, `infra` 등.

새 블록을 파일 **최상단**(기존 블록 위)에 삽입한다.

### 4. 보존 규칙

`pairloop/handoff.md`에 블록이 **10개를 초과**하면 가장 오래된 블록을 잘라내고 `## Archive` 섹션으로 이동한다.
`## Archive` 섹션은 파일 하단에 위치하며, 그 안에서도 최신순으로 유지한다.

### 5. pairloop/to-do.md 업데이트

이번 세션에서 완료된 항목을 ✅로 변경한다 (체크박스가 있으면 `[x]`).
새로 발생한 후속 태스크가 있으면 우선순위에 맞춰 추가한다.

### 6. 통합 E2E 작업 리포트 생성 (두 번째 handoff에서만)

0-b 단계의 상태가 **second**가 아닌 경우 이 단계는 **건너뛴다.**

- 상태가 **first**이면 짧은 안내만 출력하고 7단계로 진행:
  ```
  첫 번째 창 handoff 완료. 다른 창에서 /pair-hand 를 실행하면 통합 리포트가 출력됩니다.
  ```
- 상태가 **duplicate**이면 0-b에서 이미 안내했으므로 추가 출력 없이 7단계로 진행.

상태가 **second**면 다음 두 가지를 수행한다 (본문 박스는 두 출력 모두 100% 동일).

#### 6-a. 화면 출력 (즉시 확인)

아래 박스를 사용자 화면에 출력한다.

```
═══════════════════════════════════════════════════════════════
  E2E 세션 리포트  ({YYYY-MM-DD HH:MM} ~ {YYYY-MM-DD HH:MM} / {경과시간})
═══════════════════════════════════════════════════════════════

📊 E2E 실행 통계
  ├ 사이클 수: {N}회
  ├ 🟢 통과: {N}사이클
  ├ 🔴 실제 버그: {N}건 발견
  ├ 🟡 스펙 변경: {N}건
  └ 🔵 불안정: {N}건 (→ 🔴 격상 {a}건, 🟢 정리 {b}건)

🔧 처리 결과
  ├ ✅ 🔴 자동 수정: {a}/{N}
  ├ ✅ 🟡 테스트 갱신: {b}/{M}
  └ ❌ 자동 수정 실패: {c}건

📚 known-pitfalls 신규 등재
  ├ {bugPrefix}-{n}: <한 줄 요약>
  └ ...
  (없으면 "(없음)")

📝 git 활동
  ├ 커밋: {N}건
  └ 마지막 빌드: {hash7} "{메시지 한 줄}"

📋 잔여 미해결
  ├ 🔴 ...
  ├ 🟡 ...
  (없으면 "(없음)")

📌 다음 세션 후보
  1. ...
  2. ...
═══════════════════════════════════════════════════════════════
✓ 리포트 저장됨 → pairloop/reports/e2e-report-{YYYY-MM-DD-HHMM}.md
```

값이 0이거나 해당 없는 줄은 "(없음)" 또는 그 줄 자체를 생략해 깔끔하게 유지한다.

#### 6-b. md 파일로 저장 (보존·누적)

같은 박스 내용을 다음 위치에 md 파일로 Write한다.

```bash
mkdir -p pairloop/reports
# 파일 경로: pairloop/reports/e2e-report-{YYYY-MM-DD-HHMM}.md
```

- `YYYY-MM-DD-HHMM`: 두 번째 `/pair-hand` 호출 시각, 24시간 표기·콜론 없음 (예: `2026-04-28-1445`).
- 파일 본문은 화면 박스와 동일하되 상단에 메타 헤더를 둔다:
  ```markdown
  # E2E 세션 리포트 — {YYYY-MM-DD HH:MM}

  > 자동 생성 by `/pair-hand` (두 번째 창)
  > 세션 기간: {시작} ~ {종료} ({경과시간})
  > 관련 커밋 범위: {first-commit-hash}..{last-commit-hash}
  > 프로젝트: {pairloop.config.json의 project.name}

  ---

  (본문 박스 — 화면 출력과 100% 동일)
  ```

데이터 출처·디자인 결정 등 자세한 규칙은 패키지에 동봉된 `prototype/docs/e2e-report-guideline.md` 참조.

### 7. 커밋 및 푸시

다음을 **순서대로** 실행:

```bash
git add pairloop/handoff.md pairloop/to-do.md pairloop/known-pitfalls.md
# 두 번째 handoff에서 6-b로 새 리포트가 생성됐다면 reports/도 함께 add
[ -d pairloop/reports ] && git add pairloop/reports/
git commit -m "docs: update pairloop tracking docs (<작업영역>)"
git push
```

`-A` 옵션은 사용하지 않는다 (의도치 않은 파일이 함께 커밋되는 것을 방지).
pairloop/known-pitfalls.md를 이번에 수정하지 않았으면 add 대상에서 제외한다.
첫 번째 handoff에서는 `reports/`가 없으므로 위 add 라인은 자연 스킵된다.

### 8. 최종 상태 확인

```bash
git status
```

출력 결과를 사용자에게 보여주고 깨끗한 상태(working tree clean) 또는 추적되지 않은 파일만 남았는지 확인한다.

---

## 구현 참고

- 4블록을 빠뜨리면 안 된다. 이번 세션에 해당 블록에 넣을 내용이 정말 없으면 `(해당 없음)` 한 줄을 명시적으로 적는다.
- 동일 세션 안에서 `/pair-hand`를 두 번 실행할 경우, 같은 타임스탬프 블록을 새로 만들지 말고 기존 최상단 블록을 갱신한다.
- 푸시 실패 시 사용자에게 사유를 보고하고 종료한다 (force push 금지).
