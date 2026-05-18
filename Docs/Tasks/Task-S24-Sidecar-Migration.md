# Tarefa: Spec S24 — Sidecar Full Migration (HTMX + S23)

## 1. Objetivo
Migrar as funcionalidades críticas do Dext Sidecar Dashboard para a nova infraestrutura **S23 (Streamable Sessions + HTMX)**. O objetivo é eliminar o código legado de sincronização manual e transformar o Dashboard em uma aplicação reativa, baseada em fragmentos HTML e eventos de streaming robustos.

## 2. Funcionalidades Prioritárias

### 📺 Live Logging (Real-time) ✅
- **Status:** Concluído.
- **Implementação:** O servidor agora usa `IEventStreamer` para capturar logs via telemetria e despachar para sessões S23. O cliente `DextSSE` no Dashboard consome esses eventos e os renderiza via `processLog`.

### 🧪 Test Runner (Integrado) ✅
- **Status:** Concluído.
- **Implementação:** O runner emite eventos `run_start`, `test_complete`, etc., via telemetria. O Dashboard recebe esses eventos estruturados (JSON) e atualiza a UI (árvore de testes e barra de progresso) reativamente.

## 3. Plano de Ação

### Fase 1: Infraestrutura de Eventos no Sidecar ✅
- [x] Adaptar o `TSidecarServer` para injetar logs no `IStreamableSessionManager`.
- [x] Criar o `TEventStreamer` que observa o `Dext.Logging` e distribui para as sessões ativas.

### Fase 2: Migração dos Logs (UI) ✅
- [x] Atualizar `index.html` com a abstração `DextSSE` para suporte a S23.
- [x] Refatorar `main.js` para processar eventos `log` via bridge S23.

### Fase 3: Test Runner Reativo ✅
- [x] Integrar o `Dext.Testing.Runner` com o sistema de eventos S23 (via telemetria log ingestion).
- [x] Refatorar `updateTestState` no `main.js` para suportar eventos JSON estruturados.
- [x] Criar componente fixo `tr-status` no Dashboard para feedback visual imediato.

### Fase 4: Cleanup (Pendente)
- [ ] Remover endpoints legados (`/events` antigo, hub de sinalização manual) após período de validação.
- [ ] Remover dependências de bibliotecas JS desnecessárias (SignalR) que foram substituídas.

---
## 5. Status Atual
- **Status:** 🔵 Finalizando. Migração funcional concluída com sucesso.
- **Próximo Passo:** Testar a execução de uma suite de testes completa e verificar o feedback no Dashboard.
