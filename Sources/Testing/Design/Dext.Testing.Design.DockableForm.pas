unit Dext.Testing.Design.DockableForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, DockForm, ToolsAPI, Dext.Testing.Design.Server, Dext.Testing.Design.AST,
  System.JSON, System.Generics.Collections, System.IOUtils, System.Threading,
  System.ImageList, Vcl.ImgList, Vcl.Menus, System.Math;

type
  TFormDextTestRunner = class;

  TTestDetailInfo = record
    TestName: string;
    Status: string;
    FileName: string;
    Line: Integer;
    DurationMs: Double;
    ErrorMessage: string;
    StackTrace: string;
  end;

  TTestSession = class
  public
    TabSheet: TTabSheet;
    TreeView: TTreeView;
    TestLocations: TList<TTestLocation>;
    ActiveProjectFile: string;
    constructor Create(APageControl: TPageControl; const AName: string); overload;
    constructor CreateFromExisting(ATabSheet: TTabSheet; ATreeView: TTreeView; ALocations: TList<TTestLocation>; const AProjFile: string); overload;
    destructor Destroy; override;
  end;

  TTelemetryTracker = class
  public
    class procedure RecordTestResult(const AProjectFile, ATestName, AStatus: string; ADurationMs: Integer);
    class procedure AnalyzeHistory(const AProjectFile: string; AMemo: TMemo);
  end;

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
    FHoverNode: TTreeNode;
    
    // Sessions
    FSessions: TObjectList<TTestSession>;
    FActiveSession: TTestSession;
    FAddTab: TTabSheet;
    
    // Test Inspector components
    FTestDetails: TDictionary<string, TTestDetailInfo>;
    FDetailsPageControl: TPageControl;
    FConsoleTab: TTabSheet;
    FInspectorTab: TTabSheet;
    FInspectorScroll: TScrollBox;
    FLblTestName: TLabel;
    FLblStatus: TLabel;
    FLblLocation: TLabel;
    FLblDuration: TLabel;
    FLblErrorHeader: TLabel;
    FMemoError: TMemo;
    // Progress tracking
    FProgressBar: TProgressBar;
    FProgressLabel: TLabel;
    FProgressPanel: TPanel;
    FTotalTests: Integer;
    FCompletedTests: Integer;
    procedure TestsTreeViewChange(Sender: TObject; Node: TTreeNode);
    procedure UpdateTestInspector(const ATestName: string);
    procedure SetActiveSession(ASession: TTestSession);
    procedure SessionsPageControlChange(Sender: TObject);
    procedure SessionTabContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure CloseActiveSessionClick(Sender: TObject);
    function CompileProjectDirect(const AProjFile: string): Boolean;
    procedure CreateNewSession(const AName: string);
    procedure CloseSession(ASession: TTestSession);
    procedure TryLoadCoverage;
    procedure ApplyIDETheme;
    procedure RefreshProjects;
    procedure OnTestResultReceived(const AJSONData: string);
    procedure UpdateTestNode(const ATestName, AStatus, AMessage, AStackTrace: string);
    function FindNodeByPath(const APath: string): TTreeNode;
    procedure ClearTestStatus;
    function GetCheckedTests: TArray<string>;
    function GetRunButtonRect(ANode: TTreeNode): TRect;
    procedure TestsTreeViewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure TestsTreeViewMouseLeave(Sender: TObject);
    procedure TestsTreeViewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure TestsTreeViewMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure TestsTreeViewAdvancedCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage; var PaintImages, DefaultDraw: Boolean);
    procedure DebugSelectedClick(Sender: TObject);
    procedure RunAllProjectsClick(Sender: TObject);
    procedure RunAllProjectsTests;
  protected
    procedure DoShow; override;
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RunActiveProjectTests(const ATestFilter: string = '');
    procedure RunImpactedTests(const ATests: TArray<string>);
    procedure HandleFileSaved(const AFileName: string);
  end;

procedure ShowDextTestExplorer;
procedure RegisterDockableForm;
procedure UnregisterDockableForm;

var
  FormDextTestRunner: TFormDextTestRunner = nil;

implementation

{$R *.dfm}

uses
  DeskUtil, Dext.Utils, System.Actions, Vcl.ActnList, Dext.Testing.Design.Coverage;

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

{ TTestSession }

constructor TTestSession.Create(APageControl: TPageControl; const AName: string);
begin
  inherited Create;
  TestLocations := TList<TTestLocation>.Create;
  
  TabSheet := TTabSheet.Create(APageControl.Owner);
  TabSheet.PageControl := APageControl;
  TabSheet.Caption := AName;
  
  TreeView := TTreeView.Create(TabSheet);
  TreeView.Parent := TabSheet;
  TreeView.Align := alClient;
  TreeView.ReadOnly := True;
  TreeView.HideSelection := False;
  TreeView.Checkboxes := True;
  TreeView.DoubleBuffered := True;
end;

constructor TTestSession.CreateFromExisting(ATabSheet: TTabSheet; ATreeView: TTreeView; ALocations: TList<TTestLocation>; const AProjFile: string);
begin
  inherited Create;
  TabSheet := ATabSheet;
  TreeView := ATreeView;
  TestLocations := ALocations;
  ActiveProjectFile := AProjFile;
end;

