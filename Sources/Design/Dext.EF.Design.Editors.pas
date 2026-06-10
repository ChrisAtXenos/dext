unit Dext.EF.Design.Editors;

interface

{$I ..\Dext.Inc}

uses
  Data.DB,
  DesignEditors,
  DesignIntf,
  System.Classes,
  System.IOUtils,
  System.RegularExpressions,
  System.SysUtils,
  ToolsAPI,
  Vcl.CheckLst,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls,
  VCLEditors,
  Dext.Collections,
  Dext.Collections.Base,
  Dext.Entity.DataSet,
  Dext.Entity.DataProvider,
  Dext.Entity.Core,
  Dext.Entity.Metadata,
  Dext.EF.Design.Metadata,
  Dext.EF.Design.Preview,
  Dext.EF.Design.EntitySelection,
  Dext.Entity.Scaffolding,
  Dext.EF.Design.Scaffolding.Helpers,
  Dext.EF.Design.Scaffolding.Preview,
  FireDAC.Comp.Client,
  FireDAC.Comp.DataSet;

type
{$IFDEF DEXT_USE_ENTITY_PREFIX}
  TDextEntityDataSet = class(TEntityDataSet)
  end;
  TDextEntityDataProvider = class(TEntityDataProvider)
  end;
{$ENDIF}

  /// <summary>Property editor for selecting a TEntityDataProvider in the Object Inspector.</summary>
  TEntityDataProviderComponentProperty = class(TComponentProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

  /// <summary>Property editor for dynamic selection of Entity classes from discovered metadata.</summary>
  TEntityClassNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
    procedure Edit; override;
  end;

  TEntityDataProviderEditor = class(TComponentEditor)
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

  /// <summary>Selection editor for TEntityDataSet, providing context menus for field generation and preview.</summary>
  TEntityDataSetSelectionEditor = class(TSelectionEditor)
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer; const List: IDesignerSelections); override;
  end;

  TScaffoldingConnectionSelectionEditor = class(TSelectionEditor)
  public
    procedure ExecuteVerb(Index: Integer; const List: IDesignerSelections); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

  TScaffoldingDataSetSelectionEditor = class(TSelectionEditor)
  public
    procedure ExecuteVerb(Index: Integer; const List: IDesignerSelections); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

function FindOwnerProject(ADesigner: IDesigner): IOTAProject;
procedure RegisterEditors;

implementation

uses
  System.UITypes,
  System.Generics.Collections,
  Vcl.Buttons;

function InputCombo(const ACaption, APrompt: string; const AItems: TStrings; var AValue: string): Boolean; forward;

function FindOwnerProject(ADesigner: IDesigner): IOTAProject;
var
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  ProjectGroup: IOTAProjectGroup;
  Project: IOTAProject;
  I, J, K: Integer;
  CurFile: string;
begin
  Result := nil;
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  if ModuleServices = nil then
    Exit;

  // Use the current module (the one being designed)
  Module := ModuleServices.CurrentModule;
  if Module = nil then
    Exit;

  // Search all project groups and projects for the one containing this module
  for I := 0 to ModuleServices.ModuleCount - 1 do
  begin
    if Supports(ModuleServices.Modules[I], IOTAProjectGroup, ProjectGroup) then
    begin
      for J := 0 to ProjectGroup.ProjectCount - 1 do
      begin
        Project := ProjectGroup.Projects[J];
        if Project = nil then Continue;
        
        for K := 0 to Project.GetModuleCount - 1 do
        begin
          CurFile := Project.GetModule(K).FileName;
          if (CurFile = '') or (Module.FileName = '') then Continue;

          if SameText(TPath.GetFullPath(CurFile), TPath.GetFullPath(Module.FileName)) then
          begin
            Result := Project;
            Exit;
          end;
        end;
      end;
    end;
  end;
end;

function TryGetActiveProject(out AProject: IOTAProject): Boolean;
var
  ModuleServices: IOTAModuleServices;
  ProjectGroup: IOTAProjectGroup;
  I: Integer;
begin
  AProject := nil;
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  for I := 0 to ModuleServices.ModuleCount - 1 do
  begin
    if Supports(ModuleServices.Modules[I], IOTAProjectGroup, ProjectGroup) then
    begin
      AProject := ProjectGroup.ActiveProject;
      Exit(AProject <> nil);
    end;
  end;
  Result := False;
end;

function ValidateProjectContext(ADesigner: IDesigner; out AProject: IOTAProject): Boolean;
var
  ActiveProject: IOTAProject;
