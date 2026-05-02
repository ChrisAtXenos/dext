program Dext.ScopedServicesTest;

{$APPTYPE CONSOLE}

uses
  Dext.MM,
  System.SysUtils,
  Dext.DI.Interfaces,
  Dext.DI.Middleware,
  Dext.Web.Interfaces,
  Dext.WebHost,
  Dext.Web.ApplicationBuilder.Extensions,
  Dext.Web.Results,
  Dext.Utils;

type
  // Interface for a request-scoped service
  IRequestContext = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function GetRequestId: string;
    procedure SetRequestId(const AValue: string);
    property RequestId: string read GetRequestId write SetRequestId;
  end;

  // Implementation of request-scoped service
  TRequestContext = class(TInterfacedObject, IRequestContext)
  private
    FRequestId: string;
  public
    constructor Create;
    function GetRequestId: string;
    procedure SetRequestId(const AValue: string);
  end;

  // A service that depends on the scoped service
  IGreetingService = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    function GetGreeting: string;
  end;

  TGreetingService = class(TInterfacedObject, IGreetingService)
  private
    FRequestContext: IRequestContext;
  public
    constructor Create(ARequestContext: IRequestContext);
    function GetGreeting: string;
  end;

{ TRequestContext }

constructor TRequestContext.Create;
begin
  inherited Create;
  FRequestId := TGUID.NewGuid.ToString;
  WriteLn('[RequestContext] Created new instance with ID: ' + FRequestId);
end;

function TRequestContext.GetRequestId: string;
begin
  Result := FRequestId;
end;

procedure TRequestContext.SetRequestId(const AValue: string);
begin
  FRequestId := AValue;
end;

{ TGreetingService }

constructor TGreetingService.Create(ARequestContext: IRequestContext);
begin
  inherited Create;
  FRequestContext := ARequestContext;
  WriteLn('[GreetingService] Created with RequestContext ID: ' + FRequestContext.RequestId);
end;

function TGreetingService.GetGreeting: string;
begin
  Result := Format('Hello from request %s!', [FRequestContext.RequestId]);
end;

var
  Host: IWebHost;
begin
  SetConsoleCharSet(65001);
  try
    WriteLn('=== Dext Scoped Services Test ===');
    WriteLn;

    Host := TDextWebHost.CreateDefaultBuilder
      .ConfigureServices(procedure(Services: IServiceCollection)
      begin
        WriteLn('Registering services...');
        
        // Register RequestContext as SCOPED (one instance per request)
        TDextServices.Create(Services).AddScoped<IRequestContext, TRequestContext>;
        
        // Register GreetingService as TRANSIENT (new instance every time, but gets the scoped RequestContext)
        TDextServices.Create(Services).AddTransient<IGreetingService, TGreetingService>;
        
        WriteLn('  IRequestContext registered as SCOPED');
        WriteLn('  IGreetingService registered as TRANSIENT');
        WriteLn;
      end)
      .Configure(procedure(App: IApplicationBuilder)
      begin
        WriteLn('Configuring middleware...');
        
        // IMPORTANT: Add Service Scope middleware FIRST
        // This creates a new scope for each HTTP request
        TApplicationBuilderScopeExtensions.UseServiceScope(App);
        
        WriteLn('  Service Scope middleware added');
        WriteLn;
        
        WriteLn('Configuring routes...');
        
        // Route 1: Test scoped service
        TApplicationBuilderExtensions.MapGetR<IGreetingService, IResult>(
          App,
          '/api/greeting',
          function(GreetingService: IGreetingService): IResult
          var
            Message: string;
          begin
            WriteLn('  [/api/greeting] Handler executing...');
            Message := GreetingService.GetGreeting;
            WriteLn('  [/api/greeting] Message: ' + Message);
            Result := Results.Json(Format('{"message":"%s"}', [Message]));
          end
        );
        
        // Route 2: Test that same scoped service is reused within request
        TApplicationBuilderExtensions.MapGetR<IRequestContext, IGreetingService, IResult>(
          App,
          '/api/test-scope',
          function(Ctx: IRequestContext; Greeting: IGreetingService): IResult
          begin
            WriteLn('  [/api/test-scope] Handler executing...');
            WriteLn('  [/api/test-scope] RequestContext ID: ' + Ctx.RequestId);
            WriteLn('  [/api/test-scope] Greeting: ' + Greeting.GetGreeting);
            
            Result := Results.Json(Format('{"requestId":"%s","message":"%s"}', 
              [Ctx.RequestId, Greeting.GetGreeting]));
          end
        );
        
        WriteLn('  Routes configured');
        WriteLn;
      end)
      .Build;

    WriteLn('===========================================');
    WriteLn('Server running on http://localhost:8080');
    WriteLn('===========================================');
    WriteLn;
    WriteLn('Test Commands:');
    WriteLn;
    WriteLn('curl http://localhost:8080/api/greeting');
    WriteLn('curl http://localhost:8080/api/test-scope');
    WriteLn;
    WriteLn('Expected behavior:');
    WriteLn('  - Each request should create a NEW RequestContext (different GUID)');
    WriteLn('  - Within the SAME request, the RequestContext ID should be IDENTICAL');
    WriteLn('  - The GreetingService should receive the SAME RequestContext instance');
    WriteLn;
    WriteLn('Press Enter to stop the server...');
    WriteLn;

    Host.Run;
    ConsolePause;

    WriteLn;
    WriteLn('Server stopped successfully');

  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ConsolePause;
    end;
  end;
end.
