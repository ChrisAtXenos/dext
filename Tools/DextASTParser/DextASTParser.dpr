program DextASTParser;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Types,
  System.TypInfo,
  System.Generics.Collections,
  System.Generics.Defaults,
  DelphiAST,
  DelphiAST.Writer,
  DelphiAST.Classes,
  DelphiAST.Consts,
  SimpleParser,
  SimpleParser.Lexer,
  SimpleParser.Lexer.Types,
  DelphiAST.SimpleParserEx,
  StringPool;

type
  TIncludeHandler = class(TInterfacedObject, IIncludeHandler)
  private
    FPaths: TArray<string>;
    FCurrentFileDir: string;
  public
    constructor Create(const APaths: TArray<string>);
    function GetIncludeFileContent(const ParentFileName, IncludeName: string;
      out Content: string; out FileName: string): Boolean;
    property CurrentFileDir: string read FCurrentFileDir write FCurrentFileDir;
  end;

constructor TIncludeHandler.Create(const APaths: TArray<string>);
begin
  inherited Create;
  FPaths := APaths;
end;

function TIncludeHandler.GetIncludeFileContent(const ParentFileName, IncludeName: string;
  out Content: string; out FileName: string): Boolean;
var
  Path, FullPath: string;
  FileContent: TStringList;
begin
  Result := False;
  
  // First try relative to parent file
  if ParentFileName <> '' then
    FullPath := TPath.Combine(ExtractFilePath(ParentFileName), IncludeName)
  else
    FullPath := TPath.Combine(FCurrentFileDir, IncludeName);
    
  if FileExists(FullPath) then
  begin
    FileName := FullPath;
  end
  else
  begin
    // Try each include path
    for Path in FPaths do
    begin
      FullPath := TPath.Combine(Path, IncludeName);
      if FileExists(FullPath) then
      begin
        FileName := FullPath;
        Break;
      end;
    end;
  end;
  
  if not FileExists(FullPath) then
    Exit;
    
  FileContent := TStringList.Create;
  try
    FileContent.LoadFromFile(FullPath);
    Content := FileContent.Text;
    Result := True;
  finally
    FileContent.Free;
  end;
end;

type
  TNodeInfo = record
    Node: TSyntaxNode;
    Line: Integer;
    constructor Create(ANode: TSyntaxNode);
  end;

constructor TNodeInfo.Create(ANode: TSyntaxNode);
begin
  Node := ANode;
  Line := ANode.Line;
end;

procedure CollectNodes(Root: TSyntaxNode; var List: TList<TNodeInfo>);
var
  Child: TSyntaxNode;
begin
  if (Root.Typ in [ntTypeDecl, ntMethod, ntProperty, ntField, ntConstants, ntTypeSection]) then
    List.Add(TNodeInfo.Create(Root));
    
  for Child in Root.ChildNodes do
    CollectNodes(Child, List);
end;

procedure InjectXmlDocumentation(Root: TSyntaxNode; Comments: TObjectList<TCommentNode>);
var
  Nodes: TList<TNodeInfo>;
  Comment: TCommentNode;
  I: Integer;
  Target: TSyntaxNode;
  DocNode: TValuedSyntaxNode;
begin
  if (Comments = nil) or (Comments.Count = 0) then Exit;

  Nodes := TList<TNodeInfo>.Create;
  try
    CollectNodes(Root, Nodes);
    Nodes.Sort(TComparer<TNodeInfo>.Construct(
      function(const Left, Right: TNodeInfo): Integer
      begin
        Result := Left.Line - Right.Line;
      end
    ));

     for Comment in Comments do
    begin
      // Only process XML documentation comments (parsed as starting with / after // is stripped)
      if not TrimLeft(Comment.Text).StartsWith('/') then Continue;

      // Find the first node that starts AFTER or AT the comment line
      Target := nil;
      for I := 0 to Nodes.Count - 1 do
      begin
        if Nodes[I].Line >= Comment.Line then
        begin
          // Ensure it's close enough (e.g., within 5 lines) to be relevant
          if (Nodes[I].Line - Comment.Line) <= 5 then
            Target := Nodes[I].Node;
          Break;
        end;
      end;

      if Target <> nil then
      begin
        // Inject as a valued child node
        DocNode := TValuedSyntaxNode.Create(ntSlashesComment);
        DocNode.Value := Comment.Text;
        Target.AddChild(DocNode);
      end;
    end;
  finally
    Nodes.Free;
  end;
end;

