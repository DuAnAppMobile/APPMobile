param([int]$Port = 5137)
$ErrorActionPreference = 'Stop'
if (Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue) {
    throw "Cong $Port da duoc dung. Tat backend dang chay truoc. Khong tu dong xoa hay ghi de database."
}
$serverRoot = Join-Path $PSScriptRoot 'server'
$exe = Join-Path $serverRoot 'EnglishRpg.Api.exe'
if (!(Test-Path -LiteralPath $exe)) { throw 'Hay giai nen TOAN BO file ZIP, khong chay truc tiep trong ZIP.' }
$dataRoot = Join-Path $PSScriptRoot 'data'
New-Item -ItemType Directory -Path $dataRoot -Force | Out-Null
$env:DatabaseProvider = 'Sqlite'
$env:ConnectionStrings__Sqlite = 'Data Source="' + (Join-Path $dataRoot 'english-quest-accounts.db') + '"'
$env:ASPNETCORE_ENVIRONMENT = 'Development'
$env:Logging__LogLevel__Microsoft = 'Warning'
Push-Location $serverRoot
try {
    & $exe --seed
    if ($LASTEXITCODE -ne 0) { throw 'Khong tao duoc database. Hay dat thu muc trong Documents, khong de trong Program Files.' }
    Write-Host "Backend demo local: http://127.0.0.1:$Port. Giu cua so nay mo. Ctrl+C de dung." -ForegroundColor Green
    & $exe --urls "http://127.0.0.1:$Port"
    if ($LASTEXITCODE -ne 0) { throw 'Backend gap loi. Xem thong bao phia tren.' }
} finally { Pop-Location }
