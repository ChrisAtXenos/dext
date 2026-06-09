unit Dext.Testing.Design.DockableForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, DockForm, ToolsAPI, Dext.Testing.Design.Server, Dext.Testing.Design.AST,
  System.JSON, System.Generics.Collections, System.IOUtils, System.Threading,
  System.ImageList, Vcl.ImgList, Vcl.Menus, System.Math, System.Diagnostics, System.TimeSpan;

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

  TDextProjectInfo = class
  public
    FileName: string;
    constructor Create(const AFileName: string);
  end;

  TDextProjectNotifier = class(TNotifierObject, IOTAModuleNotifier, IOTAProjectNotifier)
  private
    FForm: TFormDextTestRunner;
    FProjectFile: string;
  public
    constructor Create(AForm: TFormDextTestRunner; const AProjectFile: string);
    // IOTAModuleNotifier
    function CheckOverwrite: Boolean;
    procedure ModuleRenamed(const NewName: string); overload;
    // IOTAProjectNotifier
    procedure ModuleAdded(const AFileName: string);
    procedure ModuleRemoved(const AFileName: string);
    procedure ModuleRenamed(const AOldFileName, ANewFileName: string); overload;
  end;

  TTestSession = class
  public
    TabSheet: TTabSheet;
    TreeView: TTreeView;
    TestLocations: TList<TTestLocation>;
    ActiveProjectFile: string;
    FilterEdit: TEdit;
    constructor Create(APageControl: TPageControl; const AName: string); overload;
    constructor CreateFromExisting(ATabSheet: TTabSheet; ATreeView: TTreeView; ALocations: TList<TTestLocation>; const AProjFile: string); overload;
    destructor Destroy; override;
  end;

  TFileScanCache = class
  public
    Timestamp: TDateTime;
    Tests: TList<TTestLocation>;
    constructor Create(ATimestamp: TDateTime; ATests: TList<TTestLocation>);
    destructor Destroy; override;
  end;

  TTelemetryTracker = class
  public
    class procedure RecordTestResult(const AProjectFile, ATestName, AStatus: string; ADurationMs: Integer);
    class procedure AnalyzeHistory(const AProjectFile: string; AMemo: TMemo);
  end;

  TTestExplorerLayout = (telCompact, telSplitBottom, telSplitRight);
  TTestGroupingMode = (tgmCodeStructure, tgmStatus);

  TFormDextTestRunner = class(TDockableForm)
    SessionsPageControl: TPageControl;
    DefaultSessionTabSheet: TTabSheet;
    TestsTreeView: TTreeView;
    DetailsPanel: TPanel;
    DetailsMemo: TMemo;
    NameSplitter: TSplitter;
    ButtonsPanel: TPanel;
    RefreshButton: TButton;
    RunAllButton: TButton;
    RunSelectedButton: TButton;
    StopButton: TButton;
    SummaryPanel: TPanel;
    SummaryTotalLabel: TLabel;
    SummarySelectedLabel: TLabel;
    SummarySuccessLabel: TLabel;
    SummaryFailedLabel: TLabel;
    SummarySkippedLabel: TLabel;
    SummaryTimeLabel: TLabel;
    ProjectsComboBox: TComboBox;
    ActionsButton: TButton;
    ActionsPopupMenu: TPopupMenu;
    ClearMenuItem: TMenuItem;
    LayoutSeparator: TMenuItem;
    TabbedLayoutMenuItem: TMenuItem;
    SplitBottomLayoutMenuItem: TMenuItem;
    SplitRightLayoutMenuItem: TMenuItem;
    ExportSeparator: TMenuItem;
    ExportToJUnitXmlMenutem: TMenuItem;
    ExportToXUnitXMLMenutem: TMenuItem;
    ExportToJsonMenutem: TMenuItem;
    ExportToSonarQubeXmlMenutem: TMenuItem;
    ExportToHtmlReportMenuItem: TMenuItem;
    ClearSeparator: TMenuItem;
    GroupByClassMenuItem: TMenuItem;
    GroupByTestStatusMenuItem: TMenuItem;
    CreateaNewSessionMenuItem: TMenuItem;
    EnableDisableTestExplorerMenuItem: TMenuItem;
    SummaryTotalTimeLabel: TLabel;
    procedure ActionsButtonClick(Sender: TObject);
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

    // Process handling
    FRunningProcessHandle: THandle;

    // Project changes notification
    FActiveProjectNotifierIndex: Integer;
    FActiveProjectForNotifier: IOTAProject;

    // Sessions
    FSessions: TObjectList<TTestSession>;
    FActiveSession: TTestSession;

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
    FInspectorSplitter: TSplitter;
    FCurrentLayout: TTestExplorerLayout;
    //LayoutButton: TButton;
    // Async compile state
    FPendingTestFilter: string;
    FWaitingForCompile: Boolean;
    FPendingProject: IOTAProject;
    FThemeNotifierIndex: Integer;
    FGroupingMode: TTestGroupingMode;
    FRunningTests: Boolean;

    // Disabled/Enabled Mode
    FEnabled: Boolean;
    FDisabledPanel: TPanel;
    FDisabledContainer: TPanel;

    // Configurations/Startup Tab
    FConfigTab: TTabSheet;
    FCustomParamsEdit: TEdit;
    FChkRunOnSave: TCheckBox;
    FChkRunOnIdle: TCheckBox;
    FChkEnabled: TCheckBox;
    FIdleTimer: TTimer;
    FSaveTimer: TTimer;
    FPendingSaveFiles: TStringList;

    // Execution Stopwatch & Counts
    FStopwatch: TStopwatch;
    FTestExecutionDurationMs: Double;
    FPassedCount: Integer;
    FFailedCount: Integer;
    FSkippedCount: Integer;

    // File scan AST cache (thread-safe performance optimization)
    FScanCache: TObjectDictionary<string, TFileScanCache>;

    procedure CollapseSuccessAndFocusFailures;
    procedure NotifyProcessExited;
    procedure GroupingMenuClick(Sender: TObject);

    function ActiveFilterEdit: TEdit;
    procedure TestsTreeViewChange(Sender: TObject; Node: TTreeNode);
    procedure UpdateTestInspector(const ATestName: string);
    procedure FilterEditChange(Sender: TObject);
    procedure LayoutMenuClick(Sender: TObject);
    procedure ApplyLayout(ALayout: TTestExplorerLayout);
    procedure RefreshTreeView;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    function GetNodeFullTestName(ANode: TTreeNode): string;
    procedure SetActiveSession(ASession: TTestSession);
    procedure SessionsPageControlChange(Sender: TObject);
    function FindMethodImplementationLine(const AFileName, AClassName, AMethodName: string; ADefaultLine: Integer): Integer;
    procedure SessionTabContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure CloseActiveSessionClick(Sender: TObject);
    function CompileProjectDirect(const AProjFile: string): Boolean;
    procedure CreateNewSession(const AName: string);
    procedure CloseSession(ASession: TTestSession);
    procedure TryLoadCoverage;
    procedure ApplyIDETheme;
    procedure OnTestResultReceived(const AJSONData: string);
    procedure UpdateTimingLabels;
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
    procedure LaunchTestExe(const ATestFilter: string);
    procedure LogMsg(const AMsg: string);
    procedure RebuildStatusImages;
    procedure UpdateTabVisibility;
    procedure AddSessionButtonClick(Sender: TObject);

    procedure SetEnabledState(AValue: Boolean);
    procedure ToggleEnabledClick(Sender: TObject);
    procedure EnableBtnClick(Sender: TObject);
    procedure ClearLogsClick(Sender: TObject);
    procedure ExportMenuClick(Sender: TObject);
    procedure RunFailedTestsClick(Sender: TObject);
    procedure ExportResults(const ExportFormat, FileName: string);
    procedure IdleTimerTimer(Sender: TObject);
    procedure SaveTimerTimer(Sender: TObject);
    procedure ConfigChangeHandler(Sender: TObject);

    // Process handling
    function GetProjectByFileName(const AFileName: string): IOTAProject;
    procedure RefreshActiveProjectTestsList;
    procedure ResetSummaryLabels;
  protected
    procedure DoShow; override;
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RunActiveProjectTests(const ATestFilter: string = ''; AAutoSave: Boolean = True);
    procedure RunImpactedTests(const ATests: TArray<string>);
    procedure HandleFileSaved(const AFileName: string);
    // Called by the IDE AfterCompile notifier
    procedure NotifyCompileComplete(ASucceeded: Boolean);
    procedure RefreshProjects;
  end;

procedure ShowDextTestExplorer;
procedure RegisterDockableForm;
procedure UnregisterDockableForm;

var
  FormDextTestRunner: TFormDextTestRunner = nil;

implementation

{$R *.dfm}

uses
  DeskUtil, Dext.Utils, System.Actions, Vcl.ActnList, Dext.Testing.Design.Coverage, System.IniFiles,
  Winapi.CommCtrl, Dext.Testing.Report, Dext.Testing.Runner;

{$IF CompilerVersion < 35.0}
type
  TTreeViewHelper = class helper for TTreeView
  private
    function GetCheckboxes: Boolean;
    procedure SetCheckboxes(Value: Boolean);
  public
    property Checkboxes: Boolean read GetCheckboxes write SetCheckboxes;
  end;

  TTreeNodeHelper = class helper for TTreeNode
  private
    function GetChecked: Boolean;
    procedure SetChecked(Value: Boolean);
  public
    property Checked: Boolean read GetChecked write SetChecked;
  end;

function TTreeViewHelper.GetCheckboxes: Boolean;
begin
  Result := (GetWindowLong(Handle, GWL_STYLE) and TVS_CHECKBOXES) <> 0;
end;

procedure TTreeViewHelper.SetCheckboxes(Value: Boolean);
var
  Style: Longint;
begin
  Style := GetWindowLong(Handle, GWL_STYLE);
  if Value then
    Style := Style or TVS_CHECKBOXES
  else
    Style := Style and not TVS_CHECKBOXES;
  SetWindowLong(Handle, GWL_STYLE, Style);
end;

function TTreeNodeHelper.GetChecked: Boolean;
var
  TVItem: TTVItem;
begin
  Result := False;
  if (TreeView <> nil) and (TreeView.HandleAllocated) then
  begin
    TVItem.mask := TVIF_STATE or TVIF_HANDLE;
    TVItem.hItem := ItemId;
    TVItem.stateMask := TVIS_STATEIMAGEMASK;
    if TreeView_GetItem(TreeView.Handle, TVItem) then
      Result := ((TVItem.state and TVIS_STATEIMAGEMASK) shr 12) = 2;
  end;
end;

procedure TTreeNodeHelper.SetChecked(Value: Boolean);
var
  TVItem: TTVItem;
begin
  if (TreeView <> nil) and (TreeView.HandleAllocated) then
  begin
    TVItem.mask := TVIF_STATE or TVIF_HANDLE;
    TVItem.hItem := ItemId;
    TVItem.stateMask := TVIS_STATEIMAGEMASK;
    if Value then
      TVItem.state := 2 shl 12
    else
      TVItem.state := 1 shl 12;
    TreeView_SetItem(TreeView.Handle, TVItem);
  end;
end;
{$ENDIF}

type
  TDextThemeNotifier = class(TNotifierObject, INTAIDEThemingServicesNotifier)
  private
    FForm: TFormDextTestRunner;
  public
    constructor Create(AForm: TFormDextTestRunner);
    // INTAIDEThemingServicesNotifier
    procedure ChangingTheme;
    procedure ChangedTheme;
  end;

constructor TDextThemeNotifier.Create(AForm: TFormDextTestRunner);
begin
  inherited Create;
  FForm := AForm;
end;

procedure TDextThemeNotifier.ChangingTheme;
begin
end;

procedure TDextThemeNotifier.ChangedTheme;
begin
  if Assigned(FForm) then
  begin
    TThread.ForceQueue(nil, TThreadProcedure(procedure
      begin
        FForm.ApplyIDETheme;
      end));
  end;
end;

procedure ShowDextTestExplorer;
begin
  if not Assigned(FormDextTestRunner) then
    FormDextTestRunner := TFormDextTestRunner.Create(nil);
  ShowDockableForm(FormDextTestRunner);
end;

procedure RegisterDockableForm;
var
  ThemingServices: IOTAIDEThemingServices;
begin
  if @RegisterFieldAddress <> nil then
    RegisterFieldAddress('FormDextTestRunner', @FormDextTestRunner);
  RegisterDesktopFormClass(TFormDextTestRunner, 'FormDextTestRunner', 'FormDextTestRunner');

  if Supports(BorlandIDEServices, IOTAIDEThemingServices, ThemingServices) then
    ThemingServices.RegisterFormClass(TFormDextTestRunner);
end;

procedure UnregisterDockableForm;
begin
  if @UnRegisterFieldAddress <> nil then
    UnRegisterFieldAddress(@FormDextTestRunner);
  if Assigned(FormDextTestRunner) then
  begin
    FormDextTestRunner.Free;
    FormDextTestRunner := nil;
  end;
end;

function GetModuleBuildTime: string;
var
  FilePath: array[0..MAX_PATH] of Char;
  FileTime: TFileTime;
  SystemTime: TSystemTime;
  LocalTime: TSystemTime;
  Handle: THandle;
