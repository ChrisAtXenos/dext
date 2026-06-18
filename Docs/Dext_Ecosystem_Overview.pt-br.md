# Dext Framework — Visão de Ecossistema

> *"Não é uma coleção de bibliotecas. É uma plataforma integrada."*

Este documento apresenta o **Dext Framework** como um ecossistema coeso, destacando como cada subsistema se conecta para formar uma plataforma de desenvolvimento enterprise completa — algo que **não existia no Delphi** antes.

Existem projetos excelentes no ecossistema Delphi que resolvem problemas isolados (ORM, DI, testes, REST). O diferencial do Dext é que **todas as peças foram desenhadas para funcionar juntas**, do request HTTP até a persistência no banco, passando por DI, logging, validação, serialização e telemetria — tudo em uma pipeline unificada e coerente.

---

## 🧬 A Filosofia: Simplicidade Exige Engenharia Sofisticada

> *"Simplicity is Complicated."* — Rob Pike

O desenvolvedor escreve `App.MapGet('/users', ...)` e ganha roteamento, model binding, serialização JSON, DI, logging e tratamento de erros. Mas por baixo, o framework resolve:

1. O **Reflection Engine** descobre os tipos dos parâmetros via RTTI cache thread-safe
2. O **Activator** resolve dependências com **greedy constructor selection**
3. O **DI Container** injeta serviços com lifecycle híbrido (ARC para interfaces, manual para classes)
4. O **Model Binder** desserializa o body JSON usando o driver de alta performance (zero-allocation UTF-8)
5. O **Validation Engine** aplica atributos de validação automaticamente
6. O handler executa a lógica de negócio
7. O resultado é serializado via `TUtf8JsonWriter` diretamente para o socket — **sem string intermediária**

Tudo isso acontece invisível ao desenvolvedor. Essa é a promessa.

> *"Make what is right easy and what is wrong difficult."* — Steve "Ardalis" Smith

---

## 🌐 Web Server Agnostic: Flexibilidade de Hospedagem

O Dext Web Framework é completamente isolado da implementação do servidor HTTP subjacente. Você escreve a sua aplicação e a sua lógica de rotas uma única vez e escolhe como vai servir esse tráfego dependendo do ambiente e licenciamento, suportando:

1. **Indy (Built-in)**: A escolha padrão. Vem nativo com o Delphi, sem nenhuma dependência externa. Perfeito para APIs internas, microsserviços standalone, testes e desenvolvimento rápido.
2. **WebBroker (Delphi Professional/Enterprise)**: A escolha para infraestrutura legada ou web servers consolidados. Permite rodar a mesma aplicação Dext como **Módulo Apache**, **ISAPI** (IIS) ou **FastCGI** (para ser servida via NGINX).
3. **Delphi Cross Sockets - DCS (Alta Performance)**: A escolha para escalabilidade extrema e aplicações Real-Time. Usa APIs assíncronas do sistema operacional (**IOCP** no Windows, **EPOLL** no Linux e **KQUEUE** no macOS) e oferece suporte nativo a **WebSockets** para comunicações bidirecionais. 
   * *Atenção de Licenciamento:* O DCS é uma dependência de terceiros licenciada sob **LGPL**. Caso opte por usá-lo em produção, é necessário avaliar a compatibilidade com a forma de distribuição do seu projeto comercial.
4. **Windows HTTP Server API - http.sys (Zero-Allocation Nativo)**: A escolha para performance máxima no Windows. Registra-se diretamente com o driver de modo kernel `http.sys` do Windows, ignorando o overhead de sockets no espaço de usuário. Oferece **zero alocações de heap** no hot-path de processamento de requisições e respostas usando pools de contexto e mapeamento direto em tabela de cabeçalhos UTF-8 conhecida.

---

## 🔥 Pipeline Web Zero-Allocation: O Motor de Performance

A pipeline HTTP do Dext foi integralmente refatorada para **eliminar alocações de heap** nos hot-paths de processamento de requisições. Isso não é uma otimização pontual — é uma filosofia arquitetural que perpassa toda a stack:

### Da Requisição à Resposta — Sem Alocar

```
[Socket] → TByteSpan (raw bytes, stack-allocated)
         → TUtf8JsonReader (parsing zero-copy direto do buffer)
         → TUtf8JsonSerializer (record fields via PTypeInfo cache — sem TValue boxing)
         → Prop<T> / Smart Types (query mode ou runtime mode, sem intermediários)
         → Handler executa lógica
         → TUtf8JsonWriter (streaming direto para o socket — sem string intermediária)
         → [Socket]
```

**Componentes envolvidos na pipeline zero-allocation:**

