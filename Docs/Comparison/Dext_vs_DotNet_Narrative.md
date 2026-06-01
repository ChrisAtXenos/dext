# Dext vs .NET: A Visionary Architecture Comparison

*How Dext bridges modern backend paradigms, enterprise engineering standards, and native compilation in a single, high-performance Delphi ecosystem.*

---

## The Perception Gap & Modern Frameworks

Modern backend engineering is frequently evaluated through the lens of dominant ecosystems like .NET and JVM. Developers looking at Object Pascal / Delphi from the outside often assume the ecosystem lacks the cohesive, unified, and highly structured architectures found in ASP.NET Core or Entity Framework Core. 

This document exists to close that perception gap. By providing concrete technical comparisons, code samples, and architectural benchmarks, we demonstrate that Dext is not only a fully peer-level enterprise framework, but one that actively pioneers new concepts specifically engineered for compiled native environments.


---

## Part 1: The Legitimate Inspiration

Dext was intentionally designed to bring the patterns of ASP.NET Core and Entity Framework Core to the Delphi world. The inspiration is not hidden — it's the design philosophy.

The same patterns are here:
- `DbContext` / Unit of Work / Change Tracking
- `IOptions<T>` / `IOptionsMonitor<T>` for typed configuration
- `IHostedService` / `TBackgroundService` for background tasks
- `ILogger<T>` / `ILoggerFactory`
- `Minimal APIs` with `app.MapGet(...)` / `app.MapPost(...)`
- `[FromBody]`, `[FromQuery]`, `[FromRoute]`, `[FromHeader]` model binding
- `IHealthCheck` with Healthy / Degraded / Unhealthy states
- `ProblemDetails` RFC 9457 for error responses

If you write .NET, you already know how to use Dext. The learning surface is intentionally minimal.

---

## Part 2: What We Share (Parity)

Dext achieves full functional parity with the .NET ecosystem across more than 60 features — spanning ORM/data access, the web framework, the core DI and configuration system, and the testing infrastructure. And critically: several of the most important patterns that in .NET require separate third-party NuGet packages (AutoMapper, MediatR, FluentAssertions, Moq, Ardalis.Specification) are shipped natively inside Dext as first-class citizens.

For the full itemized comparison, see the **[Feature Comparison Reference →](./Feature_Comparison_Dext_vs_DotNet.md)**. It covers 60+ parity features in structured tables (Block A), 17 Dext-exclusive features (Block B), honest gaps (Block C), and platform differences that don't apply to Delphi by design (Block D).

If you're coming from .NET: you already know how to use Dext. The API naming, the attribute patterns, and the architectural layers are intentionally familiar.

---

## Part 3: Where Dext Goes Beyond

