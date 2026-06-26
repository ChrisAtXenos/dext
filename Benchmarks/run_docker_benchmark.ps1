# run_docker_benchmark.ps1 - Compilação cruzada e execução automatizada do benchmark no Docker (Ubuntu)
#
# Uso:
#   .\run_docker_benchmark.ps1

$ErrorActionPreference = "Stop"

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host " AUTOMATIZAÇÃO DE BENCHMARK REAL VIA DOCKER (UBUNTU)" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan

# 1. Verificar se o Docker está rodando ou disponível
try {
    & docker ps &>$null
} catch {
    Write-Error "O comando docker falhou ou o Docker Desktop não está rodando. Por favor, inicie o Docker Desktop no Windows."
}

# 2. Caminhos dos Projetos
$DextProj = Join-Path $PSScriptRoot "Dext.Benchmarks.dproj"
$HorseProj = "d:\Delphi\horse\samples\delphi\epoll\EpollConsole.dproj"

$DextBinSource = Join-Path $PSScriptRoot "Linux64\Release\Dext.Benchmarks"
$HorseBinSource = "d:\Delphi\horse\samples\delphi\epoll\Linux64\Release\EpollConsole"

# 3. Compilação Cruzada dos Servidores para Linux64
Write-Host "`n[1/4] Compilando Dext.Benchmarks para Linux64 (Release)..." -ForegroundColor Yellow
& Powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\..\..\DelphiBuildDPROJ.ps1" -ProjectFile $DextProj -Config Release -Platform Linux64

Write-Host "`n[2/4] Compilando Horse EpollConsole para Linux64 (Release)..." -ForegroundColor Yellow
& Powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\..\..\DelphiBuildDPROJ.ps1" -ProjectFile $HorseProj -Config Release -Platform Linux64

# 4. Preparar contexto do Docker Build
Write-Host "`n[3/4] Preparando contexto de arquivos para o Docker..." -ForegroundColor Gray
$TempHorseBin = Join-Path $PSScriptRoot "EpollConsole"
Copy-Item -Path $HorseBinSource -Destination $TempHorseBin -Force

# 5. Construir Imagem Docker
Write-Host "`n[4/4] Construindo imagem Docker (Ubuntu 22.04)..." -ForegroundColor Yellow
& docker build -t dext-vs-horse-bench $PSScriptRoot

# Limpar binário temporário do contexto local do Dext
Remove-Item -Path $TempHorseBin -Force

# 6. Executar o Benchmark dentro do container
Write-Host "`nDisparando bateria de testes no container Ubuntu..." -ForegroundColor Green
& docker run --rm -it dext-vs-horse-bench

Write-Host "`n==============================================================" -ForegroundColor Green
Write-Host " BENCHMARK REAL NO DOCKER COMPLETO" -ForegroundColor Green
Write-Host "==============================================================" -ForegroundColor Green
