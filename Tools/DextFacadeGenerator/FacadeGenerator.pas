unit FacadeGenerator;

interface

uses
  System.SysUtils,
  System.StrUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  DelphiAST.Classes,
  DelphiAST.Consts,
  DelphiAST;

type
  TOrdinalIgnoreCaseComparer = class(TEqualityComparer<string>)
  public
    function Equals(const Left, Right: string): Boolean; override;
    function GetHashCode(const Value: string): Integer; override;
  end;

  TExtractedUnit = class
  public
    UnitName: string;
    Types: TList<string>;
    GenericTypes: TList<string>; // New: Store generic types for comments
    Consts: TList<string>;
    constructor Create(const AName: string);
    destructor Destroy; override;
  end;

  TFacadeGenerator = class
  protected
    FSourcePath: string;
    FSearchPattern: string;
    FExcludedUnits: THashSet<string>;
    FParsedUnits: TObjectList<TExtractedUnit>;
    FGlobalTypeNames: THashSet<string>; // New: Global deduplication
    
    procedure ScanFolder(const Folder: string);
    procedure ProcessFile(const FileName: string); virtual;
    function IsExcluded(const UnitName: string): Boolean;
    function IsGeneric(Node: TSyntaxNode): Boolean;
    function GetUnitName(Root: TSyntaxNode; const FileName: string): string;
  public
    property ParsedUnits: TObjectList<TExtractedUnit> read FParsedUnits;
    constructor Create(const SourcePath, Wildcard: string; const Excluded: TArray<string>);
    destructor Destroy; override;
    procedure Execute; virtual;
    procedure InjectIntoFile(const TargetFile: string);
  private
    FSkippedUnits: TList<string>;
    FProcessedUnits: Integer;
    function IsFieldName(const AName: string): Boolean;
    function IsUnitProcessed(const UnitName: string): Boolean;
  end;

implementation

{ TOrdinalIgnoreCaseComparer }

function TOrdinalIgnoreCaseComparer.Equals(const Left, Right: string): Boolean;
begin
  Result := SameText(Left, Right);
end;

function TOrdinalIgnoreCaseComparer.GetHashCode(const Value: string): Integer;
begin
  Result := TEqualityComparer<string>.Default.GetHashCode(UpperCase(Value));
end;

{ TExtractedUnit }

constructor TExtractedUnit.Create(const AName: string);
begin
  UnitName := AName;
  Types := TList<string>.Create;
  GenericTypes := TList<string>.Create;
  Consts := TList<string>.Create;
end;

destructor TExtractedUnit.Destroy;
begin
  Types.Free;
  GenericTypes.Free;
  Consts.Free;
  inherited;
end;

{ TFacadeGenerator }

constructor TFacadeGenerator.Create(const SourcePath, Wildcard: string; const Excluded: TArray<string>);
var
  S: string;
begin
  FSourcePath := SourcePath;
  FSearchPattern := Wildcard;
  FExcludedUnits := THashSet<string>.Create(TOrdinalIgnoreCaseComparer.Create);
  FGlobalTypeNames := THashSet<string>.Create(TOrdinalIgnoreCaseComparer.Create); // Case-insensitive
  for S in Excluded do
    FExcludedUnits.Add(S);
    
  FParsedUnits := TObjectList<TExtractedUnit>.Create(True);
  FSkippedUnits := TList<string>.Create;
  FProcessedUnits := 0;
end;

destructor TFacadeGenerator.Destroy;
begin
  FParsedUnits.Free;
  FSkippedUnits.Free;
  FExcludedUnits.Free;
  FGlobalTypeNames.Free;
  inherited;
end;

function TFacadeGenerator.IsFieldName(const AName: string): Boolean;
begin
  Result := (Length(AName) >= 2) and 
            (AName[1] = 'F') and 
            CharInSet(AName[2], ['A'..'Z']);
end;

function TFacadeGenerator.IsGeneric(Node: TSyntaxNode): Boolean;
begin
  // Check if declaration has type parameters
  Result := Node.FindNode(ntTypeParams) <> nil;
end;

function TFacadeGenerator.GetUnitName(Root: TSyntaxNode; const FileName: string): string;
begin
  if (Root <> nil) and (Root.Typ = ntUnit) then
    Result := Root.GetAttribute(anName)
  else
    Result := '';
    
  if Result = '' then
    Result := TPath.GetFileNameWithoutExtension(FileName);
end;

function TFacadeGenerator.IsExcluded(const UnitName: string): Boolean;
begin
  Result := FExcludedUnits.Contains(UnitName);
end;

function TFacadeGenerator.IsUnitProcessed(const UnitName: string): Boolean;
var
  U: TExtractedUnit;
begin
  Result := False;
  for U in FParsedUnits do
    if SameText(U.UnitName, UnitName) then Exit(True);
end;

procedure TFacadeGenerator.Execute;
begin
  ScanFolder(FSourcePath);