begin
  Result := '';
  if GetModuleFileName(HInstance, FilePath, Length(FilePath)) > 0 then
  begin
    Handle := CreateFile(FilePath, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    if Handle <> INVALID_HANDLE_VALUE then
    begin
      try
        if GetFileTime(Handle, nil, nil, @FileTime) then
        begin
          if FileTimeToSystemTime(FileTime, SystemTime) then
          begin
            if SystemTimeToTzSpecificLocalTime(nil, SystemTime, LocalTime) then
            begin
              Result := Format('%.4d-%.2d-%.2d %.2d:%.2d:%.2d',
                [LocalTime.wYear, LocalTime.wMonth, LocalTime.wDay,
                 LocalTime.wHour, LocalTime.wMinute, LocalTime.wSecond]);
            end;
          end;
        end;
      finally
        CloseHandle(Handle);
      end;
    end;
  end;
end;

{ TDextProjectInfo }

constructor TDextProjectInfo.Create(const AFileName: string);
begin
  inherited Create;
  FileName := AFileName;
end;

{ TDextProjectNotifier }

constructor TDextProjectNotifier.Create(AForm: TFormDextTestRunner; const AProjectFile: string);
begin
  inherited Create;
  FForm := AForm;
  FProjectFile := AProjectFile;
end;

function TDextProjectNotifier.CheckOverwrite: Boolean;
begin
  Result := True;
end;

procedure TDextProjectNotifier.ModuleRenamed(const NewName: string);
begin
end;

procedure TDextProjectNotifier.ModuleAdded(const AFileName: string);
begin
  if Assigned(FForm) then
  begin
    TThread.ForceQueue(nil, TThreadProcedure(procedure
      begin
        if Assigned(FormDextTestRunner) then
          FormDextTestRunner.RefreshActiveProjectTestsList;
      end));
  end;
end;

procedure TDextProjectNotifier.ModuleRemoved(const AFileName: string);
begin
  if Assigned(FForm) then
  begin
    TThread.ForceQueue(nil, TThreadProcedure(procedure
      begin
        if Assigned(FormDextTestRunner) then
          FormDextTestRunner.RefreshActiveProjectTestsList;
      end));
  end;
end;

procedure TDextProjectNotifier.ModuleRenamed(const AOldFileName, ANewFileName: string);
begin
end;

{ TTestSession }

constructor TTestSession.Create(APageControl: TPageControl; const AName: string);
begin
  inherited Create;
  TestLocations := TList<TTestLocation>.Create;

  TabSheet := TTabSheet.Create(APageControl.Owner);
  TabSheet.PageControl := APageControl;
  TabSheet.Caption := AName;

  var LFilterPanel := TPanel.Create(TabSheet);
  LFilterPanel.Parent := TabSheet;
  LFilterPanel.Align := alTop;
  LFilterPanel.Height := 28;
  LFilterPanel.BevelOuter := bvNone;

  FilterEdit := TEdit.Create(TabSheet);
  FilterEdit.Parent := LFilterPanel;
  FilterEdit.Align := alClient;
  FilterEdit.AlignWithMargins := True;
  FilterEdit.Margins.Left := 0;
  FilterEdit.Margins.Right := 0;
  FilterEdit.Margins.Top := 3;
  FilterEdit.Margins.Bottom := 3;
  FilterEdit.TextHint := 'Filter tests (Ctrl+F)...';
  if APageControl.Owner is TFormDextTestRunner then
    FilterEdit.OnChange := TFormDextTestRunner(APageControl.Owner).FilterEditChange;

  TreeView := TTreeView.Create(TabSheet);
  TreeView.Parent := TabSheet;
  TreeView.Align := alClient;
  TreeView.ReadOnly := True;
  TreeView.HideSelection := False;
  TreeView.Checkboxes := True;
  TreeView.DoubleBuffered := True;
  TreeView.StyleElements := [];
end;

constructor TTestSession.CreateFromExisting(ATabSheet: TTabSheet; ATreeView: TTreeView; ALocations: TList<TTestLocation>; const AProjFile: string);
begin
  inherited Create;
  TabSheet := ATabSheet;
  TreeView := ATreeView;
  TestLocations := ALocations;
  ActiveProjectFile := AProjFile;

  var LFilterPanel := TPanel.Create(ATabSheet);
  LFilterPanel.Parent := ATabSheet;
  LFilterPanel.Align := alTop;
  LFilterPanel.Height := 28;
  LFilterPanel.BevelOuter := bvNone;

  FilterEdit := TEdit.Create(ATabSheet);
  FilterEdit.Parent := LFilterPanel;
  FilterEdit.Align := alClient;
  FilterEdit.AlignWithMargins := True;
  FilterEdit.Margins.Left := 0;
  FilterEdit.Margins.Right := 0;
  FilterEdit.Margins.Top := 3;
  FilterEdit.Margins.Bottom := 3;
  FilterEdit.TextHint := 'Filter tests (Ctrl+F)...';
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

procedure TFormDextTestRunner.RebuildStatusImages;
var
  BgColor: TColor;
  Bitmap: TBitmap;
  ImageList: TImageList;
  OldImages: TCustomImageList;

  procedure DrawSmoothCircle(AColor: TColor; ADest: TBitmap);
  var
    LargeBmp: TBitmap;
  begin
    LargeBmp := TBitmap.Create;
    try
      LargeBmp.SetSize(64, 64);
      LargeBmp.Canvas.Brush.Color := BgColor;
      LargeBmp.Canvas.FillRect(Rect(0, 0, 64, 64));

      LargeBmp.Canvas.Pen.Color := AColor;
      LargeBmp.Canvas.Brush.Color := AColor;
      LargeBmp.Canvas.Ellipse(16, 16, 48, 48);

      ADest.Canvas.Brush.Color := BgColor;
      ADest.Canvas.FillRect(Rect(0, 0, 16, 16));

      SetStretchBltMode(ADest.Canvas.Handle, HALFTONE);
      SetBrushOrgEx(ADest.Canvas.Handle, 0, 0, nil);
      StretchBlt(ADest.Canvas.Handle, 0, 0, 16, 16, LargeBmp.Canvas.Handle, 0, 0, 64, 64, SRCCOPY);
    finally
      LargeBmp.Free;
    end;
  end;

begin
  if TestsTreeView <> nil then
    BgColor := TestsTreeView.Color
  else
    BgColor := clWindow;

  ImageList := TImageList.Create(Self);
  ImageList.Width := 16;
  ImageList.Height := 16;

  Bitmap := TBitmap.Create;
  try
    Bitmap.SetSize(16, 16);

    // 0: Idle (Gray circle)
    DrawSmoothCircle(clGray, Bitmap);
    ImageList.AddMasked(Bitmap, BgColor);

    // 1: Pass (Green circle)
    DrawSmoothCircle(TColor($5EC522), Bitmap);
    ImageList.AddMasked(Bitmap, BgColor);

    // 2: Fail (Red circle)
    DrawSmoothCircle(TColor($4444EF), Bitmap);
    ImageList.AddMasked(Bitmap, BgColor);

    // 3: Fixture (Blue circle)
    DrawSmoothCircle(TColor($F6823B), Bitmap);
    ImageList.AddMasked(Bitmap, BgColor);
  finally
    Bitmap.Free;
  end;

  OldImages := TestsTreeView.Images;
  TestsTreeView.Images := ImageList;

  if Assigned(FSessions) then
  begin
    for var I := 0 to FSessions.Count - 1 do
      if Assigned(FSessions[I].TreeView) then
        FSessions[I].TreeView.Images := ImageList;
  end;

  if Assigned(OldImages) then
    OldImages.Free;
end;

{ TFileScanCache }

constructor TFileScanCache.Create(ATimestamp: TDateTime; ATests: TList<TTestLocation>);
begin
  inherited Create;
  Timestamp := ATimestamp;
  Tests := ATests;
end;

destructor TFileScanCache.Destroy;
begin
  Tests.Free;
  inherited Destroy;
end;

{ TFormDextTestRunner }

constructor TFormDextTestRunner.Create(AOwner: TComponent);
var
  ThemingServices: IOTAIDEThemingServices;
begin
  FormDextTestRunner := Self;
  FRunningProcessHandle := 0;
  FActiveProjectNotifierIndex := -1;
  FActiveProjectForNotifier := nil;
  FStopwatch := TStopwatch.Create;
  FScanCache := TObjectDictionary<string, TFileScanCache>.Create([doOwnsValues]);

  inherited Create(AOwner);
  Caption := 'Test Explorer' {$IFDEF DEBUG} + '(Compiled: ' + GetModuleBuildTime + ')'{$ENDIF};
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

  var LRunAllItem3 := TMenuItem.Create(LRunAllMenu);
  LRunAllItem3.Caption := 'Run Failed Tests';
  LRunAllItem3.OnClick := RunFailedTestsClick;
  LRunAllMenu.Items.Add(LRunAllItem3);

  RunAllButton.Style := bsSplitButton;
  RunAllButton.DropDownMenu := LRunAllMenu;

  RunSelectedButton.Caption := #$25B6 + ' Selected';
  RunSelectedButton.Hint := 'Run checked tests only';
  RunSelectedButton.ShowHint := True;

  StopButton.Caption := #$25A0 + ' Stop';
  StopButton.Hint := 'Cancel current test execution';
  StopButton.ShowHint := True;

  RebuildStatusImages;
  TestsTreeView.Checkboxes := True;
  TestsTreeView.DoubleBuffered := True;
  TestsTreeView.StyleElements := [];

  // Assign advanced dynamic event handlers
  TestsTreeView.OnMouseMove := TestsTreeViewMouseMove;
  TestsTreeView.OnMouseLeave := TestsTreeViewMouseLeave;
  TestsTreeView.OnMouseDown := TestsTreeViewMouseDown;
  TestsTreeView.OnMouseUp := TestsTreeViewMouseUp;
  TestsTreeView.OnAdvancedCustomDrawItem := TestsTreeViewAdvancedCustomDrawItem;
  TestsTreeView.OnChange := TestsTreeViewChange;

  // Build context menu for TreeView
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

  SessionsPageControl.OnChange := SessionsPageControlChange;
  SessionsPageControl.OnContextPopup := SessionTabContextPopup;

  FServer := TTestRunnerServer.Create(8102);

  // Initialize Inspector UI dynamically
  FTestDetails := TDictionary<string, TTestDetailInfo>.Create;
  FTotalTests := 0;
  FCompletedTests := 0;

  // Progress bar panel
  FProgressPanel := TPanel.Create(Self);
  FProgressPanel.Parent := Self;
  FProgressPanel.Align := alTop;
  FProgressPanel.Height := 18;
  FProgressPanel.BevelOuter := bvNone;
  FProgressPanel.Visible := False;
  FProgressPanel.AlignWithMargins := True;
  FProgressPanel.Margins.Left := 4;
  FProgressPanel.Margins.Right := 4;
  FProgressPanel.Margins.Top := 2;
  FProgressPanel.Margins.Bottom := 2;
  FProgressPanel.BringToFront;

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

  ResetSummaryLabels;

  EnableDisableTestExplorerMenuItem.OnClick := ToggleEnabledClick;
  ClearMenuItem.OnClick := ClearLogsClick;

  FDetailsPageControl := TPageControl.Create(Self);
  FDetailsPageControl.Parent := DetailsPanel;
  FDetailsPageControl.Align := alClient;

  FInspectorTab := TTabSheet.Create(Self);
  FInspectorTab.PageControl := FDetailsPageControl;
  FInspectorTab.Caption := 'Test Inspector';

  FInspectorScroll := TScrollBox.Create(Self);
  FInspectorScroll.Parent := FInspectorTab;
  FInspectorScroll.Align := alClient;
  FInspectorScroll.BorderStyle := bsNone;
  FInspectorScroll.ParentColor := True;
  FInspectorScroll.StyleElements := [];

  var LInfoPanel := TPanel.Create(Self);
  LInfoPanel.Parent := FInspectorScroll;
  LInfoPanel.Align := alTop;
  LInfoPanel.Height := 98;
  LInfoPanel.BevelOuter := bvNone;
  LInfoPanel.ParentColor := True;
  LInfoPanel.StyleElements := [];

  FLblTestName := TLabel.Create(Self);
  FLblTestName.Parent := LInfoPanel;
  FLblTestName.Top := 6;
  FLblTestName.Left := 6;
  FLblTestName.Font.Style := [fsBold];
  FLblTestName.Caption := 'Test Name: Select a test...';
  FLblTestName.StyleElements := [];

  FLblStatus := TLabel.Create(Self);
  FLblStatus.Parent := LInfoPanel;
  FLblStatus.Top := 24;
  FLblStatus.Left := 6;
  FLblStatus.Caption := 'Status: Idle';
  FLblStatus.StyleElements := [];

  FLblLocation := TLabel.Create(Self);
  FLblLocation.Parent := LInfoPanel;
  FLblLocation.Top := 42;
  FLblLocation.Left := 6;
  FLblLocation.Caption := 'Location: N/A';
  FLblLocation.StyleElements := [];

  FLblDuration := TLabel.Create(Self);
  FLblDuration.Parent := LInfoPanel;
  FLblDuration.Top := 60;
  FLblDuration.Left := 6;
  FLblDuration.Caption := 'Duration: N/A';
  FLblDuration.StyleElements := [];

  FLblErrorHeader := TLabel.Create(Self);
  FLblErrorHeader.Parent := LInfoPanel;
  FLblErrorHeader.Top := 78;
  FLblErrorHeader.Left := 6;
  FLblErrorHeader.Font.Style := [fsBold];
  FLblErrorHeader.Caption := 'Errors / Stack Trace:';
  FLblErrorHeader.StyleElements := [];

  FMemoError := TMemo.Create(Self);
  FMemoError.Parent := FInspectorScroll;
  FMemoError.Align := alClient;
  FMemoError.AlignWithMargins := True;
  FMemoError.Margins.Left := 6;
  FMemoError.Margins.Right := 6;
  FMemoError.Margins.Top := 2;
  FMemoError.Margins.Bottom := 6;
  FMemoError.ReadOnly := True;
  FMemoError.ScrollBars := ssBoth;

  // Configurations Tab
  FConfigTab := TTabSheet.Create(Self);
  FConfigTab.PageControl := FDetailsPageControl;
  FConfigTab.Caption := 'Configurations';

  var LConfigScroll := TScrollBox.Create(Self);
  LConfigScroll.Parent := FConfigTab;
  LConfigScroll.Align := alClient;
  LConfigScroll.BorderStyle := bsNone;

  var FLblCustomParams := TLabel.Create(Self);
  FLblCustomParams.Parent := LConfigScroll;
  FLblCustomParams.Left := 10;
  FLblCustomParams.Top := 10;
  FLblCustomParams.Caption := 'Custom Command Line Parameters:';

  FCustomParamsEdit := TEdit.Create(Self);
  FCustomParamsEdit.Parent := LConfigScroll;
  FCustomParamsEdit.Left := 10;
  FCustomParamsEdit.Top := 28;
  FCustomParamsEdit.Width := 350;
  FCustomParamsEdit.TextHint := 'e.g. --filter mytest* --verbose';
  FCustomParamsEdit.OnChange := ConfigChangeHandler;

  FChkRunOnSave := TCheckBox.Create(Self);
  FChkRunOnSave.Parent := LConfigScroll;
  FChkRunOnSave.Left := 10;
  FChkRunOnSave.Top := 65;
  FChkRunOnSave.Width := 200;
  FChkRunOnSave.Caption := 'Run tests automatically on Save';
  FChkRunOnSave.OnClick := ConfigChangeHandler;

  FChkRunOnIdle := TCheckBox.Create(Self);
  FChkRunOnIdle.Parent := LConfigScroll;
  FChkRunOnIdle.Left := 10;
  FChkRunOnIdle.Top := 90;
  FChkRunOnIdle.Width := 200;
  FChkRunOnIdle.Caption := 'Run tests automatically on Idle';
  FChkRunOnIdle.OnClick := ConfigChangeHandler;

  FChkEnabled := TCheckBox.Create(Self);
  FChkEnabled.Parent := LConfigScroll;
  FChkEnabled.Left := 10;
  FChkEnabled.Top := 115;
  FChkEnabled.Width := 200;
  FChkEnabled.Caption := 'Enable Dext Test Explorer';
  FChkEnabled.OnClick := ToggleEnabledClick;

  FConsoleTab := TTabSheet.Create(Self);
  FConsoleTab.PageControl := FDetailsPageControl;
  FConsoleTab.Caption := 'Console Log';

  DetailsMemo.Parent := FConsoleTab;
  DetailsMemo.Align := alClient;

  ExportToJUnitXmlMenutem.OnClick := ExportMenuClick;
  ExportToXUnitXMLMenutem.OnClick := ExportMenuClick;
  ExportToJsonMenutem.OnClick := ExportMenuClick;
  ExportToSonarQubeXmlMenutem.OnClick := ExportMenuClick;
  ExportToHtmlReportMenuItem.OnClick := ExportMenuClick;

  if Supports(BorlandIDEServices, IOTAIDEThemingServices, ThemingServices) then
  begin
    if ThemingServices.IDEThemingEnabled then
      ThemingServices.ApplyTheme(Self);
  end;

  // Reposition layout & session buttons
  RefreshButton.Left   := 2;
  RefreshButton.Top    := 5;
  RefreshButton.Width  := 75;
  RefreshButton.Height := 25;

  RunAllButton.Left   := 80;
  RunAllButton.Top    := 5;
  RunAllButton.Width  := 85;
  RunAllButton.Height := 25;

  RunSelectedButton.Left   := 168;
  RunSelectedButton.Top    := 5;
  RunSelectedButton.Width  := 75;
  RunSelectedButton.Height := 25;

  StopButton.Left   := 246;
  StopButton.Top    := 5;
  StopButton.Width  := 50;
  StopButton.Height := 25;

  CreateaNewSessionMenuItem.OnClick := AddSessionButtonClick;

  TabbedLayoutMenuItem.Tag := Ord(telCompact);
  TabbedLayoutMenuItem.OnClick := LayoutMenuClick;
  TabbedLayoutMenuItem.Checked := True;
  SplitBottomLayoutMenuItem.Tag := Ord(telSplitBottom);
  SplitBottomLayoutMenuItem.OnClick := LayoutMenuClick;
  SplitBottomLayoutMenuItem.Checked := True;
  SplitRightLayoutMenuItem.Tag := Ord(telSplitRight);
  SplitRightLayoutMenuItem.OnClick := LayoutMenuClick;
  SplitRightLayoutMenuItem.Checked := True;

  GroupByClassMenuItem.Tag := 100 + Ord(tgmCodeStructure);
  GroupByClassMenuItem.OnClick := GroupingMenuClick;
  GroupByClassMenuItem.Checked := True;
  GroupbyTestStatusMenuItem.Tag := 100 + Ord(tgmStatus);
  GroupbyTestStatusMenuItem.OnClick := GroupingMenuClick;
  GroupbyTestStatusMenuItem.Checked := False;

  FInspectorSplitter := TSplitter.Create(Self);
  FInspectorSplitter.Parent := DetailsPanel;
  FInspectorSplitter.Visible := False;
  FCurrentLayout := telCompact;

  // Disabled overlay banner/panel
  FDisabledPanel := TPanel.Create(Self);
  FDisabledPanel.Parent := Self;
  FDisabledPanel.Align := alClient;
  FDisabledPanel.BevelOuter := bvNone;
  FDisabledPanel.Visible := False;
  FDisabledPanel.Color := clWindow;
  FDisabledPanel.ParentBackground := False;

  FDisabledContainer := TPanel.Create(Self);
  FDisabledContainer.Parent := FDisabledPanel;
  FDisabledContainer.Width := 300;
  FDisabledContainer.Height := 100;
  FDisabledContainer.BevelOuter := bvNone;
  FDisabledContainer.ParentBackground := True;

  var FLblDisabledMsg := TLabel.Create(Self);
  FLblDisabledMsg.Parent := FDisabledContainer;
  FLblDisabledMsg.Align := alTop;
  FLblDisabledMsg.Alignment := taCenter;
  FLblDisabledMsg.Caption := 'Dext Test Explorer is currently disabled.' + #13#10 + 'Enable it to load projects and run tests.';
  FLblDisabledMsg.Font.Size := 10;
  FLblDisabledMsg.Height := 40;

  var FBtnEnable := TButton.Create(Self);
  FBtnEnable.Parent := FDisabledContainer;
  FBtnEnable.Left := (FDisabledContainer.Width - 120) div 2;
  FBtnEnable.Top := 50;
  FBtnEnable.Width := 120;
  FBtnEnable.Height := 30;
  FBtnEnable.Caption := 'Enable';
  FBtnEnable.OnClick := EnableBtnClick;
  EnableDisableTestExplorerMenuItem.OnClick := ToggleEnabledClick;
  EnableDisableTestExplorerMenuItem.Visible := True;

  // Initialize Idle Timer
  FIdleTimer := TTimer.Create(Self);
  FIdleTimer.Interval := 2500; // 2.5 seconds debounce
  FIdleTimer.Enabled := False;
  FIdleTimer.OnTimer := IdleTimerTimer;

  // Initialize Save Timer and list
  FSaveTimer := TTimer.Create(Self);
  FSaveTimer.Interval := 250; // 250ms debounce
  FSaveTimer.Enabled := False;
  FSaveTimer.OnTimer := SaveTimerTimer;

  FPendingSaveFiles := TStringList.Create;
  FPendingSaveFiles.Sorted := True;
  FPendingSaveFiles.Duplicates := dupIgnore;

  // Load layout and configs from ini file
  var LLayoutMode := Ord(telCompact);
  var LGroupingMode := Ord(tgmCodeStructure);
  var LIniFile := TPath.Combine(TPath.GetHomePath, 'DextTestExplorer.ini');
  try
    var LIni := TMemIniFile.Create(LIniFile);
    try
      FEnabled := LIni.ReadBool('General', 'Enabled', True);
      LLayoutMode := LIni.ReadInteger('Layout', 'Mode', Ord(telCompact));
      LGroupingMode := LIni.ReadInteger('Grouping', 'Mode', Ord(tgmCodeStructure));
      FCustomParamsEdit.Text := LIni.ReadString('General', 'CustomParams', '');
      FChkRunOnSave.Checked := LIni.ReadBool('General', 'RunOnSave', False);
      FChkRunOnIdle.Checked := LIni.ReadBool('General', 'RunOnIdle', False);
    finally
      LIni.Free;
    end;
  except
    FEnabled := True;
  end;

  SetEnabledState(FEnabled);
  ApplyLayout(TTestExplorerLayout(LLayoutMode));
  FGroupingMode := TTestGroupingMode(LGroupingMode);
  FIdleTimer.Enabled := FChkRunOnIdle.Checked;

  // Sync menu Checked states based on loaded configurations
  TabbedLayoutMenuItem.Checked := TTestExplorerLayout(LLayoutMode) = telCompact;
  SplitBottomLayoutMenuItem.Checked := TTestExplorerLayout(LLayoutMode) = telSplitBottom;
  SplitRightLayoutMenuItem.Checked := TTestExplorerLayout(LLayoutMode) = telSplitRight;

  GroupByClassMenuItem.Checked := TTestGroupingMode(LGroupingMode) = tgmCodeStructure;
  GroupByTestStatusMenuItem.Checked := TTestGroupingMode(LGroupingMode) = tgmStatus;

  Self.KeyPreview := True;
  Self.OnKeyDown := FormKeyDown;

  FThemeNotifierIndex := -1;
  ApplyIDETheme;

  if Supports(BorlandIDEServices, IOTAIDEThemingServices, ThemingServices) then
  begin
    FThemeNotifierIndex := ThemingServices.AddNotifier(TDextThemeNotifier.Create(Self) as INTAIDEThemingServicesNotifier);
  end;

  if FEnabled then
  begin
    RefreshProjects;
  end;
  UpdateTabVisibility;
  FServer.Start(OnTestResultReceived);
end;

destructor TFormDextTestRunner.Destroy;
var
  LThemingServices: IOTAIDEThemingServices;
begin
  if (FActiveProjectNotifierIndex <> -1) and Assigned(FActiveProjectForNotifier) then
  begin
    try
      FActiveProjectForNotifier.RemoveNotifier(FActiveProjectNotifierIndex);
    except
    end;
    FActiveProjectNotifierIndex := -1;
    FActiveProjectForNotifier := nil;
  end;

  if FRunningProcessHandle <> 0 then
  begin
    TerminateProcess(FRunningProcessHandle, 0);
    CloseHandle(FRunningProcessHandle);
    FRunningProcessHandle := 0;
  end;

  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) and (FThemeNotifierIndex <> -1) then
  begin
    LThemingServices.RemoveNotifier(FThemeNotifierIndex);
    FThemeNotifierIndex := -1;
  end;

  FServer.Stop;
  FServer.Free;
  FSessions.Free;
  FTestDetails.Free;

  if Assigned(FIdleTimer) then
    FIdleTimer.Free;
  if Assigned(FSaveTimer) then
    FSaveTimer.Free;
  if Assigned(FPendingSaveFiles) then
    FPendingSaveFiles.Free;
  if Assigned(FScanCache) then
    FScanCache.Free;

  if Assigned(ProjectsComboBox) then
  begin
    for var I := 0 to ProjectsComboBox.Items.Count - 1 do
      ProjectsComboBox.Items.Objects[I].Free;
  end;

  if FormDextTestRunner = Self then
    FormDextTestRunner := nil;
  inherited Destroy;
