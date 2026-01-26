{***************************************************************************}
{                                                                           }
{           Dext Framework - Example                                        }
{                                                                           }
{           Counter Main Form - MVU Orchestrator (Minimal!)                 }
{                                                                           }
{***************************************************************************}
unit Counter.Main;

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
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Counter.Model,
  Counter.Messages,
  Counter.Update,
  Counter.View;

type
  TMainForm = class(TForm)
    MainPanel: TPanel;
    FooterPanel: TPanel;
    InfoLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FModel: TCounterModel;
    FFrame: TCounterViewFrame;
    
    procedure DispatchMsg(const Msg: TCounterMsg);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // 1. Initialize Model
  FModel := TCounterModel.Init;
  
  // 2. Create Frame
  FFrame := TCounterViewFrame.Create(MainPanel);
  FFrame.Parent := MainPanel;
  FFrame.Align := alClient;
  
  // 3. Initialize Frame with dispatch callback
  FFrame.Initialize(DispatchMsg);
  
  // 4. Initial render
  FFrame.Render(FModel);
  
  InfoLabel.Caption := 'MVU Pattern with TFrame - Low Coupling!';
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FFrame.Free;
end;

procedure TMainForm.DispatchMsg(const Msg: TCounterMsg);
begin
  try
    // THE MVU LOOP:
    // 1. Update the model
    FModel := TCounterUpdate.Update(FModel, Msg);
    
    // 2. Re-render
    FFrame.Render(FModel);
    
    // 3. Update title
    Caption := Format('MVU Counter Frame - Count: %d', [FModel.Count]);
  finally
    Msg.Free;
  end;
end;

end.
