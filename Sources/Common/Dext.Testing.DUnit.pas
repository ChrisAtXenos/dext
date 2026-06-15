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
unit Dext.Testing.DUnit;

interface

uses
  System.SysUtils,
  Dext.Testing.Integration;

type
  TDUnitRunnerIntegration = class(TInterfacedObject, ITestRunnerIntegration)
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
  System.Rtti,
  System.TypInfo,
  TestFramework;

type
  TAbstractTestAccess = class(TAbstractTest);

  TDextDUnitListener = class(TInterfacedObject, IStatusListener, ITestListener, ITestListenerX)
  private
    FBaseUrl: string;
    FClient: THTTPClient;
    FSelectTest: Boolean;
    FSelectedTests: TDictionary<string, Boolean>;
    FSelectedTest: string;
    FLastError: ITest;
    FPath: string;
    procedure PostResult(const ResultType: string; const Test: ITest; const APath: string); overload;
    procedure PostResult(const ResultType: string; const Failure: TTestFailure; const APath: string); overload;
    function Matches(const Test: ITest): Boolean;
    function GetMethodName(const Test: ITest): string;
    function GetTestClass(const Test: ITest): TClass;
    function GetFixtureName(const Test: ITest): string;
  protected
    // IStatusListener
    procedure Status(test: ITest; const msg: string);
    // ITestListener
    procedure StartTest(test: ITest);
    procedure AddSuccess(test: ITest);
    procedure AddError(error: TTestFailure);
    procedure AddFailure(failure: TTestFailure);
    procedure EndTest(test: ITest);
    // ITestListenerX
    procedure TestingStarts;
    procedure TestingEnds(testResult: TTestResult);
    procedure StartSuite(suite: ITest);
    procedure EndSuite(suite: ITest);
  public
    constructor Create(const ABaseUrl: string);
    destructor Destroy; override;
  end;

{ TDUnitRunnerIntegration }

function TDUnitRunnerIntegration.GetName: string;
begin
  Result := 'DUnit';
end;

procedure TDUnitRunnerIntegration.Execute(const APort: Integer);
var
  Url: string;
  Suite: ITestSuite;
  TestResult: TTestResult;
  Listener: ITestListener;
begin
  Url := 'http://127.0.0.1:' + APort.ToString + '/';

  Suite := RegisteredTests;
  if not Assigned(Suite) then Exit;

  TestResult := TTestResult.Create;
  try
    TestResult.FailsIfNoChecksExecuted := True;
    TestResult.FailsIfMemoryLeaked := True;
    Listener := TDextDUnitListener.Create(Url);
    TestResult.AddListener(Listener);
    Suite.Run(TestResult);
  finally
    TestResult.Free;
  end;
end;

{ TDextDUnitListener }

constructor TDextDUnitListener.Create(const ABaseUrl: string);
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
  FSelectedTest := '';
  FPath := '';

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

  if FSelectedTests.Count = 1 then
  begin
    for TestName in FSelectedTests.Keys do
      FSelectedTest := TestName;
  end;
  FSelectTest := FSelectedTests.Count > 0;
end;

destructor TDextDUnitListener.Destroy;
begin
  FSelectedTests.Free;
  FClient.Free;
  inherited;
end;

function TDextDUnitListener.GetMethodName(const Test: ITest): string;
begin
  if Test is TAbstractTest then
    Result := TAbstractTestAccess(Test as TAbstractTest).FTestName
  else
    Result := SplitString(Test.Name, '(')[0];
end;

function TDextDUnitListener.GetTestClass(const Test: ITest): TClass;
  function FindMethod(Cls: TClass; const MethodName: string): TClass;
  var
    Context: TRttiContext;
    RttiType: TRttiType;
    Method: TRttiMethod;
  begin
    Context := TRttiContext.Create;
    while Assigned(Cls) and (Cls <> TTestCase) do
    begin
      RttiType := Context.GetType(Cls);
      if Assigned(RttiType) then
      begin
        for Method in RttiType.GetDeclaredMethods do
        begin
          if (Method.Visibility = mvPublished) and SameText(Method.Name, MethodName) then
            Exit(Cls);
        end;
      end;
      Cls := Cls.ClassParent;
    end;
    Result := nil;
  end;
var
  MethodName: string;
  Obj: TObject;
begin
  MethodName := GetMethodName(Test);
  Obj := Test as TObject;
  Result := FindMethod(Obj.ClassType, MethodName);
  if Result = nil then
    Result := Obj.ClassType;
end;

function TDextDUnitListener.GetFixtureName(const Test: ITest): string;
begin
  Result := (Test as TObject).ClassName;
end;

function TDextDUnitListener.Matches(const Test: ITest): Boolean;
var
  TestName: string;
  Cls: TClass;
  Obj: TObject;
begin
  Obj := Test as TObject;
  Cls := Obj.ClassType;
  while (Cls <> TTestCase) and (Cls <> TObject) do
  begin
    TestName := Cls.UnitName + '.' + Cls.ClassName + '.' + GetMethodName(Test);
    if FSelectedTests.ContainsKey(TestName) then
      Exit(True);

    TestName := Cls.ClassName + '.' + GetMethodName(Test);
    if FSelectedTests.ContainsKey(TestName) then
      Exit(True);

    Cls := Cls.ClassParent;
  end;
  Result := False;
end;

procedure TDextDUnitListener.PostResult(const ResultType: string; const Test: ITest; const APath: string);
var
  JSONObj: TJSONObject;
  JSONArray: TJSONArray;
  PostStream: TStringStream;
  TestClass: TClass;