end;

procedure TFormDextTestRunner.DoShow;
begin
  inherited DoShow;
  ApplyIDETheme;
end;

function TFormDextTestRunner.GetProjectByFileName(const AFileName: string): IOTAProject;
var
  LModuleServices: IOTAModuleServices;
  LGroup: IOTAProjectGroup;
  I: Integer;
begin
  Result := nil;
  if not Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) then
    Exit;
  LGroup := LModuleServices.MainProjectGroup;
  if Assigned(LGroup) then
  begin
    for I := 0 to LGroup.ProjectCount - 1 do
    begin
      if Assigned(LGroup.Projects[I]) and SameText(LGroup.Projects[I].FileName, AFileName) then
      begin
        Result := LGroup.Projects[I];
        Exit;
      end;
    end;
  end;
end;

procedure TFormDextTestRunner.RefreshActiveProjectTestsList;
var
  CacheDict: TObjectDictionary<string, TFileScanCache>;
  FileName: string;
  Files: TArray<string>;
  FilesToScan: TList<string>;
  FilesToScanArray: TArray<string>;
  Generation: Integer;
  i: Integer;
  ModifiedTimes: TArray<TDateTime>;
  Project: IOTAProject;
begin
  if not FEnabled then Exit;
  Project := GetProjectByFileName(FActiveProjectFile);
  if not Assigned(Project) then
  begin
    TestsTreeView.Items.BeginUpdate;
    try
      TestsTreeView.Items.Clear;
      FTestLocations.Clear;
      ResetSummaryLabels;
    finally
      TestsTreeView.Items.EndUpdate;
    end;
    Exit;
  end;

  SetLength(Files, Project.GetModuleCount);
  for i := 0 to Project.GetModuleCount - 1 do
    Files[i] := Project.GetModule(i).FileName;

  TestsTreeView.Items.BeginUpdate;
  try
    TestsTreeView.Items.Clear;
    FTestLocations.Clear;
    TestsTreeView.Items.AddChild(nil, 'Loading tests asynchronously...');
  finally
    TestsTreeView.Items.EndUpdate;
  end;

  Inc(FScanGeneration);
  Generation := FScanGeneration;

  // Query modified times and determine what needs to be scanned
  CacheDict := TObjectDictionary<string, TFileScanCache>(FScanCache);
  FilesToScan := TList<string>.Create;
  try
    for FileName in Files do
    begin
      if SameText(ExtractFileExt(FileName), '.pas') and FileExists(FileName) then
      begin
        var LCache: TFileScanCache := nil;
        var LTime := TFile.GetLastWriteTime(FileName);
        if CacheDict.TryGetValue(FileName, LCache) then
        begin
          if LCache.Timestamp <> LTime then
            FilesToScan.Add(FileName);
        end
        else
          FilesToScan.Add(FileName);
      end;
    end;
    FilesToScanArray := FilesToScan.ToArray;
  finally
    FilesToScan.Free;
  end;

  SetLength(ModifiedTimes, Length(FilesToScanArray));
  for i := 0 to Length(FilesToScanArray) - 1 do
    ModifiedTimes[i] := TFile.GetLastWriteTime(FilesToScanArray[i]);

  TTask.Run(TProc(procedure
    var
      LScannedLists: TArray<TList<TTestLocation>>;
      i: Integer;
    begin
      SetLength(LScannedLists, Length(FilesToScanArray));

      for i := 0 to Length(FilesToScanArray) - 1 do
      begin
        var LTests: TList<TTestLocation> := nil;
        if TTestASTScanner.ScanFile(FilesToScanArray[i], LTests) then
          LScannedLists[i] := LTests
        else
          LScannedLists[i] := nil;
      end;

      TThread.Queue(nil, TThreadProcedure(procedure
        var
          i: Integer;
          FileName: string;
        begin
          if Generation <> FScanGeneration then
          begin
            for i := 0 to Length(LScannedLists) - 1 do
              if Assigned(LScannedLists[i]) then
                LScannedLists[i].Free;
            Exit;
          end;

          for i := 0 to Length(FilesToScanArray) - 1 do
          begin
            FileName := FilesToScanArray[i];
            var LTests := LScannedLists[i];
            if LTests = nil then
              LTests := TList<TTestLocation>.Create;
            CacheDict.AddOrSetValue(FileName, TFileScanCache.Create(ModifiedTimes[i], LTests));
          end;

          TestsTreeView.Items.BeginUpdate;
          try
            TestsTreeView.Items.Clear;
            FTestLocations.Clear;

            for FileName in Files do
            begin
              var LCache: TFileScanCache := nil;
              if CacheDict.TryGetValue(FileName, LCache) then
              begin
                for var LTest in LCache.Tests do
                  FTestLocations.Add(LTest);
              end;
            end;

            RefreshTreeView;
          finally
            TestsTreeView.Items.EndUpdate;
          end;
        end));
    end));
end;

procedure TFormDextTestRunner.ApplyIDETheme;
var
  ThemingServices: IOTAIDEThemingServices;
  BgColor, FgColor: TColor;
