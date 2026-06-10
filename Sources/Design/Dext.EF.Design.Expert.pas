unit Dext.EF.Design.Expert;

{$I ..\Dext.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  ToolsAPI,
  Vcl.Menus,
  Dext.Entity.DataProvider,
  Dext.EF.Design.Metadata;

type
  TDextModuleNotifier = class(TNotifierObject, IOTAModuleNotifier)
  public
    // IOTAModuleNotifier
    function CheckOverwrite: Boolean;
    procedure ModuleRenamed(const NewName: string);
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;
  end;

  TDextIDENotifier = class(TNotifierObject, IOTAIDENotifier)
  public
    // IOTAIDENotifier
    procedure FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var CanModify: Boolean);
    procedure BeforeCompile(const Project: IOTAProject; var CanCompile: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean); overload;
    procedure BeforeCompile(const Project: IOTAProject; IsCodeInsigth: Boolean; var CanCompile: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean; IsCodeInsight: Boolean); overload;
  end;

procedure RegisterExpert;

implementation

uses
  Dext.EF.Design.DocExpert,
  System.IOUtils,
  System.JSON,
  System.Net.HttpClient,
  System.StrUtils,
  Winapi.Windows,
  Winapi.ShellAPI,
  Vcl.Forms,
  Vcl.Dialogs;

{$IFDEF DEXT_ENABLE_SIDECAR_EXPERT}
var
  FNotifierIndex: Integer = -1;
{$ENDIF}

{$IFDEF DEXT_ENABLE_SIDECAR_EXPERT}
type
  TDextSidecarSupervisor = class
  private
    class var FMenuAdded: Boolean;
    class var FMainMenu: TMenuItem;
    class function FindDextExe: string;
  public
    class procedure LogToIDE(const AMessage: string);
    class function IsSidecarRunning: Boolean;
    class procedure StartSidecar;
    class procedure StopSidecar;
    class procedure RestartSidecar;
    class procedure OpenDashboard;
    class procedure SyncActiveProjects;
    class procedure SetupMenus;
    class procedure RemoveMenus;
    class procedure OnMenuClick(Sender: TObject);
  end;
{$ENDIF DEXT_ENABLE_SIDECAR_EXPERT}

{$IFDEF DEXT_ENABLE_SIDECAR_EXPERT}
{ TDextSidecarSupervisor }

class procedure TDextSidecarSupervisor.LogToIDE(const AMessage: string);
var
  MsgServices: IOTAMessageServices;
begin
  if Assigned(BorlandIDEServices) and Supports(BorlandIDEServices, IOTAMessageServices, MsgServices) then
  begin
    MsgServices.AddTitleMessage('[Dext] ' + AMessage);
  end;
end;

class function TDextSidecarSupervisor.FindDextExe: string;
var
  Paths: TArray<string>;
  P: string;
  ActiveProject: IOTAProject;
  ProjDir: string;
  ModServices: IOTAModuleServices;
begin
  Result := 'dext.exe';
  ProjDir := '';
  if Assigned(BorlandIDEServices) then
  begin
    if Supports(BorlandIDEServices, IOTAModuleServices, ModServices) then
    begin
      ActiveProject := ModServices.CurrentModule as IOTAProject;
      if Assigned(ActiveProject) then
        ProjDir := ExtractFilePath(ActiveProject.FileName);
    end;
  end;

  Paths := [
    'C:\dev\Dext\DextRepository\Apps\dext.exe',
    TPath.Combine(ProjDir, '..\..\..\Apps\dext.exe'),
    TPath.Combine(ProjDir, '..\..\Apps\dext.exe')
  ];
  for P in Paths do
  begin
    if TFile.Exists(P) then
      Exit(P);
  end;
end;

class function TDextSidecarSupervisor.IsSidecarRunning: Boolean;
var
  Client: THTTPClient;
  Resp: IHTTPResponse;
begin
  Result := False;
  Client := THTTPClient.Create;
  try
    try
      // Timeout quickly
      Client.ConnectionTimeout := 500;
      Client.ResponseTimeout := 500;
      Resp := Client.Get('http://localhost:3030/health');
      Result := (Resp <> nil) and (Resp.StatusCode = 200);
    except
      // Silent fail (not running)
    end;
  finally
    Client.Free;
  end;
