# Dext Logging Example: VCL Memo Sink

This example demonstrates how to integrate the **Dext Logging System** into a VCL application, specifically capturing logs and displaying them in a `TMemo` component.

## Key Features

1.  **Custom Sinks**: Shows how to implement the `ILogSink` interface to redirect logs to any target (in this case, a UI component).
2.  **Thread-Safety**: Demonstrates the use of `TThread.Queue` within the Sink to ensure that UI updates happen safely on the Main Thread, even though Dext's logging pipeline is fully asynchronous and background-processed.
3.  **Global Access**: Uses the `Log` static class for easy access from anywhere in the application.
4.  **Formatting**: Utilizes Dext's structured log formatting (e.g., `{Value}` placeholders).

## How it works

The core of the integration is the `TMemoLogSink` class:

```pascal
procedure TMemoLogSink.Emit(const Entry: TLogEntry);
begin
  // Format entry...
  TThread.Queue(nil,
    procedure
    begin
      FMemo.Lines.Add(LFormattedText);
    end);
end;
```

And registering it at application startup (or FormCreate):

```pascal
procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Log.AddSink(TMemoLogSink.Create(memoLogs));
end;
```

## Why use Dext Logging?

*   **Async by Design**: Logging never blocks the main UI thread or business logic.
*   **Structured**: Supports placeholders and metadata for future integration with tools like DataDog or OpenTelemetry.
*   **Lightweight**: Uses a high-performance RingBuffer to minimize contention between threads.

---
Part of the Dext Framework Examples.
