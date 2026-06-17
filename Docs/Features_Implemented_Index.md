# 📑 Dext Framework — Exhaustive Technical Features Index

Exhaustive master index of all implemented features in the Dext Framework. Each item directly references the implementation unit in `Sources/`.

> [!IMPORTANT]
> Generated via a technical audit ("X-Ray") directly from the source code. No features have been omitted or simplified.

---

## 📋 1. Core Framework & Language Foundation

Dext was designed to leverage modern Object Pascal features while maintaining a balance between innovation and compatibility.

### 1.0 Delphi Compatibility
- **Architectural Minimum**: Delphi 2010 (Extended RTTI, Generics, and Attributes).
- **Validated Version**: 10.3+ Rio (extensive use of `var inline` and Managed Records optimizations).
- **10.1 - 10.2 Support**: In community testing phase; requires minor refactoring of inline variables.
- **Web Stencils**: Requires Delphi 12.2+.

## 🧩 1. Dext Core Foundation (`Sources\Core` + `Sources\Core\Base`)

### 1.1 Reflection Engine (`Dext.Core.Reflection`)
- **TReflection** — High-performance static facade for Delphi's RTTI system. Maintains a globally shared `TRttiContext`.
- **Metadata Cache** (`TTypeMetadata`) — Global cache of type metadata (properties, fields, attributes) with thread-safe initialization via `TMREWSync` (Multiple-Read Exclusive-Write). Hot-paths are lock-free.
- **Smart Properties** (`Prop<T>`, `Nullable<T>`, `Lazy<T>`) — Automatic detection of generic wrappers via `PTypeInfo.Name` analysis. The metadata cache stores `IsSmartProp`, `IsNullable`, `IsLazy`, `InnerType`, and direct pointer to the `FValue` field.
- **Property Path Resolution** — Recursive resolution of nested paths (e.g., `User.Address.Street`) via `TReflection.GetPropertyValue` with `TRttiProperty` caching per segment.
- **Custom Attribute Scanning** — `GetAttributes<T>` and `HasAttribute<T>` with scanning on fields, properties, and methods. Used by DI, Validation, JSON, and ORM.
- **Property Handlers** — `TPropertyHandler` for optimized property access with getter/setter caching.

### 1.2 Dependency Injection (`Dext.DI.Core`, `Dext.DI.Interfaces`, `Dext.DI.Attributes`)
- **TDextServices** — Fluent facade for service registration. Methods: `AddSingleton<T>`, `AddTransient<T>`, `AddScoped<T>`, `AddSingletonInstance<T>`, `AddSingletonFactory<T>`.
- **Interface/Implementation Mapping** — Complete decoupling between definitions and concrete logic.
- **TServiceCollection** — Internal repository of `TServiceDescriptor` with reverse search (LIFO) to allow registration overrides.
- **TDextServiceProvider** — IoC container with hybrid storage: `FSingletonInstances` (ARC/Interfaces) + `FSingletonObjects` (Non-ARC/Manual Classes) + `FScopedInstances`/`FScopedObjects` for scoping.
- **Lifecycles** — `Singleton` (global single instance), `Transient` (new instance per resolution), `Scoped` (single instance per DI scope via `CreateScope`).
- **Scope Isolation** — `IServiceScope` with `TDextServiceScope` creating an isolated child provider. Scope destruction releases all scoped objects.
- **Auto-Collections** — Automatic resolution of `IList<T>`, `IEnumerable<T>`, `IDictionary<K,V>` via `TActivator.IsListType`/`IsDictionaryType`.
- **DI Attributes** — `[Inject]` for property/field injection, `[ServiceConstructor]` for explicit constructor selection, overriding the Greedy strategy.

### 1.3 Object Activator (`Dext.Core.Activator`)
- **TActivator** — Central RTTI-based dynamic instantiation engine with 4 `CreateInstance` overloads:
  1. **Manual** — Explicit positional arguments.
  2. **Pure DI (Greedy Strategy)** — Selects the constructor with the MOST resolvable parameters from the container. Prioritizes the most derived class in case of a tie.
  3. **Hybrid** — Initial positional arguments + DI resolution for the rest.
  4. **PTypeInfo-based** — Instantiation by `PTypeInfo` (supports classes and interfaces, including auto-instantiation of collections).
- **[ServiceConstructor] Attribute** — First-pass priority over the Greedy strategy.
- **Constructor Cache** — Thread-safe cache (`TMREWSync`) of `TConstructorEntry` (method + `PTypeInfo` array of parameters) to avoid redundant RTTI scanning.
- **Field/Property Injection** — `InjectFields` processes `[Inject]` on fields and properties after construction, supporting custom `TargetTypeInfo`.
- **Default Implementation Registry** — `RegisterDefault(TBase, TImpl)` and `RegisterDefault<TService, TImpl>` for base→implementation mapping (e.g., `TStrings→TStringList`).

### 1.4 JSON Engine (`Dext.Json`, `Dext.Json.Types`)
- **TDextJson** — Static facade for serialization/deserialization with `Serialize<T>` and `Deserialize<T>`.
- **Driver Architecture** — Pluggable `IDextJsonProvider` (`DextJsonDataObjects` default, `System.JSON` alternative). Drivers implement `CreateObject`, `CreateArray`, `Parse`.
- **TJsonSettings (Fluent Record API)** — Immutable configuration via chaining: `.CamelCase`, `.SnakeCase`, `.PascalCase`, `.EnumAsString`, `.EnumAsNumber`, `.IgnoreNullValues`, `.CaseInsensitive`, `.ISODateFormat`, `.UnixTimestamp`, `.CustomDateFormat(fmt)`, `.ServiceProvider(p)`.
- **Automatic Casing** (`TCaseStyle`) — 5 modes: `CaseInherit`, `Unchanged`, `CamelCase`, `PascalCase`, `SnakeCase`. Automatically applied during serialization.
- **Enum Serialization** (`TEnumStyle`) — `AsNumber` (ordinal) or `AsString` (RTTI enum name).
- **Date Formats** (`TDateFormat`) — `ISO8601`, `UnixTimestamp`, `CustomFormat`. Default: `yyyy-mm-dd"T"hh:nn:ss.zzz`.
- **DOM Abstraction** — `IDextJsonNode`, `IDextJsonObject`, `IDextJsonArray` with strong typing (6 node types: Null, String, Number, Boolean, Object, Array).
- **TJsonBuilder** — Fluent builder for programmatic JSON construction without strings.
- **Attributes** — `[JsonName]` (rename field), `[JsonIgnore]` (exclude field), `[JsonCaseStyle]` (class-level override).
- **Architectural Profiles**:
  - **Dext DOM (IDextJsonNode)** — Optimized for 99% of use cases (REST APIs, Configs). High-speed random access and object manipulation via in-memory tree (DataObjects engine).
  - **Dext UTF-8 (Low-Level Streaming)** — Surgical tool for Big Data. Zero-allocation sequential processing of massive volumes (GBs) with constant memory footprint.
- **TUtf8JsonSerializer** (`Dext.Json.Utf8.Serializer`) — Zero-allocation record serializer. Operates directly on `TByteSpan` (raw UTF-8) without intermediate `string` conversion. `TJsonRecordInfo` caching per `PTypeInfo` to eliminate RTTI overhead in hot-paths. `ToUtf8JSON` in the `DextJsonDataObjects` driver for native UTF-8 output.

### 1.4b AutoMapper Engine (`Dext.Mapper`)
- **TMapper** — Static facade and central registry for object-to-object mapping using Delphi RTTI.
- **Fluent Mapping Configuration** — `TTypeMapConfig<TSource, TDest>` record supporting custom mappings using fluent notation:
  - `ForMember(DestName, MapFunc)` — Define custom mapping functions mapping source to target values.
  - `Ignore(DestName)` — Prevent copying specific properties.
- **Instance Mapping** — `TMapper.Map<TSource, TDest>(Source)` returns a newly instantiated mapped destination class.
- **In-Place Mapping** — `TMapper.Map<TSource, TDest>(Source, Dest)` maps source properties onto an existing destination object reference.
- **Collection Mapping** — `TMapper.MapList<TSource, TDest>(SourceList)` maps lists and generic collections automatically.
- **Record Mapping** — Maps matching fields and properties between classes and records.
- **Default Value Optimization** — Support for mapping only non-default values using the `AOnlyNonDefault` parameter to avoid overwriting initialized destination values.

### 1.5 Configuration System (`Dext.Configuration.Core`)
- **TDextConfiguration (Fluent Builder)** — `.AddJsonFile(path)`, `.AddYamlFile(path)`, `.AddEnvironmentVariables(prefix)`, `.AddCommandLine`, `.AddInMemoryCollection`.
- **TConfigurationRoot** — Multi-provider aggregator with LIFO precedence (last registered wins). Implements `IConfiguration`.
- **Hierarchical Keys** — Access via `:` separator (e.g., `Database:ConnectionString`). `GetSection(key)` returns sub-tree.
- **Options Pattern** — `IOptions<T>`, `IOptionsSnapshot<T>`, `IOptionsMonitor<T>` for typed binding of configuration sections to records/classes.
- **Section Validators** — `AddSectionValidator(section, validator)` for startup configuration validation.
- **Change Tracking** — `IChangeToken` with `OnReload` callback for hot-reload configuration.

