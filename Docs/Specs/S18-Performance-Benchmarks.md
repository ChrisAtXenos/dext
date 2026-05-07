# S18: Performance Benchmarks Specification

## Objective
Establish a formal performance benchmarking suite for the Dext Framework to prevent regressions and ensure that architectural improvements (like Smart Mapping and Generic Hydration) maintain an "Enterprise Grade" performance profile.

## Golden Metrics
Every benchmark must report:
1.  **Ops/sec**: Higher is better.
2.  **Latency (µs)**: Time per single operation (Average/P95).
3.  **Memory Alloc**: Bytes allocated per operation (should be near zero for core reflection).

---

## 1. Core Reflection & Cache
Since Dext relies on RTTI for almost everything, the reflection cache is the most critical point.

*   **Benchmark R01: Cache Hit Latency**
    *   Target: `TReflection.GetType` for the same type 1,000,000 times.
    *   Goal: Sub-microsecond latency.
*   **Benchmark R02: Field/Property Discovery**
    *   Target: Iterating over fields of a record with 50+ members.
    *   Goal: Validate that `GetFields` doesn't re-scan the RTTI pool every time.

## 2. TActivator & Dependency Resolution
The recent "Strategy B" for generic type resolution must be monitored to ensure it doesn't degrade as the number of registered types grows.

*   **Benchmark A01: Generic List Instantiation**
    *   Target: `TActivator.CreateInstance(TypeInfo(IList<T>))` vs `TList<T>.Create`.
    *   Acceptable Overhead: < 15%.
*   **Benchmark A02: Deep Dependency Tree**
    *   Target: Resolving a service with 5 levels of nested dependencies.
    *   Goal: Linear growth, not exponential.

## 3. JSON Engine (DOM vs. Streaming)
Validating the performance of the new pointer-based record assignment.

*   **Benchmark J01: Heavy Record Deserialization**
    *   Payload: JSON Array with 10,000 records containing nested lists.
    *   Goal: Compare `TDextJson` (DOM) against a baseline of raw JSON parsing.
*   **Benchmark J02: Attribute Overhead**
    *   Target: Serializing records with `[JsonName]` vs. direct mapping.
    *   Goal: Ensure attribute lookup is cached and doesn't impact throughput.

## 4. ORM & Hydration
The bridge between `TDataSet` and `Entities`.

*   **Benchmark H01: Bulk Hydration**
    *   Scenario: Mapping a 5,000-row `TDataSet` to `IList<TEntity>`.
    *   Focus: Field-to-Property mapping speed and `IsDirty` tracking overhead.
*   **Benchmark H02: Lazy Loading Proxy**
    *   Target: Accessing a lazy-loaded property for the first time.

## 5. Web Pipeline (Middleware & Routing)
The per-request overhead.

*   **Benchmark W01: Routing Lookup Speed**
    *   Scenario: Matching a URL against 500 registered routes (Static, Parametric, and Regex).
    *   Goal: Validate O(1) or O(log n) lookup performance.
*   **Benchmark W02: Middleware Chain Latency**
    *   Scenario: Executing a chain of 20 empty middlewares.
    *   Goal: Ensure the `Next()` delegate call doesn't create excessive stack/memory pressure.

---

## Implementation Strategy
1.  **Isolation**: Use a dedicated project `Tests/Performance/Dext.Benchmarks.dproj`.
2.  **Tooling**: Use **Dext.Testing** performance metrics. Custom attributes like `[PerformanceTest]` or `[IterationCount]` should be integrated if not already present.
3.  **Baseline**: Record results in a `PERF_BASELINE.json` file.
4.  **CI/CD Integration**: Run benchmarks on every Pull Request; fail if performance degrades by more than 10%.
