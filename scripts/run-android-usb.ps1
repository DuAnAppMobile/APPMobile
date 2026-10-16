param([Parameter(Mandatory=$true)][string]$DeviceId)
. (Join-Path $PSScriptRoot 'environment.ps1')
. (Join-Path $PSScriptRoot 'ensure-backend.ps1')
adb -s $DeviceId reverse tcp:5137 tcp:5137
if ($LASTEXITCODE -ne 0) { throw 'Kiem tra USB debugging va cho phep may tinh tren dien thoai.' }
Push-Location (Join-Path (Split-Path -Parent $PSScriptRoot) 'flutter_app')
try {
    flutter run -d $DeviceId --dart-define=API_BASE_URL=http://127.0.0.1:5137/api
} finally { Pop-Location }
