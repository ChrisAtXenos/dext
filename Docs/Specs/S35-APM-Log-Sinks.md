# S35 — APM Log Sinks & Unified Telemetry Pipeline (OTLP & Seq)

**Status:** ✅ Finalized (Implemented)

This architectural specification details the extension of Dext Logging and Telemetry to support asynchronous, batch-oriented pluggable sinks targeting centralized APM services (Seq, SigNoz, Datadog) via native protocols and standard OpenTelemetry (OTLP).

---

## 1. Context & Motivation

Dext currently supports local structured logging, ring buffers, and telemetry output via the Sidecar dashboard. However, production environments require logs, metrics, and execution traces to be aggregated in centralized Application Performance Monitoring (APM) tools.

Rather than building proprietary exporters for every APM platform on the market, Dext supports a dual-pipeline strategy:
1. **Seq Integration**: High-efficiency, developer-friendly structured logging using the Compact Log Event Format (CLEF). Ideal for local development, staging, and lightweight single-instance production setups.
2. **OpenTelemetry Protocol (OTLP)**: The cloud-native standard. By supporting OTLP over HTTP/JSON (and optionally gRPC), Dext telemetry connects out-of-the-box to **SigNoz** (our recommended open-source APM suite powered by ClickHouse), **Datadog**, **Grafana Loki/Tempo**, and any OpenTelemetry collector.

---

## 2. Architectural Design

The telemetry pipeline is non-blocking and batch-oriented to prevent network bottlenecks or application halts:

```
[Application Logger] 
        ➔ [Thread-Safe Ring Buffer Queue] 
        ➔ [TLogConsumerThread] 
        ➔ [TBatchingTelemetrySink] 
        ➔ (Async Batch HTTP Post) 
        ➔ [Seq / OpenTelemetry Collector (SigNoz/Datadog)]
```

### 1. Base Batching Sink (`TBatchingTelemetrySink`)
An abstract base class that buffers events, handles retries with exponential backoff via the Resilience Pipeline, and flushes data based on size or time limits.

```pascal
type
  TBatchingTelemetrySink = class(TInterfacedObject, ILogSink)
  private
    FQueue: TThreadSafeQueue<TLogEntry>;
    FBatchSize: Integer;
    FFlushIntervalMs: Integer;
    // ... thread execution and timer controls
  protected
    procedure Emit(const Entry: TLogEntry); virtual;
    procedure Flush; virtual;
    procedure SendBatch(const Batch: TArray<TLogEntry>); virtual; abstract;
  public
    constructor Create(const Options: TBatchOptions);
  end;
```

---

## 3. APM Providers & Protocols

### A. Seq Logger Sink (`TSeqLogSink`)
* **Protocol**: HTTP/JSON POST.
* **Format**: CLEF (Compact Log Event Format). Each log event is mapped as a single-line JSON object:
  ```json
  {"@t":"2026-06-06T13:30:00.000Z","@l":"Information","@mt":"User {UserId} logged in from {IP}","UserId":1024,"IP":"127.0.0.1"}
  ```
* **Default Endpoint**: `POST http://localhost:5341/api/events/raw?key=API_KEY`

### B. OpenTelemetry Protocol Sink (`TOTLPTelemetrySink`)
* **Protocol**: OTLP/HTTP (JSON or Protobuf payloads).
* **Endpoints**:
  * Logs: `POST /v1/logs`
  * Traces (APM spans): `POST /v1/traces`
* **Structure Alignment**:
  * **Resource Attributes**: Shared environment variables (`service.name`, `service.version`, `deployment.environment`).
  * **LogRecord**: Map `TLogEntry` attributes (timestamp, severity text, message body, context RTTI properties).
  * **SpanRecord**: Connects with Dext’s database profiler and web handler invoker to export tracing trees with spans representing queries, external HTTP calls, and route handlers.

---

## 4. Usage & Configuration Example

### Programmatic Registration
```pascal
// Register Seq for local logging
Log.AddSink(TSeqLogSink.Create(
  'http://localhost:5341', 
  'SECRET_API_KEY',
  TBatchOptions.Create.BatchSize(100).FlushInterval(5000)
));

// Register OpenTelemetry (SigNoz/Datadog Collector) for centralized tracing & logs
Telemetry.AddSink(TOTLPTelemetrySink.Create(
  'http://localhost:4318', // Default OTLP/HTTP collector port
  TTelemetryOptions.Create
    .ServiceName('DextCommerceAPI')
    .Environment('Production')
    .EnableTraces(True)
    .EnableLogs(True)
));
```

### JSON Configuration (`appsettings.json`)
```json
{
  "Dext": {
    "Telemetry": {
      "Seq": {
        "Enabled": true,
        "Endpoint": "http://localhost:5341",
        "ApiKey": "SECRET_API_KEY"
      },
      "OpenTelemetry": {
        "Enabled": true,
        "Endpoint": "http://localhost:4318",
        "ServiceName": "DextCommerceAPI",
        "Environment": "Production",
        "ExportLogs": true,
        "ExportTraces": true
      }
    }
  }
}
```

---
*Dext Specifications — S35 APM Log Sinks & Unified Telemetry | June 2026*