end;

class procedure TDextSidecarSupervisor.StartSidecar;
var
  DextExe: string;
  SI: TStartupInfo;
  PI: TProcessInformation;
  CmdLine: string;
begin
  LogToIDE('Checking if Sidecar is already running...');
  if IsSidecarRunning then
  begin
    LogToIDE('Sidecar is already running. Syncing active projects.');
    SyncActiveProjects;
    Exit;
  end;

  DextExe := FindDextExe;
  LogToIDE('Attempting to launch Sidecar process at ' + DextExe);
  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SI.dwFlags := STARTF_USESHOWWINDOW;
  SI.wShowWindow := SW_HIDE;

  CmdLine := Format('"%s" sidecar', [DextExe]);
  UniqueString(CmdLine);

  if CreateProcess(nil, PChar(CmdLine), nil, nil, False, CREATE_NO_WINDOW, nil, PChar(ExtractFilePath(DextExe)), SI, PI) then
  begin
    CloseHandle(PI.hProcess);
    CloseHandle(PI.hThread);
    LogToIDE('Sidecar process launched successfully in background. Sleeping 500ms to boot...');
    // Give it a moment to boot
    TThread.Sleep(500);
    SyncActiveProjects;
  end
  else
  begin
    LogToIDE('Failed to execute Dext Sidecar process at ' + DextExe);
    MessageDlg('Failed to execute Dext Sidecar process at ' + DextExe, mtError, [mbOK], 0);
  end;
end;

class procedure TDextSidecarSupervisor.StopSidecar;
var
  Client: THTTPClient;
begin
  LogToIDE('Stopping Sidecar supervisor...');
  Client := THTTPClient.Create;
  try
    try
      Client.Post('http://localhost:3030/api/telemetry/flush', TStream(nil));
    except
    end;
  finally
    Client.Free;
  end;

  // Kill process
  LogToIDE('Sending taskkill to terminate dext.exe processes...');
  ShellExecute(0, 'open', 'taskkill', '/f /im dext.exe', nil, SW_HIDE);
  TThread.Sleep(200);
  LogToIDE('Sidecar stopped.');
end;

class procedure TDextSidecarSupervisor.RestartSidecar;
begin
  StopSidecar;
  StartSidecar;
end;

class procedure TDextSidecarSupervisor.OpenDashboard;
begin
  if not IsSidecarRunning then
    StartSidecar;
  ShellExecute(0, 'open', 'http://localhost:3030', nil, nil, SW_SHOWNORMAL);
end;

class procedure TDextSidecarSupervisor.SyncActiveProjects;
begin
  LogToIDE('Starting active projects synchronization in background thread...');
  TThread.CreateAnonymousThread(procedure
    var
      ModuleServices: IOTAModuleServices;
      Group: IOTAProjectGroup;
      I: Integer;
      Proj: IOTAProject;
      JArr: TJSONArray;
      Client: THTTPClient;
      Source: TStringStream;
      GroupDir: string;
      PPath: string;
    begin
      if not IsSidecarRunning then
      begin
        LogToIDE('Cannot sync projects: Sidecar is not running.');
        Exit;
      end;

      ModuleServices := BorlandIDEServices as IOTAModuleServices;
      if ModuleServices = nil then Exit;

      Group := ModuleServices.MainProjectGroup;
      if Group <> nil then
      begin
        GroupDir := ExtractFilePath(Group.FileName);
        LogToIDE('Syncing Project Group: ' + Group.FileName);
        JArr := TJSONArray.Create;
        try
          for I := 0 to Group.ProjectCount - 1 do
          begin
            Proj := Group.Projects[I];
            if Proj <> nil then
            begin
              PPath := Proj.FileName;
              if not TPath.IsPathRooted(PPath) then
                PPath := TPath.Combine(GroupDir, PPath);
              PPath := TPath.GetFullPath(PPath);
              LogToIDE('  Sync Project Path: ' + PPath);
              JArr.Add(PPath);
            end;
          end;

          LogToIDE(Format('Sending %d projects to Sidecar at http://localhost:3030/api/ide/projects...', [Group.ProjectCount]));
          Client := THTTPClient.Create;
          Source := nil;
          try
            Client.ContentType := 'application/json';
            Source := TStringStream.Create(JArr.ToJSON, TEncoding.UTF8);
            try
              Client.Post('http://localhost:3030/api/ide/projects', Source, nil);
              LogToIDE('Projects successfully synchronized with Sidecar!');
            except
              on E: Exception do
                LogToIDE('Failed to sync projects: ' + E.Message);
            end;
          finally
            if Source <> nil then
              Source.Free;
            Client.Free;
          end;
        finally
          JArr.Free;
        end;
      end
      else
        LogToIDE('No active main project group found in IDE.');
    end).Start;
