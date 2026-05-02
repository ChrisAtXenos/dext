unit Dext.Entity.Setup.Test;

interface

uses
  System.SysUtils,
  System.Classes,
   Dext.Entity,
   Dext.Entity.Drivers.Interfaces,
   Dext.Entity.Setup,
   Dext.Entity.Drivers.FireDAC,
   FireDAC.Comp.Client;

type
  TSetupTest = class
  public
    procedure Run;
  end;

implementation

{ TSetupTest }

procedure TSetupTest.Run;
var
  Options: TDbContextOptions;
  Conn: IDbConnection;
  FDConn: TFDConnection;
begin
  WriteLn('ðŸ§ª Running Setup & ConnectionString Tests...');

  Options := TDbContextOptions.Create;
  try
    Options.ConnectionString := 'Server=localhost;Port=5432;Database=postgres;User_Name=postgres;Password=123456';
    
    Conn := Options.BuildConnection;
    if Conn is TFireDACConnection then
    begin
      FDConn := TFireDACConnection(Conn).Connection;
      
      // FireDAC's ConnectionString property should be set correctly
      if FDConn.ConnectionString = Options.ConnectionString then
        WriteLn('   âœ… ConnectionString propagated correctly.')
      else
        WriteLn('   âŒ ConnectionString NOT propagated.');

      // Check if FireDAC parsed the password (even if not connected)
      if FDConn.Params.Password = '123456' then
        WriteLn('   âœ… Password correctly parsed by FireDAC.')
      else
        WriteLn('   âŒ Password NOT parsed: ' + FDConn.Params.Password);
        
      if FDConn.Params.UserName = 'postgres' then
        WriteLn('   âœ… UserName correctly parsed.')
      else
        WriteLn('   âŒ UserName NOT parsed: ' + FDConn.Params.UserName);
    end
    else
      WriteLn('   âŒ Connection is not a TFireDACConnection.');
  finally
    Options.Free;
  end;
  WriteLn('');
end;

end.
