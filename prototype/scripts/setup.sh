#!/bin/bash
# pairloop — 대화형 초기 설정
# 사용법: 내 프로젝트 폴더에서 실행
#   bash ~/Downloads/pairloop/scripts/setup.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo "======================================"
echo "  pairloop 초기 설정 (6단계)"
echo "======================================"
echo ""

# ── 1 / 6  프로젝트 이름 ──────────────────────────────────────────
default_name=$(basename "$PWD")

echo -e "${CYAN}1/6  프로젝트 이름${NC}"
echo "     버그 ID나 보고서에 표시될 이름입니다."
echo "     영어, 숫자, 하이픈만 사용하세요. (예: my-blog, shop-api)"
read -rp "     [기본값: $default_name] > " project_name
project_name="${project_name:-$default_name}"
# 공백 → 하이픈, 소문자
project_name=$(echo "$project_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
echo ""

# ── 2 / 6  배포 URL ───────────────────────────────────────────────
echo -e "${CYAN}2/6  배포 주소${NC}"
echo "     Vercel, Railway 등에 이미 배포된 서비스가 있으면 주소를 입력하세요."
echo "     (예: https://my-blog.vercel.app)"
echo "     없으면 그냥 Enter — 로컬(localhost)에서만 테스트합니다."
read -rp "     > " deploy_url

if [ -z "$deploy_url" ]; then
  ping_url="http://localhost:3000/api/ping"
  echo -e "     ${YELLOW}→ 로컬 모드로 설정합니다 (localhost:3000).${NC}"
  echo "       포트가 다르면 나중에 pairloop/pairloop.config.json 에서 바꾸세요."
else
  deploy_url="${deploy_url%/}"        # 끝 슬래시 제거
  ping_url="${deploy_url}/api/ping"
  echo "     → 감시 주소: $ping_url"
fi
echo ""

# ── 3 / 6  git 브랜치 ────────────────────────────────────────────
default_branch=$(git branch --show-current 2>/dev/null || echo "main")

echo -e "${CYAN}3/6  기준 브랜치${NC}"
echo "     주로 커밋하고 배포하는 브랜치 이름을 입력하세요."
read -rp "     [기본값: $default_branch] > " git_branch
git_branch="${git_branch:-$default_branch}"
echo ""

# ── 4 / 6  테스트 명령 ───────────────────────────────────────────
echo -e "${CYAN}4/6  테스트 실행 명령${NC}"

if [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]; then
  default_cmd="npx playwright test"
  echo "     playwright.config 파일을 발견했습니다."
  echo "     특정 파일만 돌리려면 뒤에 경로를 붙이세요."
  echo "     (예: npx playwright test e2e/smoke.spec.ts)"
  read -rp "     [기본값: $default_cmd] > " test_command
  test_command="${test_command:-$default_cmd}"
  echo ""
  echo -e "  ${YELLOW}ℹ️  로컬 서버 자동 시작 권장${NC}"
  echo "     Harness는 로컬 서버를 직접 띄우지 않습니다."
  echo "     playwright.config.ts 에 webServer 옵션을 추가하면"
  echo "     테스트 전에 서버가 자동으로 시작됩니다:"
  echo ""
  echo "     webServer: {"
  echo "       command: 'npm run dev',"
  echo "       url: 'http://localhost:3000',"
  echo "       reuseExistingServer: true,"
  echo "     }"
else
  echo "     Playwright 테스트 파일이 아직 없으면 Enter를 누르세요."
  echo "     나중에 pairloop/pairloop.config.json 에서 추가할 수 있습니다."
  read -rp "     > " test_command
fi
echo ""

# ── 5 / 6  개발 서버 시작 명령 ───────────────────────────────────
echo -e "${CYAN}5/6  개발 서버 시작 명령 (선택)${NC}"
echo "     pair-watch가 테스트 전 서버를 자동으로 띄울 때 사용합니다."
echo "     서버를 수동으로 띄울 계획이면 그냥 Enter."

# 패키지 매니저 자동 감지
if [ -f "pnpm-lock.yaml" ]; then default_dev_cmd="pnpm dev"
elif [ -f "yarn.lock" ]; then default_dev_cmd="yarn dev"
else default_dev_cmd="npm run dev"
fi

read -rp "     [기본값: $default_dev_cmd] > " dev_server_command
dev_server_command="${dev_server_command:-$default_dev_cmd}"
echo ""

# ── 6 / 6  브라우저 표시 여부 ─────────────────────────────────────
echo -e "${CYAN}6/6  테스트 시 브라우저 창 표시 여부${NC}"
echo "     y → 창을 띄움 (눈으로 확인 가능, 느림, 다른 작업 방해됨)"
echo "     n → 안 띄움 (빠르고 백그라운드 실행, 권장)"
echo ""
echo "     안 띄워도 실패하면 trace/screenshot/video가 자동 저장되어"
echo "     'npx playwright show-trace' 로 사후 재생할 수 있습니다."
read -rp "     [기본값: n] > " show_browser
show_browser="${show_browser:-n}"
case "$show_browser" in
  [Yy]*) headless_value="false" ;;
  *)     headless_value="true" ;;
