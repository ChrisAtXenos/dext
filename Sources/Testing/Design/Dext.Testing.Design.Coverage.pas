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
begin
  for var LPair in FFileCoverage do
    LPair.Value.Free;
  FFileCoverage.Clear;

  for var LPair in FLineCoveringTests do
  begin
    for var LInnerPair in LPair.Value do
      LInnerPair.Value.Free;
    LPair.Value.Free;
  end;
  FLineCoveringTests.Clear;
end;

procedure TCoverageManager.LoadCoverageFromXML(const AXmlPath: string);
var
  LContent: string;
  LPos, LEndPos: Integer;
  LFilePos, LFileEndPos: Integer;
  LFileBlock, LFilePath: string;
  LState: TCoverageLineState;
  LLineNum: Integer;
  LIsCovered: Boolean;
  LFileLines: TDictionary<Integer, TCoverageLineState>;
begin
  ClearCoverage;
  if not FileExists(AXmlPath) then Exit;

  try
    LContent := TFile.ReadAllText(AXmlPath, TEncoding.UTF8);
    
    LPos := 1;
    while True do
    begin
      LFilePos := LContent.IndexOf('<file path="', LPos - 1);
      if LFilePos < 0 then Break;
      
      Inc(LFilePos, 12);
      LFileEndPos := LContent.IndexOf('"', LFilePos);
      if LFileEndPos < 0 then Break;
      
      LFilePath := LContent.Substring(LFilePos, LFileEndPos - LFilePos);
      LFilePath := TPath.GetFullPath(LFilePath);
      
      LFileLines := TDictionary<Integer, TCoverageLineState>.Create;
      FFileCoverage.Add(LFilePath, LFileLines);
      
      LEndPos := LContent.IndexOf('</file>', LFileEndPos);
      if LEndPos < 0 then LEndPos := Length(LContent);
      
      LFileBlock := LContent.Substring(LFileEndPos, LEndPos - LFileEndPos);
      
      var LLinePos := 0;
      while True do
      begin
        LLinePos := LFileBlock.IndexOf('<lineToCover', LLinePos);
        if LLinePos < 0 then Break;
        
        var LLineEnd := LFileBlock.IndexOf('/>', LLinePos);
        if LLineEnd < 0 then Break;
        
        var LTag := LFileBlock.Substring(LLinePos, LLineEnd - LLinePos);
        
        var LNumStart := LTag.IndexOf('lineNumber="');
        if LNumStart >= 0 then
        begin
          Inc(LNumStart, 12);
          var LNumEnd := LTag.IndexOf('"', LNumStart);
          LLineNum := StrToIntDef(LTag.Substring(LNumStart, LNumEnd - LNumStart), 0);
          
          LState := clsNone;
          var LCovStart := LTag.IndexOf('covered="');
          if LCovStart >= 0 then
          begin
            Inc(LCovStart, 9);
            var LCovEnd := LTag.IndexOf('"', LCovStart);
            LIsCovered := SameText(LTag.Substring(LCovStart, LCovEnd - LCovStart), 'true');
            if LIsCovered then
              LState := clsCovered
            else
              LState := clsUncovered;
          end;
          
          var LBranchStart := LTag.IndexOf('branchesToCover="');
          if LBranchStart >= 0 then
          begin
            Inc(LBranchStart, 17);
            var LBranchEnd := LTag.IndexOf('"', LBranchStart);
            var LBranchesToCover := StrToIntDef(LTag.Substring(LBranchStart, LBranchEnd - LBranchStart), 0);
            
            var LBranchCovStart := LTag.IndexOf('branchesCovered="');
            if LBranchCovStart >= 0 then
            begin
              Inc(LBranchCovStart, 17);
              var LBranchCovEnd := LTag.IndexOf('"', LBranchCovStart);
              var LBranchesCovered := StrToIntDef(LTag.Substring(LBranchCovStart, LBranchCovEnd - LBranchCovStart), 0);
              
              if (LBranchesToCover > 0) and (LBranchesCovered < LBranchesToCover) and (LBranchesCovered > 0) then
                LState := clsPartiallyCovered;
            end;
          end;
          
          if LLineNum > 0 then
            LFileLines.AddOrSetValue(LLineNum, LState);
            
          // Parse covering tests attribute
          var LTestsStart := LTag.IndexOf('tests="');
          if (LTestsStart >= 0) and (LLineNum > 0) then
          begin
            Inc(LTestsStart, 7);
            var LTestsEnd := LTag.IndexOf('"', LTestsStart);
            var LTestsStr := LTag.Substring(LTestsStart, LTestsEnd - LTestsStart).Trim;
            if LTestsStr <> '' then
            begin
              var LTestsList := TList<string>.Create;
              var LSplitTests := LTestsStr.Split([',']);
              for var LTestName in LSplitTests do
                LTestsList.Add(LTestName.Trim);
              
              var LLineDict: TDictionary<Integer, TList<string>> := nil;
              if not FLineCoveringTests.TryGetValue(LFilePath, LLineDict) then
              begin
                LLineDict := TDictionary<Integer, TList<string>>.Create;
                FLineCoveringTests.Add(LFilePath, LLineDict);
              end;
              LLineDict.AddOrSetValue(LLineNum, LTestsList);
            end;
          end;
        end;
        
        Inc(LLinePos);
      end;
      
      LPos := LEndPos + 7;
    end;
  except
    // ignore parsing errors
  end;
  
  // Refresh active views to force paint
  RefreshActiveViews;
