/**
 * md-config — 마크다운 가이드 파일 안의 ```json <tag> 블록을 파싱해 테스트 설정으로 반환한다.
 *
 * 가이드 MD가 single source of truth — 값을 변경하면 다음 E2E 실행에 바로 반영된다.
 *
 * 사용 예:
 *   import { loadGuideConfig } from "./md-config";
 *   const cfg = loadGuideConfig({ path: "e2e/e2e-test-guide.md", tag: "harness-config" });
 *   const baseUrl: string = cfg.baseUrl as string;
 *
 * 스키마 검증은 호출 측에서 Zod 등으로 수행하는 것을 권장한다.
 */
import * as fs from "fs";
import * as path from "path";

export interface LoadOptions {
  /** 파싱 대상 MD 파일 경로 (절대 또는 cwd 기준 상대). */
  path: string;
  /** ```json <tag> 에서 <tag> 문자열. 기본: "harness-config". */
  tag?: string;
  /** 파싱 결과를 프로세스 수명 동안 캐시할지. 기본 true. */
  cache?: boolean;
}

const _cache = new Map<string, unknown>();

export function loadGuideConfig<T = Record<string, unknown>>(opts: LoadOptions): T {
  const tag = opts.tag ?? "harness-config";
  const useCache = opts.cache !== false;
  const abs = path.isAbsolute(opts.path) ? opts.path : path.join(process.cwd(), opts.path);
  const cacheKey = `${abs}::${tag}`;

  if (useCache && _cache.has(cacheKey)) {
    return _cache.get(cacheKey) as T;
  }

  if (!fs.existsSync(abs)) {
    throw new Error(`[md-config] 가이드 MD를 찾을 수 없습니다: ${abs}`);
  }

  const content = fs.readFileSync(abs, "utf-8");
  const escaped = tag.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const re = new RegExp("```json " + escaped + "\\r?\\n([\\s\\S]*?)\\r?\\n```");
  const match = content.match(re);
  if (!match) {
    throw new Error(
      `[md-config] ${abs} 에서 \`\`\`json ${tag} 블록을 찾을 수 없습니다.`,
    );
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(match[1]);
  } catch (e) {
    throw new Error(
      `[md-config] JSON 파싱 실패 — 문법 오류를 확인하세요: ${(e as Error).message}`,
    );
  }

  if (useCache) _cache.set(cacheKey, parsed);
  return parsed as T;
}

/** 단위 테스트에서 캐시를 비우고 싶을 때 호출. */
export function clearCache(): void {
  _cache.clear();
}
