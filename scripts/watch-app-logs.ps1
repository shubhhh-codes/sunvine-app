# ============================================================================
# Real-Time Clean App Telemetry & Navigation Stream
# Usage: .\scripts\watch-app-logs.ps1
# Filters out OS and framework noise, displaying clean production telemetry:
#   [NAV]    Screen and Tab transitions
#   [ACTION] User button clicks and gestures
#   [API]    Cloudflare HTTP requests and response latency
#   [AUTH]   Session login and token status
# ============================================================================

[CmdletBinding()]
param(
    [string]$DeviceId = ""
)

$ErrorActionPreference = "Continue"

Write-Host "=== Sunvine EPC Mobile Live Telemetry Stream ===" -ForegroundColor Cyan

# 1. Locate adb
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
if (-not $AdbPath) { Write-Error "adb.exe not found."; exit 1 }

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
    Write-Error "No connected Android device found."
    exit 1
}

Write-Host "Connected Device: $DeviceId" -ForegroundColor Green
Write-Host "Streaming clean app logs (Press Ctrl+C to stop)...`n" -ForegroundColor DarkGray

# Clear existing logcat buffer
& $AdbPath -s $DeviceId logcat -c

# Stream only flutter tags
& $AdbPath -s $DeviceId logcat -v tag -s flutter:V | ForEach-Object {
    $line = $_
    if ($line -like "*[NAV]*") {
        Write-Host $line -ForegroundColor Magenta
    } elseif ($line -like "*[ACTION]*") {
        Write-Host $line -ForegroundColor Yellow
    } elseif ($line -like "*[API]*") {
        if ($line -match "2\d\d") {
            Write-Host $line -ForegroundColor Green
        } else {
            Write-Host $line -ForegroundColor Red
        }
    } elseif ($line -like "*[AUTH]*") {
        Write-Host $line -ForegroundColor Cyan
    } elseif ($line -like "*[ERROR]*") {
        Write-Host $line -ForegroundColor Red
    } elseif ($line -like "*[STATE]*") {
        Write-Host $line -ForegroundColor Blue
    }
}
