# pairloop — 프로토타입 v0.8.17

> **이게 뭐예요?** Claude Code 위에 얹는 **장기 프로젝트 운영 레이어**의 프로토타입입니다.
> E2E 감시 · 버그 분류 · 세션 인수인계를 하나의 규약으로 묶은 스킬·템플릿 모음이에요.

## 누가 쓰면 좋은가

- Claude Code Pro 이상을 **매일** 쓰는 **1~2인** 개발자
- 작은 Next.js/Express/FastAPI SaaS를 혼자 운영 중
- "어제 AI랑 했던 맥락이 매번 사라진다"가 짜증나는 분

**안 맞는 분:**
- 3인 이상 팀 → Git 브랜치 + PR 리뷰가 더 깔끔합니다.
- Claude Code를 안 쓰는 분 → 이 프로토타입은 `Monitor`, `ScheduleWakeup` 에 강하게 묶여 있어요.
- "24/7 감시" 가 필요한 분 → Monitor는 Claude Code 세션이 열려 있을 때만 돕니다. 세션이 끊기면 감시도 꺼져요.

---

## 퀵스타트 (3분)

사용자가 해야 하는 일은 3가지뿐입니다.

### 1. 이 레포 clone (또는 ZIP 다운로드) + 프로젝트 루트에서 Claude Code 실행

```bash
git clone https://github.com/daleyoon76/pairloop-oss.git ~/Downloads/pairloop
```

또는 GitHub 페이지의 **Code → Download ZIP**으로 받아 `~/Downloads/pairloop`에 풀어둡니다. 그다음 테스트 대상 프로젝트의 루트 폴더에서 Claude Code를 실행합니다.

### 2. 창 A에 자연어 한 줄 붙여넣기 (첫 설치)

첫 설치 시점에는 `~/.claude/skills/`에 `pairloop-install`이 아직 없어 슬래시 명령이 작동하지 않습니다. 아래 자연어 박스를 그대로 복사해 창 A에 붙여넣으세요.

```
~/Downloads/pairloop/prototype 안의 스킬과 템플릿으로 이 프로젝트(현재 폴더)에 pairloop를 처음 설치해줘. 스킬 6개를 ~/.claude/skills/에 복사하고, 템플릿 5개와 schema는 이 프로젝트의 pairloop/ 폴더에 복사한 뒤, 6가지 질문(프로젝트명·배포URL·브랜치·테스트명령·devServer·브라우저표시)에 답하면 pairloop.config.json을 만들고 곧바로 pair-watch 감시 루프를 시작해줘.
```

이 한 번으로 다음이 자동 처리됩니다.

1. `~/Downloads/pairloop-v*.zip` 자동 탐색 → 압축 해제
2. 스킬 6개 → `~/.claude/skills/` 복사 (이후 `/pairloop-install` 슬래시 사용 가능)
3. 템플릿 + schema → 이 프로젝트의 `pairloop/` 복사
4. 6개 질문에 답하면 `pairloop.config.json` 자동 작성
5. 곧바로 감시 루프 시작 — 처음이면 시나리오 자동 생성 4가지 질문이 이어짐

> **두 번째 프로젝트부터:** 스킬이 이미 등록되어 있으므로 `/pairloop-install` 슬래시 한 번으로 동일 동작.
>
> **기존 시나리오를 바꾸고 싶을 때**도 `/pairloop-install`을 다시 실행하면 "기존 시나리오를 그대로 쓸까요? (Y/n)"를 묻습니다. `n`이라고 답하면 기존 파일을 `.bak`으로 백업하고 시나리오 자동 생성 4가지 질문을 다시 받습니다. (또는 `pairloop/test-scenario.md`를 직접 편집해도 다음 사이클부터 적용됩니다.)

### 3. 안내에 따라 창 B 띄우고 `/pair-fix`

창 A 안내문대로 IDE의 'New Window' 메뉴로 같은 프로젝트의 새 창을 띄우고 거기서:

```
/pair-fix
```

### 종료 — 두 개의 창 모두에서

```
/pair-hand
```

→ stop + 4블록 핸드오프 + git 커밋 + push까지 한 번에.

### (선택) `/api/ping` 엔드포인트 추가

기본 흐름에는 필요하지 않습니다. Vercel/Railway 배포 직후 즉시 감지를 원할 때만 추가하세요.

```ts
// Next.js — app/api/ping/route.ts
export async function GET() {
  return Response.json({ commit: process.env.VERCEL_GIT_COMMIT_SHA ?? "local" });
}
```

가이드: [`docs/ping-endpoint.md`](docs/ping-endpoint.md)

---

## 핵심 워크플로우

### 창A / 창B 이중 루프

두 Claude Code 창을 엽니다.

**창A** (감시 전담):
```
/pair-watch
```
→ 30초마다 `/api/ping` 폴링, 3분마다 git fetch. 변경 감지 시 E2E 실행 → 결과를 3-way 분류(🔴🟡🔵)해서 `pairloop/result.md`에 기록.

**창B** (수정 전담):
```
/pair-fix
```
→ `pairloop/result.md`의 미해결 항목을 순서대로 처리. 🔴=코드 수정, 🟡=테스트 업데이트, 🔵=재시도 판정.

상세: [`docs/dual-loop-pattern.md`](docs/dual-loop-pattern.md)

### 루프 종료