begin
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, ThemingServices) then
  begin
    if ThemingServices.IDEThemingEnabled then
    begin
      BgColor := ThemingServices.StyleServices.GetSystemColor(clWindow);
      FgColor := ThemingServices.StyleServices.GetSystemColor(clWindowText);

      // 1. Update the active TestsTreeView
      if Assigned(TestsTreeView) then
      begin
        TestsTreeView.Color := BgColor;
        TestsTreeView.Font.Color := FgColor;
        TestsTreeView.Font.Size := 9;
        TestsTreeView.Invalidate;
      end;

      // 2. Loop through all sessions to update all TreeViews
      if Assigned(FSessions) then
      begin
        for var LIdx := 0 to FSessions.Count - 1 do
        begin
          var LSession := FSessions[LIdx];
          if Assigned(LSession.TreeView) then
          begin
            LSession.TreeView.Color := BgColor;
            LSession.TreeView.Font.Color := FgColor;
            LSession.TreeView.Font.Size := 9;
            LSession.TreeView.Invalidate;
          end;
        end;
      end;

      // 3. Details Memo
      if Assigned(DetailsMemo) then
      begin
        DetailsMemo.Color := BgColor;
        DetailsMemo.Font.Color := FgColor;
      end;

      // 4. Test Inspector (Scrollbox & Labels)
      if Assigned(FInspectorScroll) then
      begin
        FInspectorScroll.ParentColor := False;
        FInspectorScroll.Color := BgColor;
      end;

      if Assigned(FLblTestName) then FLblTestName.Font.Color := FgColor;
      if Assigned(FLblStatus) then
      begin
        if (not string(FLblStatus.Caption).Contains('Passed')) and (not string(FLblStatus.Caption).Contains('Failed')) then
          FLblStatus.Font.Color := FgColor;
      end;
      if Assigned(FLblLocation) then FLblLocation.Font.Color := FgColor;
      if Assigned(FLblDuration) then FLblDuration.Font.Color := FgColor;
      if Assigned(FLblErrorHeader) then FLblErrorHeader.Font.Color := FgColor;

      if Assigned(FMemoError) then
      begin
        FMemoError.Color := BgColor;
        FMemoError.Font.Color := FgColor;
      end;

      if Assigned(SummaryTotalLabel) then SummaryTotalLabel.Font.Color := FgColor;
      if Assigned(SummarySelectedLabel) then SummarySelectedLabel.Font.Color := FgColor;
      if Assigned(SummaryTimeLabel) then SummaryTimeLabel.Font.Color := FgColor;

      // 5. Form background color
      Self.Color := ThemingServices.StyleServices.GetSystemColor(clBtnFace);

      RebuildStatusImages;
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

procedure TFormDextTestRunner.Resize;
begin
  inherited;
  if Assigned(FDisabledContainer) and Assigned(FDisabledPanel) then
  begin
    FDisabledContainer.Left := (FDisabledPanel.ClientWidth - FDisabledContainer.Width) div 2;
    FDisabledContainer.Top := (FDisabledPanel.ClientHeight - FDisabledContainer.Height) div 2;
  end;
end;

procedure TFormDextTestRunner.SetEnabledState(AValue: Boolean);
begin
  FEnabled := AValue;
  FDisabledPanel.Visible := not AValue;

  if Assigned(FChkEnabled) then
  begin
    var LHandler := FChkEnabled.OnClick;
    FChkEnabled.OnClick := nil;
    try
      FChkEnabled.Checked := AValue;
    finally
      FChkEnabled.OnClick := LHandler;
    end;
  end;

  ProjectsComboBox.Enabled := AValue;
  ButtonsPanel.Enabled := AValue;
  SessionsPageControl.Enabled := AValue;
  DetailsPanel.Enabled := AValue;

  if AValue then
  begin
    if ProjectsComboBox.Items.Count = 0 then
      RefreshProjects
    else if FActiveProjectFile <> '' then
      RefreshActiveProjectTestsList;
  end
  else
  begin
    TestsTreeView.Items.Clear;
    FTestLocations.Clear;
  end;

  if Assigned(EnableDisableTestExplorerMenuItem) then
  begin
    if AValue then
      EnableDisableTestExplorerMenuItem.Caption := 'Disable Test Explorer'
    else
      EnableDisableTestExplorerMenuItem.Caption := 'Enable Test Explorer';
  end;
end;

procedure TFormDextTestRunner.ToggleEnabledClick(Sender: TObject);
var
  IniFile: TMemIniFile;
begin
  SetEnabledState(not FEnabled);
  IniFile := TMemIniFile.Create(TPath.Combine(TPath.GetHomePath, 'DextTestExplorer.ini'));
  try
    IniFile.WriteBool('General', 'Enabled', FEnabled);
    IniFile.UpdateFile;
  finally
    IniFile.Free;
  end;
end;

procedure TFormDextTestRunner.EnableBtnClick(Sender: TObject);
var
  IniFile : TMemIniFile;
begin
  SetEnabledState(True);
  IniFile := TMemIniFile.Create(TPath.Combine(TPath.GetHomePath, 'DextTestExplorer.ini'));
  try
    IniFile.WriteBool('General', 'Enabled', True);
    IniFile.UpdateFile;
  finally
    IniFile.Free;
  end;
end;

procedure TFormDextTestRunner.ClearLogsClick(Sender: TObject);
begin
  DetailsMemo.Clear;
  ClearTestStatus;
  ResetSummaryLabels;
end;

procedure TFormDextTestRunner.RunFailedTestsClick(Sender: TObject);
var
  LFailedTests: TList<string>;
  LKey: string;
  LInfo: TTestDetailInfo;
begin
  LFailedTests := TList<string>.Create;
  try
    for LKey in FTestDetails.Keys do
    begin
      LInfo := FTestDetails[LKey];
      if SameText(LInfo.Status, 'Failed') or SameText(LInfo.Status, 'Error') then
      begin
        LFailedTests.Add(LKey);
      end;
    end;

    if LFailedTests.Count > 0 then
    begin
      LogMsg(Format('Running %d failed tests...', [LFailedTests.Count]));
      RunImpactedTests(LFailedTests.ToArray);
    end
    else
    begin
      LogMsg('No failed tests to run.');
    end;
  finally
    LFailedTests.Free;
  end;
end;

procedure TFormDextTestRunner.ExportMenuClick(Sender: TObject);
var
  DefaultExtension: string;
  ExportFormat: string;
  Filter: string;
  SaveDialog: TSaveDialog;
  Text: string;
begin
  if not (Sender is TMenuItem) then Exit;
  Text := TMenuItem(Sender).Caption;

  if Text = 'Export to JUnit XML' then
  begin
    ExportFormat := 'junit';
    DefaultExtension := 'xml';
    Filter := 'XML Files (*.xml)|*.xml';
  end
  else if Text = 'Export to XUnit XML' then
  begin
    ExportFormat := 'xunit';
    DefaultExtension := 'xml';
    Filter := 'XML Files (*.xml)|*.xml';
  end
  else if Text = 'Export to JSON' then
  begin
    ExportFormat := 'json';
    DefaultExtension := 'json';
    Filter := 'JSON Files (*.json)|*.json';
  end
  else if Text = 'Export to SonarQube XML' then
  begin
    ExportFormat := 'sonar';
    DefaultExtension := 'xml';
    Filter := 'XML Files (*.xml)|*.xml';
  end
  else if Text = 'Export to HTML Report' then
  begin
    ExportFormat := 'html';
    DefaultExtension := 'html';
    Filter := 'HTML Files (*.html)|*.html';
  end
  else
    Exit;

  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.DefaultExt := DefaultExtension;
    SaveDialog.Filter := Filter;
    SaveDialog.Title := 'Export Test Report';
    if SaveDialog.Execute then
    begin
      ExportResults(ExportFormat, SaveDialog.FileName);
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TFormDextTestRunner.ExportResults(const ExportFormat, FileName: string);
var
  HTMLReporter: THTMLReporter;
  JsonReporter: TJsonReporter;
  JUnitReporter: TJUnitReporter;
  SonarReporter: TSonarQubeReporter;
  SuiteName: string;
  TestDetailInfo: TTestDetailInfo;
  TestInfo: TTestInfo;
  XUnitReporter: TXUnitReporter;
begin
  SuiteName := ExtractFileName(ChangeFileExt(FActiveProjectFile, ''));
  if SuiteName = '' then SuiteName := 'DextTests';

  if SameText(ExportFormat, 'junit') then
  begin
    JUnitReporter := TJUnitReporter.Create;
    try
      JUnitReporter.BeginSuite(SuiteName);
      for var LKey in FTestDetails.Keys do
      begin
        TestDetailInfo := FTestDetails[LKey];
        FillChar(TestInfo, SizeOf(TestInfo), 0);
        var LParts := TestDetailInfo.TestName.Split(['.']);
        if Length(LParts) >= 2 then
        begin
          TestInfo.FixtureName := LParts[0];
          TestInfo.TestName := LParts[1];
        end
        else
        begin
          TestInfo.FixtureName := 'Default';
          TestInfo.TestName := TestDetailInfo.TestName;
        end;
        TestInfo.DisplayName := TestDetailInfo.TestName;
        if SameText(TestDetailInfo.Status, 'Passed') then TestInfo.Result := trPassed
        else if SameText(TestDetailInfo.Status, 'Failed') or SameText(TestDetailInfo.Status, 'Error') then TestInfo.Result := trFailed
        else if SameText(TestDetailInfo.Status, 'Skipped') then TestInfo.Result := trSkipped
        else TestInfo.Result := trNone;
        TestInfo.Duration := TTimeSpan.FromMilliseconds(TestDetailInfo.DurationMs);
        TestInfo.ErrorMessage := TestDetailInfo.ErrorMessage;
        TestInfo.StackTrace := TestDetailInfo.StackTrace;
        JUnitReporter.AddTestCase(TestInfo);
      end;
      JUnitReporter.EndSuite;
      JUnitReporter.SaveToFile(FileName);
      LogMsg('Results exported to JUnit format: ' + FileName);
    finally
      JUnitReporter.Free;
    end;
  end
  else if SameText(ExportFormat, 'xunit') then
  begin
    XUnitReporter := TXUnitReporter.Create;
    try
      XUnitReporter.BeginSuite(SuiteName);
      for var LKey in FTestDetails.Keys do
      begin
        TestDetailInfo := FTestDetails[LKey];
        FillChar(TestInfo, SizeOf(TestInfo), 0);
        var LParts := TestDetailInfo.TestName.Split(['.']);
        if Length(LParts) >= 2 then
        begin
          TestInfo.FixtureName := LParts[0];
          TestInfo.TestName := LParts[1];
        end
        else
        begin
          TestInfo.FixtureName := 'Default';
          TestInfo.TestName := TestDetailInfo.TestName;
        end;
        TestInfo.DisplayName := TestDetailInfo.TestName;
        if SameText(TestDetailInfo.Status, 'Passed') then TestInfo.Result := trPassed
        else if SameText(TestDetailInfo.Status, 'Failed') or SameText(TestDetailInfo.Status, 'Error') then TestInfo.Result := trFailed
        else if SameText(TestDetailInfo.Status, 'Skipped') then TestInfo.Result := trSkipped
        else TestInfo.Result := trNone;
        TestInfo.Duration := TTimeSpan.FromMilliseconds(TestDetailInfo.DurationMs);
        TestInfo.ErrorMessage := TestDetailInfo.ErrorMessage;
        TestInfo.StackTrace := TestDetailInfo.StackTrace;
        XUnitReporter.AddTestCase(TestInfo);
      end;
      XUnitReporter.EndSuite;
      XUnitReporter.SaveToFile(FileName);
      LogMsg('Results exported to XUnit format: ' + FileName);
    finally
      XUnitReporter.Free;
    end;
  end;
  if SameText(ExportFormat, 'json') then
  begin
    JsonReporter := TJsonReporter.Create;
    try
      JsonReporter.BeginSuite(SuiteName);
      for var LKey in FTestDetails.Keys do
      begin
        TestDetailInfo := FTestDetails[LKey];
        FillChar(TestInfo, SizeOf(TestInfo), 0);
        var LParts := TestDetailInfo.TestName.Split(['.']);
        if Length(LParts) >= 2 then
        begin
          TestInfo.FixtureName := LParts[0];
          TestInfo.TestName := LParts[1];
        end
        else
        begin
          TestInfo.FixtureName := 'Default';
          TestInfo.TestName := TestDetailInfo.TestName;
        end;
        TestInfo.DisplayName := TestDetailInfo.TestName;
        if SameText(TestDetailInfo.Status, 'Passed') then TestInfo.Result := trPassed
        else if SameText(TestDetailInfo.Status, 'Failed') or SameText(TestDetailInfo.Status, 'Error') then TestInfo.Result := trFailed
        else if SameText(TestDetailInfo.Status, 'Skipped') then TestInfo.Result := trSkipped
        else TestInfo.Result := trNone;
        TestInfo.Duration := TTimeSpan.FromMilliseconds(TestDetailInfo.DurationMs);
        TestInfo.ErrorMessage := TestDetailInfo.ErrorMessage;
        TestInfo.StackTrace := TestDetailInfo.StackTrace;
        JsonReporter.AddTestCase(TestInfo);
      end;
      JsonReporter.EndSuite;
      JsonReporter.SaveToFile(FileName);
      LogMsg('Results exported to JSON format: ' + FileName);
    finally
      JsonReporter.Free;
    end;
  end
  else if SameText(ExportFormat, 'sonar') then
  begin
    SonarReporter := TSonarQubeReporter.Create;
    try
      for var LKey in FTestDetails.Keys do
      begin
        TestDetailInfo := FTestDetails[LKey];
        FillChar(TestInfo, SizeOf(TestInfo), 0);
        var LParts := TestDetailInfo.TestName.Split(['.']);
        if Length(LParts) >= 2 then
        begin
          TestInfo.FixtureName := LParts[0];
          TestInfo.TestName := LParts[1];
        end
        else
        begin
          TestInfo.FixtureName := 'Default';
          TestInfo.TestName := TestDetailInfo.TestName;
        end;
        TestInfo.DisplayName := TestDetailInfo.TestName;
        if SameText(TestDetailInfo.Status, 'Passed') then TestInfo.Result := trPassed
        else if SameText(TestDetailInfo.Status, 'Failed') or SameText(TestDetailInfo.Status, 'Error') then TestInfo.Result := trFailed
        else if SameText(TestDetailInfo.Status, 'Skipped') then TestInfo.Result := trSkipped
        else TestInfo.Result := trNone;
        TestInfo.Duration := TTimeSpan.FromMilliseconds(TestDetailInfo.DurationMs);
        TestInfo.ErrorMessage := TestDetailInfo.ErrorMessage;
        TestInfo.StackTrace := TestDetailInfo.StackTrace;
        SonarReporter.AddTestCase(TestInfo);
      end;
      SonarReporter.SaveToFile(FileName);
      LogMsg('Results exported to SonarQube format: ' + FileName);
    finally
      SonarReporter.Free;
    end;
  end
  else if SameText(ExportFormat, 'html') then
  begin
    HTMLReporter := THTMLReporter.Create;
    try
      HTMLReporter.SetTitle(SuiteName);
      HTMLReporter.BeginSuite(SuiteName);
      for var LKey in FTestDetails.Keys do
      begin
        TestDetailInfo := FTestDetails[LKey];
        FillChar(TestInfo, SizeOf(TestInfo), 0);
        var LParts := TestDetailInfo.TestName.Split(['.']);
        if Length(LParts) >= 2 then
        begin
          TestInfo.FixtureName := LParts[0];
          TestInfo.TestName := LParts[1];
        end
        else
        begin
          TestInfo.FixtureName := 'Default';
          TestInfo.TestName := TestDetailInfo.TestName;
        end;
        TestInfo.DisplayName := TestDetailInfo.TestName;
        if SameText(TestDetailInfo.Status, 'Passed') then TestInfo.Result := trPassed
        else if SameText(TestDetailInfo.Status, 'Failed') or SameText(TestDetailInfo.Status, 'Error') then TestInfo.Result := trFailed
        else if SameText(TestDetailInfo.Status, 'Skipped') then TestInfo.Result := trSkipped
        else TestInfo.Result := trNone;
        TestInfo.Duration := TTimeSpan.FromMilliseconds(TestDetailInfo.DurationMs);
        TestInfo.ErrorMessage := TestDetailInfo.ErrorMessage;
        TestInfo.StackTrace := TestDetailInfo.StackTrace;
        HTMLReporter.AddTestCase(TestInfo);
      end;
      HTMLReporter.EndSuite;
      HTMLReporter.SaveToFile(FileName);
      LogMsg('Results exported to HTML format: ' + FileName);
    finally
      HTMLReporter.Free;
    end;
  end;
