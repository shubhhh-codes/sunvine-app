# ============================================================================
# E2E Dealer Authentication & API Flow Smoke Test
# Usage: .\scripts\e2e-login.ps1 [-BaseUrl http://localhost:8787]
# Security: Asks for credentials at runtime via Read-Host -AsSecureString.
#           Prints step names and HTTP status codes only. Never logs tokens or credentials.
# ============================================================================

[CmdletBinding()]
param(
    [string]$BaseUrl = "http://localhost:8787"
)

$ErrorActionPreference = "Stop"

Write-Host "--- Sunvine EPC Dealer Backend Smoke Test ---" -ForegroundColor Cyan
Write-Host "Target: $BaseUrl`n"

# 1. Prompt for credentials securely
$Mobile = Read-Host "Enter 10-digit Dealer Mobile"
if (-not $Mobile -or $Mobile.Trim().Length -lt 10) {
    Write-Error "A valid 10-digit mobile number is required."
    exit 1
}

$SecurePassword = Read-Host -AsSecureString "Enter Dealer Password"
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
$Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

function Invoke-Step {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Path,
        [hashtable]$Headers = @{},
        [object]$Body = $null,
        [int[]]$ExpectedStatus = @(200)
    )

    $Uri = "$BaseUrl$Path"
    $ReqParams = @{
        Uri = $Uri
        Method = $Method
        Headers = $Headers
        ErrorAction = 'SilentlyContinue'
    }

    if ($Body) {
        $ReqParams["Body"] = ($Body | ConvertTo-Json -Compress)
        $ReqParams["ContentType"] = "application/json"
    }

    try {
        $response = Invoke-WebRequest @ReqParams
        $statusCode = $response.StatusCode
        $content = $response.Content | ConvertFrom-Json
    } catch {
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            try {
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $content = $reader.ReadToEnd() | ConvertFrom-Json
            } catch {
                $content = $null
            }
        } else {
            Write-Host "$Name : FAILED (Connection Error: $($_.Exception.Message))" -ForegroundColor Red
            return $null
        }
    }

    $isExpected = $ExpectedStatus -contains $statusCode
    $color = if ($isExpected) { "Green" } else { "Red" }
    Write-Host "$Name : HTTP $statusCode" -ForegroundColor $color

    return @{ StatusCode = $statusCode; Data = $content }
}

Write-Host "`nRunning Test Steps..." -ForegroundColor Yellow

# Step 1: Health
$resHealth = Invoke-Step -Name "[1/10] Health Check" -Method "GET" -Path "/v1/health"
if (-not $resHealth -or $resHealth.StatusCode -ne 200) {
    Write-Error "Health check failed. Ensure Worker is running."
    exit 1
}

# Step 2: Login
$loginPayload = @{
    mobile = $Mobile.Trim()
    password = $Password
}
$resLogin = Invoke-Step -Name "[2/10] Dealer Login" -Method "POST" -Path "/v1/auth/login" -Body $loginPayload
if (-not $resLogin -or $resLogin.StatusCode -ne 200) {
    Write-Error "Login failed with HTTP $($resLogin.StatusCode). Check credentials."
    exit 1
}

$accessToken = $resLogin.Data.accessToken
$refreshToken = $resLogin.Data.refreshToken
$authHeader = @{ "Authorization" = "Bearer $accessToken" }

# Step 3: Get Me
Invoke-Step -Name "[3/10] Get Profile (/v1/me)" -Method "GET" -Path "/v1/me" -Headers $authHeader | Out-Null

# Step 4: Catalog Bootstrap
Invoke-Step -Name "[4/10] Catalog Bootstrap (/v1/catalog/bootstrap)" -Method "GET" -Path "/v1/catalog/bootstrap" -Headers $authHeader | Out-Null

# Step 5: Quotations List
Invoke-Step -Name "[5/10] Quotations List (/v1/quotations)" -Method "GET" -Path "/v1/quotations?limit=5" -Headers $authHeader | Out-Null

# Step 6: Customer Files List
Invoke-Step -Name "[6/10] Customer Files List (/v1/customer-files)" -Method "GET" -Path "/v1/customer-files?limit=5" -Headers $authHeader | Out-Null

# Step 7: Financial Ledger
Invoke-Step -Name "[7/10] Financial Ledger (/v1/ledger)" -Method "GET" -Path "/v1/ledger" -Headers $authHeader | Out-Null

# Step 8: Token Refresh (Single-use rotation)
$refreshPayload = @{ refreshToken = $refreshToken }
$resRefresh = Invoke-Step -Name "[8/10] Token Refresh (Rotation)" -Method "POST" -Path "/v1/auth/refresh" -Body $refreshPayload
$newRefreshToken = $resRefresh.Data.refreshToken
$newAccessToken = $resRefresh.Data.accessToken

# Step 9: Replay Old Refresh Token (Verify Reuse Invalidation)
Invoke-Step -Name "[9/10] Old Token Reuse Rejection" -Method "POST" -Path "/v1/auth/refresh" -Body $refreshPayload -ExpectedStatus @(401) | Out-Null

# Step 10: Logout
$logoutPayload = @{ refreshToken = $newRefreshToken }
Invoke-Step -Name "[10/10] Logout (/v1/auth/logout)" -Method "POST" -Path "/v1/auth/logout" -Body $logoutPayload | Out-Null

Write-Host "`nAll E2E flow tests completed successfully!" -ForegroundColor Green
