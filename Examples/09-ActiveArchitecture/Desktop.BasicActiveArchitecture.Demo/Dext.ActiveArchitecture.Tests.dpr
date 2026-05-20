program Dext.ActiveArchitecture.Tests;

{$IFNDEF TESTINSIGHT}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  Dext.MM,
  System.SysUtils,
  Dext.Testing,
  Dext.Utils,
  Dext.ActiveArchitecture.Entities in 'Domain\Dext.ActiveArchitecture.Entities.pas',
  Dext.ActiveArchitecture.Specifications in 'Domain\Dext.ActiveArchitecture.Specifications.pas',
  Dext.ActiveArchitecture.Domain in 'Domain\Dext.ActiveArchitecture.Domain.pas',
  Dext.ActiveArchitecture.Services in 'Infra\Dext.ActiveArchitecture.Services.pas',
  Dext.ActiveArchitecture.ViewModels in 'Presentation\Dext.ActiveArchitecture.ViewModels.pas',
  Dext.ActiveArchitecture.UnitTests in 'Tests\Dext.ActiveArchitecture.UnitTests.pas';

begin
  try
    SafeWriteLn;
    SafeWriteLn('========================================================');
    SafeWriteLn('          DEXT FRAMEWORK - DELPHI CONNECT PORTUGAL      ');
    SafeWriteLn('                SUITE DE TESTES UNITARIOS               ');
    SafeWriteLn('========================================================');
    SafeWriteLn;
    
    // Registra e executa todas as fixtures da nossa unit de testes
    TTest.SetExitCode(
      TTest.Configure
       {$IFDEF TESTINSIGHT}
       .UseTestInsight
       {$ENDIF}
       .Verbose
       .RegisterFixtures([
         TOrderDetailsTests,
         TOrderViewModelTests,
         TOrderSpecificationsTests
       ]).Run);
  except
    on E: Exception do
    begin
      SafeWriteLn('ERRO FATAL: ' + E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;

  ConsolePause;
end.
