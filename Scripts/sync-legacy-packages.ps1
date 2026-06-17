# Script to synchronize legacy Delphi packages using tmsdev
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$RepoRoot = (Resolve-Path "$PSScriptRoot\..").Path

$SourcesDir = "$RepoRoot\Sources"
$TempPackagesDir = "$RepoRoot\packages"
$TmsDevExe = "C:\dev\SmartSetup\tmsdev\tmsdev.exe"
$LegacyPackagesTargetDir = "$SourcesDir\packages"

Write-Host ">>> Iniciando sincronização de pacotes para Delphi XE2 a Delphi 10.3 Rio..." -ForegroundColor Cyan

# 1. Limpar/criar diretório temporário
if (Test-Path $TempPackagesDir) {
    Remove-Item $TempPackagesDir -Recurse -Force | Out-Null
}
$TempSydneyDir = New-Item -ItemType Directory -Force -Path "$TempPackagesDir\dsydney"

# 2. Copiar pacotes Sydney (10.4+) como base de origem
Write-Host ">>> Copiando pacotes Sydney do diretório Sources..." -ForegroundColor Gray
Copy-Item "$SourcesDir\*.dpk" $TempSydneyDir.FullName
Copy-Item "$SourcesDir\*.dproj" $TempSydneyDir.FullName
Copy-Item "$SourcesDir\*.res" $TempSydneyDir.FullName

# Copiar e filtrar o arquivo de grupo (.groupproj) para remover referências externas fora da pasta Sources
Write-Host ">>> Filtrando DextFramework.groupproj para remover executáveis externos..." -ForegroundColor Gray
$GroupProjContent = Get-Content "$SourcesDir\DextFramework.groupproj" -Raw
# Remove os blocos <Projects Include="..\..."> ... </Projects>
$GroupProjContent = $GroupProjContent -replace '(?s)\s*<Projects Include="\.\.\\.*?</Projects>', ''
# Salvar no diretório temporário
[System.IO.File]::WriteAllText((Join-Path $TempSydneyDir.FullName "DextFramework.groupproj"), $GroupProjContent)

# 3. Executar o tmsdev para sincronizar os pacotes legados
Write-Host ">>> Executando tmsdev sync-packages..." -ForegroundColor Yellow
$OldCwd = Get-Location
Set-Location $RepoRoot
try {
    & $TmsDevExe sync-packages -targets:delphixe2-delphirio -source:delphisydney -createtarget
}
finally {
    Set-Location $OldCwd
}

# 4. Mover pacotes gerados para a pasta Sources\packages
Write-Host ">>> Movendo pacotes gerados para a pasta de destino final ($LegacyPackagesTargetDir)..." -ForegroundColor Gray

# Garantir que a pasta de destino exista
if (!(Test-Path $LegacyPackagesTargetDir)) {
    New-Item -ItemType Directory -Force -Path $LegacyPackagesTargetDir | Out-Null
}

Get-ChildItem $TempPackagesDir -Directory | Where-Object { $_.Name -ne 'dsydney' } | ForEach-Object {
    $TargetFolder = Join-Path $LegacyPackagesTargetDir $_.Name
    if (Test-Path $TargetFolder) {
        Remove-Item $TargetFolder -Recurse -Force | Out-Null
    }
    Move-Item $_.FullName $LegacyPackagesTargetDir -Force
    Write-Host " Pacote legado '$($_.Name)' atualizado com sucesso em $LegacyPackagesTargetDir\$($_.Name)" -ForegroundColor Green
}

# 5. Limpar pasta temporária
Write-Host ">>> Limpando pasta temporária de pacotes..." -ForegroundColor Gray
Remove-Item $TempPackagesDir -Recurse -Force | Out-Null

Write-Host ">>> Processo concluído com sucesso!" -ForegroundColor Green
