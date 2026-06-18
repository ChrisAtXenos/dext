# Native Server Engine

Dext Framework includes a native, high-performance HTTP server engine driver. This engine bypasses standard adapters and integrates directly with OS-level high-performance APIs:
- **Windows**: Uses kernel-mode HTTP Server API (`http.sys`) with asynchronous socket handling.
- **Linux**: Uses edge-triggered Linux epoll (`epoll`) system calls for non-blocking I/O event loops.

By selecting the native engine, you minimize user-space overhead, context switching, and achieve near-hardware HTTP throughput and resource efficiency.

## Key Benefits
1. **OS Kernel Integration**: `http.sys` manages TCP connections, SSL handshakes, and response caching inside the Windows kernel, saving user-space CPU cycles.
2. **Zero-Allocation HTTP Parser**: Dext uses a custom, highly optimized incremental HTTP parser (`TDextIocpHttpParser`) that extracts routing segments and headers without heap allocations.
3. **High Concurrency Event Loops**: On Linux, the epoll event loop handles thousands of connections per thread concurrently using non-blocking sockets.

## Configuration

To activate the native server, cast your `IWebHost` instance to `IWebApplication` and call `.UseNativeServer`:

```pascal
program MyProject;

{$APPTYPE CONSOLE}

uses
  Dext.WebHost,
  Dext.Web;

var
  Builder: IWebHostBuilder;
  Host: IWebHost;
begin
  Builder := TDextWebHost.CreateDefaultBuilder;

  Builder.Configure(
    procedure(App: IApplicationBuilder)
    begin
      App.MapGet('/',
        procedure(Context: IHttpContext)
        begin
          Context.Response.Write('Hello from Native Server!');
        end);
    end);

  Host := Builder.Build;

  // Configure Dext to use the Native HTTP.sys / epoll server engine
  (Host as IWebApplication).UseNativeServer;

  Host.Run;
end.
```

## Configuration Options

You can tune the native engine's behavior using `TServerEngineOptions`:

```pascal
var
  Options: TServerEngineOptions;
begin
  Options := TServerEngineOptions.Create;
  Options.IoThreadCount := 4; // Number of worker threads (defaults to CPU count)
  Options.QueueLimit := 1000;  // Backlog/queue limit for incoming requests
  
  // Apply options when initializing the builder
  // ...
end;
```

> [!WARNING]
> On Windows, running `http.sys` servers requires appropriate URL reservation permissions. If you bind to all interfaces (`0.0.0.0`), Dext will register the strong wildcard prefix `http://+:port/` which requires running the application as Administrator, or configuring a URL ACL namespace reservation via:
> ```cmd
> netsh http add urlacl url=http://+:5000/ user=Everyone
> ```