| Camada | Componente | Impacto |
|---|---|---|
| **Parsing de entrada** | `TByteSpan` + `TUtf8JsonReader` | Evita conversão UTF-8 → UTF-16 → UTF-8 |
| **Desserialização** | `TUtf8JsonSerializer` | Cache de `TJsonRecordInfo` por `PTypeInfo` — elimina RTTI scan repetido |
| **RTTI / Reflection** | `TReflection` | Lock-free fast path com cache singleton de metadata |
| **Value Conversion** | `TValueConverterRegistry` | Lookup 3 níveis sem alocação de TValue intermediário |
| **Comparações** | `TDextSimd.EqualsBytes` | AVX2 (32 bytes/ciclo) ou SSE2 (16 bytes/ciclo) |
| **Serialização de saída** | `TUtf8JsonWriter` | Streaming direto para output buffer — zero string temporária |
| **View Engine** | Flyweight Iterators | Memória O(1) em loops de template |

**O resultado**: O tempo de processamento de requisições caiu **drasticamente** em comparação com pipelines tradicionais que convertem strings múltiplas vezes. Cada requisição toca a heap **o mínimo possível**.

---

## 🧠 Smart Types: A DSL que Não Deveria Existir no Delphi

O sistema `Prop<T>` é a inovação mais significativa do Dext — uma **DSL fluente LINQ-like com tipagem forte** implementada inteiramente via **operator overloading** e **expression trees**. Isso não existia no Delphi.

### O Que o Desenvolvedor Escreve

```pascal
TUser = class
  property Age: IntType ...;      // Alias para Prop<Integer>
  property Name: StringType ...;  // Alias para Prop<string>
end;

var U := Prototype.Entity<TUser>;
// Query com compilação estática e IntelliSense
var Users := DbContext.Users
  .Where((U.Age > 18) and (U.Name.StartsWith('Ce')))
  .OrderBy(U.Age.Desc)
  .Take(50)
  .ToList;
```

### O Que Acontece Por Baixo

1. `TPrototype` cria uma instância "fantasma" de `TUser` com `IPropInfo` injetado em cada `Prop<T>`
2. Quando `U.Age > 18` executa, o `Prop<Integer>` está em **Query Mode** — em vez de comparar valores, gera um nó `TBinaryExpression(TPropertyExpression('Age'), TLiteralExpression(18), boGreaterThan)`
3. O operador `and` combina as expressões em `TLogicalExpression(left, right, loAnd)`
4. O `BooleanExpression` final carrega toda a AST
5. O **SQL Dialect Compiler** percorre a árvore e gera: `WHERE "Age" > 18 AND "Name" LIKE 'Ce%'`

**A mágica**: O mesmo `Prop<T>` funciona em dois modos. Em contexto de query, gera SQL. Em contexto de runtime, opera como value type normal. O desenvolvedor **nunca muda de API** — é a mesma entidade nos dois cenários.

### Profundidade do Type System

```
Prop<T>  ───────────►  BooleanExpression  ────►  IExpression (AST)
  │                           │                    │
  ├─ Implicit(T)              └─ and/or/not        ├─ TPropertyExpression
  ├─ Implicit(Nullable<T>)                         ├─ TBinaryExpression
  ├─ Implicit(Variant)                             ├─ TLogicalExpression
  ├─ Like/StartsWith/Contains                      ├─ TFunctionExpression
  ├─ In/NotIn/Between/IsNull                       ├─ TLiteralExpression
  ├─ Asc/Desc → IOrderBy                           └─ TConstantExpression
  └─ Aritmética: +, -, *, /
```

---

## 🏎️ Collections & Concurrency: Oásis de Performance

O Dext reconstrói as bases de dados do Delphi para resolver os dois maiores gargalos de aplicações modernas: **Generic Code Bloat** (inchaço de binário/lentidão de build) e **Thread Contention** (travamentos em multi-core).

### 1. Binary Code Folding: O Fim do Inchaço de Genéricos
O compilador Delphi gera binário duplicado para cada especialização de genérico. O Dext implementa o padrão **Code Folding**, onde centenas de instâncias de `IList<T>` compartilham um único motor central `TRawList` que opera sobre memória bruta. 
- **Impacto Real**: Redução de **60% no tempo de compilação** em grandes projetos (ex: build de 9min reduzido para 3.5min).

### 2. Arquitetura Sniper (Zero-Alloc & SIMD)
- **Dicionários com Open Addressing**: Diferente da RTL (que usa listas ligadas e gera cache misses), o `TRawDictionary` usa *Linear Probing* em memória contígua. **Resultado: 6.6x mais rápido que a RTL.**
- **Aceleração SIMD**: Varreduras de memória usando instruções de hardware (AVX2/SSE2) processam até 32 bytes por ciclo. **Resultado: Sorts 6.8x mais rápidos.**
- **Vector + Span**: Manipulação de buffers e arquivos enormes sem alocação de memória intermediária.

