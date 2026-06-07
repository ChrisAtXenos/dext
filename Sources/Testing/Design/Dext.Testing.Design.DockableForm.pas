unit Dext.Testing.Design.DockableForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, DockForm, ToolsAPI, Dext.Testing.Design.Server, Dext.Testing.Design.AST,
  System.JSON, System.Generics.Collections, System.IOUtils;

type
  TFormDextTestRunner = class(TDockableForm)
    pnlToolbar: TPanel;
    cbProjects: TComboBox;
    btnRunAll: TButton;
    btnRunSelected: TButton;
    btnStop: TButton;
    pcSessions: TPageControl;
    tsDefaultSession: TTabSheet;
    tvTests: TTreeView;
    pnlDetails: TPanel;
    memDetails: TMemo;
    Splitter1: TSplitter;
    procedure cbProjectsChange(Sender: TObject);
    procedure btnRunAllClick(Sender: TObject);
    procedure btnRunSelectedClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure tvTestsDblClick(Sender: TObject);
  private
    FServer: TTestRunnerServer;
    FTestLocations: TList<TTestLocation>;
    FActiveProjectFile: string;
    procedure ApplyIDETheme;
    procedure RefreshProjects;
    procedure OnTestResultReceived(const AJSONData: string);
    procedure UpdateTestNode(const ATestName, AStatus, AMessage, AStackTrace: string);
    procedure RunActiveProjectTests(const ATestFilter: string = '');
    function FindNodeByPath(const APath: string): TTreeNode;
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

procedure ShowDextTestExplorer;
procedure RegisterDockableForm;
procedure UnregisterDockableForm;

var
  FormDextTestRunner: TFormDextTestRunner = nil;

implementation

{$R *.dfm}

uses
  DeskUtil, Dext.Utils;

procedure ShowDextTestExplorer;
begin
  if not Assigned(FormDextTestRunner) then
    FormDextTestRunner := TFormDextTestRunner.Create(nil);
  ShowDockableForm(FormDextTestRunner);
end;

procedure RegisterDockableForm;
begin
  if @RegisterFieldAddress <> nil then
    RegisterFieldAddress('FormDextTestRunner', @FormDextTestRunner);
  RegisterDesktopFormClass(TFormDextTestRunner, 'FormDextTestRunner', 'FormDextTestRunner');
end;

procedure UnregisterDockableForm;
begin
  if @UnRegisterFieldAddress <> nil then
    UnRegisterFieldAddress(@FormDextTestRunner);
  if Assigned(FormDextTestRunner) then
    FreeAndNil(FormDextTestRunner);
end;

{ TFormDextTestRunner }

constructor TFormDextTestRunner.Create(AOwner: TComponent);
var
  LThemingServices: IOTAIDEThemingServices;
begin
  FormDextTestRunner := Self;
  inherited Create(AOwner);
  Caption := 'Dext Test Explorer';
  Name := 'FormDextTestRunner';
  DeskSection := 'FormDextTestRunner';
  AutoSave := True;
  SaveStateNecessary := True;

  FTestLocations := TList<TTestLocation>.Create;
  FServer := TTestRunnerServer.Create(8102);

  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
      LThemingServices.ApplyTheme(Self);
  end;

  ApplyIDETheme;
  RefreshProjects;
  FServer.Start(OnTestResultReceived);
end;

destructor TFormDextTestRunner.Destroy;
begin
  FServer.Stop;
  FServer.Free;
  FTestLocations.Free;
  if FormDextTestRunner = Self then
    FormDextTestRunner := nil;
  inherited Destroy;
end;

procedure TFormDextTestRunner.DoShow;
begin
  inherited DoShow;
  RefreshProjects;
  ApplyIDETheme;
end;

procedure TFormDextTestRunner.ApplyIDETheme;
var
  LThemingServices: IOTAIDEThemingServices;
begin
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      // Custom theme overrides for background/foreground standard colors
      tvTests.Color := LThemingServices.StyleServices.GetSystemColor(clWindow);
      memDetails.Color := LThemingServices.StyleServices.GetSystemColor(clWindow);
    end;
  end;
end;

procedure TFormDextTestRunner.RefreshProjects;
var
  LModuleServices: IOTAModuleServices;
  LGroup: IOTAProjectGroup;
  I: Integer;
  LProj: IOTAProject;
  LProjFile: string;
