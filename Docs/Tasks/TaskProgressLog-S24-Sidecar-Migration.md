# Progress Log — Spec S24 (Sidecar Migration)

## [15/05/2026] — Checkpoint: Infraestrutura S23 e Estabilização do Sidecar

Concluímos a primeira grande fase da migração do Sidecar para a infraestrutura **S23/S24**. O foco foi a unificação do sistema de streaming e o desacoplamento de dependências legadas.

### 🚀 Ações Realizadas:

1.  **Limpeza e Desacoplamento do DextTool (dext.exe):**
    *   Removidas as referências ao Dashboard (`Dext.Dashboard.Routes`, `TUICommand`, etc.) da CLI.
    *   O `DextTool` agora é um binário focado exclusivamente em ferramentas de desenvolvimento (Scaffolding, Migrations, Docs).
    *   Isolamento completo do servidor de Dashboard no binário `DextSidecar.exe`.

2.  **Unificação da Ingestão de Telemetria:**
    *   Refatorada a rota `/api/telemetry/logs` para atuar como um bridge inteligente.
    *   Logs recebidos via POST agora são automaticamente distribuídos para as sessões **S23 (Streamable Sessions)** através do novo `IEventStreamer`.
    *   Suporte a processamento em lote (Batch Ingestion) de logs e eventos de teste.

3.  **Refatoração do Frontend (Dashboard UI):**
    *   Implementada a abstração `DextSSE` em JavaScript, que gerencia o ciclo de vida da sessão S23 (`/sidecar/session` + `/sidecar/events`).
    *   Refatorada a lógica de tratamento de eventos no `main.js` para suportar dados estruturados (JSON) nativamente.
    *   Adicionado componente reativo de status do Test Runner na home do Dashboard.

4.  **Estabilização da Infraestrutura de Streaming:**
    *   Introduzida a interface `IEventStreamer` no framework para desacoplar a lógica de negócio do transporte de eventos.
    *   Implementada a bridge `TEventStreamer` no Sidecar, que observa os logs do framework e os injeta no `IStreamableSessionManager`.

### 🛡️ Estabilização e Correções:

*   **Build:** Todos os projetos (`DextTool`, `DextSidecar`, `Dext.AI`) compilando sem avisos ou dependências circulares.
*   **Test Scripts:** Corrigido o script PowerShell do `Web.ControllerExample` para lidar corretamente com falhas de rede sem gerar exceções de stream vazias.
*   **Search Paths:** Limpeza dos arquivos `.dproj` para garantir que o compilador use os pacotes de saída e não referências diretas de source, evitando erros de versão de DCU.

### 🎯 Status Atual:
*   **Sidecar:** Operacional com SSE S23.
*   **Live Logs:** Funcionando 100% via HTMX-style streaming.
*   **Test Runner:** Recebendo eventos reativos no Dashboard.

---
**Próximo Passo:** Executar uma bateria de testes completa via CLI/Sidecar e validar se a árvore de testes no Dashboard reflete o estado em tempo real sem "flicker" ou perda de pacotes.
