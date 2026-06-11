# =============================================================================
# build_package.ps1 - Build Individual Dext Framework Packages
# =============================================================================
# Compiles a single framework package (or all packages) using MSBuild.
# Handles Delphi environment setup, output paths, and unit search paths
# exactly like build_framework.bat, but for individual packages.
#
# USAGE:
#   .\build_package.ps1 Dext.Core
#   .\build_package.ps1 Dext.EF.Core -Config Release
#   .\build_package.ps1 -All
#   .\build_package.ps1 Dext.Core -VerboseOutput
#
# EXAMPLES:
#   .\build_package.ps1 Dext.Core              # Build only Dext.Core
#   .\build_package.ps1 Dext.Web.Core          # Build only Dext.Web.Core
#   .\build_package.ps1 -All                   # Build all packages in order
#   .\build_package.ps1 Dext.Core -Clean       # Clean before building
#
# =============================================================================

param(
    [Parameter(Position=0)]
    [string]$PackageName = "",

    [string]$Config = "Debug",
    [string]$Platform = "Win32",
    [string]$DelphiVersion = "",
    [switch]$All,
    [switch]$Clean,
    [switch]$VerboseOutput
)

# =============================================================================
# CONSTANTS
# =============================================================================

# Build order matches build_framework.bat (dependency order)
$BuildOrder = @(
    "Dext.Core",
    "Dext.EF.Core",
    "Dext.Web.Core",
    "Dext.Web.Hubs",
    "Dext.Hosting",
    "Dext.Testing",
    "Dext.UI",
    "Dext.Net"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DextRoot  = Split-Path -Parent $ScriptDir
$SourcesDir = Join-Path $DextRoot "Sources"

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================
function Write-Info($Message)    { Write-Host $Message -ForegroundColor Cyan }
function Write-Success($Message) { Write-Host $Message -ForegroundColor Green }
function Write-Warn($Message)    { Write-Host $Message -ForegroundColor Yellow }
function Write-Err($Message)     { Write-Host $Message -ForegroundColor Red }
function Write-Detail($Message)  { Write-Host $Message -ForegroundColor Gray }

# =============================================================================
# Get-LatestDelphiVersion - Auto-detect from registry
# =============================================================================
function Get-LatestDelphiVersion {
    $RegistryPaths = @(
        "HKLM:\SOFTWARE\Embarcadero\BDS",
        "HKLM:\SOFTWARE\WOW6432Node\Embarcadero\BDS"
    )

    $FoundVersions = @()

    foreach ($RegPath in $RegistryPaths) {
        if (Test-Path $RegPath) {
            try {
                $BDSKeys = Get-ChildItem -Path $RegPath -ErrorAction SilentlyContinue
                foreach ($Key in $BDSKeys) {
                    $VersionName = $Key.PSChildName
                    if ($VersionName -match '^\d+\.\d+$') {
                        try {
                            $RootDir = Get-ItemProperty -Path $Key.PSPath -Name "RootDir" -ErrorAction SilentlyContinue
                            if ($RootDir -and $RootDir.RootDir -and (Test-Path $RootDir.RootDir)) {
                                $FoundVersions += [PSCustomObject]@{
                                    Version = $VersionName
                                    RootDir = $RootDir.RootDir
                                }
                            }
                        } catch { }
                    }
                }
            } catch { }
        }
    }

    if ($FoundVersions.Count -eq 0) { return $null }

    return ($FoundVersions | Sort-Object { [Version]$_.Version } -Descending)[0]
}

# =============================================================================
# Initialize-DelphiEnvironment - Load rsvars.bat and find MSBuild
# =============================================================================
function Initialize-DelphiEnvironment {
    param([string]$Version)

    . "$ScriptDir\set_env.ps1" -DelphiVersion $Version -Platform $env:PLATFORM -Config $env:BUILD_CONFIG
    
    return [PSCustomObject]@{
        Version    = $env:PRODUCT_VERSION
        DelphiPath = $env:BDS
    }
}

# =============================================================================
# Get-OutputPath - Calculate output directory (matches build_framework.bat)
# =============================================================================
function Get-OutputPath {
    param(
        [string]$ProductVersion,
        [string]$Platform,
        [string]$Config
    )

    # Output path format: $(dext)\Output\$(ProductVersion)\$(Platform)\$(Config)
    $OutputDir = Join-Path $DextRoot "Output\${ProductVersion}\${Platform}\${Config}"

    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    return $OutputDir
}

# =============================================================================
# Resolve-PackagePath - Find the .dproj file for a package name
# =============================================================================
function Resolve-PackagePath {
    param([string]$Name)

    # Try direct match in Sources directory
    $DprojFile = Join-Path $SourcesDir "$Name.dproj"
    if (Test-Path $DprojFile) { return $DprojFile }

    # Try Apps subdirectories (DextTool, DextSidecar, etc.)
    $AppsDir = Join-Path $DextRoot "Apps"
    $found = Get-ChildItem -Path $AppsDir -Recurse -Filter "$Name.dproj" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { return $found.FullName }

    # Try Tests subdirectories
    $TestsDir = Join-Path $DextRoot "Tests"
    $found = Get-ChildItem -Path $TestsDir -Recurse -Filter "$Name.dproj" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { return $found.FullName }

    return $null
}

# =============================================================================
# Build-Package - Build a single package
# =============================================================================
function Build-Package {
    param(
        [string]$Name,
        [string]$OutputPath,
        [string]$Config,
        [string]$Platform,
        [bool]$Verbose
    )

    $DprojPath = Resolve-PackagePath -Name $Name
    if (-not $DprojPath) {
        Write-Err "Package not found: $Name"
        Write-Err "Searched in: $SourcesDir"
        return $false
    }

    Write-Warn "Building $Name..."
    Write-Detail "  Project: $DprojPath"

    $CommonPath = Join-Path $SourcesDir "Common"
    $MSBuildArgs = @(
        $DprojPath,
        "/t:Build",
        "/p:Configuration=$Config",
        "/p:Config=$Config",
        "/p:Platform=$Platform",
        "/p:DCC_DcuOutput=`"$OutputPath`"",
        "/p:DCC_DcpOutput=`"$OutputPath`"",
        "/p:DCC_BplOutput=`"$OutputPath`"",
        "/p:DCC_OutputNeverBuildDcps=false",
        "/p:DCC_UnitSearchPath=`"$OutputPath;$CommonPath`"",
        "/nologo"
    )

    if ($Verbose) {
        $MSBuildArgs += "/v:normal"
    } else {
        $MSBuildArgs += "/v:minimal"
    }

    $BuildOutput = & msbuild @MSBuildArgs 2>&1
    $BuildExitCode = $LASTEXITCODE

    # Show output
    $BuildOutput | ForEach-Object { Write-Host $_ }

    if ($BuildExitCode -eq 0) {
        Write-Success "  $Name - OK"
        Write-Host ""
        return $true
    } else {
        Write-Err "  $Name - FAILED (exit code: $BuildExitCode)"
        Write-Host ""
        return $false
    }
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
try {
    # Validate parameters
    if (-not $All -and [string]::IsNullOrEmpty($PackageName)) {
        Write-Info "Usage: .\build_package.ps1 <PackageName> [-Config Debug|Release] [-Platform Win32|Win64] [-Clean] [-All]"
        Write-Host ""
        Write-Info "Available packages:"
        foreach ($pkg in $BuildOrder) {
            Write-Detail "  $pkg"
        }
        Write-Host ""
        Write-Info "Examples:"
        Write-Detail "  .\build_package.ps1 Dext.Core"
        Write-Detail "  .\build_package.ps1 Dext.Web.Core -VerboseOutput"
        Write-Detail "  .\build_package.ps1 -All"
        Write-Detail "  .\build_package.ps1 -All -Clean"
        exit 0
    }

    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    Write-Info "Dext Framework Package Builder"
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    Write-Host ""

    # 1. Initialize Delphi environment
    Write-Info "Initializing Delphi environment..."
    $DelphiEnv = Initialize-DelphiEnvironment -Version $DelphiVersion

    # 2. Calculate output path
    $OutputPath = Get-OutputPath -ProductVersion $DelphiEnv.Version -Platform $Platform -Config $Config
    Write-Detail "  Output: $OutputPath"
    Write-Host ""

    # 3. Clean if requested
    if ($Clean) {
        Write-Warn "Cleaning output directory..."
        Remove-Item "$OutputPath\*.dcu" -ErrorAction SilentlyContinue
        Remove-Item "$OutputPath\*.bpl" -ErrorAction SilentlyContinue
        Remove-Item "$OutputPath\*.dcp" -ErrorAction SilentlyContinue
        Write-Success "  Clean complete"
        Write-Host ""
    }

    # 4. Determine what to build
    if ($All) {
        $PackagesToBuild = $BuildOrder
    } else {
        $PackagesToBuild = @($PackageName)
    }

    # 5. Build
    $TotalCount = $PackagesToBuild.Count
    $SuccessCount = 0
    $FailedPackages = @()

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    foreach ($pkg in $PackagesToBuild) {
        $result = Build-Package -Name $pkg -OutputPath $OutputPath -Config $Config -Platform $Platform -Verbose $VerboseOutput

        if ($result) {
            $SuccessCount++
        } else {
            $FailedPackages += $pkg
            if ($All) {
                Write-Err "Build chain stopped at $pkg (dependency order)"
                break
            }
        }
    }

    $Stopwatch.Stop()

    # 6. Summary
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    Write-Info "Build Summary"
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    Write-Detail "  Packages: $SuccessCount/$TotalCount succeeded"
    Write-Detail "  Time:     $([math]::Round($Stopwatch.Elapsed.TotalSeconds, 1))s"
    Write-Detail "  Output:   $OutputPath"

    if ($FailedPackages.Count -gt 0) {
        Write-Err "  Failed:   $($FailedPackages -join ', ')"
        Write-Host ""
        Write-Err "BUILD FAILED"
        Write-Host ("=" * 60) -ForegroundColor DarkGray
        exit 1
    } else {
        Write-Host ""
        Write-Success "BUILD SUCCESSFUL"
        Write-Host ("=" * 60) -ForegroundColor DarkGray
        exit 0
    }
}
catch {
    Write-Err "Unexpected error: $($_.Exception.Message)"
    Write-Err "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