### 1.6 Type System (`Dext.Types.*`)
- **TUUID** (`Dext.Types.UUID`) — RFC 9562 compliant type with Big-Endian storage (Network Byte Order). `NewV4` (random), `NewV7` (time-ordered, 48-bit Unix timestamp ms + random). Implicit bidirectional conversion with `TGUID` (automatic endianness swap) and `string`. Operators `=` and `<>` via `CompareMem`. Compatible with PostgreSQL `uuid` and Web APIs.
- **Nullable\<T\>** (`Dext.Types.Nullable`) — Generic wrapper for nullable value types. `HasValue`, `Value`, `GetValueOrDefault`, `Clear`. Implicit operators: `T→Nullable<T>`, `Nullable<T>→T`, `Variant→Nullable<T>`, `Nullable<T>→Variant`. Comparison via `TEqualityComparer<T>.Default`. `TNullableHelper` for low-level access via raw `PTypeInfo` without generics.
- **Lazy\<T\>** (`Dext.Types.Lazy`) — Thread-safe lazy initialization via `TCriticalSection` (double-checked locking). `ILazy` and `ILazy<T>` interfaces. `TLazy<T>` (factory-based) and `TValueLazy<T>` (pre-computed). Implicit operators: `T→Lazy<T>`, `Lazy<T>→T`, `TFunc<T>→Lazy<T>`. Ownership management: `AOwnsValue` parameter controls if the value is destroyed with the lazy wrapper.

### 1.6b Smart Types & Expression Trees (`Dext.Core.SmartTypes`, `Dext.Specifications.*`)
- **TEntityType\<T\>** (`Dext.Entity.TypeSystem`) — Separate definition classes for queries. Allows separating data from metadata by working with pure POCOs, generating the same expression trees without embedding `Prop<T>` in the entity itself. Ideal for legacy systems or strict separation.
- **Prop\<T\>** (`Dext.Core.SmartTypes`) — Generic record operating in **dual mode**: (1) **Runtime Mode** — stores value `T` normally, (2) **Query Mode** — generates expression trees (`IExpression` / AST) automatically via operator overloading. The central pillar of Dext's **LINQ-like fluent DSL**.
- **BooleanExpression** — Hybrid record that can contain a literal `Boolean` OR an `IExpression` node (AST). Operators `and`, `or`, `not`, `xor` automatically generate `TLogicalExpression` nodes in query mode.
- **Type Aliases** — `StringType`, `IntType`, `Int64Type`, `BoolType`, `FloatType`, `CurrencyType`, `DateTimeType`, `DateType`, `TimeType` — semantic aliases for `Prop<T>` that make entities self-documenting.
- **Full Operator Overloading** — `=`, `<>`, `>`, `>=`, `<`, `<=`, `+`, `-`, `*`, `/`, unary negation — all generate `TBinaryExpression` with `boEqual`, `boGreaterThan`, etc., in query mode.
- **String Methods** — `Like`, `StartsWith`, `EndsWith`, `Contains` generate `TFunctionExpression` with the corresponding operation.
- **Collection Methods** — `In(values)`, `NotIn(values)`, `Between(lower, upper)`, `IsNull`, `IsNotNull`.
- **OrderBy** — `Prop.Asc` / `Prop.Desc` return `IOrderBy` for sorting composition.
- **IPropInfo** — Ported metadata carrying the physical column name, injected by `TPrototype`.
- **TQueryPredicate\<T\>** — `function(Arg: T): BooleanExpression` delegate used by the ORM as a query predicate.
- **Expression Tree Nodes** (`Dext.Specifications.Types`) — `TPropertyExpression`, `TLiteralExpression`, `TConstantExpression`, `TBinaryExpression`, `TLogicalExpression`, `TUnaryExpression`, `TFunctionExpression`, `TFluentExpression`.
- **Nullable\<T\> Interop** — Implicit bidirectional conversion between `Prop<T>` and `Nullable<T>`.
- **Variant Interop** — Implicit bidirectional conversion between `Prop<T>` and `Variant`.

### 1.7 Value Converter Engine (`Dext.Core.ValueConverters`)
- **TValueConverterRegistry** — Global converter registry with 3-level lookup: (1) Exact Match by `PTypeInfo` pair, (2) Kind Match by `TTypeKind` pair, (3) Fallback for `tkVariant` source.
- **TValueConverter** — Execution engine orchestrating conversions, with automatic handling of Smart Types (`Prop<T>`) and `Nullable<T>` (detected via `TReflection.GetMetadata`).
- **20+ Built-in Converters** — `Variant→Integer/String/Boolean/Float/DateTime/Date/Time/Enum/GUID/Class/TBytes/TUUID`, `Integer→Enum/String`, `String→GUID/TBytes/TUUID/Integer/Float/DateTime/Boolean`, `Float→String`, `Boolean→String`, `Class→Class`.
- **ConvertAndSet / ConvertAndSetField** — Conversion + assignment via RTTI in a single call (used by ORM and Model Binding).

### 1.8 Memory & Span (`Dext.Core.Span`, `Dext.Core.Memory`)
- **TSpan\<T\>** — Zero-allocation reference to a contiguous memory region. `Slice`, `ToArray`, `Clear`, `GetEnumerator` (for-in). Bounds checking on all accesses.
- **TVector\<T\>** — Efficient, growable stack-allocated vectors for high-speed buffer management.
- **TReadOnlySpan\<T\>** — Immutable version of `TSpan<T>`. Implicit operator `TSpan<T>→TReadOnlySpan<T>` and `TArray<T>→TReadOnlySpan<T>`.
- **TByteSpan** — Specialized span for bytes. `Equals` via `TDextSimd.EqualsBytes` (SIMD-accelerated). `EqualsString` compares with UTF-8 without allocation. `IndexOf`, `ToString` (UTF-8→string), `ToBytes`. Optimized for JSON/REST parsers and network protocols.
- **ILifetime\<T\>** (`Dext.Core.Memory`) — ARC wrapper for Non-ARC object lifecycle management. `TLifetime<T>` encapsulates an object and automatically releases it when the interface goes out of scope.
- **IDeferred / TDeferredAction** (`Dext.Core.Memory`) — Defer pattern (Go-inspired). Action executed automatically in the destructor when the interface goes out of scope. Useful for temporary resource cleanup.

### 1.9 Threading & Async (`Dext.Threading.*`)
- **TAsyncTask** — Fluent Async/Await implementation for asynchronous operations.
- **Work-Stealing Scheduler** — Efficient task distribution across CPU cores for maximum parallel performance.
- **ICancellationToken** — Cooperative cancellation with `WaitForCancellation(timeout)` and `IsCancellationRequested`. Integrated with Event Bus Lifecycle and Background Services.

### 1.10 Logging Pipeline (`Dext.Logging`, `Dext.Logging.Sinks.APM`)
- **ILoggerFactory** — Factory for loggers with multiple provider registration. `CreateLogger(categoryName)` returns a composite `ILogger`.
- **ILogger** — Interface with methods per level: `Trace`, `Debug`, `Information`, `Warning`, `Error`, `Critical`. Structured template support with placeholders.
- **Aggregate Logger** — Each `ILogger` created by the factory aggregates all registered providers, dispatching every log entry to all simultaneously.
- **TBatchingTelemetrySink** — Base abstract asynchronous batching sink with queue buffering, thread-safe synchronization, and background thread execution.
- **TSeqLogSink** — Compact Log Event Format (CLEF) structured logger sink sending batches to Seq servers over HTTP.
- **TOTLPTelemetrySink** — OpenTelemetry (OTLP/HTTP JSON) telemetry sink for exporting Logs to OTel collectors (SigNoz, Datadog).
- **TTelemetrySinkRegistry** — Pluggable sink creator registry decoupling circular dependencies between package layers.
- **Fluent Logging Builders** — Startup extensions supporting `AddSeq()` and `AddOpenTelemetry()` with custom batching and service settings.

### 1.11 Event Bus & Messaging (`Dext.Events`, `Dext.Events.Interfaces`)
- **Dext.Events (In-Process)** — **MediatR**-inspired Publish/Subscribe system. Enables total decoupling between event producers and handlers.
- **IEventPublisher / IEventHandler<T>** — Asynchronous event dispatch via DI. Supports multiple handlers for the same event or exclusive handlers.
- **Scoping Support** — Handlers respect DI lifecycle (Scoped handlers receive the same context as the original request).

### 1.12 Observability & Telemetry (`Dext.Core.Diagnostics`)
- **TDiagnosticSource** — Telemetry infrastructure based on observers. Allows intercepting HTTP request lifecycle and SQL execution without coupling monitoring code to business logic.
- **SQL Logging Hooks** — Automatic interception of SQL commands, parameters, and execution time, integrated into the framework's logger.
- **Activity Tracking** — Activity tracking support (CorrelationId) for debugging complex and distributed flows.