destructor TTestSession.Destroy;
begin
  if (TabSheet <> nil) and not (csDestroying in TabSheet.ComponentState) then
  begin
    TabSheet.Free;
  end;
  TestLocations.Free;
  inherited;
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

  // Set button captions with elegant symbols and hints
  RefreshButton.Caption := #$21BB + ' Refresh';
  RefreshButton.Hint := 'Scan project files and discover tests';
  RefreshButton.ShowHint := True;
  
  RunAllButton.Caption := #$25B6 + ' Run All';
  RunAllButton.Hint := 'Run all tests in the selected project (Click dropdown arrow for more options)';
  RunAllButton.ShowHint := True;
  
  var LRunAllMenu := TPopupMenu.Create(Self);
  var LRunAllItem1 := TMenuItem.Create(LRunAllMenu);
  LRunAllItem1.Caption := 'Run Selected Project';
  LRunAllItem1.OnClick := RunAllButtonClick;
  LRunAllMenu.Items.Add(LRunAllItem1);
  
  var LRunAllItem2 := TMenuItem.Create(LRunAllMenu);
  LRunAllItem2.Caption := 'Run All Test Projects';
  LRunAllItem2.OnClick := RunAllProjectsClick;
  LRunAllMenu.Items.Add(LRunAllItem2);
  
  RunAllButton.Style := bsSplitButton;
  RunAllButton.DropDownMenu := LRunAllMenu;
  
  RunSelectedButton.Caption := #$25B6 + ' Selected';
  RunSelectedButton.Hint := 'Run checked tests only';
  RunSelectedButton.ShowHint := True;
  
  StopButton.Caption := #$25A0 + ' Stop';
  StopButton.Hint := 'Cancel current test execution';
  StopButton.ShowHint := True;

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
  TestsTreeView.Checkboxes := True;
  TestsTreeView.DoubleBuffered := True;
  
  // Assign advanced dynamic event handlers
  TestsTreeView.OnMouseMove := TestsTreeViewMouseMove;
  TestsTreeView.OnMouseLeave := TestsTreeViewMouseLeave;
  TestsTreeView.OnMouseDown := TestsTreeViewMouseDown;
  TestsTreeView.OnMouseUp := TestsTreeViewMouseUp;
  TestsTreeView.OnAdvancedCustomDrawItem := TestsTreeViewAdvancedCustomDrawItem;
  TestsTreeView.OnChange := TestsTreeViewChange;

  // Build Context Menu
  var LPopupMenu := TPopupMenu.Create(Self);
  var LItem := TMenuItem.Create(LPopupMenu);
  LItem.Caption := #$25B6 + ' Run';
  LItem.OnClick := RunSelectedButtonClick;
  LPopupMenu.Items.Add(LItem);
  
  LItem := TMenuItem.Create(LPopupMenu);
  LItem.Caption := 'Debug';
  LItem.OnClick := DebugSelectedClick;
  LPopupMenu.Items.Add(LItem);
  
  LItem := TMenuItem.Create(LPopupMenu);
  LItem.Caption := 'Go to Source';
  LItem.OnClick := TestsTreeViewDblClick;
  LPopupMenu.Items.Add(LItem);
  
  TestsTreeView.PopupMenu := LPopupMenu;

  FTestLocations := TList<TTestLocation>.Create;
  FSessions := TObjectList<TTestSession>.Create(True);
  FActiveSession := TTestSession.CreateFromExisting(DefaultSessionTabSheet, TestsTreeView, FTestLocations, FActiveProjectFile);
  FSessions.Add(FActiveSession);

  FAddTab := TTabSheet.Create(Self);
  FAddTab.PageControl := SessionsPageControl;
  FAddTab.Caption := '  +  ';

  SessionsPageControl.OnChange := SessionsPageControlChange;
  SessionsPageControl.OnContextPopup := SessionTabContextPopup;

  FServer := TTestRunnerServer.Create(8102);

  // Initialize Inspector UI dynamically
  FTestDetails := TDictionary<string, TTestDetailInfo>.Create;
  FTotalTests := 0;
  FCompletedTests := 0;

  // Create progress bar inside DetailsPanel at the top (hidden until running)
  FProgressPanel := TPanel.Create(Self);
  FProgressPanel.Parent := DetailsPanel;
  FProgressPanel.Align := alTop;
  FProgressPanel.Height := 20;
  FProgressPanel.BevelOuter := bvNone;
  FProgressPanel.Visible := False; // only shown when tests are running

  FProgressLabel := TLabel.Create(Self);
  FProgressLabel.Parent := FProgressPanel;
  FProgressLabel.Align := alLeft;
  FProgressLabel.Layout := tlCenter;
  FProgressLabel.Caption := '';
  FProgressLabel.Width := 55;
  FProgressLabel.Font.Size := 7;
  FProgressLabel.Margins.Left := 2;

  FProgressBar := TProgressBar.Create(Self);
  FProgressBar.Parent := FProgressPanel;
  FProgressBar.Align := alClient;
  FProgressBar.Min := 0;
  FProgressBar.Max := 100;
  FProgressBar.Position := 0;
  FProgressBar.Style := pbstNormal;

  FDetailsPageControl := TPageControl.Create(Self);
  FDetailsPageControl.Parent := DetailsPanel;
  FDetailsPageControl.Align := alClient;

  FConsoleTab := TTabSheet.Create(Self);
  FConsoleTab.PageControl := FDetailsPageControl;
  FConsoleTab.Caption := 'Console Log';

  DetailsMemo.Parent := FConsoleTab;
  DetailsMemo.Align := alClient;

  FInspectorTab := TTabSheet.Create(Self);
  FInspectorTab.PageControl := FDetailsPageControl;
  FInspectorTab.Caption := 'Test Inspector';

  FInspectorScroll := TScrollBox.Create(Self);
  FInspectorScroll.Parent := FInspectorTab;
  FInspectorScroll.Align := alClient;
  FInspectorScroll.BorderStyle := bsNone;

  FLblTestName := TLabel.Create(Self);
  FLblTestName.Parent := FInspectorScroll;
  FLblTestName.Top := 8;
  FLblTestName.Left := 8;
  FLblTestName.Font.Style := [fsBold];
  FLblTestName.Caption := 'Test Name: Select a test...';

  FLblStatus := TLabel.Create(Self);
  FLblStatus.Parent := FInspectorScroll;
  FLblStatus.Top := 26;
  FLblStatus.Left := 8;
  FLblStatus.Caption := 'Status: Idle';

  FLblLocation := TLabel.Create(Self);
  FLblLocation.Parent := FInspectorScroll;
  FLblLocation.Top := 44;
  FLblLocation.Left := 8;
  FLblLocation.Caption := 'Location: N/A';

  FLblDuration := TLabel.Create(Self);
  FLblDuration.Parent := FInspectorScroll;
  FLblDuration.Top := 62;
  FLblDuration.Left := 8;
  FLblDuration.Caption := 'Duration: N/A';

  FLblErrorHeader := TLabel.Create(Self);
  FLblErrorHeader.Parent := FInspectorScroll;
  FLblErrorHeader.Top := 80;
  FLblErrorHeader.Left := 8;
  FLblErrorHeader.Font.Style := [fsBold];
  FLblErrorHeader.Caption := 'Errors / Stack Trace:';

  FMemoError := TMemo.Create(Self);
  FMemoError.Parent := FInspectorScroll;
  FMemoError.Top := 98;
  FMemoError.Left := 8;
  FMemoError.Width := FInspectorScroll.ClientWidth - 16;
  FMemoError.Height := 40;
  FMemoError.Anchors := [akLeft, akTop, akRight, akBottom];
  FMemoError.ReadOnly := True;
  FMemoError.ScrollBars := ssBoth;

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
  FSessions.Free;
  FTestDetails.Free;
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
      // Match IDE font size (Project Explorer uses 9pt typically)
      TestsTreeView.Font.Size := 9;
      DetailsMemo.Color := LThemingServices.StyleServices.GetSystemColor(clWindow);
      DetailsMemo.Font.Color := LThemingServices.StyleServices.GetSystemColor(clWindowText);
      if Assigned(FMemoError) then
      begin
        FMemoError.Color := LThemingServices.StyleServices.GetSystemColor(clWindow);
        FMemoError.Font.Color := LThemingServices.StyleServices.GetSystemColor(clWindowText);
      end;
    end;
  end;
end;

procedure TFormDextTestRunner.CMStyleChanged(var Message: TMessage);
begin
  inherited;
  TThread.ForceQueue(nil, TThreadProcedure(procedure
    begin
      ApplyIDETheme;
    end));
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
  if FActiveSession <> nil then
    FActiveSession.ActiveProjectFile := FActiveProjectFile;

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
  TTask.Run(TProc(procedure
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
        TThread.Queue(nil, TThreadProcedure(procedure
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
          end));
      except
        on E: Exception do
        begin
          LScanResults.Free;
        end;
      end;
    end));
end;

function TFormDextTestRunner.FindNodeByPath(const APath: string): TTreeNode;
var
  I: Integer;
  LNode: TTreeNode;
  LSplit: TArray<string>;
