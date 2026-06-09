unit Dext.Testing.Design.Coverage;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, ToolsAPI, System.IOUtils, Vcl.Menus;

type
  TCoverageLineState = (clsNone, clsCovered, clsUncovered, clsPartiallyCovered);

  TCoverageManager = class
  private
    class var FInstance: TCoverageManager;
    FFileCoverage: TDictionary<string, TDictionary<Integer, TCoverageLineState>>;
    FLineCoveringTests: TDictionary<string, TDictionary<Integer, TList<string>>>;
    FNotifiers: TDictionary<IOTAEditView, Integer>;
  var
    FTest: Integer;
    procedure ClearCoverage;
  public
    constructor Create;
    destructor Destroy; override;
    class function GetInstance: TCoverageManager;
    procedure LoadCoverageFromXML(const AXmlPath: string);
    function GetLineState(const AFileName: string; ALineNumber: Integer): TCoverageLineState;
    function GetCoveringTests(const AFileName: string; ALineNumber: Integer): TArray<string>;
    function GetTestsCoveringFile(const AFileName: string): TList<string>;
    procedure RegisterView(const AView: IOTAEditView);
    procedure UnregisterView(const AView: IOTAEditView);
    procedure RefreshActiveViews;
    procedure ShowCoveringTestsPopup(const AView: IOTAEditView; const ATests: TArray<string>);
    property Test: Integer read FTest write FTest;
  end;

  TEditorViewNotifier = class(TInterfacedObject, IOTANotifier, INTAEditViewNotifier)
  private
    FView: IOTAEditView;
  public
    constructor Create(const AView: IOTAEditView);
    // IOTANotifier
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;
    // INTAEditViewNotifier
    procedure EditorDestroyed(const View: IOTAEditView);
    procedure FrameFormCreated(const FrameForm: TCustomFrame);
    procedure PaintLine(const View: IOTAEditView; LineNumber: Integer;
      const LineText: PAnsiChar; const TextWidth: Word;
      const LineAttributes: TOTAAttributeArray; const Canvas: TCanvas;
      const TextRect: TRect; const LineRect: TRect; const CellSize: TSize);
    procedure EditorIdle(const View: IOTAEditView);
    procedure BeginPaint(const View: IOTAEditView; var FullRepaint: Boolean);
    procedure EndPaint(const View: IOTAEditView);
  end;

  TDextKeyboardBinding = class(TInterfacedObject, IOTANotifier, IOTAKeyboardBinding)
  public
    // IOTANotifier
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;
    // IOTAKeyboardBinding
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
    procedure ShowCoveringTestsProc(const Context: IOTAKeyContext; KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
  end;

implementation

uses
  Dext.Testing.Design.DockableForm;

type
  TPopupMenuHelper = class(TComponent)
  private
    FTestName: string;
  public
    constructor CreateHelper(AOwner: TComponent; const ATestName: string);
    procedure OnClick(Sender: TObject);
  end;

{ TPopupMenuHelper }

constructor TPopupMenuHelper.CreateHelper(AOwner: TComponent; const ATestName: string);
begin
  inherited Create(AOwner);
  FTestName := ATestName;
end;

procedure TPopupMenuHelper.OnClick(Sender: TObject);
begin
  if Assigned(FormDextTestRunner) then
  begin
    FormDextTestRunner.Show;
    FormDextTestRunner.RunActiveProjectTests(FTestName);
  end;
end;

{ TCoverageManager }

constructor TCoverageManager.Create;
begin
  inherited Create;
  FFileCoverage := TDictionary<string, TDictionary<Integer, TCoverageLineState>>.Create;
  FLineCoveringTests := TDictionary<string, TDictionary<Integer, TList<string>>>.Create;
  FNotifiers := TDictionary<IOTAEditView, Integer>.Create;
end;

destructor TCoverageManager.Destroy;
begin
  ClearCoverage;
  FFileCoverage.Free;
  FLineCoveringTests.Free;
  FNotifiers.Free;
  inherited;
end;

class function TCoverageManager.GetInstance: TCoverageManager;
begin
  if FInstance = nil then
    FInstance := TCoverageManager.Create;
  Result := FInstance;
end;

procedure TCoverageManager.ClearCoverage;
var
  pair: TPair<string, TDictionary<Integer, TCoverageLineState>>;
  pairCovering: TPair<string, TDictionary<Integer, TList<string>>>;
  innerPair: TPair<Integer, TList<string>>;
begin
  for pair in FFileCoverage do
    pair.Value.Free;
  FFileCoverage.Clear;

  for pairCovering in FLineCoveringTests do
  begin
    for innerPair in pairCovering.Value do
      innerPair.Value.Free;
    pairCovering.Value.Free;
  end;
  FLineCoveringTests.Clear;
end;

procedure TCoverageManager.LoadCoverageFromXML(const AXmlPath: string);
var
  Content: string;
  PosIdx: Integer;
  EndPos: Integer;
  FilePos: Integer;
  FileEndPos: Integer;
  FileBlock: string;
  FilePath: string;
  State: TCoverageLineState;
  LineNum: Integer;
  IsCovered: Boolean;
  FileLines: TDictionary<Integer, TCoverageLineState>;
  LinePos: Integer;
  LineEnd: Integer;
  Tag: string;
  NumStart: Integer;
  NumEnd: Integer;
  CovStart: Integer;
  CovEnd: Integer;
  BranchStart: Integer;
  BranchEnd: Integer;
  BranchesToCover: Integer;
  BranchCovStart: Integer;
  BranchCovEnd: Integer;
  BranchesCovered: Integer;
  TestsStart: Integer;
  TestsEnd: Integer;
  TestsStr: string;
  TestsList: TList<string>;
  SplitTests: TArray<string>;
  TestName: string;
  LineDict: TDictionary<Integer, TList<string>>;
begin
  ClearCoverage;
  if not FileExists(AXmlPath) then Exit;

  try
    Content := TFile.ReadAllText(AXmlPath, TEncoding.UTF8);
    
    PosIdx := 1;
    while True do
    begin
      FilePos := Content.IndexOf('<file path="', PosIdx - 1);
      if FilePos < 0 then Break;
      
      Inc(FilePos, 12);
      FileEndPos := Content.IndexOf('"', FilePos);
      if FileEndPos < 0 then Break;
      
      FilePath := Content.Substring(FilePos, FileEndPos - FilePos);
      FilePath := TPath.GetFullPath(FilePath);
      
      FileLines := TDictionary<Integer, TCoverageLineState>.Create;
      FFileCoverage.Add(FilePath, FileLines);
      
      EndPos := Content.IndexOf('</file>', FileEndPos);
      if EndPos < 0 then EndPos := Length(Content);
      
      FileBlock := Content.Substring(FileEndPos, EndPos - FileEndPos);
      
      LinePos := 0;
      while True do
      begin
        LinePos := FileBlock.IndexOf('<lineToCover', LinePos);
        if LinePos < 0 then Break;
        
        LineEnd := FileBlock.IndexOf('/>', LinePos);
        if LineEnd < 0 then Break;
        
        Tag := FileBlock.Substring(LinePos, LineEnd - LinePos);
        
        NumStart := Tag.IndexOf('lineNumber="');
        if NumStart >= 0 then
        begin
          Inc(NumStart, 12);
          NumEnd := Tag.IndexOf('"', NumStart);
          LineNum := StrToIntDef(Tag.Substring(NumStart, NumEnd - NumStart), 0);
          
          State := clsNone;
          CovStart := Tag.IndexOf('covered="');
          if CovStart >= 0 then
          begin
            Inc(CovStart, 9);
            CovEnd := Tag.IndexOf('"', CovStart);
            IsCovered := SameText(Tag.Substring(CovStart, CovEnd - CovStart), 'true');
            if IsCovered then
              State := clsCovered
            else
              State := clsUncovered;
          end;
          
          BranchStart := Tag.IndexOf('branchesToCover="');
          if BranchStart >= 0 then
          begin
            Inc(BranchStart, 17);
            BranchEnd := Tag.IndexOf('"', BranchStart);
            BranchesToCover := StrToIntDef(Tag.Substring(BranchStart, BranchEnd - BranchStart), 0);
            
            BranchCovStart := Tag.IndexOf('branchesCovered="');
            if BranchCovStart >= 0 then
            begin
              Inc(BranchCovStart, 17);
              BranchCovEnd := Tag.IndexOf('"', BranchCovStart);
              BranchesCovered := StrToIntDef(Tag.Substring(BranchCovStart, BranchCovEnd - BranchCovStart), 0);
              
              if (BranchesToCover > 0) and (BranchesCovered < BranchesToCover) and (BranchesCovered > 0) then
                State := clsPartiallyCovered;
            end;
          end;
          
          if LineNum > 0 then
            FileLines.AddOrSetValue(LineNum, State);
            
          // Parse covering tests attribute
          TestsStart := Tag.IndexOf('tests="');
          if (TestsStart >= 0) and (LineNum > 0) then
          begin
            Inc(TestsStart, 7);
            TestsEnd := Tag.IndexOf('"', TestsStart);
            TestsStr := Tag.Substring(TestsStart, TestsEnd - TestsStart).Trim;
            if TestsStr <> '' then
            begin
              TestsList := TList<string>.Create;
              SplitTests := TestsStr.Split([',']);
              for TestName in SplitTests do
                TestsList.Add(TestName.Trim);

              LineDict := nil;
              if not FLineCoveringTests.TryGetValue(FilePath, LineDict) then
              begin
                LineDict := TDictionary<Integer, TList<string>>.Create;
                FLineCoveringTests.Add(FilePath, LineDict);
              end;
              LineDict.AddOrSetValue(LineNum, TestsList);
            end;
          end;
        end;
        
        Inc(LinePos);
      end;
      
      PosIdx := EndPos + 7;
    end;
  except
    // ignore parsing errors
  end;
  
  // Refresh active views to force paint
  RefreshActiveViews;
end;

function TCoverageManager.GetLineState(const AFileName: string; ALineNumber: Integer): TCoverageLineState;
var
  Dict: TDictionary<Integer, TCoverageLineState>;
begin
  Result := clsNone;
  if FFileCoverage.TryGetValue(AFileName, Dict) then
  begin
    Dict.TryGetValue(ALineNumber, Result);
  end;
end;

function TCoverageManager.GetCoveringTests(const AFileName: string; ALineNumber: Integer): TArray<string>;
var
  Dict: TDictionary<Integer, TList<string>>;
  List: TList<string>;
begin
  Result := [];
  if FLineCoveringTests.TryGetValue(AFileName, Dict) then
  begin
    if Dict.TryGetValue(ALineNumber, List) then
      Result := List.ToArray;
  end;
end;

function TCoverageManager.GetTestsCoveringFile(const AFileName: string): TList<string>;
var
  Dict: TDictionary<Integer, TList<string>>;
  TestName: string;
  Pair: TPair<Integer, TList<string>>;
begin
  Result := TList<string>.Create;
  if FLineCoveringTests.TryGetValue(AFileName, Dict) then
  begin
    for Pair in Dict do
    begin
      for TestName in Pair.Value do
      begin
        if not Result.Contains(TestName) then
          Result.Add(TestName);
      end;
    end;
  end;
end;

procedure TCoverageManager.RegisterView(const AView: IOTAEditView);
begin
  // Gutter view notifier registration disabled to prevent crash
  // on TEditView.NotifyDestroyed when editor tabs are closed.
  // TODO: Re-enable with proper lifetime management.
end;

procedure TCoverageManager.UnregisterView(const AView: IOTAEditView);
begin
  // No-op: registration is disabled, nothing to unregister.
  FNotifiers.Remove(AView);
end;

procedure TCoverageManager.RefreshActiveViews;
begin
  // Gutter refresh disabled to prevent crash when attaching
  // notifiers to editor views that may be destroyed by the IDE.
  // Coverage data is still loaded and available for the Inspector.
end;

procedure TCoverageManager.ShowCoveringTestsPopup(const AView: IOTAEditView; const ATests: TArray<string>);
var
  PopupMenu: TPopupMenu;
  Item: TMenuItem;
  ScreenPos: TPoint;
  Test: string;
  PopupMenuHelper: TPopupMenuHelper;
begin
  if Length(ATests) = 0 then
  begin
    MessageBox(0, 'No covering tests found for this line.', 'Dext Coverage', MB_OK or MB_ICONINFORMATION);
    Exit;
  end;

  PopupMenu := TPopupMenu.Create(nil);
  try
    for Test in ATests do
    begin
      PopupMenuHelper := TPopupMenuHelper.CreateHelper(PopupMenu, Test);
      Item := TMenuItem.Create(PopupMenu);
      Item.Caption := Test;
      Item.OnClick := PopupMenuHelper.OnClick;
      PopupMenu.Items.Add(Item);
    end;
    
    ScreenPos := Mouse.CursorPos;
    PopupMenu.Popup(ScreenPos.X, ScreenPos.Y);
  finally
    TThread.ForceQueue(nil, TThreadProcedure(procedure
      begin
        PopupMenu.Free;
      end));
  end;
end;

{ TEditorViewNotifier }

constructor TEditorViewNotifier.Create(const AView: IOTAEditView);
begin
  inherited Create;
  FView := AView;
end;

procedure TEditorViewNotifier.AfterSave;
begin
  // Disabled: notifier is no longer attached to edit views.
  // File save handling is not active until gutter feature is re-enabled.
end;

procedure TEditorViewNotifier.BeforeSave; begin end;
procedure TEditorViewNotifier.Destroyed; begin end;
procedure TEditorViewNotifier.Modified; begin end;

procedure TEditorViewNotifier.EditorDestroyed(const View: IOTAEditView);
begin
  TCoverageManager.GetInstance.UnregisterView(View);
end;

procedure TEditorViewNotifier.FrameFormCreated(const FrameForm: TCustomFrame); begin end;

procedure TEditorViewNotifier.PaintLine(const View: IOTAEditView; LineNumber: Integer;
  const LineText: PAnsiChar; const TextWidth: Word;
  const LineAttributes: TOTAAttributeArray; const Canvas: TCanvas;
  const TextRect: TRect; const LineRect: TRect; const CellSize: TSize);
var
  FileName: string;
  State: TCoverageLineState;
  GutterRect: TRect;
begin
  FileName := View.Buffer.FileName;
  State := TCoverageManager.GetInstance.GetLineState(FileName, LineNumber);
  
  if State <> clsNone then
  begin
    GutterRect.Left := LineRect.Left + 1;
    GutterRect.Top := LineRect.Top;
    GutterRect.Right := GutterRect.Left + 3;
    GutterRect.Bottom := LineRect.Bottom;
    
    Canvas.Pen.Style := psSolid;
    if State = clsCovered then
    begin
      Canvas.Brush.Color := TColor($22C55E); // Green
      Canvas.Pen.Color := TColor($22C55E);
    end
    else if State = clsPartiallyCovered then
    begin
      Canvas.Brush.Color := TColor($EAB308); // Yellow
      Canvas.Pen.Color := TColor($EAB308);
    end
    else
    begin
      Canvas.Brush.Color := TColor($EF4444); // Red
      Canvas.Pen.Color := TColor($EF4444);
    end;
    
    Canvas.FillRect(GutterRect);
  end;
end;

procedure TEditorViewNotifier.EditorIdle(const View: IOTAEditView); begin end;

procedure TEditorViewNotifier.BeginPaint(const View: IOTAEditView; var FullRepaint: Boolean);
begin
end;

procedure TEditorViewNotifier.EndPaint(const View: IOTAEditView);
begin
end;

{ TDextKeyboardBinding }

procedure TDextKeyboardBinding.AfterSave; begin end;
procedure TDextKeyboardBinding.BeforeSave; begin end;
procedure TDextKeyboardBinding.Destroyed; begin end;
procedure TDextKeyboardBinding.Modified; begin end;

function TDextKeyboardBinding.GetBindingType: TBindingType;
begin
  Result := btPartial;
end;

function TDextKeyboardBinding.GetDisplayName: string;
begin
  Result := 'Dext Show Covering Tests Binding';
end;

function TDextKeyboardBinding.GetName: string;
begin
  Result := 'Dext.ShowCoveringTests.Binding';
end;

procedure TDextKeyboardBinding.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
  BindingServices.AddKeyBinding([ShortCut(Ord('C'), [ssCtrl, ssAlt])], ShowCoveringTestsProc, nil);
end;

procedure TDextKeyboardBinding.ShowCoveringTestsProc(const Context: IOTAKeyContext; KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
var
  EditView: IOTAEditView;
  FileName: string;
  Line: Integer;
  Tests: TArray<string>;
begin
  BindingResult := krHandled;
  if Context.EditBuffer = nil then Exit;
  
  EditView := Context.EditBuffer.EditViews[0];
  if EditView = nil then Exit;
  
  FileName := EditView.Buffer.FileName;
  Line := EditView.CursorPos.Line;
  
  Tests := TCoverageManager.GetInstance.GetCoveringTests(FileName, Line);
  TCoverageManager.GetInstance.ShowCoveringTestsPopup(EditView, Tests);
end;

initialization
  TCoverageManager.FInstance := nil;

finalization
  if TCoverageManager.FInstance <> nil then
    TCoverageManager.FInstance.Free;

end.
