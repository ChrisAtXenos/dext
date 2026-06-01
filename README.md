[🇧🇷 Português](README.pt-br.md)

# Dext Framework
**Modern Full-Stack Development for Delphi**

<p align="center">
  <img src="Docs/Images/dext-mascot.png" alt="Dext Framework Mascot">
</p>

---

> [!IMPORTANT]
> Dext Framework is currently in **Version 1 Release Candidate (RC2)**.

**Dext Framework** is a native and integrated ecosystem for Delphi development.

It brings together Dependency Injection, ORM, Web Pipeline, and Testing into a single, high-performance architecture. Designed to eliminate the need for connecting isolated libraries and to drastically reduce boilerplate code, Dext handles the infrastructure complexity so your team can focus strictly on business logic.

## Delphi Modernization & .NET Parity

Dext was built to bridge the perception and architectural gap between Delphi and modern platforms like .NET Core. If your team is considering migrating a legacy VCL/FMX system to another modern stack due to the lack of modern enterprise patterns, Dext offers a complete native alternative without the cost, risk, and time of rewriting your entire codebase.

We provide full functional parity with modern ASP.NET Core & Entity Framework Core patterns, while leveraging native compilation (no JIT, zero cold starts, and minimal memory footprint).

Explore our detailed comparison and capability references:
*   [**Dext vs .NET Architectural Narrative**](Docs/Comparison/Dext_vs_DotNet_Narrative.md) — How Dext bridges the backend gap with native compilation.
*   [**Feature-by-Feature Parity Matrix**](Docs/Comparison/Feature_Comparison_Dext_vs_DotNet.md) — Over 60+ features compared directly between ASP.NET/EF Core and Dext.
*   [**Complete ORM Capabilities Reference**](Docs/Comparison/Dext_ORM_Capabilities.md) — DbContext, Change Tracking, JSON columns, and Lazy/Eager strategies.
*   [**Enterprise Licensing Guide**](Docs/Comparison/Open_Source_Licensing_Enterprise.md) — Why Dext is completely free, secure, and ready for commercial use under Apache 2.0.

## Where to Use?

Dext was specifically designed to solve the real-world pain points faced by Delphi developers:

* **Web Applications:** Develop complete web applications with Server-Side rendering using WebStencils or native templates integrated into the pipeline.
* **High-Performance APIs:** Build robust RESTful backends using *Minimal APIs*, *Controllers*, or generating direct endpoints with the `[DataApi]` attribute.
* **Concurrency and Asynchrony:** Use *Dext Threading* (Async Task, Cancellation Token, Async Rest Client) to create background routines and non-blocking workflows, replacing the complex manual usage of the `TThread` class.
* **Mobile Backend (iOS/Android):** Provide the integration, connectivity, and security infrastructure needed to support mobile applications efficiently.
* **Legacy Modernization:** Gradually integrate with old 3-tier systems (like DataSnap), ISAPI/Apache middlewares, or Desktop monoliths (VCL) without having to rewrite your 20-year-old ERP. Dext acts as a modern foundation within existing systems.
* **Background Services and Microservices:** Robust data extraction, high-performance scheduled tasks, and connectivity between applications.

---

## Quick Start

See how Dext's structure simplifies complex flows into clean, typed, and object-oriented code. Exploring the framework's pillars:

### Minimal API

Creating a high-performance endpoint integrated with Dependency Injection requires minimal effort:

```pascal
program MyAPI;

uses Dext.Web;

begin
  var App := WebApplication;
  
  // Simple endpoint
  App.MapGet('/hello', function: string
  begin
    Result := 'Hello from Dext! Modern full-stack for Delphi.';
  end);

  // Endpoint with native Automatic Dependency Injection (DI) and Model Binding
  App.MapPost<TUserDto, IEmailService, IResult>('/register',
    function(Dto: TUserDto; EmailService: IEmailService): IResult
    begin
      EmailService.SendWelcome(Dto.Email);
      Result := Results.Created('/login', 'User successfully registered');
    end);

  App.Run(8080);
end.
```

### Simple Entity (COC, DataApi, and Smart Properties)

Automatic mapping via *Convention over Configuration* and structured properties for advanced relational mapping:

```pascal
[Table]
[DataApi('/api/orders')] // Automatically exposed as a REST API (Zero-Code API)!
TOrder = class
private
  FId: IntType;
  FStatus: Prop<TOrderStatus>;
  FNotes: StringType;
  FTotal: Nullable<CurrencyType>;
  FItems: Lazy<IList<TOrderItem>>;
public
  [PK, AutoInc]
  property Id: IntType read FId write FId;
  property Status: Prop<TOrderStatus> read FStatus write FStatus;
  property Notes: StringType read FNotes write FNotes;
  
  // Smart Types to natively handle nulls, validation, and Lazy Loading
  property Total: Nullable<CurrencyType> read FTotal write FTotal;
  property Items: Lazy<IList<TOrderItem>> read FItems write FItems;
end;
```

### ORM and Strongly Typed Queries (Type-Safe)

No more magic strings or broken queries at runtime. Dext generates the Abstract Syntax Tree (AST) of your code:

```pascal
// Complex query with Joins and Filters interpreted as clean code
var O := Prototype.Entity<TOrder>;

var Orders := DbContext.Orders
  .Where((O.Status = TOrderStatus.Paid) and (O.Total > 1000))
  .Include('Customer') // Eager Loading
  .Include('Items')
  .OrderBy(O.Date.Desc)
  .Take(50)
  .ToList;

// High-performance Bulk Update directly in the DBMS without loading records into memory
DbContext.Products
  .Where(Prototype.Entity<TProduct>.Category = 'Outdated')
  .Update
  .Execute;
```

### Async Processing (Fluent Tasks)

The complexity of `TThread` transformed into modern asynchronous chained pipelines. The `Fluent Async Tasks` abstraction delivers superpowers over the `PPL` (*Parallel Programming Library*) and `Future<T>`, allowing pipelines based on the *Thread Pool*:

```pascal
var CTS := TCancellationTokenSource.Create;

TAsyncTask.Run<TStream>(
  function: TStream
  begin
    // Requests a free Task from the Thread Pool for network download
    Result := AsyncClient.DownloadStream('https://api.company.com/data', CTS.Token);
  end)
  .Then<TReport>(
    function(Stream: TStream): TReport
    begin
      // Chains a new processing Task as soon as the previous one finishes
      Result := JsonSerializer.Deserialize<TReport>(Stream);
      Stream.Free;
    end)
  .OnComplete(
    procedure(Report: TReport)
    begin
      // Automatically and safely synchronizes the return with the Original Thread (UI)
      ShowReport(Report);
    end)
  .OnException(
    procedure(Ex: Exception)
    begin
      ShowError('Process failed: ' + Ex.Message);
    end)
  .Start;
```

### Configuration, Options & DI

Structured environment for registering services and external configurations using `JSON`, `YAML`, or Environment Variables:

```pascal
  var Builder := WebApplication.CreateBuilder;
  
  // Load hierarchical configuration sources
  Builder.Configuration
    .AddJsonFile('appsettings.json')
    .AddYamlFile('config.yaml')
    .AddEnvironmentVariables;
  
  Builder.Services
    // Natively binds configuration to a strongly-typed class
    .Configure<TDatabaseSettings>(Builder.Configuration.GetSection('Database'))
    
    // Complete Dependency Injection for repositories and services
    .AddSingleton<IEmailService, TSmtpEmailService>
    .AddScoped<IOrderRepository, TDbOrderRepository>;
    
  var App := Builder.Build;
```

### Full VCL Compatibility (TEntityDataSet)

The `TEntityDataSet` converts the ORM's object orientation (POCOs) into *DataSet-compatible* structures consumable by your VCL grids, data-aware components, and Design Time reports, without losing performance!

> Design-Time Support: Native *TFields* creation from entity code and record visualization directly in the IDE.

---

## Core Features

<p align="center">
  <img src="Docs/Images/dext_ecosystem.png" alt="Dext Ecosystem Architecture" width="80%">
</p>

Dext is composed of flexible and minimalist modules. You retain full control over the architecture and include only the vital components for your solution:

