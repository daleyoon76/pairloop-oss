---
name: pairloop-install
description: "pairloop 설치를 Claude Code 한 번 실행으로 끝낸다. ZIP 자동 탐색·압축 해제, 스킬 6개 + 템플릿 + schema 복사, pairloop.config.json 6개 질문 대화, 종료 후 자동으로 /pair-watch 절차로 진입. /pairloop-install 로 실행."
user_invocable: true
---

사용자가 컴퓨터 어딘가에 받아둔 `pairloop-v*.zip`을 찾아 자동 설치한다. 사용자는 슬래시 한 번만 입력하면 되도록, 외부 install/setup 스크립트의 동작을 이 스킬 안에서 직접 수행한다.

**전제 조건:**
- 사용자가 **테스트 대상 프로젝트의 루트 폴더**에서 Claude Code를 실행한 상태 (= 현재 cwd가 프로젝트 루트).
- 사용자 컴퓨터 어딘가에 `pairloop-v*.zip`이 다운로드되어 있는 상태.

---

## 0. 안내 + 상황 확인

다음을 출력하고 사용자에게 한 번에 보고한다.

```
pairloop 설치를 시작합니다.

이 스킬은 다음을 자동으로 처리합니다:
  1. ZIP 자동 탐색 + 압축 해제
  2. 스킬 6개 → ~/.claude/skills/ 복사
  3. 템플릿 5개 + schema → 이 프로젝트의 pairloop/ 복사
  4. 6가지 질문에 답하면 pairloop/pairloop.config.json 자동 작성
  5. 끝나면 자동으로 /pair-watch 감시 루프로 진입

현재 cwd가 테스트 대상 프로젝트의 루트 폴더가 맞는지 확인합니다.
```

`pwd` 결과를 출력해서 사용자에게 보여주고, 다른 폴더에서 실행했으면 중단을 권유한다.

---

## 1. ZIP 탐색 + 압축 해제

### 1-a. ZIP 위치 자동 탐색

다음 후보 위치에서 가장 최신 `pairloop-v*.zip`을 찾는다.

- macOS/Linux: `~/Downloads/pairloop-v*.zip`
- Windows (WSL/Git Bash 환경 포함): `$HOME/Downloads/pairloop-v*.zip`, `/mnt/c/Users/$USER/Downloads/pairloop-v*.zip`

Bash 명령 예시:
```bash
ls -t ~/Downloads/pairloop-v*.zip 2>/dev/null | head -1
```

찾으면 사용자에게 확인:
```
다음 ZIP 파일을 찾았습니다: ~/Downloads/pairloop-v0.8.x.zip
이 파일로 설치를 진행할까요? (Y/n)
```

### 1-b. ZIP 위치 수동 입력

자동 탐색 실패 또는 사용자가 다른 ZIP을 쓰겠다고 하면, 절대 경로를 묻는다.

```
ZIP 파일의 절대 경로를 입력해주세요.
(예: ~/Downloads/pairloop-v0.8.x.zip, C:\Users\me\Downloads\pairloop-v0.8.x.zip)
```

### 1-c. 압축 해제

ZIP이 위치한 폴더 안에 `pairloop/` 폴더를 만들고 그 안에 압축 해제한다.

```bash
ZIP_PATH="<사용자 ZIP 경로>"
ZIP_DIR="$(dirname "$ZIP_PATH")"
TARGET="$ZIP_DIR/pairloop"
mkdir -p "$TARGET"
unzip -o "$ZIP_PATH" -d "$TARGET"
```

이미 `pairloop/` 폴더가 존재하면 사용자에게 덮어쓸지 묻는다 (기본 N).

압축 해제가 끝나면 `$TARGET/VERSION` 내용을 출력해 사용자에게 어떤 버전이 설치 중인지 알린다.

---

## 2. 스킬 6개 복사 → `~/.claude/skills/`

복사 대상: `pair-watch`, `pair-watch-stop`, `pair-fix`, `pair-fix-stop`, `pair-hand`, `pairloop-install` (자기 자신 포함)

```bash
SKILLS_SRC="$TARGET/skills"
SKILLS_DST="$HOME/.claude/skills"
mkdir -p "$SKILLS_DST"
for name in pairloop-install pair-watch pair-watch-stop pair-fix pair-fix-stop pair-hand; do
  cp -rf "$SKILLS_SRC/$name" "$SKILLS_DST/"
done
```

이미 같은 이름의 스킬이 `~/.claude/skills/`에 있으면 **덮어쓴다** (사용자가 이미 설치를 시작한 시점이라 최신 버전 의도가 명확).

---

## 3. 템플릿 5개 + schema 복사 → 프로젝트의 `pairloop/`

복사 대상: `handoff.md`, `known-pitfalls.md`, `to-do.md`, `result.md`, `test-scenario.md`, `pairloop.config.schema.json`

```bash
PROJECT_ROOT="$(pwd)"
mkdir -p "$PROJECT_ROOT/pairloop"
for t in handoff.md known-pitfalls.md to-do.md result.md test-scenario.md; do
  if [[ ! -e "$PROJECT_ROOT/pairloop/$t" ]]; then
    cp "$TARGET/templates/$t" "$PROJECT_ROOT/pairloop/$t"
  fi
done
cp -f "$TARGET/pairloop.config.schema.json" "$PROJECT_ROOT/pairloop/pairloop.config.schema.json"
```

기존에 동일 파일이 있으면 **건너뛴다** (사용자 작성물 보존). schema는 항상 덮어쓴다 (IDE 자동완성용).

---

## 4. `pairloop.config.json` 6개 질문 + 직접 작성