```
창A에서: /pair-watch-stop   (현재 사이클 완료 후 종료)
창B에서: /pair-fix-stop     (남은 항목 전부 처리 후 종료)
```

### 세션 마무리

```
/pair-hand
```

→ `pairloop/handoff.md` 최상단에 4블록(완료/다음후보/주의사항/상태스냅샷) 삽입 + `pairloop/to-do.md`, `pairloop/known-pitfalls.md` 갱신 + git push.

---

## 디렉토리 구조

```
prototype/
├── README.md                       ← 지금 이 파일
├── pairloop.config.example.json     ← 사용자가 복사해서 시작
├── pairloop.config.schema.json      ← JSON Schema (IDE 자동완성용)
├── skills/                         ← ~/.claude/skills/ 에 복사될 6개
│   ├── pairloop-install/SKILL.md    ← 첫 진입점: ZIP 자동 압축해제 + 설치 + pairloop.config.json 작성 + 자동으로 pair-watch 진입
│   ├── pair-watch/SKILL.md        ← 창A: 배포·커밋 감시 + E2E + 3-way 분류
│   ├── pair-watch-stop/SKILL.md   ← 창A: 현재 사이클 완료 후 감시 루프 종료 (호환성)
│   ├── pair-fix/SKILL.md          ← 창B: 미해결 항목 자동 수정 루프
│   ├── pair-fix-stop/SKILL.md     ← 창B: 남은 항목 전부 처리 후 수정 루프 종료 (호환성)
│   └── pair-hand/SKILL.md        ← 창A·B: stop + 세션 마무리 (문서 갱신 + push)
├── templates/                      ← 고객 프로젝트의 pairloop/ 에 복사될 빈 템플릿 5개
│   ├── handoff.md              세션 인수인계 (4블록 구조)
│   ├── known-pitfalls.md       버그 카탈로그 (BUG-N ID 체계)
│   ├── to-do.md                PPSSTT 6자리 번호 체계
│   ├── result.md               창A 기록 / 창B 읽기 (공유 신호 파일)
│   └── test-scenario.md        ★ 테스트 시나리오 정의 (핵심 파일)
└── docs/
    ├── quickstart.md               3분 설치 가이드 (/pairloop-install 흐름)
    ├── algorithm-guide.md          3-way 분류 · pair-hand · known-pitfalls 알고리즘
    ├── dual-loop-pattern.md        창A/창B 이중 루프 패턴
    ├── ping-endpoint.md            /api/ping 구현 가이드
    └── session-continuity.md       MD 3종 운영 규칙
```

설치 후 고객 프로젝트:
```
my-project/
└── pairloop/                       ← pairloop가 만들고 관리하는 폴더
    ├── pairloop.config.json
    ├── pairloop.config.schema.json
    ├── handoff.md
    ├── known-pitfalls.md
    ├── to-do.md
    ├── result.md
    └── test-scenario.md
```

---

## 솔직한 한계

1. **Claude Code 네이티브 기능에 강하게 묶임** — `Monitor`, `ScheduleWakeup` 없이는 대부분 동작 안 함.

2. **축적이 전제** — 설치 직후 `pairloop/known-pitfalls.md`와 `pairloop/handoff.md`는 비어 있음. 진가는 2~3주 뒤.

3. **24/7 감시 불가** — 세션이 닫히면 감시도 꺼짐. 상시 감시는 Phase 2 SaaS 범위.

4. **Playwright 의존** — 브라우저 바이너리 400MB+ 다운로드 필요. 다른 프레임워크는 `test.command`만 바꾸면 실행은 됨.

5. **대부분 마크다운 규약** — 순수 코드는 `lib/`의 TypeScript 헬퍼 2개뿐. 나머지는 SKILL.md 지시문 + 템플릿 MD.

---

## FAQ

**Q. 왜 자동 치유(auto-heal) 기능이 없어요?**
A. 자동 치유가 실제 버그를 가려서 운영 품질을 망가뜨리기 때문입니다. Harness는 3-way 분류로 실패 원인을 명시해 기록하는 것이 목적입니다.

**Q. 24/7 감시 가능해요?**
A. 아니요. Claude Code 세션이 열려 있을 때만 동작합니다. 상시 감시는 GitHub Actions cron이나 Checkly 같은 도구를 별도로 쓰세요.

**Q. `pairloop/pairloop.config.json` 값을 바꾸면 바로 반영되나요?**
A. `/pair-watch-stop` 후 `/pair-watch`로 재시작하면 반영됩니다.

**Q. 창A/창B 패턴을 하나의 세션에서 쓸 수 있나요?**
A. 물리적으로 가능하지만 context가 섞여 품질이 떨어집니다. Claude Code 창 2개를 별도로 여세요.

**Q. 내가 만든 스킬을 추가해도 되나요?**
A. `~/.claude/skills/`는 자유롭게 쓸 수 있습니다. 본 프로토타입의 6개 스킬(`pairloop-install`, `pair-watch`, `pair-watch-stop`, `pair-fix`, `pair-fix-stop`, `pair-hand`)과 이름이 안 겹치면 공존합니다.

---

## 피드백

이 프로토타입은 Phase 1 (4주) 전 자기 검증용 v0.1입니다.

의견: [GitHub Issues](https://github.com/daleyoon76/pairloop-oss/issues)