begin
  Result := nil;
  
  // If APath contains a dot, try to find the child node via ClassName.MethodName
  if APath.Contains('.') then
  begin
    LSplit := APath.Split(['.'], 2);
    if Length(LSplit) = 2 then
    begin
      for I := 0 to TestsTreeView.Items.Count - 1 do
      begin
        LNode := TestsTreeView.Items[I];
        if (LNode.Parent = nil) and SameText(LNode.Text, LSplit[0]) then
        begin
          var J: Integer;
          for J := 0 to LNode.Count - 1 do
          begin
            if SameText(LNode.Item[J].Text, LSplit[1]) then
            begin
              Result := LNode.Item[J];
              Exit;
            end;
          end;
        end;
      end;
    end;
  end;
  
  // Fallback: search all nodes by text
  if Result = nil then
  begin
    for I := 0 to TestsTreeView.Items.Count - 1 do
    begin
      if SameText(TestsTreeView.Items[I].Text, APath) then
      begin
        Result := TestsTreeView.Items[I];
        Exit;
      end;
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
  LDurationMs: Double;
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
      // Complete and then hide the progress panel
      if Assigned(FProgressPanel) then
      begin
        FProgressBar.Position := FProgressBar.Max;
        FProgressLabel.Caption := Format('%d/%d', [FCompletedTests, Max(FCompletedTests, FTotalTests)]);
        // Hide after a short delay so user can see 100%
        TThread.ForceQueue(nil, TThreadProcedure(procedure
          begin
            if Assigned(FProgressPanel) then
              FProgressPanel.Visible := False;
          end));
      end;
      TTelemetryTracker.AnalyzeHistory(FActiveProjectFile, DetailsMemo);
      TryLoadCoverage;
      Exit;
    end;
    
    if LJSON.TryGetValue<string>('event', LEvent) and SameText(LEvent, 'RunStart') then
    begin
      FTotalTests := LJSON.GetValue<Integer>('totalTests');
      FCompletedTests := 0;
      if Assigned(FProgressPanel) then
      begin
        FProgressBar.Max := Max(1, FTotalTests);
        FProgressBar.Position := 0;
        FProgressLabel.Caption := Format('0/%d', [FTotalTests]);
        FProgressPanel.Visible := True;
      end;
      Exit;
    end;


    DetailsMemo.Lines.Add('Result received: ' + AJSONData);
    LTestName := LJSON.GetValue<string>('testName');
    LStatus := LJSON.GetValue<string>('status');
    LMsg := '';
    LStackTrace := '';
    LDurationMs := 0;

    LJSON.TryGetValue<Double>('durationMs', LDurationMs);
    
    // Update progress bar
    Inc(FCompletedTests);
    if Assigned(FProgressPanel) and FProgressPanel.Visible then
    begin
      FProgressBar.Max := Max(FProgressBar.Max, FCompletedTests);
      FProgressBar.Position := FCompletedTests;
      FProgressLabel.Caption := Format('%d/%d', [FCompletedTests, Max(FCompletedTests, FTotalTests)]);
    end;
    
    TTelemetryTracker.RecordTestResult(FActiveProjectFile, LTestName, LStatus, Round(LDurationMs));

    if LJSON.TryGetValue<TJSONObject>('error', LErrorObj) and Assigned(LErrorObj) then
    begin
      LMsg := LErrorObj.GetValue<string>('message');
      LStackTrace := LErrorObj.GetValue<TJSONObject>('stackTrace').ToJSON;
    end;

    UpdateTestNode(LTestName, LStatus, LMsg, LStackTrace);

    // Cache test details
    var LInfo: TTestDetailInfo;
    LInfo.TestName := LTestName;
    LInfo.Status := LStatus;
    LInfo.DurationMs := LDurationMs;
    LInfo.ErrorMessage := LMsg;
    LInfo.StackTrace := LStackTrace;
    
    var LNode := FindNodeByPath(LTestName);
    if Assigned(LNode) and (LNode.Data <> nil) then
    begin
      var LIdx := Integer(LNode.Data);
      if (LIdx >= 0) and (LIdx < FTestLocations.Count) then
      begin
        LInfo.FileName := FTestLocations[LIdx].FileName;
        LInfo.Line := FTestLocations[LIdx].Line;
      end;
    end;
    
    FTestDetails.AddOrSetValue(LTestName, LInfo);
    
    // If this test is selected, update inspector tab
    if (TestsTreeView.Selected <> nil) and 
       (SameText(TestsTreeView.Selected.Text, LTestName) or 
        (TestsTreeView.Selected.Parent <> nil) and SameText(TestsTreeView.Selected.Parent.Text + '.' + TestsTreeView.Selected.Text, LTestName)) then
    begin
      UpdateTestInspector(LTestName);
    end;
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

procedure TFormDextTestRunner.TestsTreeViewChange(Sender: TObject; Node: TTreeNode);
var
  LKey: string;
begin
  if not Assigned(Node) then Exit;
  
  if Node.Parent = nil then
  begin
    UpdateTestInspector(Node.Text);
  end
  else
  begin
    LKey := Node.Parent.Text + '.' + Node.Text;
    UpdateTestInspector(LKey);
    if FTestDetails.ContainsKey(LKey) then
      FDetailsPageControl.ActivePage := FInspectorTab;
  end;
end;

procedure TFormDextTestRunner.UpdateTestInspector(const ATestName: string);
var
  LInfo: TTestDetailInfo;
  LStatusText: string;
  LNode: TTreeNode;
  LIdx: Integer;
  LLoc: TTestLocation;
begin
  if not Assigned(FLblTestName) then Exit;
  FLblTestName.Caption := 'Test Name: ' + ATestName;
  FMemoError.Clear;
  
  // Set default Location
  FLblLocation.Caption := 'Location: Unknown';
  LNode := FindNodeByPath(ATestName);
  if Assigned(LNode) and (LNode.Data <> nil) then
  begin
    LIdx := Integer(LNode.Data);
    if (LIdx >= 0) and (LIdx < FTestLocations.Count) then
    begin
      LLoc := FTestLocations[LIdx];
      FLblLocation.Caption := Format('Location: %s (Line %d)', [ExtractFileName(LLoc.FileName), LLoc.Line]);
    end;
  end;

  if FTestDetails.TryGetValue(ATestName, LInfo) then
  begin
    LStatusText := LInfo.Status;
    FLblStatus.Caption := 'Status: ' + LStatusText;
    if SameText(LStatusText, 'Passed') then
      FLblStatus.Font.Color := TColor($22C55E) // Green
    else if SameText(LStatusText, 'Failed') or SameText(LStatusText, 'Error') then
      FLblStatus.Font.Color := TColor($EF4444) // Red
    else
      FLblStatus.Font.Color := clWindowText;
      
    // Format duration intelligently: show sub-ms precision when needed
    if LInfo.DurationMs < 1.0 then
      FLblDuration.Caption := Format('Duration: %.3f ms', [LInfo.DurationMs])
    else if LInfo.DurationMs < 100.0 then
      FLblDuration.Caption := Format('Duration: %.2f ms', [LInfo.DurationMs])
    else
      FLblDuration.Caption := Format('Duration: %.0f ms', [LInfo.DurationMs]);
    
    if LInfo.ErrorMessage <> '' then
    begin
      FMemoError.Lines.Add('Error Message:');
      FMemoError.Lines.Add(LInfo.ErrorMessage);
      FMemoError.Lines.Add('');
    end;
    if LInfo.StackTrace <> '' then
    begin
      FMemoError.Lines.Add('Stack Trace:');
      FMemoError.Lines.Add(LInfo.StackTrace);
    end;
  end
  else
  begin
    FLblStatus.Caption := 'Status: Idle';
    FLblStatus.Font.Color := clWindowText;
    FLblDuration.Caption := 'Duration: N/A';
  end;
end;

procedure TFormDextTestRunner.ClearTestStatus;
var
  I: Integer;
  LNode: TTreeNode;
begin
  if Assigned(FTestDetails) then
    FTestDetails.Clear;
  if Assigned(FLblTestName) then
  begin
    FLblTestName.Caption := 'Test Name: Select a test...';
    FLblStatus.Caption := 'Status: Idle';
    FLblStatus.Font.Color := clWindowText;
    FLblLocation.Caption := 'Location: N/A';
    FLblDuration.Caption := 'Duration: N/A';
    FMemoError.Clear;
  end;

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
  LModuleServices: IOTAModuleServices;
  LGroup: IOTAProjectGroup;
begin
  if ProjectsComboBox.ItemIndex = -1 then Exit;
  LProj := IOTAProject(Pointer(ProjectsComboBox.Items.Objects[ProjectsComboBox.ItemIndex]));
  if not Assigned(LProj) then Exit;

  // Synchronize IDE Active Project
  if Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) and Assigned(LModuleServices) then
  begin
    LGroup := LModuleServices.MainProjectGroup;
    if Assigned(LGroup) and (LGroup.ActiveProject <> LProj) then
    begin
      LGroup.ActiveProject := LProj;
    end;
  end;

  ClearTestStatus;
  DetailsMemo.Clear;
  FTotalTests := 0;
  FCompletedTests := 0;
  if Assigned(FProgressPanel) then
  begin
    FProgressBar.Position := 0;
    FProgressBar.Max := 100;
    FProgressLabel.Caption := '...';
    FProgressPanel.Visible := True;
  end;
  // Focus Console Log
  if Assigned(FDetailsPageControl) and Assigned(FConsoleTab) then
    FDetailsPageControl.ActivePage := FConsoleTab;
  DetailsMemo.Lines.Add('Compiling project: ' + ExtractFileName(FActiveProjectFile));

  // Get dynamic executable path from project target info
  LIsPackage := False;
  LOutput := '';
  GetProjectTargetInfo(FActiveProjectFile, LIsPackage, LOutput);
  LExeFile := ResolveExePath(FActiveProjectFile, LOutput);
  DetailsMemo.Lines.Add('Resolved Executable: ' + LExeFile);

  // Try direct DCC bypass first, fall back to slow MSBuild if it fails
  if not CompileProjectDirect(FActiveProjectFile) then
  begin
    DetailsMemo.Lines.Add('Direct DCC compile failed or bypassed. Falling back to MSBuild...');
    LProj.ProjectBuilder.BuildProject(cmOTAMake, False, True);
  end;

  if not FileExists(LExeFile) then
  begin
    DetailsMemo.Lines.Add('Error: Executable not found at ' + LExeFile);
    Exit;
  end;

  // Set the selected tests in the design-time server to be queried by the runner via GET /tests
  if ATestFilter <> '' then
    FServer.SelectedTestsJSON := '["' + ATestFilter + '"]'
  else
  begin
    var LChecked := GetCheckedTests;
    if Length(LChecked) > 0 then
    begin
      var LJSON: string := '[';
      for var LIdx := 0 to Length(LChecked) - 1 do
      begin
        if LIdx > 0 then LJSON := LJSON + ',';
        LJSON := LJSON + '"' + LChecked[LIdx] + '"';
      end;
      LJSON := LJSON + ']';
      FServer.SelectedTestsJSON := LJSON;
    end
    else
      FServer.SelectedTestsJSON := '[]';
  end;

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
      LParams := LParams + ' -fixture:' + ATestFilter;
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

