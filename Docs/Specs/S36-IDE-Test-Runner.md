# Specification: S36 — Native Delphi IDE Test Runner (VCL Premium)

Esta especificação detalha o **Dext IDE Test Runner**, um plugin nativo integrado diretamente ao Embarcadero Delphi usando a **Open Tools API (OTA)** e construído inteiramente com **VCL Nativa**. Esta abordagem garante baixíssimo consumo de memória, alta performance e estabilidade dentro do processo da IDE (`bds.exe`), trazendo a experiência de produtividade de nível internacional do **JetBrains Rider** e **Visual Studio Test Explorer** para o ecossistema Delphi.

---

## 1. Experiência Visual & Gerenciamento de Sessões (Rider Explorer Style)

Para garantir compatibilidade universal (Delphi 10.3+), compilação limpa sem dependências e **zero risco de colisões de units BPL** (como ocorreria ao incluir código compilado de componentes de terceiros como VirtualTreeView), a interface é desenvolvida utilizando **componentes VCL nativos padrão** otimizados:

### A. Componentes de UI Nativos Otimizados:
*   **TListView em Modo Virtual (`OwnerData = True`):** Utilizado para renderizar a lista de testes, resultados e stack traces de forma instantânea e de baixo consumo de memória, tratando o renderização de forma reativa sob demanda via evento `OnData`.
*   **TTreeView Padrão (Lazy Loading):** Para a visualização de hierarquias de pacotes e fixtures, preenchendo os métodos de teste dinamicamente apenas quando o nó da classe for expandido.
*   **Múltiplas Abas de Sessão (Custom Test Sessions):** Abas dinâmicas baseadas em `TPageControl` padrão de design nativo da IDE.
*   **Dropdown de Projetos & Toolbar:** Combinação de `TComboBox` e `TToolBar` nativos VCL.
*   **Painel de Detalhes Rico:** Painel VCL com links clicáveis sobre os stack traces para navegação rápida do cursor no código-fonte.

### B. Integração Estrita com Temas da IDE (Light & Dark Modes):
*   **Registro de Form Classes:** Todas as janelas e componentes visuais do plugin serão registrados no serviço de temas via `IOTAIDEThemingServices.RegisterFormClass(TFormClass)`.
*   **Dynamic Theme Styling:** Ao registrar as classes, a IDE assume a injeção do tema ativo (Light, Dark, Mountain Mist, etc.) sobre os componentes VCL nativos do plugin automaticamente.
*   **Acesso a Cores de Sistema:** Para elementos de desenho manual (como a barra de progresso de status de testes ou indicadores de cobertura de código), o plugin utilizará o `IOTAIDEThemingServices.StyleServices` para ler as paletas de cores ativas e manter fidelidade visual cromática com o ambiente do desenvolvedor.

### C. Agrupamento Avançado (Smart Grouping):
A árvore/lista de testes pode ser agrupada dinamicamente via barra de ferramentas pelos seguintes critérios:
1.  **Estrutura do Projeto:** `Projeto > Unit > Fixture > Método`.
2.  **Duração (Duration):** Classificação automática em *Fast* (< 50ms), *Medium* (50ms - 500ms) e *Slow* (> 500ms).
3.  **Resultado da Execução:** `Failed > Passed > Skipped`.
4.  **Categorias (Traits):** Agrupamento por atributos personalizados declarados no código (ex: `[Category('Integration')]`, `[Priority(1)]`).

### C. Filtros de Busca Semânticos:
A busca rápida interpreta termos de filtragem lógica:
*   `state:failed` / `state:passed` / `state:ignored`
*   `duration:>100` (testes mais lentos que 100ms)
*   `category:api`
*   `project:MyDextTests`

---

## 2. Smart Continuous Testing (Impact-Analysis Auto-Run)

Em vez de monitorar modificações de arquivos para rodar todas as suítes (o que é pesado e lento), o Dext implementa a **Execução Baseada em Análise de Impacto (Impact-Analysis)**:

*   **Correlacionamento de Cobertura:** O plugin salva um mapeamento binário rápido (`Line -> Tests`) a partir do último resultado de Code Coverage.
*   **Auto-Run Cirúrgico:** Ao salvar um arquivo de código produtivo (`.pas`), o plugin identifica a linha alterada e aciona a compilação incremental de background e executa **apenas os testes que cobrem aquela linha específica**.
*   **Idle Execution:** O gatilho pode ser configurado para rodar imediatamente ao salvar ou de forma silenciosa após 1 segundo de inatividade (idle) no teclado da IDE.

---

## 3. Integração Premium de Code Coverage (dotCover / VS Style)

A análise de cobertura deixa de ser um relatório estático e torna-se parte activa do editor de código do Delphi:

