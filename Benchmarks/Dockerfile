FROM ubuntu:22.04

# Evitar prompts interativos durante a instalação de pacotes
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependências de runtime do Delphi para Linux e a ferramenta wrk
RUN apt-get update && apt-get install -y \
    libcurl4 \
    ca-certificates \
    wrk \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /bench

# Copiar os binários compilados de Linux64 e o script
COPY Linux64/Release/Dext.Benchmarks .
COPY EpollConsole .
COPY run_linux_benchmark.sh .

# Dar permissão de execução nas ferramentas
RUN chmod +x Dext.Benchmarks EpollConsole run_linux_benchmark.sh

# Definir o script de benchmark como o entrypoint de execução
ENTRYPOINT ["./run_linux_benchmark.sh"]
