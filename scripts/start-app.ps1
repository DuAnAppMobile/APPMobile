$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'ensure-backend.ps1')
if (Get-NetTCPConnection -State Listen -LocalPort 8082 -ErrorAction SilentlyContinue) {
    $chromePath = Join-Path ${env:ProgramFiles} 'Google\Chrome\Application\chrome.exe'
    if (Test-Path $chromePath) {
        Start-Process -FilePath $chromePath -ArgumentList 'http://127.0.0.1:8082'
        return
    }
}
& (Join-Path $PSScriptRoot 'run-web.ps1')
