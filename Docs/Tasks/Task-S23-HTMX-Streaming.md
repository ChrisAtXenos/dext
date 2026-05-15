# Tarefa: Implementação do Spec S23 - HTTP Streamable Sessions & HTMX

## 1. Avaliação da Feature
A especificação S23 propõe uma evolução arquitetural fantástica para o framework Dext. A abordagem de separar comandos (POSTs síncronos) da telemetria (SSE unidirecional) resolve de forma elegante os problemas clássicos de conexões persistentes em proxies e firewalls. 
Utilizar o **HTMX** nativamente com fragmentos HTML renderizados diretamente pelo Delphi elimina a complexidade do build frontend (Node.js/Vue.js) e demonstra o verdadeiro poder do framework como um ambiente full-stack moderno.

### Respostas às Perguntas:
- **Pode conviver com o SSE existente?**
  **Sim.** O Streamable Sessions pode ser construído como uma camada de abstração em cima da infraestrutura SSE já existente no `Dext.WebHost`. O SSE atual continuará funcionando para quem precisa de conexões cruas, mas o S23 introduzirá o gerenciamento de estado (`IStreamableSession`) independente da conexão.
  
- **Podemos extrair o código do MCP, e o MCP ainda utilizá-lo sem causar impacto negativo?**
  **Sim.** O protocolo MCP 2025-03-26 já utiliza este exato padrão (POST para mensagens, SSE para eventos). Se movermos a lógica de `Streamable` para o core do `Dext.WebHost` (conforme descrito no S23), o MCP Server do Dext poderá simplesmente consumir essa mesma interface (`IStreamableSessionManager`). A única diferença é que o MCP trafegará payloads JSON-RPC pelo SSE, enquanto o Sidecar trafegará fragmentos HTML para o HTMX. Isso centraliza e fortalece o código.

- **Alteração do Dashboard para torná-lo uma ferramenta realmente útil:**
  Esta é a maior vitória prática. Ao migrar para Tailwind + HTMX, o Sidecar Dashboard se tornará muito mais leve e fácil de manter. Para que seja "apresentável", precisamos caprichar no design dos componentes (views Delphi) e focar em métricas reais (uso de CPU, Memória, logs em tempo real, controle de cache) que demonstrem o poder do Dext em produção.

---

## 2. Plano de Ação (Tarefas)

### Fase 1: Core Framework (Dext.WebHost)
- [x] Implementar as interfaces `IStreamableSession` e `IStreamableSessionManager`.
- [x] Desenvolver a implementação em memória (`TInMemoryStreamableSessionManager`) com controle de concorrência (`TDextMREW`).
- [x] Implementar o controle de ciclo de vida (timeout e garbage collection de sessões ociosas) — `CollectGarbage` + `StartScavenger`/`StopScavenger` implementados com thread background em `Dext.Web.Sessions.Streamable.pas`.
- [x] Criar o suporte no `IHttpContext` para resolver automaticamente o cabeçalho `Dext-Session-Id`.
- [x] Adaptar/Extrair a lógica de transporte SSE que hoje reside no MCP para utilizar a nova infraestrutura core, garantindo que o MCP continue funcionando.
- [x] Adicionar extension methods `Services.AddStreamableSessions` e `App.UseStreamableSessions` ao `TWebServicesHelper` / `THttpAppBuilderHelper` em `Dext.Web.pas` — registra o manager no DI (Singleton) e inicia o Scavenger automaticamente.

### Fase 2: View Engine e Helpers HTMX
- [x] Criar helpers no `IHttpResponse` para trabalhar com HTMX (ex: `Res.Htmx.Trigger`, `Res.Htmx.Retarget`, `Res.Htmx.Location`) — implementado em `THtmxResponse` e validado com 9 testes unitários.
- [x] Suporte automático a parciais no View Engine — `TViewResult.Render` detecta `HX-Request` e zera o layout automaticamente, retornando apenas o fragmento HTML.

### Fase 3: Refatoração do Dext Sidecar (Dashboard)
**Nota Importante:** Antes de iniciar a reescrita ou refatoração profunda do Dashboard (seja para HTMX ou para um app nativo Windows), vamos **testar a implementação da S23 com o dashboard atual**. Isso servirá para validar a nova arquitetura do core (Dext.WebHost) e ajudar na decisão de como o Sidecar evoluirá.

- [x] Registrar `Services.AddStreamableSessions` e `App.UseStreamableSessions` no `TSidecarServer` (`Dext.Sidecar.Server.pas`).
- [x] Adicionar endpoints S23 ao `Dext.Dashboard.Routes.pas`:
  - `POST /sidecar/session` — cria `IStreamableSession`, retorna `{sessionId}`.
  - `GET /sidecar/events?sessionId=` — SSE via `IStreamableSession.TryDequeueEvent` com heartbeat a cada 15s.
  - `GET /sidecar/fragments/metrics` — fragmento HTML com métricas reais do Windows (memória) para polling HTMX.
