program Dext.Web.UnitTests;

{$IFNDEF TESTINSIGHT}
   {$APPTYPE CONSOLE}
{$ENDIF}

{$R *.res}

uses
  Dext.MM,
  System.SysUtils,
  Dext.Testing.Runner,
  Dext.Testing.Attributes,
  Dext.Testing.Fluent,
  Dext.Utils,
  Dext.Web.DataApi.Resolver.Tests in 'Dext.Web.DataApi.Resolver.Tests.pas',
  Dext.Web.DataApi.Tests in 'Dext.Web.DataApi.Tests.pas',
  Dext.Web.Json.Tests in 'Dext.Web.Json.Tests.pas',
  Dext.Web.Binding.Tests in 'Dext.Web.Binding.Tests.pas',
  Dext.Web.Features.Tests in 'Dext.Web.Features.Tests.pas',
  Dext.Web.DataApi.Utils.Tests in 'Dext.Web.DataApi.Utils.Tests.pas',
  Dext.Web.Hosting.Tests in 'Dext.Web.Hosting.Tests.pas';

var
  TestResult: Boolean;
begin
  SetConsoleCharSet();
  try
    SafeWriteLn;
    SafeWriteLn('🧪 Dext Web Unit Tests');
    SafeWriteLn('======================');
    SafeWriteLn;

    TestResult := TTest
      .Configure
      .Verbose
      {$IFDEF TESTINSIGHT}
      .UseTestInsight
      {$ENDIF}
      .RegisterFixtures([
        TWebBindingTests,
        TEntityIdResolverTests,
        TJsonNullableTests,
        TWebFeaturesTests,
        TDataApiNamingTests,
        TWebHostingTests,
        TDataApiConventionTests
      ]).Run;

    TTest.SetExitCode(TestResult);
  except
    on E: Exception do
    begin
      SafeWriteLn('FATAL ERROR: ' + E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;

  ConsolePause;
end.
