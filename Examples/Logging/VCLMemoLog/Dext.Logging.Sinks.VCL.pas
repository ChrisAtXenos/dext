unit Dext.Logging.Sinks.VCL;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.StdCtrls,
  Dext.Logging,
  Dext.Logging.Async,
  Dext.Logging.RingBuffer;

type
  /// <summary>
  ///   A Log Sink that outputs log entries to a VCL TMemo.
  ///   Automatically handles thread-safety by queuing updates to the Main Thread.
  /// </summary>
  TMemoLogSink = class(TInterfacedObject, ILogSink)
  private
    FMemo: TMemo;
    FMaxLines: Integer;
    procedure AppendToMemo(const AText: string);
  public
    constructor Create(AMemo: TMemo; AMaxLines: Integer = 1000);
    procedure Emit(const Entry: TLogEntry);
    procedure Flush;
  end;

implementation

{ TMemoLogSink }

constructor TMemoLogSink.Create(AMemo: TMemo; AMaxLines: Integer);
begin
  inherited Create;
  FMemo := AMemo;
  FMaxLines := AMaxLines;
end;

procedure TMemoLogSink.Emit(const Entry: TLogEntry);
var
  LText: string;
  LPrefix: string;
begin
  if FMemo = nil then Exit;

  // Format the line for the Memo
  case Entry.Level of
    TLogLevel.Trace:       LPrefix := '[TRC]';
    TLogLevel.Debug:       LPrefix := '[DBG]';
    TLogLevel.Information: LPrefix := '[INF]';
    TLogLevel.Warning:     LPrefix := '[WRN]';
    TLogLevel.Error:       LPrefix := '[ERR]';
    TLogLevel.Critical:    LPrefix := '[CRT]';
  else
    LPrefix := '[LOG]';
  end;

  LText := Format('%s %s - %s', [
    FormatDateTime('hh:nn:ss.zzz', Entry.TimeStamp),
    LPrefix,
    Entry.FormattedMessage
  ]);

  // Sinks are called from the TLogConsumerThread. 
  // We MUST use TThread.Queue/Synchronize to update VCL components.
  TThread.Queue(nil,
    procedure
    begin
      AppendToMemo(LText);
    end);
end;

procedure TMemoLogSink.Flush;
begin
  // Nothing to flush for a Memo
end;

procedure TMemoLogSink.AppendToMemo(const AText: string);
begin
  if FMemo = nil then Exit;
  
  FMemo.Lines.BeginUpdate;
  try
    FMemo.Lines.Add(AText);
    
    // Simple rotation to prevent memory bloat
    if (FMaxLines > 0) and (FMemo.Lines.Count > FMaxLines) then
    begin
      while FMemo.Lines.Count > FMaxLines do
        FMemo.Lines.Delete(0);
    end;
    
    // Auto-scroll to bottom
    FMemo.SelStart := FMemo.GetTextLen;
    FMemo.Perform(256 {WM_VSCROLL}, 7 {SB_BOTTOM}, 0);
  finally
    FMemo.Lines.EndUpdate;
  end;
end;

end.
