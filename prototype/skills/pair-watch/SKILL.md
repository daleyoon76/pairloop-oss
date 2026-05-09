---
name: pair-watch
description: "창 A 감시 루프 — 미해결 버그가 없을 때 E2E 전체 실행, 실패는 3-way로 분류해 pairloop/result.md에 기록. /pair-watch 로 시작."
user_invocable: true
---

E2E 테스트를 자동으로 반복 실행하는 **창 A 전용** 루프다.
**코드 수정은 하지 않는다. 실행·분류·기록만 한다.**
수정은 창 B의 `/pair-fix`가 담당한다.

---

## 0. 설정 로드

프로젝트 루트의 `pairloop/pairloop.config.json`을 읽는다.

필요한 값:
- `project.bugPrefix` — 버그 ID 접두사 (예: `BUG`)
- `watch.pingUrl` — 헬스체크 엔드포인트
- `watch.gitBranch` — 감시할 브랜치
- `test.command` — 테스트 실행 명령
- `test.headless` — 헤드리스 모드 여부 (생략 시 기본 true)
- `test.captureOnFailure` — 실패 시 trace/screenshot/video 자동 저장 여부 (생략 시 기본 true)
- `intervals.pingSec` — 핑 주기 (기본 30)
- `intervals.gitSec` — git fetch 주기 (기본 180)

**파일이 없으면 즉시 중단하고 출력:**
```
pairloop/pairloop.config.json을 찾을 수 없습니다.
프로젝트 루트에서 install-pairloop 스크립트를 먼저 실행해 주세요.
```

**콘솔 캡처 확인:**
`pairloop/console-capture.ts`가 있는지 확인한다.
- **있으면**: 콘솔 로그 수집 활성. 실패 항목 기록 시 `pairloop/console-logs/` 아래 대응 파일을 찾아 로그를 첨부한다.
- **없으면**: 콘솔 로그 없이 진행. `install-pairloop` 스크립트를 다시 실행하면 파일이 복사된다.

`pairloop/console-capture.ts`가 있으면 — 최초 실행 시 한 번만 아래를 출력한다:
```
ℹ️  콘솔 캡처 활성화됨.
    아직 테스트 파일의 import를 바꾸지 않았다면 교체해 주세요 (한 번만):
      변경 전: import { test, expect } from '@playwright/test';
      변경 후: import { test, expect } from '../pairloop/console-capture';
    (경로는 테스트 파일 위치에 맞게 조정)
```

---

## 1. 시나리오 파일 확인 (0단계)

프로젝트 루트에서 `pairloop/test-scenario.md`를 찾는다.

**파일이 비어 있거나 템플릿 그대로(`<!--` 주석만 있거나 헤더만 있음)이면 → 자동 생성 모드 진입.**
**파일에 실제 시나리오 내용이 있으면 → "파일이 있으면" 절로 이동.**

### 1-a. 자동 생성 모드 — 시나리오 파일이 없거나 비어 있을 때

**반드시 한 번에 한 질문씩 출력하고 사용자 답을 받은 뒤에야 다음 질문으로 진행한다.** 4개를 한 번에 표나 목록으로 나열하면 사용자가 어떤 형식으로 답해야 할지 혼란스러우니 절대 그렇게 하지 않는다.

각 질문은 `[N/4] 제목` 헤더로 시작하고, 한 번에 하나씩만 보여준다. 사용자 답을 받은 뒤에야 다음 질문 출력.

**질문 1 — 참조 파일**
```
참조할 기존 시나리오/요구사항 md 파일이 있나요?
(예: docs/scenarios.md, requirements/user-flows.md 등)
경로를 입력하거나 Enter로 건너뛰세요.
```
- 사용자가 경로를 입력하면 Read 도구로 그 파일을 읽어 컨텍스트에 보관한다.
- 파일이 없거나 읽을 수 없으면 "해당 경로의 파일을 찾을 수 없습니다. 건너뜁니다." 출력 후 다음 질문으로 진행.
- Enter만 누르면 건너뛴다.

**질문 2 — 서비스 한 줄 설명**
```
이 서비스를 한 줄로 설명해주세요.
(예: "Next.js 기반 미니 블로그 플랫폼", "Express 백엔드 + React 관리자 페이지")
```

**질문 3 — 핵심 플로우 (3개 이내)**
```
가장 중요한 사용자 플로우를 1~3개만 알려주세요. 줄바꿈으로 구분하면 됩니다.
(예:
  1. 회원가입 → 로그인 → 대시보드 진입
  2. 글 작성 → 발행 → 공유
)
Enter만 누르면 참조 파일에서 자동 추출합니다.
```

**질문 4 — 테스트 계정 (선택)**
```
테스트에 쓸 계정 정보가 있다면 알려주세요. (없으면 Enter)
형식: 역할: 이메일 / 비밀번호
(예:
  일반: test@example.com / pass1234
  관리자: admin@example.com / admin1234
)
```