- [x] Adicionar HTMX (CDN) ao `index.html` e widget "Live Metrics" com `hx-get="/sidecar/fragments/metrics" hx-trigger="every 3s"`.
- [x] Abstração client-side SSE (`DextSSE`): objeto JS com `DEXT_SSE_MODE = 's23' | 'legacy'` que troca entre o endpoint legado `/events` e o novo `/sidecar/session` + `/sidecar/events` sem alterar o resto do código.
- [x] Rebuildar o arquivo de recursos `Dext.Dashboard.RES` com o novo `index.html` atualizado (script `build-resources.ps1`).
- [x] Compilar e executar o Sidecar para validação manual no browser (`http://localhost:3030`).
  - Widget "Live Metrics" pulsando a cada 3s com RAM real do sistema e timestamp em tempo real.
  - Endpoints `/sidecar/session`, `/sidecar/events` e `/sidecar/fragments/metrics` validados e funcionais.
  - Abstração `DextSSE` client-side operacional (modo `'s23'` ativo).

---

## 4. Preocupações, Dúvidas e Impasses
- **Gerenciamento de Memória (GC):** Como o ambiente Delphi é multi-thread, a exclusão de sessões expiradas enquanto uma requisição de leitura (SSE) ou POST pode estar ocorrendo precisa ser extremamente bem testada contra *Access Violations*.
- **Performance do View Engine:** O View Engine do Dext precisa ser rápido o suficiente para gerar fragmentos HTML numa alta frequência (caso a telemetria atualize a cada segundo).
- **Escalabilidade (Redis):** O S23 menciona o `TRedisStreamableSessionManager`. Implementaremos o de memória primeiro, mas é importante deixar a interface pronta para não quebrar a arquitetura quando o Redis for introduzido.
- **MCP Regression:** Temos que garantir que a extração do código Streamable para o core não adicione latência indesejada no protocolo MCP, que já está operacional com TOTVS.
- **Alternativa Nativa para o Dashboard:** Por questões de performance máxima e integração fluida com o ecossistema desktop, existe a consideração de construir o Dashboard como um aplicativo nativo VCL ou FMX no futuro. **Decisão Adiada:** Essa ideia fica registrada aqui como uma alternativa válida. Apenas tomaremos uma decisão definitiva (HTMX vs Nativo) após implementarmos e testarmos a infraestrutura S23 usando o dashboard web atual como prova de conceito.

---

## 5. Consolidação e Modernização do Módulo MCP (AI)

Durante a Fase 1, realizamos uma refatoração profunda no módulo MCP para garantir que ele sirva como o "padrão ouro" de integração com a nova infraestrutura S23:

- **Reestruturação de Package e Namespaces:**
  - Criado o package `Dext.AI.dpk` para centralizar as capacidades de Inteligência Artificial do framework.
  - Consolidado o namespace para `Dext.AI.MCP.*` (anteriormente disperso), seguindo a hierarquia global do Dext.
- **Integração com Dext.Collections:**
  - Substituído o uso de `System.Generics.Collections` por `Dext.Collections` e `Dext.Collections.Dict`.
  - Essa mudança reduz o *generics bloat*, melhora a performance de busca nos dicionários e utiliza o gerenciamento de memória nativo do framework (`OwnsObjects`).
- **Otimização de Performance (Metadados e Cache):**
  - O registro de ferramentas (`TMCPToolRegistry`) agora utiliza `Dext.Core.Reflection` para descoberta declarativa via RTTI, aproveitando o cache de metadados do Dext.
  - Implementado cache de resposta JSON para o método `list_tools`, evitando reconstruções desnecessárias de objetos JSON em chamadas frequentes.
- **Estabilidade e Gestão de Memória:**
  - Identificado e corrigido um vazamento de memória (Memory Leak) na infraestrutura de testes HTMX, causado por referências circulares entre o Mock de resposta e o Helper fluente.
  - Resolvido utilizando referências `[Weak]` e eliminando cache de estado desnecessário em objetos Mock.

---

## 6. Status Atual
- **Status:** ✅ Fases 1, 2 e 3 concluídas. Infraestrutura S23 validada end-to-end no Sidecar Dashboard. Widget "Live Metrics" com HTMX polling a cada 3s funcionando em produção.
- **Build:** Framework estável, zero memory leaks, 27/27 testes unitários passando.
- **Próximo Passo:** Commit e tag da entrega S23. Evoluir o Dashboard para mais fragmentos HTMX (CPU, logs em tempo real via SSE, controles de cache).