begin
  Result := False;
  AProject := FindOwnerProject(ADesigner);
  
  if AProject = nil then
  begin
    MessageDlg('Dext: Could not identify the project this form belongs to.' + sLineBreak +
               'Ensure the form is saved and part of a project in the Project Manager.', 
               mtError, [mbOK], 0);
    Exit;
  end;

  if not TryGetActiveProject(ActiveProject) then
  begin
    MessageDlg('Dext: Could not identify the "Active Project" in the IDE.', mtError, [mbOK], 0);
    Exit;
  end;

  // Force Active Project match to ensure metadata stability
  if not SameText(AProject.FileName, ActiveProject.FileName) then
  begin
    MessageDlg(Format('Dext: Project Conflict Detected!' + sLineBreak + sLineBreak +
               'This form belongs to project: "%s"' + sLineBreak +
               'But the active project in the IDE is: "%s"' + sLineBreak + sLineBreak +
               'For safety, the refresh has been cancelled. Please activate the correct project in the Project Manager before trying again.',
               [ExtractFileName(AProject.FileName), ExtractFileName(ActiveProject.FileName)]),
               mtWarning, [mbOK], 0);
    Exit;
  end;

  Result := True;
end;

function PopulateProviderModelUnitsFromProject(AProvider: TEntityDataProvider; AProject: IOTAProject): Integer;
var
  ModuleInfo: IOTAModuleInfo;
  FileName: string;
  I: Integer;
begin
  Result := 0;
  if (AProvider = nil) or (AProject = nil) then
    Exit;

  AProvider.ModelUnits.BeginUpdate;
  try
    for I := 0 to AProject.GetModuleCount - 1 do
    begin
      ModuleInfo := AProject.GetModule(I);
      if (ModuleInfo = nil) or (ModuleInfo.FileName = '') then
        Continue;

      FileName := TPath.GetFullPath(ModuleInfo.FileName);
      if not SameText(ExtractFileExt(FileName), '.pas') then
        Continue;

      // Skip common Delphi units or the project file itself
      if SameText(ExtractFileExt(FileName), '.dpr') or 
         SameText(ExtractFileExt(FileName), '.dpk') then
        Continue;

      if not FileExists(FileName) then
        Continue;

      if AProvider.ModelUnits.IndexOf(FileName) >= 0 then
        Continue;

      AProvider.ModelUnits.Add(FileName);
      Inc(Result);
    end;
  finally
    AProvider.ModelUnits.EndUpdate;
  end;
end;

function PopulateProviderModelUnitsFromActiveProject(AProvider: TEntityDataProvider; ADesigner: IDesigner): Boolean;
var
  Project: IOTAProject;
  I: Integer;
  UnitsLog: string;
begin
  Result := False;
  if not ValidateProjectContext(ADesigner, Project) then
    Exit;

  // Clear units to ensure a fresh sync with the current project file
  AProvider.ModelUnits.Clear;
  PopulateProviderModelUnitsFromProject(AProvider, Project);
  AProvider.UpdateRefreshSummary;
  
  UnitsLog := '';
  for I := 0 to AProvider.ModelUnits.Count - 1 do
  begin
    if UnitsLog <> '' then UnitsLog := UnitsLog + ', ';
    UnitsLog := UnitsLog + ExtractFileName(AProvider.ModelUnits[I]);
  end;

  AProvider.LastRefreshSummary := AProvider.LastRefreshSummary + sLineBreak +
                                  'Units: ' + UnitsLog + sLineBreak +
                                  'Project: ' + ExtractFileName(Project.FileName);
  Result := True;
end;

procedure RefreshBoundDataSets(AProvider: TEntityDataProvider; ADesigner: IDesigner);
var
  I: Integer;
  OwnedComponent: TComponent;
begin
  if (AProvider = nil) or (AProvider.Owner = nil) then
    Exit;

  for I := 0 to AProvider.Owner.ComponentCount - 1 do
  begin
    OwnedComponent := AProvider.Owner.Components[I];
    if (OwnedComponent is TEntityDataSet) and
       (TEntityDataSet(OwnedComponent).DataProvider = AProvider) and
       (TEntityDataSet(OwnedComponent).EntityClassName <> '') then
    begin
      TEntityDataSet(OwnedComponent).GenerateFields;
      if ADesigner <> nil then
        ADesigner.Modified;
    end;
  end;
end;

function ReadEditorContent(const AEditor: IOTASourceEditor): string;
const
  BufferSize = 1024 * 32;
var
  Reader: IOTAEditReader;
  Buffer: AnsiString;
  Read: Integer;
  Position: Integer;
begin
  Result := '';
  if (AEditor = nil) then Exit;
  Reader := AEditor.CreateReader;
  Position := 0;
  repeat
    SetLength(Buffer, BufferSize);
    Read := Reader.GetText(Position, PAnsiChar(Buffer), BufferSize);
    if Read > 0 then
    begin
      SetLength(Buffer, Read);
      Result := Result + UTF8ToString(Buffer);
    end;
    Inc(Position, Read);
  until Read < BufferSize;
