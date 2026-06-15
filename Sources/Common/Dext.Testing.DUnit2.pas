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
unit Dext.Testing.DUnit2;

interface

uses
  System.SysUtils,
  Dext.Testing.Integration;

type
  TDUnit2RunnerIntegration = class(TInterfacedObject, ITestRunnerIntegration)
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
  System.StrUtils,
  TestFramework,
  TestFrameworkProxyIfaces,
  TestFrameworkIfaces,
  TestFrameworkProxy;

type
  TTestProxyAccess = class(TInterfacedObject, IInterface)
  private
    FITest: ITest;
  end;

  TDextDUnit2Listener = class(TInterfacedObject, IStatusListener, ITestListener, ITestListenerX)
  private
    FBaseUrl: string;
    FClient: THTTPClient;
    FSelectTest: Boolean;
    FSelectedTests: TDictionary<string, Boolean>;
    FTestCount: Cardinal;
    FLastError: ITestProxy;
    procedure PostResult(const ResultType: string; test: ITestProxy); overload;
    procedure PostResult(const ResultType: string; failure: TTestFailure); overload;
    function Matches(const test: ITest): Boolean;
    function GetTest(const testProxy: ITestProxy): ITest;
    function GetClassName(const test: ITestProxy): string;
    function GetFixtureName(const test: ITestProxy): string;
    function GetPath(const test: ITestProxy): string;
    function GetUnitName(const test: ITestProxy): string;
  protected
    // IStatusListener
    procedure Status(const test: ITestProxy; msg: string);
    // ITestListener
    procedure StartTest(test: ITestProxy);
    procedure AddSuccess(test: ITestProxy);
    procedure AddError(error: TTestFailure);
    procedure AddFailure(failure: TTestFailure);
    procedure AddWarning(warning: TTestFailure);
    procedure AddSkipped(test: ITestProxy);
    procedure EndTest(test: ITestProxy);
    // ITestListenerX
    procedure TestingStarts;
    procedure TestingEnds(testResult: TTestResult);
    procedure StartSuite(suite: ITestProxy);
    procedure EndSuite(suite: ITestProxy);
    function ShouldRunTest(const test: ITestProxy): Boolean;
  public
    constructor Create(const ABaseUrl: string; ATestCount: Cardinal);
    destructor Destroy; override;
  end;

{ TDUnit2RunnerIntegration }

function TDUnit2RunnerIntegration.GetName: string;
begin
  Result := 'DUnit2';
end;

procedure TDUnit2RunnerIntegration.Execute(const APort: Integer);
var
  Url: string;
  Suite: ITestSuiteProxy;
  TestResult: TTestResult;
  Listener: ITestListener;
begin
  Url := 'http://127.0.0.1:' + APort.ToString + '/';

  Suite := RegisteredTests;
  if not Assigned(Suite) then Exit;

  Listener := TDextDUnit2Listener.Create(Url, Suite.CountEnabledTestCases);
  try
    TestResult := RunTest(Suite, [Listener]);
  finally
    TestResult.ReleaseListeners;
  end;
end;

{ TDextDUnit2Listener }

constructor TDextDUnit2Listener.Create(const ABaseUrl: string; ATestCount: Cardinal);
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
  FTestCount := ATestCount;

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

destructor TDextDUnit2Listener.Destroy;
begin
  FSelectedTests.Free;
  FClient.Free;
  inherited;
end;

function TDextDUnit2Listener.GetTest(const testProxy: ITestProxy): ITest;
var
  Proxy: TTestProxyAccess;
begin
  Proxy := TTestProxyAccess(testProxy as TObject);
  Result := Proxy.FITest;
end;

function TDextDUnit2Listener.GetClassName(const test: ITestProxy): string;
begin
  Result := (GetTest(test).ParentTestCase as TObject).ClassName;
end;

function TDextDUnit2Listener.GetFixtureName(const test: ITestProxy): string;
begin
  Result := GetTest(test).ParentTestCase.DisplayedName;
end;

function TDextDUnit2Listener.GetPath(const test: ITestProxy): string;
begin
  Result := GetTest(test).ParentPath;
  Delete(Result, 1, Length(ExtractFileName(ParamStr(0))) + 1);
end;

function TDextDUnit2Listener.GetUnitName(const test: ITestProxy): string;
begin
  Result := (GetTest(test).ParentTestCase as TObject).UnitName;
end;

function TDextDUnit2Listener.Matches(const test: ITest): Boolean;
var
  TestName: string;
  Cls: TClass;
begin
  Cls := (test.ParentTestCase as TObject).ClassType;
  while (Cls <> TTestCase) and (Cls <> TObject) do
  begin
    TestName := Cls.UnitName + '.' + Cls.ClassName + '.' + test.GetName;
    if FSelectedTests.ContainsKey(TestName) then
      Exit(True);

    TestName := Cls.ClassName + '.' + test.GetName;
    if FSelectedTests.ContainsKey(TestName) then
      Exit(True);

    Cls := Cls.ClassParent;
  end;
  Result := False;
end;

