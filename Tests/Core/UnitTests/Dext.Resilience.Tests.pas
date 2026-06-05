unit Dext.Resilience.Tests;

interface

uses
  System.SysUtils,
  Dext.Testing.Attributes,
  Dext.Assertions,
  Dext.Resilience;

type
  [TestFixture('Resilience Pipeline & Fault Handling Tests')]
  TResilienceTests = class
  public
    [Test('Should retry failed operations and succeed or fail accordingly')]
    procedure TestResilienceRetry;

    [Test('Should trip circuit breaker and block requests when failure threshold is reached')]
    procedure TestResilienceCircuitBreaker;

    [Test('Should execute fallback when an exception is thrown')]
    procedure TestResilienceFallback;

    [Test('Should timeout when operations exceed maximum duration')]
    procedure TestResilienceTimeout;
  end;

implementation

procedure TResilienceTests.TestResilienceRetry;
var
  Counter: Integer;
  Pipeline: TResiliencePipeline;
  Res: Integer;
  LFunc: TFunc<Integer>;
begin
  Counter := 0;
  Pipeline := TResiliencePipeline.Create.AddRetry(3, 10);
  LFunc := function: Integer
    begin
      Inc(Counter);
      if Counter < 3 then
        raise Exception.Create('Fail');
      Result := 42;
    end;
  Res := Pipeline.Execute<Integer>(LFunc);
  Should(Res).Be(42);
  Should(Counter).Be(3);
end;

procedure TResilienceTests.TestResilienceCircuitBreaker;
var
  Pipeline: TResiliencePipeline;
  CBExceptionCaught: Boolean;
  I: Integer;
begin
  Pipeline := TResiliencePipeline.Create.AddCircuitBreaker(2, 1000);
  
  // Fail first 2 times
  for I := 1 to 2 do
  begin
    try
      Pipeline.Execute(
        procedure
        begin
          raise Exception.Create('Fail');
        end
      );
    except
      on E: Exception do; // expected
    end;
  end;

  // 3rd call should throw ECircuitBrokenException immediately
  CBExceptionCaught := False;
  try
    Pipeline.Execute(
      procedure
      begin
        // shouldn't even execute
      end
    );
  except
    on E: ECircuitBrokenException do
      CBExceptionCaught := True;
  end;

  Should(CBExceptionCaught).BeTrue;
end;

procedure TResilienceTests.TestResilienceFallback;
var
  Pipeline: TResiliencePipeline;
  Res: string;
  LFallback: TFunc<string>;
  LFunc: TFunc<string>;
begin
  LFallback := function: string
    begin
      Result := 'fallback-value';
    end;
  Pipeline := TResiliencePipeline.Create.AddFallback<string>(LFallback);
      
  LFunc := function: string
    begin
      raise Exception.Create('Force Error');
    end;

  Res := Pipeline.Execute<string>(LFunc);
  Should(Res).Be('fallback-value');
end;

procedure TResilienceTests.TestResilienceTimeout;
var
  Pipeline: TResiliencePipeline;
  TimeoutCaught: Boolean;
begin
  Pipeline := TResiliencePipeline.Create.AddTimeout(50);
  TimeoutCaught := False;
  try
    Pipeline.Execute(
      procedure
      begin
        Sleep(200);
      end
    );
  except
    on E: ETimeoutException do
      TimeoutCaught := True;
  end;
  Should(TimeoutCaught).BeTrue;
end;

end.
