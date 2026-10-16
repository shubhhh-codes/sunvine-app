# ============================================================================
# Sunvine EPC App Launcher & Real-Time Telemetry Stream
# Usage: npm run app:launch
# ============================================================================

[CmdletBinding()]
param(
    [string]$DeviceId = ""
)

$ErrorActionPreference = "Continue"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host " [Sunvine EPC] Mobile Launcher & Telemetry Stream" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# 1. Locate adb.exe
$AdbPath = ""
$CandidatePaths = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:ANDROID_HOME\platform-tools\adb.exe",
    "$env:ProgramFiles\Android\platform-tools\adb.exe"
)
foreach ($p in $CandidatePaths) {
    if (Test-Path $p) { $AdbPath = $p; break }
}
if (-not $AdbPath) {
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) { $AdbPath = $cmd.Source }
}
if (-not $AdbPath) {
    Write-Host "`n[ERROR] adb.exe not found in standard Android SDK paths or PATH." -ForegroundColor Red
    exit 1
}

# 2. Get connected device
if (-not $DeviceId) {
    $rawDevices = & $AdbPath devices
    foreach ($dLine in $rawDevices) {
        if ($dLine -match "^([^\s]+)\s+device$") {
            $DeviceId = $Matches[1].Trim()
            break
        }
    }
}

if (-not $DeviceId) {
    Write-Host "`n[ERROR] No connected Android device found. Please connect your phone via USB with USB debugging enabled." -ForegroundColor Red
    exit 1
}

$model = (& $AdbPath -s $DeviceId shell getprop ro.product.model).Trim()
Write-Host "[OK] Connected Device: $model ($DeviceId)" -ForegroundColor Green

# 3. Launch application on phone (force-stop and restart fresh)
Write-Host "[...] Starting Sunvine EPC on $model..." -ForegroundColor Yellow
& $AdbPath -s $DeviceId shell am start -S -n com.sunvine.epc/.MainActivity | Out-Null

Write-Host "[OK] App launched successfully!" -ForegroundColor Green
Write-Host "[i] Streaming live clean logs in this terminal (Press Ctrl+C to stop)...`n" -ForegroundColor DarkGray

# 4. Stream only clean production logs starting from current timestamp (-T 1)
try {
    & $AdbPath -s $DeviceId logcat -T 1 -v brief -s flutter:V | ForEach-Object {
        $line = $_
        if ($line -match "\[(NAV|ACTION|API|AUTH|ERROR|STATE)\]") {
            $clean = $line -replace "^[IWEF]/flutter\s*\(\s*\d+\):\s*", ""
            
            if ($clean -match "\[NAV\]") {
                Write-Host $clean -ForegroundColor Magenta
            } elseif ($clean -match "\[ACTION\]") {
                Write-Host $clean -ForegroundColor Yellow
            } elseif ($clean -match "\[API\]") {
                if ($clean -match "2\d\d") {
                    Write-Host $clean -ForegroundColor Green
                } else {
                    Write-Host $clean -ForegroundColor Red
                }
            } elseif ($clean -match "\[AUTH\]") {
                Write-Host $clean -ForegroundColor Cyan
            } elseif ($clean -match "\[ERROR\]") {
                Write-Host $clean -ForegroundColor Red
            } elseif ($clean -match "\[STATE\]") {
                Write-Host $clean -ForegroundColor Blue
            } else {
                Write-Host $clean -ForegroundColor White
            }
        }
    }
} finally {
    Write-Host "`n[x] App log stream closed." -ForegroundColor Yellow
}
