unit Dext.Sidecar.TestInsight;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.IOUtils,
  System.SyncObjs,
  Dext.DI.Interfaces,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.WebHost,
  Dext.Web.Results,
  Dext.Logging;

type
  /// <summary>
  ///   TTestInsightCompatServer hosts the REST endpoint compatible with TestInsight client.
  /// </summary>
  TTestInsightCompatServer = class
  private
    FHost: IWebHost;
    FPort: Integer;
    FRunning: Boolean;
    class var FActiveSessionId: string;
    class var FSelectedTests: TArray<string>;
    class var FLock: TCriticalSection;
  public
    constructor Create(APort: Integer = 8102);
    destructor Destroy; override;

    procedure Start;
    procedure Stop;

    class procedure SetSelectedTests(const ATests: TArray<string>);
    class function GetSelectedTests: TArray<string>;

    property Port: Integer read FPort;
    property Running: Boolean read FRunning;
  end;

implementation

uses
  Dext.Dashboard.Routes,
  Dext.Utils;

{ TTestInsightCompatServer }

constructor TTestInsightCompatServer.Create(APort: Integer);
begin
  inherited Create;
  FPort := APort;
  FRunning := False;
  if FLock = nil then
    FLock := TCriticalSection.Create;
end;

destructor TTestInsightCompatServer.Destroy;
begin
  Stop;
  inherited;
end;

class procedure TTestInsightCompatServer.SetSelectedTests(const ATests: TArray<string>);
begin
  FLock.Enter;
  try
    FSelectedTests := ATests;
  finally
    FLock.Leave;
  end;
end;

class function TTestInsightCompatServer.GetSelectedTests: TArray<string>;
begin
  FLock.Enter;
  try
    Result := FSelectedTests;
  finally
    FLock.Leave;
  end;
end;

procedure TTestInsightCompatServer.Start;
begin
  if FRunning then Exit;
  FRunning := True;

  FHost := TWebHostBuilder.CreateDefault(nil)
    .UseUrls(Format('http://localhost:%d', [FPort]))
    .Configure(procedure(App: IApplicationBuilder)
      begin
        // Catch-all TestInsight POST/GET router middleware
        App.Use(procedure(Ctx: IHttpContext; Next: TRequestDelegate)
          var
            Path: string;
            SR: TStreamReader;
            Body: string;
            Streamer: IEventStreamer;
          begin
            Path := Ctx.Request.Path;
            Streamer := TDextServices.GetService<IEventStreamer>(Ctx.Services);

            // 1. GET /options or /api/options
            if Path.Contains('/options') then
            begin
              // Return standard options
              Ctx.Response.SetContentType('application/json; charset=utf-8');
              Ctx.Response.Write('{"executeTests":true,"showProgress":true}');
              Exit;
            end;

            // 2. GET /tests or /api/tests
            if Path.Contains('/tests') then
            begin
              // Return selected tests
              Ctx.Response.SetContentType('application/json; charset=utf-8');
              Ctx.Response.Write('[]');
              Exit;
            end;

            // 3. POST /postResult or general POST
            if SameText(Ctx.Request.Method, 'POST') then
            begin
              SR := TStreamReader.Create(Ctx.Request.Body);
              try
                Body := SR.ReadToEnd;
              finally
                SR.Free;
              end;

              if not Body.IsEmpty then
              begin
                // Standard TestInsight client might send JSON
                // Translate and broadcast SSE so Dashboard updates reactively
                if Streamer <> nil then
                begin
                  // Map raw legacy test status to active session
                  Streamer.PushEvent('test_complete', Body);
                end;
                
                // Also trigger legacy SSE broadcast
                TDashboardRoutes.BroadcastSSE('test_complete', Body);
              end;

              Ctx.Response.StatusCode := 200;
              Ctx.Response.Write('{"status":"ok"}');
              Exit;
            end;

            Next(Ctx);
          end);
      end)
    .Build;

  try
    FHost.Start;
  except
    on E: Exception do
    begin
      FRunning := False;
      // Fail silently if port 8102 is already occupied by the Delphi IDE TestInsight server
    end;
  end;
end;

procedure TTestInsightCompatServer.Stop;
begin
  if not FRunning then Exit;
  if FHost <> nil then
  begin
    try
      FHost.Stop;
    except
    end;
    FHost := nil;
  end;
  FRunning := False;
end;

initialization
  TTestInsightCompatServer.FActiveSessionId := 'Auto-Session';
  TTestInsightCompatServer.FSelectedTests := [];

finalization
  TTestInsightCompatServer.FLock.Free;

end.
