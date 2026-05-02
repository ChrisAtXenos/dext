program VerifyScaffold;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  Dext,
  Dext.Entity,
  Dext.Logging,
  Dext.Logging.Extensions,
  Dext.DI.Interfaces,
  Dext.DI.Core,
  Dext.Utils,
  Entities in 'Entities.pas';

procedure RunVerification;
var
  Provider: IServiceProvider;
  FDB: TDbContext;
begin
  Provider := TDextServices.New
    .AddLogging(
      procedure(Builder: ILoggingBuilder)
      begin
        Builder.SetMinimumLevel(TLogLevel.Debug).AddConsole;
      end
    )
    .AddDbContext<TDbContext>(
      procedure(Options: TDbContextOptions)
      begin
        Options.Params.AddOrSetValue('DriverID', 'FB');
        Options.Params.AddOrSetValue('Database', 'C:\dev\Dext\DextRepository\Tests\Output\EMPLOYEE.FDB');
        Options.Params.AddOrSetValue('User_Name', 'SYSDBA');
        Options.Params.AddOrSetValue('Password', 'masterkey');
        Options.Params.AddOrSetValue('CharacterSet', 'UTF8');
        Options.Params.AddOrSetValue('Protocol', 'TCPIP');
        Options.Params.AddOrSetValue('Server', 'localhost');
        Options.Params.AddOrSetValue('Port', '3050');
        Options.LogTo(procedure(Msg: string) begin Writeln('LOG: ', Msg); end);
      end
    )
    .BuildServiceProvider;

  // Use manual resolution to avoid generic extension issues in this context
  FDB := TDbContext(Provider.GetService(TServiceType.FromClass(TDbContext)));

  FDB.Connection.OnLog := procedure(Msg: string)
    begin
      Writeln('LOG: ', Msg);
    end;
  
  if FDB = nil then
  begin
    Writeln('Error: Could not resolve TDbContext');
    Exit;
  end;

  Writeln('=== Running Queries for all entities ===');
  try
    try Writeln('COUNTRY: ', FDB.Entities<TCountry>.ToList.Count); except on E: Exception do Writeln('ERROR COUNTRY: ', E.Message); end;
    try Writeln('CUSTOMER: ', FDB.Entities<TCustomer>.ToList.Count); except on E: Exception do Writeln('ERROR CUSTOMER: ', E.Message); end;
    try Writeln('DEPARTMENT: ', FDB.Entities<TDepartment>.ToList.Count); except on E: Exception do Writeln('ERROR DEPARTMENT: ', E.Message); end;
    try Writeln('EMPLOYEE: ', FDB.Entities<TEmployee>.ToList.Count); except on E: Exception do Writeln('ERROR EMPLOYEE: ', E.Message); end;
    try Writeln('EMPLOYEE_PROJECT: ', FDB.Entities<TEmployeeProject>.ToList.Count); except on E: Exception do Writeln('ERROR EMPLOYEE_PROJECT: ', E.Message); end;
    try Writeln('JOB: ', FDB.Entities<TJob>.ToList.Count); except on E: Exception do Writeln('ERROR JOB: ', E.Message); end;
    try Writeln('PHONE_LIST: ', FDB.Entities<TPhoneList>.ToList.Count); except on E: Exception do Writeln('ERROR PHONE_LIST: ', E.Message); end;
    try Writeln('PROJECT: ', FDB.Entities<TProject>.ToList.Count); except on E: Exception do Writeln('ERROR PROJECT: ', E.Message); end;
    try Writeln('PROJ_DEPT_BUDGET: ', FDB.Entities<TProjDeptBudget>.ToList.Count); except on E: Exception do Writeln('ERROR PROJ_DEPT_BUDGET: ', E.Message); end;
    try Writeln('SALARY_HISTORY: ', FDB.Entities<TSalaryHistory>.ToList.Count); except on E: Exception do Writeln('ERROR SALARY_HISTORY: ', E.Message); end;
    try Writeln('SALES: ', FDB.Entities<TSales>.ToList.Count); except on E: Exception do Writeln('ERROR SALES: ', E.Message); end;
  finally
    Writeln('Verification finished.');
  end;
end;

begin
  try
    RunVerification;
  except
    on E: Exception do
      Writeln('FATAL: ', E.ClassName, ': ', E.Message);
  end;
  // No Readln for background execution
  ConsolePause;
end.
