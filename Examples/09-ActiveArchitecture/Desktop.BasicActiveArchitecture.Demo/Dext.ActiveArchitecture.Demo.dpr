program Dext.ActiveArchitecture.Demo;

uses
  Dext.MM,
  Vcl.Forms,
  Dext.ActiveArchitecture.Startup in 'Infra\Dext.ActiveArchitecture.Startup.pas',
  Dext.ActiveArchitecture.Main.Form in 'Presentation\Dext.ActiveArchitecture.Main.Form.pas' {MainForm},
  Dext.ActiveArchitecture.Entities in 'Domain\Dext.ActiveArchitecture.Entities.pas',
  Dext.ActiveArchitecture.Specifications in 'Domain\Dext.ActiveArchitecture.Specifications.pas',
  Dext.Logging.Sinks.VCL in 'Infra\Dext.Logging.Sinks.VCL.pas',
  Dext.ActiveArchitecture.Domain in 'Domain\Dext.ActiveArchitecture.Domain.pas',
  Dext.ActiveArchitecture.Services in 'Infra\Dext.ActiveArchitecture.Services.pas',
  Dext.ActiveArchitecture.ViewModels in 'Presentation\Dext.ActiveArchitecture.ViewModels.pas';

{$R *.res}

begin
  // 1. Inicializa o contêiner de Injeção de Dependências global (Application Root)
  TStartup.Initialize;
  try
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    
    // 2. Cria o formulário principal usando o padrão oficial da VCL
    Application.CreateForm(TMainForm, MainForm);
    // 3. Injeta a ViewModel resolvida a partir do contêiner de DI do Dext
    MainForm.InjectDependencies(TStartup.GetOrderViewModel);
    
    Application.Run;
  finally
    // 4. Libera o formulário principal primeiro para desalocar referências
    MainForm.Free;
    
    // 5. Encerra e libera os recursos do contêiner de DI
    TStartup.Terminate;
  end;
end.
