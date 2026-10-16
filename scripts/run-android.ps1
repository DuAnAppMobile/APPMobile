param([string]$DeviceId, [string]$AvdName)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')
foreach ($tool in @('flutter', 'adb')) {
    if (!(Get-Command $tool -ErrorAction SilentlyContinue)) { throw "Thieu $tool. Chay scripts/setup.ps1 va doc README.md." }
}
. (Join-Path $PSScriptRoot 'ensure-backend.ps1')
$readyDevices = @(adb devices | ForEach-Object { if ($_ -match '^(\S+)\s+device$') { $matches[1] } })
if (!$DeviceId) {
    if ($readyDevices.Count -eq 1) { $DeviceId = $readyDevices[0] }
    elseif ($readyDevices.Count -gt 1) { throw 'Co nhieu thiet bi. Chay lai voi -DeviceId ID (xem adb devices).' }
}
if (!$DeviceId -or $readyDevices -notcontains $DeviceId) {
    if ($DeviceId) { throw 'Thiet bi chua san sang. Bat/mat khoa thiet bi va kiem tra adb devices.' }
    $emulator = Join-Path $env:ANDROID_HOME 'emulator\emulator.exe'
    if (!(Test-Path -LiteralPath $emulator)) { throw 'Chua cai Android Emulator. Cai bang Android Studio SDK Manager.' }
    $avds = @(& $emulator -list-avds | Where-Object { $_.Trim() })
    if (!$AvdName) {
        if ($avds.Count -eq 1) { $AvdName = $avds[0] }
        else { throw "Hay tao/bat 1 may ao tu Android Studio Device Manager, hoac dung -AvdName. AVD: $($avds -join ', ')" }
    }
    if ($avds -notcontains $AvdName) { throw "Khong tim thay AVD '$AvdName'." }
    Start-Process -FilePath $emulator -WindowStyle Hidden -ArgumentList @('-avd', $AvdName, '-gpu', 'swiftshader', '-no-snapshot') | Out-Null
    $booted = $false
    for ($i = 0; $i -lt 150; $i++) {
        Start-Sleep -Seconds 2
        $readyDevices = @(adb devices | ForEach-Object { if ($_ -match '^(\S+)\s+device$') { $matches[1] } })
        if ($readyDevices.Count -ne 1) { continue }
        $candidate = $readyDevices[0]
        if ((adb -s $candidate shell getprop sys.boot_completed) -match '^1') {
            $DeviceId = $candidate; $booted = $true; break
        }
    }
    if (!$booted) { throw 'May ao chua boot xong. Kiem tra ao hoa va Android Studio Device Manager.' }
}
adb -s $DeviceId reverse tcp:5137 tcp:5137
if ($LASTEXITCODE -ne 0) { throw 'Khong tao duoc ADB reverse. Kiem tra USB debugging.' }
Push-Location (Join-Path (Split-Path -Parent $PSScriptRoot) 'flutter_app')
try {
    flutter run -d $DeviceId --no-enable-impeller --dart-define=API_BASE_URL=http://127.0.0.1:5137/api
    if ($LASTEXITCODE -ne 0) { throw 'Flutter khong chay duoc. Xem loi phia tren.' }
} finally { Pop-Location }