end;

procedure TFormDextTestRunner.IdleTimerTimer(Sender: TObject);
begin
  FIdleTimer.Enabled := False;
  if FEnabled and FChkRunOnIdle.Checked and (FActiveProjectFile <> '') then
  begin
    LogMsg('Idle auto-run triggered.');
    RunActiveProjectTests;
  end;
end;

procedure TFormDextTestRunner.ConfigChangeHandler(Sender: TObject);
begin
  var LIni := TMemIniFile.Create(TPath.Combine(TPath.GetHomePath, 'DextTestExplorer.ini'));
  try
    LIni.WriteString('General', 'CustomParams', FCustomParamsEdit.Text);
    LIni.WriteBool('General', 'RunOnSave', FChkRunOnSave.Checked);
    LIni.WriteBool('General', 'RunOnIdle', FChkRunOnIdle.Checked);
    LIni.UpdateFile;
  finally
    LIni.Free;
  end;

  if Assigned(FIdleTimer) then
    FIdleTimer.Enabled := FChkRunOnIdle.Checked;
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
  LPrevSelectedFile: string;
  LFoundIndex: Integer;
begin
  LPrevSelectedFile := FActiveProjectFile;

  // Clear existing items and free their TDextProjectInfo objects
  for I := 0 to ProjectsComboBox.Items.Count - 1 do
    ProjectsComboBox.Items.Objects[I].Free;
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

          ProjectsComboBox.Items.AddObject(ExtractFileName(LProjFile), TDextProjectInfo.Create(LProjFile));
        end;
      end;
    end;
  end;

  LFoundIndex := -1;
  if LPrevSelectedFile <> '' then
  begin
    for I := 0 to ProjectsComboBox.Items.Count - 1 do
    begin
      var LInfo := TDextProjectInfo(ProjectsComboBox.Items.Objects[I]);
      if Assigned(LInfo) and SameText(LInfo.FileName, LPrevSelectedFile) then
      begin
        LFoundIndex := I;
        Break;
      end;
    end;
  end;

  if LFoundIndex <> -1 then
  begin
    ProjectsComboBox.ItemIndex := LFoundIndex;
    ProjectsComboBoxChange(ProjectsComboBox);
  end
  else if ProjectsComboBox.Items.Count > 0 then
  begin
    ProjectsComboBox.ItemIndex := 0;
    ProjectsComboBoxChange(ProjectsComboBox);
  end
  else
  begin
    ProjectsComboBox.ItemIndex := -1;
    FActiveProjectFile := '';
    if FActiveSession <> nil then
      FActiveSession.ActiveProjectFile := '';
    TestsTreeView.Items.Clear;
    FTestLocations.Clear;
    ResetSummaryLabels;
  end;
end;

procedure TFormDextTestRunner.ProjectsComboBoxChange(Sender: TObject);
var
  LProj: IOTAProject;
  LProjInfo: TDextProjectInfo;
begin
  if ProjectsComboBox.ItemIndex = -1 then Exit;

  LProjInfo := TDextProjectInfo(ProjectsComboBox.Items.Objects[ProjectsComboBox.ItemIndex]);
  if not Assigned(LProjInfo) then Exit;

  LProj := GetProjectByFileName(LProjInfo.FileName);
  if not Assigned(LProj) then Exit;

  FActiveProjectFile := LProj.FileName;
  if FActiveSession <> nil then
    FActiveSession.ActiveProjectFile := FActiveProjectFile;

  // Unregister old project notifier
  if (FActiveProjectNotifierIndex <> -1) and Assigned(FActiveProjectForNotifier) then
  begin
    try
      FActiveProjectForNotifier.RemoveNotifier(FActiveProjectNotifierIndex);
    except
      // ignore in case project was already destroyed
    end;
    FActiveProjectNotifierIndex := -1;
    FActiveProjectForNotifier := nil;
  end;

  // Register notifier on new project
  FActiveProjectForNotifier := LProj;
  try
    FActiveProjectNotifierIndex := LProj.AddNotifier(TDextProjectNotifier.Create(Self, LProj.FileName));
  except
    FActiveProjectNotifierIndex := -1;
    FActiveProjectForNotifier := nil;
  end;

  RefreshActiveProjectTestsList;
end;

function TFormDextTestRunner.FindNodeByPath(const APath: string): TTreeNode;
var
  I: Integer;
  LNode: TTreeNode;
  LSplit: TArray<string>;

  function GetNodeClassName(const ANodeText: string): string;
  var
    LPos: Integer;
  begin
    LPos := ANodeText.IndexOf(' (');
    if LPos > 0 then
      Result := ANodeText.Substring(0, LPos)
    else
      Result := ANodeText;
  end;
begin
  Result := nil;

  if FGroupingMode = tgmStatus then
  begin
    // In status mode, child nodes are named exactly 'ClassName.MethodName'. Root nodes are 'Failed', 'Passed', 'Skipped', 'Idle'.
    for I := 0 to TestsTreeView.Items.Count - 1 do
    begin
      LNode := TestsTreeView.Items[I];
      if (LNode.Parent <> nil) and SameText(LNode.Text, APath) then
      begin
        Result := LNode;
        Exit;
      end;
    end;

    // If not found, check if searching for a status category node itself
    for I := 0 to TestsTreeView.Items.Count - 1 do
    begin
      LNode := TestsTreeView.Items[I];
      if (LNode.Parent = nil) and SameText(LNode.Text, APath) then
      begin
        Result := LNode;
        Exit;
      end;
    end;

    Exit;
  end;

  // If APath contains a dot, try to find the child node via ClassName.MethodName
  if APath.Contains('.') then
  begin
    LSplit := APath.Split(['.'], 2);
    if Length(LSplit) = 2 then
    begin
      for I := 0 to TestsTreeView.Items.Count - 1 do
      begin
        LNode := TestsTreeView.Items[I];
        if (LNode.Parent = nil) and SameText(GetNodeClassName(LNode.Text), LSplit[0]) then
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

  // Fallback: search all nodes by ClassName prefix
  for I := 0 to TestsTreeView.Items.Count - 1 do
  begin
    LNode := TestsTreeView.Items[I];
    if (LNode.Parent = nil) and SameText(GetNodeClassName(LNode.Text), APath) then
    begin
      Result := LNode;
      Exit;
    end;
  end;
end;

procedure TFormDextTestRunner.OnTestResultReceived(const AJSONData: string);
var
  LValue: TJSONValue;
  LArray: TJSONArray;
  I: Integer;

  procedure ProcessSingleResult(LJSON: TJSONObject);
  var
    LTestName, LStatus, LMsg, LStackTrace: string;
    LErrorObj: TJSONObject;
    LEvent: string;
    LPassed, LFailed, LIgnored: Integer;
    LDurationMs: Double;
  begin
    if LJSON.TryGetValue<string>('event', LEvent) and SameText(LEvent, 'RunComplete') then
    begin
      LPassed := LJSON.GetValue<Integer>('passed');
      LFailed := LJSON.GetValue<Integer>('failed');
      LIgnored := LJSON.GetValue<Integer>('ignored');
      LogMsg('');
      LogMsg('========================================');
      LogMsg(Format('Testing Completed. Passed: %d, Failed: %d, Ignored: %d', [LPassed, LFailed, LIgnored]));
      LogMsg('========================================');

      // Stop the stopwatch
      TStopwatch(FStopwatch).Stop;
      UpdateTimingLabels;

      // Mark any remaining 'Idle' tests as 'Skipped'
      var LIdx: Integer;
      var LTest: TTestLocation;
      var LFullTestName: string;
      var LInfo: TTestDetailInfo;
      for LIdx := 0 to FTestLocations.Count - 1 do
      begin
        LTest := FTestLocations[LIdx];
        LFullTestName := LTest.ClassName + '.' + LTest.MethodName;
        if FTestDetails.TryGetValue(LFullTestName, LInfo) then
        begin
          if SameText(LInfo.Status, 'Idle') or (LInfo.Status = '') then
          begin
            LInfo.Status := 'Skipped';
            FTestDetails.AddOrSetValue(LFullTestName, LInfo);
            Inc(FSkippedCount);
          end;
        end
        else
        begin
          LInfo.TestName := LFullTestName;
          LInfo.Status := 'Skipped';
          LInfo.DurationMs := 0;
          LInfo.ErrorMessage := 'Not executed';
          LInfo.StackTrace := '';
          LInfo.FileName := LTest.FileName;
          LInfo.Line := LTest.Line;
          FTestDetails.AddOrSetValue(LFullTestName, LInfo);
          Inc(FSkippedCount);
        end;
      end;

      // Update final labels
      SummarySuccessLabel.Caption := 'Passed: ' + FPassedCount.ToString;
      SummaryFailedLabel.Caption := 'Failed: ' + FFailedCount.ToString;
      SummarySkippedLabel.Caption := 'Skipped: ' + FSkippedCount.ToString;

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
      if FRunningProcessHandle <> 0 then
      begin
        CloseHandle(FRunningProcessHandle);
        FRunningProcessHandle := 0;
      end;
      FRunningTests := False;
      TTelemetryTracker.AnalyzeHistory(FActiveProjectFile, DetailsMemo);
      CollapseSuccessAndFocusFailures;
      TryLoadCoverage;
      Exit;
    end;

    if LJSON.TryGetValue<string>('event', LEvent) and SameText(LEvent, 'RunStart') then
    begin
      FTotalTests := LJSON.GetValue<Integer>('totalTests');
      FCompletedTests := 0;
      FPassedCount := 0;
      FFailedCount := 0;
      FSkippedCount := 0;
      FTestExecutionDurationMs := 0;

      // Ensure all test locations exist in FTestDetails as Idle
      var LIdx: Integer;
      var LTest: TTestLocation;
      var LFullTestName: string;
      var LInfo: TTestDetailInfo;
      for LIdx := 0 to FTestLocations.Count - 1 do
      begin
        LTest := FTestLocations[LIdx];
        LFullTestName := LTest.ClassName + '.' + LTest.MethodName;
        LInfo.TestName := LFullTestName;
        LInfo.Status := 'Idle';
        LInfo.DurationMs := 0;
        LInfo.ErrorMessage := '';
        LInfo.StackTrace := '';
        LInfo.FileName := LTest.FileName;
        LInfo.Line := LTest.Line;
        FTestDetails.AddOrSetValue(LFullTestName, LInfo);
      end;

      if Assigned(FProgressPanel) then
      begin
        FProgressBar.Max := Max(1, FTotalTests);
        FProgressBar.Position := 0;
        FProgressLabel.Caption := Format('0/%d', [FTotalTests]);
        FProgressPanel.Visible := True;
      end;

      // Update summary counts
      var LChecked := GetCheckedTests;
      var LSelectedCount := Length(LChecked);
      if LSelectedCount = 0 then
        LSelectedCount := FTestLocations.Count;
      SummarySelectedLabel.Caption := 'Selected: ' + LSelectedCount.ToString;
      SummaryTotalLabel.Caption := 'Total: ' + FTestLocations.Count.ToString;
      SummarySuccessLabel.Caption := 'Passed: 0';
      SummaryFailedLabel.Caption := 'Failed: 0';
      SummarySkippedLabel.Caption := 'Skipped: 0';
      UpdateTimingLabels;

      if FGroupingMode = tgmStatus then
        RefreshTreeView;
      Exit;
    end;

    // Detect if this is a standard result or a TestInsight result
    LTestName := '';
    LStatus := '';
    LMsg := '';
    LStackTrace := '';
    LDurationMs := 0;

    if LJSON.TryGetValue<string>('testName', LTestName) then
    begin
      // Standard Dext result format
      LJSON.TryGetValue<string>('status', LStatus);
      LJSON.TryGetValue<Double>('durationMs', LDurationMs);
      if LJSON.TryGetValue<TJSONObject>('error', LErrorObj) and Assigned(LErrorObj) then
      begin
        LMsg := LErrorObj.GetValue<string>('message');
        LStackTrace := LErrorObj.GetValue<TJSONObject>('stackTrace').ToJSON;
      end;
    end
    else if LJSON.TryGetValue<string>('testname', LTestName) then
    begin
      // TestInsight compatibility result format
      LJSON.TryGetValue<string>('resulttype', LStatus);

      // Map TestInsight status to Dext status standard values ('Passed', 'Failed', 'Skipped', 'Error')
      if SameText(LStatus, 'Passed') then LStatus := 'Passed'
      else if SameText(LStatus, 'Failed') then LStatus := 'Failed'
      else if SameText(LStatus, 'Error') then LStatus := 'Error'
      else if SameText(LStatus, 'Skipped') then LStatus := 'Skipped';

      var LFixture: string := '';
      if LJSON.TryGetValue<string>('fixturename', LFixture) and (LFixture <> '') then
      begin
        LTestName := LFixture + '.' + LTestName;
      end;

      var LTempDur: Double := 0;
      if LJSON.TryGetValue<Double>('duration', LTempDur) then
        LDurationMs := LTempDur;

      LJSON.TryGetValue<string>('exceptionmessage', LMsg);
      LJSON.TryGetValue<string>('status', LStackTrace);
    end;

    if LTestName = '' then Exit;

    LogMsg('Result received: ' + LTestName + ' - ' + LStatus);

    if not SameText(LStatus, 'Running') then
    begin
      // Update progress bar
      Inc(FCompletedTests);
      if Assigned(FProgressPanel) and FProgressPanel.Visible then
      begin
        if FProgressBar.Style = pbstMarquee then
          FProgressBar.Style := pbstNormal;
        FProgressBar.Max := Max(FProgressBar.Max, FTotalTests);
        FProgressBar.Position := Min(FCompletedTests, FProgressBar.Max);
        FProgressLabel.Caption := Format('%d/%d', [FCompletedTests, FTotalTests]);
      end;

      if SameText(LStatus, 'Passed') then
        Inc(FPassedCount)
      else if SameText(LStatus, 'Failed') or SameText(LStatus, 'Error') then
        Inc(FFailedCount)
      else if SameText(LStatus, 'Skipped') then
        Inc(FSkippedCount);

      SummarySuccessLabel.Caption := 'Passed: ' + FPassedCount.ToString;
      SummaryFailedLabel.Caption := 'Failed: ' + FFailedCount.ToString;
      SummarySkippedLabel.Caption := 'Skipped: ' + FSkippedCount.ToString;
      FTestExecutionDurationMs := FTestExecutionDurationMs + LDurationMs;
      UpdateTimingLabels;
    end;

    TTelemetryTracker.RecordTestResult(FActiveProjectFile, LTestName, LStatus, Round(LDurationMs));

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
      var LIdx := Integer(LNode.Data) - 1;
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
        SameText(GetNodeFullTestName(TestsTreeView.Selected), LTestName)) then
    begin
      UpdateTestInspector(LTestName);
    end;
  end;