### 3. Concorrência Moderna (Inspirada em Go e .NET 8)
- **IChannel\<T\>**: Canais de transmissão *Lock-Free* com suporte nativo a **Backpressure** (Bounded Channels) — essencial para evitar que produtores rápidos derrubem o servidor.
- **Frozen Collections**: Coleções imutáveis ("Write once, freeze") que permitem infinitas leituras simultâneas sem nenhum uso de travas (`TCriticalSection`), eliminando gargalos de escalabilidade em backend.

---

## 🏗️ O Ecossistema Integrado: Como Tudo Se Conecta

O que diferencia o Dext de soluções isoladas é a **integração de ponta a ponta**. Cada subsistema foi desenhado com conhecimento dos demais:

### O Grafo de Integração

```
                        ┌──────────────────┐
                        │   Dext CLI       │
                        │  (dext new/add)  │
                        └────────┬─────────┘
                                 │ gera projetos usando
                                 ▼
┌────────────────┐      ┌──────────────────┐      ┌────────────────┐
│ Template Engine│◄─────│  Web Pipeline    │─────►│ View Engine    │
│ (AST-based)    │      │  (Zero-Alloc)    │      │ (SSR/Stencils) │
└────────────────┘      └────────┬─────────┘      └────────────────┘
                                 │
                    ┌────────────┼──────────────┐
                    ▼            ▼              ▼
        ┌──────────────┐  ┌────────────────┐  ┌──────────────┐
        │ DI Container │  │ JSON Engine    │  │ Validation   │
        │ (Hybrid ARC) │  │ (UTF-8 0-alloc)│  │ (Attribute)  │
        └──────┬───────┘  └──────┬─────────┘  └──────────────┘
               │                 │
               ▼                 ▼
        ┌──────────────┐ ┌────────────┐  ┌──────────────────┐
        │  Reflection  │ │Smart Types │  │ Collections      │
        │  (Cache)     │ │ (Prop<T>)  │  │ (SIMD/Channels)  │
        └──────┬───────┘ └──────┬─────┘  └────────┬─────────┘
               │                │                 │
               ▼                ▼                 ▼
        ┌──────────────────────────────────────────────────┐
        │        Memory & Performance Foundation           │
        │   (TSpan<T>, TByteSpan, SIMD, Code Folding)      │
        └───────────────┬────────────────┬─────────────────┘
                        │                │ 
                        ▼                ▼
                ┌──────────────┐   ┌──────────────┐
                │   ORM        │◄──│Specifications│
                │ (Multi-DB)   │   │ (IExpression)│
                └──────┬───────┘   └──────────────┘
                       │
              ┌────────┼──────────┐
              ▼        ▼          ▼
          ┌────────┐  ┌────────┐  ┌────────┐
          │ PgSQL  │  │ MSSQL  │  │ MySQL  │ ... + Firebird, SQLite, Oracle
          └────────┘  └────────┘  └────────┘
```

### Integrações Chave que Não Existem em Soluções Isoladas

| Integração | O Que Faz | Por Que Importa |
|---|---|---|
| **DI → ORM → Web** | DbContext é registrado como Scoped; cada request HTTP recebe sua instância; o EventBus compartilha o mesmo scope | Sem isso, transações e Identity Map quebram |
| **Smart Types → ORM → SQL** | `Prop<T>` gera AST → ORM compila para o dialeto correto (PostgreSQL, MSSQL, etc.) | Query type-safe com IntelliSense, sem magic strings |
| **Reflection → JSON → Web** | Cache RTTI é compartilhado entre serialização JSON, model binding, ORM mapping e validation | Um único scan RTTI serve todo o framework |
| **Templating → CLI → Web** | O mesmo motor de templates serve: scaffolding CLI, SSR web e geração de relatórios de testes unitários | Uma engine, três usos — zero dependência cruzada |
| **EventBus → DI → Lifecycle** | Behaviors (Logging, Timing, Exception) são resolvidos via DI; lifecycle events conectam ao Host | Cross-cutting concerns sem acoplamento |
| **Collections → SIMD → JSON** | `TByteSpan.Equals` usa `TDextSimd.EqualsBytes` (AVX2/SSE2) para comparações do parser JSON | Hardware acceleration transparente |
| **Navigator → DI → Middleware** | Navigator usa a mesma arquitetura de middleware pipeline do Web para auth guards em navegação desktop | Desktop com padrões de segurança web |
| **EntityDataSet → ORM → VCL** | `TEntityDataSet` lê offsets via `TEntityMap` do ORM; `LoadFromUtf8Json` usa `TByteSpan` zero-alloc | Bridge perfeita entre ORM moderno e grids legadas |
| **REST Client → Async → DI** | `TRestClient` usa connection pool thread-safe; `TAsyncTask` encadeia operações; auth providers injetados via DI | HTTP client com mesma DX fluente do resto do framework |
| **HTMX → View Engine → ORM** | Flyweight Iterators streamam queries do ORM direto para templates; HTMX auto-detection suprime layouts | Full-stack SSR com O(1) memória e zero JavaScript |

