$ErrorActionPreference = 'Stop'
# Refresh PATH so terminals opened before SDK installation also work.
$env:Path = $env:Path + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
$androidHome = [Environment]::GetEnvironmentVariable('ANDROID_HOME', 'User')
$javaHome = [Environment]::GetEnvironmentVariable('JAVA_HOME', 'User')
if ($androidHome) { $env:ANDROID_HOME = $androidHome }
if ($javaHome) { $env:JAVA_HOME = $javaHome }
if (!$env:ANDROID_HOME -and $env:ANDROID_SDK_ROOT) { $env:ANDROID_HOME = $env:ANDROID_SDK_ROOT }
if (!$env:ANDROID_HOME) { $env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
if (!$env:JAVA_HOME) { $env:JAVA_HOME = Join-Path ${env:ProgramFiles} 'Android\Android Studio\jbr' }
foreach ($extraPath in @(
    (Join-Path $env:ANDROID_HOME 'platform-tools'),
    (Join-Path $env:ANDROID_HOME 'emulator'),
    (Join-Path $env:JAVA_HOME 'bin'),
    (Join-Path $env:USERPROFILE 'Documents\Codex\toolchains\flutter\bin')
)) {
    if (Test-Path -LiteralPath $extraPath) { $env:Path = $extraPath + ';' + $env:Path }
}