### 1.13 Collections & Concurrency (`Dext.Collections.*`)
- **Binary Code Folding** (`TRawList`) — Invisible base engine consolidating hundreds of generic specializations into a single implementation manipulating raw memory slices, reducing compile times by up to 60% and eliminating *Code Bloat* from RTL Generics.
- **CPU-Friendly Dictionaries** (`TRawDictionary`) — Uses Open Addressing with Linear Probing in contiguous memory (Hash Metadata), eliminating cache misses caused by traditional linked-lists. Up to 6.6x faster lookups than RTL.
- **SIMD Acceleration** (`Dext.Collections.Simd`) — Vectorized scans and comparisons (AVX2/SSE2) processing 16 to 32 bytes per clock cycle. Extreme performance (up to 6.8x faster) in native lists.
- **Zero-Allocation Vectors** (`Dext.Collections.Vector`) — Native `Span<T>` integration for slicing and massive buffer processing without allocation or copying in the Memory Manager.
- **TFrozenDictionary\<K,V\> / TFrozenSet\<T\>** (`Dext.Collections.Frozen`) — Immutable collections ("Write Once, Freeze") designed for aggressive concurrency without contention (*Lock-Free Read*). Bypassing `TCriticalSection` instances radically optimizes scaling.
- **TChannel\<T\>** (`Dext.Collections.Channel`) — Go-inspired async communication channels (*Lock-Free*), with native **Backpressure** (Bounded Channels) to avoid CPU/memory starvation.

### 1.14 I/O Writers (`Dext.Core.Writers`)
- **IDextWriter** — Thread-safe abstraction for framework output. Implementations: `TConsoleWriter` (stdout), `TWindowsDebugWriter` (OutputDebugString with buffering), `TStringsWriter` (TStringList/TMemo), `TNullWriter` (silent).
- **SafeWrite / SafeWriteLn** (`Dext.Utils`) — Global functions routing output via the active `IDextWriter`. Automatic console detection. Native Unicode writing via `WriteConsoleW` (Windows) with UTF-8 fallback for pipes.
- **SafeAttachConsole** — Attach to parent process console (CMD/PowerShell) or `AllocConsole` for F5-executed GUI applications.

### 1.15 Text Escaping (`Dext.Text.Escaping`)
- **TDextEscaping** — Centralized text escaping utilities: `Html`, `Xml`, `Json` (manual character-by-character with `\uXXXX` support), `Url`. Used by Reporters, Serializers, and RestClient.

### 1.16 Date Utilities (`Dext.Core.DateUtils`)
- **TryParseISODateTime** — Robust ISO 8601 parser (`YYYY-MM-DDTHH:NN:SS.ZZZ`) with support for variations (separator `T` or space, optional milliseconds).
- **TryParseCommonDate** — Multi-format parser: ISO 8601 → `dd/mm/yyyy` → `mm/dd/yyyy` → `yyyy/mm/dd` with automatic format detection.

### 1.17 Resilience Pipeline (`Dext.Resilience`)
- **IResiliencePipeline / TResiliencePipeline** — Fluent record wrapper and interface exposing Polly-style policies. Synchronous and asynchronous generic/non-generic execution support (`Execute<T>` and `Execute`).
- **Retry Policy** (`TRetryPolicy`) — Handles transient failures with customizable retry count and backoff strategies (linear, exponential backoff with jitter).
- **Circuit Breaker Policy** (`TCircuitBreakerPolicy`) — Implements `Closed`, `Open`, and `Half-Open` states, failing fast and throwing `ECircuitBrokenException` once failure thresholds are exceeded.
- **Fallback Policy** (`TFallbackPolicy`) — Intercepts exceptions and returns fallback alternative values or executes fallback actions.
- **Timeout Policy** (`TTimeoutPolicy`) — Throws `ETimeoutException` when operations exceed set duration limits using cooperative task cancellation and asynchronous futures.
- **RestClient Integration** — `TRestClient` natively integrates with the resilience engine, enabling backwards-compatible `.Retry()` and `.Timeout()` methods, plus custom pipeline configuration.

### 1.18 Persistent Background Jobs (`Dext.BackgroundJobs.*`)
- **`IJobStorage`** — Decoupled storage abstraction supporting multiple providers.
- **`IJobClient` / `TDextJobs`** — Thread-safe enqueueing client and static utility facade (`TDextJobs.Enqueue<T>`, `TDextJobs.Schedule<T>`).
- **`TInMemoryJobStorage`** — Memory-only job storage provider designed for rapid local testing.
- **`TSqliteJobStorage`** — SQLite database job persistence provider using FireDAC, supporting automated schema creation and transactional safety.
- **`TJobServer` / `TBackgroundJobsService`** — Robust multi-threaded background worker engine running as an `IHostedService` (`TBackgroundService`), polling, locking, executing, and monitoring jobs.
- **`TJobSerializer`** — RTTI-based method parameter serializer using Dext JSON DOM to serialize and deserialize class method parameters (`TValue` arrays).

---

## 📚 2. Dext Collections Library (`Sources\Core`)

### 2.1 Core Collections (`Dext.Collections`, `Dext.Collections.Base`)
- **TRawList\<T\>** — Backbone of all collections. Generic list based on dynamic arrays with `Move`-based insertion/deletion to minimize overhead. `for-in` support via custom enumerator.
- **TList\<T\>** / **IList\<T\>** — High-performance generic list. Operations: `Add`, `Insert`, `Remove`, `IndexOf`, `Sort`, `BinarySearch`, `Contains`, `ToArray`.
- **TDictionary\<K,V\>** / **IDictionary\<K,V\>** — Generic hash map supporting `TryGetValue`, `AddOrSetValue`, `ContainsKey`, `Keys`, `Values`.
- **THashSet\<T\>** / **IHashSet\<T\>** — Set of unique values with set theory operations: `UnionWith`, `IntersectWith`, `ExceptWith`.
- **TCollections (Factory)** — Static factory: `CreateList<T>`, `CreateDictionary<K,V>`, `CreateHashSet<T>`, `CreateSortedList<T>`, etc.
- **TSmartEnumerator\<T\>** — Extensible base enumerator for custom iteration in derived collections.

### 2.2 LINQ Extensions (`Dext.Collections.Extensions`)
- **Fluent Operations** — `Where`, `Select`, `OrderBy`, `OrderByDescending`, `First`, `FirstOrDefault`, `Last`, `Any`, `All`, `Count`, `Sum`, `Min`, `Max`, `Average`, `Distinct`, `Take`, `Skip`, `GroupBy`, `SelectMany`, `Aggregate`, `Contains`, `ToList`, `ToDictionary`, `ForEach`.

### 2.3 Concurrent Collections (`Dext.Collections.Concurrent`)
- **TConcurrentDictionary\<K,V\>** — Thread-safe dictionary with **Lock Striping** via `TSpinLock` array (multiple independent lock buckets to reduce contention).
- **TConcurrentQueue\<T\>** / **TConcurrentStack\<T\>** — Thread-safe queue and stack for producer/consumer scenarios.

### 2.4 Frozen Collections (`Dext.Collections.Frozen`)
- **TFrozenDictionary\<K,V\>** / **TFrozenSet\<T\>** — Immutable structures optimized for high-read scenarios (.NET 8 `FrozenDictionary` style). Once constructed, no modifications are allowed, enabling memory layout optimizations.

### 2.5 Channels (`Dext.Collections.Channels`)
- **TChannel\<T\>** — Go-style async communication primitive for Producer/Consumer pipelines.
- **Bounded Channel** — Fixed capacity with back-pressure (writer blocks when full).
- **Unbounded Channel** — Unlimited capacity (writer never blocks).
- **ChannelReader / ChannelWriter** — Segregated interfaces for reading and writing.

### 2.6 SIMD & Hardware Acceleration (`Dext.Collections.Simd`)
- **TDextSimd** — Vectorized operations with automatic instruction set detection:
  - `EqualsBytes` — Byte array comparison via **AVX2** (32 bytes/cycle), **SSE2** (16 bytes/cycle), or Pascal fallback.
  - `IndexOfByte` — Linear search accelerated via vector instructions.
  - `FillByte` / `MoveMem` — Optimized memory fill and copy.
- **Runtime Detection** — CPUID detection at startup. Automatic selection of the best available path.

### 2.7 Comparers & Algorithms (`Dext.Collections.Comparers`, `Dext.Collections.Algorithms`)
- **TEqualityComparer\<T\>** / **TComparer\<T\>** — Standard generic comparers supporting primitives, records, and classes.
- **Algorithms** — `Sort` (IntroSort), `BinarySearch`, `Reverse`, `Shuffle`.

---

## 🌐 3. Dext Web Framework (`Sources\Web`)

