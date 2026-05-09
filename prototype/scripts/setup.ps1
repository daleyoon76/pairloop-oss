# pairloop — 대화형 초기 설정 (Windows PowerShell)
# 사용법: 내 프로젝트 폴더에서 실행
#   powershell -File $HOME\Downloads\pairloop\scripts\setup.ps1

$ErrorActionPreference = "Stop"

function Prompt-Input($question, $default) {
    if ($default) {
        $answer = Read-Host "     $question`n     [기본값: $default] >"
        if ([string]::IsNullOrWhiteSpace($answer)) { return $default }
        return $answer.Trim()
    } else {
        $answer = Read-Host "     $question`n     >"
        return $answer.Trim()
    }
}

Write-Host ""
Write-Host "======================================"
Write-Host "  pairloop 초기 설정 (6단계)"
Write-Host "======================================"
Write-Host ""

# ── 1 / 4  프로젝트 이름 ──────────────────────────────────────────
$defaultName = (Get-Item -Path ".").Name

Write-Host "1/6  프로젝트 이름" -ForegroundColor Cyan
Write-Host "     버그 ID나 보고서에 표시될 이름입니다."
Write-Host "     영어, 숫자, 하이픈만 사용하세요. (예: my-blog, shop-api)"
$projectName = Prompt-Input "" $defaultName
$projectName = $projectName -replace '\s', '-' -replace '[^a-zA-Z0-9\-]', ''
$projectName = $projectName.ToLower()
Write-Host ""

# ── 2 / 4  배포 주소 ──────────────────────────────────────────────
Write-Host "2/6  배포 주소" -ForegroundColor Cyan
Write-Host "     Vercel, Railway 등에 이미 배포된 서비스가 있으면 주소를 입력하세요."
Write-Host "     (예: https://my-blog.vercel.app)"
Write-Host "     없으면 그냥 Enter — 로컬(localhost)에서만 테스트합니다."
$deployUrl = Prompt-Input "" ""

if ([string]::IsNullOrWhiteSpace($deployUrl)) {
    $pingUrl = "http://localhost:3000/api/ping"
    Write-Host "     → 로컬 모드로 설정합니다 (localhost:3000)." -ForegroundColor Yellow
    Write-Host "       포트가 다르면 나중에 pairloop/pairloop.config.json 에서 바꾸세요."
} else {
    $deployUrl = $deployUrl.TrimEnd('/')
    $pingUrl = "$deployUrl/api/ping"
    Write-Host "     → 감시 주소: $pingUrl"
}
Write-Host ""

# ── 3 / 4  git 브랜치 ────────────────────────────────────────────
try {
    $defaultBranch = (git branch --show-current 2>$null)
    if ([string]::IsNullOrWhiteSpace($defaultBranch)) { $defaultBranch = "main" }
} catch {
    $defaultBranch = "main"
}

Write-Host "3/6  기준 브랜치" -ForegroundColor Cyan
Write-Host "     주로 커밋하고 배포하는 브랜치 이름을 입력하세요."
$gitBranch = Prompt-Input "" $defaultBranch
Write-Host ""

# ── 4 / 4  테스트 명령 ───────────────────────────────────────────
Write-Host "4/6  테스트 실행 명령" -ForegroundColor Cyan

$hasPlaywright = (Test-Path "playwright.config.ts") -or (Test-Path "playwright.config.js")
if ($hasPlaywright) {
    $defaultCmd = "npx playwright test"
    Write-Host "     playwright.config 파일을 발견했습니다."
    Write-Host "     특정 파일만 돌리려면 뒤에 경로를 붙이세요."
    Write-Host "     (예: npx playwright test e2e/smoke.spec.ts)"
    $testCommand = Prompt-Input "" $defaultCmd
    Write-Host ""
    Write-Host "  ℹ️  로컬 서버 자동 시작 권장" -ForegroundColor Yellow
    Write-Host "     Harness는 로컬 서버를 직접 띄우지 않습니다."
    Write-Host "     playwright.config.ts 에 webServer 옵션을 추가하면"
    Write-Host "     테스트 전에 서버가 자동으로 시작됩니다:"
    Write-Host ""
    Write-Host "     webServer: {"
    Write-Host "       command: 'npm run dev',"
    Write-Host "       url: 'http://localhost:3000',"
    Write-Host "       reuseExistingServer: true,"
    Write-Host "     }"
} else {
    Write-Host "     Playwright 테스트 파일이 아직 없으면 Enter를 누르세요."
    Write-Host "     나중에 pairloop/pairloop.config.json 에서 추가할 수 있습니다."
    $testCommand = Prompt-Input "" ""
}
Write-Host ""

