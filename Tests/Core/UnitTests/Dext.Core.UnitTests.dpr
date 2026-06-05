program Dext.Core.UnitTests;

{$IFNDEF TESTINSIGHT}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  Dext.MM,
  Dext.Core.Debug,
  System.SysUtils,
  Dext.Testing.Runner,
  Dext.Testing.Attributes,
  Dext.Testing.Fluent,
  Dext.Testing,
  Dext.Utils,
  Dext.Json.Refactored.Tests in 'Dext.Json.Refactored.Tests.pas',
  Dext.Configuration.Features.Tests in 'Dext.Configuration.Features.Tests.pas',
  Dext.Configuration.Hashing.Tests in 'Dext.Configuration.Hashing.Tests.pas',
  Dext.Logging.Telemetry.Tests in 'Dext.Logging.Telemetry.Tests.pas',
  Dext.Json.Utf8.Serializer.Tests in 'Dext.Json.Utf8.Serializer.Tests.pas',
  Dext.Json.Regression.Tests in 'Dext.Json.Regression.Tests.pas',
  Dext.Json.RecordProperties.Tests in 'Dext.Json.RecordProperties.Tests.pas',
  Dext.Resilience.Tests in 'Dext.Resilience.Tests.pas',
  Dext.Validation.Fluent.Tests in 'Dext.Validation.Fluent.Tests.pas',
  Dext.BackgroundJobs.Tests in 'Dext.BackgroundJobs.Tests.pas',
  Dext.BackgroundJobs.Storage.Sqlite in '..\..\..\Sources\Data\Dext.BackgroundJobs.Storage.Sqlite.pas';

begin
  {$IFDEF TESTINSIGHT}
  HideConsoleIfAutocreated;
  {$ENDIF}
  SetConsoleCharSet();
  try
    SafeWriteLn;
    SafeWriteLn('🧪 Dext Core Unit Tests');
    SafeWriteLn('=======================');
    SafeWriteLn;

    RunTests(ConfigureTests
      .Verbose
      {$IFDEF TESTINSIGHT}
      .UseTestInsight
      {$ENDIF}
      .RegisterFixtures([
        TConfigFeaturesTests,
        TConfigurationHashingTests,
        TEntityMappingWarningTests,
        TJsonBugReproTests,
        TJsonInterfaceListTests,
        TJsonIssue108RegressionTests,
        TJsonIssue127RegressionTests,
        TJsonRecordPropertiesTests,
        TJsonRegressionTests,
        TResilienceTests,
        TTelemetryTests,
        TUtf8SerializerCurrencyTests,
        TValidationFluentTests,
        TBackgroundJobsTests
      ]));
  except
    on E: Exception do
    begin
      SafeWriteLn('FATAL ERROR: ' + E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