### 3.1 Bootstrapping & Minimal API
- **TWebApplication** — Fluent facade for initialization: automatically loads `appsettings.json`, `appsettings.yaml`, Environment Variables, registers services, and builds the pipeline in a single chain.
- **Minimal API** — Direct handler registration via delegates without controllers (`app.MapGet`, `app.MapPost`).

### 3.2 Middleware Pipeline
- **Chain of Responsibility** — Functional (anonymous delegates) and class-based middlewares with DI constructor injection.
- **Built-in Middlewares** — Logger, Compression (GZip/Brotli), Exception Handling (**ProblemDetails** RFC 9457), **DeveloperExceptionPage**, CORS, StartupLock.

### 3.3 Routing Engine
- **Dynamic Parameters** — Routes with `{id}`, `{slug}`, and type constraints.
- **API Versioning** — `THeaderApiVersionReader`, `TQueryStringApiVersionReader`, `TPathApiVersionReader`, `TCompositeApiVersionReader` (composite strategy).

### 3.4 Model Binding
- **Hybrid Binding** — `[FromBody]`, `[FromQuery]`, `[FromRoute]`, `[FromHeader]`, `[FromServices]` attributes.
- **Zero-Allocation** — Direct UTF-8 deserialization to records and classes via `TByteSpan`.
- **Multipart/Form-Data** — Upload processing via `IFormFile` abstraction.
- **Object Lifecycle Management** — Tracking of objects created by Model Binding with integration to ORM **ChangeTracker** for automatic ownership transfer.

### 3.5 Hosting
- **IWebHost / IWebHostBuilder** — Hosting abstractions. Support for **Dynamic Ports (Port 0)** with automatic OS assignment.
- **Server Adapters** — Indy (default, OpenSSL/Taurus SSL), **WebBroker Adapter** (ISAPI/CGI for IIS/Apache), **DCS Adapter** (Delphi-Cross-Socket, non-blocking).
- **IHostedService** — Background tasks with `StartAsync`/`StopAsync`. `TBackgroundService` with `Execute(ICancellationToken)`.
- **IHostApplicationLifetime** — Tokens for `ApplicationStarted`, `ApplicationStopping`, `ApplicationStopped`.

### 3.6 Security & Identity
- **IClaimsPrincipal** — JWT, Basic Auth (RFC 7617), and Cookie authentication.
- **Rate Limiting** — Fixed Window, Sliding Window, Token Bucket, Concurrency Limiter.

### 3.7 Real-time & Caching
- **SSE (Server-Sent Events)** — Unidirectional event streaming.
- **SSE-based Messaging (SignalR roadmap)** — Basic SSE event broadcast. High-performance SignalR-equivalent bi-directional WebSockets/Hubs are planned.
- **Caching** — In-Memory. (A full high-performance native Redis client is planned and under active development, currently ~80% complete). Detailed **Health Checks** (expandable roadmap under development).

### 3.8 API Documentation & Scaffolding
- **OpenAPI / Swagger** — Automatic specification generation.
- **Auto-Migrations (S11)** — Automatic schema synchronization during startup with table/column rename detection via attributes.
- **View Engine & WebStencils (S09)** — AST-based template engine (Razor-style), zero-dependency.

### 3.9 Database as API (`Dext.Web.DataApi`)
One of Dext's most powerful features: **automatic generation of full REST APIs from ORM entities — with a single line of code**. Not a scaffold that generates code — it's a runtime handler mapping entities to endpoints dynamically.

#### Registration (3 coexisting modes)
- **Automatic by Attribute** — `[DataApi]` on the entity + `App.MapDataApis` at startup. `TDataApi.MapAll` scans RTTI and registers all decorated entities automatically.
- **Typed Manual** — `TDataApiHandler<TProduct>.Map(App, '/api/products')`.
- **Fluent Manual** — `App.Builder.MapDataApi<T>(path, DataApiOptions.AllowRead.RequireAuth)`.

#### 5 Generated CRUD Endpoints
| Method | Route | Handler |
|---|---|---|
| `GET` | `/api/{entity}` | `HandleGetList` — List with pagination, sorting, and filters |
| `GET` | `/api/{entity}/{id}` | `HandleGet` — PK lookup (simple or composite) |
| `POST` | `/api/{entity}` | `HandlePost` — Creates new record, returns 201 |
| `PUT` | `/api/{entity}/{id}` | `HandlePut` — Updates existing record |
| `DELETE` | `/api/{entity}/{id}` | `HandleDelete` — Removes record |

#### Dynamic Specification Mapping (QueryString Filters)
- **11 Operators** automatically parsed from URL: `_eq`, `_neq`, `_gt`, `_gte`, `_lt`, `_lte`, `_cont` (LIKE %x%), `_sw` (LIKE x%), `_ew` (LIKE %x), `_in` (IN), `_null` (IS NULL).
- **Pagination** — `?_limit=20&_offset=40`.
- **Sorting** — `?_orderby=price desc,name asc`.
- **Name Resolution** — `ResolvePropertyName` via `TReflection.GetMetadata().GetHandlerBySnakeCase` to convert URL snake_case to Delphi property PascalCase.
- Each filter generates an `IExpression` via `TStringExpressionParser.Parse` and is injected into the `ISpecification` — the same AST used by Smart Properties.

#### TDataApiOptions — Fluent Configuration API
- **Security** — `RequireAuth`, `RequireRole(roles)`, `RequireReadRole(roles)`, `RequireWriteRole(roles)` — Read/write permission separation with integrated JWT validation via `IClaimsPrincipal`.
- **Allowed Methods** — `Allow([amGet, amGetList])` restricts which endpoints are generated.
- **Multi-Tenancy** — `RequireTenant` for tenant isolation.
- **Naming Strategy** — `UseSnakeCase`, `UseCamelCase` for serialization casing control.
- **Enum Style** — `EnumsAsStrings`, `EnumsAsNumbers`.
- **Explicit DbContext** — `DbContext<TMyContext>` to select which context to use.
- **Custom SQL** — `UseSql('SELECT ...')` for custom queries.
- **Swagger** — `UseSwagger`, `Tag('Products')`, `Description('...')` for automatic documentation.

#### Naming Conventions (`TDataApiNaming`)
- **Auto-Discovery** — `T` prefix automatically removed via `TReflection.NormalizeFieldName`.
- **Pluralization** — English: `y→ies`, `ch/sh/x/s→es`, default `→s` (e.g., `TCategory` → `/api/category`).
- **Custom Routes** — `[DataApi('/my/path')]` overrides conventions.
- **Case Mapping** — Delphi property `PascalCase` → URL `snake_case` for filters.

#### Entity ID Resolver (`TEntityIdResolver`)
- **Automatic PK Type Resolution** — Delegates to `IModelBinder` for transparent conversion: Integer, String, TUUID, TGUID.
- **Composite Keys** — `|` separator for composite keys (e.g., `/api/entity/1|ABC`).

#### Ecosystem Integration
- **DI Scope** — `GetDbContext` resolves `TDbContext` from the DI container (supports multiple contexts via `ContextClass`).
- **Telemetry** — `TDiagnosticSource.Write('DataApi.ModelBinding.Start/Complete')` emits traceable events.
- **Logging** — All handlers emit logs via `Log.Debug`/`Log.Error` with structured templates.
- **Serialization** — `TDextJson.Deserialize` + `TDextSerializer` with per-endpoint configurable settings.
- **Swagger** — Registered endpoints automatically appear in OpenAPI documentation.
- **`[DataApiIgnore]`** — Attribute to exclude specific entities from automatic scanning.

---

## 📊 4. Dext ORM & Entity Framework (`Sources\Data`)

### 4.1 Core Persistence
- **TDbContext** — Unit of Work with automatic **Change Tracking** (states: Added, Modified, Deleted, Unchanged). **Identity Map** for instance uniqueness by primary key.
- **DbSet\<T\>** — Generic repository. Operations: `Add`, `Update`, `Remove`, `Find`, `FirstOrDefault`, `Where`, `Include`, `ToList`.
- **SaveChanges** — Persists all tracked changes in a transaction.
- **Fluent Connection Setup & Pooling Auto-Detection** — Connection builders (`UsePostgreSQL`, `UseFirebird`, etc.) support automatic parameter extraction and synchronization with property setters, resolving empty-options/pooling bugs.
- **ConnectionDefName Support (FireDAC)** — Direct support for FireDAC connection definition names (`UseConnectionDef`). Automatically queries `FDManager.ConnectionDefs` to resolve the database dialect, driver ID, and pooling configuration dynamically.
- **Shadow Properties Support** — Declares columns (like `TenantId`, `CreatedAt`, `IsDeleted`) in database mappings that are tracked and saved without needing to be exposed as physical fields in class declarations.