end;

class procedure TDextSidecarSupervisor.OnMenuClick(Sender: TObject);
var
  Tag: Integer;
begin
  if Sender is TMenuItem then
  begin
    Tag := TMenuItem(Sender).Tag;
    case Tag of
      1: StartSidecar;
      2: StopSidecar;
      3: RestartSidecar;
      4: OpenDashboard;
      5: SyncActiveProjects;
    end;
  end;
end;

class procedure TDextSidecarSupervisor.SetupMenus;
var
  NTAServices: INTAServices;
  MainMenu: TMainMenu;
  ToolsMenu: TMenuItem;
  SubItem: TMenuItem;
  I: Integer;
begin
  if FMenuAdded then Exit;
  if Supports(BorlandIDEServices, INTAServices, NTAServices) then
  begin
    MainMenu := NTAServices.MainMenu;
    if MainMenu <> nil then
    begin
      // Look for Tools menu
      ToolsMenu := nil;
      for I := 0 to MainMenu.Items.Count - 1 do
      begin
        if SameText(MainMenu.Items[I].Name, 'ToolsMenu') or ContainsText(MainMenu.Items[I].Caption, 'Tools') then
        begin
          ToolsMenu := MainMenu.Items[I];
          Break;
        end;
      end;

      if ToolsMenu = nil then ToolsMenu := MainMenu.Items[MainMenu.Items.Count - 1]; // Fallback

      FMainMenu := TMenuItem.Create(MainMenu);
      FMainMenu.Caption := 'Dext Sidecar';

      SubItem := TMenuItem.Create(MainMenu);
      SubItem.Caption := 'Start Sidecar';
      SubItem.Tag := 1;
      SubItem.OnClick := OnMenuClick;
      FMainMenu.Add(SubItem);

      SubItem := TMenuItem.Create(MainMenu);
      SubItem.Caption := 'Stop Sidecar';
      SubItem.Tag := 2;
      SubItem.OnClick := OnMenuClick;
      FMainMenu.Add(SubItem);

      SubItem := TMenuItem.Create(MainMenu);
      SubItem.Caption := 'Restart Sidecar';
      SubItem.Tag := 3;
      SubItem.OnClick := OnMenuClick;
      FMainMenu.Add(SubItem);

      FMainMenu.Add(TMenuItem.Create(MainMenu)); // Separator

      SubItem := TMenuItem.Create(MainMenu);
      SubItem.Caption := 'Open Dashboard';
      SubItem.Tag := 4;
      SubItem.OnClick := OnMenuClick;
      FMainMenu.Add(SubItem);

      SubItem := TMenuItem.Create(MainMenu);
      SubItem.Caption := 'Sync IDE Projects';
      SubItem.Tag := 5;
      SubItem.OnClick := OnMenuClick;
      FMainMenu.Add(SubItem);

      ToolsMenu.Add(FMainMenu);
      FMenuAdded := True;
    end;
  end;
end;

class procedure TDextSidecarSupervisor.RemoveMenus;
begin
  if not FMenuAdded then Exit;
  if FMainMenu <> nil then
  begin
    FMainMenu.Free;
    FMainMenu := nil;
  end;
  FMenuAdded := False;
end;

{$ENDIF DEXT_ENABLE_SIDECAR_EXPERT}

