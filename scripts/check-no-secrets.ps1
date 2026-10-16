# ============================================================================
# Security Scanner: Detect Leaked Secret Literals in app/ and gateway/
# Rules: Scans for actual secret values (eyJ..., hardcoded tokens, long keys).
# Excludes: .dev.vars (local-only gitignored file) and node_modules.
# ============================================================================

$RootPath = (Get-Item $PSScriptRoot).Parent.FullName
$FoldersToScan = @("gateway\src", "gateway\migrations", "gateway\wrangler.toml", "gateway\package.json", "app\lib", "app\pubspec.yaml")

# Detect actual secret literals (not variable names or type declarations)
$ForbiddenPatterns = @(
    "eyJ[A-Za-z0-9_-]{20,}",
    "['`"]service_role['`"]",
    "SUPABASE_SERVICE_ROLE_KEY\s*=\s*['`"][^'`"]{10,}['`"]",
    "APP_JWT_SECRET\s*=\s*['`"][^'`"]{10,}['`"]",
    "JWT_SECRET\s*=\s*['`"][^'`"]{10,}['`"]",
    "sbp_[A-Za-z0-9_]{20,}"
)

$Findings = @()

foreach ($relPath in $FoldersToScan) {
    $target = Join-Path $RootPath $relPath
    if (-not (Test-Path $target)) { continue }

    $files = if ((Get-Item $target) -is [System.IO.DirectoryInfo]) {
        Get-ChildItem -Path $target -Recurse -File | Where-Object { $_.FullName -notmatch "node_modules|\.git|\.wrangler|\.dev\.vars" }
    } else {
        @(Get-Item $target)
    }

    foreach ($file in $files) {
        if ($file.Name -like ".dev.vars*" -and $file.Name -ne ".dev.vars.example") { continue }
        $lines = Get-Content -Path $file.FullName

        for ($i = 0; $i -lt $lines.Length; $i++) {
            $line = $lines[$i]
            foreach ($pattern in $ForbiddenPatterns) {
                if ($line -match $pattern) {
                    # Ignore comments or mock test strings
                    if ($line -match "^\s*//" -or $line -match "^\s*\*" -or $line -match "mock_" -or $line -match "\.dev\.vars\.example") {
                        continue
                    }
                    $Findings += [PSCustomObject]@{
                        File = $file.FullName.Replace($RootPath, "")
                        LineNumber = $i + 1
                        Snippet = $line.Trim().Substring(0, [Math]::Min(80, $line.Trim().Length))
                    }
                }
            }
        }
    }
}

if ($Findings.Count -eq 0) {
    Write-Host "CLEAN: Zero secrets found across app/ and gateway/." -ForegroundColor Green
    exit 0
} else {
    Write-Host "WARNING: Potential secret values detected:" -ForegroundColor Red
    $Findings | Format-Table -AutoSize
    exit 1
}