### 4.2 Query Engine (LINQ-like)
- Fluent queries with **Projection (Select)**, **Paging** (`Skip`/`Take`), and **Aggregates** (`Count`, `Sum`, `Max`, `Min`, `Average`).
- **SQL Cache** — Reuse of generated SQL commands for repeated queries.
- **Strongly-Typed Fluent Joins** (`JoinInner`, `JoinLeft`, `JoinRight`, `JoinFull`, `JoinCross`) — Compiles directly into optimized database-level joins (INNER, LEFT, RIGHT, FULL, CROSS) using explicit condition expressions, implicit auto-resolution via relations metadata (`TModelBuilder`), or Cross Join Cartesian product execution.
- **Pessimistic Locking** — `FOR UPDATE` for concurrency control.
- **Multi-Mapping** (Dapper-style) — Recursive hydration via `[Nested]` attribute.
- **Fluent Validation Integration** — Integrates with validation engine inside `SaveChanges` to run automatic object verification before executing commits.

### 4.3 Specification Pattern (`Dext.Specifications`)
- **Fluent Specification Builder** — `Where`, `OrderBy`, `Include`, `Take`, `Skip` for decoupled and reusable business rules.
- **TExpressionEvaluator** (`Dext.Specifications.Evaluator`) — **In-memory** evaluator for the same AST used by the SQL Compiler. Evaluates `IExpression` against objects (`TObject`) or dictionaries (`TDictionary<string, Variant>`). Supports: comparisons (`=`, `<>`, `>`, `>=`, `<`, `<=`), `LIKE` (case-insensitive with `%`), `IN`/`NOT IN`, `IS NULL`/`IS NOT NULL`, bitwise operations (`AND`/`OR`/`XOR`), arithmetic (`+`, `-`, `*`, `/`, `mod`, `div`), and `AND`/`OR` short-circuiting. Automatically **unwraps `Prop<T>`** (Smart Types) via RTTI.
- **TStringExpressionParser** (`Dext.Specifications.Parser`) — Parser converting `"Field Operator Value"` strings into `IExpression` nodes. Automatic type conversion: Boolean, Float (invariant), Integer, String. Used internally by **Database as API** to transform QueryString filters into expression trees.
- **IExpressionVisitor** — Visitor pattern for traversing the expression tree, used by both the SQL Compiler (generating SQL) and the Evaluator (in-memory filtering).

### 4.4 Relationships & Loading
- **One-to-One**, **One-to-Many**, **Many-to-Many**.
- **Lazy Loading** via Proxy Objects (transparent interception).
- **Eager Loading** — `Include`/`ThenInclude` for graph pre-loading.
- **Split Queries Loading** — Collection navigation properties loaded via dedicated SQL queries using `IN` bounds parameters to avoid cartesian join explosion.

### 4.5 Migrations System
- Automated Code-First evolution with chronological database model snapshots.

### 4.6 Dialect Support (Polyglot)
- PostgreSQL, SQL Server, MySQL, SQLite, Oracle, Firebird, InterBase.
- **Legacy Paging** — Automatic wrapping for `ROWNUM` in older Oracle/SQL Server versions.