### A. Gutter Overlays de Três Estados:
O plugin pinta discretamente a margem esquerda (gutter) do editor de código ativo para indicar o status da linha:
*   **Verde (Covered):** A linha foi totalmente executada por pelo menos um teste.
*   **Vermelho (Uncovered):** A linha existe, mas nenhum teste passou por ela.
*   **Amarelo (Partially Covered):** A linha contém múltiplos branches de decisão (ex: `if A and B then`), e nem todas as condições ou caminhos lógicos foram testados.

### B. "Show Covering Tests" (Mapeamento Reverso):
*   Ao posicionar o cursor em qualquer linha de código produtivo e pressionar o atalho configurado (ou clicar com o botão direito no menu de contexto), o plugin exibe um popup flutuante com a lista de testes que executam aquela linha.
*   Ao clicar em um teste da lista, a IDE abre a unit de teste correspondente posicionando o cursor no método de teste.

### C. Parâmetros de Execução do Delphi Code Coverage:
Para gerar as métricas de cobertura, o plugin utilizará a mesma orquestração madura do **`DextTool` (Dext CLI)**:
*   **Comando disparado pelo plugin (reutilizando a lógica do CLI):**
    ```cmd
    DelphiCodeCoverage.exe -e "<binary_path>" -m "<map_path>" -uf "<units_list_file>" -spf "<source_paths_file>" -od "<report_dir>" -xml -xmllines -a <runner_args>
    ```
*   **Alternativa Direta:** O plugin pode invocar diretamente o CLI do Dext (`dext test --coverage --project="<project_path>"`) para reaproveitar automaticamente as exclusões e configurações definidas no `dext.json` do workspace.
*   **Leitura de Linhas:** O parser do plugin interpretará o arquivo XML gerado com a flag `-xmllines`, extraindo a contagem exata de execuções de cada linha de instrução para pintar os Gutter Overlays e alimentar o popup "Show Covering Tests".


---

## 4. Histórico, Analytics & Métricas de Risco (Risk Telemetry)

O plugin armazena localmente o histórico das últimas 50 execuções do projeto (JSON compacto na pasta `.dext/testing/`), gerando análises preditivas durante as sessões de desenvolvimento:

### A. Alertas de Regressão de Performance:
*   O plugin monitora a média móvel de tempo de execução de cada teste.
*   Se um teste sofrer um aumento de tempo superior a 50% ou desviar significativamente do padrão histórico após uma alteração, ele ganha uma marcação visual e alerta de regressão de performance (ex: `+120ms` em relação ao histórico recente).

### B. Detecção de Flaky Tests (Instabilidade):
*   Identifica testes intermitentes (que alternam entre Pass e Fail sem alterações em seu código ou nas unidades cobertas).
*   Gera um selo de aviso `[Flaky]` com a taxa histórica de estabilidade (ex: *"Estabilidade: 75%"*).

### C. Risk Hotspots (Churn vs. Cobertura):
*   Cruza a frequência de alterações de um arquivo (histórico local de modificações) com a cobertura de código atual daquela unit.
*   Foca a atenção do desenvolvedor em arquivos de **alta modificação e baixa cobertura**, exibindo um índice de criticidade no painel de estatísticas.

### D. Densidade de Asserção (Assertion Density):
*   O runner de testes envia a quantidade de asserções executadas por teste.
*   O plugin detecta testes "vazios" (0 asserções executadas) e alerta o usuário sobre possíveis falsos positivos.

### E. Configurações Locais e Projetos Externos (`.dext/testing/settings.json`):
O plugin salva o estado da sessão de testes na raiz do workspace ativo para persistência e carregamento de testes fora do Project Group atual da IDE:
```json
{
  "externalTestProjects": [
    "C:/dev/OtherSystem/Tests/OtherTests.dproj"
  ],
  "activeTestSession": "Default",
  "coverage": {
    "enabled": true,
    "executablePath": "C:/Tools/DelphiCodeCoverage.exe"
  }
}
```

### F. Resolução de Binários do Runner:
Para localizar o `.exe` gerado pelo projeto de testes, o plugin:
1.  Lê as tags `<DCC_ExeOutput>` e `<DCC_DcuOutput>` diretamente do XML do `.dproj` (ou busca no grafo de configurações do `IOTAProject`).
2.  Resolve variáveis dinâmicas de diretório como `$(Platform)` e `$(Config)` relativas à pasta do projeto para encontrar o caminho correto do executável em runtime.


---

## 5. Comunicação & Servidor Dext em Background

O plugin inicializa uma thread de background que roda um servidor leve usando o próprio motor de rede do Dext (`Dext.Net`).

### A. Protocolo JSON de Resultados Ricos:
O runner de testes envia informações detalhadas em tempo real:
```json
{
  "testName": "TMyFixture.TestDatabaseConnection",
  "status": "Failed",
  "durationMs": 142,
  "error": {
    "className": "EAssertionFailed",
    "message": "Expected database state Active, but was Closed",
    "stackTrace": [
      { "file": "MyTests.pas", "line": 42, "method": "TMyFixture.TestDatabaseConnection" },
      { "file": "Dext.Testing.pas", "line": 118, "method": "TAssert.AreEqual" }
    ]
  }
}
```

