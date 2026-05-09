/**
 * console-capture — Playwright 픽스처.
 * 브라우저 콘솔 에러·경고를 수집해 실패 시 pairloop/console-logs/<testName>.txt 에 저장한다.
 *
 * 사용법: 테스트 파일의 @playwright/test import를 아래로 교체한다.
 *   import { test, expect } from '../pairloop/console-capture';
 *   (경로는 테스트 파일 위치에 맞게 조정)
 */
import { test as base, expect } from "@playwright/test";
import * as fs from "fs";
import * as path from "path";

const LOG_DIR = path.join("pairloop", "console-logs");

export const test = base.extend<Record<string, never>>({
  page: async ({ page }, use, testInfo) => {
    const logs: string[] = [];
    page.on("console", (msg) => {
      const type = msg.type();
      if (type === "error" || type === "warning") {
        logs.push(`[${type.toUpperCase()}] ${msg.text()}`);
      }
    });
    page.on("pageerror", (err) => {
      logs.push(`[PAGE_ERROR] ${err.message}`);
    });
    await use(page);
    if (testInfo.status !== testInfo.expectedStatus && logs.length > 0) {
      fs.mkdirSync(LOG_DIR, { recursive: true });
      const safe = testInfo.title.replace(/[^\w-]/g, "_").slice(0, 80);
      fs.writeFileSync(path.join(LOG_DIR, `${safe}.txt`), logs.join("\n"), "utf-8");
    }
  },
});

export { expect };