### 4.7 Soft Delete (`[SoftDelete]`)
- **Declarative Attribute** — `[SoftDelete('IsDeleted')]` transforms `Remove()` into an automatic `UPDATE`.
- **Custom Values** — `[SoftDelete('Status', 99, 0)]` for integers/enums.
- **HardDelete** — `Db.Tasks.HardDelete(Task)` for physical deletion.
- **Restore** — `Db.Tasks.Restore(Task)` to restore soft-deleted records.
- **Automatic Query Filters** — Deleted records are **invisible** by default. `IgnoreQueryFilters` to see everything, `OnlyDeleted` for the trash bin.
- **Timestamp Soft Delete** (`[DeletedAt]`) — Automatically converts `Remove()` into an update setting the current timestamp, and generates `IS NULL` filters for active records (Issue #121).
- **IdentityMap Cleanup** — Soft-deleted entities are removed from the memory cache after `SaveChanges`.

### 4.8 JSON/JSONB Column Queries (`[JsonColumn]`)
- **`[JsonColumn]` Attribute** — Marks string properties as JSON columns. `[JsonColumn(True)]` for JSONB in PostgreSQL.
- **Fluent Query** — `.Json('path')` to query properties inside JSON columns: `Prop('Settings').Json('role') = 'admin'`.
- **Nested Properties** — `Prop('Settings').Json('profile.details.level') = 5` using dot notation.
- **IS NULL** — `Prop('Settings').Json('nonexistent').IsNull` for missing keys.
- **Cross-Database** — PostgreSQL (`#>>` / indexed JSONB), MySQL (`JSON_EXTRACT` / `JSON_UNQUOTE`), SQLite (`json_extract` + JSON1), SQL Server (`JSON_VALUE`).
- **INSERT with Cast** — Automatic `::jsonb` in PostgreSQL for `[JsonColumn(True)]`.

### 4.9 EntityDataSet (`Dext.Data.EntityDataSet`)
- **ORM ↔ VCL/FMX Bridge** — Connects components (DBGrid, FastReport) to `TList<T>` POCO collections while preserving a clean architecture.
- **Zero-Allocation Memory** — Access via `TEntityMap` mapped memory offsets eliminates RTTI or string copying on every record read.
- **`LoadFromUtf8Json`** — Direct loading from JSON streams/buffers via `TByteSpan` without prior encoding conversion.
- **Automatic Setup (AST Parsing)** — In design-time, "Sync Fields" and "Refresh Entity" *Verbs* directly parse `.pas` units and create `TFields` dynamically **without needing to compile the project**.
- **Live Data Preview (Hybrid)** — IDE magic: by providing a `TFDConnection` and a `DataProvider`, Dext **generates dynamic SQL** and displays real data in the Grid during development. In *runtime*, this SQL is completely ignored, and the component consumes only the injected collections.
- **Expression Filtering** — `DataSet.Filter := 'Score > 100'` supported using the same `TExpressionEvaluator` as the in-memory framework.
- **Auto-Stabilization** — The `Active` property is never serialized as `True` in the DFM; prevents missing instance errors at runtime.
- **DML Memory Mode** — `Append`, `Edit`, `Post`, and `Delete` operations natively manipulate the underlying in-memory list.

### 4.10 Inheritance Mapping
- **TPH (Table-Per-Hierarchy)** — Automatic polymorphic hydration based on discriminators via attributes.

### 4.11 Advanced Features
- **Streaming Iterators** (Flyweight pattern) — O(1) memory for rendering large volumes in SSR views. `TStreamingViewIterator<T>` iterates on demand during template `@foreach`.
- Automatic converters for GUID, Enums, JSONB, and UUID v7.
- **Stored Procedures** — Declarative execution via `[StoredProcedure]` and `[DbParam]`.
- **Multi-Tenancy** — Shared Database (TenantId), Schema Isolation (`search_path`), Tenant per Database.
- **Bulk / Batch Operations** — High-performance batch APIs: `AddRange`, `UpdateRange`, and `RemoveRange` supporting raw generic collections (`TArray<T>`, `IEnumerable<T>`) for bulk database operations in a single context transaction.

### 4.12 Dynamic Query Filters (`Dext.Entity.DbSet`, `Dext.Specifications.SQL.Generator`)
- **`IgnoreQueryFilters` (Fluent API)** — `Db.Users.IgnoreQueryFilters.ToList` — bypasses all registered global query filters (Soft Delete, Multi-Tenancy) for a single query. Does not affect subsequent calls.
- **Specification-Level Control** — `ISpecification<T>.IgnoreQueryFilters` and `ISpecification<T>.IsIgnoringFilters`: enables specification classes to declare intent, keeping admin queries self-contained and reusable.
- **`IsOnlyDeleted` (Spec Integration)** — `ISpecification<T>.IsOnlyDeleted` propagates the trash-bin query flag in the same mechanism, allowing `OnlyDeleted` to be declared in a spec.
- **Scoped Propagation** — In `TDbSet<T>.ToList(ASpec)`, spec flags are propagated to the internal `FIgnoreQueryFilters` / `FOnlyDeleted` state before SQL generation and reset via `ResetQueryFlags` in a `finally` block — ensuring isolation between calls.
- **SQL Generator Integration** — `TSQLGenerator<T>.GetSoftDeleteFilter` returns empty string when `FIgnoreQueryFilters` is `True`. `GetQueryFiltersSQL` exits early for the same reason.
- **Admin Spec Pattern** — Allows building dedicated specification classes (`TAdminListSpec`) that call `IgnoreQueryFilters` in their constructor, enabling declarative, zero-friction access to raw data.

---

## 🔌 5. Dext Net — HTTP Client & Authentication (`Sources\Net`)

### 5.1 High-Performance REST Client (`Dext.Net.RestClient`)
- **Fluent API** — Consume APIs without visual components. Methods: `RestClient('url').BearerToken('...').Get<T>('/path').Await`.
- **Fluent REST Request Factory** — Grouping pattern using `Client.Request.Get('/path')` to isolate request building, avoiding root-level client scope bloat and return type limitations (Issue #119).
- **Unrestricted Body Payloads** — Native support for serializing `record` and `TArray<T>` in request payloads (`Body<T>` and the array helper `BodyArray<T>`), bypassing generic compiler restrictions.
- **Record & Array Deserialization** — Native deserialization of JSON arrays and objects directly into records and dynamic arrays (`TArray<T>`) during request execution.
- **Ergonomic Responses** — Boolean helper `IRestResponse.IsSuccess` for immediate status code validation in the `200..299` range.
- **Connection Pooling** — Intelligent `TNetHttpClient` instance reuse (thread-safe pooling), eliminating TCP/SSL handshake overhead and radically reducing OS resource usage.
- **Auto-Serialization** — Native integration with Dext's JSON engine for hydrating objects and generic collections (`IList<T>`).
- **Async First** — Fully integrated with `Dext.Threading.Async` with `ICancellationToken` support for cooperative cancellation and UI Access Violation protection.
- **Retry Logic** — Automatic recovery with exponential backoff and Async/Await support.
- **Typed Responses** — `Client.Get<TUser>('/users/1')` with automatic deserialization.
- **Async Chaining** — `Client.Get<TToken>('/auth').ThenBy<TUser>(...)`.OnComplete(...)`.Start`.
- **Cancellation** — `ICancellationToken` to abort ongoing requests.
- **Pluggable Auth** — `TBearerAuthProvider`, `TBasicAuthProvider`, `TApiKeyAuthProvider`.
- **Thread Safety** — Immutable configuration snapshot in `Execute`; isolated execution via pool.
- **Response Headers** — Full access via `GetHeader` (case-insensitive) and `GetHeaders` (TNetHeaders array).
- **THttpRequestInfo** — Integration with `.http` parsers for ad-hoc request execution.
- **Multipart Form Fields with Content-Type** — Support for specifying custom MIME types (e.g. `application/json`) for individual form fields in multipart requests via `AddFormField` and `AddMultipartField` (Issue #125).
- **Conditional Query Parameters** — Support for fluently adding query parameters conditionally (`QueryParamIfNotEmpty`, `QueryParamIf`, and overloads with default values) to simplify request building (Issue #123).
- **Legacy Compatibility and Indy Fallback** — Complete abstraction of the HTTP engine (`IDextHttpEngine`) with automatic fallback using Indy (`TIdHTTP`) for older IDEs (Delphi XE2 to XE7), active in compilers below XE8 or under the `DEXT_FORCE_INDY` directive. OpenSSL DLLs required for legacy HTTPS requests.

### 5.2 Authentication Providers
- **Bearer Token (JWT)** — Automatic `Authorization: Bearer <token>` header.
- **Basic Auth (RFC 7617)** — Base64 encoding of `user:password`.
- **API Key** — Customizable header or query string.
- **OAuth 2.0 Client Credentials (RFC 6749 §4.4)** — Automatic token caching, thread-safe refresh with a 30s safety margin to prevent using expired tokens.

---

## 📢 6. Dext Event Bus (`Sources\Events`)

### 6.1 Core Architecture (`Dext.Events.Interfaces`, `Dext.Events.Bus`)
- **IEventBus** — Central in-memory event bus for total decoupling between producers and consumers.
- **IEventHandler\<T\>** — Typed interface for event handlers. Multiple handlers per event type, executed in registration order.
- **IEventPublisher\<T\>** — ISP (Interface Segregation Principle) facade for components that only publish a specific event type.
- **Synchronous Dispatch** — `IEventBus.Dispatch` invokes all handlers and returns `TPublishResult` with statistics (`HandlersInvoked`, `HandlersFailed`, `HandlersSucceeded`).
- **Asynchronous Dispatch** — `DispatchBackground` executes handlers in a separate thread with an isolated DI scope (fire-and-forget).
- **TEventBusExtensions** — Generic static helpers `Publish<T>` and `PublishBackground<T>` that box the event to `TValue` and delegate to `IEventBus`.

### 6.2 Behavior Pipeline (`Dext.Events.Behaviors`)
- **IEventBehavior** — Cross-cutting middleware for the event pipeline. `Intercept(AEventType, AEvent, ANext)` method — calling `ANext()` continues the pipeline; omitting it short-circuits.
- **TEventLoggingBehavior** — Structured logging via `ILogger`. Debug before/after handler with elapsed time. Error handling with failure re-raise.
- **TEventTimingBehavior** — Debug-only, records dispatch time via `OutputDebugString`.
- **TEventExceptionBehavior** — Structured exception wrapping in `EEventDispatchException` with event type name. Re-raise preserves original context.
- **Global vs Per-Event Behaviors** — Global apply to all events; Per-event apply only to the specific type and execute INSIDE global ones.

### 6.3 DI Extensions (`Dext.Events.Extensions`)
- **`Services.AddEventBus`** — Registers `IEventBus` as a Singleton (each Publish creates a child DI scope).
- **`Services.AddScopedEventBus`** — Registers as Scoped (handlers share the same scope, ideal for web requests with a shared DbContext).
- **`Services.AddEventHandler<TEvent, THandler>`** — Typed handler registration with automatic Transient registration.
- **`Services.AddEventBehavior<T>`** — Global behavior. **`AddEventBehaviorFor<TEvent, T>`** — Per-event behavior.
- **`Services.AddEventPublisher<T>`** — Registers `IEventPublisher<T>` as transient for ISP injection.
- **`Services.AddEventBusLifecycle`** — Registers `TEventBusLifecycleService` as an `IHostedService`.

### 6.4 Lifecycle Events (`Dext.Events.Lifecycle`)
- **TEventBusLifecycleService** — Background service listening to `IHostApplicationLifetime` and publishing `TApplicationStartedEvent`, `TApplicationStoppingEvent`, `TApplicationStoppedEvent` to the `IEventBus`.
- **Hosting Bridge** (`Dext.Hosting.Events.Bridge`) — `THostingLifecycleEventBridge` for integration with the background services builder via `AddLifecycleEvents`.

### 6.5 Testing Support (`Dext.Events.Testing`)
- Infrastructure for testing handlers and behaviors with pipeline mocking.

### 6.6 Aggregate Exception Handling
- **EEventDispatchAggregate** — Aggregate exception containing `Errors: TArray<string>` with one entry per failed handler. All handlers are always invoked before raising.

---

## 🧪 7. Dext Testing Framework (`Sources\Testing`)

### 7.1 Test Runner & Dashboard
- **CLI Runner** — High-performance command-line executor (`dext test`) with support for category and priority filtering.
- **Live Dashboard** — Built-in visual host for real-time test monitoring with failure history and stack trace analysis.
- **Fluent Runner API** (`Dext.Testing.Fluent`) — Programmatic configuration: `TTest.Configure.Verbose.RegisterFixtures([...]).Run`.

### 7.2 Attribute-Based Runner (`Dext.Testing.Attributes`)
Write tests without base class inheritance using RTTI metadata.
- **Core Attributes** — `[Fixture]`, `[Test]`, `[Fact]`, `[TestClass]`.
- **Lifecycle Management** — `[Setup]`, `[TearDown]`, `[BeforeAll]`, `[AfterAll]`, `[AssemblyInitialize]`, `[AssemblyCleanup]`.
- **Data-Driven Testing** —
  - `[TestCase(A, B, Expected)]` — Inline parameterized tests.
  - `[TestCaseSource('MethodName')]` — Dynamic data providers via methods.
  - `[Values(V1, V2)]`, `[Range(Start, Stop, Step)]`, `[Random(Min, Max, Count)]` — Automatic case generation.
  - `[Combinatorial]` — Execute all possible parameter combinations.
- **Execution Filters & Control** —
  - `[Ignore('Reason')]`, `[Skip('Reason')]` — Skip tests.
  - `[Explicit]` — Tests run only when explicitly selected.
  - `[Category('Tag')]`, `[Trait('Name', 'Value')]` — Categorization and filtering.
  - `[Timeout(ms)]`, `[MaxTime(ms)]`, `[Repeat(n)]`, `[Priority(n)]` — Execution and performance control.
  - `[Platform('Windows, Linux')]` — OS-specific restrictions.

### 7.3 Fluent Assertions (`Dext.Assertions`)
Fluent API based on the `Should(Value)` pattern.
- **Typed Assertions** — Specific methods for `ShouldString`, `ShouldInteger`, `ShouldDouble` (approximation), `ShouldBoolean`, `ShouldDateTime`, `ShouldGuid`, `ShouldUUID`, `ShouldObject`.
- **List/Collection Assertions** — `Should(List).HaveCount(5).Contain(X).OnlyContain(Predicate).AllSatisfy(Predicate)`.
- **Structural Comparison** — `BeEquivalentTo` for deep object and collection comparison (order-independent).
- **Soft Asserts** — `Assert.Multiple(procedure ... end)` to collect multiple failures in a block before failing the test.
- **Action Assertions** — `Should(Proc).Throw<EException>().WithMessageContaining('...')`.

### 7.4 Snapshot Testing
- **`MatchSnapshot('name')`** — Verify complex objects and JSON payloads via disk-based baseline comparison.
- **Structural JSON Compare** — Smart comparison that ignores formatting and property order in JSON.
- **Update Mode** — `SNAPSHOT_UPDATE=1` environment variable for automatic baseline updates.

### 7.5 Mocking & Interception (`Dext.Mocks`, `Dext.Interception`)
- **Dynamic Proxies** — `TProxy` (Interfaces) and `TClassProxy` (Classes with virtual methods) via `TVirtualInterface` and `TVirtualMethodInterceptor`.
- **Fluent Mocking** — `Mock<T>.Setup.Returns(Val).When.Method(Args)`.
- **Argument Matchers** — `Arg.Any<T>`, `Arg.Is<T>`, `Arg.IsNotNull<T>`.
- **Verification** — `Received(Times.Once)`, `Received(Times.AtLeast(n))`.
- **Auto-Mocking** — `TAutoMocker` for automated mock injection into the DI container during unit tests.

### 7.6 Reporting & CI/CD (`Dext.Testing.Report`)
- **Multi-Format Export** — JUnit XML, xUnit XML, TRX (Azure DevOps), HTML (Dark Theme), JSON.
- **SonarQube Integration** — Generate code coverage and failure reports compatible with Quality Gates.
- **Decoupled TestInsight Integration** (`Dext.Testing.TestInsight`) — Decoupled execution hook and listener for TestInsight plugin that automatically routes test runs and results to the IDE without framework compile-time coupling.
- **Decoupled Test Runner Integration & Registry** (`Dext.Testing.Integration`) — Command-line registry and parameter processing system enabling decoupled executions from the IDE or CLI without intermediate BPL dependencies.
- **Native DUnitX Integration** (`Dext.Testing.DUnitX`) — Decoupled runner adaptation for DUnitX that pipes real-time results, status streams, and filtering logic over local HTTP/SSE to the Dext Test Explorer IDE Expert.
- **Native DUnit Integration** (`Dext.Testing.DUnit`) — Decoupled runner adaptation for DUnit that registers custom listeners to pipe results, duration metadata, and execution streams to the Dext Test Explorer.
- **Native DUnit2 Integration** (`Dext.Testing.DUnit2`) — Decoupled runner adaptation using proxy interfaces to pipe real-time results and suite hierarchies from DUnit2 frameworks to the Dext Test Explorer.
- **Test Context Injection** — `ITestContext` injectable via parameter for `WriteLine`, `AttachFile` (screenshots), and execution metadata.

---

## 🎨 8. Dext Template Engine (`Sources\Core\Base\Dext.Templating`)

### 8.1 Core Architecture
- **ITemplateEngine** — Main interface: `Render(template, context)` and `RenderTemplate(name, context)`.
- **TDextTemplateEngine** — Complete implementation with AST (Abstract Syntax Tree) parser. Each directive is compiled into a node (`TTemplateNode`) with a `Render` method.
- **ITemplateContext** — Hierarchical context with string values, objects, and lists. `CreateChildScope` for nested scoping.

### 8.2 Template Loader
- **ITemplateLoader** — Pluggable interface for loading templates. Implementations: FileSystem and In-Memory.

### 8.3 Node Types (AST)
- `TTextNode` (literal text), `TExpressionNode` (interpolation `{{ var }}`), `TIfNode`/`TElseIfNode`/`TElseNode` (conditionals), `TForEachNode` (iteration with `@index`, `@first`, `@last`), `TBlockNode` (named blocks), `TExtendsNode` (layout inheritance), `TSectionNode` (sections), `TMacroNode` (reusable macros), `TBreakNode`/`TContinueNode` (loop flow control).

### 8.4 Expression Engine
- Expression parser with support for arithmetic, comparison, and logical operators (`and`, `or`, `not`).
- **Chained Filters** — `{{ value | upper | truncate(10) }}` with filter pipeline.
- **Filter Registry** (`ITemplateFilterRegistry`) — `RegisterFilter(name, func)` for custom filters.
- **Built-in Filters** — `upper`, `lower`, `capitalize`, `truncate`, `default`, `date`, `html_escape`, etc.

### 8.5 Advanced Features
- **Layout Inheritance** — `{% extends "base.html" %}` with block overrides.
- **Whitespace Control** — `{%- -%}` for whitespace control in directives.
- **HTML Mode** — `IsHtmlMode` for automatic output escaping.
- **Source Position Tracking** — `TSourcePos` with line, column, and filename for precise error reporting.
- **ETemplateException** — Exceptions with position and template snippet for debugging.

---

## ✅ 9. Dext Validation Engine (`Dext.Validation`)

- **Attribute-Based Validation** — RTTI decorators: `[Required]`, `[StringLength(min, max)]`, `[Range(min, max)]`, `[RegularExpression(pattern)]`, `[EmailAddress]`, `[Url]`.
- **Fluent Validation API** — Strongly-typed validation base class `TAbstractValidator<T>` implementing `IValidator<T>` as a modern C# FluentValidation-like alternative.
- **Fluent Rule Builder** — Memory-efficient record `TValidationRuleBuilder<T>` that avoids heap allocations while building chained validation rules (`Required`, `Length`, `Range`, `EmailAddress`, `Matches`, `MatchesPattern`, `Must`, `When`).
- **Smart Property Integration** — Concrete `RuleFor` overloads for standard `Prop<T>` smart properties (e.g., `Prop<string>`, `Prop<Integer>`, `Prop<Boolean>`, etc.) to automatically extract property names from Prototype ghost entities without magic strings or compiler casting issues.
- **Pattern Registry** — `TValidationPatterns` registry mapping keys to locale-specific regular expressions (e.g. Pt-BR or En-US phone numbers and zipcodes).
- **TValidator** — Non-generic helper: `Validate(obj)` returns `TValidationResult` with a list of `TValidationError` (field + message).
- **TValidator\<T\>** — Typed generic version.
- **Custom Validators** — Inherit from `ValidationAttribute` for custom business rules.
- **Web Integration** — Automatic resolution of registered validators (`IValidator<T>`) from the Dependency Injection (DI) container inside the web model binding pipeline (`THandlerInvoker.Validate`), raising `TWebValidationException` to yield structured error JSON/HTMX payloads.

---

## 🔄 10. Dext Mapper (`Dext.Mapper`)

- **TMapper** — AutoMapper-like for DTO↔Entity transformation.
- **CreateMap\<TSource, TDest\>** — Mapping registration with automatic property reflection by name.
- **ForMember** — Mapping override for specific properties with custom lambda expressions.
- **Map\<TSource, TDest\>** — Mapping execution with automatic destination instance creation.
- **Collection Mapping** — Automatic mapping of lists and arrays.

---

## 🏢 11. Dext Multi-Tenancy (`Dext.MultiTenancy`)

- **ITenantProvider** — Abstraction for current tenant identification.
- **ITenantConnectionStringProvider** — Dynamic connection string resolution per tenant.
- **Strategies** — Shared Database (TenantId discriminator), Schema Isolation (`search_path` in PostgreSQL), Database per Tenant.
- **DI Integration** — Registered as a Scoped service for resolution per request.

---

## 🖥️ 12. Desktop UI & Design-Time (`Sources\UI`, `Sources\Design`)

### 12.1 Navigator Framework (Flutter-style)
- **ISimpleNavigator** — Push/Pop/Replace/PopUntil navigation with `TValue` data passing.
- **3 Adapters** — `TCustomContainerAdapter` (embed frames in panel), `TPageControlAdapter` (tabs), `TMDIAdapter` (child windows).
- **Middleware Pipeline** — `TLoggingMiddleware`, `TAuthMiddleware`, `TRoleMiddleware` — same architecture as the Web pipeline.
- **Lifecycle Hooks** — `INavigationAware` with `OnNavigatedTo(Context)` and `OnNavigatedFrom`.
- **DI Integration** — Navigator registered as a Singleton service in the container.

### 12.2 Magic Binding (`Dext.UI.Binding`)
- **Two-Way Attribute-Based Binding** — `[BindEdit('Name')]`, `[BindCheckBox('Active')]`, `[BindText('ErrorMessage')]`.
- **Nested Properties** — `[BindEdit('Customer.Address.City')]` with dot notation.
- **Message Dispatch** — `[OnClickMsg(TSaveMsg)]` eliminates manual `OnClick` handlers.
- **Custom Converters** — `IValueConverter` with `Convert`/`ConvertBack` for complex types (e.g., `TCurrencyConverter`).
- **TBindingEngine** — Central engine automatically synchronizing ViewModel ↔ UI.

### 12.3 MVVM Patterns
- Clean architecture with ViewModel + Controller + DI.
- **Validation Integration** — `FViewModel.Validate` with errors automatically reflected in the UI via binding.

### 12.4 Infrastructure
- **Interception Engine** — Proxy engine for method interception, base for Mocks and AOP (Aspect-Oriented Programming) features.
- **Design-Time Experts** — IDE Grid Data Preview and specialized metadata property editors.

### 12.5 Design-Time Scaffolding Experts (`Dext.EF.Design.Scaffolding`)
- **TSelectionEditor Integration** — Non-invasive context menu integration for `TFDConnection` and `TDataSet` (FireDAC and Generic). Dext menus coexist with native IDE menus.
- **TTableSelectionForm** — Advanced selection UI with real-time filtering, "Select All/None" shortcuts, and live table/selection counters.
- **Live Scaffolding Preview** — High-fidelity preview window with real-time code generation, statistics (Entities/Metadata/Lines), and style switching (POCO vs. Smart).
- **Smart PascalCase Engine** — Acronym-aware naming logic (`EmployeeID` → `EmployeeId`, `ReportsTo` preserved) with support for `snake_case` and `ALL_CAPS` normalization.
- **Enhanced Meta-Inference** — Precise AutoInc detection via RTTI and `ftAutoInc`, ensuring 1:1 parity with database schema.
- **IOTA Automation** — Seamless creation of new units in memory and automatic association with the active Delphi project.

---

## 🛠️ 13. Dext CLI & Scaffolding (`Tools\Dext.Tool.Scaffolding`)

- **Dext CLI (S01)** — Unified CLI engine (`dext.exe`) for project management.
- **Advanced Scaffolding** — Project and file generation via smart templates: `dext new` (projects), `dext add` (controllers, entities, middlewares).
- **Template Logic** — Direct integration with **Dext.Templating** for complex logic within scaffolding templates.
- **Dext Doc** — Automated technical project documentation generation.
- **`dext test`** — CLI-based test execution and coverage report generation.
- **`dext ui`** — Web dashboard for real-time test monitoring.

---

## 🔍 14. Observability & Telemetry (`Sources\Core\Base`)

- **TDiagnosticSource (S03)** — Centralized event publisher based on JSON payloads, ensuring decoupling between producers (ORM, Web) and consumers.
- **Telemetry Bridge** (`Dext.Logging.Telemetry`) — Automatic `ILogger` integration, enabling HTTP and SQL telemetry visualization in console or log files.
- **SQL Capture** — ORM native SQL instruction extraction and formatting for real-time auditing.
- **HTTP Lifecycle** — Latency, status codes, and web framework route tracing.
- **Stack Trace Extraction** (`Dext.Core.Debug`) — Precise and detailed stack trace extraction at the point of exception. Critical for debugging highly integrated frameworks with dynamic execution flows.

---

## 🤖 15. AI Skills & Developer Experience (`Docs\ai-agents`)

- **Native AI Skills** — Modular instruction files (`dext-web.md`, `dext-orm.md`, `dext-auth.md`) teaching AI assistants (Cursor, Antigravity, Copilot, Claude) to generate idiomatic Dext code.
- **3 Integration Modes** — Direct copy to `.agents/skills/`, global custom configuration, or symlinks.
- **Modular by Design** — Atomic skills to save context tokens; load only relevant modules for the current feature.
- **Compatibility** — Claude Code, Cursor, Antigravity, Cline, OpenCode, GitHub Copilot.

---

## 🌐 16. SSR & View Engines — Advanced Features

### 16.1 HTMX Integration
- **Auto-Detection** — The pipeline automatically detects `HX-Request` headers and **suppresses the global layout** on compatible endpoints.
- **Partial Rendering** — `Results.View<T>('fragment', Query).WithLayout('')` for partial fragment rendering without layout.
- **Full-Stack SPA Feel** — Combines server-side SSR with dynamic HTMX swapping for highly responsive apps without heavy JavaScript.

### 16.2 Flyweight Iterators (Streaming SSR)
- **O(1) Memory** — `TStreamingViewIterator<T>` iterates on demand during template `@foreach`. 10.000 records rendered using memory equivalent to **a single object**.
- **No `ToList`** — Pass `Db.Customers.QueryAll` directly to `Results.View<T>('customers', Query)` and the framework automatically engages streaming.
- **Smart Properties in Templates** — `@(Prop(item.Name))` for automatic `Prop<T>` unwrapping inside HTML templates.

### 16.3 Web Stencils (Delphi 12.2+)
- **Native Provider** — `Services.AddWebStencils(...)` with entity whitelisting via `TWebStencilsProcessor.Whitelist.Configure`.
- **Agnostic** — Same `IViewEngine` interface for Dext Template Engine and Web Stencils; switch without changing code.

---

## 🧪 17. Quality & Testing (Scale and Rigor)

Dext is continuously validated by a massive testing infrastructure to ensure integrity across its subsystems:

- **Engineering Statistics** — The project exceeds **200,000 lines of pure Pascal code** (excluding templates and documentation), reflecting a massive investment in stability and high-level abstractions.
- **Massive Coverage** — Hundreds of test suites with thousands of individual assertions validating everything from the Core (Memory, Collections) to complex Web and ORM integrations.
- **Multi-DB Matrix (ORM)** — The persistence engine is exhaustively tested across a real matrix of 5 databases: PostgreSQL, SQL Server, MySQL, SQLite, and Firebird.
- **Stress & Concurrency Testing** — Validation of concurrent collections, channels, and async tasks under high load to ensure no Race Conditions.
- **Anti-Leak Policies** — Rigorous memory monitoring in every suite; test failures are triggered if object leaks are detected.
- **Field Evidence** — Framework validated in real-world projects deployed on **AWS and Azure**, with fiscal management systems processing peaks of **~800,000 daily requests**.
- **CI/CD Quality Gates** — Native integration with Azure DevOps and GitHub Actions, enforcing coverage thresholds and snapshot approval.

---

## 🤖 18. MCP Server (Model Context Protocol) (`Sources\MCP`)

The framework provides a native, zero-dependency implementation of the **MCP 2025-03-26** specification, enabling Dext applications to expose tools, resources, and prompts to AI agents (like Claude Desktop and Claude Code).

- **Supported Transports** — `HTTP Streamable` (Synchronous POST with Sessions), `SSE` (Legacy Server-Sent Events), and `Stdio`.
- **Declarative RTTI API** — `TMCPToolProvider` with `[MCPTool]`, `[MCPParam]`, `[MCPResource]`, and `[MCPPrompt]` attributes for frictionless endpoint registration.
- **Fluent Builder API** — Chainable registration: `Server.Tool('name').Description('...').OnCall(...)`.
- **Rich Content Types** — Built-in support for `TMCPContent` (Text, Image, Audio, Embedded Resources) and `TMCPToolResult` returning multiple blocks and error states.
- **Integration** — Runs natively on top of Dext's `TWebHostBuilder` allowing MCP and REST endpoints to coexist non-blocking in the same process.

---

## 📊 19. Dext Observability Suite & Telemetry (S23 — S27) (`Sources\Core\Base`, `Sources\Dashboard`)

The framework embeds a premium, high-performance, asynchronous observability suite designed to gather, persist, and visualize structured logs, distributed spans, system health metrics, and detailed database query and external network profiling.

### 19.1 Distributed Tracing & Structured Logging (S24)
- **Asynchronous Ring Buffer** — Log entries and spans are collected into a high-performance in-memory ring buffer (capped at 1000 items), eliminating disk I/O bottlenecks in critical request-handling threads.
- **Asynchronous Persistence** — A dedicated background worker (`TDashboardSaveTimer`) periodically flushes traces to `telemetry.json` every 30 seconds in a non-blocking manner.
- **Hierarchical Gantt Tree** — The Dashboard renders visual span nodes nested under their parent trace contexts (`TraceId`/`SpanId`) in real time, making latency and processing bottlenecks simple to analyze.

### 19.2 System Metrics & Throughput (S25)
- **RED Metrics Dashboard** — Real-time visual graphs in the Dashboard tracking HTTP RPS (Requests per Second), SQL QPS (Queries per Second), HTTP Errors, and average latency.
- **System Health Monitor** — Operating system resource sampling: CPU usage (%), physical memory (Working Set in MB), active thread count, and active DB connections.
- **Non-Blocking Persistence** — Serialized metrics are appended to a ring buffer and written to `metrics.json` every 30s via the async background timer.

### 19.3 Database & Outbound HTTP Profiler (S27)
- **FireDAC Auto-Instrumentation** — Zero-coupling interception inside the DB driver layers (`Dext.Entity.Drivers.FireDAC.pas`), automatically capturing raw SQL queries (`db.statement`), query parameters (`db.params`), query elapsed execution times, and routing database exceptions.
- **Outbound HTTP Auto-Instrumentation** — Network call interception inside the Rest Client (`Dext.Net.RestClient.pas`), capturing target URLs, HTTP methods, response elapsed timings, HTTP status codes, and exceptions.
- **Context Inspector Drawer** — A sliding overlay panel in the Dashboard triggered by clicking any span node in the tree. Displays pretty-printed SQL statements, structured query parameters, copied cURL commands, and generic metadata tags.

### 19.4 Streamable Sessions & HTMX (S23)
- **IStreamableSessionManager** — SSE channel manager with automatic garbage collection (runs every 60s, evicting idle sessions after 30 minutes).
- **HTMX Fragment Swap** — Endpoints serving dynamic HTML fragments (e.g. `/sidecar/fragments/metrics`), allowing live DOM updates via HTMX without writing any client-side JavaScript.

---

*Dext Framework — Exhaustive Technical Map & Features Index. (Revision: May 28, 2026).*
