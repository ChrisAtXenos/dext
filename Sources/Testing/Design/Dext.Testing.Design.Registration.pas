unit Dext.Testing.Design.Registration;

interface

uses
  System.SysUtils,
  System.Classes,
  Dext.Testing.Design.Expert;

procedure Register;

implementation

procedure Register;
begin
  Dext.Testing.Design.Expert.RegisterExpert;
end;

end.
