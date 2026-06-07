# Specification: S26 — Interactive Test Runner (Premium Edition)

> [!CAUTION]
> **STATUS: CANCELED / SUPERSEDED**
> Esta especificação (S26 - baseada no Sidecar externo) foi cancelada e substituída pela especificação nativa de IDE: [S27 — Native Delphi IDE Test Runner (VCL Premium)](file:///C:/dev/Dext/DextRepository/Docs/Specs/S27-IDE-Test-Runner.md).

---

## 1. Quebrando as Limitações do Legado (TestInsight)

Para criar uma experiência verdadeiramente revolucionária, o Dext resolve duas das maiores dores do ecossistema de testes Delphi:

### A. Suporte Nativo a Múltiplos Projetos de Teste (Multi-Project Support)
*   **O Problema do Legado**: O TestInsight é limitado a monitorar e executar apenas um único projeto de testes por vez.
*   **A Solução Dext**: O Sidecar descobre e gerencia múltiplos projetos de teste (`*.dproj` ou `*.dpr`) simultaneamente dentro do grupo de projetos (Project Group). A árvore de testes consolida todos os projetos em uma única visualização unificada, permitindo disparar a execução de todos os projetos simultaneamente ou filtrar por escopo.

### B. Sessões de Teste Customizadas pelo Usuário (Custom Test Sessions)
*   **O Problema do Legado**: Não há suporte para agrupar testes ad-hoc; você executa tudo ou apenas um teste isolado.
*   **A Solução Dext**: Inspirado no Rider, o desenvolvedor pode selecionar testes de múltiplos fixtures, units ou projetos diferentes e salvá-los em uma **"Sessão de Teste Personalizada"** (ex: *Smoke Tests*, *Auth Pipeline*, *Slow Integration*). Essas sessões são salvas no escopo do desenvolvedor e podem ser re-executadas com um único clique.

---

## 2. A Experiência Visual Interativa (Premium Rider/VS Style)

### A. Test Tree Explorer Avançado
*   **Organização Hierárquica Tridimensional**: `Project Group > Project > Unit > Fixture > Method`.
*   **Smart Filtering & Search**: Busca instantânea por termo de pesquisa, filtragem por tags/categorias (`[Category]`), prioridade (`[Priority]`) ou pelo status da última execução (Passed, Failed, Skipped).
*   **Múltiplas Visualizações**: Alternar o agrupamento da árvore por **Estrutura Física** (Units/Pastas) ou por **Categorias** (Traits/Mapeamento Semântico).

### B. Live Result Stream (SSE & SignalR)
*   **Dashboard reativo em tempo real**: Uma barra de progresso linear e circular de alta fidelidade no topo com métricas rápidas (X rodando, Y passados, Z falhos).
*   **Feedback Micro-Animado**: Conforme o pipeline avança, ícones e linhas na árvore são atualizados em tempo real com suaves micro-animações (fade-in, transições suaves de cores).

### C. Visual Assertion Diff Viewer
*   Para testes que falham em asserções de igualdade (strings, JSONs, arrays complexos), o dashboard abre um visualizador de diff inteligente, lado a lado, com destaque sintático e indicação exata de caracteres adicionados, removidos ou modificados (estilo Git diff).

---

## 3. Deep Integration (Observability Correlation)

O grande diferencial do Dext Sidecar é a união da telemetria em runtime com os resultados dos testes:

*   **Test-to-Log Link (Span Correlation)**:
    *   Durante a execução, cada teste é envelopado em um `SpanId` exclusivo.
    *   Ao selecionar um teste na árvore do Dashboard, os painéis de **Logs do Terminal** e **Traces SQL** filtram-se automaticamente, exibindo apenas as mensagens e comandos executados sob o escopo exato daquele teste específico.
*   **SQL & Network Outbound Profiling**:
    *   Se o teste faz queries no banco (FireDAC) ou chamadas REST (RestClient), a árvore de logs expande para mostrar o SQL formatado (pretty-print) e as requisições geradas especificamente por aquele teste, ideal para depurar falhas de banco ou integrações.

---

## 4. O Ciclo de Compilação (Build & Run) e TDD

O ciclo de TDD exige compilação e execução em milissegundos. Recompilar o projeto inteiro a cada execução de teste quebra o fluxo de foco do desenvolvedor. O Dext adota estratégias avançadas:

### A. Modos de Compilação
1.  **Modo IDE Integration (O Expert Delphi - S15)**: O Dext Studio (Plugin da IDE) compila na velocidade máxima usando o compilador interno em memória da IDE e aciona o Sidecar silenciosamente para relatar e exibir o dashboard de testes.
2.  **Modo CLI Inteligente (MSBuild Incremental)**: O Sidecar monitora os timestamps dos arquivos e usa parâmetros específicos do MSBuild para tentar realizar compilações incrementais puras (sem rebuild), aproveitando ao máximo a otimização de geração de `.dcu` intermediários.

### B. Watch Mode Inteligente (Auto-Trigger)
*   Watcher de arquivos integrado. Ao detectar alterações em arquivos `.pas`, o Sidecar executa a compilação de background apenas da Unit afetada e roda de imediato a Fixture que cobre aquela funcionalidade.

---

## 5. Histórico, Analytics & Cobertura de Código

*   **Failure Persistence & Flakiness Tracking**:
    *   O Dashboard mantém o histórico das últimas 10 execuções de cada teste.
    *   Identificação visual de **Flaky Tests** (testes intermitentes que passam e falham sem alterações no código) usando métricas de desvio padrão e estabilidade histórica.
    *   Gráfico de tendência de tempo de execução por teste (identificando gargalos de performance que surgiram em commits recentes).
*   **Visual Code Coverage Overlay**:
    *   Exibição do Heatmap de cobertura de código integrado ao gerenciador de arquivos do Sidecar.
    *   Drill-down visual das linhas executadas e não executadas diretamente nos arquivos `.pas` carregados no visualizador de código do Dashboard.

---

## 6. Arquitetura de Execução Paralela de Elite (O Desafio do Estado)

Executar testes em paralelo é um dos maiores desafios de engenharia devido à concorrência por recursos compartilhados (banco de dados, arquivos, Singletons no container de DI). O Dext implementa duas estratégias revolucionárias para vencer essa barreira:

### A. Parallel Workers (Isolamento por Processos - Requisito de Resiliência)
*   **A Estratégia**: Inspirado no Playwright e Jest, para testes de integração ou testes que dependem de estado global, o Sidecar divide a carga de testes selecionados em fatias e inicializa múltiplos subprocessos do mesmo `.exe` em paralelo (Workers).
*   **Vantagens Absolutas**:
    *   **Isolamento de Memória**: Cada Worker tem seu próprio espaço de endereçamento de memória do SO. Variáveis globais e Singletons do DI não colidem.
    *   **Tolerância a Falhas**: Se um teste causar um Access Violation (crash fatal) no Worker 1, o processo morre isoladamente. Os Workers 2, 3 e 4 continuam rodando e reportando resultados normalmente.
    *   **Facilidade de Escrita**: O desenvolvedor escreve os testes normalmente, sem precisar se preocupar em torná-los thread-safe.

### B. Declarative Multi-Threading (Isolamento por Thread - Testes Unitários Puros)
*   **O Atributo `[Parallelizable]`**: Fixtures puramente unitárias ou mockadas podem ser decoradas com `[Parallelizable]`.
*   **DI Scoped Isolation**: O runner interno de testes do Dext instancia e executa cada teste paralelo dentro de seu próprio `IServiceScope`.
*   **Database Transaction Isolation**: Se os testes usarem banco de dados, o ORM do Dext aloca automaticamente conexões isoladas por thread rodando em transações aninhadas com Rollback garantido ao fim do teste.

---
**Meta**: Redefinir completamente o padrão de desenvolvimento orientado a testes no ecossistema Delphi, trazendo a experiência luxuosa de IDEs modernas para o ciclo de desenvolvimento do Dext Framework.
