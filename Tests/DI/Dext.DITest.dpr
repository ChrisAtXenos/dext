program Dext.DITest;

uses
  Dext.MM,
  Dext.Utils,
  System.SysUtils,
  Dext.DI.Interfaces,
  Dext.DI.Core;

{$APPTYPE CONSOLE}

{$R *.res}

type
  ILogger = interface
    ['{A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D}']
    procedure Log(const AMessage: string);
  end;

  TConsoleLogger = class(TInterfacedObject, ILogger)
  public
    procedure Log(const AMessage: string);
  end;

  IDataService = interface
    ['{B2C3D4E5-F6A7-4B8C-9D0E-1F2A3B4C5D6E}']
    function GetData: string;
  end;

  TDataService = class(TInterfacedObject, IDataService)
  private
    FLogger: ILogger;
  public
    constructor Create(ALogger: ILogger);
    function GetData: string;
  end;

{ TConsoleLogger }

procedure TConsoleLogger.Log(const AMessage: string);
begin
  Writeln('LOG: ', AMessage);
end;

{ TDataService }

constructor TDataService.Create(ALogger: ILogger);
begin
  inherited Create;
  FLogger := ALogger;
end;

function TDataService.GetData: string;
begin
  FLogger.Log('Getting data...');
  Result := 'Hello from DataService!';
end;

var
  Provider: IServiceProvider;
  Logger, Logger2: ILogger;
  DataService: IDataService;
begin
  SetConsoleCharSet(65001);
  try
    // Configurar serviços usando TDextServices (API fluente)
    Provider := TDextServices.New()
      .AddSingleton<ILogger, TConsoleLogger>()
      .AddTransient<IDataService, TDataService>(
        function(P: IServiceProvider): TObject
        begin
          Result := TDataService.Create(TDextServices.GetService<ILogger>(P));
        end
      )
      .BuildServiceProvider();

    // Resolver serviços usando métodos estáticos do TDextServices
    Logger := TDextServices.GetService<ILogger>(Provider);
    DataService := TDextServices.GetService<IDataService>(Provider);

    // Usar serviços
    if Assigned(Logger) then
      Logger.Log('Application started');

    if Assigned(DataService) then
      Writeln('Data: ', DataService.GetData);

    // Testar singleton - mesma instância
    Logger2 := TDextServices.GetService<ILogger>(Provider);
    if Logger = Logger2 then
      Writeln('✔ Singleton working - same instance')
    else
      Writeln('✘ Singleton broken - different instances');

  except
    on E: Exception do
      Writeln('Error: ', E.Message);
  end;

  ConsolePause;
end.
