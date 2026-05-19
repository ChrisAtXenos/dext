program VCLMemoLog;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {frmMain},
  Dext.Logging.Sinks.VCL in 'Dext.Logging.Sinks.VCL.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