end;

function GetModuleContent(const AFileName: string): string;
var
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  Editor: IOTAEditor;
  SourceEditor: IOTASourceEditor;
  I: Integer;
begin
  Result := '';
  if not Supports(BorlandIDEServices, IOTAModuleServices, ModuleServices) then Exit;
  
  Module := ModuleServices.FindModule(AFileName);
  if Module = nil then Exit;
  
  for I := 0 to Module.GetModuleFileCount - 1 do
  begin
    Editor := Module.GetModuleFileEditor(I);
    if Supports(Editor, IOTASourceEditor, SourceEditor) then
    begin
      Result := ReadEditorContent(SourceEditor);
      if Result <> '' then Break;
    end;
  end;
end;

procedure DesignTimeRefreshUnit(AProvider: TEntityDataProvider; const AFileName: string);
var
  Parser: TEntityMetadataParser;
  ParsedList: IList<TEntityClassMetadata>;
  ParsedCollection: ICollection;
  MD: TEntityClassMetadata;
  Content: string;
begin
  if (AProvider = nil) or (AFileName = '') then
    Exit;

  Content := GetModuleContent(AFileName);

  Parser := TEntityMetadataParser.Create;
  try
    ParsedList := Parser.ParseUnit(AFileName, Content);
    try
      for MD in ParsedList do
      begin
        AProvider.AddOrSetMetadata(MD);
      end;

      if Supports(ParsedList, ICollection, ParsedCollection) then
        ParsedCollection.OwnsObjects := False;
    finally
      ParsedList := nil;
    end;
  finally
    Parser.Free;
  end;

  AProvider.UpdateRefreshSummary;
end;



function GetCurrentSourceEditor: IOTASourceEditor;
var
  Module: IOTAModule;
  ModuleServices: IOTAModuleServices;
  I: Integer;
begin
  Result := nil;
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  Module := ModuleServices.CurrentModule;
  if Module = nil then
    Exit;

  for I := 0 to Module.GetModuleFileCount - 1 do
    if Supports(Module.GetModuleFileEditor(I), IOTASourceEditor, Result) then
      Exit;
end;

procedure EnsureUnitInCurrentModuleUses(const AUnitName: string);
const
  RegexImplementation = '\bimplementation\b';
  RegexUsesSection = '\buses\b[\h\s\w[.,]*;';
var
  SourceEditor: IOTASourceEditor;
  Writer: IOTAEditWriter;
  Source: string;
  ImplementationMatch: TMatch;
  UsesMatches: TMatchCollection;
  UsesMatch: TMatch;
  HasUsesMatch: Boolean;
  InsertPosition: Integer;
  InsertText: string;
  Match: TMatch;
begin
  if AUnitName = '' then
    Exit;

  SourceEditor := GetCurrentSourceEditor;
  if SourceEditor = nil then
    Exit;

  Source := ReadEditorContent(SourceEditor);
  if TRegEx.IsMatch(Source, '\b' + AUnitName.Replace('.', '\.') + '\b', [roIgnoreCase, roMultiLine]) then
    Exit;

  ImplementationMatch := TRegEx.Match(Source, RegexImplementation, [roIgnoreCase, roMultiLine]);
  if not ImplementationMatch.Success then
    Exit;

  UsesMatches := TRegEx.Matches(Source, RegexUsesSection, [roIgnoreCase, roMultiLine]);
  HasUsesMatch := False;
  for Match in UsesMatches do
  begin
    if Match.Index > ImplementationMatch.Index then
    begin
      UsesMatch := Match;
      HasUsesMatch := True;
      Break;
    end;
  end;

  if HasUsesMatch then
  begin
    InsertPosition := UsesMatch.Index + UsesMatch.Length - 1;
    InsertText := ', ' + AUnitName;
  end
  else
  begin
    InsertPosition := ImplementationMatch.Index + ImplementationMatch.Length;
    InsertText := sLineBreak + sLineBreak + 'uses' + sLineBreak + '  ' + AUnitName + ';';
  end;

  Writer := SourceEditor.CreateUndoableWriter;
  Writer.CopyTo(InsertPosition);
  Writer.Insert(PAnsiChar(AnsiString(InsertText)));
end;

{ TEntityDataProviderComponentProperty }

function TEntityDataProviderComponentProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList];
end;

procedure TEntityDataProviderComponentProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
  OwnedComponent: TComponent;
  Component: TComponent;
