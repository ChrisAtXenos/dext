program WebStencilsDemo;

{$APPTYPE CONSOLE}

uses
  Dext.MM,
  System.SysUtils,
  Dext,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Utils,
  Startup in 'Startup.pas',
  Customer in 'Models\Customer.pas';

var
  App: IWebApplication;
  Provider: IServiceProvider;
begin
  SetConsoleCharset;
  try
    // Use the WebApplication helper for a cleaner setup
    App := WebApplication;
    
    // Register the startup class
    App.UseStartup(TStartup.Create);

    // Build services and seed database BEFORE running
    Writeln('🔧 Initializing services...');
    Provider := App.BuildServices;

    Writeln('📦 Setting up database...');
    TStartup.SeedData(Provider);

    // Run the application
    App.Run(5000);
  except
    on E: Exception do
    begin
      Writeln('❌ Error: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  ConsolePause;
end.
