# =============================================================================
# Test.Dashboard.API.ps1
# Dext Dashboard API Endpoint Tests
# =============================================================================
# Usage: 
#   1. Start the dashboard: dext ui
#   2. Run this script: .\Test.Dashboard.API.ps1
# =============================================================================

param(
    [string]$BaseUrl = "http://localhost:3000"
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Success { param($msg) Write-Host "[PASS] " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Write-Failure { param($msg) Write-Host "[FAIL] " -ForegroundColor Red -NoNewline; Write-Host $msg }
function Write-Info { param($msg) Write-Host "[INFO] " -ForegroundColor Cyan -NoNewline; Write-Host $msg }
function Write-TestHeader { param($msg) Write-Host "`n=== $msg ===" -ForegroundColor Yellow }

$TotalTests = 0
$PassedTests = 0
$FailedTests = 0

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method = "GET",
        [string]$Endpoint,
        [string]$Body = $null,
        [scriptblock]$Validate = $null
    )
    
    $script:TotalTests++
    $Url = "$BaseUrl$Endpoint"
    
    Write-Host "`nTesting: $Name" -ForegroundColor White
    Write-Host "  $Method $Url" -ForegroundColor DarkGray
    
    try {
        $Headers = @{ "Content-Type" = "application/json" }
        
        if ($Method -eq "GET") {
            $Response = Invoke-WebRequest -Uri $Url -Method GET -Headers $Headers -TimeoutSec 10
        }
        elseif ($Method -eq "POST") {
            if ($Body) {
                $Response = Invoke-WebRequest -Uri $Url -Method POST -Headers $Headers -Body $Body -TimeoutSec 10
            }
            else {
                $Response = Invoke-WebRequest -Uri $Url -Method POST -Headers $Headers -TimeoutSec 10
            }
        }
        
        $StatusCode = $Response.StatusCode
        $Content = $Response.Content
        
        Write-Host "  Status: $StatusCode" -ForegroundColor DarkGray
        
        if ($StatusCode -ge 200 -and $StatusCode -lt 300) {
            # Custom validation if provided
            if ($Validate) {
                $ValidationResult = & $Validate $Content
                if ($ValidationResult -eq $true) {
                    Write-Success $Name
                    $script:PassedTests++
                }
                else {
                    Write-Failure "$Name - Validation failed: $ValidationResult"
                    $script:FailedTests++
                }
            }
            else {
                Write-Success $Name
                $script:PassedTests++
            }
            
            # Show response preview
            if ($Content.Length -gt 200) {
                Write-Host "  Response: $($Content.Substring(0, 200))..." -ForegroundColor DarkGray
            }
            else {
                Write-Host "  Response: $Content" -ForegroundColor DarkGray
            }
        }
        else {
            Write-Failure "$Name - Status code: $StatusCode"
            $script:FailedTests++
        }
    }
    catch {
        Write-Failure "$Name - Error: $($_.Exception.Message)"
        $script:FailedTests++
    }
}

# =============================================================================
# MAIN
# =============================================================================

Write-Host "`n" 
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "   Dext Dashboard API Tests" -ForegroundColor Magenta
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "Base URL: $BaseUrl" -ForegroundColor DarkGray
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray

# Check if server is running
Write-Info "Checking if dashboard is running..."
try {
    $null = Invoke-WebRequest -Uri $BaseUrl -Method GET -TimeoutSec 5
    Write-Success "Dashboard is running!"
}
catch {
    Write-Failure "Dashboard is not running on $BaseUrl"
    Write-Host "`nPlease start the dashboard first:" -ForegroundColor Yellow
    Write-Host "  dext ui" -ForegroundColor White
    exit 1
}

# =============================================================================
# TEST: Dashboard HTML
# =============================================================================
Write-TestHeader "Dashboard HTML"

Test-Endpoint -Name "GET / (Dashboard HTML)" -Method "GET" -Endpoint "/" -Validate {
    param($content)
    if ($content -match "<!DOCTYPE html>" -and $content -match "Dext Dashboard") {
        return $true
    }
    return "Missing DOCTYPE or title"
}

# =============================================================================
# TEST: Configuration API
# =============================================================================
Write-TestHeader "Configuration API"

Test-Endpoint -Name "GET /api/config" -Method "GET" -Endpoint "/api/config" -Validate {
    param($content)
    $json = $content | ConvertFrom-Json
    if ($json.PSObject.Properties["environments"]) {
        return $true
    }
    return "Missing 'environments' property"
}

# =============================================================================
# TEST: Projects API
# =============================================================================
Write-TestHeader "Projects API"

Test-Endpoint -Name "GET /api/projects" -Method "GET" -Endpoint "/api/projects" -Validate {
    param($content)
    try {
        $json = $content | ConvertFrom-Json
        # It's an array (can be empty)
        if ($json -is [System.Array] -or $content -eq "[]") {
            return $true
        }
        return "Response is not an array"
    }
    catch {
        return "Invalid JSON"
    }
}

# =============================================================================
# TEST: Test Summary API
# =============================================================================
Write-TestHeader "Test Summary API"

Test-Endpoint -Name "GET /api/test/summary" -Method "GET" -Endpoint "/api/test/summary" -Validate {
    param($content)
    $json = $content | ConvertFrom-Json
    if ($json.PSObject.Properties["available"]) {
        return $true
    }
    return "Missing 'available' property"
}

# =============================================================================
# TEST: Environment Scan API
# =============================================================================
Write-TestHeader "Environment Scan API"

Test-Endpoint -Name "POST /api/env/scan" -Method "POST" -Endpoint "/api/env/scan" -Validate {
    param($content)
    $json = $content | ConvertFrom-Json
    if ($json.status -eq "ok") {
        return $true
    }
    return "Expected status 'ok'"
}

# =============================================================================
# TEST: Config POST (Save)
# =============================================================================
Write-TestHeader "Config Save API"

$ConfigBody = '{"dextPath":"","coveragePath":""}'
Test-Endpoint -Name "POST /api/config (save config)" -Method "POST" -Endpoint "/api/config" -Body $ConfigBody -Validate {
    param($content)
    $json = $content | ConvertFrom-Json
    if ($json.status -eq "saved") {
        return $true
    }
    return "Expected status 'saved'"
}

# =============================================================================
# SUMMARY
# =============================================================================

Write-Host "`n"
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "   TEST SUMMARY" -ForegroundColor Magenta
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Total Tests:  $TotalTests" -ForegroundColor White
Write-Host "  Passed:       $PassedTests" -ForegroundColor Green
Write-Host "  Failed:       $FailedTests" -ForegroundColor Red
Write-Host ""

if ($FailedTests -eq 0) {
    Write-Host "ALL TESTS PASSED!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "SOME TESTS FAILED!" -ForegroundColor Red
    exit 1
}
