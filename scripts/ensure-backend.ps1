$ErrorActionPreference = 'Stop'
function Test-QuestBackend {
    try {
        $health = Invoke-RestMethod 'http://127.0.0.1:5137/health' -TimeoutSec 2
        return ($health.service -eq 'EnglishQuest' -and $health.version -eq 'accounts-v1')
    } catch { return $false }
}
if (Test-QuestBackend) { return }
if (Get-NetTCPConnection -State Listen -LocalPort 5137 -ErrorAction SilentlyContinue) {
    throw 'Cong 5137 dang bi chiem hoac backend cu chua cap nhat. Tat backend cu, roi chay scripts/run-backend.ps1.'
}
$logRoot = Join-Path (Split-Path -Parent $PSScriptRoot) '.run-logs'
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$errorLog = Join-Path $logRoot "backend-$stamp.err.log"
$outputLog = Join-Path $logRoot "backend-$stamp.out.log"
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', ('"' + (Join-Path $PSScriptRoot 'run-backend.ps1') + '"')) -RedirectStandardOutput $outputLog -RedirectStandardError $errorLog | Out-Null
for ($i = 0; $i -lt 120; $i++) {
    if (Test-QuestBackend) { return }
    Start-Sleep -Seconds 1
}
throw "Backend chua san sang. Chay scripts/run-backend.ps1 de xem loi. Log: $errorLog"
