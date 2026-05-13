> 🌐 **Note for English-speaking visitors**: pairloop is currently a Korean-language tool — skills, templates, and documentation are written in Korean. English localization is not ready yet. Browser auto-translation is recommended in the meantime.

---

# pairloop

<img src="assets/demo.gif" alt="pairloop demo" width="800">

> Claude Code 위에 얹는 **장기 프로젝트 운영 레이어**. 한 창은 감시(watch), 다른 창은 수정(fix), 세션 종료 시 인계(hand). 1~2인 개발자를 위한 Claude Code 운영 스킬·템플릿 모음입니다.

**현재 버전**: v0.8.17 · **라이선스**: [MIT](LICENSE)

---

## 누가 쓰면 좋은가

- Claude Code Pro 이상을 **매일** 쓰는 **1~2인** 개발자
- 작은 Next.js / Express / FastAPI SaaS를 혼자 운영 중
- "어제 AI랑 했던 맥락이 매번 사라진다"가 짜증나는 분

**안 맞는 분:**
- 3인 이상 팀 → Git 브랜치 + PR 리뷰가 더 깔끔합니다.
- Claude Code를 안 쓰는 분 → 본 도구는 `Monitor`, `ScheduleWakeup` 에 강하게 묶여 있어요.
- "24/7 감시"가 필요한 분 → Monitor는 Claude Code 세션이 열려 있을 때만 돕니다.

---

## 빠른 시작 (3분)

### 1) 이 레포 clone 또는 ZIP 다운로드

```bash
git clone https://github.com/daleyoon76/pairloop-oss.git ~/Downloads/pairloop
```

또는 GitHub 페이지의 **Code → Download ZIP**으로 받아 `~/Downloads/pairloop`에 풀어둡니다.

### 2) 테스트 대상 프로젝트 루트에서 Claude Code 실행 + 자연어 한 줄 붙여넣기

```
~/Downloads/pairloop/prototype 안의 스킬과 템플릿으로 이 프로젝트(현재 폴더)에 pairloop를 처음 설치해줘. 스킬 6개를 ~/.claude/skills/에 복사하고, 템플릿 5개와 schema는 이 프로젝트의 pairloop/ 폴더에 복사한 뒤, 6가지 질문(프로젝트명·배포URL·브랜치·테스트명령·devServer·브라우저표시)에 답하면 pairloop.config.json을 만들고 곧바로 pair-watch 감시 루프를 시작해줘.
```

이 한 번으로:

1. 스킬 6개 → `~/.claude/skills/` 복사 (이후 `/pairloop-install` 슬래시 명령 사용 가능)
2. 템플릿 + schema → 이 프로젝트의 `pairloop/` 폴더 복사
3. 6개 질문에 답하면 `pairloop.config.json` 자동 작성
4. 곧바로 감시 루프 시작 — 처음이면 시나리오 자동 생성 4가지 질문이 이어짐

### 3) 새 창에서 `/pair-fix`

창 A 안내문대로 IDE의 'New Window'로 같은 프로젝트의 새 창을 띄우고:

```
/pair-fix
```

### 종료 — 두 창 모두에서

```
/pair-hand
```

→ stop + 4블록 핸드오프 + git 커밋 + push까지 한 번에.

> **자세한 가이드**: [`prototype/README.md`](prototype/README.md) · [`prototype/docs/quickstart.md`](prototype/docs/quickstart.md) · [`prototype/docs/dual-loop-pattern.md`](prototype/docs/dual-loop-pattern.md)

---

## 6개 스킬 한눈에

| 스킬 | 트리거 | 역할 |
|:--|:--|:--|
| `pairloop-install` | `/pairloop-install` | 첫 설치 + 설정 + 곧바로 watch 진입 |
| `pair-watch` | `/pair-watch` | 창A — 배포·커밋 감시 → E2E 실행 → 3-way 분류(🔴🟡🔵) |
| `pair-watch-stop` | `/pair-watch-stop` | 창A — 현재 사이클 완료 후 종료 |
| `pair-fix` | `/pair-fix` | 창B — 미해결 항목 자동 수정 |
| `pair-fix-stop` | `/pair-fix-stop` | 창B — 남은 항목 처리 후 종료 |
| `pair-hand` | `/pair-hand` | 세션 종료 — 핸드오프 + 커밋 + push |

---

## 솔직한 한계

1. **Claude Code 네이티브 기능에 강하게 묶임** — `Monitor`, `ScheduleWakeup` 없이는 대부분 동작 안 함.
2. **축적이 전제** — 설치 직후 `pairloop/known-pitfalls.md`와 `pairloop/handoff.md`는 비어 있음. 진가는 2~3주 뒤.
3. **24/7 감시 불가** — 세션이 닫히면 감시도 꺼짐.
4. **Playwright 의존** — 브라우저 바이너리 400MB+ 다운로드 필요.
5. **대부분 마크다운 규약** — 순수 코드는 `lib/`의 TypeScript 헬퍼 몇 개뿐.

---

## 피드백 / 기여

- 버그·제안: [GitHub Issues](https://github.com/daleyoon76/pairloop-oss/issues)
- Pull Request 환영합니다. 단 본 레포는 *공개 미러* 성격이라 큰 구조 변경은 제안 단계에서 먼저 논의해 주시면 좋습니다.

---

## 라이선스

[MIT](LICENSE) — 자유롭게 사용·수정·재배포하셔도 됩니다.
