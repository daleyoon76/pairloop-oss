# pairloop — 3분 설치 가이드 (v0.8.17)

사용자가 해야 하는 일은 3가지뿐입니다. ▶ 표시는 직접 입력해야 하는 명령입니다.

## 전제 조건

- Claude Code (Pro 이상 권장 — `Monitor`, `ScheduleWakeup` 사용)
- Node.js 18+
- Git
- 웹앱 하나 (프레임워크 무관)

---

## 1. ZIP 다운로드 + 프로젝트 루트에서 Claude Code 실행

`pairloop-v0.8.17.zip`을 컴퓨터 어디든 받아둡니다 (보통 `~/Downloads`).

테스트 대상 프로젝트의 루트 폴더에서 Claude Code를 실행합니다.

- VS Code/Cursor: 프로젝트 폴더를 열고 통합 터미널에서 `claude`
- 일반 터미널: `cd ~/Projects/my-app` → `claude`

---

## 2. 창 A에 자연어 한 줄 붙여넣기 (첫 설치)

`~/.claude/skills/`에 `pairloop-install`이 아직 등록되지 않은 첫 설치 시점에는 슬래시 명령이 작동하지 않습니다. 아래 박스를 그대로 복사해 창 A에 붙여넣으세요.

▶
```
~/Downloads에 받아둔 pairloop-v0.8.17.zip을 풀어서 이 프로젝트(현재 폴더)에 pairloop를 처음 설치해줘. 스킬 6개를 ~/.claude/skills/에 복사하고, 템플릿 5개와 schema는 이 프로젝트의 pairloop/ 폴더에 복사한 뒤, 6가지 질문(프로젝트명·배포URL·브랜치·테스트명령·devServer·브라우저표시)에 답하면 pairloop.config.json을 만들고 곧바로 pair-watch 감시 루프를 시작해줘.
```

> **두 번째 프로젝트부터는** 스킬이 이미 등록되어 있어 슬래시 한 번으로 가능합니다: `/pairloop-install`
>
> **기존 시나리오를 바꾸고 싶으면** `/pairloop-install`을 다시 실행하면 "기존 시나리오를 그대로 쓸까요? (Y/n)"를 묻고 `n`이면 기존 파일을 `.bak`으로 옮긴 뒤 시나리오 자동 생성 4가지 질문을 다시 받습니다.

이 한 번으로 다음이 자동 처리됩니다.

1. `~/Downloads/pairloop-v*.zip` 자동 탐색 → `pairloop/` 폴더로 압축 해제 (없으면 ZIP 경로를 묻습니다)
2. 스킬 6개 → `~/.claude/skills/` 복사
3. 템플릿 5개 + schema → 이 프로젝트의 `pairloop/` 복사
4. 6개 질문 답변 → `pairloop.config.json` 자동 작성

   ```
   1/6  프로젝트 이름        (Enter = 현재 폴더 이름)
   2/6  배포 주소            (Enter = 로컬 모드)
   3/6  기준 git 브랜치       (Enter = 현재 브랜치)
   4/6  테스트 실행 명령      (Enter = Playwright 자동 감지)
   5/6  개발 서버 명령        (Enter = npm/pnpm/yarn 자동 감지)
   6/6  브라우저 창 표시      (Enter = n, 안 띄움 권장)
   ```

5. 곧바로 감시 루프 시작 — 처음이면 시나리오 자동 생성 4가지 질문이 이어집니다.

생성되는 `pairloop.config.json`:
```json
{
  "$schema": "./pairloop.config.schema.json",
  "project": { "name": "my-app", "bugPrefix": "BUG" },
  "watch": { "pingUrl": "http://localhost:3000/api/ping", "gitBranch": "main" },
  "test": { "command": "npx playwright test", "devServerCommand": "npm run dev", "headless": true, "captureOnFailure": true },
  "intervals": { "pingSec": 30, "gitSec": 180 }
}
```

---

## 3. 안내에 따라 창 B 띄우고 `/pair-fix`

창 A에 안내가 출력됩니다.

```
지금 창B를 띄워주세요:

  1. IDE의 'New Window' 메뉴로 이 프로젝트의 새 창을 하나 더 엽니다.
  2. 새 창에서 같은 프로젝트 폴더를 엽니다.
  3. 새 창에서 Claude Code를 실행한 뒤 다음을 입력하세요:

     ▶  /pair-fix
```

새 창(창 B)에서:

▶
```
/pair-fix
```

창 A는 실패를 분류·기록, 창 B는 자동 수정.

---

## 작업 끝낼 때 (두 개의 창 모두)

▶ 창 A 먼저
```
/pair-hand
```

▶ 창 A 완료 후, 창 B
```
/pair-hand
```

→ stop + 4블록 핸드오프 + git 커밋 + push까지 한 번에.

---

## (선택) `/api/ping` 엔드포인트 — 더 정확한 배포 감지

기본 흐름에는 필요하지 않습니다. Vercel/Railway 배포 직후 즉시 감지를 원할 때만 추가하세요. 자세한 내용: [`ping-endpoint.md`](ping-endpoint.md)

**Next.js** — `app/api/ping/route.ts`:
```ts
export async function GET() {
  return Response.json({ commit: process.env.VERCEL_GIT_COMMIT_SHA ?? "local" });
}
```

**Express** — `app.js`:
```js
app.get("/api/ping", (req, res) => {
  res.json({ commit: process.env.COMMIT_SHA ?? "local" });
});
```

---

## 설치 완료 체크리스트

- [ ] `~/.claude/skills/` 에 6개 폴더 생성 확인 (`pairloop-install` 포함)
- [ ] 프로젝트 루트의 `pairloop/pairloop.config.json` 존재 확인
- [ ] 창 A에서 시나리오 자동 생성 → 감시 루프 시작 → 창 B 안내 메시지 확인
- [ ] 창 B에서 `/pair-fix` 후 두 개의 창이 협업 시작
