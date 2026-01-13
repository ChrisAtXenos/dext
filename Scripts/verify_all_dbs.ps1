$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Multi-Database Verification..." -ForegroundColor Cyan

# Check if executable exists
$ExePath = "..\Examples\Orm.EntityDemo\Orm.EntityDemo.exe"
if (-not (Test-Path $ExePath)) {
    Write-Error "Executable not found at $ExePath. Please build first."
}

# Define test matrix
$dbs = @(
    "SQLite",
    "PostgreSQL",
    "MySQL",
    "Firebird",
    "SQLServer"
)

$failed = @()

foreach ($db in $dbs) {
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host "testing Provider: $db" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    
    try {
        # Run process and wait
        $proc = Start-Process -FilePath $ExePath -ArgumentList $db -Wait -NoNewWindow -PassThru
        
        if ($proc.ExitCode -ne 0) {
            Write-Host "❌ Tests FAILED for $db (Exit Code: $($proc.ExitCode))" -ForegroundColor Red
            $failed += $db
        } else {
            Write-Host "✅ Tests PASSED for $db" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Error executing test for $db : $_" -ForegroundColor Red
        $failed += $db
    }
}

Write-Host "`n----------------------------------------"
if ($failed.Count -eq 0) {
    Write-Host "🎉 ALL DATABASE CHECKS PASSED!" -ForegroundColor Green
} else {
    Write-Host "❌ SOME CHECKS FAILED: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