begin
  cbProjects.Items.Clear;
  if not Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) then
    Exit;

  LGroup := LModuleServices.MainProjectGroup;
  if Assigned(LGroup) then
  begin
    for I := 0 to LGroup.ProjectCount - 1 do
    begin
      LProj := LGroup.Projects[I];
      if Assigned(LProj) then
      begin
        LProjFile := LProj.FileName;
        if (LProjFile.ToLower.Contains('test') or LProjFile.ToLower.Contains('tests')) and 
           SameText(ExtractFileExt(LProjFile), '.dproj') then
        begin
          cbProjects.Items.AddObject(ExtractFileName(LProjFile), TObject(Pointer(LProj)));
        end;
      end;
    end;
  end;

  if cbProjects.Items.Count > 0 then
  begin
    cbProjects.ItemIndex := 0;
    cbProjectsChange(cbProjects);
  end;
end;

procedure TFormDextTestRunner.cbProjectsChange(Sender: TObject);
var
  LProj: IOTAProject;
  I: Integer;
  LFile: string;
  LTests: TList<TTestLocation>;
  LTest: TTestLocation;
  LFixtureNode, LMethodNode: TTreeNode;
begin
  tvTests.Items.BeginUpdate;
  try
    tvTests.Items.Clear;
    FTestLocations.Clear;

    if cbProjects.ItemIndex = -1 then Exit;

    LProj := IOTAProject(Pointer(cbProjects.Items.Objects[cbProjects.ItemIndex]));
    if not Assigned(LProj) then Exit;

    FActiveProjectFile := LProj.FileName;

    // Scan all unit files in the project to statically discover tests
    for I := 0 to LProj.GetModuleCount - 1 do
    begin
      LFile := LProj.GetModule(I).FileName;
      if SameText(ExtractFileExt(LFile), '.pas') then
      begin
        LTests := nil;
        if TTestASTScanner.ScanFile(LFile, LTests) then
        begin
          for LTest in LTests do
          begin
            FTestLocations.Add(LTest);

            // Populate Tree View
            LFixtureNode := FindNodeByPath(LTest.ClassName);
            if not Assigned(LFixtureNode) then
              LFixtureNode := tvTests.Items.AddChild(nil, LTest.ClassName);

            LMethodNode := tvTests.Items.AddChild(LFixtureNode, LTest.MethodName);
            LMethodNode.Data := Pointer(FTestLocations.Count - 1); // Index of location
          end;
        end;
        if Assigned(LTests) then
          LTests.Free;
      end;
    end;

    tvTests.FullExpand;
  finally
    tvTests.Items.EndUpdate;
  end;
end;

function TFormDextTestRunner.FindNodeByPath(const APath: string): TTreeNode;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to tvTests.Items.Count - 1 do
  begin
    if SameText(tvTests.Items[I].Text, APath) then
    begin
      Result := tvTests.Items[I];
      Exit;
    end;
  end;
end;

procedure TFormDextTestRunner.OnTestResultReceived(const AJSONData: string);
var
  LJSON: TJSONObject;
  LTestName, LStatus, LMsg, LStackTrace: string;
  LErrorObj: TJSONObject;
begin
  LJSON := TJSONObject.ParseJSONValue(AJSONData) as TJSONObject;
  if not Assigned(LJSON) then Exit;

  try
    LTestName := LJSON.GetValue<string>('testName');
    LStatus := LJSON.GetValue<string>('status');
    LMsg := '';
    LStackTrace := '';

    if LJSON.TryGetValue<TJSONObject>('error', LErrorObj) and Assigned(LErrorObj) then
    begin
      LMsg := LErrorObj.GetValue<string>('message');
      LStackTrace := LErrorObj.GetValue<TJSONObject>('stackTrace').ToJSON;
    end;

    UpdateTestNode(LTestName, LStatus, LMsg, LStackTrace);
  finally
    LJSON.Free;
  end;
end;

procedure TFormDextTestRunner.UpdateTestNode(const ATestName, AStatus, AMessage, AStackTrace: string);
var
  LNode: TTreeNode;
  LText: string;
begin
  // ATestName is usually in the format: ClassName.MethodName or TClassName.MethodName
  LNode := FindNodeByPath(ATestName);
  if not Assigned(LNode) then
  begin
    // Fallback: search for method leaf node matching method portion
    LText := ATestName;
    if LText.Contains('.') then
      LText := LText.Split(['.'])[1];
    LNode := FindNodeByPath(LText);
  end;

  if Assigned(LNode) then
  begin
    if SameText(AStatus, 'Passed') then
      LNode.Text := LNode.Text + ' [PASS]'
    else if SameText(AStatus, 'Failed') or SameText(AStatus, 'Error') then
    begin
      LNode.Text := LNode.Text + ' [FAIL]';
      if AMessage <> '' then
      begin
        memDetails.Lines.Add('Test Failed: ' + ATestName);
        memDetails.Lines.Add('Error: ' + AMessage);
        if AStackTrace <> '' then
        begin
          memDetails.Lines.Add('Stack Trace:');
          memDetails.Lines.Add(AStackTrace);
        end;
        memDetails.Lines.Add('----------------------------------------');
      end;
    end;
  end;