begin
  LogMsg('[Debug Payload] ' + AJSONData);

  LValue := TJSONObject.ParseJSONValue(AJSONData);
  if not Assigned(LValue) then Exit;

  try
    if LValue is TJSONArray then
    begin
      LArray := TJSONArray(LValue);
      for I := 0 to LArray.Count - 1 do
      begin
        if LArray.Items[I] is TJSONObject then
          ProcessSingleResult(TJSONObject(LArray.Items[I]));
      end;
    end
    else if LValue is TJSONObject then
    begin
      ProcessSingleResult(TJSONObject(LValue));
    end;
  finally
    LValue.Free;
  end;
end;

procedure TFormDextTestRunner.CollapseSuccessAndFocusFailures;
var
  I: Integer;
  LNode: TTreeNode;
  LChild: TTreeNode;
  LHasFailures: Boolean;
  LFirstFailedNode: TTreeNode;
begin
  if TestsTreeView = nil then Exit;

  if FGroupingMode = tgmStatus then
    RefreshTreeView;

  TestsTreeView.Items.BeginUpdate;
  try
    LFirstFailedNode := nil;

    // Iterate through all nodes to find top-level nodes
    for I := 0 to TestsTreeView.Items.Count - 1 do
    begin
      LNode := TestsTreeView.Items[I];

      // We only care about root nodes that have children
      if (LNode.Parent = nil) and (LNode.Count > 0) then
      begin
        if FGroupingMode = tgmStatus then
        begin
          if SameText(LNode.Text, 'Failed') then
          begin
            LNode.Expanded := True;
            LChild := LNode.GetFirstChild;
            if Assigned(LChild) and not Assigned(LFirstFailedNode) then
              LFirstFailedNode := LChild;
          end
          else
          begin
            LNode.Expanded := False;
          end;
        end
        else
        begin
          LHasFailures := False;

          LChild := LNode.GetFirstChild;
          while Assigned(LChild) do
          begin
            if LChild.ImageIndex = 2 then
            begin
              LHasFailures := True;
              if not Assigned(LFirstFailedNode) then
                LFirstFailedNode := LChild;
            end;

            LChild := LChild.GetNextSibling;
          end;

          if LHasFailures then
            LNode.Expanded := True;
        end;
      end;
    end;

    // Focus the first failure if found
    if Assigned(LFirstFailedNode) then
    begin
      TestsTreeView.Selected := LFirstFailedNode;
      LFirstFailedNode.MakeVisible;
    end;
  finally
    TestsTreeView.Items.EndUpdate;
  end;
end;

procedure TFormDextTestRunner.NotifyProcessExited;
begin
  FRunningTests := False;
  if FRunningProcessHandle <> 0 then
  begin
    LogMsg('');
    LogMsg('========================================');
    LogMsg('Testing Completed (Process Exited)');
    LogMsg('========================================');

    if Assigned(FProgressPanel) then
    begin
      FProgressBar.Position := FProgressBar.Max;
      FProgressLabel.Caption := Format('%d/%d', [FCompletedTests, Max(FCompletedTests, FTotalTests)]);
      TThread.Queue(nil, TThreadProcedure(procedure
        begin
          if Assigned(FProgressPanel) then
            FProgressPanel.Visible := False;
        end));
    end;

    CloseHandle(FRunningProcessHandle);
    FRunningProcessHandle := 0;
    TStopwatch(FStopwatch).Stop;
    UpdateTimingLabels;

    TTelemetryTracker.AnalyzeHistory(FActiveProjectFile, DetailsMemo);
    CollapseSuccessAndFocusFailures;
    TryLoadCoverage;
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
        LogMsg('Test Failed: ' + ATestName);
        LogMsg('Error: ' + AMessage);
        if AStackTrace <> '' then
        begin
          LogMsg('Stack Trace:');
          LogMsg(AStackTrace);
        end;
        LogMsg('----------------------------------------');
      end;
    end
    else if SameText(AStatus, 'Skipped') then
    begin
      LNode.ImageIndex := 0; // Gray
      LNode.SelectedIndex := 0;
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

  LKey := GetNodeFullTestName(Node);
  UpdateTestInspector(LKey);
  if (Node.Parent <> nil) and FTestDetails.ContainsKey(LKey) then
  begin
    if FDetailsPageControl.Visible then
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
    LIdx := Integer(LNode.Data) - 1;
    if (LIdx >= 0) and (LIdx < FTestLocations.Count) then
    begin
      LLoc := FTestLocations[LIdx];
      var LRealLine := FindMethodImplementationLine(LLoc.FileName, LLoc.ClassName, LLoc.MethodName, LLoc.Line);
      FLblLocation.Caption := Format('Location: %s (Line %d)', [ExtractFileName(LLoc.FileName), LRealLine]);
    end;
  end;

  if FTestDetails.TryGetValue(ATestName, LInfo) then
  begin
    LStatusText := LInfo.Status;
    FLblStatus.Caption := 'Status: ' + LStatusText;
    FLblStatus.ParentColor := False;
    if SameText(LStatusText, 'Passed') then
      FLblStatus.Font.Color := TColor($5EC522) // Green BGR
    else if SameText(LStatusText, 'Failed') or SameText(LStatusText, 'Error') then
      FLblStatus.Font.Color := TColor($4444EF) // Red BGR
    else
    begin
      FLblStatus.Font.Color := clWindowText;
      FLblStatus.ParentColor := True;
    end;

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

procedure TFormDextTestRunner.RunActiveProjectTests(const ATestFilter: string; AAutoSave: Boolean);
var
  LProj: IOTAProject;
  LModuleServices: IOTAModuleServices;
  LGroup: IOTAProjectGroup;
begin
  if ProjectsComboBox.ItemIndex = -1 then Exit;
  LProj := GetProjectByFileName(FActiveProjectFile);
  if not Assigned(LProj) then Exit;

  FRunningTests := True;

  // Synchronize IDE Active Project
  if Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) and Assigned(LModuleServices) then
  begin
    LGroup := LModuleServices.MainProjectGroup;
    if Assigned(LGroup) and (LGroup.ActiveProject <> LProj) then
      LGroup.ActiveProject := LProj;
  end;

  ClearTestStatus;
  DetailsMemo.Clear;
  FTotalTests := 0;
  FCompletedTests := 0;
  FTestExecutionDurationMs := 0;

  // Start stopwatch
  TStopwatch(FStopwatch).Reset;
  TStopwatch(FStopwatch).Start;
  UpdateTimingLabels;

  // Show progress immediately so the user knows something is happening
  if Assigned(FProgressPanel) then
  begin
    FProgressBar.Style := pbstMarquee;
    FProgressBar.Position := 0;
    FProgressBar.Max := 100;
    FProgressLabel.Caption := 'Saving files...';
    FProgressPanel.Visible := True;
    FProgressPanel.Update;
  end;
  if Assigned(FDetailsPageControl) and Assigned(FConsoleTab) then
    FDetailsPageControl.ActivePage := FConsoleTab;

  LogMsg('--- Dext Test Runner ---');
  LogMsg('Project: ' + ExtractFileName(FActiveProjectFile));

  // Step 1: Save all editor buffers so IDE's make sees up-to-date timestamps
  var LSaveServices: IOTAModuleServices;
  if AAutoSave and Supports(BorlandIDEServices, IOTAModuleServices, LSaveServices) then
  begin
    LogMsg('[1/3] Saving all modified files...');
    LSaveServices.SaveAll;
  end;

  // Step 2: Trigger the IDE's incremental make (async).
  //   The IDE knows exactly which files changed in the editor.
  //   Test launch happens in NotifyCompileComplete → AfterCompile notifier.
  FPendingTestFilter  := ATestFilter;
  FPendingProject     := LProj;
  FWaitingForCompile  := True;

  if Assigned(FProgressPanel) then
  begin
    FProgressLabel.Caption := '[2/3] Compiling...';
    FProgressPanel.Update;
  end;
  LogMsg('[2/3] Starting incremental compile (IDE make)...');
  DetailsMemo.Update;

  LProj.ProjectBuilder.BuildProject(cmOTAMake, False, True);
  // Returns immediately — NotifyCompileComplete is called by Expert.AfterCompile
end;

procedure TFormDextTestRunner.LaunchTestExe(const ATestFilter: string);
var
  LIsPackage: Boolean;
  LOutput: string;
  LExeFile: string;
  LParams: string;
  LCmdLine: string;
  SI: TStartupInfo;
  PI: TProcessInformation;
begin
  LIsPackage := False;
  LOutput := '';
  GetProjectTargetInfo(FActiveProjectFile, LIsPackage, LOutput);
  LExeFile := ResolveExePath(FActiveProjectFile, LOutput);

  if not FileExists(LExeFile) then
  begin
    LogMsg('Error: Executable not found at ' + LExeFile);
    TStopwatch(FStopwatch).Stop;
    UpdateTimingLabels;
    if Assigned(FProgressPanel) then FProgressPanel.Visible := False;
    Exit;
  end;

  // Apply test filter to server selection JSON
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

  LogMsg('Selected tests filter: ' + FServer.SelectedTestsJSON);

  // Update progress to 'Executing'
  if Assigned(FProgressPanel) then
  begin
    FProgressLabel.Caption := '⏳ Executing tests...';
    FProgressBar.Style := pbstMarquee;
    FProgressPanel.Visible := True;
    FProgressPanel.Update;
  end;
  DetailsMemo.Update;

  LParams := Format('--port %d -no-wait', [FServer.Port]);
  var LCustomParams := FCustomParamsEdit.Text;
  if LCustomParams <> '' then
    LParams := LParams + ' ' + LCustomParams;

  if ATestFilter <> '' then
  begin
    FServer.SelectedTestsJSON := '["' + ATestFilter + '"]';
  end;

  LCmdLine := Format('"%s" %s', [LExeFile, LParams]);
  LogMsg('Command Line: ' + LCmdLine);
  UniqueString(LCmdLine);

  ZeroMemory(@SI, SizeOf(SI));
  SI.cb := SizeOf(SI);
  ZeroMemory(@PI, SizeOf(PI));

  if FRunningProcessHandle <> 0 then
  begin
    TerminateProcess(FRunningProcessHandle, 0);
    CloseHandle(FRunningProcessHandle);
    FRunningProcessHandle := 0;
  end;

  if CreateProcess(nil, PChar(LCmdLine), nil, nil, False, CREATE_NO_WINDOW, nil, PChar(ExtractFilePath(LExeFile)), SI, PI) then
  begin
    FRunningProcessHandle := PI.hProcess;
    CloseHandle(PI.hThread);

    var LProcessHandle := PI.hProcess;
    TThread.CreateAnonymousThread(procedure
      begin
        WaitForSingleObject(LProcessHandle, 120000); // 120s timeout max
        TThread.Queue(nil, TThreadProcedure(procedure
          begin
            if Assigned(FormDextTestRunner) then
              FormDextTestRunner.NotifyProcessExited;
          end));
      end).Start;
  end
  else
    LogMsg('Failed to launch runner: ' + LExeFile);
end;

procedure TFormDextTestRunner.LogMsg(const AMsg: string);
begin
  if AMsg = '' then
    DetailsMemo.Lines.Add('')
  else
    DetailsMemo.Lines.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss.zzz', Now), AMsg]));
  DetailsMemo.Update;
end;

procedure TFormDextTestRunner.UpdateTimingLabels;
begin
  SummaryTimeLabel.Caption := Format('Tests: %.2fs', [FTestExecutionDurationMs / 1000]);
  SummaryTotalTimeLabel.Caption := Format('Total: %.2fs', [TStopwatch(FStopwatch).Elapsed.TotalSeconds]);
end;

procedure TFormDextTestRunner.NotifyCompileComplete(ASucceeded: Boolean);
begin
  if not FWaitingForCompile then Exit;
  FWaitingForCompile := False;

  if not ASucceeded then
  begin
    FRunningTests := False;
    LogMsg('❌ Compile failed — tests not executed.');
    TStopwatch(FStopwatch).Stop;
    UpdateTimingLabels;
    if Assigned(FProgressPanel) then
    begin
      FProgressLabel.Caption := 'Compile failed';
      FProgressPanel.Visible := False;
    end;
    Exit;
  end;

  LogMsg('✔ Compile succeeded.');
  LaunchTestExe(FPendingTestFilter);
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
  FRunningTests := True;
  ClearTestStatus;
  DetailsMemo.Clear;
  FTotalTests := 0;
  FCompletedTests := 0;
  if Assigned(FProgressPanel) then
  begin
    FProgressBar.Style := pbstMarquee;
    FProgressBar.Position := 0;
    FProgressBar.Max := 100;
    FProgressLabel.Caption := '...';
    FProgressPanel.Visible := True;
  end;
  // Focus Console Log
  if Assigned(FDetailsPageControl) and Assigned(FConsoleTab) then
    FDetailsPageControl.ActivePage := FConsoleTab;
  LogMsg('=== Running All Test Projects ===');

  // Save all modified IDE files once before the loop.
  var LSaveServices: IOTAModuleServices;
  if Supports(BorlandIDEServices, IOTAModuleServices, LSaveServices) then
  begin
    LogMsg('Saving all modified files...');
    LSaveServices.SaveAll;
  end;

  for I := 0 to ProjectsComboBox.Items.Count - 1 do
  begin
    var LProjInfo := TDextProjectInfo(ProjectsComboBox.Items.Objects[I]);
    if Assigned(LProjInfo) then
    begin
      LProj := GetProjectByFileName(LProjInfo.FileName);
      if Assigned(LProj) then
      begin
        LProjFile := LProj.FileName;
        LogMsg('');
        LogMsg('----------------------------------------');
        LogMsg('Compiling ' + ExtractFileName(LProjFile) + '...');
        if not CompileProjectDirect(LProjFile) then
        begin
          LogMsg('Direct DCC compile failed, building via IDE make...');
          LProj.ProjectBuilder.BuildProject(cmOTAMake, False, True);
        end;

        LIsPackage := False;
        LOutput := '';
        GetProjectTargetInfo(LProjFile, LIsPackage, LOutput);
        LExeFile := ResolveExePath(LProjFile, LOutput);

        if FileExists(LExeFile) then
        begin
          LogMsg('Executing ' + ExtractFileName(LExeFile) + '...');
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
            LogMsg('Failed to launch runner: ' + LExeFile);
            TStopwatch(FStopwatch).Stop;
            UpdateTimingLabels;
          end;
        end;
      end;
    end;
  end;
  FRunningTests := False;
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
    RunActiveProjectTests(GetNodeFullTestName(TestsTreeView.Selected));
  end
  else
    RunActiveProjectTests;
