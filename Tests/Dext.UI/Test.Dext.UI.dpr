program Test.Dext.UI;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Dext.MM,
  Dext.Utils,
  Dext.Testing,
  System.SysUtils,
  Dext.UI.Navigator.Tests in 'Dext.UI.Navigator.Tests.pas';

begin
  SetConsoleCharSet();
  try
    WriteLn;
    WriteLn('🧪 Dext Dext.UI.Navigator Tests');
    WriteLn('=====================================');
    WriteLn;

    var TestResult := TTest.Configure
      .Verbose
      .RegisterFixtures([
        TNavParamsTests,
        TNavigationResultTests,
        TNavigationContextTests,
        THistoryEntryTests
      ]).Run;

     if TestResult then
      ExitCode := 0
    else
      ExitCode := 1;
  except
    on E: Exception do
    begin
      WriteLn('FATAL ERROR: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
      WriteLn('Press Enter to exit...');
      ReadLn;
    end;
  end;
end.