---
## 📦 Inovações no Dext.ORM: Multi-Mapping e Command Pattern

O Dext.ORM não se limita a emular o Entity Framework; ele resolve dores históricas de acesso a dados com soluções de alta performance inspiradas em micro-mappers (como o Dapper) e padrões arquiteturais avançados.

### 1. Multi-Mapping Sem Boilerplate (Split-free)
Diferente do Dapper (.NET), que exige a declaração de strings mágicas de divisão (`splitOn: 'Id'`) para mapear joins planos para grafos de objetos, o Dext realiza **roteamento de caminhos baseado em convenção**:
* **Varredura de Colunas**: Ao encontrar colunas com separadores `_` ou `.` (ex: `Product_Name` ou `Product.Price`), o hidratador reconhece a intenção de aninhamento.
* **Auto-Instanciação Recursiva**: Se o objeto aninhado (`Product: TProduct`) estiver marcado com `[Nested]` e for `nil`, o framework o aloca dinamicamente em tempo de execução via `TActivator` de forma preguiçosa.
* **Profundidade Infinita**: O hidratador do Dext percorre caminhos de qualquer profundidade (ex: `Order_Customer_Address_City`) de forma recursiva automática.
* **Performance O(1)**: O mapeamento ignora *setters* lentos e injeta os valores diretamente nos offsets de memória física dos campos de suporte (`FFields`), eliminando alocações de heap intermediárias.

### 2. Stored Procedures como Command/CQRS Pattern
Executar stored procedures com múltiplos parâmetros de entrada/saída ou múltiplos datasets em ORMs tradicionais é uma fonte constante de vazamentos de conexão e código de baixo nível. O Dext transforma procedures em classes de **Command fortemente tipadas**:
* **Classe de Contrato**: O desenvolvedor declara uma classe representando a procedure (ex: `TGetTopProducts`), anotando parâmetros de entrada e saída com `[DbParam]`.
* **Auto-Hidratação de Projeções**: Conjuntos de dados retornados são hidratados automaticamente em coleções (ex: `Results: IList<TProduct>`) expostas na própria classe.
* **Isolamento de Banco**: Toda a complexidade de criar objetos de parâmetros do ADO.NET/FireDAC, associar tipos de dados físicos e abrir/fechar cursores é abstraída pelo Dext. O desenvolvedor apenas instancia o comando, define as propriedades de entrada e executa `Db.Execute(Command)`.

---

## 🖼️ TEntityDataSet: A Ponte Mágica entre ORM e Design-Time UI

> *"E se uma empresa com um grande ERP de mercado quiser adotar o Dext? Como ela lidaria com centenas de forms lotados de componentes DB-aware (DBGrids, DevExpress cxGrid) e dezenas de relatórios FastReport desenhados visualmente na IDE?"*

Foi exatamente essa pergunta que guiou a criação desta feature. Desenvolver APIs modernas com POCOs e Clean Architecture é excelente, mas o Delphi é insuperável na produtividade de construção visual de UIs. O `TEntityDataSet` foi construído para ser a ponte perfeita entre a nova arquitetura e o rico ecossistema de componentes visuais legados, **sem abrir mão de performance ou da experiência de desenvolvimento (DX)**.

1. **Performance Absurda via Zero-Allocation**: Diferente de conversores tradicionais que usam RTTI em cada leitura, o `TEntityDataSet` se conecta nativamente a um `TList<T>` (ou `TObjectList<T>`). Ele extrai os *offsets* de memória durante a inicialização via `TEntityMap`. Durante o binding com a grid, ler um dado é virtualmente acessar um ponteiro de memória diretamente, sem reflexão.
2. **Setup Automático (Parse de Entidades)**: Esqueça configurar colunas manualmente. Em *design-time*, o Dext faz o parse das suas units, localiza as entidades marcadas com atributos e **cria todos os `TFields` automaticamente** no DataSet.
3. **Design-Time Data Preview Real**: Desenvolver relatórios (FastReport) "no escuro" é frustrante. O Dext resolve isso de forma brilhante: se você informar um `TFDConnection` e um `DataProvider`, o framework **gera um SQL dinâmico em tempo de design** e popula o `TEntityDataSet` com dados reais do banco. Você vê os dados na grid da IDE! 
   * *Atenção:* Em *runtime*, esse SQL não é executado; o componente consome a sua lista de objetos real, respeitando a lógica da sua aplicação.