esac
echo ""

# ── pairloop/pairloop.config.json 생성 ─────────────────────────────
mkdir -p pairloop

# devServerCommand 필드 조건부 포함
if [ -n "$dev_server_command" ]; then
  dev_server_line="    \"devServerCommand\": \"$dev_server_command\","
else
  dev_server_line=""
fi

cat > pairloop/pairloop.config.json <<EOF
{
  "\$schema": "./pairloop.config.schema.json",
  "project": {
    "name": "$project_name",
    "bugPrefix": "BUG"
  },
  "watch": {
    "pingUrl": "$ping_url",
    "gitBranch": "$git_branch"
  },
  "test": {
    "command": "$test_command",
    $dev_server_line
    "headless": $headless_value,
    "captureOnFailure": true
  },
  "intervals": {
    "pingSec": 30,
    "gitSec": 180
  }
}
EOF

echo -e "${GREEN}✓ pairloop/pairloop.config.json 생성 완료${NC}"
echo ""

# ── /api/ping 코드 안내 ───────────────────────────────────────────
echo "======================================"
echo "  마지막: 서버에 코드 한 줄 추가"
echo "======================================"
echo ""
echo "Harness가 배포를 감지하려면 /api/ping 엔드포인트가 필요합니다."
echo "아래 코드를 서버에 추가하세요. (1~2분 작업)"
echo ""

# 기술 스택 자동 감지
if [ -f "next.config.ts" ] || [ -f "next.config.js" ] || [ -f "next.config.mjs" ]; then
  echo "  [Next.js 감지됨]"
  echo "  파일 생성: app/api/ping/route.ts"
  echo ""
  echo "  ┌──────────────────────────────────────────"
  echo "  │ export async function GET() {"
  echo "  │   return Response.json({"
  echo "  │     commit: process.env.VERCEL_GIT_COMMIT_SHA ?? 'local'"
  echo "  │   });"
  echo "  │ }"
  echo "  └──────────────────────────────────────────"
elif [ -f "package.json" ] && grep -q '"express"' package.json 2>/dev/null; then
  echo "  [Express 감지됨]"
  echo "  app.js 또는 routes 파일에 추가:"
  echo ""
  echo "  ┌──────────────────────────────────────────"
  echo "  │ app.get('/api/ping', (req, res) => {"
  echo "  │   res.json({ commit: process.env.COMMIT_SHA ?? 'local' });"
  echo "  │ });"
  echo "  └──────────────────────────────────────────"
else
  echo "  GET /api/ping 에 아래 JSON을 반환하도록 추가하세요:"
  echo ""
  echo '  { "commit": "현재 배포된 git 커밋 해시 또는 local" }'
fi

echo ""
echo "추가를 완료했으면 Claude Code 를 열고 아래를 입력하세요:"
echo ""
echo -e "  ${GREEN}/pair-watch${NC}"
echo ""
echo "설치 완료입니다."
echo ""