* **Core Technologies:** Enterprise-grade Dependency Injection (Singleton, Transient, Scoped), optimized Reflection cache, advanced event support, and IOptions.
* **Clean Native Collections:** Elimination of memory leaks using interfaces (`IList`, `IDictionary`). Dext solves the classic *Generic Bloat* with Binary Code Folding, significantly reducing huge binaries.
* **Data Access (ORM):** Robust management via *Unit of Work*, automatic transaction control (DAO support), and multi-database support.
* **Web Frameworks:** Embedded HTTP server, *Minimal APIs*, *Controllers*, *DataAPI* REST generator, modular middlewares, *WebSockets* (Hubs), native CORS, *Native HTMX Support*, and extremely fast rendering.
* **AI & Agentic Capabilities:** Built-in **MCP (Model Context Protocol)** Server for seamless integration with AI Assistants (like Claude), exposing your Delphi business logic as AI tools via HTTP Streamable Sessions.
* **Testing & Quality:** Coupled TestContext framework, automated *Mock Objects* (`TAutoMocker`), test coverage, and reporting.

**[See the full features list and Dext modules](Docs/Features_Implemented_Index.md)**

---

## Installation

Dext distribution prioritizes minimalism, without opaque installers that inject clutter into your system directory:

1. Download the source code: `git clone https://github.com/cesarliws/dext.git`
2. Add `Library Paths` in Delphi referencing Dext's main modules.
3. Compile the project through the `Sources\DextFramework.groupproj` group.

**[Read Detailed Setup and Installation Instructions](Docs/Book/01-getting-started/installation.md)**

### Requirements and Compatibility
* **Delphi:** 10.3 Rio or higher (Full support for 10.4, 11, and 12 Athens).
* **Legacy Versions:** Can be compiled on 10.1 Berlin with limitations.
* **Dependencies:** No mandatory external dependencies (uses native components).

**[Detailed Compatibility Matrix](Docs/Delphi_Compatibility_Matrix.md)**

---

## Design and Philosophy: Born for Performance

Delphi has historically been chosen for domains that did not tolerate overheads; however, recent frameworks have adopted unrestrained allocation patterns based on developer convenience. **Dext returns the performance while maintaining modern ease of use:**

<p align="center">
  <img src="Docs/Images/dext_performance_graph.png" alt="Dext Performance Graph" width="80%">
</p>

1. **Zero-Allocation Pipeline:** When the server exposes JSON or data, common components instantiate and process gigabytes of temporary `string`s, causing deadly spikes in the Memory Manager and forced pauses. Dext bypasses classic conversion through *Direct-to-JSON streaming*, reading entire blocks via immutable memory structures (`TSpan`).
2. **Hardware Affinity (SIMD):** The underlying layers benefit from parallel computing using SIMD (Single Instruction, Multiple Data) in parsing to ensure response in very few CPU ticks.

---

## Open Source and License

**Dext** is developed and maintained publicly and provided under the **Apache License 2.0**.
It is fully and unconditionally free (for open-source scenarios or strict enterprise/commercial development). Create billion-dollar software, distribute, or encapsulate at will. No catches.

---

## Join the Community

Dext is driven by the community. Whether you are an enthusiastic user or an infrastructure-focused developer, there are many ways to help:

* **Spread the word:** If Dext is useful to you, please consider **leaving a star** on the repository. This helps the project gain visibility and attract more contributors.
* **Share your Success:** Built something amazing with Dext? We would love to hear about your use case. Share your story in the [Discussions](https://github.com/cesarliws/dext/discussions).
* **For Users:** Start using the framework in your projects and give us real feedback on your experience.
* **For Contributors:** Report instabilities (*issues*), suggest improvements, or send a pull request.
  * Follow the [Contribution Instructions](CONTRIBUTING.md)
  * Want to submit new Features? Follow the [Features and Improvements Workflow](Docs/CONTRIBUTING_IMPROVEMENTS.md)

Check out our [Roadmap](Docs/ROADMAP.md) metrics and steps, and see our **[Code of Conduct](./CODE_OF_CONDUCT.md)** to keep this hub welcoming.

<br>
<p align="center">
  <i>Stop rebuilding foundations and spend energy on your customers' problems. Dext takes care of the rest.</i><br>
  <b>Built with pride for the entire Delphi Ecosystem.</b>
</p>