begin
  if (GetComponent(0) <> nil) and (GetComponent(0) is TComponent) and
     (TComponent(GetComponent(0)).Owner <> nil) then
  begin
    for I := 0 to TComponent(GetComponent(0)).Owner.ComponentCount - 1 do
    begin
      OwnedComponent := TComponent(GetComponent(0)).Owner.Components[I];
      if OwnedComponent is TEntityDataProvider then
        Proc(OwnedComponent.Name);
    end;
    Exit;
  end;

  for I := 0 to Designer.Root.ComponentCount - 1 do
  begin
    Component := Designer.Root.Components[I];
    if Component is TEntityDataProvider then
      Proc((Component as TComponent).Name);
  end;
end;

procedure TEntityDataProviderComponentProperty.SetValue(const Value: string);
begin
  inherited SetValue(Value);
end;

{ TEntityClassNameProperty }

function TEntityClassNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList];
end;

procedure TEntityClassNameProperty.GetValues(Proc: TGetStrProc);
var
  DataSet: TEntityDataSet;
  DP: IEntityDataProvider;
  Entities: TArray<string>;
  E: string;
begin
  DataSet := GetComponent(0) as TEntityDataSet;
  if Assigned(DataSet.DataProvider) then
  begin
    if DataSet.DataProvider.GetInterface(IEntityDataProvider, DP) then
    begin
      Entities := DP.GetEntities;
      for E in Entities do
        Proc(E);
    end;
  end;
end;

procedure TEntityClassNameProperty.SetValue(const Value: string);
var
  DataSet: TEntityDataSet;
  DP: IEntityDataProvider;
  EntityMD: TEntityClassMetadata;
begin
  inherited SetValue(Value);
  
  DataSet := GetComponent(0) as TEntityDataSet;
  if Assigned(DataSet.DataProvider) and DataSet.DataProvider.GetInterface(IEntityDataProvider, DP) then
  begin
    EntityMD := DP.GetEntityMetadata(Value);
    if EntityMD <> nil then
    begin
      EnsureUnitInCurrentModuleUses(DP.GetEntityUnitName(Value));
      DataSet.GenerateFields;
    end;
  end;
end;

procedure TEntityClassNameProperty.Edit;
var
  DataSet: TEntityDataSet;
  DP: IEntityDataProvider;
  Entities: TArray<string>;
  Selected: string;
begin
  DataSet := GetComponent(0) as TEntityDataSet;
  if Assigned(DataSet.DataProvider) and DataSet.DataProvider.GetInterface(IEntityDataProvider, DP) then
  begin
    Entities := DP.GetEntities;
    Selected := GetValue;
    
    if SelectEntity(Entities, Selected) then
    begin
      SetValue(Selected);
    end;
  end;
end;

{ TEntityDataProviderEditor }

procedure TEntityDataProviderEditor.ExecuteVerb(Index: Integer);
var
  Provider: TEntityDataProvider;
  ProviderProject: IOTAProject;
begin
  Provider := TEntityDataProvider(Component);

  case Index of
    0: // Scan Active Project + Refresh Metadata
      begin
        if PopulateProviderModelUnitsFromActiveProject(Provider, Designer) then
        begin
          RefreshProviderMetadata(Provider);
          RefreshBoundDataSets(Provider, Designer);
          if Designer <> nil then
            Designer.Modified;
        end;
      end;
    1: // Refresh Entity Metadata
      begin
        RefreshProviderMetadata(Provider);
        RefreshBoundDataSets(Provider, Designer);
        if Designer <> nil then
          Designer.Modified;
      end;
    2: // Clear All Cached Metadata
      begin
        Provider.ClearMetadata;
        Provider.ModelUnits.Clear;
        Provider.LastRefreshSummary := 'Metadata cache and units list cleared.';
        if Designer <> nil then
          Designer.Modified;
      end;
    3: // Clear + Rescan Active Project
      begin
        if ValidateProjectContext(Designer, ProviderProject) then
        begin
          Provider.ClearMetadata;
          Provider.ModelUnits.Clear;
          PopulateProviderModelUnitsFromProject(Provider, ProviderProject);
          RefreshProviderMetadata(Provider);
          RefreshBoundDataSets(Provider, Designer);
          if Designer <> nil then
            Designer.Modified;
        end;
      end;
  end;
end;

function TEntityDataProviderEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Dext: Scan Project + Refresh Metadata';
    1: Result := 'Dext: Refresh Entity Metadata';
    2: Result := 'Dext: Clear All Cached Metadata';
    3: Result := 'Dext: Clear + Rescan Active Project';
  end;
end;

function TEntityDataProviderEditor.GetVerbCount: Integer;
begin
  Result := 4;
end;

{ TEntityDataSetSelectionEditor }