### 4-a. 기존 설정 처리 (재설치·재실행 케이스)

`pairloop/pairloop.config.json`이 이미 존재하면 다음 두 가지를 **순서대로** 묻는다 (한 번에 한 질문씩).

**[기존 설정] 기존 설정을 유지할까요? (Y/n)**
- Y(기본) → 4-b 6개 질문 단계는 스킵 (config 그대로)
- n → 4-b로 진행해 6개 질문 다시 받기

**[기존 시나리오] 기존 test-scenario.md를 그대로 쓸까요? (Y/n)**
- Y(기본) → 시나리오 그대로
- n → `pairloop/test-scenario.md`를 `pairloop/test-scenario.md.bak`으로 옮기고, 템플릿 폴더(`$TARGET/templates/test-scenario.md`)의 빈 버전을 다시 깔아둔다. 이렇게 하면 6단계의 pair-watch 자동 진입 시 자동 생성 4가지 질문이 다시 발동된다.

두 질문 모두 새 메시지로 한 번에 한 개씩 출력하고 사용자 답을 받은 뒤에야 다음으로 진행한다.

### 4-b. 6개 질문으로 `pairloop.config.json` 작성

`pairloop.config.json`이 없거나 4-a에서 n을 받은 경우. **반드시 한 번에 한 질문씩 출력하고 사용자 답을 받은 뒤에야 다음 질문으로 진행한다.** 6개를 표나 목록으로 한 번에 나열하면 안 된다 — 사용자가 어떤 형식으로 답해야 할지 혼란스럽기 때문이다.

각 질문은 다음 형식으로 출력한다:

```
[1/6] 프로젝트 이름
  추천: my-project  (← 자동 감지: 폴더명 정규화)
  → 그대로 쓰려면 Enter, 바꾸려면 새 값을 입력해주세요.
```

사용자가 답하면 다음 질문으로:

```
[2/6] 배포 주소 (ping URL)
  추천: (비워둠)
  → 운영 URL이 있으면 https://... 형식으로, 없으면 Enter.
```

이런 식으로 1번부터 6번까지 차례로 진행한다. **이전 질문의 답을 받기 전에 다음 질문을 미리 출력하지 않는다.**

질문 항목과 자동 감지 default:

| # | 질문 | 자동 감지 default |
|---|------|------------------|
| 1 | 프로젝트 이름 (영문/숫자/하이픈) | 현재 폴더 이름(소문자, 공백·`_` → 하이픈) |
| 2 | 배포 주소 (ping URL) | 없음 (Enter면 로컬 모드 `http://localhost:3000/api/ping`) |
| 3 | 기준 git 브랜치 | `git branch --show-current` 결과 또는 `main` |
| 4 | 테스트 실행 명령 | `playwright.config.*` 발견 시 `npx playwright test`, 없으면 빈 값 |
| 5 | 개발 서버 시작 명령 (선택) | `pnpm-lock.yaml` → `pnpm dev`, `yarn.lock` → `yarn dev`, 그 외 → `npm run dev` |
| 6 | 테스트 시 브라우저 창 표시 (y/n) | `n` (= headless: true) |

6개 답을 모두 받은 뒤 `pairloop/pairloop.config.json`을 Write 도구로 직접 작성한다.

```json
{
  "$schema": "./pairloop.config.schema.json",
  "project": { "name": "<답 1>", "bugPrefix": "BUG" },
  "watch": { "pingUrl": "<답 2 처리>", "gitBranch": "<답 3>" },
  "test": {
    "command": "<답 4>",
    "devServerCommand": "<답 5 — 비어있으면 키 자체 생략>",
    "headless": <답 6: y면 false, n/Enter면 true>,
    "captureOnFailure": true
  },
  "intervals": { "pingSec": 30, "gitSec": 180 }
}
```

작성 완료 후 결과 한 줄 보고:
```
✓ pairloop/pairloop.config.json 작성 완료 (project=<답1>, branch=<답3>, headless=<...>)
```

---

## 5. (선택) `/api/ping` 안내

`/api/ping`은 선택사항임을 명확히 알린다 — 없어도 git 커밋 감지로 동작한다. Vercel/Railway 즉시 배포 감지가 필요한 경우만 추가하라고 한 줄 안내.

기술 스택을 자동 감지해서 (Next.js 파일 / Express 의존성 등) 해당 코드 스니펫을 한 번만 출력한다.

---

## 6. 자동으로 `/pair-watch` 절차로 진입

설치 완료 메시지를 출력한 뒤, 별도 사용자 입력 없이 곧바로 `pair-watch` 스킬의 동작을 이어 진행한다.

```
=== pairloop 설치 완료 ===
이제 곧바로 감시 루프를 시작합니다 — 이 창이 창A가 됩니다.
```

이어서 `pair-watch` SKILL.md의 "0. 설정 로드" 단계부터 그대로 수행한다 (시나리오 파일이 비어 있으면 자동 생성 4가지 질문도 자연스럽게 이어짐).

---

## 구현 참고

- 모든 Bash 명령은 dangerously running mode가 아니라 사용자 권한 프롬프트가 뜰 수 있다. 사용자가 거부하면 그 단계만 건너뛰고 다음으로 진행하지 말고 이유를 출력한 뒤 중단한다.
- 압축 해제·복사 단계는 모두 멱등(idempotent)이다. 같은 명령을 여러 번 실행해도 안전.
- 사용자가 중간에 `중지`/`stop`을 입력하면 즉시 중단하고 현재 상태를 보고한다.
- Windows에서는 unzip 대신 PowerShell `Expand-Archive` 또는 WSL 환경의 `unzip`을 사용한다 — 환경에 맞게 분기.