# ── 5 / 5  개발 서버 시작 명령 ───────────────────────────────────
Write-Host "5/6  개발 서버 시작 명령 (선택)" -ForegroundColor Cyan
Write-Host "     pair-watch가 테스트 전 서버를 자동으로 띄울 때 사용합니다."
Write-Host "     서버를 수동으로 띄울 계획이면 그냥 Enter."

# 패키지 매니저 자동 감지
if (Test-Path "pnpm-lock.yaml") { $defaultDevCmd = "pnpm dev" }
elseif (Test-Path "yarn.lock") { $defaultDevCmd = "yarn dev" }
else { $defaultDevCmd = "npm run dev" }

$devServerCommand = Prompt-Input "" $defaultDevCmd
Write-Host ""

# ── 6 / 6  브라우저 표시 여부 ─────────────────────────────────────
Write-Host "6/6  테스트 시 브라우저 창 표시 여부" -ForegroundColor Cyan
Write-Host "     y → 창을 띄움 (눈으로 확인 가능, 느림, 다른 작업 방해됨)"
Write-Host "     n → 안 띄움 (빠르고 백그라운드 실행, 권장)"
Write-Host ""
Write-Host "     안 띄워도 실패하면 trace/screenshot/video가 자동 저장되어"
Write-Host "     'npx playwright show-trace' 로 사후 재생할 수 있습니다."
$showBrowser = Prompt-Input "" "n"
if ($showBrowser -match '^(y|Y)') { $headlessValue = $false } else { $headlessValue = $true }
Write-Host ""

# ── pairloop/pairloop.config.json 생성 ─────────────────────────────
New-Item -ItemType Directory -Force -Path "pairloop" | Out-Null

$testSection = [ordered]@{ command = $testCommand }
if (-not [string]::IsNullOrWhiteSpace($devServerCommand)) {
    $testSection["devServerCommand"] = $devServerCommand
}
$testSection["headless"] = $headlessValue
$testSection["captureOnFailure"] = $true

$config = [ordered]@{
    '$schema' = "./pairloop.config.schema.json"
    project   = [ordered]@{ name = $projectName; bugPrefix = "BUG" }
    watch     = [ordered]@{ pingUrl = $pingUrl; gitBranch = $gitBranch }
    test      = $testSection
    intervals = [ordered]@{ pingSec = 30; gitSec = 180 }
}
$config | ConvertTo-Json -Depth 4 | Set-Content -Path "pairloop\pairloop.config.json" -Encoding utf8

Write-Host "✓ pairloop/pairloop.config.json 생성 완료" -ForegroundColor Green
Write-Host ""

# ── /api/ping 코드 안내 ───────────────────────────────────────────
Write-Host "======================================"
Write-Host "  마지막: 서버에 코드 한 줄 추가"
Write-Host "======================================"
Write-Host ""
Write-Host "Harness가 배포를 감지하려면 /api/ping 엔드포인트가 필요합니다."
Write-Host "아래 코드를 서버에 추가하세요. (1~2분 작업)"
Write-Host ""

$isNextJs  = (Test-Path "next.config.ts") -or (Test-Path "next.config.js") -or (Test-Path "next.config.mjs")
$isExpress = (Test-Path "package.json") -and ((Get-Content "package.json" -Raw) -match '"express"')

if ($isNextJs) {
    Write-Host "  [Next.js 감지됨]"
    Write-Host "  파일 생성: app/api/ping/route.ts"
    Write-Host ""
    Write-Host "  export async function GET() {"
    Write-Host "    return Response.json({"
    Write-Host "      commit: process.env.VERCEL_GIT_COMMIT_SHA ?? 'local'"
    Write-Host "    });"
    Write-Host "  }"
} elseif ($isExpress) {
    Write-Host "  [Express 감지됨]"
    Write-Host "  app.js 또는 routes 파일에 추가:"
    Write-Host ""
    Write-Host "  app.get('/api/ping', (req, res) => {"
    Write-Host "    res.json({ commit: process.env.COMMIT_SHA ?? 'local' });"
    Write-Host "  });"
} else {
    Write-Host "  GET /api/ping 에 아래 JSON을 반환하도록 추가하세요:"
    Write-Host ""
    Write-Host '  { "commit": "현재 배포된 git 커밋 해시 또는 local" }'
}

Write-Host ""
Write-Host "추가를 완료했으면 Claude Code 를 열고 아래를 입력하세요:"
Write-Host ""
Write-Host "  /pair-watch" -ForegroundColor Green
Write-Host ""
Write-Host "설치 완료입니다."
Write-Host ""
