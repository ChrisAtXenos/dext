{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{                                                                           }
{           Copyright (C) 2026 Cesar Romero & Dext Contributors             }
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
unit Dext.Testing.DUnitX;

interface

uses
  System.SysUtils,
  Dext.Testing.Integration;

type
  TDUnitXRunnerIntegration = class(TInterfacedObject, ITestRunnerIntegration)
  public
    function GetName: string;
    procedure Execute(const APort: Integer);
  end;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.Net.HttpClient,
  System.JSON,
  DUnitX.TestFramework,
  DUnitX.Extensibility,
  DUnitX.Filters,
  DUnitX.TestRunner;

type
  TDextDUnitXLogger = class(TInterfacedObject, ITestLogger)
  private
    FBaseUrl: string;
    FClient: THTTPClient;
    FTestCount: Cardinal;
    procedure PostResult(const ResultType: string; const TestResult: ITestResult); overload;
    procedure PostResult(const ResultType: string; const TestName, FixtureName: string); overload;
  public
    constructor Create(const ABaseUrl: string);
    destructor Destroy; override;

    // ITestLogger Implementation
    procedure OnTestingStarts(const ThreadId: TThreadID; TestCount, TestActiveCount: Cardinal);
    procedure OnTestingEnds(const RunResults: IRunResults);
    procedure OnStartTestFixture(const ThreadId: TThreadID; const Fixture: ITestFixtureInfo);
    procedure OnEndTestFixture(const ThreadId: TThreadID; const Results: IFixtureResult);
    procedure OnBeginTest(const ThreadId: TThreadID; const Test: ITestInfo);
    procedure OnEndTest(const ThreadId: TThreadID; const Test: ITestResult);
    procedure OnLog(const LogType: TLogLevel; const Msg: string);
    procedure OnSetupFixture(const ThreadId: TThreadID; const Fixture: ITestFixtureInfo);
    procedure OnEndSetupFixture(const ThreadId: TThreadID; const Fixture: ITestFixtureInfo);
    procedure OnSetupTest(const ThreadId: TThreadID; const Test: ITestInfo);
    procedure OnEndSetupTest(const ThreadId: TThreadID; const Test: ITestInfo);
    procedure OnTeardownTest(const ThreadId: TThreadID; const Test: ITestInfo);
    procedure OnEndTeardownTest(const ThreadId: TThreadID; const Test: ITestInfo);
    procedure OnTearDownFixture(const ThreadId: TThreadID; const Fixture: ITestFixtureInfo);
    procedure OnEndTearDownFixture(const ThreadId: TThreadID; const Fixture: ITestFixtureInfo);
    procedure OnExecuteTest(const ThreadId: TThreadID; const Test: ITestInfo);
    procedure OnTestSuccess(const ThreadId: TThreadID; const Test: ITestResult);
    procedure OnTestFailure(const ThreadId: TThreadID; const Failure: ITestError);
    procedure OnTestError(const ThreadId: TThreadID; const Error: ITestError);
    procedure OnTestIgnored(const ThreadId: TThreadID; const AIgnored: ITestResult);
    procedure OnTestMemoryLeak(const ThreadId: TThreadID; const Test: ITestResult);
  end;

  TDextDUnitXFilter = class(TInterfacedObject, ITestFilter)
  private
    FSelectedTests: TDictionary<string, Boolean>;
    FSelectTest: Boolean;
    FBaseUrl: string;
    FClient: THTTPClient;
    procedure AddSkipped(const Test: ITest);
  public
    constructor Create(const ABaseUrl: string);
    destructor Destroy; override;
    function Match(const Test: ITest): Boolean;
    function IsEmpty: Boolean;
  end;

{ TDUnitXRunnerIntegration }

function TDUnitXRunnerIntegration.GetName: string;
begin
  Result := 'DUnitX';
end;

procedure TDUnitXRunnerIntegration.Execute(const APort: Integer);
var
  Url: string;
  Logger: TDextDUnitXLogger;
  Runner: ITestRunner;
  Results: IRunResults;
  Filter: ITestFilter;
  AndFilter: IAndFilter;
begin
  Url := 'http://localhost:' + APort.ToString + '/';

  Runner := TDUnitX.CreateRunner;
  Logger := TDextDUnitXLogger.Create(Url);
  Runner.AddLogger(Logger);

  Filter := TDextDUnitXFilter.Create(Url);
  if Assigned(TDUnitX.Filter) then
  begin
    AndFilter := TAndFilter.Create(TDUnitX.Filter);
    AndFilter.Add(Filter);
    Filter := AndFilter;
  end;
  TDUnitX.Filter := Filter;

  Runner.FailsOnNoAsserts := True;
  Runner.UseRTTI := True;
  Results := Runner.Execute;
  TDUnitX.Filter := nil;
end;

{ TDextDUnitXLogger }

constructor TDextDUnitXLogger.Create(const ABaseUrl: string);
begin
  inherited Create;
  FBaseUrl := ABaseUrl;
  FClient := THTTPClient.Create;
end;

destructor TDextDUnitXLogger.Destroy;
begin
  FClient.Free;
  inherited;
end;

procedure TDextDUnitXLogger.PostResult(const ResultType: string; const TestResult: ITestResult);
var
  JSONObj: TJSONObject;
  JSONArray: TJSONArray;
  PostStream: TStringStream;
  ErrorIntf: ITestError;
  ExceptionMsg: string;
  StackTrace: string;
  Duration: Cardinal;
begin
  JSONObj := TJSONObject.Create;
  try
    JSONObj.AddPair('resulttype', ResultType);
    JSONObj.AddPair('testname', TestResult.Test.Name);
    JSONObj.AddPair('fixturename', TestResult.Test.Fixture.Name);
    Duration := Trunc(TestResult.Duration.TotalMilliseconds);
    JSONObj.AddPair('duration', TJSONNumber.Create(Duration));

    ExceptionMsg := TestResult.Message;
    StackTrace := '';

    if TestResult.QueryInterface(ITestError, ErrorIntf) = 0 then
    begin
      if ResultType = 'Error' then
      begin
        if Assigned(ErrorIntf.ExceptionClass) then
          ExceptionMsg := Format('%s with message ''%s''', [ErrorIntf.ExceptionClass.ClassName, ErrorIntf.ExceptionMessage])
        else
          ExceptionMsg := ErrorIntf.ExceptionMessage;
      end;
      StackTrace := ErrorIntf.StackTrace;
    end;

    JSONObj.AddPair('exceptionmessage', ExceptionMsg);
    JSONObj.AddPair('unitname', TestResult.Test.Fixture.UnitName);
    if Assigned(TestResult.Test.Fixture.TestClass) then
      JSONObj.AddPair('classname', TestResult.Test.Fixture.TestClass.ClassName)
    else
      JSONObj.AddPair('classname', TestResult.Test.Fixture.Name);
    JSONObj.AddPair('methodname', TestResult.Test.MethodName);
    JSONObj.AddPair('linenumber', TJSONNumber.Create(0));
    JSONObj.AddPair('path', TestResult.Test.Fixture.FullName);
    JSONObj.AddPair('status', StackTrace);

    JSONArray := TJSONArray.Create;
    try
      JSONArray.AddElement(JSONObj);
      PostStream := TStringStream.Create(JSONArray.ToJSON, TEncoding.UTF8);
      try
        FClient.Post(FBaseUrl + 'tests/results', PostStream);
      finally
        PostStream.Free;
      end;
    finally
      JSONArray.Free;
    end;
  except
    // Silent fail
  end;
end;

procedure TDextDUnitXLogger.PostResult(const ResultType: string; const TestName, FixtureName: string);
var
  JSONObj: TJSONObject;
  JSONArray: TJSONArray;
  PostStream: TStringStream;
begin
  JSONObj := TJSONObject.Create;
  try
    JSONObj.AddPair('resulttype', ResultType);
    JSONObj.AddPair('testname', TestName);
    JSONObj.AddPair('fixturename', FixtureName);
    JSONObj.AddPair('duration', TJSONNumber.Create(0));
    JSONObj.AddPair('exceptionmessage', '');
    JSONObj.AddPair('unitname', '');
    JSONObj.AddPair('classname', FixtureName);
    JSONObj.AddPair('methodname', TestName);
    JSONObj.AddPair('linenumber', TJSONNumber.Create(0));
    JSONObj.AddPair('path', FixtureName);
    JSONObj.AddPair('status', '');

    JSONArray := TJSONArray.Create;
    try
      JSONArray.AddElement(JSONObj);
      PostStream := TStringStream.Create(JSONArray.ToJSON, TEncoding.UTF8);
      try
        FClient.Post(FBaseUrl + 'tests/results', PostStream);
      finally
        PostStream.Free;
      end;
    finally
      JSONArray.Free;
    end;
  except
    // Silent fail
  end;
end;

procedure TDextDUnitXLogger.OnTestingStarts(const ThreadId: TThreadID; TestCount, TestActiveCount: Cardinal);
begin
  FTestCount := TestCount;
  try
    FClient.Post(FBaseUrl + Format('tests/started?totalcount=%d', [FTestCount]), nil);
  except
    // Silent fail
  end;
end;

procedure TDextDUnitXLogger.OnTestingEnds(const RunResults: IRunResults);
begin
  try
    FClient.Post(FBaseUrl + 'tests/finished', nil);
  except
    // Silent fail
  end;
end;

procedure TDextDUnitXLogger.OnStartTestFixture(const ThreadId: TThreadID; const Fixture: ITestFixtureInfo);
begin
end;

procedure TDextDUnitXLogger.OnEndTestFixture(const ThreadId: TThreadID; const Results: IFixtureResult);
begin
end;

procedure TDextDUnitXLogger.OnBeginTest(const ThreadId: TThreadID; const Test: ITestInfo);
begin
  PostResult('Running', Test.Name, Test.Fixture.Name);
end;

procedure TDextDUnitXLogger.OnEndTest(const ThreadId: TThreadID; const Test: ITestResult);
begin
end;

procedure TDextDUnitXLogger.OnLog(const LogType: TLogLevel; const Msg: string);
begin
end;

procedure TDextDUnitXLogger.OnSetupFixture(const ThreadId: TThreadID; const Fixture: ITestFixtureInfo);
begin
end;

procedure TDextDUnitXLogger.OnEndSetupFixture(const ThreadId: TThreadID; const Fixture: ITestFixtureInfo);
begin
end;

procedure TDextDUnitXLogger.OnSetupTest(const ThreadId: TThreadID; const Test: ITestInfo);
begin
end;

procedure TDextDUnitXLogger.OnEndSetupTest(const ThreadId: TThreadID; const Test: ITestInfo);
begin
end;

procedure TDextDUnitXLogger.OnTeardownTest(const ThreadId: TThreadID; const Test: ITestInfo);
begin
end;

procedure TDextDUnitXLogger.OnEndTeardownTest(const ThreadId: TThreadID; const Test: ITestInfo);
begin
end;

procedure TDextDUnitXLogger.OnTearDownFixture(const ThreadId: TThreadID; const Fixture: ITestFixtureInfo);
begin
end;

procedure TDextDUnitXLogger.OnEndTearDownFixture(const ThreadId: TThreadID; const Fixture: ITestFixtureInfo);
begin
end;

procedure TDextDUnitXLogger.OnExecuteTest(const ThreadId: TThreadID; const Test: ITestInfo);
begin
end;

procedure TDextDUnitXLogger.OnTestSuccess(const ThreadId: TThreadID; const Test: ITestResult);
begin
  PostResult('Passed', Test);
end;

procedure TDextDUnitXLogger.OnTestFailure(const ThreadId: TThreadID; const Failure: ITestError);
begin
  PostResult('Failed', Failure);
end;

procedure TDextDUnitXLogger.OnTestError(const ThreadId: TThreadID; const Error: ITestError);
begin
  PostResult('Error', Error);
end;

procedure TDextDUnitXLogger.OnTestIgnored(const ThreadId: TThreadID; const AIgnored: ITestResult);
begin
  PostResult('Skipped', AIgnored);
end;

procedure TDextDUnitXLogger.OnTestMemoryLeak(const ThreadId: TThreadID; const Test: ITestResult);
begin
  PostResult('Warning', Test);
end;

{ TDextDUnitXFilter }

constructor TDextDUnitXFilter.Create(const ABaseUrl: string);
var
  Response: IHTTPResponse;
  JSONVal: TJSONValue;
  JSONObj: TJSONObject;
  JSONArray: TJSONArray;
  i: Integer;
  TestName: string;
begin
  inherited Create;
  FBaseUrl := ABaseUrl;
  FClient := THTTPClient.Create;
  FSelectedTests := TDictionary<string, Boolean>.Create;
  FSelectTest := False;

  try
    Response := FClient.Get(FBaseUrl + 'tests');
    if Response.StatusCode = 200 then
    begin
      JSONVal := TJSONObject.ParseJSONValue(Response.ContentAsString(TEncoding.UTF8));
      if Assigned(JSONVal) and (JSONVal is TJSONObject) then
      begin
        JSONObj := TJSONObject(JSONVal);
        JSONVal := JSONObj.GetValue('SelectedTests');
        if Assigned(JSONVal) and (JSONVal is TJSONArray) then
        begin
          JSONArray := TJSONArray(JSONVal);
          for i := 0 to JSONArray.Count - 1 do
          begin
            TestName := JSONArray.Items[i].Value;
            FSelectedTests.AddOrSetValue(TestName, True);
          end;
        end;
        JSONObj.Free;
      end;
    end;
  except
    // Silent fail
  end;
  FSelectTest := FSelectedTests.Count > 0;
end;

destructor TDextDUnitXFilter.Destroy;
begin
  FSelectedTests.Free;
  FClient.Free;
  inherited;
end;

procedure TDextDUnitXFilter.AddSkipped(const Test: ITest);
var
  JSONObj: TJSONObject;
  JSONArray: TJSONArray;
  PostStream: TStringStream;
  FixtureName: string;
  TestName: string;
begin
  FixtureName := Test.Fixture.Name;
  TestName := Test.Name;
  JSONObj := TJSONObject.Create;
  try
    JSONObj.AddPair('resulttype', 'Skipped');
    JSONObj.AddPair('testname', TestName);
    JSONObj.AddPair('fixturename', FixtureName);
    JSONObj.AddPair('duration', TJSONNumber.Create(0));
    JSONObj.AddPair('exceptionmessage', 'Not in selection');
    JSONObj.AddPair('unitname', Test.Fixture.UnitName);
    if Assigned(Test.Fixture.TestClass) then
      JSONObj.AddPair('classname', Test.Fixture.TestClass.ClassName)
    else
      JSONObj.AddPair('classname', FixtureName);
    JSONObj.AddPair('methodname', Test.MethodName);
    JSONObj.AddPair('linenumber', TJSONNumber.Create(0));
    JSONObj.AddPair('path', Test.Fixture.FullName);
    JSONObj.AddPair('status', 'Not in selection');

    JSONArray := TJSONArray.Create;
    try
      JSONArray.AddElement(JSONObj);
      PostStream := TStringStream.Create(JSONArray.ToJSON, TEncoding.UTF8);
      try
        FClient.Post(FBaseUrl + 'tests/results', PostStream);
      finally
        PostStream.Free;
      end;
    finally
      JSONArray.Free;
    end;
  except
    // Silent fail
  end;
end;

function TDextDUnitXFilter.Match(const Test: ITest): Boolean;
var
  TestName: string;
  Cls: TClass;
  Matched: Boolean;
begin
  if FSelectTest then
  begin
    TestName := Test.Fixture.FullName + '.' + Test.Name;
    if FSelectedTests.ContainsKey(TestName) then
      Exit(True);

    Matched := False;
    if Assigned(Test.Fixture.FixtureInstance) then
    begin
      Cls := Test.Fixture.FixtureInstance.ClassType;
      while Cls <> TObject do
      begin
        TestName := Cls.UnitName + '.' + Cls.ClassName + '.' + Test.MethodName;
        if FSelectedTests.ContainsKey(TestName) then
        begin
          Matched := True;
          Break;
        end;
        Cls := Cls.ClassParent;
      end;
    end;

    if Matched then
      Exit(True);

    Result := False;
    AddSkipped(Test);
  end
  else
    Result := True;
end;

function TDextDUnitXFilter.IsEmpty: Boolean;
begin
  Result := False;
end;

initialization
  TTestRunnerRegistry.RegisterIntegration(TDUnitXRunnerIntegration.Create);

end.
