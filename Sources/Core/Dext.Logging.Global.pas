{***************************************************************************}
{           Dext Framework                                                  }
{           Copyright (C) 2025 Cesar Romero & Dext Contributors             }
{***************************************************************************}
unit Dext.Logging.Global;

interface

uses
  System.SysUtils,
  System.Classes,
  Dext.Logging,
  Dext.Logging.Async,
  Dext.Logging.Sinks,
  Dext.Logging.Sinks.Sidecar,
  Dext.Logging.Telemetry,
  Dext.Options,
  Dext;

type
  /// <summary>
  ///   Provides a static entry point for application-wide logging.
  /// </summary>
  Log = class
  private
    class var FLogger: ILogger;
    class var FFactory: TAsyncLoggerFactory;
    class function GetLogger: ILogger; static;
  public
    class constructor Create;
    class destructor Destroy;
    
    /// <summary>
    ///   Initializes the global logger with default sinks (Console, File).
    ///   Calling this is optional; if not called, default config is used on first access.
    /// </summary>
    class procedure Initialize;
    
    /// <summary>
    ///   Adds a custom sink to the global logging pipeline.
    /// </summary>
    class procedure AddSink(const ASink: ILogSink);
    
    /// <summary>
    ///   Access the global logger instance.
    /// </summary>
    class property Logger: ILogger read GetLogger;
    
    // Convenience proxies (optional, but requested "Static Registry")
    
    class procedure Trace(const AMessage: string); overload;
    class procedure Trace(const AMessage: string; const AArgs: array of const); overload;
    
    class procedure Debug(const AMessage: string); overload;
    class procedure Debug(const AMessage: string; const AArgs: array of const); overload;
    
    class procedure Info(const AMessage: string); overload;
    class procedure Info(const AMessage: string; const AArgs: array of const); overload;
    
    class procedure Warn(const AMessage: string); overload;
    class procedure Warn(const AMessage: string; const AArgs: array of const); overload;
    
    class procedure Error(const AMessage: string); overload;
    class procedure Error(const AMessage: string; const AArgs: array of const); overload;
    class procedure Error(const AException: Exception; const AMessage: string; const AArgs: array of const); overload;
    
    class procedure Critical(const AMessage: string); overload;
    class procedure Critical(const AMessage: string; const AArgs: array of const); overload;
    class procedure Critical(const AException: Exception; const AMessage: string; const AArgs: array of const); overload;
    
    class procedure LogGeneric(ALevel: TLogLevel; const AMessage: string; const AArgs: array of const); overload;
    class procedure LogGeneric(ALevel: TLogLevel; const AException: Exception; const AMessage: string; const AArgs: array of const); overload;
    // ... add more as needed
  end;

implementation

{ Log }

class constructor Log.Create;
begin
  FLogger := nil;
  FFactory := nil;
end;

class destructor Log.Destroy;
begin
  FLogger := nil;
  if FFactory <> nil then
  begin
    FFactory.Dispose;
    FFactory.Free;
  end;
end;

class procedure Log.Initialize;
var
  PortStr: string;
  Port: Integer;
  SidecarUrl: string;
  Options: IOptions<TSidecarOptions>;
begin
  if FFactory <> nil then Exit; // Already initialized

  FFactory := TAsyncLoggerFactory.Create;
  
  // Default Sinks
  FFactory.AddSink(TConsoleSink.Create);

  // Sidecar Discovery
  Port := 3030;
  
  // 1. Environment Variable
  PortStr := GetEnvironmentVariable('DEXT_SIDECAR_PORT');
  if PortStr <> '' then 
    Port := StrToIntDef(PortStr, 3030);

  // 2. IOptions (if available via Default Provider)
  try
    Options := TDextServices.GetService<IOptions<TSidecarOptions>>(TDextServices.DefaultProvider);
    if (Options <> nil) and (Options.Value <> nil) then
    begin
      if Options.Value.Port <> 0 then
        Port := Options.Value.Port;
        
      if not Options.Value.Enabled then
      begin
        // Sidecar disabled via options
        FLogger := FFactory.CreateLogger('App');
        Exit;
      end;
    end;
  except
    // Provider might not be ready or Options not registered, ignore
  end;

  SidecarUrl := 'http://localhost:' + Port.ToString;
  WriteLn('>> [Log] Initializing Sidecar Sink at ', SidecarUrl);
  FFactory.AddSink(TSidecarSink.Create(SidecarUrl));
  TDiagnosticSource.Instance.Subscribe(TSidecarTelemetryObserver.Create(SidecarUrl));
  
  // Create the Logger instance
  FLogger := FFactory.CreateLogger('App');
  WriteLn('>> [Log] Logger initialized');
end;

class procedure Log.AddSink(const ASink: ILogSink);
begin
  if FFactory = nil then
    Initialize;
  FFactory.AddSink(ASink);
end;

class function Log.GetLogger: ILogger;
begin
  if FLogger = nil then
    Initialize;
  Result := FLogger;
end;

class procedure Log.Trace(const AMessage: string);
begin
  Logger.Trace(AMessage, []);
end;

class procedure Log.Trace(const AMessage: string; const AArgs: array of const);
begin
  Logger.Trace(AMessage, AArgs);
end;

class procedure Log.Debug(const AMessage: string);
begin
  Logger.Debug(AMessage, []);
end;

class procedure Log.Debug(const AMessage: string; const AArgs: array of const);
begin
  Logger.Debug(AMessage, AArgs);
end;

class procedure Log.Info(const AMessage: string);
begin
  Logger.Info(AMessage, []);
end;

class procedure Log.Info(const AMessage: string; const AArgs: array of const);
begin
  Logger.Info(AMessage, AArgs);
end;

class procedure Log.Warn(const AMessage: string);
begin
  Logger.Warn(AMessage, []);
end;

class procedure Log.Warn(const AMessage: string; const AArgs: array of const);
begin
  Logger.Warn(AMessage, AArgs);
end;

class procedure Log.Error(const AMessage: string);
begin
  Logger.Error(AMessage, []);
end;

class procedure Log.Error(const AMessage: string; const AArgs: array of const);
begin
  Logger.Error(AMessage, AArgs);
end;

class procedure Log.Error(const AException: Exception; const AMessage: string; const AArgs: array of const);
begin
  Logger.Error(AException, AMessage, AArgs);
end;

class procedure Log.Critical(const AMessage: string);
begin
  Logger.Critical(AMessage, []);
end;

class procedure Log.Critical(const AMessage: string; const AArgs: array of const);
begin
  Logger.Critical(AMessage, AArgs);
end;

class procedure Log.Critical(const AException: Exception; const AMessage: string; const AArgs: array of const);
begin
  Logger.Critical(AException, AMessage, AArgs);
end;

class procedure Log.LogGeneric(ALevel: TLogLevel; const AMessage: string; const AArgs: array of const);
begin
  Logger.Log(ALevel, AMessage, AArgs);
end;

class procedure Log.LogGeneric(ALevel: TLogLevel; const AException: Exception; const AMessage: string; const AArgs: array of const);
begin
  Logger.Log(ALevel, AException, AMessage, AArgs);
end;

end.