procedure TEntityDataSetSelectionEditor.ExecuteVerb(Index: Integer; const List: IDesignerSelections);
var
  DataSet: TEntityDataSet;
  Provider: TEntityDataProvider;
  I: Integer;
  UnitName: string;
  DP: IEntityDataProvider;
  Entities: TArray<string>;
  Selected: string;
begin
  if (List.Count = 0) or not (List[0] is TEntityDataSet) then
    Exit;

  DataSet := TEntityDataSet(List[0]);

  case Index of
    0: // Generate Fields (Auto)
      DataSet.GenerateFields;
    1: // Preview Data
      ShowEntityPreview(DataSet);
    2: // Toggle Design-Time Preview
      DataSet.Active := not DataSet.Active;
    3: // Refresh Entity (Scan + Rebuild Fields)
      begin
        Provider := DataSet.DataProvider;
        if Provider = nil then
          Exit;

        // Re-scan only the unit of this entity if possible
        UnitName := Provider.GetEntityUnitName(DataSet.EntityClassName);
        if UnitName <> '' then
        begin
          // Find the full filename from ModelUnits
          for I := 0 to Provider.ModelUnits.Count - 1 do
          begin
            if SameText(ChangeFileExt(ExtractFileName(Provider.ModelUnits[I]), ''), UnitName) then
            begin
              DesignTimeRefreshUnit(Provider, Provider.ModelUnits[I]);
              Break;
            end;
          end;
        end
        else
        begin
          // Full refresh as fallback
          if PopulateProviderModelUnitsFromActiveProject(Provider, Designer) then
            RefreshProviderMetadata(Provider)
          else
            Exit;
        end;

        // Rebuild fields on this dataset
        DataSet.DisableControls;
        try
          if DataSet.Active then
            DataSet.Close;

          DataSet.GenerateFields(True, True, True); // AWipeAll=True, RemoveOrphans=True, UpdateExisting=True
        finally
          DataSet.EnableControls;
        end;

        if Designer <> nil then
          Designer.Modified;
      end;
      4: // Dext: Sync Fields (Keep Customizations)
      begin
        Provider := DataSet.DataProvider;
        if Provider = nil then
          Exit;

        UnitName := Provider.GetEntityUnitName(DataSet.EntityClassName);
        if UnitName <> '' then
        begin
          for I := 0 to Provider.ModelUnits.Count - 1 do
          begin
            if SameText(ChangeFileExt(ExtractFileName(Provider.ModelUnits[I]), ''), UnitName) then
            begin
              DesignTimeRefreshUnit(Provider, Provider.ModelUnits[I]);
              Break;
            end;
          end;
        end
        else
        begin
          if PopulateProviderModelUnitsFromActiveProject(Provider, Designer) then
            RefreshProviderMetadata(Provider)
          else
            Exit;
        end;

        DataSet.DisableControls;
        try
          if DataSet.Active then
            DataSet.Close;

          // Merge fields safely without overwriting user customizations
          DataSet.GenerateFields(False, True, False); // AWipeAll=False, RemoveOrphans=True, UpdateExisting=False
        finally
          DataSet.EnableControls;
        end;

        if Designer <> nil then
          Designer.Modified;
      end;
    5: // Dext: Search Entity Class...
      begin
        DP := nil;
        if Assigned(DataSet.DataProvider) and DataSet.DataProvider.GetInterface(IEntityDataProvider, DP) then
        begin
          Entities := DP.GetEntities;
          Selected := DataSet.EntityClassName;
          if SelectEntity(Entities, Selected) then
          begin
            DataSet.EntityClassName := Selected;
            if Designer <> nil then
              Designer.Modified;
          end;
        end;
      end;
  end;
end;

function TEntityDataSetSelectionEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Dext: Generate Fields (Auto)';
    1: Result := 'Dext: Preview Data...';
    2: Result := 'Dext: Toggle Design-Time Preview';
    3: Result := 'Dext: Refresh Entity (Scan + Rebuild Fields)';
    4: Result := 'Dext: Sync Fields (Keep Customizations)';
    5: Result := 'Dext: Search Entity Class...';
  end;
end;

function TEntityDataSetSelectionEditor.GetVerbCount: Integer;
begin
  Result := 6;
end;

type
  TTableSelectionForm = class(TForm)
  private
    FCheckList: TCheckListBox;
    FFilterEdit: TEdit;
    FStatsLabel: TLabel;
    FSelectedLabel: TLabel;
    FAllItems: TStringList;
    FCheckedItems: TDictionary<string, Boolean>;
    procedure RebuildList;
    procedure OnFilterChange(Sender: TObject);
    procedure OnSelectAll(Sender: TObject);
    procedure OnUnselectAll(Sender: TObject);
    procedure OnCheckClick(Sender: TObject);
  public
    constructor Create(const ACaption: string; AItems: TStrings); reintroduce;
    destructor Destroy; override;
    function GetSelected(ASelected: TStrings): Boolean;
  end;

