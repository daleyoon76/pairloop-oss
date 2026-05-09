# lib/

두 개의 작은 런타임 유틸. Playwright 프로젝트 안에 복사해서 쓴다.

| 파일 | 용도 |
|---|---|
| `md-config.ts` | 가이드 MD 안의 ```json harness-config 블록을 파싱. `loadGuideConfig({ path, tag })` 한 함수. |
| `failure-capture.ts` | Playwright 테스트 실패 시 스크린샷 + URL을 한 줄 문자열로 반환. `result.md`에 그대로 붙여 쓰기 편함. |

## 설치

```bash
cp docs/pairloop/prototype/lib/*.ts your-project/e2e/helpers/
```

또는 npm 패키지로 떨어뜨릴 거라면 `@pairloop/md-config` 같은 이름을 검토한다 (현 프로토타입은 소스 복사 방식).

## 의존성

- `md-config.ts` — 없음 (Node 기본 fs/path만 사용)
- `failure-capture.ts` — `@playwright/test` 타입만 사용

Zod 검증은 포함하지 않았다. 호출 측에서 본인 스키마로 검증한다.
