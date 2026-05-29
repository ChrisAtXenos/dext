# Specification: S27 — Database & HTTP Profiler

Esta especificação detalha o sistema de profiling especializado para interações de I/O (Banco de Dados e APIs Externas), integrando-se ao ecossistema de observabilidade do Dext Sidecar.

## 1. Database Profiler (SQL Insight)

### A. SQL Live Stream
*   **Captura de Queries:** Capturar todas as sentenças SQL executadas via Dext ORM ou FireDAC (via Telemetria).
*   **Parameter Inspection:** Mostrar os valores reais dos parâmetros enviados (evitando o "SELECT * FROM Table WHERE ID = :ID" genérico).
*   **Timing & Performance:** Destacar queries que ultrapassarem um threshold (ex: > 100ms) em vermelho.

### B. Query Analysis
*   **Execution Plan (Futuro):** Atalho para tentar rodar um `EXPLAIN` direto do dashboard.
*   **Impact Mapping:** Ver qual Controller/Método originou aquela query.

## 2. HTTP Client Profiler (API Insight)

### A. Outbound Requests
*   **Spying:** Monitorar chamadas feitas pelo `Dext.Net.RestClient`.
*   **Headers & Body:** Visualização rica de Request/Response headers e payloads (JSON formatado).
*   **Status Timeline:** Ver a sequência de chamadas externas em um processo complexo.

## 3. UI: Data-Centric Views

### A. The "I/O Wall"
*   Uma view cronológica focada apenas em I/O, permitindo identificar gargalos de rede ou banco de dados rapidamente.
*   Filtros por Connection String ou Base URL.

### B. Inspector Side-panel
*   Ao clicar em uma query ou request, abrir um painel lateral com:
    *   Stack Trace (Onde no código Delphi isso foi chamado).
    *   Raw Payload.
    *   Copy as cURL (para HTTP).
    *   Copy as SQL.

---
**Meta:** Dar visibilidade total sobre o que acontece "debaixo do capô" nas camadas de integração da aplicação.

## 4. Status da Implementação (Maio 2026)
*   **Auto-Instrumentação de I/O:** Interceptação automática de sentenças SQL e parâmetros na camada do FireDAC, e chamadas HTTP de saída no Rest Client, transmitidas de forma assíncrona como spans.
*   **Context Inspector Drawer:** Painel deslizante interativo no Dashboard exibindo código SQL limpo, parâmetros estruturados (suportando variações db.params, db.param e dh.param), cURL da chamada HTTP pronto para cópia e listagem de erros.
*   **Estabilidade de Processo:** Implementado o encerramento gracioso via sinalização `StopServer` nos endpoints de SSE, eliminando qualquer travamento de threads Indy no shutdown.