{ TTableSelectionForm }

constructor TTableSelectionForm.Create(const ACaption: string; AItems: TStrings);
var
  TopPanel, BottomPanel: TPanel;
  BtnOk, BtnCancel, BtnAll, BtnNone: TButton;
  I: Integer;
begin
  inherited CreateNew(nil);
  FCheckedItems := TDictionary<string, Boolean>.Create;
  FAllItems := TStringList.Create;
  FAllItems.Assign(AItems);
  for I := 0 to FAllItems.Count - 1 do
    FCheckedItems.Add(FAllItems[I], False);

  Caption := ACaption;
  Width := 450;
  Height := 550;
  Position := poScreenCenter;

  TopPanel := TPanel.Create(Self);
  TopPanel.Parent := Self;
  TopPanel.Align := alTop;
  TopPanel.Height := 80;
  TopPanel.BevelOuter := bvNone;

  FFilterEdit := TEdit.Create(Self);
  FFilterEdit.Parent := TopPanel;
  FFilterEdit.Align := alTop;
  FFilterEdit.Margins.SetBounds(10, 10, 10, 5);
  FFilterEdit.AlignWithMargins := True;
  FFilterEdit.TextHint := 'Filter tables...';
  FFilterEdit.OnChange := OnFilterChange;

  BtnAll := TButton.Create(Self);
  BtnAll.Parent := TopPanel;
  BtnAll.Caption := 'Select All';
  BtnAll.Left := 10;
  BtnAll.Top := 45;
  BtnAll.Width := 100;
  BtnAll.OnClick := OnSelectAll;

  BtnNone := TButton.Create(Self);
  BtnNone.Parent := TopPanel;
  BtnNone.Caption := 'Unselect All';
  BtnNone.Left := 120;
  BtnNone.Top := 45;
  BtnNone.Width := 100;
  BtnNone.OnClick := OnUnselectAll;

  FStatsLabel := TLabel.Create(Self);
  FStatsLabel.Parent := TopPanel;
  FStatsLabel.Left := 230;
  FStatsLabel.Top := 50;
  FStatsLabel.Caption := 'Tables: 0';

  BottomPanel := TPanel.Create(Self);
  BottomPanel.Parent := Self;
  BottomPanel.Align := alBottom;
  BottomPanel.Height := 50;
  BottomPanel.BevelOuter := bvNone;

  FSelectedLabel := TLabel.Create(Self);
  FSelectedLabel.Parent := BottomPanel;
  FSelectedLabel.Left := 10;
  FSelectedLabel.Top := 15;
  FSelectedLabel.Caption := 'Selected: 0';
  FSelectedLabel.Font.Color := clRed;
  FSelectedLabel.Font.Style := [fsBold];

  BtnCancel := TButton.Create(Self);
  BtnCancel.Parent := BottomPanel;
  BtnCancel.Caption := 'Cancel';
  BtnCancel.Cancel := True;
  BtnCancel.ModalResult := mrCancel;
  BtnCancel.Width := 80;
  BtnCancel.Height := 30;
  BtnCancel.Top := 10;
  BtnCancel.Left := BottomPanel.Width - 90;
  BtnCancel.Anchors := [akRight, akBottom];

  BtnOk := TButton.Create(Self);
  BtnOk.Parent := BottomPanel;
  BtnOk.Caption := 'OK';
  BtnOk.Default := True;
  BtnOk.ModalResult := mrOk;
  BtnOk.Width := 80;
  BtnOk.Height := 30;
  BtnOk.Top := 10;
  BtnOk.Left := BtnCancel.Left - 85; // 5px gap (85 - 80)
  BtnOk.Anchors := [akRight, akBottom];

  FCheckList := TCheckListBox.Create(Self);
  FCheckList.Parent := Self;
  FCheckList.Align := alClient;
  FCheckList.AlignWithMargins := True;
  FCheckList.OnClickCheck := OnCheckClick;

  RebuildList;
end;

destructor TTableSelectionForm.Destroy;
begin
  FAllItems.Free;
  FCheckedItems.Free;
  inherited;
end;

function TTableSelectionForm.GetSelected(ASelected: TStrings): Boolean;
var
  Pair: TPair<string, Boolean>;
begin
  Result := False;
  if ShowModal = mrOk then
  begin
    ASelected.Clear;
    for Pair in FCheckedItems do
      if Pair.Value then
        ASelected.Add(Pair.Key);
    Result := ASelected.Count > 0;
  end;
end;

procedure TTableSelectionForm.OnCheckClick(Sender: TObject);
var
  I, Count: Integer;
