. (Join-Path $PSScriptRoot 'environment.ps1')
$projectPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'flutter_app'
$studioPath = Join-Path ${env:ProgramFiles} 'Android\Android Studio\bin\studio64.exe'
if (-not (Test-Path $studioPath)) { throw 'Android Studio is not installed.' }
Start-Process -FilePath $studioPath -ArgumentList ('"' + $projectPath + '"')