**자동 작성**
- 위 4가지 답변과 (입력된 경우) 참조 파일 내용을 바탕으로 `pairloop/test-scenario.md`를 작성한다.
- 기존에 있던 빈 템플릿 파일 구조(`§0 harness-config`, `§1 시나리오 목록`)를 따른다.
- 우선순위(Critical/High/Medium)도 자동 부여한다 (사용자가 처음 적은 플로우 = Critical).
- 작성 완료 후 사용자에게 보고:
  ```
  ✓ pairloop/test-scenario.md 작성 완료 — {N}개 시나리오 ({Critical 수} Critical)
  내용을 확인하시려면 파일을 열어 검토해주세요. 곧 감시 루프를 시작합니다.
  ```
- 그대로 다음 절(파일이 있으면)로 진행한다.

### 1-b. 파일이 있으면
- `pairloop/.pairloop-stop` 파일이 남아 있으면 삭제한다 (이전 세션 잔재).
- `§0 harness-config` JSON 블록 파싱 → `baseUrl`, `accounts` 로드
- `§1` 시나리오 목록을 우선순위 순(Critical → High → Medium)으로 정렬
- 한 번만 출력 후 메인 루프 진입:
  ```
  시나리오 로드 완료 — {N}개 ({Critical 수} Critical)
  감시 루프 시작

  ─────────────────────────────────────────────────────────────
  ** 이제부터 이 곳이 창A입니다. E2E 테스트 루프가 시작되었습니다 **
  ─────────────────────────────────────────────────────────────

  지금 창B를 띄워주세요:

    1. 사용 중인 IDE(VS Code, Cursor 등)에서 'New Window' 메뉴로
       이 프로젝트의 새 창을 하나 더 엽니다.
    2. 새 창에서 같은 프로젝트 폴더를 엽니다.
    3. 새 창에서 Claude Code를 실행한 뒤 다음을 입력하세요:

       ▶  /pair-fix

  창B가 시작되면 두 개의 창이 자동으로 협업합니다.
  창A는 실패를 감지·기록하고, 창B는 그 항목을 위에서부터 자동 수정합니다.
  ```

---

## 2. 메인 루프

아래 순서를 무한 반복한다. 4분 대기는 ScheduleWakeup(delaySeconds=240)을 사용한다.

### 2-a. 중단 마커 확인 + 미해결 항목 확인

**루프 진입 시 가장 먼저** `pairloop/.pairloop-stop` 파일이 있는지 확인한다.
- **있으면** → 파일을 삭제하고 즉시 루프를 종료한다:
  ```
  ✅ handoff 완료 감지 — 감시 루프를 종료합니다.
  ```
- **없으면** → 계속 진행한다.

`pairloop/result.md`를 읽어 🔴 또는 🟡로 시작하는 줄 중 ✅ 처리되지 않은 항목 수를 센다.

**🔴 미해결 항목이 1개 이상 있으면:**
아래를 출력하고 ScheduleWakeup(delaySeconds=240)으로 4분 대기 후 2-a로 복귀.
**E2E를 실행하지 않는다.**
```
🔴 N건 미해결 — 창 B 처리 대기 중. 4분 후 재확인.
```

**미해결 항목이 없으면:** 2-b로 이동.

### 2-b. E2E 실행

`pairloop/result.md` 상단에 진행 표시:
```
⏳ E2E 실행 중 (YYYY-MM-DD HH:MM)
```

**개발 서버 자동 시작 (test.devServerCommand가 설정된 경우):**
1. `watch.pingUrl`로 GET 요청을 보내 서버가 이미 실행 중인지 확인한다.
2. 응답이 없으면: `test.devServerCommand`를 백그라운드에서 실행하고, `watch.pingUrl`이 응답할 때까지 2초 간격으로 최대 30초 대기한다.
   - 서버 시작 중 출력: `🚀 개발 서버 시작 중... (최대 30초)`
   - 서버 준비 완료 출력: `✓ 서버 준비 완료`
   - 30초 후에도 응답 없으면: `⚠️ 서버 응답 없음 — 테스트를 계속 진행합니다` 출력 후 테스트 진행
3. 응답이 있으면: 서버가 이미 실행 중이므로 바로 테스트로 진행한다.

`pairloop/pairloop.config.json`의 `test.command`를 실행한다. 명령 끝에 아래 플래그를 조건부로 자동 부착한다.

