unit Dext.Testing.Design.Expert;

interface

uses
  System.SysUtils,
  System.Classes,
  ToolsAPI,
  Vcl.Menus;

type
  { IDE Notifier to handle Auto-Run after compiles and file saving }
  TDextTestRunnerIDENotifier = class(TNotifierObject, IOTAIDENotifier)
  public
    procedure FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var CanModify: Boolean);
    procedure BeforeCompile(const Project: IOTAProject; var CanCompile: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean); overload;
    procedure BeforeCompile(const Project: IOTAProject; IsCodeInsight: Boolean; var CanCompile: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean; IsCodeInsight: Boolean); overload;
  end;

procedure RegisterExpert;

implementation

uses
  Winapi.Windows,
  Vcl.Forms,
  Dext.Testing.Design.DockableForm,
  Dext.Testing.Design.Gutter,
  Dext.Testing.Design.Coverage;

type
  TDextMenuHelper = class
  public
    procedure OnMenuClick(Sender: TObject);
  end;

var
  FNotifierIndex: Integer = -1;
  FTestExplorerMenu: TMenuItem = nil;
  FMenuHelper: TDextMenuHelper = nil;

procedure TDextMenuHelper.OnMenuClick(Sender: TObject);
begin
  ShowDextTestExplorer;
end;

procedure SetupMenus;
var
  LNTAServices: INTAServices;
  LMainMenu: TMainMenu;
  LToolsMenu: TMenuItem;
  I: Integer;
begin
  if Assigned(FTestExplorerMenu) then Exit;
  
  if Supports(BorlandIDEServices, INTAServices, LNTAServices) then
  begin
    LMainMenu := LNTAServices.MainMenu;
    if LMainMenu <> nil then
    begin
      LToolsMenu := nil;
      for I := 0 to LMainMenu.Items.Count - 1 do
      begin
        if SameText(LMainMenu.Items[I].Name, 'ToolsMenu') or 
           (LMainMenu.Items[I].Caption.Contains('Tools')) or
           (LMainMenu.Items[I].Caption.Contains('Ferramentas')) then
        begin
          LToolsMenu := LMainMenu.Items[I];
          Break;
        end;
      end;

      if LToolsMenu = nil then 
        LToolsMenu := LMainMenu.Items[LMainMenu.Items.Count - 1];

      if FMenuHelper = nil then
        FMenuHelper := TDextMenuHelper.Create;

      FTestExplorerMenu := TMenuItem.Create(LMainMenu);
      FTestExplorerMenu.Caption := 'Dext Test Explorer';
      FTestExplorerMenu.OnClick := FMenuHelper.OnMenuClick;
      LToolsMenu.Add(FTestExplorerMenu);
    end;
  end;
end;

procedure RemoveMenus;
begin
  if Assigned(FTestExplorerMenu) then
  begin
    FTestExplorerMenu.Free;
    FTestExplorerMenu := nil;
  end;
  if Assigned(FMenuHelper) then
  begin
    FMenuHelper.Free;
    FMenuHelper := nil;
  end;
end;

procedure RegisterExpert;
var
  LOTAServices: IOTAServices;
begin
  if FNotifierIndex = -1 then
  begin
    if Supports(BorlandIDEServices, IOTAServices, LOTAServices) then
      FNotifierIndex := LOTAServices.AddNotifier(TDextTestRunnerIDENotifier.Create);
  end;

  SetupMenus;
  RegisterDockableForm;
  RegisterGutterVisualizer;
end;

{ TDextTestRunnerIDENotifier }

procedure TDextTestRunnerIDENotifier.AfterCompile(Succeeded: Boolean);
begin
  // Notify the test runner that the IDE compile has finished.
  // If FWaitingForCompile is set, this triggers test execution.
  if Assigned(FormDextTestRunner) then
    FormDextTestRunner.NotifyCompileComplete(Succeeded);
end;

procedure TDextTestRunnerIDENotifier.AfterCompile(Succeeded, IsCodeInsight: Boolean);
begin
  AfterCompile(Succeeded);
end;

procedure TDextTestRunnerIDENotifier.BeforeCompile(const Project: IOTAProject; var CanCompile: Boolean);
begin
end;

procedure TDextTestRunnerIDENotifier.BeforeCompile(const Project: IOTAProject; IsCodeInsight: Boolean; var CanCompile: Boolean);
begin
end;

procedure TDextTestRunnerIDENotifier.FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var CanModify: Boolean);
begin
  if NotifyCode = ofnFileOpened then
  begin
    TCoverageManager.GetInstance.RefreshActiveViews;
  end;

  if Assigned(FormDextTestRunner) then
  begin
    if (NotifyCode = ofnActiveProjectChanged) or 
       ((NotifyCode in [ofnFileOpened, ofnFileClosing, ofnEndProjectGroupOpen, ofnEndProjectGroupClose]) and 
        (SameText(ExtractFileExt(FileName), '.dproj') or SameText(ExtractFileExt(FileName), '.groupproj'))) then
    begin
      TThread.ForceQueue(nil, TThreadProcedure(procedure
        begin
          if Assigned(FormDextTestRunner) then
            FormDextTestRunner.RefreshProjects;
        end));
    end;
  end;
end;

initialization

finalization
  if (FNotifierIndex <> -1) and Assigned(BorlandIDEServices) then
  begin
    (BorlandIDEServices as IOTAServices).RemoveNotifier(FNotifierIndex);
    FNotifierIndex := -1;
  end;
  RemoveMenus;
  UnregisterDockableForm;
  UnregisterGutterVisualizer;

end.
