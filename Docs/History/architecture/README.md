# Dext Framework - High-Level Architecture

This document describes the internal architecture of the Dext Framework and how data flows through its various layers.

## System Overview

Dext is designed as a modular, high-performance framework. It abstracts the underlying HTTP server, allowing for pluggable adapters while maintaining a consistent programming model.

### 🔄 Request Lifecycle Diagram

```mermaid
graph TD
    A[Client Request] --> B{Server Adapter}
    B -- stable --> C[TDextIndyWrapper]
    B -- enterprise --> D[TDextKestrelWrapper]
    B -- future --> E[Native epoll/http.sys]

    C & D & E --> F[TDextHttpContext]
    
    F --> G[Middleware Pipeline]
    
    subgraph Pipeline
        G1[Logger] --> G2[Auth] --> G3[Compression] --> G4[...]
    end
    
    G4 --> H[TDextRouter]
    H --> I[TDextHandlerInvoker]
    
    subgraph Execution
        I --> J[MVC Controller]
        I --> K[Minimal API Handler]
        I --> L[DataAPI (Auto-CRUD)]
    end
    
    J & K & L --> M[Dext Entity ORM]
    M --> N[(Database)]
    
    N --> M --> Execution --> F --> O[Client Response]
```

## Core Components

### 1. Server Adapters (`Sources\Web\Server`)
Dext doesn't implement its own raw socket listener by default. It uses **Adapters**:
*   **Indy**: The default stable driver for Delphi.
*   **Kestrel (Research)**: High-performance engine using .NET interop via NativeAOT.
*   **WebBroker**: Compatibility layer for IIS/Apache/Standalone.

### 2. The Middleware Pipeline
Inspired by ASP.NET Core, every request passes through a chain of middlewares. Each middleware can:
*   Process the request before the next one.
*   Short-circuit the pipeline (e.g., Auth failure).
*   Process the response after the handler has executed.

### 3. Handler Invoker & Model Binding
This is the "brain" of the Web module. It uses **Dext.Expressions** and **Smart Reflection** to:
*   Analyze method signatures.
*   Bind values from Query, Route, Header, and Body to parameters.
*   Inject services from the DI container (`TDextServices`).

### 4. Dext Entity ORM (`Sources\Entity`)
A Code-First ORM that manages database communication:
*   **DbContext**: Orchestrates the Unit of Work.
*   **Linq Engine**: Translates Pascal expressions into optimized SQL.
*   **Change Tracker**: Detects entity modifications to generate surgical `UPDATE` statements.

---
*For more details on specific modules, check the Dext Book chapters.*