end;

procedure TFacadeGenerator.ScanFolder(const Folder: string);
var
  FileName: string;
  SubFolder: string;
begin
  for FileName in TDirectory.GetFiles(Folder, FSearchPattern) do
  begin
    ProcessFile(FileName);
  end;

  for SubFolder in TDirectory.GetDirectories(Folder) do
  begin
    ScanFolder(SubFolder);
  end;
end;

procedure TFacadeGenerator.ProcessFile(const FileName: string);
var
  Root, IntfNode, SectionNode, DeclNode: TSyntaxNode;
  UnitName: string;
  UnitDecl: TExtractedUnit;
  TypeName: string;
  GenericParams: string;
  
  function IsValidType(Name: string): Boolean;
  begin
     Result := True;
     // Filter obvious keywords if mistakenly parsed as name
     if MatchStr(Name, ['type', 'const', 'var', 'class', 'interface', 'record', 'end']) then Exit(False);
     if IsFieldName(Name) then Exit(False);
  end;
  
begin
  if TPath.GetFileName(FileName).StartsWith('.') then Exit;
  if TPath.GetFileName(FileName).Contains('.Aliases.inc') then Exit;
  if TPath.GetFileName(FileName).Contains('.Uses.inc') then Exit;
  
  Writeln('Processing: ' + TPath.GetFileName(FileName));
  Inc(FProcessedUnits);

  Root := nil;
  try
    try
      // Use TPasSyntaxTreeBuilder from DelphiAST.pas
      Root := TPasSyntaxTreeBuilder.Run(FileName);
    except
      on E: Exception do
      begin
        Writeln('Error parsing ' + FileName + ': ' + E.Message);
        Exit;
      end;
    end;

    if Root = nil then Exit;

    UnitName := GetUnitName(Root, FileName);
    
    if IsExcluded(UnitName) then 
    begin
      Writeln('  Excluded: ' + UnitName);
      Exit;
    end;

    // Deduplicate units
    if IsUnitProcessed(UnitName) then
    begin
       Writeln('  Duplicate unit skipped: ' + UnitName);
       Exit;
    end;

    UnitDecl := TExtractedUnit.Create(UnitName);
    
    // Find Interface section
    IntfNode := Root.FindNode(ntInterface);
    if IntfNode <> nil then
    begin
      // Iterate interface sections (Type, Const, etc.)
      for SectionNode in IntfNode.ChildNodes do
      begin
        if SectionNode.Typ = ntTypeSection then
        begin
          for DeclNode in SectionNode.ChildNodes do
          begin
            if DeclNode.Typ = ntTypeDecl then
            begin
              TypeName := DeclNode.GetAttribute(anName);
              
              if not IsValidType(TypeName) then Continue;

              // Check for Generics
              if IsGeneric(DeclNode) then 
              begin
                 // Add to generics list (no global check needed for comments, but optional)
                 // Format: MyType<T>
                 // Note: Extracting exact params from AST is harder without traversing ntTypeParams.
                 // For now, we will just assume <T> as a placeholder or try to simple append <> if we don't parse deeply.
                 // Actually, checking children of ntTypeParams would be better.
                 // Let's just append IsGeneric marker for now to keep it simple as requested "commented reference".
                 // Or we can try to reconstruct it.
                 // Simplest is just storing the name, adding it to comments.
                 GenericParams := '<T>'; // Default placeholder
                 UnitDecl.GenericTypes.Add(TypeName + GenericParams); 
                 Continue;
              end;
              
              // Global Deduplication check
              if FGlobalTypeNames.Contains(TypeName) then
              begin
                 //writeln('  Skipping duplicate type: ' + TypeName);
                 Continue;
              end;
              
              if not UnitDecl.Types.Contains(TypeName) then
              begin
                UnitDecl.Types.Add(TypeName);
                FGlobalTypeNames.Add(TypeName); // Mark as used
              end;
            end;
          end;
        end
        else if SectionNode.Typ = ntConstants then // Changed from ntConstSection
        begin
           for DeclNode in SectionNode.ChildNodes do
           begin
             if DeclNode.Typ = ntConstant then
             begin
               var ConstName := DeclNode.GetAttribute(anName);
               
               // Global Deduplication for constants too
               if FGlobalTypeNames.Contains(ConstName) then Continue;
               
               if not UnitDecl.Consts.Contains(ConstName) then
               begin
                 UnitDecl.Consts.Add(ConstName);
                 FGlobalTypeNames.Add(ConstName);
               end;
             end;
           end;
        end;
      end;
    end;

    if (UnitDecl.Types.Count > 0) or (UnitDecl.Consts.Count > 0) or (UnitDecl.GenericTypes.Count > 0) then
      FParsedUnits.Add(UnitDecl)
    else
      UnitDecl.Free;

  finally
    Root.Free;
  end;
end;