end;

function TCoverageManager.GetLineState(const AFileName: string; ALineNumber: Integer): TCoverageLineState;
var
  LDict: TDictionary<Integer, TCoverageLineState>;
begin
  Result := clsNone;
  if FFileCoverage.TryGetValue(AFileName, LDict) then
  begin
    LDict.TryGetValue(ALineNumber, Result);
  end;
end;

function TCoverageManager.GetCoveringTests(const AFileName: string; ALineNumber: Integer): TArray<string>;
var
  LDict: TDictionary<Integer, TList<string>>;
  LList: TList<string>;
begin
  Result := [];
  if FLineCoveringTests.TryGetValue(AFileName, LDict) then
  begin
    if LDict.TryGetValue(ALineNumber, LList) then
      Result := LList.ToArray;
  end;
end;

function TCoverageManager.GetTestsCoveringFile(const AFileName: string): TList<string>;
var
  LDict: TDictionary<Integer, TList<string>>;
  LTest: string;
begin
  Result := TList<string>.Create;
  if FLineCoveringTests.TryGetValue(AFileName, LDict) then
  begin
    for var LPair in LDict do
    begin
      for LTest in LPair.Value do
      begin
        if not Result.Contains(LTest) then
          Result.Add(LTest);
      end;
    end;
  end;
end;

procedure TCoverageManager.RegisterView(const AView: IOTAEditView);
var
  LIndex: Integer;
  LNotifier: INTAEditViewNotifier;
begin
  if not FNotifiers.ContainsKey(AView) then
  begin
    LNotifier := TEditorViewNotifier.Create(AView);
    LIndex := AView.AddNotifier(LNotifier);
    FNotifiers.Add(AView, LIndex);
  end;
end;

procedure TCoverageManager.UnregisterView(const AView: IOTAEditView);
var
  LIndex: Integer;
begin
  if FNotifiers.TryGetValue(AView, LIndex) then
  begin
    try
      AView.RemoveNotifier(LIndex);
    except
      // ignore potential OTA teardown issues
    end;
    FNotifiers.Remove(AView);
  end;
end;

procedure TCoverageManager.RefreshActiveViews;
var
  LModuleServices: IOTAModuleServices;
  LModule: IOTAModule;
  LSourceEditor: IOTASourceEditor;
  LView: IOTAEditView;
  I, J, K: Integer;
begin
  if Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) then
  begin
    for I := 0 to LModuleServices.ModuleCount - 1 do
    begin
      LModule := LModuleServices.Modules[I];
      if Assigned(LModule) then
      begin
        for J := 0 to LModule.ModuleFileCount - 1 do
        begin
          if Supports(LModule.ModuleFileEditors[J], IOTASourceEditor, LSourceEditor) then
          begin
            for K := 0 to LSourceEditor.EditViewCount - 1 do
            begin
              LView := LSourceEditor.EditViews[K];
              RegisterView(LView);
              LView.Paint;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TCoverageManager.ShowCoveringTestsPopup(const AView: IOTAEditView; const ATests: TArray<string>);
