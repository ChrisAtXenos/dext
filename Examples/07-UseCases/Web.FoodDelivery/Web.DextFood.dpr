program Web.DextFood;

{$APPTYPE CONSOLE}

uses
  Dext.MM,
  System.SysUtils,
  Dext.Utils,
  Dext.Web,
  Dext.DI.Interfaces,
  DextFood.Startup in 'DextFood.Startup.pas',
  DextFood.Domain in 'DextFood.Domain.pas',
  DextFood.Services in 'DextFood.Services.pas',
  DextFood.DbSeeder in 'DextFood.DbSeeder.pas';

var
  App: IWebApplication;
  Provider: IServiceProvider;
begin
  SetConsoleCharSet;
  try
    Writeln('🚀 Iniciando DextFood Backend...');
    
    // Instancia a aplicação Dext
    App := TDextApplication.Create;
    
    // Configura a aplicação via classe Startup
    App.UseStartup(TStartup.Create);
    
    // OBRIGATÓRIO para SQLite :memory: ou Seeding manual:
    // Construir os serviços antes de rodar o seeder, para que ele use o Provider final.
    Provider := App.BuildServices;
    TDbSeeder.Seed(Provider);

    Writeln('🌐 Servidor ouvindo em: http://localhost:9000');
    Writeln('Endpoints disponíveis:');
    Writeln('  GET  /health');
    Writeln('  POST /api/orders');
    Writeln('  GET  /api/orders/high-value');
    Writeln('  CRUD /api/super-orders');
    Writeln;
    Writeln('Pressione Enter para encerrar.');
    
    // Inicia o servidor na porta 9000
    App.Run(9000);
    
  except
    on E: Exception do
      Writeln('❌ Erro crítico: ', E.ClassName, ': ', E.Message);
  end;
  ConsolePause;
end.