procedure TFacadeGenerator.InjectIntoFile(const TargetFile: string);
var
  Lines: TStringList;
  NewLines: TStringList;
  I: Integer;
  InAliasesBlock, InUsesBlock: Boolean;
  
  // Local logic
  procedure AddAliases;
  var
    LUnitInfo: TExtractedUnit;
    LTypeName: string;
    LConstName: string;
    LGenericName: string;
    HasConsts, HasGenerics: Boolean;
  begin
    NewLines.Add('  // Generated Aliases');
    
    // Sort units
    FParsedUnits.Sort(TComparer<TExtractedUnit>.Construct(
      function(const L, R: TExtractedUnit): Integer
      begin
        Result := CompareText(L.UnitName, R.UnitName);
      end
    ));

    for LUnitInfo in FParsedUnits do
    begin
      // Normal Types
      if LUnitInfo.Types.Count > 0 then
      begin
        NewLines.Add('');
        NewLines.Add('  // ' + LUnitInfo.UnitName);
        for LTypeName in LUnitInfo.Types do
          NewLines.Add(Format('  %s = %s.%s;', [LTypeName, LUnitInfo.UnitName, LTypeName]));
      end;
      
      // Generic Types (Commented)
      if LUnitInfo.GenericTypes.Count > 0 then
      begin
         if LUnitInfo.Types.Count = 0 then // Add header if not already added
         begin
            NewLines.Add('');
            NewLines.Add('  // ' + LUnitInfo.UnitName);
         end;
         for LGenericName in LUnitInfo.GenericTypes do
           NewLines.Add(Format('  // %s = %s.%s;', [LGenericName, LUnitInfo.UnitName, LGenericName]));
      end;
    end;
    
    // Constants
    HasConsts := False;
    for LUnitInfo in FParsedUnits do if LUnitInfo.Consts.Count > 0 then HasConsts := True;
    
    if HasConsts then
    begin
        NewLines.Add('');
        NewLines.Add('const');
        for LUnitInfo in FParsedUnits do
        begin
          if LUnitInfo.Consts.Count > 0 then
          begin
             NewLines.Add('  // ' + LUnitInfo.UnitName);
             for LConstName in LUnitInfo.Consts do
                NewLines.Add(Format('  %s = %s.%s;', [LConstName, LUnitInfo.UnitName, LConstName]));
          end;
        end;
    end;
  end;
  
  procedure AddUses;
  var
    LUnitInfo: TExtractedUnit;
    LUnits: TList<string>;
    i: Integer;
  begin
      NewLines.Add('  // Generated Uses');
      LUnits := TList<string>.Create;
      try
        for LUnitInfo in FParsedUnits do
        begin
            // Include unit if traversed, even if only for generics (as reference) or constants
           if (LUnitInfo.Types.Count > 0) or (LUnitInfo.Consts.Count > 0) or (LUnitInfo.GenericTypes.Count > 0) then
              LUnits.Add(LUnitInfo.UnitName);
        end;
        
        for i := 0 to LUnits.Count - 1 do
        begin
          if i < LUnits.Count - 1 then
            NewLines.Add('  ' + LUnits[i] + ',')
          else
            NewLines.Add('  ' + LUnits[i]);
        end;
      finally
        LUnits.Free;
      end;
  end;
  
begin
  if not TFile.Exists(TargetFile) then
  begin
    Writeln('Target file not found: ' + TargetFile);
    Exit;
  end;
  
  Lines := TStringList.Create;
  NewLines := TStringList.Create;
  try
    Lines.LoadFromFile(TargetFile);
    
    InAliasesBlock := False;
    InUsesBlock := False;
    
    for I := 0 to Lines.Count - 1 do
    begin
      var Trimmed := Trim(Lines[I]);
      
      if Trimmed.StartsWith('// {BEGIN_DEXT_ALIASES}') then
      begin
         NewLines.Add(Lines[I]);
         AddAliases;
         InAliasesBlock := True;
         Continue;
      end;
      
      if Trimmed.StartsWith('// {END_DEXT_ALIASES}') then
      begin
         NewLines.Add(Lines[I]);
         InAliasesBlock := False;
         Continue;
      end;
      
      if Trimmed.StartsWith('// {BEGIN_DEXT_USES}') then
      begin
         NewLines.Add(Lines[I]);
         AddUses;
         InUsesBlock := True;
         Continue;
      end;
      
      if Trimmed.StartsWith('// {END_DEXT_USES}') then
      begin
         NewLines.Add(Lines[I]);
         InUsesBlock := False;
         Continue;
      end;
      
      if not InAliasesBlock and not InUsesBlock then
         NewLines.Add(Lines[I]);
    end;
    
    NewLines.SaveToFile(TargetFile);
    Writeln('Injected code into ' + TargetFile);
    
  finally
    Lines.Free;
    NewLines.Free;
  end;
end;

end.
