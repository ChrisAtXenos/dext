unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Dext.Logging,
  Dext.Logging.Global,
  Dext.Logging.Sinks.VCL;

type
  TfrmMain = class(TForm)
    pnlTop: TPanel;
    btnInfo: TButton;
    btnWarn: TButton;
    btnError: TButton;
    memoLogs: TMemo;
    lblTitle: TLabel;
    btnStressTest: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnInfoClick(Sender: TObject);
    procedure btnWarnClick(Sender: TObject);
    procedure btnErrorClick(Sender: TObject);
    procedure btnStressTestClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // 1. Register the Memo as a Log Sink
  // This demonstrates how to extend Dext Logging with custom targets.
  Log.AddSink(TMemoLogSink.Create(memoLogs, 500));
  
  Log.Info('Application started. Dext Logging initialized with Memo Sink.');
end;

procedure TfrmMain.btnInfoClick(Sender: TObject);
begin
  Log.Info('This is an information message from VCL.');
end;

procedure TfrmMain.btnWarnClick(Sender: TObject);
begin
  Log.Warn('Careful! This is a warning with a parameter: {Value}', [Random(100)]);
end;

procedure TfrmMain.btnErrorClick(Sender: TObject);
begin
  try
    raise EProgrammerNotFound.Create('Where is the developer?');
  except
    on E: Exception do
      Log.Error(E, 'An intentional error occurred: {Msg}', [E.Message]);
  end;
end;

procedure TfrmMain.btnStressTestClick(Sender: TObject);
begin
  // The Dext Logger is 100% async. This stress test won't freeze the UI.
  TThread.CreateAnonymousThread(
    procedure
    var
      I: Integer;
    begin
      for I := 1 to 100 do
      begin
        Log.Debug('Stress log from Background Thread #{ThreadID}: Iteration {Idx}', 
          [TThread.CurrentThread.ThreadID, I]);
        Sleep(10); 
      end;
      Log.Info('Stress test finished from thread #{ThreadID}', [TThread.CurrentThread.ThreadID]);
    end).Start;
end;

end.
