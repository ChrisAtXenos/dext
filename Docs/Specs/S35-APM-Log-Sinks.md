# S35 — APM Log Sinks & Structured Logging Pipeline

This architectural specification details the extension of Dext Logging to support asynchronous, batch-oriented pluggable log sinks targeting centralized APM services (Seq, Elasticsearch, Datadog).

---

## 1. Context & Motivation

Dext currently supports in-memory structured logging, ring buffers, and local telemetry output via the Sidecar dashboard. However, production microservices and enterprise clusters require logs to be forwarded to centralized log management systems (APMs).

While creating custom `ILogSink` implementations is natively supported (such as `TMemoLogSink` in VCL), sending individual log entries immediately to external APIs causes blocking overhead and network saturation.

This specification details a thread-safe, batch-oriented HTTP log sink infrastructure designed to buffer log events and forward them asynchronously in batches.

---

## 2. Architectural Design

The pipeline introduces the base asynchronous HTTP logger sink:

```
[ILogger] ➔ [Ring Buffer] ➔ [TLogConsumerThread] ➔ [TBatchingLogSink] ➔ (Batch HTTP POST) ➔ [Seq/Elastic]
```

### 1. The Batching Sink Interface (`TBatchingLogSink`)
An abstract base class inheriting from `ILogSink`. It intercepts log entries, appends them to a thread-safe local queue, and schedules a periodic flush:

```pascal
type
  TBatchingLogSink = class(TInterfacedObject, ILogSink)
  protected
    procedure Emit(const Entry: TLogEntry); virtual;
    procedure Flush; virtual;
    procedure SendBatch(const Batch: IList<TLogEntry>); virtual; abstract;
  end;
```

---

## 3. Concrete APM Providers

### A. Seq Logger Sink (`TSeqLogSink`)
* **Format**: Converts log entries to CLEF (Compact Log Event Format) JSON structure.
* **Endpoint**: Batch POST to `/api/events/raw?key=API_KEY`.
* **Details**: Maps log levels, structured parameters, and exceptions automatically.

### B. Elasticsearch / OpenSearch Sink (`TElasticSearchLogSink`)
* **Format**: Converts entries to standard NDJSON (Newline Delimited JSON).
* **Endpoint**: Bulk API `POST /_bulk`.
* **Details**: Dynamic index naming based on UTC date (e.g. `dext-logs-2026-06-04`).

---

## 4. Usage Example

```pascal
Log.AddSink(TSeqLogSink.Create(
  'http://localhost:5341', 
  'MY_API_KEY',
  TBatchOptions.Create
    .BatchSize(100)      // Flush when 100 items are queued
    .FlushInterval(5000) // Or every 5 seconds
));
```

---
*Dext Specifications — S35 APM Log Sinks | June 2026*
