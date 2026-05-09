# install-pairloop.ps1 — pairloop 설치 (Windows PowerShell)
#
# 사용법:
#   cd your-project
#   powershell -File path\to\pairloop\scripts\install-pairloop.ps1
#
# 하는 일: install-pairloop.sh 와 동일.

$ErrorActionPreference = "Stop"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProtoDir    = Resolve-Path (Join-Path $ScriptDir "..")
$ProjectRoot = Get-Location
$SkillsDst   = Join-Path $env:USERPROFILE ".claude\skills"

# 제품에 포함되는 스킬 6개
$ProductSkills = @("pairloop-install", "pair-watch", "pair-watch-stop", "pair-fix", "pair-fix-stop", "pair-hand")

# 고객 프로젝트의 pairloop/ 폴더에 복사되는 템플릿 5개
$ProductTemplates = @("handoff.md", "known-pitfalls.md", "to-do.md", "result.md", "test-scenario.md")

# pairloop/ 폴더에 복사되는 TypeScript 헬퍼
$ProductLib = @("console-capture.ts")

Write-Host "=== pairloop 설치 ==="
Write-Host "  프로토타입 위치: $ProtoDir"
Write-Host "  설치 대상 프로젝트: $ProjectRoot"
Write-Host "  스킬 설치 위치: $SkillsDst"
Write-Host ""

function Confirm-YN($prompt) {
    $resp = Read-Host "$prompt [y/N]"
    return $resp -match '^[Yy]$'
}

# 1. SKILL.md 5개 복사
Write-Host "[1/3] ~/.claude/skills/ 에 스킬 복사"
if (-not (Test-Path $SkillsDst)) { New-Item -ItemType Directory -Force -Path $SkillsDst | Out-Null }
foreach ($name in $ProductSkills) {
    $src = Join-Path $ProtoDir "skills\$name"
    $dst = Join-Path $SkillsDst $name
    if (-not (Test-Path $src)) {
        Write-Host "  ⚠️  소스 없음, 건너뜀: $name"
        continue
    }
    if (Test-Path (Join-Path $dst "SKILL.md")) {
        if (Confirm-YN "  ⚠️  $name 이미 존재. 덮어쓸까요?") {
            Copy-Item -Recurse -Force $src $SkillsDst
            Write-Host "  ✓ 덮어씀: $name"
        } else {
            Write-Host "  - 건너뜀: $name"
        }
    } else {
        Copy-Item -Recurse -Force $src $SkillsDst
        Write-Host "  ✓ 설치: $name"
    }
}
Write-Host ""

# 2. 운영 문서 템플릿 5개 + TypeScript 헬퍼 복사 (pairloop/ 폴더)
Write-Host "[2/3] pairloop/ 폴더에 운영 문서 템플릿 복사 (없을 때만)"
$AutoDir = Join-Path $ProjectRoot "pairloop"
if (-not (Test-Path $AutoDir)) { New-Item -ItemType Directory -Force -Path $AutoDir | Out-Null }
foreach ($t in $ProductTemplates) {
    $dst = Join-Path $ProjectRoot "pairloop\$t"
    if (Test-Path $dst) {
        Write-Host "  - 이미 존재: pairloop/$t"
    } else {
        Copy-Item (Join-Path $ProtoDir "templates\$t") $dst
        Write-Host "  ✓ 복사: pairloop/$t"
    }
}
foreach ($f in $ProductLib) {
    $dst = Join-Path $ProjectRoot "pairloop\$f"
    if (Test-Path $dst) {
        Write-Host "  - 이미 존재: pairloop/$f"
    } else {
        Copy-Item (Join-Path $ProtoDir "lib\$f") $dst
        Write-Host "  ✓ 복사: pairloop/$f"
    }
}
Write-Host ""

# 3. JSON Schema 복사 (IDE 자동완성)
Write-Host "[3/3] pairloop/ 에 pairloop.config.schema.json 복사"
$schemaDst = Join-Path $ProjectRoot "pairloop\pairloop.config.schema.json"
if (Test-Path $schemaDst) {
    Write-Host "  - 이미 존재 — 건너뜀"
} else {
    Copy-Item (Join-Path $ProtoDir "pairloop.config.schema.json") $schemaDst
    Write-Host "  ✓ 복사됨"
}
Write-Host ""

Write-Host "=== 설치 완료 ==="
Write-Host ""

# 4. setup 자동 이어서 실행 (사용자 동의)
$SetupPs1 = Join-Path $ProtoDir "scripts\setup.ps1"
$ConfigPath = Join-Path $ProjectRoot "pairloop\pairloop.config.json"
if ((Test-Path $SetupPs1) -and (Test-Path $ConfigPath)) {
    Write-Host "  ℹ️  pairloop/pairloop.config.json 이 이미 존재합니다 — setup 자동 실행을 건너뜁니다."
    Write-Host ""
    Write-Host "  설정을 다시 만들고 싶으면 직접 실행하세요:"
    Write-Host "    powershell -File $SetupPs1"
} elseif (Test-Path $SetupPs1) {
    Write-Host "[4/4] 이어서 setup 스크립트를 실행합니다 (pairloop/pairloop.config.json 생성)."
    if (Confirm-YN "  지금 실행할까요?") {
        Write-Host ""
        & powershell -File $SetupPs1
    } else {
        Write-Host "  - 건너뜀. 나중에 직접 실행: powershell -File $SetupPs1"
    }
}

Write-Host ""
Write-Host "==================================================="
Write-Host "  남은 단계 (Claude Code 에서)"
Write-Host "==================================================="
Write-Host "  창 A:  /pair-watch   ← 처음 실행 시 시나리오 자동 생성"
Write-Host "  창 B:  /pair-fix"
Write-Host "  종료:  두 개의 창 모두에서  /pair-hand"
Write-Host ""
Write-Host "  (선택) 더 정확한 배포 감지를 원하면 /api/ping 엔드포인트 추가 — docs\ping-endpoint.md"
