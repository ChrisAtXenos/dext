  # Resumo Técnico de Alterações — Spec S23 & MCP Refactoring
  Este documento resume as alterações realizadas no framework Dext para a implementação da especificação **S23 (Streamable Sessions & HTMX)** e a modernização do módulo **MCP (Model Context Protocol)**.
  ---
  ## 1. Módulo MCP (Inteligência Artificial)
  *Anteriormente em `Sources\MCP`, agora consolidado em `Sources\AI\MCP`.*
  ### 🏗️ Reorganização e Namespaces
  - **Novo Namespace:** `Dext.AI.MCP.*` (adicionado o prefixo `.AI` para alinhar com a hierarquia global do framework).
  - **Novo Package:** Criado o `Dext.AI.dpk` para desacoplar as capacidades de IA do core web.
  - **Namespaces Atualizados:**
    - `Dext.MCP.Server` → `Dext.AI.MCP.Server`
    - `Dext.MCP.Tools` → `Dext.AI.MCP.Tools` (e assim por diante).
  ### ⚡ Otimizações de Performance
  - **Dext.Collections Integration:** Substituído o uso de `System.Generics.Collections` por `Dext.Collections` em todo o protocolo. 
    - *Ganhos:* Redução de generics bloat e melhor performance em dicionários de alta frequência (ferramentas e recursos).
  - **Declarative Reflection:** O registro de ferramentas (`TMCPToolRegistry`) agora utiliza `Dext.Core.Reflection`.
    - Aproveita o sistema de cache de metadados do Dext em vez de re-escanear RTTI a cada inicialização.
  - **Response Caching:** Implementado cache de resposta JSON para o método `list_tools`, evitando serialização repetitiva em ambientes de alta carga.
  ### 🛡️ Estabilidade e Memória
  - **Zero Leak Policy:** Corrigido leak na infraestrutura de testes (referências circulares em Mocks).
  - **Streamable Transition:** O transporte SSE do MCP foi desacoplado de implementações manuais e agora consome a interface core `IStreamableSession`.
  ---
  ## 2. Core Web Framework (S23 Infrastructure)
  *Novas capacidades em `Dext.Web.pas` e `Dext.Web.Sessions.Streamable.pas`.*
  ### 🔄 Streamable Sessions (O coração do S23)
  - **Conceito:** Implementada a abstração de sessões que sobrevivem à conexão HTTP. Essencial para o padrão "POST command / SSE telemetry".
  - **Lifecycle Management:**
    - **Scavenger Thread:** Thread background responsável por limpar sessões ociosas (Timeout).
    - **Shutdown Seguro:** Integrado com `ICancellationToken` (padrão .NET/Dext). O thread de limpeza agora encerra instantaneamente no shutdown do host, eliminando processos presos na memória.
  - **Thread Safety:** Utilização de `TDextMREW` (Multi-Read Exclusive-Write) no gerenciamento do dicionário de sessões para suportar alta concorrência no lugar do TCriticalSection.
  ### 🎨 HTMX & View Engine
  - **Automatic Partials:** O View Engine agora detecta o cabeçalho `HX-Request`. Se presente, ele desabilita o Layout automaticamente e retorna apenas o fragmento HTML (parcial).
  - **Htmx Helpers:** Adicionado `Res.Htmx` (Fluent Interface) para controle de fluxo HTMX:
    - `Trigger`, `Retarget`, `Reswap`, `Redirect`.
  ---
  ## 3. Sidecar Dashboard (Prova de Conceito)
  - **Migração HTMX:** O widget "Live Metrics" foi convertido para HTMX.
    - **Endpoint:** `/sidecar/fragments/metrics` retorna HTML renderizado pelo Delphi.
    - **Client:** O browser faz polling a cada 3s via `hx-get`, sem necessidade de JavaScript manual ou React/Vue.
  - **DextSSE Abstraction:** Criada uma camada client-side (`DextSSE`) que gerencia a troca transparente entre o modo SSE legado e o novo modo S23 (`POST session` → `GET events`).
  ---
  ## 4. Notas para o Time de Integração
  - **Compatibilidade:** O protocolo MCP continua seguindo a spec 2025-03-26.
  - **Migração de Código:** Ao atualizar o framework, será necessário atualizar os `uses` de `Dext.MCP.*` para `Dext.AI.MCP.*`.
  - **Recomendação:** Utilizar `Services.AddStreamableSessions` para gerenciar o estado das conexões MCP de forma mais robusta que o padrão SSE puro.
  ---
  **Status da Entrega:** ✅ Estável | 27/27 Testes Passando | Zero Leaks.