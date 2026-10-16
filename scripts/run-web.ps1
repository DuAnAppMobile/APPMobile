$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')
$flutterRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'flutter_app'
Push-Location $flutterRoot
try {
    flutter run -d chrome --web-hostname 127.0.0.1 --web-port 8082 --dart-define=API_BASE_URL=http://127.0.0.1:5137/api
} finally { Pop-Location }
