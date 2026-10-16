# ============================================================================
# Development Launcher for Samsung Phone Testing
# Features:
#   1. Auto-locates adb in Android SDK
#   2. Verifies connected Android device (Samsung SM-S921E)
#   3. Runs adb reverse tcp:8787 tcp:8787
#   4. Checks Worker health at http://127.0.0.1:8787/v1/health
#   5. Launches Flutter app with --dart-define-from-file=env/dev.json
# ============================================================================

[CmdletBinding()]
param(
    [string]$DeviceId = "",
    [switch]$NoRun
)

$ErrorActionPreference = "Stop"

Write-Host "=== Sunvine EPC Phone Launcher ===" -ForegroundColor Cyan

# 1. Locate adb.exe
$AdbPath = ""
$CandidatePaths = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:ANDROID_HOME\platform-tools\adb.exe",
    "$env:ProgramFiles\Android\platform-tools\adb.exe"
)

foreach ($p in $CandidatePaths) {
    if (Test-Path $p) {
        $AdbPath = $p
        break
    }
}

if (-not $AdbPath) {
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) {
        $AdbPath = $cmd.Source
    }
}

if (-not $AdbPath) {
    Write-Error "Could not locate adb.exe. Please ensure Android SDK platform-tools are installed."
    exit 1
}

Write-Host "Found ADB: $AdbPath" -ForegroundColor DarkGray

# 2. Check connected devices
$deviceList = & $AdbPath devices | Where-Object { $_ -match "\bdevice\b" -and $_ -notmatch "List of devices" }
if (-not $deviceList) {
    Write-Error "No authorized Android device detected. Connect your Samsung phone via USB with USB debugging enabled."
    exit 1
}

$firstDevice = ($deviceList[0] -split "`t")[0].Trim()
if (-not $DeviceId) {
    $DeviceId = $firstDevice
}

$deviceModel = & $AdbPath -s $DeviceId shell getprop ro.product.model
Write-Host "Target Device: $DeviceId ($($deviceModel.Trim()))" -ForegroundColor Green

# 3. Setup port forwarding: adb reverse tcp:8787 tcp:8787
Write-Host "Configuring port forwarding: adb reverse tcp:8787 tcp:8787..." -ForegroundColor Yellow
$revResult = & $AdbPath -s $DeviceId reverse tcp:8787 tcp:8787
Write-Host "Port reverse active: $revResult" -ForegroundColor Green

# 4. Check Worker Health
Write-Host "Checking local Worker health..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://127.0.0.1:8787/v1/health" -TimeoutSec 3
    if ($health.ok -eq $true) {
        Write-Host "Worker Health: OK (Supabase: $($health.supabaseReachable), D1: $($health.d1), Env: $($health.env))" -ForegroundColor Green
    } else {
        Write-Host "Worker is reachable but reported unhealthy status." -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: Worker not responding at http://127.0.0.1:8787. Make sure 'npx wrangler dev' is running in gateway/." -ForegroundColor Red
}

if ($NoRun) {
    Write-Host "Setup complete (NoRun specified). Exiting." -ForegroundColor Green
    exit 0
}

# 5. Launch Flutter App
Write-Host "`nLaunching Flutter app on $DeviceId..." -ForegroundColor Cyan
Set-Location (Join-Path (Get-Item $PSScriptRoot).Parent.FullName "app")
flutter run -d $DeviceId --dart-define-from-file=env/dev.json