begin
  if FCheckList.ItemIndex >= 0 then
    FCheckedItems.AddOrSetValue(FCheckList.Items[FCheckList.ItemIndex], FCheckList.Checked[FCheckList.ItemIndex]);
    
  Count := 0;
  for I := 0 to FAllItems.Count - 1 do
    if FCheckedItems[FAllItems[I]] then
      Inc(Count);
  FSelectedLabel.Caption := 'Selected: ' + IntToStr(Count);
end;

procedure TTableSelectionForm.OnFilterChange(Sender: TObject);
begin
  RebuildList;
end;

procedure TTableSelectionForm.OnSelectAll(Sender: TObject);
var
  I, Count: Integer;
begin
  for I := 0 to FCheckList.Items.Count - 1 do
  begin
    FCheckList.Checked[I] := True;
    FCheckedItems.AddOrSetValue(FCheckList.Items[I], True);
  end;
  
  Count := 0;
  for I := 0 to FAllItems.Count - 1 do
    if FCheckedItems[FAllItems[I]] then
      Inc(Count);
  FSelectedLabel.Caption := 'Selected: ' + IntToStr(Count);
end;

procedure TTableSelectionForm.OnUnselectAll(Sender: TObject);
var
  I, Count: Integer;
begin
  for I := 0 to FCheckList.Items.Count - 1 do
  begin
    FCheckList.Checked[I] := False;
    FCheckedItems.AddOrSetValue(FCheckList.Items[I], False);
  end;
  
  Count := 0;
  for I := 0 to FAllItems.Count - 1 do
    if FCheckedItems[FAllItems[I]] then
      Inc(Count);
  FSelectedLabel.Caption := 'Selected: ' + IntToStr(Count);
end;

procedure TTableSelectionForm.RebuildList;
var
  S, Filter: string;
begin
  Filter := FFilterEdit.Text;
  FCheckList.Items.BeginUpdate;
  try
    FCheckList.Items.Clear;
    for S in FAllItems do
    begin
      if (Filter = '') or (S.ToLower.Contains(Filter.ToLower)) then
      begin
        FCheckList.Items.Add(S);
        FCheckList.Checked[FCheckList.Items.Count - 1] := FCheckedItems[S];
      end;
    end;
  finally
    FCheckList.Items.EndUpdate;
  end;
  FStatsLabel.Caption := Format('Visible: %d / Total: %d', [FCheckList.Items.Count, FAllItems.Count]);
end;

function MultiInput(const ACaption: string; const AItems: TStrings; ASelected: TStrings): Boolean;
var
  Form: TTableSelectionForm;
begin
  Form := TTableSelectionForm.Create(ACaption, AItems);
  try
    Result := Form.GetSelected(ASelected);
  finally
    Form.Free;
  end;
end;

{ TScaffoldingConnectionSelectionEditor }

procedure TScaffoldingConnectionSelectionEditor.ExecuteVerb(Index: Integer; const List: IDesignerSelections);
var
  Conn: TFDConnection;
  Tables, SelectedTables: TStringList;
  MetaArray: TArray<TMetaTable>;
  Path: string;
  I: Integer;
  TableName: string;
  Provider: TEntityDataProvider;
begin
  if (List.Count = 0) or not (List[0] is TFDConnection) then
    Exit;
    
  Conn := TFDConnection(List[0]);

  case Index of
    0: // Dext: Generate Entities from Tables...
    begin
      Tables := TStringList.Create;
      SelectedTables := TStringList.Create;
      try
        for TableName in TScaffoldingHelper.GetTablesFromConnection(Conn) do
          Tables.Add(TableName);
        if Tables.Count = 0 then
        begin
          MessageDlg('No tables found in this connection.', mtWarning, [mbOK], 0);
          Exit;
        end;

        if not MultiInput('Select Tables to Scaffold', Tables, SelectedTables) then
          Exit;

        SetLength(MetaArray, SelectedTables.Count);
        for I := 0 to SelectedTables.Count - 1 do
          MetaArray[I] := TScaffoldingHelper.GetTableMetadata(Conn, SelectedTables[I]);
        
        // Suggested path: current module path
        Path := '';
        if (BorlandIDEServices as IOTAModuleServices).CurrentModule <> nil then
          Path := ExtractFilePath((BorlandIDEServices as IOTAModuleServices).CurrentModule.FileName);
        
        if Path = '' then
          Path := TPath.GetDocumentsPath;

        if ShowScaffoldingPreview(MetaArray, Path) then
        begin
          // Auto-refresh any DataProvider on the same form
          if Assigned(Conn.Owner) then
          begin
            for I := 0 to Conn.Owner.ComponentCount - 1 do
            begin
              if Conn.Owner.Components[I] is TEntityDataProvider then
              begin
                Provider := TEntityDataProvider(Conn.Owner.Components[I]);
                if PopulateProviderModelUnitsFromActiveProject(Provider, Designer) then
                begin
                  RefreshProviderMetadata(Provider);
                  RefreshBoundDataSets(Provider, Designer);
                end;
              end;
            end;
          end;
        end;
      finally
        Tables.Free;
        SelectedTables.Free;
      end;
    end;
  end;
