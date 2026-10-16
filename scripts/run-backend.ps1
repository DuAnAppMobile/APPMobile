$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')
$env:Logging__LogLevel__Microsoft = 'Warning'
$backendRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'backend_api'
Push-Location $backendRoot
try {
    Write-Host 'Cap nhat database va nap du lieu mau...' -ForegroundColor Yellow
    dotnet run -- --seed
    if ($LASTEXITCODE -ne 0) { throw 'Khong the tao/nap database. Xem loi dotnet ben tren.' }
    Write-Host 'Backend: http://localhost:5137' -ForegroundColor Green
    dotnet run --urls http://0.0.0.0:5137
} finally { Pop-Location }
