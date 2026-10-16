$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')
$repoRoot = Split-Path -Parent $PSScriptRoot
$flutterRoot = Join-Path $repoRoot 'flutter_app'
$backendRoot = Join-Path $repoRoot 'backend_api'

Write-Host '== English Quest: kiem tra moi truong ==' -ForegroundColor Cyan

foreach ($toolName in @('git', 'dotnet', 'flutter')) {
    if (-not (Get-Command $toolName -ErrorAction SilentlyContinue)) {
        throw "Thieu cong cu '$toolName'. Doc README.md phan Cai cong cu."
    }
}

$sdkVersions = dotnet --list-sdks
if (-not ($sdkVersions -match '^10\.')) {
    throw 'Can .NET SDK 10.x de build backend.'
}

if (-not (Test-Path (Join-Path $flutterRoot 'android'))) {
    Write-Host 'Tao Android scaffold...' -ForegroundColor Yellow
    Push-Location $flutterRoot
    try { flutter create --platforms=android . } finally { Pop-Location }
}

Write-Host 'Tai Flutter packages...' -ForegroundColor Yellow
Push-Location $flutterRoot
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get that bai.' }
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'flutter analyze that bai.' }
    flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Flutter test that bai.' }
} finally { Pop-Location }

Write-Host 'Restore va build backend...' -ForegroundColor Yellow
Push-Location $backendRoot
try {
    dotnet restore
    if ($LASTEXITCODE -ne 0) { throw 'dotnet restore that bai.' }
    dotnet build --no-restore
    if ($LASTEXITCODE -ne 0) { throw 'Backend build that bai.' }
    dotnet run --no-build -- --seed
    if ($LASTEXITCODE -ne 0) { throw 'Khong tao duoc database moi.' }
} finally { Pop-Location }

Write-Host ''
Write-Host 'Setup hoan tat. Chay scripts/run-backend.ps1, sau do run-web.ps1 hoac run-android.ps1.' -ForegroundColor Green