end;

function TScaffoldingConnectionSelectionEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Dext: Scaffolding -> Generate Entities from Tables...';
  end;
end;

function TScaffoldingConnectionSelectionEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

{ TScaffoldingDataSetSelectionEditor }

procedure TScaffoldingDataSetSelectionEditor.ExecuteVerb(Index: Integer; const List: IDesignerSelections);
var
  DS: TDataSet;
  Meta: TMetaTable;
  Path: string;
begin
  if (List.Count = 0) or not (List[0] is TDataSet) then
    Exit;
    
  DS := TDataSet(List[0]);

  case Index of
    0: // Dext: Create Entity from this Dataset...
    begin
      if DS.FieldCount = 0 then
      begin
        MessageDlg('Dataset has no fields. Open the dataset or add fields before generating.', mtError, [mbOK], 0);
        Exit;
      end;
      
      Meta := TScaffoldingHelper.DataSetToMetaTable(DS);
      
      // Suggested path: current module path
      Path := '';
      if (BorlandIDEServices as IOTAModuleServices).CurrentModule <> nil then
        Path := ExtractFilePath((BorlandIDEServices as IOTAModuleServices).CurrentModule.FileName);
      
      if Path = '' then
        Path := TPath.GetDocumentsPath;

      ShowScaffoldingPreview([Meta], Path);
    end;
  end;
end;

function TScaffoldingDataSetSelectionEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Dext: Create Entity from this Dataset...';
  end;
end;

function TScaffoldingDataSetSelectionEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function InputCombo(const ACaption, APrompt: string; const AItems: TStrings; var AValue: string): Boolean;
var
  Form: TForm;
  Lbl: TLabel;
  Combo: TComboBox;
  BtnOk, BtnCancel: TButton;
begin
  Result := False;
  Form := TForm.Create(nil);
  try
    Form.Caption := ACaption;
    Form.Width := 300;
    Form.Height := 160;
    Form.Position := poScreenCenter;
    Form.BorderStyle := bsDialog;
    
    Lbl := TLabel.Create(Form);
    Lbl.Parent := Form;
    Lbl.Caption := APrompt;
    Lbl.Left := 10;
    Lbl.Top := 10;
    
    Combo := TComboBox.Create(Form);
    Combo.Parent := Form;
    Combo.Style := csDropDownList;
    Combo.Left := 10;
    Combo.Top := 30;
    Combo.Width := 260;
    Combo.Items.Assign(AItems);
    Combo.ItemIndex := 0;
    
    BtnOk := TButton.Create(Form);
    BtnOk.Parent := Form;
    BtnOk.Caption := 'OK';
    BtnOk.Default := True;
    BtnOk.ModalResult := mrOk;
    BtnOk.Left := 110;
    BtnOk.Top := 80;
    
    BtnCancel := TButton.Create(Form);
    BtnCancel.Parent := Form;
    BtnCancel.Caption := 'Cancel';
    BtnCancel.Cancel := True;
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Left := 195;
    BtnCancel.Top := 80;
    
    if Form.ShowModal = mrOk then
    begin
      AValue := Combo.Text;
      Result := True;
    end;
  finally
    Form.Free;
  end;
end;

procedure RegisterEditors;
var
  DataSetClass: TComponentClass;
  ProviderClass: TComponentClass;
begin
{$IFDEF DEXT_USE_ENTITY_PREFIX}
  DataSetClass := TDextEntityDataSet;
  ProviderClass := TDextEntityDataProvider;
{$ELSE}
  DataSetClass := TEntityDataSet;
  ProviderClass := TEntityDataProvider;
{$ENDIF}
  RegisterComponents('Dext Entity', [ProviderClass, DataSetClass]);
  RegisterPropertyEditor(TypeInfo(string), DataSetClass, 'EntityClassName', TEntityClassNameProperty);
  RegisterComponentEditor(ProviderClass, TEntityDataProviderEditor);
  RegisterSelectionEditor(DataSetClass, TEntityDataSetSelectionEditor);

  RegisterSelectionEditor(TFDConnection, TScaffoldingConnectionSelectionEditor);
  RegisterSelectionEditor(TDataSet, TScaffoldingDataSetSelectionEditor);
end;

initialization
  GOnGetSourceContent := GetModuleContent;

finalization
  GOnGetSourceContent := nil;

end.
