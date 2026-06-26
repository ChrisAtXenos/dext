#!/usr/bin/env bash
# run_linux_benchmark.sh - Benchmark real de Dext Epoll vs Horse Epoll no Linux Ubuntu
#
# Uso:
#   chmod +x run_linux_benchmark.sh
#   ./run_linux_benchmark.sh

set -e

# Configurações de cores para o terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Sem Cor

echo -e "${CYAN}==============================================================${NC}"
echo -e "${CYAN}     BENCHMARK REAL: DEXT EPOLL VS HORSE EPOLL (LINUX)${NC}"
echo -e "${CYAN}==============================================================${NC}"

# Verificar se o wrk está instalado
if ! command -v wrk &> /dev/null; then
    echo -e "${RED}Erro: A ferramenta de carga 'wrk' não foi encontrada.${NC}"
    echo -e "${YELLOW}Por favor, instale o wrk executando: sudo apt install -y wrk${NC}"
    exit 1
fi

# Verificar presença dos binários de teste no diretório atual
DEXT_BIN="./Dext.Benchmarks"
HORSE_BIN="./EpollConsole"

if [ ! -f "$DEXT_BIN" ]; then
    echo -e "${RED}Erro: O binário do Dext '$DEXT_BIN' não foi encontrado no diretório atual.${NC}"
    exit 1
fi

if [ ! -f "$HORSE_BIN" ]; then
    echo -e "${RED}Erro: O binário do Horse '$HORSE_BIN' não foi encontrado no diretório atual.${NC}"
    exit 1
fi

# Configurações de carga
CONCURRENCY=200
THREADS=4
DURATION="15s"

# Limpeza de processos pré-existentes
cleanup_ports() {
    echo -e "${YELLOW}Limpando conexões órfãs nas portas 8085 e 9095...${NC}"
    fuser -k 8085/tcp &>/dev/null || true
    fuser -k 9095/tcp &>/dev/null || true
    sleep 1
}

run_test() {
    local NAME=$1
    local BIN=$2
    local PORT=$3
    local ENGINE_ARG=$4

    cleanup_ports

    echo -e "\n${CYAN}--------------------------------------------------------------${NC}"
    echo -e "${GREEN} Iniciando teste para: $NAME${NC}"
    echo -e "${CYAN}--------------------------------------------------------------${NC}"

    # Iniciar o servidor em background
    if [ -n "$ENGINE_ARG" ]; then
        $BIN $ENGINE_ARG &>/dev/null &
    else
        $BIN &>/dev/null &
    fi
    SERVER_PID=$!

    # Esperar o bind do socket
    echo -e "Aguardando inicialização do servidor (PID $SERVER_PID)..."
    sleep 3

    # Rodar teste de carga
    echo -e "${YELLOW}Disparando wrk contra http://localhost:$PORT/ping...${NC}"
    wrk -t$THREADS -c$CONCURRENCY -d$DURATION http://localhost:$PORT/ping

    # Encerrar o servidor de forma limpa
    echo -e "Encerrando servidor $NAME..."
    kill -2 $SERVER_PID &>/dev/null || kill -9 $SERVER_PID &>/dev/null
    sleep 2
}

# 1. Executar Teste do Dext Epoll
# --server -httpsys inicia a engine nativa no Dext (que no Linux resolve para o Epoll)
run_test "Dext Epoll (Pós-Otimização)" "$DEXT_BIN" 8085 "--server -httpsys"

# 2. Executar Teste do Horse Epoll
# Roda na porta 9095 nativamente
run_test "Horse Epoll (Referência)" "$HORSE_BIN" 9095 ""

echo -e "\n${GREEN}==============================================================${NC}"
echo -e "${GREEN}               BENCHMARK CONCLUÍDO COM SUCESSO${NC}"
echo -e "${GREEN}==============================================================${NC}"