---

## 🧪 O Ciclo Completo de Qualidade

O Dext não apenas permite construir aplicações — ele garante que sejam **testáveis de ponta a ponta**:

```
[Código] → [Testes Unitários + Mocking]
         → [Auto-Mocking Container (TAutoMocker)]
         → [Snapshot Testing (JSON baselines)]
         → [Code Coverage (dext test --coverage)]
         → [Quality Gates (thresholds CI/CD)]
         → [Relatórios: JUnit XML, TRX, SonarQube, HTML]
         → [Live Dashboard (dext ui)]
```

**Tudo integrado com DI**: `TTestServiceProvider` substitui serviços de produção por mocks sem alterar o código da aplicação.

### O Arsenal de Qualidade

1. **Auto-Mocking Container (`TAutoMocker`)**: Chega de instanciar dezenas de mocks manualmente. O `TAutoMocker` resolve o grafo de dependências e injeta mocks em todas as interfaces exigidas pela classe sob teste.
2. **Snapshot Testing (`MatchSnapshot`)**: Para testar estruturas complexas de JSON ou DTOs gigantes. O Dext serializa o resultado, compara com o snapshot aprovado e acusa qualquer regressão.
3. **Code Coverage Integrado**: Execute `dext test --coverage` na CLI e o framework usa instrumentação própria para gerar relatórios detalhados de cobertura (linhas/branches) prontos para o SonarQube.
4. **Integração CI/CD Nativa**: Suporte "out of the box" para gerar relatórios em formatos da indústria: JUnit XML, TRX, e HTML. Quality Gates reprovam a pipeline automaticamente se a cobertura cair.
5. **Live Test Dashboard**: Execute `dext ui` e ganhe um dashboard local, moderno (dark-theme) rodando no navegador para visualizar a execução de toda a sua suíte de testes em tempo real.

---

## 🗄️ Database as API: Uma Linha de Código, Todo o Ecossistema Trabalhando

O **Database as API** é a demonstração definitiva de como o ecossistema integrado do Dext elimina o atrito arquitetural. É perfeitamente possível construir APIs similares costurando bibliotecas isoladas, mas o custo prático é brutal: montanhas de código *boilerplate*, gargalos de performance, mapeamentos exaustivos de DTOs, excesso de alocações na memória (garbage collection) e uma base de código frágil e difícil de manter. O Dext resolve isso na raiz: com **uma única linha de código**, o desenvolvedor ganha uma API REST completa com segurança, filtros, paginação, documentação e telemetria — tudo operando de forma coesa sobre uma pipeline *zero-allocation* com qualidade enterprise.

### O Que o Desenvolvedor Escreve

```pascal
[Table, DataApi]  // ← Isso é tudo.
TProduct = class
  [PK, AutoInc] property Id: Integer;
  property Name: string;
  property Price: Double;
end;

// No startup:
App.Builder.MapDataApis;  // Escaneia RTTI, registra todas as [DataApi] automaticamente
```

### O Que o Framework Entrega

```
Uma linha → 5 endpoints REST (GET list, GET by id, POST, PUT, DELETE)
          → 11 operadores de filtro via QueryString (_gt, _lt, _cont, _in, ...)
          → Paginação automática (_limit, _offset)
          → Ordenação dinâmica (_orderby=price desc)
          → Segurança por operação (RequireAuth, RequireRole, ReadRole vs WriteRole)
          → Documentação Swagger automática
          → Telemetria (TDiagnosticSource)
          → Logging estruturado
          → Multi-tenancy (RequireTenant)
          → Suporte a UUID, GUID e Composite Keys
```

### Quantos Subsistemas São Ativados com Uma Linha?

