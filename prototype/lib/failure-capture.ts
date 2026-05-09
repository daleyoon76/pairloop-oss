/**
 * failure-capture — E2E 실패 시 스크린샷 + URL 컨텍스트를 캡처해 로그용 문자열을 반환한다.
 *
 * AI가 읽기 쉬운 한 줄 포맷:
 *   URL=https://... | SS=e2e/screenshots/fail-<step>-<ts>.png
 *
 * 이 한 줄을 result.md의 실패 항목에 붙이면 Claude Code가 다음 세션에서
 * 스크린샷과 URL을 바로 열어볼 수 있다.
 *
 * 사용 예:
 *   import { captureFailureContext } from "./failure-capture";
 *   const ctx = await captureFailureContext(page, "login", err, { screenshotDir: "e2e/screenshots" });
 */
import type { Page } from "@playwright/test";
import * as fs from "fs";
import * as path from "path";

export interface CaptureOptions {
  /** 스크린샷 저장 디렉토리. 기본: "e2e/screenshots". */
  screenshotDir?: string;
  /** 전체 페이지 캡처 여부. 기본 false (뷰포트만). */
  fullPage?: boolean;
}

export async function captureFailureContext(
  page: Page,
  step: string,
  _error: Error,
  opts: CaptureOptions = {},
): Promise<string> {
  try {
    const dir = opts.screenshotDir ?? path.join("e2e", "screenshots");
    fs.mkdirSync(dir, { recursive: true });
    const ts = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
    const safeStep = step.replace(/[^\w-]/g, "_");
    const ssFile = `fail-${safeStep}-${ts}.png`;
    await page.screenshot({
      path: path.join(dir, ssFile),
      fullPage: opts.fullPage ?? false,
    });
    return `URL=${page.url()} | SS=${path.join(dir, ssFile).replace(/\\/g, "/")}`;
  } catch {
    return "";
  }
}
