{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{                                                                           }
{           Copyright (C) 2025 Cesar Romero & Dext Contributors             }
{                                                                           }
{           Licensed under the Apache License, Version 2.0 (the "License"); }
{           you may not use this file except in compliance with the License.}
{           You may obtain a copy of the License at                         }
{                                                                           }
{               http://www.apache.org/licenses/LICENSE-2.0                  }
{                                                                           }
{           Unless required by applicable law or agreed to in writing,      }
{           software distributed under the License is distributed on an     }
{           "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,    }
{           either express or implied. See the License for the specific     }
{           language governing permissions and limitations under the        }
{           License.                                                        }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Author:  Cesar Romero                                                    }
{  Created: 2026-04-07                                                      }
{                                                                           }
{  Dext.Testing.TestInsight - IDE Integration Listener                      }
{***************************************************************************}
unit Dext.Testing.TestInsight;

{$IFDEF TESTINSIGHT}
  {$MESSAGE HINT 'Dext: TestInsight integration is enabled. Ensure TestInsight.Client.pas is in your Delphi Library Path.'}
{$ENDIF}

interface

uses
  System.SysUtils,
  Dext.Testing.Runner,
  System.SyncObjs,
//  System.Generics.Collections,
  TestInsight.Client;

type
  /// <summary>
  ///   TTestInsightListener reports test results back to the TestInsight IDE plugin.
  /// </summary>
  TTestInsightListener = class(TInterfacedObject, ITestListener)
  private
    FClient: ITestInsightClient;
    FFinishedEvent: TEvent;
    FEnabled: Boolean;
    function TryPost(const AResult: TTestInsightResult): Boolean;

  public
    constructor Create(const ABaseUrl: string = '');
    
    // ITestListener Implementation
    procedure OnRunStart(TotalTests: Integer);
    procedure OnRunComplete(const Summary: TTestSummary);
    procedure OnFixtureStart(const FixtureName: string; TestCount: Integer);
    procedure OnFixtureComplete(const FixtureName: string);
    procedure OnTestStart(const UnitName, Fixture, Test: string);
    procedure OnTestComplete(const Info: TTestInfo);
    
    function GetSelectedTests: TArray<string>;
    function GetOptions: TTestInsightOptions;
    function WaitForCompletion(Timeout: Cardinal): TWaitResult;
    property Enabled: Boolean read FEnabled;
    destructor Destroy; override;
  end;

implementation

uses
  Winapi.Windows,
  System.IOUtils,
  Dext.Utils;

procedure LogDebug(const AMsg: string);
begin
  // disabled
end;

constructor TTestInsightListener.Create(const ABaseUrl: string);
var
  ParentProcess: string;
  IsManualActivation: Boolean;
  LPortStr: string;
  LPort: Integer;
  LUrl: string;
begin
  inherited Create;
  
  ParentProcess := GetParentProcessName;
  IsManualActivation := FindCmdLineSwitch('X', ['-', '/'], True) or 
                           FindCmdLineSwitch('TestInsight', ['-', '/'], True);
                           
  LogDebug('TTestInsightListener.Create: ParentProcess=' + ParentProcess + ', IsManual=' + IsManualActivation.ToString);

  if (not IsManualActivation) and (ParentProcess <> 'bds.exe') then
  begin
     FEnabled := False;
     FFinishedEvent := TEvent.Create(nil, True, False, '');
     LogDebug('TTestInsightListener.Create: Not in IDE/Manual. Disabled.');
     Exit;
  end;

  TTestRunner.SetTestInsightActive(True);

  LPort := 8102;
  if FindCmdLineSwitch('port', LPortStr, True) or FindCmdLineSwitch('-port', LPortStr, True) then
    LPort := StrToIntDef(LPortStr, 8102);

  if ABaseUrl = '' then
    LUrl := 'http://127.0.0.1:' + LPort.ToString + '/'
  else
    LUrl := ABaseUrl;

  LogDebug('TTestInsightListener.Create: Connecting to ' + LUrl);
  FClient := TTestInsightRestClient.Create(LUrl);

  FEnabled := (FClient <> nil) and (not FClient.HasError);
  LogDebug('TTestInsightListener.Create: FClient created, Enabled=' + FEnabled.ToString);
  
  if FEnabled then
  begin
    try
       FClient.Options; 
       FEnabled := True;
       TTestRunner.SetTestInsightActive(True);
       LogDebug('TTestInsightListener.Create: Handshake Options success.');
    except
       on E: Exception do
       begin
         FEnabled := False;
         TTestRunner.SetTestInsightActive(False);
         LogDebug('TTestInsightListener.Create: Handshake Options failed: ' + E.Message);
       end;
    end;
  end;

  FFinishedEvent := TEvent.Create(nil, True, False, '');
end;

destructor TTestInsightListener.Destroy;
begin
  LogDebug('TTestInsightListener.Destroy called.');
  FFinishedEvent.Free;
  inherited;
end;

function TTestInsightListener.TryPost(const AResult: TTestInsightResult): Boolean;
begin
  Result := False;
  try
    FClient.PostResult(AResult, True);
    Result := True;
  except
    on E: Exception do;
  end;
end;


procedure TTestInsightListener.OnRunStart(TotalTests: Integer);
begin
  try
    LogDebug('TTestInsightListener.OnRunStart: TotalTests = ' + TotalTests.ToString);
  except
  end;
  if FEnabled then
    FClient.StartedTesting(TotalTests);
end;

procedure TTestInsightListener.OnRunComplete(const Summary: TTestSummary);
begin
  try
    LogDebug('TTestInsightListener.OnRunComplete: Completed');
  except
  end;
  try
    if FEnabled then
    begin
      FClient.FinishedTesting;
    end;
  finally
    if FFinishedEvent <> nil then
      FFinishedEvent.SetEvent;
  end;
end;

procedure TTestInsightListener.OnFixtureStart(const FixtureName: string; TestCount: Integer);
begin
  { Do nothing - reporting fixtures as tests causes duplicate nodes in IDE tree }
end;

procedure TTestInsightListener.OnFixtureComplete(const FixtureName: string);
begin
  { Do nothing }
end;

procedure TTestInsightListener.OnTestStart(const UnitName, Fixture, Test: string);
var
  TestResult: TTestInsightResult;
  LPath: string;
begin
  { Silence during Discovery Mode to avoid overwhelming the IDE }
  if TTestRunner.IsDiscoveryMode then
    Exit;

  if not FEnabled then
    Exit;

  try
    LogDebug('TTestInsightListener.OnTestStart: ' + Fixture + '.' + Test);
  except
  end;

  LPath := UnitName + '.' + Fixture;
  
  { Send "Running" status so the IDE can show the progress bar and highlight the active test }
  TestResult := TTestInsightResult.Create(TResultType.Running, Test, Fixture);
  TestResult.ClassName := Fixture;
  TestResult.UnitName := UnitName;
  TestResult.MethodName := Test;
  TestResult.Path := LPath;
  
  TryPost(TestResult);
end;

procedure TTestInsightListener.OnTestComplete(const Info: TTestInfo);
var
  ResultType: TResultType;
  TestResult: TTestInsightResult;
  LPath: string;
begin
  try
    LogDebug('TTestInsightListener.OnTestComplete: ' + Info.ClassName + '.' + Info.DisplayName + ' - Result: ' + Integer(Info.Result).ToString);
  except
  end;
  // Removed suppression to ensure TotalTests count matches reported results
  // if (Info.Result = trSkipped) and (Info.ErrorMessage = 'Not in selection') then
  //   Exit;
  case Info.Result of
    trNone:    ResultType := TResultType.Skipped;
    trPassed:  ResultType := TResultType.Passed;
    trFailed:  ResultType := TResultType.Failed;
    trError:   ResultType := TResultType.Error;
    trSkipped: ResultType := TResultType.Skipped;
    trTimeout: ResultType := TResultType.Error;
  else
    ResultType := TResultType.Skipped;
  end;

  LPath := Info.UnitName + '.' + Info.FixtureName;

  TestResult := TTestInsightResult.Create(ResultType, Info.DisplayName, Info.ClassName);
  TestResult.Duration := Trunc(Info.Duration.TotalMilliseconds);
  TestResult.ClassName := Info.ClassName;
  TestResult.UnitName := Info.UnitName;
  TestResult.MethodName := Info.TestName;
  TestResult.Path := LPath;
  
  { Attempt to get line numbers if a provider (JCL/MadExcept) is available }
  GetExtendedDetails(Info.CodeAddress, TestResult);
  
  if Info.Result in [trFailed, trError, trTimeout] then
  begin
    TestResult.ExceptionMessage := Info.ErrorMessage;
    TestResult.Status := Info.StackTrace;
  end
  else if Info.Result = trSkipped then
  begin
    TestResult.ExceptionMessage := Info.ErrorMessage;
    TestResult.Status := Info.ErrorMessage;
  end;

  if FEnabled then
  begin
    TryPost(TestResult);
  end;
end;

function TTestInsightListener.GetSelectedTests: TArray<string>;
var
  LTest: string;
begin
  Result := [];
  if not FEnabled then
  begin
    LogDebug('TTestInsightListener.GetSelectedTests: Not enabled, returning empty.');
    Exit;
  end;
  
  try
    Result := FClient.GetTests;
    LogDebug('TTestInsightListener.GetSelectedTests: Fetched ' + Length(Result).ToString + ' tests:');
    for LTest in Result do
      LogDebug('  - ' + LTest);
  except
    on E: Exception do
    begin
      LogDebug('TTestInsightListener.GetSelectedTests: Failed to fetch: ' + E.Message);
      Result := [];
    end;
  end;
end;

function TTestInsightListener.GetOptions: TTestInsightOptions;
begin
  if FEnabled then
  begin
    try
      Result := FClient.Options;
      LogDebug('TTestInsightListener.GetOptions: Options fetched successfully. ExecuteTests=' + Result.ExecuteTests.ToString);
    except
      on E: Exception do
      begin
        LogDebug('TTestInsightListener.GetOptions: Failed to fetch: ' + E.Message);
        Result.ExecuteTests := True;
        Result.ShowProgress := True;
      end;
    end;
  end
  else
  begin
    Result.ExecuteTests := True;
    Result.ShowProgress := True;
  end;
end;

function TTestInsightListener.WaitForCompletion(Timeout: Cardinal): TWaitResult;
begin
  if (not FEnabled) or (FFinishedEvent = nil) then
    Exit(wrSignaled);
    
  Result := FFinishedEvent.WaitFor(Timeout);
end;

end.