| Subsistema | O Que Faz no DataApi |
|---|---|
| **RTTI / Reflection** | `TDataApi.MapAll` escaneia atributos `[DataApi]` via `TReflection.Context.GetTypes`. `ResolvePropertyName` converte snake_case→PascalCase via `GetHandlerBySnakeCase` |
| **DI Container** | `GetDbContext` resolve `TDbContext` do scope da request — cada request HTTP tem sua própria instância |
| **ORM (TDbContext)** | `DataSet(ClassInfo)` retorna `IDbSet` dinâmico. `Add`, `Update`, `Remove`, `FindObject`, `ListObjects` |
| **Specifications (AST)** | Filtros da QueryString geram `IExpression` via `TStringExpressionParser.Parse` — a **mesma AST** usada por `Prop<T>` |
| **JSON Engine** | `TDextJson.Deserialize` (entrada) + `TDextSerializer` (saída) com `NamingStrategy` e `EnumStyle` configuráveis per-endpoint |
| **Model Binding** | `TEntityIdResolver` delega ao `IModelBinder` para converter `{id}` da URL para Integer/TUUID/TGUID automaticamente |
| **Security** | `CheckAuthorization` valida JWT via `IClaimsPrincipal` com separação read/write roles |
| **Swagger / OpenAPI** | Endpoints aparecem automaticamente na spec com tags e descrições |
| **Telemetria** | `TDiagnosticSource.Write('DataApi.ModelBinding.Start/Complete')` para tracing |
| **Naming Conventions** | `TDataApiNaming.GetDefaultPath` remove prefixo `T`, pluraliza (y→ies, s→ses), gera `/api/products` |

**Isso é o que a integração faz**: Nenhum desses subsistemas foi criado *para* o DataApi. Cada um foi criado como peça independente do ecossistema. O DataApi simplesmente os **orquestra** — e o resultado é que uma única linha de código ativa 10 subsistemas trabalhando em harmonia.

### Três Modos de Registro

```pascal
// 1. Automático — [DataApi] + MapDataApis
App.MapDataApis;

// 2. Manual tipado
TDataApiHandler<TProduct>.Map(App, '/api/products');

// 3. Fluente com políticas
App.Builder.MapDataApi<TProduct>('/api/products', DataApiOptions
  .Allow([amGet, amGetList])      // Somente leitura
  .RequireAuth                    // JWT obrigatório
  .RequireWriteRole('Admin')      // Apenas Admin pode POST/PUT/DELETE
  .UseSnakeCase                   // JSON em snake_case
  .EnumsAsStrings                 // Enums como texto
  .DbContext<TMyContext>          // Contexto específico
  .Tag('Products')                // Tag no Swagger
);
```

---

## 📊 O Que o Dext Trouxe para o Delphi

| Capacidade | Como o Dext Resolve |
|---|---|
| **DSL LINQ-like type-safe** | `Prop<T>` + Expression Trees + operator overloading |
| **Type Definition Separation** | `TEntityType<T>` separa dados (POCO) de metadados (Smart Props) para uso em sistemas legados |
| **Pipeline HTTP zero-allocation** | `TByteSpan` → `TUtf8JsonReader` → handler → `TUtf8JsonWriter` → socket |
| **Code Folding (Generics)** | TRawList compartilha binário — **Builds 60% mais rápidos** |
| **Frozen Collections (.NET 8 style)** | `TFrozenDictionary<K,V>`, `TFrozenSet<T>` — Leituras simultâneas lock-free |
| **Go-style Channels** | `IChannel<T>` com bounded/unbounded e back-pressure nativo |
| **SIMD-accelerated collections** | Dicionários **6.6x mais rápidos** e Sorts **6.8x mais rápidos** via AVX2/SSE2 |
| **Lock Striping (concurrent dict)** | `TConcurrentDictionary<K,V>` com array de `TSpinLock` |
| **Minimal API style routing** | `App.MapGet`, `App.MapPost` com auto-binding |
| **Auto-Mocking Container** | `TAutoMocker` injeta mocks automaticamente |
| **Snapshot Testing** | `MatchSnapshot` com baselines JSON |
| **Database as API (zero-code)** | `[DataApi]` + `MapDataApis` → CRUD REST com 11 filtros, segurança, Swagger, telemetria, multi-tenant — **10 subsistemas ativados com 1 linha** |
| **Expression Evaluator (dual-mode AST)** | Mesma `IExpression` AST gera SQL no banco E avalia in-memory no servidor |
| **Soft Delete declarativo** | `[SoftDelete]` → Remove vira UPDATE, `Restore`, `OnlyDeleted`, `IgnoreQueryFilters` |
| **JSON/JSONB Column Queries** | `.Json('path')` cross-database: PG `#>>`, MySQL `JSON_EXTRACT`, SQLite `json_extract`, MSSQL `JSON_VALUE` |
| **Flutter-style Navigator (Desktop)** | Push/Pop/PopUntil + 3 Adapters + Middleware Pipeline + Auth Guard |
| **Magic Binding (Desktop MVVM)** | `[BindEdit]`, `[BindText]`, `[OnClickMsg]` — two-way binding por atributos |
| **EntityDataSet zero-allocation** | Leitura via offsets `TEntityMap` + `LoadFromUtf8Json` + design-time Sync Fields |
| **Flyweight SSR Iterators** | 10K registros renderizados com O(1) memória — sem `ToList` |
| **HTMX Auto-Detection** | Pipeline suprime layout automaticamente para `HX-Request` headers |
| **REST Client com Connection Pool** | Record leve + async chaining (`ThenBy<T>`) + pluggable auth + cancellation |
| **TAsyncTask fluente** | `Run<T>.ThenBy<U>.OnComplete.OnException.Start` com cancellation |
| **IOptions<T> tipado** | Binding de seções JSON/YAML/ENV para classes tipadas — idêntico ao ASP.NET Core |
| **AI Skills nativas** | Skills modulares para Cursor/Antigravity/Copilot gerarem código idiomático Dext |
| **Multi-tenancy (Schema/DB/Column)** | 3 estratégias integradas com ORM |
| **SignalR-compatible Hubs** | `Dext.Web.Hubs` com grupos e broadcast |
| **AST Template Engine & WebStencils** | Parser → AST → Executor com layouts e integração nativa com WebStencils (12.2+) |
| **DI Híbrido (ARC + Manual)** | Interface → ARC, Classe → Manual lifecycle |
| **Defer Pattern (Go-style)** | `IDeferred` / `TDeferredAction` |
| **ILifetime<T> (ARC wrapper)** | Wrap de objetos Non-ARC em ARC |
| **Code Coverage via CLI** | `dext test --coverage` com SonarQube |
| **Live Test Dashboard** | Dashboard web dark-theme em tempo real |
| **Precise Stack Trace Extraction** | Extração de stack frames com origem e linha (`Dext.Core.Debug`) para rastrear erros no pipeline integrado |

