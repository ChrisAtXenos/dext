# Persistent Background Jobs

Persistent Background Jobs allow you to enqueue out-of-process, scheduled, or delayed tasks that survive application crashes and restarts. The engine automatically serializes the job parameters and saves them to a persistent datastore (such as SQLite or In-Memory).

Unlike raw `IHostedService` background tasks, Persistent Background Jobs are resilient, traceable, support automatic retries, and can be configured easily via `appsettings.json`.

---

## Configuration

Configure background jobs in your `appsettings.json`:

```json
{
  "Dext": {
    "BackgroundJobs": {
      "Storage": {
        "Provider": "SQLite", // "SQLite" or "InMemory"
        "ConnectionString": "DataSource=dext_jobs.db"
      },
      "Server": {
        "WorkerCount": 4,
        "PollIntervalInSeconds": 5
      }
    }
  }
}
```

---

## Registration

To enable background jobs, register them in your application startup using `AddBackgroundJobs`:

```pascal
uses
  Dext.DI.Interfaces,
  Dext.BackgroundJobs.Config;

procedure ConfigureServices(const Services: IServiceCollection);
begin
  // Register your job classes in DI
  Services.AddTransient<TEmailService>;

  // Registers job client and storage based on appsettings.json
  Services.AddBackgroundJobs;
end;
```

---

## Creating a Job Service

A background job is a method of a class registered in the DI container. The parameters must be simple types serializable to JSON.

```pascal
type
  TEmailService = class
  public
    procedure SendWelcomeEmail(const AEmail: string; const AUserId: Integer);
  end;

procedure TEmailService.SendWelcomeEmail(const AEmail: string; const AUserId: Integer);
begin
  // Send email logic here...
end;
```

---

## Enqueueing and Scheduling Jobs

Initialize the client helper `TDextJobs` and start enqueueing tasks.

### 1. Enqueue Immediately (Fire-and-Forget)

Executes as soon as a background worker becomes available.

```pascal
uses
  Dext.BackgroundJobs.Intf;

// Initialize TDextJobs with Resolved Job Client
var Client := ServiceProvider.GetRequiredService<IJobClient>;
TDextJobs.Initialize(Client);

// Enqueue immediately
var JobId := TDextJobs.Enqueue<TEmailService>('SendWelcomeEmail', ['user@example.com', 123]);
```

### 2. Schedule with a Delay

Executes after the specified time span has passed.

```pascal
uses
  System.TimeSpan,
  Dext.BackgroundJobs.Intf;

// Schedule to execute in 1 hour
var JobId := TDextJobs.Schedule<TEmailService>(
  'SendWelcomeEmail', 
  ['user@example.com', 123], 
  TTimeSpan.FromHours(1)
);
```

---

## Resiliency and Retries

If a job throws an exception during execution, the background job engine will:
1. Mark the job as failed.
2. Increment the `AttemptCount`.
3. In a future wave, exponential backoff retries will automatically retry the job execution.
4. Keep the exception details and stack trace in the `ErrorLog` column for troubleshooting.
