{***************************************************************************}
{                                                                           }
{           Dext Framework - Example                                        }
{                                                                           }
{           Counter View Frame - UI with self-contained event handling      }
{                                                                           }
{***************************************************************************}
unit Counter.View;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Counter.Model,
  Counter.Messages;

type
  /// <summary>Callback type for dispatching messages</summary>
  TDispatchProc = reference to procedure(const Msg: TCounterMsg);
  
  /// <summary>
  /// Counter View Frame - designed in IDE with self-contained event handling.
  /// The Frame owns its controls and knows how to dispatch messages.
  /// </summary>
  TCounterViewFrame = class(TFrame)
    CountLabel: TLabel;
    StepLabel: TLabel;
    IncrementButton: TButton;
    DecrementButton: TButton;
    IncrementStepButton: TButton;
    DecrementStepButton: TButton;
    ResetButton: TButton;
    StepsPanel: TPanel;
    Step1Button: TButton;
    Step5Button: TButton;
    Step10Button: TButton;
    HistoryLabel: TLabel;
    HistoryMemo: TMemo;
  private
    FDispatch: TDispatchProc;
    
    // Event handlers (TNotifyEvent compatible)
    procedure OnIncrementClick(Sender: TObject);
    procedure OnDecrementClick(Sender: TObject);
    procedure OnIncrementStepClick(Sender: TObject);
    procedure OnDecrementStepClick(Sender: TObject);
    procedure OnResetClick(Sender: TObject);
    procedure OnStep1Click(Sender: TObject);
    procedure OnStep5Click(Sender: TObject);
    procedure OnStep10Click(Sender: TObject);
    
    procedure WireEvents;
  public
    /// <summary>Initialize the Frame with a dispatch callback</summary>
    procedure Initialize(ADispatch: TDispatchProc);
    
    /// <summary>Render the UI based on the current Model state</summary>
    procedure Render(const Model: TCounterModel);
  end;

implementation

{$R *.dfm}

procedure TCounterViewFrame.Initialize(ADispatch: TDispatchProc);
begin
  FDispatch := ADispatch;
  WireEvents;
end;

procedure TCounterViewFrame.WireEvents;
begin
  IncrementButton.OnClick := OnIncrementClick;
  DecrementButton.OnClick := OnDecrementClick;
  IncrementStepButton.OnClick := OnIncrementStepClick;
  DecrementStepButton.OnClick := OnDecrementStepClick;
  ResetButton.OnClick := OnResetClick;
  Step1Button.OnClick := OnStep1Click;
  Step5Button.OnClick := OnStep5Click;
  Step10Button.OnClick := OnStep10Click;
end;

// Event Handlers - dispatch messages to the MVU loop

procedure TCounterViewFrame.OnIncrementClick(Sender: TObject);
begin
  if Assigned(FDispatch) then
    FDispatch(TIncrementMsg.Create);
end;

procedure TCounterViewFrame.OnDecrementClick(Sender: TObject);
begin
  if Assigned(FDispatch) then
    FDispatch(TDecrementMsg.Create);
end;

procedure TCounterViewFrame.OnIncrementStepClick(Sender: TObject);
begin
  if Assigned(FDispatch) then
    FDispatch(TIncrementByStepMsg.Create);
end;

procedure TCounterViewFrame.OnDecrementStepClick(Sender: TObject);
begin
  if Assigned(FDispatch) then
    FDispatch(TDecrementByStepMsg.Create);
end;

procedure TCounterViewFrame.OnResetClick(Sender: TObject);
begin
  if Assigned(FDispatch) then
    FDispatch(TResetMsg.Create);
end;

procedure TCounterViewFrame.OnStep1Click(Sender: TObject);
begin
  if Assigned(FDispatch) then
    FDispatch(TSetStepMsg.Create(1));
end;

procedure TCounterViewFrame.OnStep5Click(Sender: TObject);
begin
  if Assigned(FDispatch) then
    FDispatch(TSetStepMsg.Create(5));
end;

procedure TCounterViewFrame.OnStep10Click(Sender: TObject);
begin
  if Assigned(FDispatch) then
    FDispatch(TSetStepMsg.Create(10));
end;

// Render - update UI from Model

procedure TCounterViewFrame.Render(const Model: TCounterModel);
begin
  CountLabel.Caption := Model.Count.ToString;
  StepLabel.Caption := Format('Step: %d', [Model.Step]);
  IncrementStepButton.Caption := Format('+ %d', [Model.Step]);
  DecrementStepButton.Caption := Format('- %d', [Model.Step]);
  HistoryMemo.Text := Model.History;
  
  // Highlight active step button
  Step1Button.Font.Style := [];
  Step5Button.Font.Style := [];
  Step10Button.Font.Style := [];
  case Model.Step of
    1: Step1Button.Font.Style := [fsBold];
    5: Step5Button.Font.Style := [fsBold];
    10: Step10Button.Font.Style := [fsBold];
  end;
end;

end.
