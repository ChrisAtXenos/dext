# S33 — Persistent Background Jobs (Hangfire-style)

**Status:** ✅ Finalized
**Phase:** Wave 2
**Implementation:** Implemented in `Dext.Core` (`Dext.BackgroundJobs.Intf/Config/Server/InMemory`) and `Dext.EF.Core` (`Dext.BackgroundJobs.Storage.Sqlite`)

---

## 1. Context & Motivation

Dext currently supports in-memory background tasks via `IHostedService` and `TAsyncTask`. However, in-memory processing does not survive application crashes, restarts, or scale-out scenarios where workload needs to be balanced across multiple nodes.

A **Persistent Background Job** engine solves this by serializing job payloads (method names, target types, and parameters) and saving them to a persistent datastore (PostgreSQL, SQLite, or Redis) before execution.

---

## 2. Architectural Design & Storage Adaptability

The background jobs ecosystem relies on three main components:

```
[Web/Client App] ➔ Enqueue ➔ [Job Storage (SQLite/Postgres/Redis)] ➔ Poll ➔ [Job Worker Pool]
```

### 1. The Job Storage (`IJobStorage`)
An abstraction for the persistent state, allowing modular implementations.
* **Provedores Suportados**:
  * `TSqliteJobStorage`: Default local engine using SQLite (no separate services required, ideal for single-instance, lightweight setups).
  * `TPostgreSqlJobStorage`: For robust SQL-based environments requiring concurrency and scalability.
  * `TInMemoryJobStorage`: Memory-only fallback, useful for local testing.
  * `TRedisJobStorage`: Deferred provider, to be implemented when Dext's modern Redis client is prioritized.
* **Metadata stored**: Job Type, Method Name, Parameter Payloads (JSON), State (Enqueued, Processing, Succeeded, Failed), Attempt Count, Retry Log, Queue Name.

### 2. The Job Client (`IJobClient`)
An interface used to register tasks.
* **Fire-and-Forget**: Enqueued immediately.
* **Delayed**: Executed after a specific `TTimeSpan` or at a scheduled `TDateTime`.
* **Recurring**: Executed periodically based on a Cron expression.

```pascal
TDextJobs.Enqueue<TEmailService>(
  procedure(Svc: TEmailService)
  begin
    Svc.SendWelcomeEmail(UserId);
  end);
```

### 3. The Job Server / Worker Pool (`TJobServer`)
An active background thread pool running inside `IHostedService` that polls the datastore, locks jobs, and invokes them using `TActivator` (DI container).

---

## 3. Configuration & Concurrency Management

All parameters are configurable via application settings files (e.g. `appsettings.json` or `applicationsettings.yml`).

### Configuration Schema Example
```json
{
  "Dext": {
    "BackgroundJobs": {
      "Storage": {
        "Provider": "SQLite", // SQLite, PostgreSQL, Redis, InMemory
        "ConnectionString": "DataSource=dext_jobs.db"
      },
      "Server": {
        "DistributedLocksEnabled": false, // Set to true only in multi-node scale-out setups
        "WorkerCount": 4,
        "PollIntervalInSeconds": 5
      }
    }
  }
}
```

### Concurrency Modes
* **Simple Non-Distributed Mode (`DistributedLocksEnabled: false`)**: 
  Designed for single-instance applications. Concurrency is managed locally using lightweight thread coordination (e.g. `TCriticalSection` or `TMonitor`) and local database transactions to claim jobs.
* **Distributed Mode (`DistributedLocksEnabled: true`)**: 
  Designed for scale-out environments. The server uses database-level pessimistic locks (e.g. `SELECT FOR UPDATE SKIP LOCKED` in PostgreSQL) or distributed locks (e.g. Redlock in Redis) to prevent duplicate runs across instances.

---

## 4. UI Dashboard (Dext Sidecar Integration)

The Dext Observability Sidecar is updated to display job queues:
- Real-time counters (Active, Enqueued, Succeeded, Failed).
- Execution logs (exceptions and stack traces for failed jobs).
- Ability to manually trigger a retry for a failed job.

---
*Dext Specifications — S33 Persistent Background Jobs | June 2026*