function TDextDUnit2Listener.ShouldRunTest(const test: ITestProxy): Boolean;
var
  TestName: string;
begin
  if FSelectTest and IsTestMethod(test) then
  begin
    TestName := GetPath(test) + '.' + test.Name;

    if FSelectedTests.ContainsKey(TestName) then
      Exit(True);

    if Matches(GetTest(test)) then
      Exit(True);

    Result := False;
  end
  else
    Result := test.Enabled;
end;

procedure TDextDUnit2Listener.PostResult(const ResultType: string; test: ITestProxy);
var
  JSONObj: TJSONObject;
  JSONArray: TJSONArray;
  PostStream: TStringStream;
begin
  JSONObj := TJSONObject.Create;
  try
    JSONObj.AddPair('resulttype', ResultType);
    JSONObj.AddPair('testname', test.Name);
    JSONObj.AddPair('fixturename', GetFixtureName(test));
    JSONObj.AddPair('duration', TJSONNumber.Create(Trunc(test.ElapsedTestTime)));
    JSONObj.AddPair('exceptionmessage', '');
    JSONObj.AddPair('unitname', GetUnitName(test));
    JSONObj.AddPair('classname', GetClassName(test));
    JSONObj.AddPair('methodname', SplitString(test.Name, '(')[0]);
    JSONObj.AddPair('linenumber', TJSONNumber.Create(0));
    JSONObj.AddPair('path', GetPath(test));
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

procedure TDextDUnit2Listener.PostResult(const ResultType: string; failure: TTestFailure);
var
  JSONObj: TJSONObject;
  JSONArray: TJSONArray;
  PostStream: TStringStream;
begin
  JSONObj := TJSONObject.Create;
  try
    JSONObj.AddPair('resulttype', ResultType);
    JSONObj.AddPair('testname', failure.FailedTest.Name);
    JSONObj.AddPair('fixturename', GetFixtureName(failure.FailedTest));
    JSONObj.AddPair('duration', TJSONNumber.Create(Trunc(failure.FailedTest.ElapsedTestTime)));
    JSONObj.AddPair('exceptionmessage', failure.ThrownExceptionMessage);
    JSONObj.AddPair('unitname', GetUnitName(failure.FailedTest));
    JSONObj.AddPair('classname', GetClassName(failure.FailedTest));
    JSONObj.AddPair('methodname', failure.FailedTest.Name);
    JSONObj.AddPair('linenumber', TJSONNumber.Create(0));
    JSONObj.AddPair('path', GetPath(failure.FailedTest));
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

procedure TDextDUnit2Listener.Status(const test: ITestProxy; msg: string);
begin
end;

procedure TDextDUnit2Listener.StartTest(test: ITestProxy);
var
  JSONObj: TJSONObject;
  JSONArray: TJSONArray;
  PostStream: TStringStream;
begin
  if IsTestMethod(test) then
  begin
    JSONObj := TJSONObject.Create;
    try
      JSONObj.AddPair('resulttype', 'Running');
      JSONObj.AddPair('testname', test.Name);
      JSONObj.AddPair('fixturename', GetFixtureName(test));
      JSONObj.AddPair('duration', TJSONNumber.Create(0));
      JSONObj.AddPair('exceptionmessage', '');
      JSONObj.AddPair('unitname', GetUnitName(test));
      JSONObj.AddPair('classname', GetClassName(test));
      JSONObj.AddPair('methodname', test.Name);
      JSONObj.AddPair('linenumber', TJSONNumber.Create(0));
      JSONObj.AddPair('path', GetPath(test));
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
end;

procedure TDextDUnit2Listener.AddSuccess(test: ITestProxy);
begin
  if IsTestMethod(test) then
    PostResult('Passed', test);
end;

procedure TDextDUnit2Listener.AddError(error: TTestFailure);
begin
  PostResult('Error', error);
end;

procedure TDextDUnit2Listener.AddFailure(failure: TTestFailure);
begin
  PostResult('Failed', failure);
end;

procedure TDextDUnit2Listener.AddWarning(warning: TTestFailure);
begin
  PostResult('Warning', warning);
end;

procedure TDextDUnit2Listener.AddSkipped(test: ITestProxy);
begin
end;

procedure TDextDUnit2Listener.EndTest(test: ITestProxy);
begin
end;

procedure TDextDUnit2Listener.TestingStarts;
begin
  try
    FClient.Post(FBaseUrl + Format('tests/started?totalcount=%d', [FTestCount]), TStream(nil));
  except
    // Silent fail
  end;
end;

procedure TDextDUnit2Listener.TestingEnds(testResult: TTestResult);
begin
  try
    FClient.Post(FBaseUrl + 'tests/finished', TStream(nil));
  except
    // Silent fail
  end;
end;

procedure TDextDUnit2Listener.StartSuite(suite: ITestProxy);
begin
end;

procedure TDextDUnit2Listener.EndSuite(suite: ITestProxy);
begin
end;

initialization
  TTestRunnerRegistry.RegisterIntegration(TDUnit2RunnerIntegration.Create);

end.
