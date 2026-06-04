# S33 — Persistent Background Jobs (Hangfire-style)

This architectural specification details the design of a persistent background job processor for Dext, enabling out-of-process, resilient asynchronous task execution (delayed, scheduled, recurring) with automatic persistence.

---

## 1. Context & Motivation

Dext currently supports in-memory background tasks via `IHostedService` and `TAsyncTask`. However, in-memory processing does not survive application crashes, restarts, or scale-out scenarios where workload needs to be balanced across multiple nodes.

A **Persistent Background Job** engine solves this by serializing job payloads (method names, target types, and parameters) and saving them to a persistent datastore (PostgreSQL, SQLite, or Redis) before execution.

---

## 2. Architectural Design

The background jobs ecosystem relies on three main components:

```
[Web/Client App] ➔ Enqueue ➔ [Database / Redis] ➔ Poll ➔ [Job Worker Pool]
```

### 1. The Job Storage (`IJobStorage`)
An abstraction for the persistent state.
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

## 3. Worker Concurrency & Lock Management

* **Distributed Locks**: To prevent duplicate runs in multi-instance environments, the server uses database-level pessimistic locks (e.g. `SELECT FOR UPDATE` or Redis distributed locks) when picking jobs.
* **Greedy Invocation**: Jobs are resolved using the IoC container. Dependencies are scoped per job invocation to ensure clean context lifecycles.
* **Automatic Retry**: If a job fails, the server schedules a retry with exponential backoff.

---

## 4. UI Dashboard (Dext Sidecar Integration)

The Dext Observability Sidecar is updated to display job queues:
- Real-time counters (Active, Enqueued, Succeeded, Failed).
- Execution logs (exceptions and stack traces for failed jobs).
- Ability to manually trigger a retry for a failed job.

---
*Dext Specifications — S33 Persistent Background Jobs | June 2026*
