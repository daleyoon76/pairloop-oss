# Ping 엔드포인트 구현 가이드

`e2e-watch` 스킬이 배포 완료를 감지하려면 앱에 `/api/ping` 엔드포인트가 있어야 한다. **5분 작업**이다.

## 요구사항

- 응답 형식: JSON `{ "commit": "<빌드 시점의 git SHA>" }`
- 빌드 시점에 값이 박혀 있어야 한다 (런타임에 계산하면 의미 없음)
- 빌드 전이면 `"unknown"` 이라도 괜찮다 — `pairloop.config.json` 의 `deployPing.unknownValue` 와 맞추면 된다

## Next.js 15/16 (App Router)

`app/api/ping/route.ts`:

```ts
export const runtime = "edge"; // 선택: nodejs 도 OK
export const dynamic = "force-dynamic";

export async function GET() {
  return Response.json({
    commit: process.env.VERCEL_GIT_COMMIT_SHA ?? "unknown",
    deployedAt: process.env.VERCEL_DEPLOYMENT_ID ?? null,
  });
}
```

Vercel이 아니면 `VERCEL_GIT_COMMIT_SHA` 대신 본인 환경의 빌드 SHA 환경변수를 쓴다.

## 그 외 플랫폼 환경변수

| 플랫폼 | SHA 환경변수 |
|---|---|
| Vercel | `VERCEL_GIT_COMMIT_SHA` |
| Netlify | `COMMIT_REF` |
| Cloudflare Pages | `CF_PAGES_COMMIT_SHA` |
| GitHub Actions (빌드 시 주입) | `GITHUB_SHA` |
| Railway | `RAILWAY_GIT_COMMIT_SHA` |

## Express/Fastify/Koa

```ts
app.get("/api/ping", (_req, res) => {
  res.json({ commit: process.env.GIT_SHA ?? "unknown" });
});
```

빌드 스크립트에서 `GIT_SHA=$(git rev-parse HEAD) npm run build` 식으로 주입.

## 확인

배포 후 브라우저에서 `https://your-app.example.com/api/ping` 을 열어 `{ "commit": "a1b2c3..." }` 가 나오면 성공.

`e2e-watch` 는 이 값이 **이전과 달라지는 순간** "배포 완료"로 본다.