---

## 🛤️ Roadmap: Para Onde o Ecossistema Está Indo

### Onda Atual (Em Progresso)
- **S14 — SOA via Interfaces**: RPC/gRPC Code-First transparente — defina interfaces Delphi, o framework gera as camadas de transporte automaticamente
- **S02 — gRPC & Protobuf**: Motor nativo IOCP/EPOLL para comunicação binária de alta velocidade
- **S06 — OAuth2 & OIDC**: Login nativo com Google, Microsoft, JWT
- **S13 — Redis Client**: Client async de alta performance com RESP3 e RedisJSON

### Futuro
- HTTP Server nativo (IOCP/EPOLL/Kqueue — sem dependência de DCS)
- OData, GraphQL
- Microservices Mesh (service discovery + load balancing)
- UI Nativo com Skia

---

## 📐 Decisões de Engenharia: Por Que Funciona

### 1. Record Types Como Foundation
O Delphi moderno (10.3+) suporta **operator overloading em records**, **implicit/explicit operators** e **class operators**. O Dext explora isso ao máximo: `Prop<T>`, `Nullable<T>`, `TUUID`, `TByteSpan`, `TSpan<T>`, `BooleanExpression` — todos são records com semântica de valor que eliminam alocações de heap.

### 2. Hybrid Memory Model
Em vez de forçar uma única estratégia (ARC ou manual), o DI Container detecta automaticamente: interfaces usam ARC (reference counting nativo do Delphi), classes usam lifecycle gerenciado (Singleton = framework destrói na saída, Scoped = framework destrói no fim do scope, Transient = chamador destrói).

### 3. Driver Pattern Para Extensibilidade
JSON, HTTP Server, e Database usam o mesmo padrão: uma abstração de interface com múltiplos drivers plugáveis. Isso permite trocar `JsonDataObjects` por `System.JSON`, ou `Indy` por `DCS` ou `WebBroker`, sem alterar código de aplicação.

### 4. Reflection Cache Como Backbone
O cache RTTI thread-safe com fast paths lock-free é **o backbone** de todo o framework. JSON, ORM, Validation, Model Binding, Smart Types — todos consultam o mesmo cache singleton. Um único scan RTTI na inicialização serve **toda a vida útil** do processo.

### 5. Binary Code Folding
Para combater o inchaço de binário das Generics no Delphi, o Dext utiliza uma técnica de *folding* onde o código tipado é apenas um wrapper fino sobre implementações `TRaw` que lidam com memória bruta. Isso preserva a tipagem forte para o desenvolvedor, mas economiza megabytes no executável e minutos no compilador.

### 6. Direct Memory Inject (JSON Parsing)
Em vez de depender de setters lentos e RTTI pesado durante a desserialização JSON, o Dext faz o mapeamento prévio dos offsets físicos dos campos em memória (`PByte(Obj) + Offset`). Durante o parsing, os valores são injetados diretamente no endereço de memória, eliminando camadas de abstração e alcançando performance próxima ao processamento de structs em C++.