procedure TFormDextTestRunner.RunAllProjectsClick(Sender: TObject);
begin
  RunAllProjectsTests;
end;

procedure TFormDextTestRunner.RunAllProjectsTests;
var
  I: Integer;
  LProj: IOTAProject;
  LProjFile: string;
  LIsPackage: Boolean;
  LOutput: string;
  LExeFile: string;
  LCmdLine: string;
  LParams: string;
  SI: TStartupInfo;
  PI: TProcessInformation;
begin
  ClearTestStatus;
  DetailsMemo.Clear;
  FTotalTests := 0;
  FCompletedTests := 0;
  if Assigned(FProgressPanel) then
  begin
    FProgressBar.Position := 0;
    FProgressBar.Max := 100;
    FProgressLabel.Caption := '...';
    FProgressPanel.Visible := True;
  end;
  // Focus Console Log
  if Assigned(FDetailsPageControl) and Assigned(FConsoleTab) then
    FDetailsPageControl.ActivePage := FConsoleTab;
  DetailsMemo.Lines.Add('=== Running All Test Projects ===');
  
  for I := 0 to ProjectsComboBox.Items.Count - 1 do
  begin
    LProj := IOTAProject(Pointer(ProjectsComboBox.Items.Objects[I]));
    if Assigned(LProj) then
    begin
      LProjFile := LProj.FileName;
      DetailsMemo.Lines.Add('');
      DetailsMemo.Lines.Add('----------------------------------------');
      DetailsMemo.Lines.Add('Compiling ' + ExtractFileName(LProjFile) + '...');
      if not CompileProjectDirect(LProjFile) then
      begin
        DetailsMemo.Lines.Add('Direct DCC compile failed, building via MSBuild...');
        LProj.ProjectBuilder.BuildProject(cmOTAMake, False, True);
      end;
      
      LIsPackage := False;
      LOutput := '';
      GetProjectTargetInfo(LProjFile, LIsPackage, LOutput);
      LExeFile := ResolveExePath(LProjFile, LOutput);
      
      if FileExists(LExeFile) then
      begin
        DetailsMemo.Lines.Add('Executing ' + ExtractFileName(LExeFile) + '...');
        FServer.SelectedTestsJSON := '[]';
        LParams := Format('--port %d -no-wait', [FServer.Port]);
        LCmdLine := Format('"%s" %s', [LExeFile, LParams]);
        UniqueString(LCmdLine);
        
        FillChar(SI, SizeOf(SI), 0);
        SI.cb := SizeOf(TStartupInfo);
        FillChar(PI, SizeOf(PI), 0);
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
    end;
  end;
end;

procedure TFormDextTestRunner.RunSelectedButtonClick(Sender: TObject);
var
  LChecked: TArray<string>;
begin
  LChecked := GetCheckedTests;
  if (Sender = RunSelectedButton) and (Length(LChecked) > 0) then
  begin
    RunActiveProjectTests('');
  end
  else if Assigned(TestsTreeView.Selected) then
  begin
    if TestsTreeView.Selected.Parent <> nil then
      RunActiveProjectTests(TestsTreeView.Selected.Parent.Text + '.' + TestsTreeView.Selected.Text)
    else
      RunActiveProjectTests(TestsTreeView.Selected.Text);
  end
  else
    RunActiveProjectTests;
end;

procedure TFormDextTestRunner.StopButtonClick(Sender: TObject);
begin
  // Send cancel signals
end;

procedure TFormDextTestRunner.TestsTreeViewDblClick(Sender: TObject);
  function FindMethodImplementationLine(const AFileName, AClassName, AMethodName: string; ADefaultLine: Integer): Integer;
  var
    LStrings: TStringList;
    I: Integer;
    LSearchStr1, LSearchStr2: string;
    LLine: string;
  begin
    Result := ADefaultLine;
    if not FileExists(AFileName) then Exit;
    LStrings := TStringList.Create;
    try
      LStrings.LoadFromFile(AFileName);
      LSearchStr1 := ('procedure ' + AClassName + '.' + AMethodName).ToLower;
      LSearchStr2 := ('function ' + AClassName + '.' + AMethodName).ToLower;
      for I := 0 to LStrings.Count - 1 do
      begin
        LLine := LStrings[I].ToLower.Trim;
        if LLine.StartsWith(LSearchStr1) or LLine.StartsWith(LSearchStr2) then
        begin
          Result := I + 1;
          Break;
        end;
      end;
    finally
      LStrings.Free;
    end;
  end;

var
  LNode: TTreeNode;
  LIdx: Integer;
  LLoc: TTestLocation;
  LModuleServices: IOTAModuleServices;
  LModule: IOTAModule;
  LSourceEditor: IOTASourceEditor;
  LView: IOTAEditView;
  LTargetLine: Integer;
begin
  LNode := TestsTreeView.Selected;
  if not Assigned(LNode) or (LNode.Data = nil) then Exit;

  LIdx := Integer(LNode.Data);
  if (LIdx < 0) or (LIdx >= FTestLocations.Count) then Exit;

  LLoc := FTestLocations[LIdx];
  if LLoc.FileName = '' then Exit;

  LTargetLine := FindMethodImplementationLine(LLoc.FileName, LLoc.ClassName, LLoc.MethodName, LLoc.Line);

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
          LView.Position.Move(LTargetLine, 1);
        end;
      end;
    end;
  end;
end;

function TFormDextTestRunner.GetCheckedTests: TArray<string>;
var
  I: Integer;
  LNode: TTreeNode;
  LList: TList<string>;
begin
  LList := TList<string>.Create;
  try
    for I := 0 to TestsTreeView.Items.Count - 1 do
    begin
      LNode := TestsTreeView.Items[I];
      if (LNode.Parent <> nil) and LNode.Checked then
      begin
        LList.Add(LNode.Parent.Text + '.' + LNode.Text);
      end;
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TFormDextTestRunner.GetRunButtonRect(ANode: TTreeNode): TRect;
var
  LTextRect: TRect;
begin
  LTextRect := ANode.DisplayRect(True);
  Result.Left := LTextRect.Right + 12;
  Result.Top := LTextRect.Top + (LTextRect.Height - 14) div 2;
  Result.Right := Result.Left + 20;
  Result.Bottom := Result.Top + 14;
end;

procedure TFormDextTestRunner.TestsTreeViewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  LTreeView: TTreeView;
  LNode: TTreeNode;
  LOldNode: TTreeNode;
  LBtnRect: TRect;
  LRect: TRect;
begin
  LTreeView := Sender as TTreeView;
  LNode := LTreeView.GetNodeAt(X, Y);
  
  if LNode <> FHoverNode then
  begin
    LOldNode := FHoverNode;
    FHoverNode := LNode;
    
    if Assigned(LOldNode) then
    begin
      LRect := LOldNode.DisplayRect(False);
      LRect.Right := LTreeView.ClientWidth;
      InvalidateRect(LTreeView.Handle, @LRect, True);
    end;
    
    if Assigned(FHoverNode) then
    begin
      LRect := FHoverNode.DisplayRect(False);
      LRect.Right := LTreeView.ClientWidth;
      InvalidateRect(LTreeView.Handle, @LRect, True);
    end;
  end;
  
  if Assigned(FHoverNode) and (FHoverNode.Parent <> nil) then
  begin
    LBtnRect := GetRunButtonRect(FHoverNode);
    if PtInRect(LBtnRect, Point(X, Y)) then
    begin
      LTreeView.Cursor := crHandPoint;
      Exit;
    end;
  end;
  
  LTreeView.Cursor := crDefault;
end;

