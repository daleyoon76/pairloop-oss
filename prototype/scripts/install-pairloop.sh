#!/usr/bin/env bash
# install-pairloop.sh — pairloop 설치 (macOS/Linux/WSL)
#
# 사용법:
#   cd your-project
#   bash path/to/pairloop/scripts/install-pairloop.sh
#
# 하는 일:
#   1. ~/.claude/skills/ 에 스킬 6개 복사 (충돌 시 확인)
#   2. 프로젝트 루트의 pairloop/ 폴더에 운영 문서 템플릿 5개 복사 (없을 때만)
#   3. pairloop/pairloop.config.schema.json 복사 (IDE 자동완성용)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROTO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(pwd)"
SKILLS_DST="${HOME}/.claude/skills"

# 제품에 포함되는 스킬 6개
PRODUCT_SKILLS=(pairloop-install pair-watch pair-watch-stop pair-fix pair-fix-stop pair-hand)

# 고객 프로젝트의 pairloop/ 폴더에 복사되는 템플릿 5개
PRODUCT_TEMPLATES=(handoff.md known-pitfalls.md to-do.md result.md test-scenario.md)

# pairloop/ 폴더에 복사되는 TypeScript 헬퍼
PRODUCT_LIB=(console-capture.ts)

echo "=== pairloop 설치 ==="
echo "  프로토타입 위치: $PROTO_DIR"
echo "  설치 대상 프로젝트: $PROJECT_ROOT"
echo "  스킬 설치 위치: $SKILLS_DST"
echo

confirm() {
  local prompt="$1"
  read -r -p "$prompt [y/N] " resp
  [[ "$resp" =~ ^[Yy]$ ]]
}

# 1. SKILL.md 5개 복사
echo "[1/3] ~/.claude/skills/ 에 스킬 복사"
mkdir -p "$SKILLS_DST"
for name in "${PRODUCT_SKILLS[@]}"; do
  src="$PROTO_DIR/skills/$name"
  dst="$SKILLS_DST/$name"
  if [[ ! -d "$src" ]]; then
    echo "  ⚠️  소스 없음, 건너뜀: $name"
    continue
  fi
  if [[ -e "$dst/SKILL.md" ]]; then
    if confirm "  ⚠️  $name 이미 존재. 덮어쓸까요?"; then
      cp -r "$src/" "$dst/"
      echo "  ✓ 덮어씀: $name"
    else
      echo "  - 건너뜀: $name"
    fi
  else
    cp -r "$src" "$SKILLS_DST/"
    echo "  ✓ 설치: $name"
  fi
done
echo

# 2. 운영 문서 템플릿 5개 + TypeScript 헬퍼 복사 (pairloop/ 폴더)
echo "[2/3] pairloop/ 폴더에 운영 문서 템플릿 복사 (없을 때만)"
mkdir -p "$PROJECT_ROOT/pairloop"
for t in "${PRODUCT_TEMPLATES[@]}"; do
  if [[ -e "$PROJECT_ROOT/pairloop/$t" ]]; then
    echo "  - 이미 존재: pairloop/$t"
  else
    cp "$PROTO_DIR/templates/$t" "$PROJECT_ROOT/pairloop/$t"
    echo "  ✓ 복사: pairloop/$t"
  fi
done
for f in "${PRODUCT_LIB[@]}"; do
  if [[ -e "$PROJECT_ROOT/pairloop/$f" ]]; then
    echo "  - 이미 존재: pairloop/$f"
  else
    cp "$PROTO_DIR/lib/$f" "$PROJECT_ROOT/pairloop/$f"
    echo "  ✓ 복사: pairloop/$f"
  fi
done
echo

# 3. JSON Schema 복사 (IDE 자동완성)
echo "[3/3] pairloop/ 에 pairloop.config.schema.json 복사"
if [[ -e "$PROJECT_ROOT/pairloop/pairloop.config.schema.json" ]]; then
  echo "  - 이미 존재 — 건너뜀"
else
  cp "$PROTO_DIR/pairloop.config.schema.json" "$PROJECT_ROOT/pairloop/pairloop.config.schema.json"
  echo "  ✓ 복사됨"
fi
echo

echo "=== 설치 완료 ==="
echo

# 4. setup 자동 이어서 실행 (사용자 동의)
SETUP_SH="$PROTO_DIR/scripts/setup.sh"
if [[ -f "$SETUP_SH" && -e "$PROJECT_ROOT/pairloop/pairloop.config.json" ]]; then
  echo "  ℹ️  pairloop/pairloop.config.json 이 이미 존재합니다 — setup 자동 실행을 건너뜁니다."
  echo
  echo "  설정을 다시 만들고 싶으면 직접 실행하세요:"
  echo "    bash $SETUP_SH"
elif [[ -f "$SETUP_SH" ]]; then
  echo "[4/4] 이어서 setup 스크립트를 실행합니다 (pairloop/pairloop.config.json 생성)."
  if confirm "  지금 실행할까요?"; then
    echo
    bash "$SETUP_SH"
  else
    echo "  - 건너뜀. 나중에 직접 실행: bash $SETUP_SH"
  fi
fi

echo
echo "==================================================="
echo "  남은 단계 (Claude Code 에서)"
echo "==================================================="
echo "  창 A:  /pair-watch   ← 처음 실행 시 시나리오 자동 생성"
echo "  창 B:  /pair-fix"
echo "  종료:  두 개의 창 모두에서  /pair-hand"
echo
echo "  (선택) 더 정확한 배포 감지를 원하면 /api/ping 엔드포인트 추가 — docs/ping-endpoint.md"