var
  LPopupMenu: TPopupMenu;
  LItem: TMenuItem;
  LScreenPos: TPoint;
begin
  if Length(ATests) = 0 then
  begin
    MessageBox(0, 'No covering tests found for this line.', 'Dext Coverage', MB_OK or MB_ICONINFORMATION);
    Exit;
  end;

  LPopupMenu := TPopupMenu.Create(nil);
  try
    for var LTest in ATests do
    begin
      var LHelper := TPopupMenuHelper.CreateHelper(LPopupMenu, LTest);
      LItem := TMenuItem.Create(LPopupMenu);
      LItem.Caption := LTest;
      LItem.OnClick := LHelper.OnClick;
      LPopupMenu.Items.Add(LItem);
    end;
    
    LScreenPos := Mouse.CursorPos;
    LPopupMenu.Popup(LScreenPos.X, LScreenPos.Y);
  finally
    TThread.ForceQueue(nil, TThreadProcedure(procedure
      begin
        LPopupMenu.Free;
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
var
  LFileName: string;
  LImpactedTests: TList<string>;
begin
  LFileName := FView.Buffer.FileName;
  LImpactedTests := TCoverageManager.GetInstance.GetTestsCoveringFile(LFileName);
  try
    if (LImpactedTests.Count > 0) and Assigned(FormDextTestRunner) then
    begin
      var LTestsArr := LImpactedTests.ToArray;
      TThread.Queue(nil, TThreadProcedure(procedure
        begin
          if Assigned(FormDextTestRunner) then
          begin
            FormDextTestRunner.DetailsMemo.Lines.Add('File changed: ' + ExtractFileName(LFileName));
            FormDextTestRunner.DetailsMemo.Lines.Add(Format('Impact Analysis: Running %d impacted tests...', [Length(LTestsArr)]));
            FormDextTestRunner.RunImpactedTests(LTestsArr);
          end;
        end));
    end;
  finally
    LImpactedTests.Free;
  end;
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
  LFileName: string;
  LState: TCoverageLineState;
  LGutterRect: TRect;
begin
  LFileName := View.Buffer.FileName;
  LState := TCoverageManager.GetInstance.GetLineState(LFileName, LineNumber);
  
  if LState <> clsNone then
  begin
    LGutterRect.Left := LineRect.Left + 1;
    LGutterRect.Top := LineRect.Top;
    LGutterRect.Right := LGutterRect.Left + 3;
    LGutterRect.Bottom := LineRect.Bottom;
    
    Canvas.Pen.Style := psSolid;
    if LState = clsCovered then
    begin
      Canvas.Brush.Color := TColor($22C55E); // Green
      Canvas.Pen.Color := TColor($22C55E);
    end
    else if LState = clsPartiallyCovered then
    begin
      Canvas.Brush.Color := TColor($EAB308); // Yellow
      Canvas.Pen.Color := TColor($EAB308);
    end
    else
    begin
      Canvas.Brush.Color := TColor($EF4444); // Red
      Canvas.Pen.Color := TColor($EF4444);
    end;
    
    Canvas.FillRect(LGutterRect);
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
  LEditView: IOTAEditView;
  LFileName: string;
  LLine: Integer;
  LTests: TArray<string>;
begin
  BindingResult := krHandled;
  if Context.EditBuffer = nil then Exit;
  
  LEditView := Context.EditBuffer.EditViews[0];
  if LEditView = nil then Exit;
  
  LFileName := LEditView.Buffer.FileName;
  LLine := LEditView.CursorPos.Line;
  
  LTests := TCoverageManager.GetInstance.GetCoveringTests(LFileName, LLine);
  TCoverageManager.GetInstance.ShowCoveringTestsPopup(LEditView, LTests);
end;

initialization
  TCoverageManager.FInstance := nil;

finalization
  if TCoverageManager.FInstance <> nil then
    TCoverageManager.FInstance.Free;

end.
