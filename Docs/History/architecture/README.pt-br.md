# Dext Framework - Arquitetura de Alto Nível

Este documento descreve a arquitetura interna do Dext Framework e como os dados fluem através de suas diversas camadas.

## Visão Geral do Sistema

O Dext foi projetado como um framework modular de alta performance. Ele abstrai o servidor HTTP subjacente, permitindo o uso de adaptadores plugáveis enquanto mantém um modelo de programação consistente.

### 🔄 Diagrama do Ciclo de Vida da Requisição

```mermaid
graph TD
    A[Requisição do Cliente] --> B{Server Adapter}
    B -- estável --> C[TDextIndyWrapper]
    B -- enterprise --> D[TDextKestrelWrapper]
    B -- futuro --> E[Native epoll/http.sys]

    C & D & E --> F[TDextHttpContext]
    
    F --> G[Pipeline de Middlewares]
    
    subgraph Pipeline
        G1[Logger] --> G2[Auth] --> G3[Compressão] --> G4[...]
    end
    
    G4 --> H[TDextRouter]
    H --> I[TDextHandlerInvoker]
    
    subgraph Execução
        I --> J[Controller MVC]
        I --> K[Handler Minimal API]
        I --> L[DataAPI (Auto-CRUD)]
    end
    
    J & K & L --> M[Dext Entity ORM]
    M --> N[(Banco de Dados)]
    
    N --> M --> Execução --> F --> O[Resposta ao Cliente]
```

## Componentes Principais

### 1. Adaptadores de Servidor (`Sources\Web\Server`)
O Dext não implementa seu próprio listener de socket puro por padrão. Ele utiliza **Adapters**:
*   **Indy**: O driver padrão e estável para Delphi.
*   **Kestrel (Pesquisa)**: Motor de alta performance utilizando interop com .NET via NativeAOT.
*   **WebBroker**: Camada de compatibilidade para IIS/Apache/Standalone.

### 2. O Pipeline de Middlewares
Inspirado no ASP.NET Core, cada requisição passa por uma cadeia de middlewares. Cada middleware pode:
*   Processar a requisição antes do próximo.
*   Interromper o pipeline (ex: falha de Autenticação).
*   Processar a resposta após a execução do handler.

### 3. Handler Invoker & Model Binding
Este é o "cérebro" do módulo Web. Ele utiliza **Dext.Expressions** e **Smart Reflection** para:
*   Analisar as assinaturas dos métodos.
*   Vincular valores de Query, Route, Header e Body aos parâmetros.
*   Injetar serviços do container de DI (`TDextServices`).

### 4. Dext Entity ORM (`Sources\Entity`)
Um ORM Code-First que gerencia a comunicação com o banco de dados:
*   **DbContext**: Orquestra a Unidade de Trabalho (Unit of Work).
*   **Linq Engine**: Traduz expressões Pascal em SQL otimizado.
*   **Change Tracker**: Detecta modificações nas entidades para gerar comandos `UPDATE` cirúrgicos.

---
*Para mais detalhes sobre módulos específicos, consulte os capítulos do Dext Book.*
