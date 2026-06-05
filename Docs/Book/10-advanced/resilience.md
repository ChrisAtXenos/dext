# Resilience Pipeline & Fault Handling

Dext provides a decoupled, thread-safe resilience framework (`Dext.Resilience`) inspired by .NET's Polly. It allows developers to define execution policies (Retry, Circuit Breaker, Fallback, Timeout) and apply them to any I/O or CPU-bound operation using a fluent API.

---

## 1. Getting Started

To use the resilience pipeline, add `Dext.Resilience` to your uses clause:

```pascal
uses
  System.SysUtils,
  Dext.Resilience;
```

You configure a pipeline using `TResiliencePipeline.Create` and chain policies together. A pipeline is a lightweight, immutable record structure to avoid unnecessary heap allocations.

```pascal
var Pipeline := TResiliencePipeline.Create
  .AddRetry(3, 100)               // 3 retries, 100ms base delay
  .AddCircuitBreaker(5, 30000)   // trip breaker after 5 errors, wait 30s
  .AddTimeout(5000);             // timeout after 5s
```

---

## 2. Core Policies

### A. Retry Policy (`TRetryPolicy`)
The Retry Policy automatically retries failed operations. It supports linear or exponential backoff with random jitter to prevent "thundering herd" problems on downstream services.

```pascal
// Retry 3 times, waiting 50ms, 100ms, 150ms...
var Pipeline := TResiliencePipeline.Create.AddRetry(3, 50);
```

### B. Circuit Breaker Policy (`TCircuitBreakerPolicy`)
The Circuit Breaker prevents an application from repeatedly trying an operation that is likely to fail.
- **Closed**: Normal execution. Failures increment the failure counter.
- **Open**: The circuit trips when the failure threshold is reached. Subsequent calls fail fast immediately, throwing `ECircuitBrokenException`.
- **Half-Open**: Once the break duration expires, the circuit enters a trial state. A single successful call closes the circuit; any failure returns it to the `Open` state.

```pascal
// Trip breaker after 2 consecutive failures; keep it open for 1000ms
var Pipeline := TResiliencePipeline.Create.AddCircuitBreaker(2, 1000);
```

### C. Fallback Policy (`TFallbackPolicy`)
The Fallback Policy intercepts exceptions and executes an alternative block or returns a default value, ensuring the system degrades gracefully.

```pascal
var Pipeline := TResiliencePipeline.Create
  .AddFallback<string>(function: string
    begin
      Result := 'default-value';
    end);

var Value := Pipeline.Execute<string>(function: string
  begin
    raise Exception.Create('Primary service error');
  end); // Returns 'default-value'
```

### D. Timeout Policy (`TTimeoutPolicy`)
The Timeout Policy enforces a maximum duration on execution. It runs the operation asynchronously using a cooperative task cancellation model and throws `ETimeoutException` if the time limit is exceeded.

```pascal
var Pipeline := TResiliencePipeline.Create.AddTimeout(100);

try
  Pipeline.Execute(procedure
    begin
      Sleep(200); // Exceeds timeout
    end);
except
  on E: ETimeoutException do
    // Handle timeout
end;
```

---

## 3. Executing the Pipeline

The pipeline supports synchronous actions (procedures and functions) using strongly-typed generic execute overloads:

### A. Executing Procedures (No Return Value)
```pascal
Pipeline.Execute(procedure
  begin
    // Do work
  end);
```

### B. Executing Functions (With Return Value)
```pascal
var Res: Integer := Pipeline.Execute<Integer>(function: Integer
  begin
    Result := PerformCalculation();
  end);
```

---

## 4. Integration with RestClient

Dext's `TRestClient` natively integrates this resilience pipeline. The client-level `.Retry()` and `.Timeout()` methods configure this engine under the hood. You can also assign a custom pre-configured pipeline directly:

```pascal
var CustomPipeline := TResiliencePipeline.Create
  .AddRetry(3)
  .AddFallback<IRestResponse>(function: IRestResponse
    begin
      Result := TMockResponse.Create(503, 'Service Temporarily Unavailable');
    end);

var Resp := RestClient('https://api.example.com')
  .ResiliencePipeline(CustomPipeline)
  .Get('/data')
  .Await;
```