end;

procedure TFormDextTestRunner.StopButtonClick(Sender: TObject);
begin
  FRunningTests := False;
  LogMsg('Stop clicked. Terminating running test runner process...');
  if FRunningProcessHandle <> 0 then
  begin
    TerminateProcess(FRunningProcessHandle, 0);
    CloseHandle(FRunningProcessHandle);
    FRunningProcessHandle := 0;
  end;

  FWaitingForCompile := False;

  if Assigned(FProgressPanel) then
  begin
    FProgressBar.Style := pbstNormal;
    FProgressBar.Position := 0;
    FProgressPanel.Visible := False;
  end;
  TStopwatch(FStopwatch).Stop;
  UpdateTimingLabels;

  LogMsg('Test execution stopped.');
end;

function TFormDextTestRunner.FindMethodImplementationLine(const AFileName, AClassName, AMethodName: string; ADefaultLine: Integer): Integer;
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

procedure TFormDextTestRunner.TestsTreeViewDblClick(Sender: TObject);
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

  LIdx := Integer(LNode.Data) - 1;
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
        LList.Add(GetNodeFullTestName(LNode));
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
  Result.Left := LTextRect.Right + 3;
  Result.Top := LTextRect.Top + (LTextRect.Height - 14) div 2;
  Result.Right := Result.Left + 16;
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
          RunActiveProjectTests(GetNodeFullTestName(LNode));
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

function TFormDextTestRunner.GetNodeFullTestName(ANode: TTreeNode): string;
var
  LParentText: string;
  LSpaceIdx: Integer;
begin
  Result := '';
  if not Assigned(ANode) then Exit;

  if FGroupingMode = tgmStatus then
  begin
    if ANode.Parent <> nil then
      Result := ANode.Text // Under status grouping, leaf nodes hold 'ClassName.MethodName'
    else
      Result := '';
    Exit;
  end;

  if ANode.Parent = nil then
  begin
    LParentText := ANode.Text;
    LSpaceIdx := LParentText.IndexOf(' (');
    if LSpaceIdx > 0 then
      Result := LParentText.Substring(0, LSpaceIdx)
    else
      Result := LParentText;
  end
  else
  begin
    LParentText := ANode.Parent.Text;
    LSpaceIdx := LParentText.IndexOf(' (');
    if LSpaceIdx > 0 then
      LParentText := LParentText.Substring(0, LSpaceIdx);
    Result := LParentText + '.' + ANode.Text;
  end;
end;

procedure TFormDextTestRunner.FilterEditChange(Sender: TObject);
begin
  RefreshTreeView;
end;

procedure TFormDextTestRunner.LayoutMenuClick(Sender: TObject);
begin
  if Sender is TMenuItem then
  begin
    TabbedLayoutMenuItem.Checked := Sender = TabbedLayoutMenuItem;
    SplitBottomLayoutMenuItem.Checked := Sender = SplitBottomLayoutMenuItem;
    SplitRightLayoutMenuItem.Checked := Sender = SplitRightLayoutMenuItem;
    ApplyLayout(TTestExplorerLayout(TMenuItem(Sender).Tag));
  end;
end;

procedure TFormDextTestRunner.GroupingMenuClick(Sender: TObject);
var
  IniFile: TMemIniFile;
begin
  if Sender is TMenuItem then
  begin
    GroupByClassMenuItem.Checked := Sender = GroupByClassMenuItem;
    GroupByTestStatusMenuItem.Checked := Sender = GroupByTestStatusMenuItem;

    FGroupingMode := TTestGroupingMode(TMenuItem(Sender).Tag - 100);

    // Save grouping mode to ini file
    try
      IniFile := TMemIniFile.Create(TPath.Combine(TPath.GetHomePath, 'DextTestExplorer.ini'));
      try
        IniFile.WriteInteger('Grouping', 'Mode', Ord(FGroupingMode));
      finally
        IniFile.Free;
      end;
    except
    end;

    RefreshTreeView;
  end;
end;

function TFormDextTestRunner.ActiveFilterEdit: TEdit;
begin
  if FActiveSession <> nil then
    Result := FActiveSession.FilterEdit
  else
    Result := nil;
end;

procedure TFormDextTestRunner.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  ActiveFilter: TEdit;
begin
  if (Key = Ord('F')) and (ssCtrl in Shift) then
  begin
    ActiveFilter := ActiveFilterEdit;
    if Assigned(ActiveFilter) then
    begin
      ActiveFilter.SetFocus;
      Key := 0;
    end;
  end;
end;

procedure TFormDextTestRunner.ApplyLayout(ALayout: TTestExplorerLayout);
var
  IniFile: TMemIniFile;
begin
  FCurrentLayout := ALayout;

  try
    IniFile := TMemIniFile.Create(TPath.Combine(TPath.GetHomePath, 'DextTestExplorer.ini'));
    try
      IniFile.WriteInteger('Layout', 'Mode', Ord(ALayout));
      IniFile.UpdateFile;
    finally
      IniFile.Free;
    end;
  except
    // ignore
  end;

  DetailsMemo.Align := alNone;
  FInspectorScroll.Align := alNone;
  FInspectorSplitter.Visible := False;

  case ALayout of
    telCompact:
    begin
      NameSplitter.Align := alBottom;
      NameSplitter.Cursor := crVSplit;
      DetailsPanel.Align := alBottom;
      DetailsPanel.Height := 220;

      FDetailsPageControl.Visible := True;
      DetailsMemo.Parent := FConsoleTab;
      DetailsMemo.Align := alClient;
      DetailsMemo.AlignWithMargins := False;
      FInspectorScroll.Parent := FInspectorTab;
      FInspectorScroll.Align := alClient;
      FInspectorScroll.AlignWithMargins := False;
      NameSplitter.Top := FInspectorScroll.Top - NameSplitter.Height;
    end;

    telSplitBottom:
    begin
      NameSplitter.Align := alBottom;
      NameSplitter.Cursor := crVSplit;
      DetailsPanel.Align := alBottom;
      DetailsPanel.Height := 150;

      FDetailsPageControl.Visible := False;

      DetailsMemo.Parent := DetailsPanel;
      DetailsMemo.Align := alLeft;
      DetailsMemo.Width := DetailsPanel.Width div 2;
      DetailsMemo.AlignWithMargins := True;
      DetailsMemo.Margins.Left := 6;
      DetailsMemo.Margins.Right := 0;
      DetailsMemo.Margins.Top := 6;
      DetailsMemo.Margins.Bottom := 6;

      FInspectorSplitter.Parent := DetailsPanel;
      FInspectorSplitter.Align := alLeft;
      FInspectorSplitter.Cursor := crHSplit;
      FInspectorSplitter.Width := 6;
      FInspectorSplitter.Visible := True;

      FInspectorScroll.Parent := DetailsPanel;
      FInspectorScroll.Align := alClient;
      FInspectorScroll.AlignWithMargins := True;
      FInspectorScroll.Margins.Left := 0;
      FInspectorScroll.Margins.Right := 6;
      FInspectorScroll.Margins.Top := 6;
      FInspectorScroll.Margins.Bottom := 6;
      NameSplitter.Top := FInspectorScroll.Top - NameSplitter.Height;
    end;

    telSplitRight:
    begin
      NameSplitter.Align := alRight;
      NameSplitter.Cursor := crHSplit;
      DetailsPanel.Align := alRight;
      DetailsPanel.Width := 320;

      FDetailsPageControl.Visible := False;

      DetailsMemo.Parent := DetailsPanel;
      DetailsMemo.Align := alBottom;
      DetailsMemo.Height := DetailsPanel.Height div 2;
      DetailsMemo.AlignWithMargins := True;
      DetailsMemo.Margins.Left := 6;
      DetailsMemo.Margins.Right := 6;
      DetailsMemo.Margins.Top := 0;
      DetailsMemo.Margins.Bottom := 6;

      FInspectorSplitter.Parent := DetailsPanel;
      FInspectorSplitter.Align := alBottom;
      FInspectorSplitter.Cursor := crVSplit;
      FInspectorSplitter.Height := 6;
      FInspectorSplitter.Visible := True;

      FInspectorScroll.Parent := DetailsPanel;
      FInspectorScroll.Align := alClient;
      FInspectorScroll.AlignWithMargins := True;
      FInspectorScroll.Margins.Left := 0;
      FInspectorScroll.Margins.Right := 0;
      FInspectorScroll.Margins.Top := 6;
      FInspectorScroll.Margins.Bottom := 0;
    end;
  end;

  // Ensure correct Z-order of aligned controls to make Splitter work correctly
  DetailsPanel.SendToBack;
  NameSplitter.SendToBack;
end;

procedure TFormDextTestRunner.RefreshTreeView;
var
  LFilter: string;
  LIdx: Integer;
  LTest: TTestLocation;
  LFixtureNode, LMethodNode: TTreeNode;
  LClassMatches: Boolean;
  LMethodMatches: Boolean;
  LFixtureTestsCount: TDictionary<string, Integer>;
  LActiveFilterEdit: TEdit;
  LFailedNode, LPassedNode, LSkippedNode, LIdleNode: TTreeNode;
  LFullTestName: string;
  LInfo: TTestDetailInfo;
  LStatus: string;
  LTargetRoot: TTreeNode;
begin
  TestsTreeView.Items.BeginUpdate;
  try
    TestsTreeView.Items.Clear;
    LFilter := '';
    LActiveFilterEdit := ActiveFilterEdit;
    if Assigned(LActiveFilterEdit) then
      LFilter := Trim(LActiveFilterEdit.Text);

    if FGroupingMode = tgmStatus then
    begin
      LFailedNode := nil;
      LPassedNode := nil;
      LSkippedNode := nil;
      LIdleNode := nil;

      for LIdx := 0 to FTestLocations.Count - 1 do
      begin
        LTest := FTestLocations[LIdx];
        LClassMatches := (LFilter = '') or LTest.ClassName.ToLower.Contains(LFilter.ToLower);
        LMethodMatches := (LFilter = '') or LTest.MethodName.ToLower.Contains(LFilter.ToLower);

        if LClassMatches or LMethodMatches then
        begin
          LFullTestName := LTest.ClassName + '.' + LTest.MethodName;
          LStatus := 'Idle';
          if FTestDetails.TryGetValue(LFullTestName, LInfo) then
            LStatus := LInfo.Status;

          if SameText(LStatus, 'Failed') or SameText(LStatus, 'Error') then
          begin
            if not Assigned(LFailedNode) then
            begin
              LFailedNode := TestsTreeView.Items.AddChild(nil, 'Failed');
              LFailedNode.ImageIndex := 2;
              LFailedNode.SelectedIndex := 2;
            end;
            LTargetRoot := LFailedNode;
          end
          else if SameText(LStatus, 'Passed') or SameText(LStatus, 'Success') then
          begin
            if not Assigned(LPassedNode) then
            begin
              LPassedNode := TestsTreeView.Items.AddChild(nil, 'Passed');
              LPassedNode.ImageIndex := 1;
              LPassedNode.SelectedIndex := 1;
            end;
            LTargetRoot := LPassedNode;
          end
          else if SameText(LStatus, 'Skipped') then
          begin
            if not Assigned(LSkippedNode) then
            begin
              LSkippedNode := TestsTreeView.Items.AddChild(nil, 'Skipped');
              LSkippedNode.ImageIndex := 0;
              LSkippedNode.SelectedIndex := 0;
            end;
            LTargetRoot := LSkippedNode;
          end
          else
          begin
            if not Assigned(LIdleNode) then
            begin
              LIdleNode := TestsTreeView.Items.AddChild(nil, 'Idle');
              LIdleNode.ImageIndex := 0;
              LIdleNode.SelectedIndex := 0;
            end;
            LTargetRoot := LIdleNode;
          end;

          LMethodNode := TestsTreeView.Items.AddChild(LTargetRoot, LTest.ClassName + '.' + LTest.MethodName);
          LMethodNode.Data := Pointer(LIdx + 1);

          if SameText(LStatus, 'Failed') or SameText(LStatus, 'Error') then
          begin
            LMethodNode.ImageIndex := 2;
            LMethodNode.SelectedIndex := 2;
          end
          else if SameText(LStatus, 'Passed') or SameText(LStatus, 'Success') then
          begin
            LMethodNode.ImageIndex := 1;
            LMethodNode.SelectedIndex := 1;
          end;
        end;
      end;
    end
    else
    begin
      LFixtureTestsCount := TDictionary<string, Integer>.Create;
      try
        for LIdx := 0 to FTestLocations.Count - 1 do
        begin
          LTest := FTestLocations[LIdx];
          LClassMatches := (LFilter = '') or LTest.ClassName.ToLower.Contains(LFilter.ToLower);
          LMethodMatches := (LFilter = '') or LTest.MethodName.ToLower.Contains(LFilter.ToLower);

          if LClassMatches or LMethodMatches then
          begin
            if LFixtureTestsCount.ContainsKey(LTest.ClassName) then
              LFixtureTestsCount[LTest.ClassName] := LFixtureTestsCount[LTest.ClassName] + 1
            else
              LFixtureTestsCount.Add(LTest.ClassName, 1);
          end;
        end;

        for LIdx := 0 to FTestLocations.Count - 1 do
        begin
          LTest := FTestLocations[LIdx];
          LClassMatches := (LFilter = '') or LTest.ClassName.ToLower.Contains(LFilter.ToLower);
          LMethodMatches := (LFilter = '') or LTest.MethodName.ToLower.Contains(LFilter.ToLower);

          if LClassMatches or LMethodMatches then
          begin
            LFixtureNode := FindNodeByPath(LTest.ClassName);
            if not Assigned(LFixtureNode) then
            begin
              LFixtureNode := TestsTreeView.Items.AddChild(nil, LTest.ClassName);
              LFixtureNode.ImageIndex := 3;
              LFixtureNode.SelectedIndex := 3;
            end;

            LMethodNode := TestsTreeView.Items.AddChild(LFixtureNode, LTest.MethodName);
            LMethodNode.Data := Pointer(LIdx + 1);

            LFullTestName := LTest.ClassName + '.' + LTest.MethodName;
            LStatus := 'Idle';
            if FTestDetails.TryGetValue(LFullTestName, LInfo) then
              LStatus := LInfo.Status;

            if SameText(LStatus, 'Failed') or SameText(LStatus, 'Error') then
            begin
              LMethodNode.ImageIndex := 2;
              LMethodNode.SelectedIndex := 2;
            end
            else if SameText(LStatus, 'Passed') or SameText(LStatus, 'Success') then
            begin
              LMethodNode.ImageIndex := 1;
              LMethodNode.SelectedIndex := 1;
            end
            else if SameText(LStatus, 'Skipped') then
            begin
              LMethodNode.ImageIndex := 0;
              LMethodNode.SelectedIndex := 0;
            end
            else
            begin
              LMethodNode.ImageIndex := 0;
              LMethodNode.SelectedIndex := 0;
            end;
          end;
        end;
      finally
        LFixtureTestsCount.Free;
      end;
    end;

    TestsTreeView.FullExpand;
  finally
    TestsTreeView.Items.EndUpdate;
  end;