end;

procedure TFormDextTestRunner.RunActiveProjectTests(const ATestFilter: string);
var
  LProj: IOTAProject;
  LOutDir, LExeFile, LCmdLine: string;
  SI: TStartupInfo;
  PI: TProcessInformation;
  LParams: string;
begin
  if cbProjects.ItemIndex = -1 then Exit;
  LProj := IOTAProject(Pointer(cbProjects.Items.Objects[cbProjects.ItemIndex]));
  if not Assigned(LProj) then Exit;

  memDetails.Clear;
  memDetails.Lines.Add('Compiling project: ' + ExtractFileName(FActiveProjectFile));

  // 1. Build project using MSBuild Make target
  // (In production this calls MSBuild or DCC direct compiler bypass)
  LOutDir := ExtractFilePath(FActiveProjectFile) + 'Win32\Debug';
  LExeFile := LOutDir + '\' + ChangeFileExt(ExtractFileName(FActiveProjectFile), '.exe');

  // Trigger compiler check
  LProj.ProjectBuilder.BuildProject(cmOTAMake, True, True);

  if not FileExists(LExeFile) then
  begin
    memDetails.Lines.Add('Error: Executable not found at ' + LExeFile);
    Exit;
  end;

  memDetails.Lines.Add('Executing tests...');

  // 2. Launch test executable in background
  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  
  LParams := Format('--port %d', [FServer.Port]);
  if ATestFilter <> '' then
    LParams := LParams + ' --filter ' + ATestFilter;

  LCmdLine := Format('"%s" %s', [LExeFile, LParams]);
  UniqueString(LCmdLine);

  if CreateProcess(nil, PChar(LCmdLine), nil, nil, False, CREATE_NO_WINDOW, nil, PChar(ExtractFilePath(LExeFile)), SI, PI) then
  begin
    CloseHandle(PI.hProcess);
    CloseHandle(PI.hThread);
  end
  else
  begin
    memDetails.Lines.Add('Failed to launch runner: ' + LExeFile);
  end;
end;

procedure TFormDextTestRunner.btnRunAllClick(Sender: TObject);
begin
  RunActiveProjectTests;
end;

procedure TFormDextTestRunner.btnRunSelectedClick(Sender: TObject);
begin
  if Assigned(tvTests.Selected) and (tvTests.Selected.Parent <> nil) then
  begin
    // Run selected method
    RunActiveProjectTests(tvTests.Selected.Text);
  end
  else
    RunActiveProjectTests;
end;

procedure TFormDextTestRunner.btnStopClick(Sender: TObject);
begin
  // Send cancel signals
end;

procedure TFormDextTestRunner.tvTestsDblClick(Sender: TObject);
var
  LNode: TTreeNode;
  LIdx: Integer;
  LLoc: TTestLocation;
  LModuleServices: IOTAModuleServices;
  LProj: IOTAProject;
  I: Integer;
  LFile: string;
  LModule: IOTAModule;
  LSourceEditor: IOTASourceEditor;
  LView: IOTAEditView;
  LPos: IOTAEditPosition;
begin
  LNode := tvTests.Selected;
  if not Assigned(LNode) or (LNode.Data = nil) then Exit;

  LIdx := Integer(LNode.Data);
  if (LIdx < 0) or (LIdx >= FTestLocations.Count) then Exit;

  LLoc := FTestLocations[LIdx];

  // Navigate to editor line
  if Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) then
  begin
    LProj := IOTAProject(Pointer(cbProjects.Items.Objects[cbProjects.ItemIndex]));
    if not Assigned(LProj) then Exit;

    for I := 0 to LProj.GetModuleCount - 1 do
    begin
      LFile := LProj.GetModule(I).FileName;
      if SameText(ExtractFileExt(LFile), '.pas') then
      begin
        LModule := LModuleServices.FindModule(LFile);
        if Assigned(LModule) then
        begin
          if LModule.FileName.Contains(LLoc.ClassName) or FileExists(LFile) then
          begin
            // Open editor
            LModule.Show;
            if Supports(LModule.CurrentEditor, IOTASourceEditor, LSourceEditor) then
            begin
              LView := LSourceEditor.GetEditView(0);
              if Assigned(LView) then
              begin
                LPos := LView.Position;
                LPos.Move(LLoc.Line, 1);
              end;
            end;
            Break;
          end;
        end;
      end;
    end;
  end;
end;

initialization
  RegisterDockableForm;

finalization
  UnregisterDockableForm;

end.
