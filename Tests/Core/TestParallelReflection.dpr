program TestParallelReflection;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Threading,
  System.Rtti,
  Dext.Core.Reflection,
  Dext.Core.Activator,
  Dext.Utils;

type
  TTestEntity = class
  private
    FId: Integer;
    FName: string;
  public
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
  end;

procedure StressReflection;
var
  Meta: TTypeMetadata;
begin
  TParallel.For(1, 1000, procedure(I: Integer)
  var
    Handler: IPropertyHandler;
    Handler2: IPropertyHandler;
  begin
    Meta := TReflection.GetMetadata(TypeInfo(TTestEntity));
    Handler := Meta.GetHandler('Id');
    if Handler = nil then
      raise Exception.Create('Handler not found');
    Handler2 := Meta.GetHandlerBySnakeCase('name');
  end);
end;

procedure StressActivator;
begin
  TParallel.For(1, 1000, procedure(I: Integer)
  var
    Obj: TTestEntity;
  begin
    Obj := TActivator.CreateInstance<TTestEntity>;
    Obj.Free;
  end);
end;

procedure PrintAggregateException(const E: EAggregateException);
var
  I: Integer;
begin
  Writeln('EAggregateException: ', E.Message);
  for I := 0 to E.Count - 1 do
    Writeln('  - ', E.InnerExceptions[I].ClassName, ': ', E.InnerExceptions[I].Message);
end;

begin
  try
    Writeln('Starting Stress Tests (Wave 8 Hardened)...');
    

    
    Writeln('Testing Reflection (Parallel)...');
    StressReflection;
    Writeln('Testing Activator (Parallel)...');
    StressActivator;
    Writeln('Stress Tests Passed 100%!');
  except
    on E: EAggregateException do
      PrintAggregateException(E);
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ConsolePause;
end.