This is the section that surprises people coming from .NET. These are features that **exist in Dext but not in the .NET ecosystem** (or require expensive third-party packages that aren't officially supported).

### Database as API — Runtime, Not Scaffold

This is Dext's most distinctive feature. Annotate an entity, and the framework generates a complete CRUD REST API at runtime — no code generation, no scaffolding, no controllers:

```pascal
type
  [DataApi('/api/products')]
  TProduct = class
    Id: IntType;
    Name: StringType;
    Price: CurrencyType;
  end;
```

One line at startup: `App.MapDataApis`.

Five endpoints generated. Pagination, sorting, 11 filter operators via URL QueryString, JWT validation, role-based access control, and automatic OpenAPI documentation.

In .NET, to reach the same point you need: a scaffolded controller, a service layer, a repository, a DTO, manual filter parsing, and a Swagger annotation pass. That is days of work vs. one line.

### Smart Properties — Ergonomics and DX Unified in Delphi

In C#, the ability to write type-safe, magic-string-free queries is provided natively by the language through lambda expressions and `Expression<Func<T, bool>>`. The C# compiler generates the expression tree transparently — no library required:

```csharp
// C# — the compiler generates the AST automatically
db.Products.Where(p => p.Price > 100 && p.Name.Contains("Widget"))
```

Delphi has no equivalent language mechanism. While excellent libraries like Spring4D offer lightweight RTTI-based expression support and other tools utilize structured string-based builders, Dext focuses deeply on **Developer Experience (DX)**. 

By combining Delphi's modern language capabilities—implicit record operations, operator overloading, and generic metadata caching—Dext introduces a **type-safe fluent DSL** inspired by LINQ ergonomics. Dext's `Prop<T>` generates a unified **Abstract Syntax Tree (AST)** that spans three separate execution environments:

```pascal
var P := Prototype.Entity<TProduct>; 

// 1. ORM — compiles the AST to a raw SQL WHERE clause
Db.Products.Where(P.Price > 100 and P.Name.Contains('Widget'))

// 2. In-memory — the TExpressionEvaluator filters a TList<T> locally
Filter.Evaluate(LocalCache, P.Price > 100 and P.Name.Contains('Widget'))

// 3. HTTP Routing — parsed automatically from ?price_gt=100&name_cont=widget
// The DataApi engine converts URL QueryString operators to AST nodes on the fly
```

This represents a clean, highly cohesive model: define the business query once, and let the same AST handle physical queries, memory cache filtering, and URL parsing dynamically.

**A note on the development process.** When the first prototype of `Prop<T>` was being designed, the AI coding assistant involved in development refused to help implement it — stating that building an expression tree system with operator overloading and implicit type conversions in Object Pascal was simply not possible. Even after the reasoning was explained in detail, the response was another assertion of impossibility.

The only way forward was to build a working proof-of-concept first, alone, and then present the running code as evidence. Once the prototype existed, collaboration resumed. The lesson: the boundary between "this is impossible in Delphi" and "this has never been done in Delphi" is not always where it appears to be. `Prop<T>` is a concrete example of that gap.

### Visual Telemetry Dashboard — Built-In (Work In Progress)

The built-in telemetry dashboard is an actively developed and improving feature that collects logs, SQL profiling, Gantt spans, and system metrics asynchronously with zero execution blocking. While it is still a work-in-progress, it offers rapid, zero-setup insights for teams without heavy DevOps infrastructure (like Prometheus/Grafana clusters).

### EntityDataSet & Active Architecture — The RAD Modernization Revolution

This represents an exciting paradigm shift for legacy Delphi modernization. The `EntityDataSet` acts as the bridge connecting clean architecture domains to visual components (like DBGrids, DBCtrl grids, and FastReport) with zero architectural compromise.

In design-time, Dext parses raw `.pas` domain units to generate fields dynamically and runs real SQL preview queries so you can work visually. But at runtime, all database connections vanish; the dataset consumes pure POCO in-memory entity lists (`TList<T>`).

This powers **Active Architecture** (a pattern moving beyond traditional "Clean RAD"). By combining visual datasets with an elegant, non-redundant MVVM pattern (where the ViewModel manages UI states and async operations while components bind directly to rich domain entities via `TEntityDataSet`), developers can finally modernize massive legacy ERPs. You can eliminate tight database coupling and visual event handlers while keeping the high-productivity design form workflow that Delphi is famous for.

### native MCP Server — AI-Native Framework

Dext includes a native, zero-dependency implementation of the **Model Context Protocol** (MCP 2025-03-26), enabling Dext applications to expose tools, resources, and prompts directly to AI agents (Claude Desktop, Cursor, Antigravity).

```pascal
type
  [MCPTool('search_products')]
  [MCPParam('query', 'Search term')]
  TSearchProductsTool = class
    function Execute(const AQuery: string): TList<TProduct>;
  end;
```

### FireDAC ConnectionDef Support

Dext natively supports direct integration with FireDAC's global connection definition manager (`UseConnectionDef`). Rather than just another way to pass connection strings, it automatically analyzes active local/server definition profiles to resolve the correct dialect, database drivers, and physical pooling setups at runtime, enabling seamless, zero-config context switching between development and production.

---

## Part 4: Honest Gaps

Transparency matters. Here is where .NET has a more complete implementation:

- **OpenTelemetry exporter compatibility**: Dext has `TDiagnosticSource` and CorrelationId tracking, but does not yet export to OTLP format for Grafana Cloud or Datadog. This is on the Wave 3 roadmap.
- **HybridCache (L1 + L2 unified)**: .NET 9 introduced a unified cache that merges in-memory and distributed Redis caches. Dext's native, high-performance Redis client is currently in active development (~80% complete) on the roadmap.
- **SignalR / Websockets / Hubs**: Dext currently provides basic event broadcasting via SSE. Full WebSocket-based SignalR equivalent messaging is planned on the roadmap.
- **gRPC & Protobuf Support**: Native high-speed binary communication utilizing IOCP/EPOLL engines and transparent Code-First interface mapping is mapped as a Wave 3 roadmap item.
- **Named Query Filters**: EF Core 10 allows multiple named per-entity filters. Dext has a single global filter per entity. Roadmap item.

---

## Part 5: Platform Differences (Not Gaps)

Some .NET features simply don't apply to Delphi by design. Blazor runs in a browser runtime — Delphi compiles to native AOT binaries by default (no JIT, no cold start). EF Compiled Models exist to reduce JIT warm-up time — in Delphi, all model metadata is compiled ahead-of-time. Source Generators are a C# language feature — Dext achieves the same validation results via RTTI attributes at runtime.

For the full context breakdown, see **[Block D of the Feature Comparison →](./Feature_Comparison_Dext_vs_DotNet.md#block-d--context-differences-not-applicable-to-delphi)**.

---

## The Numbers

- **Features at parity with .NET**: 60+
- **Features Dext has that .NET doesn't**: 17 (including Database as API, Smart Properties AST, EntityDataSet, native MCP Server, built-in Telemetry Dashboard [WIP])
- **3rd-party packages replaced by built-in features**: AutoMapper, MediatR, FluentAssertions, Moq, Verify, Ardalis.Specification, xUnit, NUnit (test attributes)
- **Production scale**: ~800,000 requests/day on AWS and Azure
- **Codebase size**: 200,000+ lines of pure Pascal code with a 5-database CI test matrix

---

## Conclusion: Global Architecture for Modern Delphi

This comparison is a testament to the power of cross-pollinated technical paradigms. 

For years, the .NET ecosystem has served as an excellent benchmark for backend productivity, showing how unified structures enable teams to deliver robust software quickly. Historically, building web services in Delphi meant assembling fragmented, disconnected libraries, writing verbose manual mappers, and managing ad-hoc wrappers.

Dext was built to change that landscape. By drawing inspiration from the elegant, proven structures of ASP.NET Core and Entity Framework Core, Dext delivers a unified, highly productive, and elegant web experience directly to Delphi—without the memory overhead or cold starts of a managed JIT runtime. 

Furthermore, Dext's commitment to importing the best features of other languages—such as Go's concurrency models, Dart/Flutter's visual-reactive mechanics, and Spring Boot's IoC paradigms—ensures that the framework remains on the cutting edge of global software architecture. Dext is an industrial-grade engineering ecosystem engineered to continuously evolve alongside the real-world production needs of the modern Delphi community.

---

*For the full technical feature table: see [`Feature_Comparison_Dext_vs_DotNet.md`](./Feature_Comparison_Dext_vs_DotNet.md)*  
*For a detailed ORM breakdown: see [`Dext_ORM_Capabilities.md`](./Dext_ORM_Capabilities.md)*

*Dext Framework | May 2026*