procedure RegisterExpert;
begin
{$IFDEF DEXT_ENABLE_SIDECAR_EXPERT}
  if FNotifierIndex = -1 then
    FNotifierIndex := (BorlandIDEServices as IOTAServices).AddNotifier(TDextIDENotifier.Create);
{$ENDIF}
  RegisterDocExpert;
{$IFDEF DEXT_ENABLE_SIDECAR_EXPERT}
  TDextSidecarSupervisor.SetupMenus;
  TDextSidecarSupervisor.LogToIDE('Dext Design Time Expert Loaded.');
  // Try to start Sidecar on IDE launch
  TThread.CreateAnonymousThread(procedure
    begin
      TThread.Sleep(1000);
      TDextSidecarSupervisor.StartSidecar;
    end).Start;
{$ENDIF}
end;

{ TDextModuleNotifier }

procedure TDextModuleNotifier.AfterSave;
var
  Module: IOTAModule;
  Editor: IOTAEditor;
  i, j, k: Integer;
  FormEditor: IOTAFormEditor;
  Component: IOTAComponent;
  Comp: TComponent;
begin
  // Get active module
  Module := (BorlandIDEServices as IOTAModuleServices).CurrentModule;
  if Module = nil then Exit;

  // Refresh all TEntityDataProvider in all open forms
  // Refresh all TEntityDataProvider in all open forms
  for i := 0 to (BorlandIDEServices as IOTAModuleServices).ModuleCount - 1 do
  begin
    Module := (BorlandIDEServices as IOTAModuleServices).Modules[i];
    if Module = nil then Continue;
    
    for j := 0 to Module.GetModuleFileCount - 1 do
    begin
      Editor := Module.GetModuleFileEditor(j);
      if Supports(Editor, IOTAFormEditor, FormEditor) then
      begin
        // Iterate components in the form using RootComponent
        if Assigned(FormEditor.GetRootComponent) then
        begin
          for k := 0 to FormEditor.GetRootComponent.GetComponentCount - 1 do
          begin
            Component := FormEditor.GetRootComponent.GetComponent(k);
            if Assigned(Component) then
            begin
              Comp := (Component as INTAComponent).GetComponent;
              if Comp is TEntityDataProvider then
              begin
                 RefreshProviderMetadata(TEntityDataProvider(Comp));
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TDextModuleNotifier.BeforeSave;
begin
end;

function TDextModuleNotifier.CheckOverwrite: Boolean;
begin
  Result := True;
end;

procedure TDextModuleNotifier.Destroyed;
begin
end;

procedure TDextModuleNotifier.Modified;
begin
end;

procedure TDextModuleNotifier.ModuleRenamed(const NewName: string);
begin
end;

{ TDextIDENotifier }

procedure TDextIDENotifier.AfterCompile(Succeeded: Boolean);
begin
end;

procedure TDextIDENotifier.AfterCompile(Succeeded, IsCodeInsight: Boolean);
begin
end;

procedure TDextIDENotifier.BeforeCompile(const Project: IOTAProject; var CanCompile: Boolean);
begin
end;

procedure TDextIDENotifier.BeforeCompile(const Project: IOTAProject; IsCodeInsigth: Boolean; var CanCompile: Boolean);
begin
end;

procedure TDextIDENotifier.FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var CanModify: Boolean);
begin
  if (NotifyCode = ofnFileOpened) and SameText(ExtractFileExt(FileName), '.pas') then
  begin
    // Add module notifier if needed
  end;
{$IFDEF DEXT_ENABLE_SIDECAR_EXPERT}
  if NotifyCode = ofnActiveProjectChanged then
  begin
    TDextSidecarSupervisor.SyncActiveProjects;
  end;
{$ENDIF}
end;

initialization

finalization
{$IFDEF DEXT_ENABLE_SIDECAR_EXPERT}
  if FNotifierIndex <> -1 then
    (BorlandIDEServices as IOTAServices).RemoveNotifier(FNotifierIndex);
{$ENDIF}
  UnregisterDocExpert;
{$IFDEF DEXT_ENABLE_SIDECAR_EXPERT}
  TDextSidecarSupervisor.RemoveMenus;
{$ENDIF}

end.