end;

procedure TFormDextTestRunner.TestsTreeViewAdvancedCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage; var PaintImages, DefaultDraw: Boolean);
var
  LBtnRect: TRect;
  LRect: TRect;
  LTextX, LTextY: Integer;
  LClassName: string;
  LCountText: string;
  LFailedCount: Integer;
  LPassedCount: Integer;
  J: Integer;
  LChildFull: string;
  LChildInfo: TTestDetailInfo;
  LFullTestName: string;
  LInfo: TTestDetailInfo;
  LDurText: string;
  LErrText: string;
begin
  DefaultDraw := True;

  if (Stage = cdPrePaint) and (Node <> nil) then
  begin
    if not (cdsSelected in State) then
    begin
      Sender.Canvas.Brush.Color := TTreeView(Sender).Color;
      Sender.Canvas.Font.Color := TTreeView(Sender).Font.Color;
    end;

    if Node.Parent = nil then
      Sender.Canvas.Font.Style := [fsBold]
    else
      Sender.Canvas.Font.Style := [];
  end;

  if (Stage = cdPostPaint) and (Node <> nil) then
  begin
    Sender.Canvas.Brush.Style := bsClear;
    LRect := Node.DisplayRect(True);
    LTextX := LRect.Right + 6;
    LTextY := LRect.Top + (LRect.Height - Sender.Canvas.TextHeight('W')) div 2;

    if Node.Parent = nil then
    begin
      LClassName := Node.Text;

      // Calculate total duration and status counts for the group
      LFailedCount := 0;
      LPassedCount := 0;
      var LTotalDuration: Double := 0;
      var LHasDuration: Boolean := False;
      for J := 0 to Node.Count - 1 do
      begin
        LChildFull := LClassName + '.' + Node.Item[J].Text;
        if FTestDetails.TryGetValue(LChildFull, LChildInfo) then
        begin
          if SameText(LChildInfo.Status, 'Failed') or SameText(LChildInfo.Status, 'Error') then
            Inc(LFailedCount)
          else if SameText(LChildInfo.Status, 'Passed') then
            Inc(LPassedCount);
          if LChildInfo.DurationMs > 0 then
          begin
            LTotalDuration := LTotalDuration + LChildInfo.DurationMs;
            LHasDuration := True;
          end;
        end;
      end;

      // Draw (N Testes) or (N Testes em T ms)
      if cdsSelected in State then
        Sender.Canvas.Font.Color := clHighlightText
      else
        Sender.Canvas.Font.Color := clGrayText;
      Sender.Canvas.Font.Style := [];

      if LHasDuration then
        LCountText := ' (' + Node.Count.ToString + ' Tests in ' + Format('%.4f ms', [LTotalDuration]) + ')'
      else
        LCountText := ' (' + Node.Count.ToString + ' Tests)';
      Sender.Canvas.TextOut(LTextX, LTextY, LCountText);
      LTextX := LTextX + Sender.Canvas.TextWidth(LCountText) + 6;

      if LFailedCount > 0 then
      begin
        if cdsSelected in State then
          Sender.Canvas.Font.Color := clHighlightText
        else
          Sender.Canvas.Font.Color := TColor($4444EF); // Red BGR
        Sender.Canvas.TextOut(LTextX, LTextY, 'Failed: ' + LFailedCount.ToString + ' tests failed');
      end
      else if (LPassedCount > 0) and (LPassedCount = Node.Count) then
      begin
        if cdsSelected in State then
          Sender.Canvas.Font.Color := clHighlightText
        else
          Sender.Canvas.Font.Color := TColor($5EC522); // Green BGR
        Sender.Canvas.TextOut(LTextX, LTextY, 'Success');
      end;
    end
    else
    begin
      LFullTestName := GetNodeFullTestName(Node);
      if FTestDetails.TryGetValue(LFullTestName, LInfo) then
      begin
        if LInfo.DurationMs < 1.0 then
          LDurText := Format('[%.3f ms]', [LInfo.DurationMs])
        else
          LDurText := Format('[%.2f ms]', [LInfo.DurationMs]);

        if cdsSelected in State then
          Sender.Canvas.Font.Color := clHighlightText
        else
          Sender.Canvas.Font.Color := clGrayText;
        Sender.Canvas.Font.Style := [];
        Sender.Canvas.TextOut(LTextX, LTextY, LDurText);
        LTextX := LTextX + Sender.Canvas.TextWidth(LDurText) + 6;

        if SameText(LInfo.Status, 'Passed') then
        begin
          if cdsSelected in State then
            Sender.Canvas.Font.Color := clHighlightText
          else
            Sender.Canvas.Font.Color := TColor($5EC522); // Green BGR
          Sender.Canvas.TextOut(LTextX, LTextY, 'Success');
        end
        else if SameText(LInfo.Status, 'Failed') or SameText(LInfo.Status, 'Error') then
        begin
          if cdsSelected in State then
            Sender.Canvas.Font.Color := clHighlightText
          else
            Sender.Canvas.Font.Color := TColor($4444EF); // Red BGR
          LErrText := 'Failed';
          if LInfo.ErrorMessage <> '' then
            LErrText := 'Failed: ' + LInfo.ErrorMessage.Replace(#13, '').Replace(#10, ' ');
          if Length(LErrText) > 60 then
            LErrText := Copy(LErrText, 1, 57) + '...';
          Sender.Canvas.TextOut(LTextX, LTextY, LErrText);
        end;
      end;

      if Node = FHoverNode then
      begin
        LBtnRect := GetRunButtonRect(Node);
        Sender.Canvas.Brush.Color := TColor($E7FCDC); // Light Green BGR
        Sender.Canvas.Pen.Color := TColor($5EC522); // Green BGR
        Sender.Canvas.RoundRect(LBtnRect.Left, LBtnRect.Top, LBtnRect.Right, LBtnRect.Bottom, 4, 4);
        Sender.Canvas.Font.Color := TColor($3D8015); // Dark Green BGR
        Sender.Canvas.Font.Size := 7;
        Sender.Canvas.Font.Style := [fsBold];
        DrawText(Sender.Canvas.Handle, #$25B6, -1, LBtnRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
      end;
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

  var LProjInfo := TDextProjectInfo(ProjectsComboBox.Items.Objects[ProjectsComboBox.ItemIndex]);
  if not Assigned(LProjInfo) then Exit;
  LProj := GetProjectByFileName(LProjInfo.FileName);
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
  LogMsg('Compiling project (Debug): ' + ExtractFileName(FActiveProjectFile));

  // Save all modified IDE files before compiling.
  var LSaveServices: IOTAModuleServices;
  if Supports(BorlandIDEServices, IOTAModuleServices, LSaveServices) then
  begin
    LogMsg('Saving all modified files...');
    LSaveServices.SaveAll;
  end;

  LIsPackage := False;
  LOutput := '';
  GetProjectTargetInfo(FActiveProjectFile, LIsPackage, LOutput);
  LExeFile := ResolveExePath(FActiveProjectFile, LOutput);

  if not CompileProjectDirect(FActiveProjectFile) then
  begin
    LogMsg('Direct DCC compile failed or bypassed. Falling back to IDE make...');
    LProj.ProjectBuilder.BuildProject(cmOTAMake, False, True);
  end;

  if not FileExists(LExeFile) then
  begin
    LogMsg('Error: Executable not found at ' + LExeFile);
    Exit;
  end;

  LParams := Format('--port %d -no-wait', [FServer.Port]);
  FServer.SelectedTestsJSON := '["' + GetNodeFullTestName(LNode) + '"]';

  LogMsg('Starting debugger with parameters: ' + LParams);
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
    LogMsg('Warning: Could not trigger debugger automatically.');
    LogMsg('Please press F9 (Run) manually in the IDE to start debugging.');
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
      var LProjInfo := TDextProjectInfo(ProjectsComboBox.Items.Objects[I]);
      if Assigned(LProjInfo) and (LProjInfo.FileName = FActiveProjectFile) then
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

  FSessions.Add(LSession);

  SessionsPageControl.ActivePage := LSession.TabSheet;
  SetActiveSession(LSession);

  RefreshProjects;
  UpdateTabVisibility;
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
  UpdateTabVisibility;
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
  if LTabIndex >= 0 then
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
    LogMsg('Error: DPR/DPK file not found: ' + LDprFile);
    Exit;
  end;

  LDccExe := ExtractFilePath(ParamStr(0)) + 'dcc32.exe';
  if not FileExists(LDccExe) then
  begin
    LogMsg('Error: Compiler not found: ' + LDccExe);
    Exit;
  end;

  try
    LContent := TFile.ReadAllText(AProjFile);
  except
    on E: Exception do
    begin
      LogMsg('Error reading project file: ' + E.Message);
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

  LogMsg('DCC Command: ' + LCmdLine);

  if ExecuteAndCapture(LCmdLine, LWorkDir, LOutput) then
  begin
    LogMsg(LOutput);
    LogMsg('Direct compilation successful.');
    Result := True;
  end
  else
  begin
    LogMsg(LOutput);
    LogMsg('Direct compilation failed.');
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
    LogMsg('Loading code coverage from: ' + LCovPath);
    TThread.Queue(nil, TThreadProcedure(procedure
      begin
        TCoverageManager.GetInstance.LoadCoverageFromXML(LCovPath);
      end));
  end
  else
  begin
    LogMsg('No code coverage report found.');
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
begin
  if not SameText(ExtractFileExt(AFileName), '.pas') then Exit;
  if not Assigned(FPendingSaveFiles) then Exit;

  if FPendingSaveFiles.IndexOf(AFileName) < 0 then
    FPendingSaveFiles.Add(AFileName);

  if Assigned(FSaveTimer) then
  begin
    FSaveTimer.Enabled := False;
    FSaveTimer.Enabled := True;
  end;
end;

procedure TFormDextTestRunner.SaveTimerTimer(Sender: TObject);
var
  LTests: TList<TTestLocation>;
  LTest: TTestLocation;
  LIdx: Integer;
  LNode: TTreeNode;
  LFixtureNode: TTreeNode;
  LMethodNode: TTreeNode;
  LFile: string;
  I: Integer;
begin
  if not Assigned(FSaveTimer) then Exit;
  FSaveTimer.Enabled := False;

  if not Assigned(FPendingSaveFiles) or (FPendingSaveFiles.Count = 0) then Exit;

  TestsTreeView.Items.BeginUpdate;
  try
    for I := 0 to FPendingSaveFiles.Count - 1 do
    begin
      LFile := FPendingSaveFiles[I];
      LTests := nil;
      if TTestASTScanner.ScanFile(LFile, LTests) then
      begin
        try
          // Remove existing tests in this file from our list and TreeView
          for LIdx := FTestLocations.Count - 1 downto 0 do
          begin
            if SameText(FTestLocations[LIdx].FileName, LFile) then
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
            LMethodNode.Data := Pointer(FTestLocations.Count);
            LMethodNode.ImageIndex := 0;
            LMethodNode.SelectedIndex := 0;
          end;
        finally
          LTests.Free;
        end;
      end;
    end;

    if FPendingSaveFiles.Count > 0 then
      TestsTreeView.FullExpand;
  finally
    TestsTreeView.Items.EndUpdate;
    FPendingSaveFiles.Clear;
  end;

  // Reset/Debounce the Idle timer upon saving a file
  if FChkRunOnIdle.Checked and Assigned(FIdleTimer) then
  begin
    FIdleTimer.Enabled := False;
    FIdleTimer.Enabled := True;
  end;

  if FChkRunOnSave.Checked and not FRunningTests and not FWaitingForCompile and (FRunningProcessHandle = 0) then
  begin
    RunActiveProjectTests('', False);
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

procedure TFormDextTestRunner.ActionsButtonClick(Sender: TObject);
var
  ClickPoint: TPoint;
begin
  ClickPoint := ActionsButton.ClientToScreen(Point(0, ActionsButton.Height));
  ActionsPopupMenu.Popup(ClickPoint.X, ClickPoint.Y);
end;

procedure TFormDextTestRunner.UpdateTabVisibility;
begin
  SessionsPageControl.Pages[0].TabVisible := SessionsPageControl.PageCount > 1;
  if not SessionsPageControl.Pages[0].TabVisible then
    SessionsPageControl.ActivePageIndex := 0;
end;

procedure TFormDextTestRunner.AddSessionButtonClick(Sender: TObject);
begin
  CreateNewSession('Session ' + (FSessions.Count + 1).ToString);
end;

procedure TFormDextTestRunner.ResetSummaryLabels;
begin
  SummaryTotalLabel.Caption := 'Total: 0';
  SummarySelectedLabel.Caption := 'Selected: 0';
  SummarySuccessLabel.Caption := 'Passed: 0';
  SummaryFailedLabel.Caption := 'Failed: 0';
  SummarySkippedLabel.Caption := 'Skipped: 0';
  SummaryTimeLabel.Caption := 'Tests: 0.00 s';
  SummaryTotalTimeLabel.Caption := 'Total: 0.00 s';
  FTestExecutionDurationMs := 0;
end;

initialization
  RegisterDockableForm;

finalization
  UnregisterDockableForm;

end.













