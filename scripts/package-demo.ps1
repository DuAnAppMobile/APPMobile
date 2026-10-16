param([string]$OutputDir)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')
$repoRoot = Split-Path -Parent $PSScriptRoot
if (!$OutputDir) { $OutputDir = Join-Path $repoRoot 'dist\EnglishQuest-Demo-Windows' }
$OutputDir = [IO.Path]::GetFullPath($OutputDir)
if (Test-Path -LiteralPath $OutputDir) { throw 'Chon thu muc output moi, trong. Khong ghi de bo demo co database.' }
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Push-Location (Join-Path $repoRoot 'backend_api')
try {
    dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=false -o (Join-Path $OutputDir 'server')
    if ($LASTEXITCODE -ne 0) { throw 'Publish backend that bai.' }
} finally { Pop-Location }
Push-Location (Join-Path $repoRoot 'flutter_app')
try {
    flutter build apk --release --target-platform 'android-arm,android-arm64,android-x64' --dart-define=API_BASE_URL=http://127.0.0.1:5137/api
    if ($LASTEXITCODE -ne 0) { throw 'Build APK that bai.' }
    Copy-Item 'build\app\outputs\flutter-apk\app-release.apk' (Join-Path $OutputDir 'English-Quest-Local.apk')
} finally { Pop-Location }
Copy-Item (Join-Path $repoRoot 'packaging\demo\*') $OutputDir
if (Get-ChildItem -LiteralPath $OutputDir -Recurse -File | Where-Object { $_.Name -match '\.db($|-)' }) {
    throw 'Co database trong goi. Khong duoc chia se goi nay cho den khi kiem tra.'
}
Write-Host "Bo demo moi (khong database): $OutputDir" -ForegroundColor Green
