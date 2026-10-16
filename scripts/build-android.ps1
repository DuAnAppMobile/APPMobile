param([string]$ApiBaseUrl = 'http://127.0.0.1:5137/api')
. (Join-Path $PSScriptRoot 'environment.ps1')
Push-Location (Join-Path (Split-Path -Parent $PSScriptRoot) 'flutter_app')
try {
    flutter build apk --release --dart-define="API_BASE_URL=$ApiBaseUrl"
    if ($LASTEXITCODE -ne 0) { throw 'Build APK that bai.' }
} finally { Pop-Location }