procedure TFormDextTestRunner.TestsTreeViewMouseLeave(Sender: TObject);
var
  LTreeView: TTreeView;
  LOldNode: TTreeNode;
  LRect: TRect;
begin
  LTreeView := Sender as TTreeView;
  if Assigned(FHoverNode) then
  begin
    LOldNode := FHoverNode;
    FHoverNode := nil;
    LRect := LOldNode.DisplayRect(False);
    LRect.Right := LTreeView.ClientWidth;
    InvalidateRect(LTreeView.Handle, @LRect, True);
  end;
end;

procedure TFormDextTestRunner.TestsTreeViewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LNode: TTreeNode;
  LBtnRect: TRect;
  LHitInfo: THitTests;
begin
  if Button = mbLeft then
  begin
    LNode := TestsTreeView.GetNodeAt(X, Y);
    if Assigned(LNode) then
    begin
      LHitInfo := TestsTreeView.GetHitTestInfoAt(X, Y);
      if htOnStateIcon in LHitInfo then
      begin
        TThread.ForceQueue(nil, TThreadProcedure(procedure
          var
            I: Integer;
            LState: Boolean;
          begin
            if not Assigned(LNode) or not Assigned(TestsTreeView) then Exit;
            LState := LNode.Checked;
            if LNode.Parent = nil then
            begin
              TestsTreeView.Items.BeginUpdate;
              try
                for I := 0 to LNode.Count - 1 do
                  LNode.Item[I].Checked := LState;
              finally
                TestsTreeView.Items.EndUpdate;
              end;
            end
            else
            begin
              var LParent := LNode.Parent;
              var LAnyChecked := False;
              for I := 0 to LParent.Count - 1 do
              begin
                if LParent.Item[I].Checked then
                begin
                  LAnyChecked := True;
                  Break;
                end;
              end;
              LParent.Checked := LAnyChecked;
            end;
            TestsTreeView.Invalidate;
          end));
      end;

      if LNode.Parent <> nil then
      begin
        LBtnRect := GetRunButtonRect(LNode);
        if PtInRect(LBtnRect, Point(X, Y)) then
        begin
          TestsTreeView.Selected := LNode;
          RunActiveProjectTests(LNode.Parent.Text + '.' + LNode.Text);
        end;
      end;
    end;
  end;
end;

procedure TFormDextTestRunner.TestsTreeViewMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LNode: TTreeNode;
  LHitInfo: THitTests;
begin
  if Button = mbLeft then
  begin
    LNode := TestsTreeView.GetNodeAt(X, Y);
    if Assigned(LNode) then
    begin
      LHitInfo := TestsTreeView.GetHitTestInfoAt(X, Y);
      if htOnStateIcon in LHitInfo then
      begin
        TThread.ForceQueue(nil, TThreadProcedure(procedure
          var
            I: Integer;
            LState: Boolean;
          begin
            if not Assigned(LNode) or not Assigned(TestsTreeView) then Exit;
            LState := LNode.Checked;
            if LNode.Parent = nil then
            begin
              TestsTreeView.Items.BeginUpdate;
              try
                for I := 0 to LNode.Count - 1 do
                  LNode.Item[I].Checked := LState;
              finally
                TestsTreeView.Items.EndUpdate;
              end;
            end
            else
            begin
              var LParent := LNode.Parent;
              var LAnyChecked := False;
              for I := 0 to LParent.Count - 1 do
              begin
                if LParent.Item[I].Checked then
                begin
                  LAnyChecked := True;
                  Break;
                end;
              end;
              LParent.Checked := LAnyChecked;
            end;
            TestsTreeView.Invalidate;
          end));
      end;
    end;
  end;
end;

procedure TFormDextTestRunner.TestsTreeViewAdvancedCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage; var PaintImages, DefaultDraw: Boolean);
var
  LBtnRect: TRect;
begin
  DefaultDraw := True;
  if Stage = cdPostPaint then
  begin
    if (Node = FHoverNode) and (Node.Parent <> nil) then
    begin
      LBtnRect := GetRunButtonRect(Node);
      // Modern soft green hover button
      Sender.Canvas.Brush.Color := TColor($DCFCE7);
      Sender.Canvas.Pen.Color := TColor($22C55E);
      Sender.Canvas.RoundRect(LBtnRect.Left, LBtnRect.Top, LBtnRect.Right, LBtnRect.Bottom, 4, 4);
      Sender.Canvas.Font.Color := TColor($15803D);
      Sender.Canvas.Font.Size := 7;
      Sender.Canvas.Font.Style := [fsBold];
      DrawText(Sender.Canvas.Handle, #$25B6, -1, LBtnRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
    end;
  end;
end;

procedure TFormDextTestRunner.DebugSelectedClick(Sender: TObject);
var
  LNode: TTreeNode;
  LProj: IOTAProject;
  LNTAServices: INTAServices;
  LFoundAction: TContainedAction;
  LParams: string;
  LIsPackage: Boolean;
  LOutput: string;
  LExeFile: string;
  LModuleServices: IOTAModuleServices;
  LGroup: IOTAProjectGroup;
begin
  LNode := TestsTreeView.Selected;
  if not Assigned(LNode) then Exit;

  if ProjectsComboBox.ItemIndex = -1 then Exit;
  LProj := IOTAProject(Pointer(ProjectsComboBox.Items.Objects[ProjectsComboBox.ItemIndex]));
  if not Assigned(LProj) then Exit;

  // Synchronize IDE Active Project
  if Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) and Assigned(LModuleServices) then
  begin
    LGroup := LModuleServices.MainProjectGroup;
    if Assigned(LGroup) and (LGroup.ActiveProject <> LProj) then
    begin
      LGroup.ActiveProject := LProj;
    end;
  end;

  ClearTestStatus;
  DetailsMemo.Clear;
  FTotalTests := 0;
  FCompletedTests := 0;
  if Assigned(FProgressPanel) then
  begin
    FProgressBar.Position := 0;
    FProgressBar.Max := 100;
    FProgressLabel.Caption := '...';
    FProgressPanel.Visible := True;
  end;
  // Focus Console Log
  if Assigned(FDetailsPageControl) and Assigned(FConsoleTab) then
    FDetailsPageControl.ActivePage := FConsoleTab;
  DetailsMemo.Lines.Add('Compiling project (Debug): ' + ExtractFileName(FActiveProjectFile));

  LIsPackage := False;
  LOutput := '';
  GetProjectTargetInfo(FActiveProjectFile, LIsPackage, LOutput);
  LExeFile := ResolveExePath(FActiveProjectFile, LOutput);
  
  if not CompileProjectDirect(FActiveProjectFile) then
  begin
    DetailsMemo.Lines.Add('Direct DCC compile failed or bypassed. Falling back to MSBuild...');
    LProj.ProjectBuilder.BuildProject(cmOTAMake, False, True);
  end;

  if not FileExists(LExeFile) then
  begin
    DetailsMemo.Lines.Add('Error: Executable not found at ' + LExeFile);
    Exit;
  end;

  LParams := Format('--port %d -no-wait', [FServer.Port]);
  if LNode.Parent <> nil then
  begin
    FServer.SelectedTestsJSON := '["' + LNode.Parent.Text + '.' + LNode.Text + '"]';
    LParams := LParams + ' -fixture:' + LNode.Parent.Text + ' -filter:' + LNode.Text;
  end
  else
  begin
    FServer.SelectedTestsJSON := '[]';
  end;

  DetailsMemo.Lines.Add('Starting debugger with parameters: ' + LParams);
  LProj.ProjectOptions.Values['RunParams'] := LParams;

  LFoundAction := nil;
  if Supports(BorlandIDEServices, INTAServices, LNTAServices) then
  begin
    if LNTAServices.ActionList <> nil then
    begin
      for var I := 0 to LNTAServices.ActionList.ActionCount - 1 do
      begin
        var LAct := LNTAServices.ActionList.Actions[I];
        if SameText(LAct.Name, 'actRun') or SameText(LAct.Name, 'actRunRun') or
           SameText(LAct.Name, 'actRunProgram') or (LAct.ShortCut = ShortCut(VK_F9, [])) then
        begin
          LFoundAction := LAct;
          Break;
        end;
      end;
    end;
  end;

  if LFoundAction <> nil then
  begin
    TThread.Queue(nil, TThreadProcedure(procedure
      begin
        LFoundAction.Execute;
      end));
  end
  else
  begin
    DetailsMemo.Lines.Add('Warning: Could not trigger debugger automatically.');
    DetailsMemo.Lines.Add('Please press F9 (Run) manually in the IDE to start debugging.');
  end;