- **헤드 모드**: `test.headless`가 `false`이면 `--headed`를 추가한다. `true`이거나 값이 없으면 추가하지 않는다 (Playwright 기본값이 headless).
- **실패 캡처**: `test.captureOnFailure`가 `false`가 아니면(즉 `true`이거나 값이 없으면) 다음 3개 플래그를 추가한다.
  - `--trace=retain-on-failure`
  - `--screenshot=only-on-failure`
  - `--video=retain-on-failure`

  결과물은 Playwright 기본 출력 폴더(`test-results/`)에 저장된다. 실패한 케이스만 보관되므로 디스크 부담은 작다. 헤드리스로 돌렸어도 사후에 다음 명령으로 마치 라이브로 본 것처럼 재생할 수 있다.

  ```
  npx playwright show-trace test-results/<케이스>/trace.zip
  ```

  `test.captureOnFailure`가 명시적으로 `false`이면 위 3개 플래그를 추가하지 않는다 (사용자 본인의 `playwright.config.ts` 설정을 그대로 따른다는 뜻).

시나리오 순서·계정 정보는 `pairloop/test-scenario.md`에서 가져온다.

**실패 시 안내 출력 (captureOnFailure 활성 + 1개 이상 실패한 경우):**
```
📁 실패 케이스 캡처 → test-results/ (npx playwright show-trace 로 재생 가능)
```

### 2-c. 3-way 분류 판단 트리

각 실패 시나리오에 대해 아래를 순서대로 적용한다.

**1단계: pairloop/known-pitfalls.md 검색**
- 현상 패턴이 기존 항목과 일치하는가?
  - **YES** → 해당 항목의 "반복 해시"(재발 날짜·커밋 해시) 갱신, C형 가능성 먼저 재평가
  - **NO** → 신규 항목 후보로 2단계 진행

**2단계: A형 / B형 / C형 판단**

판단 기준:

| 유형 | 기준 | 처리 |
|------|------|------|
| **A형 🔴 실제 버그** | 직전 커밋에서 통과 + 최신 커밋에서 실패 + `git diff`와 실패 내용 연관성 있음 | pairloop/known-pitfalls.md 등재 후보 (2회 재발 시 `{bugPrefix}-N` 부여) + pairloop/result.md에 🔴 기록 |
| **B형 🟡 스펙 변경** | 의도된 UI/동작 변경으로 인한 실패 + 커밋 메시지 또는 pairloop/to-do.md에 관련 항목 존재 | pairloop/known-pitfalls.md에 메모 (버그 아님, 테스트 업데이트 필요) + pairloop/result.md에 🟡 기록 |
| **C형 🔵 테스트 함정** | 코드 변경 없음 + 타이밍/선택자 문제 의심 + 동일 조건 재실행 시 통과 가능성 | pairloop/result.md에 🔵 기록 (창 B가 3회 재시도 후 2회 이상 실패 시 🔴로 격상 판단) |

**기록 포맷 (`pairloop/result.md`의 `## 미해결` 섹션 최상단에 추가):**
```
🔴 [YYYY-MM-DD HH:MM] <시나리오 이름> — <증상 한 줄> (<커밋 diff 연관성>)
   콘솔: <첫 번째 에러 메시지> [+N줄 더] — pairloop/console-logs/<파일명>.txt
🟡 [YYYY-MM-DD HH:MM] <시나리오 이름> — 스펙 변경으로 인한 실패 (<관련 커밋 메시지>)
🔵 [YYYY-MM-DD HH:MM] <시나리오 이름> — 간헐 실패 의심 (재시도 대기 중)
```

`콘솔:` 줄은 `pairloop/console-capture.ts`가 있고, `pairloop/console-logs/` 아래 해당 시나리오 이름으로 된 `.txt` 파일이 있을 때만 추가한다. 없으면 생략한다.

**전체 통과 시:**
```
🟢 [YYYY-MM-DD HH:MM] 전체 통과 ({시나리오 수}개)
```

**3단계: 결과 보고**
분류 결과와 근거를 한 줄로 출력:
```
완료: 🟢{N} 🔴{N} 🟡{N} 🔵{N} — 4분 후 재확인
```

### 2-d. 루프 복귀

ScheduleWakeup(delaySeconds=240)으로 4분 대기 후 2-a로 돌아간다.

---

## 3. 중지

- `/pair-watch-stop` 실행 시 → 현재 사이클 완료 후 종료 (해당 스킬이 처리)
- 사용자가 "중지", "스탑", "stop" 입력 시 → 현재 사이클이 끝나면 즉시 TaskStop으로 종료

루프 도중에는 강제로 끊지 않는다. 진행 중인 E2E 사이클은 반드시 완주시킨다.

---

## 구현 참고

- 미해결 판정 기준: `pairloop/result.md`에서 🔴로 시작하는 줄이 ✅로 바뀌지 않은 채 남아 있으면 미해결.
- 창 B(`/pair-fix`)가 처리 완료한 항목은 ✅로 바뀌므로 다음 사이클부터 카운트에서 제외된다.
- 세션이 닫히면 루프도 종료된다 (24/7 감시는 이 스킬의 범위 밖이다).
- `pairloop/test-scenario.md`가 없는 상태에서 시작해도 안내 후 대기하므로 강제 종료하지 않는다.
