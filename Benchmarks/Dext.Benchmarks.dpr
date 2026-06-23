program Dext.Benchmarks;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  {$IFDEF WIN64}
  RDPMM64 in '..\..\Libs\Delphi64RTL\RDPMM64.pas',
  RDPSimd64 in '..\..\Libs\Delphi64RTL\RDPSimd64.pas',
  {$ENDIF}
  System.SysUtils,
  Spring.Benchmark in '..\External\Spring4D\Spring.Benchmark.pas',
  BM.Http in 'Sources\BM.Http.pas',
  BM.Orm in 'Sources\BM.Orm.pas';

begin
  try
    if (ParamCount >= 2) and SameText(ParamStr(1), '--server') then
    begin
      RunStandaloneServer(ParamStr(2));
    end
    else
    begin
      // Spring.Benchmark parses command line arguments and runs all registered benchmarks
      Benchmark_Main;
      Write('Press [ENTER] to finish');
      ReadLn;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
