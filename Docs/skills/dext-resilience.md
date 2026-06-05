# dext-resilience

Focused instructions for using the Dext Resilience Pipeline and Fault Handling framework (`Dext.Resilience`).

## Context & Load Trigger

Load this skill when:
- Defining or using transient-fault handling policies (Retry, Circuit Breaker, Fallback, Timeout)
- Integrating fault tolerance with external services, databases, or HTTP clients (`TRestClient`)
- Configuring pipeline executions for synchronous or asynchronous operations

---

## Core Principles

1. **Fluent Pipeline Creation**: Create pipelines using `TResiliencePipeline.Create` and chain policies together.
2. **Immutable Record Design**: `TResiliencePipeline` is an immutable record structure designed to minimize heap allocation overhead.
3. **Decoupled Execution**: Policies wrap standard execution delegates (`TProc`, `TFunc<T>`), completely independent of the execution context (HTTP, DB, or disk).

---

## Code Patterns & Examples

### 1. Simple Retry Policy
Retries failed executions with customizable attempts and delays.

```pascal
var Pipeline := TResiliencePipeline.Create
  .AddRetry(3, 100); // 3 attempts, 100ms base delay
```

### 2. Circuit Breaker Policy
Fails fast when failures cross thresholds, protecting downstream systems.
- **Closed**: Execution flows normally.
- **Open**: Throws `ECircuitBrokenException` immediately.
- **Half-Open**: Trial state after break duration.

```pascal
var Pipeline := TResiliencePipeline.Create
  .AddCircuitBreaker(2, 1000); // 2 failures trip breaker, stay open for 1000ms
```

### 3. Fallback Policy
Catches exceptions and returns alternative values or executes recovery actions.

```pascal
var Pipeline := TResiliencePipeline.Create
  .AddFallback<string>(function: string
    begin
      Result := 'fallback-value';
    end);
```

### 4. Timeout Policy
Enforces a maximum execution duration using cooperative async tasks. Throws `ETimeoutException` on timeout.

```pascal
var Pipeline := TResiliencePipeline.Create
  .AddTimeout(500); // 500ms timeout
```

### 5. Executing Synchronous and Generic Tasks
The pipeline supports generic and non-generic overloads for `Execute`:

```pascal
// Executing procedure
Pipeline.Execute(procedure
  begin
    PerformAction;
  end);

// Executing generic function
var Value := Pipeline.Execute<string>(function: string
  begin
    Result := FetchRemoteData;
  end);
```

---

## RestClient Integration

`TRestClient` integrates directly with the resilience framework. Pre-existing fluent methods `.Retry()` and `.Timeout()` configure the pipeline internally, but you can also pass a custom pipeline:

```pascal
var CustomPipeline := TResiliencePipeline.Create
  .AddRetry(3)
  .AddFallback<IRestResponse>(function: IRestResponse
    begin
      Result := TMockResponse.Create(503, 'Temporarily Unavailable');
    end);

var Resp := RestClient('https://api.example.com')
  .ResiliencePipeline(CustomPipeline)
  .Get('/endpoint')
  .Await;
```
