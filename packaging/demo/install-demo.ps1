param([string]$DeviceId)
$ErrorActionPreference = 'Stop'
$adbCommand = Get-Command adb -ErrorAction SilentlyContinue
if ($adbCommand) { $adb = $adbCommand.Source }
else {
    $sdk = $env:ANDROID_HOME
    if (!$sdk) { $sdk = $env:ANDROID_SDK_ROOT }
    if (!$sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
    $adb = Join-Path $sdk 'platform-tools\adb.exe'
}
if (!(Test-Path -LiteralPath $adb)) { throw 'Can Android Studio + Android SDK Platform Tools. Hoac cai APK bang cach keo tha vao may ao.' }
$health = Invoke-RestMethod 'http://127.0.0.1:5137/health' -TimeoutSec 3
if ($health.service -ne 'EnglishQuest' -or $health.version -ne 'accounts-v1') { throw 'Hay chay CHAY-BACKEND.cmd cua bo nay truoc.' }
$devices = @(& $adb devices | ForEach-Object { if ($_ -match '^(\S+)\s+device$') { $matches[1] } })
if (!$DeviceId) {
    if ($devices.Count -ne 1) { throw 'Hay bat dung 1 may ao, hoac cam 1 dien thoai USB debugging. Nhieu thiet bi: dung -DeviceId.' }
    $DeviceId = $devices[0]
}
if ($devices -notcontains $DeviceId) { throw 'Thiet bi chua san sang. Mo khoa va chap nhan USB debugging.' }
$apk = Join-Path $PSScriptRoot 'English-Quest-Local.apk'
& $adb -s $DeviceId reverse tcp:5137 tcp:5137
if ($LASTEXITCODE -ne 0) { throw 'ADB reverse that bai.' }
& $adb -s $DeviceId install -r $apk
if ($LASTEXITCODE -ne 0) { throw 'Khong cai duoc APK. Neu trung chu ky ban cu, tu go ban cu (se mat du lieu local) roi thu lai.' }
& $adb -s $DeviceId shell am start -n com.vanviet.englishquest/.MainActivity
if ($LASTEXITCODE -ne 0) { throw 'Khong mo duoc app.' }
Write-Host 'App da mo. Dang ky tai khoan moi. Moi may tinh co database rieng.' -ForegroundColor Green