### 7. Implicit CQRS (Read vs Write Pipeline)
O Dext DataApi adota uma estratégia de segregação de responsabilidade implícita:
- **Read (GET)**: Pipeline ultra-rápido de *Direct-to-JSON Streaming*, enviando dados do `IDbReader` direto para o socket com consumo de memória O(1).
- **Write (POST/PUT)**: Pipeline focado em segurança de domínio, com hidratação completa da entidade, rodando regras de negócio e validações antes da persistência.

### 8. Licenciamento Apache 2.0 (Segurança e Conformidade Snyk)
A governabilidade e segurança jurídica são requisitos fundamentais em projetos de nível corporativo. A escolha de licença do Dext é um elemento central de sua arquitetura de conformidade:
* **Conformidade em Pipelines CI/CD**: O Dext é 100% livre de dependências virais GPL ou AGPL. Ele passa sem restrições em ferramentas de auditoria e segurança como o **Snyk** ou **Black Duck** integradas em pipelines pós-commit.
* **Garantia de Patentes (Patent Peace)**: A licença Apache 2.0 concede explicitamente aos usuários direitos mundiais e irrevogáveis sobre qualquer patente detida pelos colaboradores que possa cobrir o código do Dext.
* **Retaliação de Patentes**: Blindagem jurídica contra trolls de patentes. Caso qualquer usuário processe judicialmente outro alegando violação de patente sobre o Dext, a sua licença de uso do framework é terminada imediatamente.
* **Isolamento de Outras Licenças**: A dependência do *Delphi Cross Sockets (DCS)* — que possui licença **LGPL** — é opcional e totalmente isolada do core. O Dext roda de forma 100% permissiva sobre o Indy ou WebBroker nativos, garantindo que o seu executável comercial permaneça estritamente proprietário e imune a contaminações de licenças Share-Alike.

### 5. Infrastructure Flywheel — Velocidade Exponencial de Features
A maturidade da infraestrutura cria um **efeito flywheel**: cada nova feature compõe de engines existentes, acelerando dramaticamente o desenvolvimento.

**Caso exemplar — Specification Pattern (inspirado por Steve "Ardalis" Smith)**:
O motor de Specifications foi construído originalmente para queries tipo-safe do ORM (`Prop<T>` → `IExpression` → SQL). Quando veio a necessidade de filtragem dinâmica no DataApi, o engine de Specifications **já sabia resolver** — `TStringExpressionParser` converte filtros da URL nos **mesmos nós `IExpression`** que `Prop<T>` gera em código tipado. A filtragem foi "grátis".

```
Engine Original                  →  Reuso Emergente
─────────────────────────────────────────────────────
Specification (ORM queries)      →  DataApi (URL filtering — grátis)
                                 →  In-Memory Evaluator (zero código extra)
Reflection Cache (JSON)          →  ORM + Validation + Model Binding + EntityDataSet
TByteSpan (zero-allocation)      →  JSON Reader + EntityDataSet + [Roadmap] Redis RESP3
TConnectionPool (REST Client)    →  [Roadmap] Redis Client (mesmo padrão)
TAsyncTask (async/await)         →  REST Client + [Roadmap] Redis + Background Services
```

**Resultado prático**: Na análise de viabilidade do Redis Client, ~80% da infraestrutura já existia — `TByteSpan`, `TAsyncTask`, `TConnectionPool`, `ICancellationToken`. O único código genuinamente novo é o protocolo RESP3.

### 6. O Trade-Off da Integração
A profundidade da integração traz um **multiplicador de responsabilidade**: uma alteração no `IExpression` deve ser validada contra **todos os consumidores**. Isso torna os testes automatizados não opcionais, mas **existenciais**. O ecossistema é sustentado por centenas de suítes de teste e milhares de asserções, abrangendo desde testes unitários atômicos até testes de integração cruzados em 5 bancos de dados simultâneos. A maturidade arquitetural é comprovada por projetos piloto em produção na **AWS e Azure**, além de sistemas de missão crítica em fase de testes processando mais de **800.000 requisições diárias** com alta performance. No total, o framework e seus testes englobam **mais de 200.000 linhas de código Pascal puro**, um testamento ao seu rigor técnico.

---

*Dext Framework — Performance nativa, produtividade moderna, ecossistema completo.*

**Compatibilidade**: Validado para Delphi 10.3+, com piso arquitetural no Delphi 2010. Suporte experimental para 10.1–10.2 via refatoração de variáveis inline. Web Stencils requer 12.2+.

*Construído em anos de estudo das melhores práticas de .NET, Go e Java — adaptadas com sabedoria para o que o Delphi faz de melhor.*

*Não é só Web. Não é só API. É Desktop, Networking, Testing, CLI, Observability e AI — tudo integrado.*
