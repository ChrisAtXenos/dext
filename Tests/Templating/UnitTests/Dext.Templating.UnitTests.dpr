program Dext.Templating.UnitTests;

{$APPTYPE CONSOLE}

uses
  Dext.MM,
  Dext.Core.Debug,
  System.SysUtils,
  Dext.Testing.Runner,
  Dext.Testing.Attributes,
  Dext.Testing.Fluent,
  Dext.Testing,
  Dext.Utils,
  Dext.Templating.Tests in 'Dext.Templating.Tests.pas';

begin
  try
    SafeWriteLn;
    SafeWriteLn('🧪 Dext Templating Unit Tests');
    SafeWriteLn('=============================');
    SafeWriteLn;

    RunTests(ConfigureTests
      .Verbose
      .RegisterFixtures([
        TTemplatingTests
      ]));
  except
    on E: Exception do
    begin
      SafeWriteLn('FATAL ERROR: ' + E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