begin
  JSONObj := TJSONObject.Create;
  try
    JSONObj.AddPair('resulttype', ResultType);
    JSONObj.AddPair('testname', Test.Name);
    JSONObj.AddPair('fixturename', GetFixtureName(Test));
    JSONObj.AddPair('duration', TJSONNumber.Create(Trunc(Test.ElapsedTestTime)));
    JSONObj.AddPair('exceptionmessage', '');
    TestClass := GetTestClass(Test);
    JSONObj.AddPair('unitname', TestClass.UnitName);
    JSONObj.AddPair('classname', TestClass.ClassName);
    JSONObj.AddPair('methodname', GetMethodName(Test));
    JSONObj.AddPair('linenumber', TJSONNumber.Create(0));
    JSONObj.AddPair('path', APath);
    JSONObj.AddPair('status', Test.Status);

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

procedure TDextDUnitListener.PostResult(const ResultType: string; const Failure: TTestFailure; const APath: string);
var
  JSONObj: TJSONObject;
  JSONArray: TJSONArray;
  PostStream: TStringStream;
  TestClass: TClass;
begin
  JSONObj := TJSONObject.Create;
  try
    JSONObj.AddPair('resulttype', ResultType);
    JSONObj.AddPair('testname', Failure.FailedTest.Name);
    JSONObj.AddPair('fixturename', GetFixtureName(Failure.FailedTest));
    JSONObj.AddPair('duration', TJSONNumber.Create(Trunc(Failure.FailedTest.ElapsedTestTime)));
    JSONObj.AddPair('exceptionmessage', Failure.ThrownExceptionMessage);
    TestClass := GetTestClass(Failure.FailedTest);
    JSONObj.AddPair('unitname', TestClass.UnitName);
    JSONObj.AddPair('classname', TestClass.ClassName);
    JSONObj.AddPair('methodname', GetMethodName(Failure.FailedTest));
    JSONObj.AddPair('linenumber', TJSONNumber.Create(0));
    JSONObj.AddPair('path', APath);
    JSONObj.AddPair('status', Failure.FailedTest.Status);

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

procedure TDextDUnitListener.Status(test: ITest; const msg: string);
begin
end;

procedure TDextDUnitListener.StartTest(test: ITest);
var
  JSONObj: TJSONObject;
  JSONArray: TJSONArray;
  PostStream: TStringStream;
  TestClass: TClass;
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
      TestClass := GetTestClass(test);
      JSONObj.AddPair('unitname', TestClass.UnitName);
      JSONObj.AddPair('classname', TestClass.ClassName);
      JSONObj.AddPair('methodname', GetMethodName(test));
      JSONObj.AddPair('linenumber', TJSONNumber.Create(0));
      JSONObj.AddPair('path', FPath);
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

procedure TDextDUnitListener.AddSuccess(test: ITest);
begin
  if (FLastError <> test) and IsTestMethod(test) then
    PostResult('Passed', test, FPath);
end;

procedure TDextDUnitListener.AddError(error: TTestFailure);
begin
  PostResult('Error', error, FPath);
  FLastError := error.FailedTest;
end;

procedure TDextDUnitListener.AddFailure(failure: TTestFailure);
begin
  PostResult('Failed', failure, FPath);
  FLastError := failure.FailedTest;
end;

procedure TDextDUnitListener.EndTest(test: ITest);
begin
end;

procedure TDextDUnitListener.TestingStarts;
  function PrepareTest(const test: ITest; var path: string): Boolean;
  var
    Suite: ITestSuite;
    Tests: IInterfaceList;
    i: Integer;
    FullTestPath: string;
  begin
    if Supports(test, ITestSuite, Suite) then
    begin
      if path <> '' then
        path := path + '.' + Suite.Name
      else if Suite <> RegisteredTests then
        path := Suite.Name;

      Result := False;
      tests := Suite.Tests;
      for i := 0 to tests.Count - 1 do
        Result := PrepareTest(ITest(tests[i]), path) or Result;

      SetLength(path, Length(path) - Length(Suite.Name) - 1);
    end
    else
    begin
      if path <> '' then
        FullTestPath := path + '.' + test.Name
      else
        FullTestPath := test.Name;

      Result := (not FSelectTest)
        or FSelectedTests.ContainsKey(FullTestPath)
        or FSelectedTests.ContainsKey(GetFixtureName(test) + '.' + test.Name)
        or (FSelectedTest <> '') and Matches(test);
    end;

    test.Enabled := Result;
  end;
var
  Path: string;
begin
  Path := '';
  try
    FClient.Post(FBaseUrl + Format('tests/started?totalcount=%d', [RegisteredTests.CountTestCases]), TStream(nil));
  except
    // Silent fail
  end;
  PrepareTest(RegisteredTests, Path);
end;

procedure TDextDUnitListener.TestingEnds(testResult: TTestResult);
begin
  try
    FClient.Post(FBaseUrl + 'tests/finished', TStream(nil));
  except
    // Silent fail
  end;
end;

procedure TDextDUnitListener.StartSuite(suite: ITest);
var
  Path: string;
  TestSuite: ITestSuite;
begin
  Path := FPath;
  if Path <> '' then
    Path := Path + '.' + Suite.Name
  else if not (Supports(Suite, ITestSuite, TestSuite) and (TestSuite = RegisteredTests)) then
    Path := Suite.Name;
  FPath := Path;
end;

procedure TDextDUnitListener.EndSuite(suite: ITest);
begin
  SetLength(FPath, Length(FPath) - Length(suite.Name) - 1);
end;

initialization
  TTestRunnerRegistry.RegisterIntegration(TDUnitRunnerIntegration.Create);

end.
