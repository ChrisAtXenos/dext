unit Dext.Entity.Design.Metadata.Tests;

interface

uses
  System.Classes,
  System.SysUtils,
  Dext.Assertions,
  Dext.Testing.Attributes,
  Dext.Collections,
  Dext.Entity.Core,
  Dext.Entity.Metadata,
  Dext.EF.Design.Metadata;


type
  [TestFixture('Design-time metadata parser')]
  TEntityDesignMetadataTests = class
  private
    function GetDemoMainFormFileName: string;
    function FindEntity(const AEntities: IList<TEntityClassMetadata>; const AClassName: string): TEntityClassMetadata;
    function FindMember(AEntity: TEntityClassMetadata; const AMemberName: string): TEntityMemberMetadata;
  public
    [Test]
    procedure Test_Parse_Demo_MainForm_Finds_TProduct;
    [Test]
    procedure Test_Parse_Demo_MainForm_Reads_Field_Attributes;
  end;

implementation

uses
  System.IOUtils;

function TEntityDesignMetadataTests.GetDemoMainFormFileName: string;
const
  DEMO_REL_PATH = 'Examples\05-UI\Desktop.EntityDataSet.Demo\MainForm.pas';
var
  BaseDir: string;
  ResultPath: string;
  CurrentDir: string;
begin
  BaseDir := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  
  // Try 1: Navigate from Output/Platform/Config to Repo Root (3 levels up)
  // c:\dev\Dext\DextRepository\Output\37.0_Win32_Debug -> c:\dev\Dext\DextRepository
  ResultPath := TPath.GetFullPath(TPath.Combine(BaseDir, '..\..\ ' + DEMO_REL_PATH)).Replace(' \ ', '\');
  if FileExists(ResultPath) then Exit(ResultPath);

  // Try 2: Standard Output (2 levels up)
  ResultPath := TPath.GetFullPath(TPath.Combine(BaseDir, '..\..\' + DEMO_REL_PATH));
  if FileExists(ResultPath) then Exit(ResultPath);

  // Try 3: Standard Output (3 levels up without space hack)
  ResultPath := TPath.GetFullPath(TPath.Combine(BaseDir, '..\..\..\' + DEMO_REL_PATH));
  if FileExists(ResultPath) then Exit(ResultPath);

  // Try 4: Recursive search up
  CurrentDir := BaseDir;
  while Length(CurrentDir) > 3 do
  begin
    ResultPath := TPath.Combine(CurrentDir, DEMO_REL_PATH);
    if FileExists(ResultPath) then Exit(ResultPath);
    CurrentDir := TPath.GetDirectoryName(CurrentDir);
  end;

  Result := DEMO_REL_PATH;
end;

function TEntityDesignMetadataTests.FindEntity(const AEntities: IList<TEntityClassMetadata>;
  const AClassName: string): TEntityClassMetadata;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to AEntities.Count - 1 do
    if SameText(AEntities[i].EntityClassName, AClassName) then
      Exit(AEntities[i]);
end;

function TEntityDesignMetadataTests.FindMember(AEntity: TEntityClassMetadata;
  const AMemberName: string): TEntityMemberMetadata;
var
  i: Integer;
begin
  Result := nil;
  if AEntity = nil then
    Exit;

  for i := 0 to AEntity.Members.Count - 1 do
  begin
    if SameText(AEntity.Members[i].Name, AMemberName) then
      Exit(AEntity.Members[i]);
  end;
end;

procedure TEntityDesignMetadataTests.Test_Parse_Demo_MainForm_Finds_TProduct;
var
  Parser: TEntityMetadataParser;
  Entities: IList<TEntityClassMetadata>;
  Product: TEntityClassMetadata;
begin
  Parser := TEntityMetadataParser.Create;
  try
    Entities := Parser.ParseUnit(GetDemoMainFormFileName);
    Should(Entities.Count > 0).BeTrue;

    Product := FindEntity(Entities, 'TProduct');
    Should(Product).NotBeNull;
    Should(Product.EntityUnitName).Be('MainForm');
    Should(Product.Members.Count).Be(4);
    Should(Product.TableName).Be('products');
  finally
    Parser.Free;
  end;
end;

procedure TEntityDesignMetadataTests.Test_Parse_Demo_MainForm_Reads_Field_Attributes;
var
  Parser: TEntityMetadataParser;
  Entities: IList<TEntityClassMetadata>;
  Product: TEntityClassMetadata;
  IdMember: TEntityMemberMetadata;
  DescriptionMember: TEntityMemberMetadata;
  StockMember: TEntityMemberMetadata;
begin
  Parser := TEntityMetadataParser.Create;
  try
    Entities := Parser.ParseUnit(GetDemoMainFormFileName);
    Product := FindEntity(Entities, 'TProduct');

    IdMember := FindMember(Product, 'Id');
    Should(IdMember).NotBeNull;
    Should(IdMember.IsPrimaryKey).BeTrue;

    DescriptionMember := FindMember(Product, 'Description');
    Should(DescriptionMember).NotBeNull;
    Should(DescriptionMember.MaxLength).Be(200);
    Should(DescriptionMember.DisplayWidth).Be(75);

    StockMember := FindMember(Product, 'Stock');
    Should(StockMember).NotBeNull;
    Should(StockMember.Visible).BeFalse;
  finally
    Parser.Free;
  end;
end;

end.
