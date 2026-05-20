unit Dext.ActiveArchitecture.Startup;

interface

uses
  System.SysUtils,
  Dext,
  Dext.DI.Interfaces,
  Dext.ActiveArchitecture.ViewModels;

type
  TStartup = class
  private
    class var FServiceProvider: IServiceProvider;
  public
    class procedure ConfigureServices(var Services: TDextServices); static;
    class procedure Initialize; static;
    class procedure Terminate; static;
    
    class function GetOrderViewModel: TOrderViewModel; static;
    
    class property ServiceProvider: IServiceProvider read FServiceProvider;
  end;

implementation

uses
  Dext.ActiveArchitecture.Domain, Dext.ActiveArchitecture.Services;

{ TStartup }

class procedure TStartup.ConfigureServices(var Services: TDextServices);
begin
  // Registra o serviço de frete externo como Singleton (compartilhado e offline-resiliente)
  Services.AddSingleton<IShippingService, TShippingService>;
  
  // Registra a ViewModel como Transient (uma nova instância a cada solicitação)
  Services.AddTransient<TOrderViewModel>;
end;

class procedure TStartup.Initialize;
var
  Services: TDextServices;
begin
  // Cria a coleção de serviços e inicializa o contêiner de DI do Dext
  Services := TDextServices.New;
  ConfigureServices(Services);
  FServiceProvider := Services.BuildServiceProvider;
end;

class procedure TStartup.Terminate;
begin
  FServiceProvider := nil;
end;

class function TStartup.GetOrderViewModel: TOrderViewModel;
begin
  // Resolve a ViewModel a partir do contêiner de DI do Dext
  Result := TDextServices.GetRequiredServiceObject<TOrderViewModel>(FServiceProvider);
end;

end.
