unit Dext.Testing.Design.DockableForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, DockForm, ToolsAPI, Dext.Testing.Design.Server, Dext.Testing.Design.AST,
  System.JSON, System.Generics.Collections, System.IOUtils, System.Threading,
  System.ImageList, Vcl.ImgList;

type
  TFormDextTestRunner = class(TDockableForm)
    ToolbarPanel: TPanel;
    ProjectsComboBox: TComboBox;
    RunAllButton: TButton;
    RunSelectedButton: TButton;
    StopButton: TButton;
    RefreshButton: TButton;
    ButtonsPanel: TPanel;
    SessionsPageControl: TPageControl;
    DefaultSessionTabSheet: TTabSheet;
    TestsTreeView: TTreeView;
    DetailsPanel: TPanel;
    DetailsMemo: TMemo;
    NameSplitter: TSplitter;
    procedure ProjectsComboBoxChange(Sender: TObject);
    procedure RunAllButtonClick(Sender: TObject);
    procedure RunSelectedButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure TestsTreeViewDblClick(Sender: TObject);
    procedure RefreshButtonClick(Sender: TObject);
  private
    FServer: TTestRunnerServer;
    FTestLocations: TList<TTestLocation>;
    FActiveProjectFile: string;
    FScanGeneration: Integer;
    procedure ApplyIDETheme;
    procedure RefreshProjects;
    procedure OnTestResultReceived(const AJSONData: string);
    procedure UpdateTestNode(const ATestName, AStatus, AMessage, AStackTrace: string);
    procedure RunActiveProjectTests(const ATestFilter: string = '');
    function FindNodeByPath(const APath: string): TTreeNode;
    procedure ClearTestStatus;
  protected
    procedure DoShow; override;
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
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

function GetModuleBuildTime: string;
var
  LFilePath: array[0..MAX_PATH] of Char;
  LFileTime: TFileTime;
  LSystemTime: TSystemTime;
  LLocalTime: TSystemTime;
  LHandle: THandle;
