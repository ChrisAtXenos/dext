program Dext.AppBuilderTest;

uses
  Dext.MM,
  System.Classes,
  System.SysUtils,
  System.Rtti,
  Dext.DI.Interfaces,
  Dext.DI.Core,
  Dext.Web.Interfaces,
  Dext.Web.Builder,
  Dext.Web.Middleware,
  Dext.Logging,
  Dext.Logging.Console,
  Dext.Utils,
  Dext.Web.Mocks in '..\Common\Dext.Web.Mocks.pas';

{$APPTYPE CONSOLE}

{$R *.res}

var
  AppBuilder: IApplicationBuilder;
  Pipeline: TRequestDelegate;
  Context: IHttpContext;
  Services: IServiceCollection;
  ServiceProvider: IServiceProvider;
  ExceptionOptions: TExceptionHandlerOptions;
  LoggingOptions: THttpLoggingOptions;
begin
  SetConsoleCharSet;
  try
    Writeln('=== Testing ApplicationBuilder ===');

    // 1. Setup DI
    Services := TDextServiceCollection.Create;
    TDextServices.Create(Services).AddSingleton<ILogger, TConsoleLogger>;
    ServiceProvider := Services.BuildServiceProvider;

    // 2. Create application builder
    AppBuilder := TApplicationBuilder.Create(ServiceProvider);

    // 3. Configure pipeline
    ExceptionOptions := TExceptionHandlerOptions.Development;
    AppBuilder.UseMiddleware(TExceptionHandlerMiddleware, TValue.From(ExceptionOptions));
    
    LoggingOptions := THttpLoggingOptions.Default;
    AppBuilder.UseMiddleware(THttpLoggingMiddleware, TValue.From(LoggingOptions));
    
    AppBuilder.Map('/hello',
        procedure(Context: IHttpContext)
        begin
          Context.Response.Write('Hello from Dext ApplicationBuilder!');
        end);
        
    AppBuilder.Map('/time',
        procedure(Context: IHttpContext)
        begin
          Context.Response.Write('Server time: ' + DateTimeToStr(Now));
        end);

    // 4. Build pipeline
    Pipeline := AppBuilder.Build;

    // 5. Test requests
    Writeln('');
    Writeln('Testing /hello route:');
    Context := TMockFactory.CreateHttpContextWithServices('GET /hello', ServiceProvider);
    Pipeline(Context);

    Writeln('');
    Writeln('Testing /time route:');
    Context := TMockFactory.CreateHttpContextWithServices('GET /time', ServiceProvider);
    Pipeline(Context);

    Writeln('');
    Writeln('Testing unknown route:');
    Context := TMockFactory.CreateHttpContextWithServices('GET /unknown', ServiceProvider);
    Pipeline(Context);

    Writeln('');
    Writeln('=== All tests completed ===');

  except
    on E: Exception do
      Writeln('ERROR: ', E.ClassName, ': ', E.Message);
  end;

  Writeln('Press Enter to exit...');
  ConsolePause;
end.