end;

procedure TFormDextTestRunner.RefreshButtonClick(Sender: TObject);
begin
  RefreshProjects;
end;

procedure TFormDextTestRunner.SetActiveSession(ASession: TTestSession);
var
  LThemingServices: IOTAIDEThemingServices;
begin
  if ASession = nil then Exit;
  FActiveSession := ASession;
  
  TestsTreeView := ASession.TreeView;
  FTestLocations := ASession.TestLocations;
  FActiveProjectFile := ASession.ActiveProjectFile;
  
  if ProjectsComboBox.Items.Count > 0 then
  begin
    var LIndex := -1;
    for var I := 0 to ProjectsComboBox.Items.Count - 1 do
    begin
      var LProj := IOTAProject(Pointer(ProjectsComboBox.Items.Objects[I]));
      if Assigned(LProj) and (LProj.FileName = FActiveProjectFile) then
      begin
        LIndex := I;
        Break;
      end;
    end;
    ProjectsComboBox.ItemIndex := LIndex;
  end;

  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      TestsTreeView.Color := LThemingServices.StyleServices.GetSystemColor(clWindow);
      TestsTreeView.Font.Color := LThemingServices.StyleServices.GetSystemColor(clWindowText);
    end;
  end;
end;

procedure TFormDextTestRunner.SessionsPageControlChange(Sender: TObject);
begin
  if SessionsPageControl.ActivePage = nil then Exit;

  if SessionsPageControl.ActivePage = FAddTab then
  begin
    var LName := 'Session ' + (FSessions.Count + 1).ToString;
    CreateNewSession(LName);
    Exit;
  end;

  for var I := 0 to FSessions.Count - 1 do
  begin
    if FSessions[I].TabSheet = SessionsPageControl.ActivePage then
    begin
      SetActiveSession(FSessions[I]);
      Break;
    end;
  end;
end;

procedure TFormDextTestRunner.CreateNewSession(const AName: string);
var
  LSession: TTestSession;
  LIndex: Integer;
begin
  LSession := TTestSession.Create(SessionsPageControl, AName);
  
  LSession.TreeView.Images := TestsTreeView.Images;
  LSession.TreeView.Checkboxes := True;
  LSession.TreeView.PopupMenu := TestsTreeView.PopupMenu;
  LSession.TreeView.OnMouseMove := TestsTreeViewMouseMove;
  LSession.TreeView.OnMouseLeave := TestsTreeViewMouseLeave;
  LSession.TreeView.OnMouseDown := TestsTreeViewMouseDown;
  LSession.TreeView.OnMouseUp := TestsTreeViewMouseUp;
  LSession.TreeView.OnAdvancedCustomDrawItem := TestsTreeViewAdvancedCustomDrawItem;
  LSession.TreeView.OnDblClick := TestsTreeViewDblClick;
  LSession.TreeView.OnChange := TestsTreeViewChange;
  
  LIndex := FAddTab.PageIndex;
  LSession.TabSheet.PageIndex := LIndex;
  
  FSessions.Add(LSession);
  
  SessionsPageControl.ActivePage := LSession.TabSheet;
  SetActiveSession(LSession);
  
  RefreshProjects;
end;

procedure TFormDextTestRunner.CloseSession(ASession: TTestSession);
begin
  if FSessions.Count <= 1 then Exit;

  var LActiveIndex := FSessions.IndexOf(ASession);
  
  if FActiveSession = ASession then
  begin
    var LNextIndex := LActiveIndex - 1;
    if LNextIndex < 0 then LNextIndex := 1;
    SetActiveSession(FSessions[LNextIndex]);
    SessionsPageControl.ActivePage := FActiveSession.TabSheet;
  end;
  
  FSessions.Remove(ASession);
end;

procedure TFormDextTestRunner.SessionTabContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
var
  LPageControl: TPageControl;
  LTabIndex: Integer;
  LPos: TPoint;
begin
  LPageControl := Sender as TPageControl;
  LPos := MousePos;
  
  LTabIndex := LPageControl.IndexOfTabAt(LPos.X, LPos.Y);
  if (LTabIndex >= 0) and (LPageControl.Pages[LTabIndex] <> FAddTab) then
  begin
    LPageControl.ActivePage := LPageControl.Pages[LTabIndex];
    SessionsPageControlChange(LPageControl);
    
    var LMenu := TPopupMenu.Create(Self);
    var LItem := TMenuItem.Create(LMenu);
    LItem.Caption := 'Close Session';
    LItem.OnClick := CloseActiveSessionClick;
    LMenu.Items.Add(LItem);
    
    LPos := LPageControl.ClientToScreen(LPos);
    LMenu.Popup(LPos.X, LPos.Y);
    Handled := True;
  end;
end;

procedure TFormDextTestRunner.CloseActiveSessionClick(Sender: TObject);
begin
  CloseSession(FActiveSession);
end;

function ExtractTagValue(const AContent, ATagName: string): string;
var
  LStart, LEnd: Integer;
begin
  Result := '';
  LStart := AContent.LastIndexOf('<' + ATagName + '>');
  if LStart >= 0 then
  begin
    Inc(LStart, Length(ATagName) + 2);
    LEnd := AContent.IndexOf('</' + ATagName + '>', LStart);
    if LEnd > LStart then
      Result := AContent.Substring(LStart, LEnd - LStart).Trim;
  end;
end;

function GetDelphiProductVersion: string;
var
  LBinDir: string;
  LSplit: TArray<string>;
  I: Integer;