### B. Stack Trace Clicável:
*   As linhas do stack trace na janela de detalhes do Test Explorer são transformadas em links dinâmicos na IDE.
*   Clicar em uma linha de erro abre o arquivo `.pas` correspondente e foca na linha exata da falha.

---

## 6. Ciclo de Compilação Inteligente & Otimização Física

Para atingir ciclos de feedback TDD abaixo de 1 segundo (sub-segundo), o plugin adota duas abordagens de compilação:

### A. MSBuild Otimizado (/t:Make):
Quando executado via MSBuild, o plugin força o uso do alvo incremental `Make` (evitando `Clean`/`Build` frios) e injeta parâmetros de otimização de I/O de disco e supressão de buffers:
*   `/t:Make` (invoca a compilação incremental e evita reconstruções redundantes).
*   `/p:DCC_BuildAllUnits=false` (switche `-M` do DCC).
*   `/p:DCC_Quiet=true` (reduz sobrecarga de log no console).
*   `/p:DCC_MapFile=0` (desativa geração de arquivos `.map`, poupando escrita em disco).
*   `/p:DCC_Warnings=false` e `/p:DCC_Hints=false` (elimina a validação secundária de avisos em micro-builds).

### B. Direct DCC Compiler Bypass (Ciclo de Milissegundos):
Para máxima velocidade local, o plugin suporta um modo de bypass completo do MSBuild, evitando o overhead de inicialização do motor .NET:
1.  **Leitura Direta de Caminhos:** O plugin realiza o parse rápido da estrutura XML do arquivo `.dproj` e resolve de forma dinâmica as variáveis do caminho de busca (`$(BDS)`, `$(Platform)`, `$(Config)`, `DCC_UnitSearchPath`).
2.  **Invocação Direta:** Invoca diretamente o binário `dcc32.exe`/`dcc64.exe` (ou o compilador da IDE na própria memória via Open Tools API) passando os parâmetros:
    *   `-M` (Make incremental).
    *   `-Q` (Quiet).
    *   `-V-` e `-$D-` (desativa geração legada e estendida de debug).
    *   `-NSsystem;vcl;xml;winapi;fmx` (injeta os namespaces comuns para otimizar a pesquisa de System.pas).
    *   `-U"<search_paths>"` (caminho completo resolvido).

### C. Descoberta Estática por AST Parser:
*   Ao carregar um projeto, o plugin invoca o `DextASTParser` em background para mapear as fixtures e testes sem precisar de compilação inicial. Isso habilita os ícones de execução (Play/Debug) no gutter ao lado de cada método de teste imediatamente.

---

## 7. Referências de APIs da IDE (Open Tools API - OTA)

Para fins de implementação e consulta rápida, estas são as interfaces da Open Tools API que o plugin utilizará:

### A. Estrutura do Grupo de Projetos e Arquivos:
*   **`IOTAModuleServices`:** Serviço global para gerenciar os módulos abertos. Utilizado para encontrar o projeto de testes ativo e a Unit ativa (`ModuleServices.GetActiveProject`).
*   **`IOTAProjectGroup`:** Representa o grupo de projetos ativo (`.groupproj`). Usado para iterar por todos os projetos de teste associados.
*   **`IOTAProject`:** Representa um projeto individual (`.dproj`). Utilizado para coletar caminhos físicos de busca (`DCC_UnitSearchPath`) e disparar compilações.

### B. Manipulação do Editor e Gutter:
*   **`IOTAEditorServices`:** Permite interagir com a janela ativa do editor de código.
*   **`IOTAEditBuffer` / `IOTAEditView`:** Usados para ler o conteúdo do arquivo ativo, verificar linhas modificadas (para Impact Analysis) e registrar listeners.
*   **`IOTAEditPosition`:** Controla a movimentação do cursor. Usado para abrir a unit e navegar para a linha exata de um erro reportado pelo Stack Trace.
*   **`IOTAGutterVisualizer` / `IOTAGutterVisualizer2`:** Interface para desenhar ícones customizados no gutter (Play/Debug) ao lado da declaração dos métodos de teste identificados pelo AST parser.

### C. Janela Dockable & UI:
*   **`INTADockableForm`:** Interface necessária para criar formulários VCL que podem ser acoplados (docked) nas barras laterais ou inferiores do Delphi, mantendo o estado de layout da IDE.
*   **`IOTAIDEThemingServices`:** Serviço usado para registrar as classes de formulário do plugin (`RegisterFormClass`), permitindo que a IDE aplique automaticamente o tema ativo (Light/Dark) nos nossos componentes VCL nativos.

### D. Compilação e Eventos:
*   **`IOTACompileServices`:** Permite interceptar eventos de compilação da IDE e disparar compilações em background silenciosas.