procedure ShowHelp;
begin
  WriteLn('DextASTParser - Generate XML AST from Delphi source files');
  WriteLn;
  WriteLn('Usage: DextASTParser.exe <input_path> <output_path> [-i include_path1;include_path2]');
  WriteLn;
  WriteLn('Arguments:');
  WriteLn('  input_path    Directory to scan recursively for .pas files');
  WriteLn('  output_path   Directory where XML files will be saved');
  WriteLn('  -i            Optional: Semicolon separated list of include paths');
end;

var
  InputDir, OutputDir: string;
  IncludePaths: TArray<string>;
  IncludeHandler: IIncludeHandler;
  Files: TStringDynArray;
  FileName, RelativePath, OutputPath, XmlContent: string;
  SyntaxTree: TSyntaxNode;
  SuccessCount, FailCount: Integer;
  Builder: TPasSyntaxTreeBuilder;
  Stream: TStringStream;
  I: Integer;
  Param: string;

begin
  try
    if (ParamCount < 2) then
    begin
      ShowHelp;
      Exit;
    end;

    InputDir := TPath.GetFullPath(ParamStr(1));
    OutputDir := TPath.GetFullPath(ParamStr(2));
    
    SetLength(IncludePaths, 0);
    
    // Parse optional include paths
    for I := 3 to ParamCount do
    begin
      Param := ParamStr(I);
      if Param.StartsWith('-i', True) then
      begin
        if Param.Length > 2 then
          IncludePaths := Param.Substring(2).Split([';'])
        else if I + 1 <= ParamCount then
          IncludePaths := ParamStr(I + 1).Split([';']);
      end;
    end;

    WriteLn('===========================================');
    WriteLn('  DextASTParser - DelphiAST for Dext');
    WriteLn('===========================================');
    WriteLn('Input:  ', InputDir);
    WriteLn('Output: ', OutputDir);
    WriteLn;
    
    if not DirectoryExists(InputDir) then
    begin
      WriteLn('[ERROR] Input directory not found: ', InputDir);
      ExitCode := 1;
      Exit;
    end;

    if not DirectoryExists(OutputDir) then
      ForceDirectories(OutputDir);
      
    IncludeHandler := TIncludeHandler.Create(IncludePaths);
    
    SuccessCount := 0;
    FailCount := 0;
    
    WriteLn('[SCANNING] ', InputDir);
    Files := TDirectory.GetFiles(InputDir, '*.pas', TSearchOption.soAllDirectories);
    
    for FileName in Files do
    begin
      // Create a relative path matching the structure for the output file
      RelativePath := ExtractRelativePath(IncludeTrailingPathDelimiter(InputDir), FileName);
      OutputPath := TPath.Combine(OutputDir, ChangeFileExt(RelativePath, '.xml'));
      
      // Ensure the output subdirectory exists
      ForceDirectories(ExtractFilePath(OutputPath));
      
      Write('  ', RelativePath, ' ... ');
      
      try
        Builder := TPasSyntaxTreeBuilder.Create;
        try
          Builder.InitDefinesDefinedByCompiler;
          Builder.AddDefine('MSWINDOWS'); // Crucial for Dext which uses Windows API in some units
          Builder.UseDefines := True;
          
          (IncludeHandler as TIncludeHandler).CurrentFileDir := TPath.GetDirectoryName(FileName);
          Builder.IncludeHandler := IncludeHandler;
          
          XmlContent := TFile.ReadAllText(FileName);
          Stream := TStringStream.Create(XmlContent, TEncoding.UTF8);
          try
            Stream.Position := 0;
            
            SyntaxTree := Builder.Run(Stream);
            try
              // Inject XML Documentation Comments
              InjectXmlDocumentation(SyntaxTree, Builder.Comments);
              
              XmlContent := TSyntaxTreeWriter.ToXML(SyntaxTree, True);
              TFile.WriteAllText(OutputPath, XmlContent, TEncoding.UTF8);
              WriteLn('[OK]');
              Inc(SuccessCount);
            finally
              SyntaxTree.Free;
            end;
          finally
            Stream.Free;
          end;
        finally
          Builder.Free;
        end;
      except
        on E: Exception do
        begin
          WriteLn('[FAIL] ', E.Message);
          Inc(FailCount);
        end;
      end;
    end;
    
    WriteLn;
    WriteLn('===========================================');
    WriteLn('  Results: ', SuccessCount, ' OK, ', FailCount, ' Failed');
    WriteLn('  Output: ', OutputDir);
    WriteLn('===========================================');
    
    if FailCount > 0 then
      ExitCode := 1;
      
  except
    on E: Exception do
    begin
      WriteLn('[FATAL] ', E.ClassName, ': ', E.Message);
      ExitCode := 2;
    end;
  end;
end.