begin
  LBinDir := ExtractFilePath(ParamStr(0));
  LSplit := LBinDir.Split(['\']);
  for I := 0 to Length(LSplit) - 1 do
  begin
    if SameText(LSplit[I], 'Studio') and (I < Length(LSplit) - 1) then
      Exit(LSplit[I + 1]);
  end;
  Result := '23.0';
end;

function ExecuteAndCapture(const ACommandLine, AWorkDir: string; out AOutput: string): Boolean;
var
  LSa: TSecurityAttributes;
  LReadPipe, LWritePipe: THandle;
  LSi: TStartUpInfo;
  LPi: TProcessInformation;
  LBuffer: array[0..4095] of AnsiChar;
  LBytesRead: DWORD;
  LSuccess: Boolean;
  LCmdLine: string;
  LExitCode: DWORD;
begin
  Result := False;
  AOutput := '';
  
  LSa.nLength := SizeOf(TSecurityAttributes);
  LSa.bInheritHandle := True;
  LSa.lpSecurityDescriptor := nil;
  
  if not CreatePipe(LReadPipe, LWritePipe, @LSa, 0) then Exit;
  
  try
    SetHandleInformation(LReadPipe, HANDLE_FLAG_INHERIT, 0);
    
    ZeroMemory(@LSi, SizeOf(TStartUpInfo));
    LSi.cb := SizeOf(TStartUpInfo);
    LSi.hStdOutput := LWritePipe;
    LSi.hStdError := LWritePipe;
    LSi.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    LSi.wShowWindow := SW_HIDE;
    
    LCmdLine := ACommandLine;
    UniqueString(LCmdLine);
    
    if CreateProcess(nil, PChar(LCmdLine), nil, nil, True, CREATE_NO_WINDOW, nil, 
      Pointer(AWorkDir), LSi, LPi) then
    begin
      CloseHandle(LWritePipe);
      LWritePipe := 0;
      
      repeat
        LSuccess := ReadFile(LReadPipe, LBuffer[0], SizeOf(LBuffer) - 1, LBytesRead, nil);
        if LBytesRead > 0 then
        begin
          LBuffer[LBytesRead] := #0;
          AOutput := AOutput + string(AnsiString(LBuffer));
        end;
      until not LSuccess or (LBytesRead = 0);
      
      WaitForSingleObject(LPi.hProcess, INFINITE);
      
      LExitCode := 0;
      GetExitCodeProcess(LPi.hProcess, LExitCode);
      Result := (LExitCode = 0);
      
      CloseHandle(LPi.hProcess);
      CloseHandle(LPi.hThread);
    end;
  finally
    if LReadPipe <> 0 then CloseHandle(LReadPipe);
    if LWritePipe <> 0 then CloseHandle(LWritePipe);
  end;
end;

function TFormDextTestRunner.CompileProjectDirect(const AProjFile: string): Boolean;
var
  LDccExe: string;
  LContent: string;
  LSearchPath, LDefines, LNamespaces, LDcuOutput, LExeOutput: string;
  LWorkDir: string;
  LProductVer: string;
  LBDS: string;
  LCommonDir: string;
  LCmdLine: string;
  LOutput: string;
  LProjName: string;
  LDprFile: string;
  function ResolvePaths(const APaths: string): string;
  var
    LParts: TArray<string>;
    I: Integer;
    LResolved: string;
  begin
    LParts := APaths.Split([';']);
    for I := 0 to Length(LParts) - 1 do
    begin
      var LPart := LParts[I].Trim;
      if LPart = '' then Continue;
      if not TPath.IsPathRooted(LPart) then
        LPart := TPath.Combine(LWorkDir, LPart);
      LPart := TPath.GetFullPath(LPart);
      if LResolved <> '' then LResolved := LResolved + ';';
      LResolved := LResolved + LPart;
    end;
    Result := LResolved;
  end;
begin
  Result := False;
  if not FileExists(AProjFile) then Exit;
  
  LWorkDir := ExtractFilePath(AProjFile);
  LProjName := TPath.GetFileNameWithoutExtension(AProjFile);
  LDprFile := TPath.Combine(LWorkDir, LProjName + '.dpr');
  if not FileExists(LDprFile) then
    LDprFile := TPath.Combine(LWorkDir, LProjName + '.dpk');
    
  if not FileExists(LDprFile) then
  begin
    DetailsMemo.Lines.Add('Error: DPR/DPK file not found: ' + LDprFile);
    Exit;
  end;

  LDccExe := ExtractFilePath(ParamStr(0)) + 'dcc32.exe';
  if not FileExists(LDccExe) then
  begin
    DetailsMemo.Lines.Add('Error: Compiler not found: ' + LDccExe);
    Exit;
  end;

  try
    LContent := TFile.ReadAllText(AProjFile);
  except
    on E: Exception do
    begin
      DetailsMemo.Lines.Add('Error reading project file: ' + E.Message);
      Exit;
    end;
  end;

  LSearchPath := ExtractTagValue(LContent, 'DCC_UnitSearchPath');
  LDefines := ExtractTagValue(LContent, 'DCC_Define');
  LNamespaces := ExtractTagValue(LContent, 'DCC_Namespace');
  LDcuOutput := ExtractTagValue(LContent, 'DCC_DcuOutput');
  LExeOutput := ExtractTagValue(LContent, 'DCC_ExeOutput');

  LProductVer := GetDelphiProductVersion;
  LBDS := ExcludeTrailingPathDelimiter(ExtractFileDir(ExtractFileDir(ParamStr(0))));
  LCommonDir := 'C:\Users\Public\Documents\Embarcadero\Studio\' + LProductVer;

  LSearchPath := LSearchPath.Replace('$(ProductVersion)', LProductVer)
                           .Replace('$(Platform)', 'Win32')
                           .Replace('$(Config)', 'Debug')
                           .Replace('$(BDS)', LBDS)
                           .Replace('$(BDSCOMMONDIR)', LCommonDir)
                           .Replace('$(DCC_UnitSearchPath)', '');
                           
  LDefines := LDefines.Replace('$(DCC_Define)', '').Trim;
  if LDefines.EndsWith(';') then
    LDefines := LDefines.Substring(0, LDefines.Length - 1).Trim;

  LNamespaces := LNamespaces.Replace('$(DCC_Namespace)', '').Trim;
  if LNamespaces.EndsWith(';') then
    LNamespaces := LNamespaces.Substring(0, LNamespaces.Length - 1).Trim;

  LDcuOutput := LDcuOutput.Replace('$(ProductVersion)', LProductVer)
                          .Replace('$(Platform)', 'Win32')
                          .Replace('$(Config)', 'Debug');
  LExeOutput := LExeOutput.Replace('$(ProductVersion)', LProductVer)
                          .Replace('$(Platform)', 'Win32')
                          .Replace('$(Config)', 'Debug');

  LSearchPath := ResolvePaths(LSearchPath);
  if LDcuOutput <> '' then
  begin
    if not TPath.IsPathRooted(LDcuOutput) then
      LDcuOutput := TPath.Combine(LWorkDir, LDcuOutput);
    LDcuOutput := TPath.GetFullPath(LDcuOutput);
    ForceDirectories(LDcuOutput);
  end;
  if LExeOutput <> '' then
  begin
    if not TPath.IsPathRooted(LExeOutput) then
      LExeOutput := TPath.Combine(LWorkDir, LExeOutput);
    LExeOutput := TPath.GetFullPath(LExeOutput);
    ForceDirectories(LExeOutput);
  end;

  if LSearchPath <> '' then LSearchPath := LSearchPath + ';';
  LSearchPath := LSearchPath + LWorkDir;

  LCmdLine := Format('"%s" -Q -M -U"%s"', [LDccExe, LSearchPath]);
  if LDefines <> '' then LCmdLine := LCmdLine + ' -D' + LDefines;
  if LNamespaces <> '' then LCmdLine := LCmdLine + ' -NS' + LNamespaces;
  if LDcuOutput <> '' then LCmdLine := LCmdLine + ' -N0"' + LDcuOutput + '"';
  if LExeOutput <> '' then LCmdLine := LCmdLine + ' -E"' + LExeOutput + '"';
  LCmdLine := LCmdLine + ' "' + LDprFile + '"';

  DetailsMemo.Lines.Add('DCC Command: ' + LCmdLine);
  
  if ExecuteAndCapture(LCmdLine, LWorkDir, LOutput) then
  begin
    DetailsMemo.Lines.Add(LOutput);
    DetailsMemo.Lines.Add('Direct compilation successful.');
    Result := True;
  end
  else
  begin
    DetailsMemo.Lines.Add(LOutput);
    DetailsMemo.Lines.Add('Direct compilation failed.');
  end;
end;

procedure TFormDextTestRunner.TryLoadCoverage;
var
  LCovPath: string;
  LRoot: string;
  LTestsDir: string;
  LFiles: TArray<string>;
  LFile: string;
begin
  LCovPath := TPath.Combine(ExtractFilePath(FActiveProjectFile), 'dext_coverage.xml');
  if not FileExists(LCovPath) then
    LCovPath := TPath.Combine(TPath.GetDirectoryName(ExtractFilePath(FActiveProjectFile)), 'dext_coverage.xml');
    
  if not FileExists(LCovPath) then
  begin
    LRoot := TPath.GetDirectoryName(TPath.GetDirectoryName(ExtractFilePath(FActiveProjectFile)));
    LCovPath := TPath.Combine(TPath.Combine(LRoot, 'Tests'), 'test-results.xml');
  end;

  if not FileExists(LCovPath) then
  begin
    LTestsDir := 'c:\dev\Dext\DextRepository\Tests\Output';
    if TDirectory.Exists(LTestsDir) then
    begin
      LFiles := TDirectory.GetFiles(LTestsDir, '*.xml');
      for LFile in LFiles do
      begin
        try
          if TFile.ReadAllText(LFile).Contains('<coverage') then
          begin
            LCovPath := LFile;
            Break;
          end;
        except
          // ignore
        end;
      end;
    end;
  end;

  if FileExists(LCovPath) then
  begin
    DetailsMemo.Lines.Add('Loading code coverage from: ' + LCovPath);
    TThread.Queue(nil, TThreadProcedure(procedure
      begin
        TCoverageManager.GetInstance.LoadCoverageFromXML(LCovPath);
      end));
  end
  else
  begin
    DetailsMemo.Lines.Add('No code coverage report found.');
  end;
end;

procedure TFormDextTestRunner.RunImpactedTests(const ATests: TArray<string>);
var
  LJSON: string;
  I: Integer;
begin
  if Length(ATests) = 0 then Exit;
  
  LJSON := '[';
  for I := 0 to Length(ATests) - 1 do
  begin
    if I > 0 then LJSON := LJSON + ',';
    LJSON := LJSON + '"' + ATests[I] + '"';
  end;
  LJSON := LJSON + ']';
  
  FServer.SelectedTestsJSON := LJSON;
  RunActiveProjectTests('');
end;

procedure TFormDextTestRunner.HandleFileSaved(const AFileName: string);
var
  LTests: TList<TTestLocation>;
begin
  if not SameText(ExtractFileExt(AFileName), '.pas') then Exit;
  
  LTests := nil;
  if TTestASTScanner.ScanFile(AFileName, LTests) then
  begin
    TThread.Queue(nil, TThreadProcedure(procedure
      var
        LIdx: Integer;
        LTest: TTestLocation;
        LNode: TTreeNode;
        LFixtureNode: TTreeNode;
        LMethodNode: TTreeNode;
      begin
        TestsTreeView.Items.BeginUpdate;
        try
          // Remove existing tests in this file from our list and TreeView
          for LIdx := FTestLocations.Count - 1 downto 0 do
          begin
            if SameText(FTestLocations[LIdx].FileName, AFileName) then
            begin
              LNode := FindNodeByPath(FTestLocations[LIdx].ClassName + '.' + FTestLocations[LIdx].MethodName);
              if not Assigned(LNode) then
                LNode := FindNodeByPath(FTestLocations[LIdx].MethodName);
                
              if Assigned(LNode) then
              begin
                var LParent := LNode.Parent;
                LNode.Free;
                if Assigned(LParent) and (LParent.Count = 0) then
                  LParent.Free;
              end;
              FTestLocations.Delete(LIdx);
            end;
          end;
          
          // Add newly discovered tests
          for LTest in LTests do
          begin
            FTestLocations.Add(LTest);
            
            LFixtureNode := FindNodeByPath(LTest.ClassName);
            if not Assigned(LFixtureNode) then
            begin
              LFixtureNode := TestsTreeView.Items.AddChild(nil, LTest.ClassName);
              LFixtureNode.ImageIndex := 3;
              LFixtureNode.SelectedIndex := 3;
            end;
            
            LMethodNode := TestsTreeView.Items.AddChild(LFixtureNode, LTest.MethodName);
            LMethodNode.Data := Pointer(FTestLocations.Count - 1);
            LMethodNode.ImageIndex := 0;
            LMethodNode.SelectedIndex := 0;
          end;
          
          if LTests.Count > 0 then
            TestsTreeView.FullExpand;
        finally
          TestsTreeView.Items.EndUpdate;
          LTests.Free;
        end;
      end));
  end;
end;

{ TTelemetryTracker }

class procedure TTelemetryTracker.RecordTestResult(const AProjectFile, ATestName, AStatus: string; ADurationMs: Integer); // ADurationMs remains Integer for storage
var
  LDir, LFile: string;
  LArray: TJSONArray;
  LObj: TJSONObject;
  LText: string;
begin
  if AProjectFile = '' then Exit;
  LDir := TPath.Combine(TPath.GetDirectoryName(AProjectFile), '.dext\testing');
  try
    ForceDirectories(LDir);
    LFile := TPath.Combine(LDir, 'history.json');
    
    LArray := nil;
    if FileExists(LFile) then
    begin
      try
        LText := TFile.ReadAllText(LFile, TEncoding.UTF8);
        LArray := TJSONObject.ParseJSONValue(LText) as TJSONArray;
      except
        // ignore parsing errors
      end;
    end;
    
    if LArray = nil then
      LArray := TJSONArray.Create;
      
    LObj := TJSONObject.Create;
    LObj.AddPair('testName', ATestName);
    LObj.AddPair('status', AStatus);
    LObj.AddPair('durationMs', TJSONNumber.Create(ADurationMs));
    LObj.AddPair('timestamp', DateTimeToStr(Now));
    LArray.AddElement(LObj);
    
    // Limit to last 1000 runs
    while LArray.Count > 1000 do
      LArray.Remove(0).Free;
      
    TFile.WriteAllText(LFile, LArray.ToJSON, TEncoding.UTF8);
    LArray.Free;
  except
    // ignore filesystem errors
  end;
end;

class procedure TTelemetryTracker.AnalyzeHistory(const AProjectFile: string; AMemo: TMemo);
var
  LDir, LFile: string;
  LText: string;
  LArray: TJSONArray;
  LIdx: Integer;
  LVal: TJSONValue;
  LObj: TJSONObject;
  LName, LStatus: string;
  LDurationMs: Integer;
  LTestDurations: TDictionary<string, TList<Integer>>;
  LTestStatuses: TDictionary<string, TList<string>>;
begin
  if (AProjectFile = '') or (AMemo = nil) then Exit;
  
  LDir := TPath.Combine(TPath.GetDirectoryName(AProjectFile), '.dext\testing');
  LFile := TPath.Combine(LDir, 'history.json');
  if not FileExists(LFile) then Exit;
  
  LTestDurations := TDictionary<string, TList<Integer>>.Create;
  LTestStatuses := TDictionary<string, TList<string>>.Create;
  try
    try
      LText := TFile.ReadAllText(LFile, TEncoding.UTF8);
      LArray := TJSONObject.ParseJSONValue(LText) as TJSONArray;
      if LArray = nil then Exit;
      
      try
        // 1. Group values by test name
        for LIdx := 0 to LArray.Count - 1 do
        begin
          LVal := LArray.Items[LIdx];
          if LVal is TJSONObject then
          begin
            LObj := TJSONObject(LVal);
            if LObj.TryGetValue<string>('testName', LName) then
            begin
              LObj.TryGetValue<string>('status', LStatus);
              LObj.TryGetValue<Integer>('durationMs', LDurationMs);
              
              var LDurList: TList<Integer> := nil;
              if not LTestDurations.TryGetValue(LName, LDurList) then
              begin
                LDurList := TList<Integer>.Create;
                LTestDurations.Add(LName, LDurList);
              end;
              LDurList.Add(LDurationMs);
              
              var LStatList: TList<string> := nil;
              if not LTestStatuses.TryGetValue(LName, LStatList) then
              begin
                LStatList := TList<string>.Create;
                LTestStatuses.Add(LName, LStatList);
              end;
              LStatList.Add(LStatus);
            end;
          end;
        end;
        
        // 2. Perform regression and flakiness analysis
        var LHasHeader := False;
        for var LPair in LTestStatuses do
        begin
          var LNameKey := LPair.Key;
          var LStatusesList := LPair.Value;
          var LDurList := LTestDurations[LNameKey];
          
          var LIsFlaky := False;
          if LStatusesList.Count >= 2 then
          begin
            var LLastStatus := LStatusesList[0];
            for LIdx := 1 to LStatusesList.Count - 1 do
            begin
              if LStatusesList[LIdx] <> LLastStatus then
              begin
                LIsFlaky := True;
                Break;
              end;
            end;
          end;
          
          var LIsRegression := False;
          var LAvgDuration := 0.0;
          var LLastDuration := 0;
          if LDurList.Count >= 3 then
          begin
            LLastDuration := LDurList[LDurList.Count - 1];
            var LSum := 0;
            for LIdx := 0 to LDurList.Count - 2 do
              Inc(LSum, LDurList[LIdx]);
            LAvgDuration := LSum / (LDurList.Count - 1);
            
            if (LAvgDuration > 10) and (LLastDuration > LAvgDuration * 1.5) then
              LIsRegression := True;
          end;
          
          if LIsFlaky or LIsRegression then
          begin
            if not LHasHeader then
            begin
              AMemo.Lines.Add('');
              AMemo.Lines.Add('[ANALYTICS] --- TEST ANALYTICS ENGINE REPORT ---');
              LHasHeader := True;
            end;
            
            if LIsFlaky then
              AMemo.Lines.Add('   [FLAKY] TEST DETECTED: ' + LNameKey + ' (status changes between Pass and Fail)');
            if LIsRegression then
              AMemo.Lines.Add(Format('   [PERF REGRESSION] %s (Last: %dms, Avg: %.1fms)', [LNameKey, LLastDuration, LAvgDuration]));
          end;
        end;
        
        if LHasHeader then
          AMemo.Lines.Add('========================================');
      finally
        LArray.Free;
      end;
    except
      // ignore errors during analysis
    end;
  finally
    for var LPair in LTestDurations do LPair.Value.Free;
    LTestDurations.Free;
    for var LPair in LTestStatuses do LPair.Value.Free;
    LTestStatuses.Free;
  end;
end;

initialization
  RegisterDockableForm;

finalization
  UnregisterDockableForm;

end.
