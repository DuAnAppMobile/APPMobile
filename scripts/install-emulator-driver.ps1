$ErrorActionPreference = 'Stop'
$driverRoot = Join-Path ([Environment]::GetEnvironmentVariable('ANDROID_HOME', 'User')) 'extras\google\Android_Emulator_Hypervisor_Driver'
$installer = Join-Path $driverRoot 'silent_install_safe.bat'
if (-not (Test-Path $installer)) { throw 'Install Android Emulator Hypervisor Driver from Android Studio SDK Manager first.' }
$logPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'emulator-driver-install.log'
Push-Location $driverRoot
try {
    & $installer *>&1 | Tee-Object -FilePath $logPath
    if ($LASTEXITCODE -ne 0) { throw "Driver installation failed. See $logPath" }
} finally { Pop-Location }
