# S32 — Resilience Pipeline & Fault Handling (Polly-style)

**Status: Finalized (Implemented)**

This architectural specification details the design of a generic, thread-safe resilience pipeline for Dext, enabling modern transient-fault handling (Retry, Circuit Breaker, Fallback, Timeout) across any I/O operation (HTTP, Database, Filesystem).

---

## 1. Context & Motivation

Applications in production operate in unstable environments: networks drop, database locks occur, and external HTTP APIs time out. Currently, Dext only supports simple HTTP retries inside the `TRestClient` layer.

The **Resilience Pipeline** decouples fault-handling policies from concrete execution logic. By treating policies as generic wrappers around delegates (`TProc` and `TFunc<T>`), developers can apply circuit breakers or fallback mechanisms to any process in a unified, non-intrusive way.

---

## 2. Architectural Design

The resilience engine operates as a pipeline of nested execution policies.

```
[Client Call] ➔ [Timeout Policy] ➔ [Circuit Breaker] ➔ [Retry Policy] ➔ [Actual Operation]
```

### 1. The Generic Pipeline (`IResiliencePipeline`)
A pipeline is an immutable execution flow configured via a fluent builder record to prevent allocations:

```pascal
var Pipeline := TResiliencePipeline.Create
  .AddRetry(3, 1000) // 3 retries, 1s delay
  .AddCircuitBreaker(5, 30000) // break after 5 errors, wait 30s
  .AddTimeout(5000); // timeout after 5s
```

### 2. Execution Delegates
The pipeline exposes overloads to execute standard synchronous or asynchronous procedures and functions:

```pascal
function Execute<T>(Action: TFunc<T>): T;
procedure Execute(Action: TProc);
```

---

## 3. Resilience Policies

### A. Retry Policy (`TRetryPolicy`)
* **Properties**: Max retries, sleep duration provider (constant, linear, exponential backoff with jitter).
* **Behavior**: Intercepts exceptions and retries the execution if the exception type matches a transient filter list.

### B. Circuit Breaker Policy (`TCircuitBreakerPolicy`)
* **Properties**: Failure threshold, duration of break (in milliseconds).
* **States**:
  * `Closed`: Normal operation. Failures increment a counter.
  * `Open`: Fails fast immediately by throwing `ECircuitBrokenException`.
  * `Half-Open`: Allows a trial execution. If it succeeds, closes the circuit. If it fails, re-opens it.

### C. Fallback Policy (`TFallbackPolicy`)
* **Properties**: Fallback action to execute.
* **Behavior**: Catches exceptions and returns a default or alternative value instead of failing.

---

## 4. Usage Example

```pascal
var
  Data: string;
begin
  Data := TResiliencePipeline.Create
    .AddRetry(3)
    .AddFallback<string>(function: string
      begin
        Result := '{"status": "offline"}';
      end)
    .Execute<string>(function: string
      begin
        Result := RestClient.Get('/status').Await.Content;
      end);
end;
```

---
*Dext Specifications — S32 Resilience Pipeline | June 2026*