begin
  Result := '';
  if GetModuleFileName(HInstance, LFilePath, Length(LFilePath)) > 0 then
  begin
    LHandle := CreateFile(LFilePath, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    if LHandle <> INVALID_HANDLE_VALUE then
    begin
      try
        if GetFileTime(LHandle, nil, nil, @LFileTime) then
        begin
          if FileTimeToSystemTime(LFileTime, LSystemTime) then
          begin
            if SystemTimeToTzSpecificLocalTime(nil, LSystemTime, LLocalTime) then
            begin
              Result := Format('%.4d-%.2d-%.2d %.2d:%.2d:%.2d',
                [LLocalTime.wYear, LLocalTime.wMonth, LLocalTime.wDay,
                 LLocalTime.wHour, LLocalTime.wMinute, LLocalTime.wSecond]);
            end;
          end;
        end;
      finally
        CloseHandle(LHandle);
      end;
    end;
  end;
end;

{ TFormDextTestRunner }

constructor TFormDextTestRunner.Create(AOwner: TComponent);
var
  LThemingServices: IOTAIDEThemingServices;
  LImageList: TImageList;
  LBitmap: TBitmap;
  procedure DrawSmoothCircle(AColor: TColor; ADest: TBitmap);
  var
    LLargeBmp: TBitmap;
  begin
    LLargeBmp := TBitmap.Create;
    try
      LLargeBmp.SetSize(64, 64);
      LLargeBmp.Canvas.Brush.Color := clWhite;
      LLargeBmp.Canvas.FillRect(Rect(0, 0, 64, 64));
      
      LLargeBmp.Canvas.Pen.Color := AColor;
      LLargeBmp.Canvas.Brush.Color := AColor;
      // Draw 32x32 circle centered in 64x64
      LLargeBmp.Canvas.Ellipse(16, 16, 48, 48);
      
      ADest.Canvas.Brush.Color := clWhite;
      ADest.Canvas.FillRect(Rect(0, 0, 16, 16));
      
      SetStretchBltMode(ADest.Canvas.Handle, HALFTONE);
      SetBrushOrgEx(ADest.Canvas.Handle, 0, 0, nil);
      StretchBlt(ADest.Canvas.Handle, 0, 0, 16, 16, LLargeBmp.Canvas.Handle, 0, 0, 64, 64, SRCCOPY);
    finally
      LLargeBmp.Free;
    end;
  end;

begin
  FormDextTestRunner := Self;
  inherited Create(AOwner);
  Caption := 'Dext Test Explorer (Compiled: ' + GetModuleBuildTime + ')';
  Name := 'FormDextTestRunner';
  DeskSection := 'FormDextTestRunner';
  AutoSave := True;
  SaveStateNecessary := True;

  // Set button captions with elegant symbols
  RefreshButton.Caption := '↻ Refresh';
  RunAllButton.Caption := '▶ Run All';
  RunSelectedButton.Caption := '▶ Selected';
  StopButton.Caption := '■ Stop';

  // Create and populate ImageList for TreeView status icons
  LImageList := TImageList.Create(Self);
  LImageList.Width := 16;
  LImageList.Height := 16;
  
  LBitmap := TBitmap.Create;
  try
    LBitmap.SetSize(16, 16);
    
    // 0: Idle (Gray circle)
    DrawSmoothCircle(clGray, LBitmap);
    LImageList.AddMasked(LBitmap, clWhite);
    
    // 1: Pass (Green circle)
    DrawSmoothCircle(TColor($22C55E), LBitmap);
    LImageList.AddMasked(LBitmap, clWhite);

    // 2: Fail (Red circle)
    DrawSmoothCircle(TColor($EF4444), LBitmap);
    LImageList.AddMasked(LBitmap, clWhite);

    // 3: Fixture (Blue circle/folder icon)
    DrawSmoothCircle(TColor($3B82F6), LBitmap);
    LImageList.AddMasked(LBitmap, clWhite);
  finally
    LBitmap.Free;
  end;
  
  TestsTreeView.Images := LImageList;

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
      TestsTreeView.Color := LThemingServices.StyleServices.GetSystemColor(clWindow);
      TestsTreeView.Font.Color := LThemingServices.StyleServices.GetSystemColor(clWindowText);
      DetailsMemo.Color := LThemingServices.StyleServices.GetSystemColor(clWindow);
      DetailsMemo.Font.Color := LThemingServices.StyleServices.GetSystemColor(clWindowText);
    end;
  end;
end;

procedure TFormDextTestRunner.CMStyleChanged(var Message: TMessage);
begin
  inherited;
  TThread.ForceQueue(nil, procedure
    begin
      ApplyIDETheme;
    end);
end;

function GetProjectTargetInfo(const ADprojPath: string; out AIsPackage: Boolean; out AExeOutput: string): Boolean;
var
  LContent: string;
  LMainSourceStart, LMainSourceEnd: Integer;
  LMainSource: string;
  LExeOutStart, LExeOutEnd: Integer;
begin
  Result := False;
  AIsPackage := False;
  AExeOutput := '';
  if not FileExists(ADprojPath) then Exit;
  
  try
    LContent := TFile.ReadAllText(ADprojPath);
    
    // Check MainSource
    LMainSourceStart := LContent.IndexOf('<MainSource>');
    if LMainSourceStart >= 0 then
    begin
      Inc(LMainSourceStart, Length('<MainSource>'));
      LMainSourceEnd := LContent.IndexOf('</MainSource>', LMainSourceStart);
      if LMainSourceEnd > LMainSourceStart then
      begin
        LMainSource := LContent.Substring(LMainSourceStart, LMainSourceEnd - LMainSourceStart).Trim;
        if LMainSource.EndsWith('.dpk', True) then
          AIsPackage := True;
      end;
    end;

    // Check ProjectType
    if not AIsPackage then
    begin
      if LContent.Contains('<Borland.ProjectType>Package</Borland.ProjectType>') then
        AIsPackage := True;
    end;

    // Get DCC_ExeOutput
    LExeOutStart := LContent.LastIndexOf('<DCC_ExeOutput>');
    if LExeOutStart >= 0 then
    begin
      Inc(LExeOutStart, Length('<DCC_ExeOutput>'));
      LExeOutEnd := LContent.IndexOf('</DCC_ExeOutput>', LExeOutStart);
      if LExeOutEnd > LExeOutStart then
      begin
        AExeOutput := LContent.Substring(LExeOutStart, LExeOutEnd - LExeOutStart).Trim;
      end;
    end;
    
    Result := True;
  except
    // ignore
  end;
end;

function ResolveExePath(const ADprojPath, AExeOutput: string): string;
var
  LProjectDir: string;
  LOutputDir: string;
  LProjectName: string;
begin
  LProjectDir := ExtractFilePath(ADprojPath);
  LProjectName := ChangeFileExt(ExtractFileName(ADprojPath), '');
  
  if AExeOutput <> '' then
  begin
    if TPath.IsRelativePath(AExeOutput) then
      LOutputDir := TPath.GetFullPath(TPath.Combine(LProjectDir, AExeOutput))
    else
      LOutputDir := AExeOutput;
  end
  else
  begin
    LOutputDir := TPath.Combine(LProjectDir, 'Win32\Debug');
  end;
  
  Result := TPath.Combine(LOutputDir, LProjectName + '.exe');
end;

procedure TFormDextTestRunner.RefreshProjects;
var
  LModuleServices: IOTAModuleServices;
  LGroup: IOTAProjectGroup;
  I: Integer;
  LProj: IOTAProject;
  LProjFile: string;
  LIsPackage: Boolean;
  LOutput: string;
begin
  ProjectsComboBox.Items.Clear;
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
          LIsPackage := False;
          LOutput := '';
          if GetProjectTargetInfo(LProjFile, LIsPackage, LOutput) and LIsPackage then
            Continue;

          ProjectsComboBox.Items.AddObject(ExtractFileName(LProjFile), TObject(Pointer(LProj)));
        end;
      end;
    end;
  end;

  if ProjectsComboBox.Items.Count > 0 then
  begin
    ProjectsComboBox.ItemIndex := 0;
    ProjectsComboBoxChange(ProjectsComboBox);
  end;
end;

procedure TFormDextTestRunner.ProjectsComboBoxChange(Sender: TObject);
var
  LProj: IOTAProject;
  I: Integer;
  LFiles: TArray<string>;
  LGeneration: Integer;
begin
  if ProjectsComboBox.ItemIndex = -1 then Exit;

  LProj := IOTAProject(Pointer(ProjectsComboBox.Items.Objects[ProjectsComboBox.ItemIndex]));
  if not Assigned(LProj) then Exit;

  FActiveProjectFile := LProj.FileName;

  // 1. Gather all files to scan on the main thread (safe for OTA)
  SetLength(LFiles, LProj.GetModuleCount);
  for I := 0 to LProj.GetModuleCount - 1 do
    LFiles[I] := LProj.GetModule(I).FileName;

  // Clear UI and locations immediately to show it is loading/updating
  TestsTreeView.Items.BeginUpdate;
  try
    TestsTreeView.Items.Clear;
    FTestLocations.Clear;
    TestsTreeView.Items.AddChild(nil, 'Loading tests asynchronously...');
  finally
    TestsTreeView.Items.EndUpdate;
  end;

  // Increment scan generation to cancel/ignore stale scans
  Inc(FScanGeneration);
  LGeneration := FScanGeneration;

  // 2. Scan files asynchronously in a background task
  TTask.Run(procedure
    var
      LScanResults: TList<TTestLocation>;
      LFile: string;
      LTests: TList<TTestLocation>;
      LTest: TTestLocation;
    begin
      LScanResults := TList<TTestLocation>.Create;
      try
        for LFile in LFiles do
        begin
          if SameText(ExtractFileExt(LFile), '.pas') then
          begin
            LTests := nil;
            if TTestASTScanner.ScanFile(LFile, LTests) then
            begin
              for LTest in LTests do
                LScanResults.Add(LTest);
            end;
            LTests.Free;
          end;
        end;

        // 3. Update the UI back on the main thread
        TThread.Queue(nil, procedure
          var
            LIdx: Integer;
            LFixtureNode, LMethodNode: TTreeNode;
          begin
            // Discard results if another scan has started in the meantime
            if LGeneration <> FScanGeneration then
            begin
              LScanResults.Free;
              Exit;
            end;

            TestsTreeView.Items.BeginUpdate;
            try
              TestsTreeView.Items.Clear;
              FTestLocations.Clear;

              for LIdx := 0 to LScanResults.Count - 1 do
              begin
                LTest := LScanResults[LIdx];
                FTestLocations.Add(LTest);

                // Populate Tree View
                LFixtureNode := FindNodeByPath(LTest.ClassName);
                if not Assigned(LFixtureNode) then
                begin
                  LFixtureNode := TestsTreeView.Items.AddChild(nil, LTest.ClassName);
                  LFixtureNode.ImageIndex := 3;
                  LFixtureNode.SelectedIndex := 3;
                end;

                LMethodNode := TestsTreeView.Items.AddChild(LFixtureNode, LTest.MethodName);
                LMethodNode.Data := Pointer(FTestLocations.Count - 1); // Index of location
                LMethodNode.ImageIndex := 0;
                LMethodNode.SelectedIndex := 0;
              end;

              TestsTreeView.FullExpand;
            finally
              TestsTreeView.Items.EndUpdate;
              LScanResults.Free;
            end;
          end);
      except
        on E: Exception do
        begin
          LScanResults.Free;
        end;
      end;
    end);
end;

function TFormDextTestRunner.FindNodeByPath(const APath: string): TTreeNode;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to TestsTreeView.Items.Count - 1 do
  begin
    if SameText(TestsTreeView.Items[I].Text, APath) then
    begin
      Result := TestsTreeView.Items[I];
      Exit;
    end;
  end;
end;

procedure TFormDextTestRunner.OnTestResultReceived(const AJSONData: string);
var
  LJSON: TJSONObject;
  LTestName, LStatus, LMsg, LStackTrace: string;
  LErrorObj: TJSONObject;
  LEvent: string;
  LPassed, LFailed, LIgnored: Integer;
begin
  LJSON := TJSONObject.ParseJSONValue(AJSONData) as TJSONObject;
  if not Assigned(LJSON) then Exit;

  try
    if LJSON.TryGetValue<string>('event', LEvent) and SameText(LEvent, 'RunComplete') then
    begin
      LPassed := LJSON.GetValue<Integer>('passed');
      LFailed := LJSON.GetValue<Integer>('failed');
      LIgnored := LJSON.GetValue<Integer>('ignored');
      DetailsMemo.Lines.Add('');
      DetailsMemo.Lines.Add('========================================');
      DetailsMemo.Lines.Add(Format('Testing Completed. Passed: %d, Failed: %d, Ignored: %d', [LPassed, LFailed, LIgnored]));
      DetailsMemo.Lines.Add('========================================');
      Exit;
    end;

    DetailsMemo.Lines.Add('Result received: ' + AJSONData);
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
  LRect: TRect;
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
    begin
      LNode.ImageIndex := 1;
      LNode.SelectedIndex := 1;
    end
    else if SameText(AStatus, 'Failed') or SameText(AStatus, 'Error') then
    begin
      LNode.ImageIndex := 2;
      LNode.SelectedIndex := 2;
      if AMessage <> '' then
      begin
        DetailsMemo.Lines.Add('Test Failed: ' + ATestName);
        DetailsMemo.Lines.Add('Error: ' + AMessage);
        if AStackTrace <> '' then
        begin
          DetailsMemo.Lines.Add('Stack Trace:');
          DetailsMemo.Lines.Add(AStackTrace);
        end;
        DetailsMemo.Lines.Add('----------------------------------------');
      end;
    end;
    LRect := LNode.DisplayRect(False);
    InvalidateRect(TestsTreeView.Handle, @LRect, True);
  end;
end;

procedure TFormDextTestRunner.ClearTestStatus;
var
  I: Integer;
  LNode: TTreeNode;
begin
  TestsTreeView.Items.BeginUpdate;
  try
    for I := 0 to TestsTreeView.Items.Count - 1 do
    begin
      LNode := TestsTreeView.Items[I];
      if LNode.ImageIndex in [1, 2] then
      begin
        LNode.ImageIndex := 0;
        LNode.SelectedIndex := 0;
      end;
    end;
  finally
    TestsTreeView.Items.EndUpdate;
  end;
end;

procedure TFormDextTestRunner.RunActiveProjectTests(const ATestFilter: string);
var
  LProj: IOTAProject;
  LExeFile, LCmdLine: string;
  SI: TStartupInfo;
  PI: TProcessInformation;
  LParams: string;
  LIsPackage: Boolean;
  LOutput: string;
  LSplit: TArray<string>;
begin
  if ProjectsComboBox.ItemIndex = -1 then Exit;
  LProj := IOTAProject(Pointer(ProjectsComboBox.Items.Objects[ProjectsComboBox.ItemIndex]));
  if not Assigned(LProj) then Exit;

  ClearTestStatus;
  DetailsMemo.Clear;
  DetailsMemo.Lines.Add('Compiling project: ' + ExtractFileName(FActiveProjectFile));

  // Get dynamic executable path from project target info
  LIsPackage := False;
  LOutput := '';
  GetProjectTargetInfo(FActiveProjectFile, LIsPackage, LOutput);
  LExeFile := ResolveExePath(FActiveProjectFile, LOutput);
  DetailsMemo.Lines.Add('Resolved Executable: ' + LExeFile);

  // Trigger compiler check quietly without showing modal dialog
  LProj.ProjectBuilder.BuildProject(cmOTAMake, False, True);

  if not FileExists(LExeFile) then
  begin
    DetailsMemo.Lines.Add('Error: Executable not found at ' + LExeFile);
    Exit;
  end;

  // Set the selected tests in the design-time server to be queried by the runner via GET /tests
  if ATestFilter <> '' then
    FServer.SelectedTestsJSON := '["' + ATestFilter + '"]'
  else
    FServer.SelectedTestsJSON := '[]';

  DetailsMemo.Lines.Add('Selected tests filter JSON: ' + FServer.SelectedTestsJSON);
  DetailsMemo.Lines.Add('Executing tests...');

  // 2. Launch test executable in background using Dext native port + filter parameters
  LParams := Format('--port %d -no-wait', [FServer.Port]);
  if ATestFilter <> '' then
  begin
    LSplit := ATestFilter.Split(['.']);
    if Length(LSplit) >= 2 then
      LParams := LParams + ' -fixture:' + LSplit[0] + ' -filter:' + LSplit[1]
    else
      LParams := LParams + ' -filter:' + ATestFilter;
  end;

  LCmdLine := Format('"%s" %s', [LExeFile, LParams]);
  DetailsMemo.Lines.Add('Command Line: ' + LCmdLine);
  UniqueString(LCmdLine);

  if CreateProcess(nil, PChar(LCmdLine), nil, nil, False, CREATE_NO_WINDOW, nil, PChar(ExtractFilePath(LExeFile)), SI, PI) then
  begin
    CloseHandle(PI.hProcess);
    CloseHandle(PI.hThread);
  end
  else
  begin
    DetailsMemo.Lines.Add('Failed to launch runner: ' + LExeFile);
  end;
end;

procedure TFormDextTestRunner.RunAllButtonClick(Sender: TObject);
begin
  RunActiveProjectTests;
end;

procedure TFormDextTestRunner.RunSelectedButtonClick(Sender: TObject);
begin
  if Assigned(TestsTreeView.Selected) and (TestsTreeView.Selected.Parent <> nil) then
  begin
    // Run selected method (Fully qualified as ClassName.MethodName)
    RunActiveProjectTests(TestsTreeView.Selected.Parent.Text + '.' + TestsTreeView.Selected.Text);
  end
  else
    RunActiveProjectTests;
end;

procedure TFormDextTestRunner.StopButtonClick(Sender: TObject);
begin
  // Send cancel signals
end;

procedure TFormDextTestRunner.TestsTreeViewDblClick(Sender: TObject);
var
  LNode: TTreeNode;
  LIdx: Integer;
  LLoc: TTestLocation;
  LModuleServices: IOTAModuleServices;
  LModule: IOTAModule;
  LSourceEditor: IOTASourceEditor;
  LView: IOTAEditView;
begin
  LNode := TestsTreeView.Selected;
  if not Assigned(LNode) or (LNode.Data = nil) then Exit;

  LIdx := Integer(LNode.Data);
  if (LIdx < 0) or (LIdx >= FTestLocations.Count) then Exit;

  LLoc := FTestLocations[LIdx];
  if LLoc.FileName = '' then Exit;

  // Navigate directly using the exact unit file path
  if Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) then
  begin
    LModule := LModuleServices.OpenModule(LLoc.FileName);
    if Assigned(LModule) then
    begin
      LModule.Show;
      if Supports(LModule.CurrentEditor, IOTASourceEditor, LSourceEditor) then
      begin
        LView := LSourceEditor.GetEditView(0);
        if Assigned(LView) then
        begin
          LView.Position.Move(LLoc.Line, 1);
        end;
      end;
    end;
  end;
end;

procedure TFormDextTestRunner.RefreshButtonClick(Sender: TObject);
begin
  RefreshProjects;
end;

initialization
  RegisterDockableForm;

finalization
  UnregisterDockableForm;

end.
