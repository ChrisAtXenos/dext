unit Dext.Entity.Architecture.Tests;

interface

uses
  System.Classes,
  System.SysUtils,
  System.IOUtils,
  Dext.Assertions,
  Dext.Collections,
  Dext.Entity.Attributes,
  Dext.Entity.Core,
  Dext.Entity.LazyLoader,
  Dext.Entity.Metadata,
  Dext.Entity.ProxyFactory,
  Dext.Interception.ClassProxy,
  Dext.Testing.Attributes;

type
  TMockLazyLoader = class(TInterfacedObject, ILazyLoader)
  public
    LastLoadProperty: string;
    procedure Load(AInstance: TObject; const APropertyName: string);
    procedure LoadCollection(AEntity: TObject; const APropertyName: string);
  end;

  [TestFixture('ORM Architecture & Logic (D.2, D.3)')]
  TEntityArchitectureTests = class
  private
    Mock: ILazyLoader;
    FMockObj: TMockLazyLoader; // Direct reference for test assertions
    function FindEntity(const AEntities: IList<TEntityClassMetadata>; const AClassName: string): TEntityClassMetadata;
    function FindMember(AEntity: TEntityClassMetadata; const AMemberName: string): TEntityMemberMetadata;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure Test_AST_Parser_Detects_Complex_Relationships;
    [Test]
    procedure Test_LazyLoading_Proxy_Calls_ILazyLoader;
  end;

  [Proxy]
  TEmployee = class
  private
    FDepartment: TObject;
  public
    function GetDepartment: TObject; virtual;
    procedure SetDepartment(const Value: TObject); virtual;
    [Lazy]
    property Department: TObject read GetDepartment write SetDepartment;
  end;

  TDepartment = class
  public
    Name: string;
  end;

implementation

{ TMockLazyLoader }

procedure TMockLazyLoader.Load(AInstance: TObject; const APropertyName: string);
begin
  LastLoadProperty := APropertyName;
  
  if SameText(APropertyName, 'Department') and (AInstance is TEmployee) then
  begin
    TEmployee(AInstance).Department := TDepartment.Create;
    TDepartment(TEmployee(AInstance).Department).Name := 'Mock Department';
  end;
end;

procedure TMockLazyLoader.LoadCollection(AEntity: TObject; const APropertyName: string);
begin
  LastLoadProperty := APropertyName;
end;

{ TEmployee }

function TEmployee.GetDepartment: TObject;
begin
  Result := FDepartment;
end;

procedure TEmployee.SetDepartment(const Value: TObject);
begin
  FDepartment := Value;
end;

{ TEntityArchitectureTests }

procedure TEntityArchitectureTests.Setup;
begin
  FMockObj := TMockLazyLoader.Create;
  Mock := FMockObj; // ARC handles cleanup via 'Mock' interface variable
end;

function TEntityArchitectureTests.FindEntity(const AEntities: IList<TEntityClassMetadata>;
  const AClassName: string): TEntityClassMetadata;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to AEntities.Count - 1 do
    if SameText(AEntities[i].EntityClassName, AClassName) then
      Exit(AEntities[i]);
end;

function TEntityArchitectureTests.FindMember(AEntity: TEntityClassMetadata;
  const AMemberName: string): TEntityMemberMetadata;
var
  i: Integer;
begin
  Result := nil;
  if AEntity = nil then Exit;
  for i := 0 to AEntity.Members.Count - 1 do
    if SameText(AEntity.Members[i].Name, AMemberName) then
      Exit(AEntity.Members[i]);
end;

procedure TEntityArchitectureTests.Test_AST_Parser_Detects_Complex_Relationships;
var
  Parser: TEntityMetadataParser;
  TempFile: string;
  Source: TStringList;
  Entities: IList<TEntityClassMetadata>;
  Employee: TEntityClassMetadata;
  DeptMember: TEntityMemberMetadata;
  TasksMember: TEntityMemberMetadata;
  ContractMember: TEntityMemberMetadata;
begin
  TempFile := TPath.Combine(TPath.GetTempPath, 'Dext.Test.Employee.pas');
  Source := TStringList.Create;
  try
    Source.Add('unit Dext.Test.Employee;');
    Source.Add('interface');
    Source.Add('type');
    Source.Add('  [Table(''employees'')]');
    Source.Add('  TEmployee = class');
    Source.Add('  private');
    Source.Add('    FDept: TObject;');
    Source.Add('  public');
    Source.Add('    [PrimaryKey, AutoInc]');
    Source.Add('    Id: Integer;');
    Source.Add('    [Join(''dept_id'', ''id''), Include, BelongsTo]');
    Source.Add('    Department: TObject;');
    Source.Add('    [HasMany(''employee_id'')]');
    Source.Add('    Tasks: TList<TObject>;');
    Source.Add('    [HasOne]');
    Source.Add('    Contract: TObject;');
    Source.Add('  end;');
    Source.Add('implementation');
    Source.Add('end.');
    Source.SaveToFile(TempFile);

    Parser := TEntityMetadataParser.Create;
    try
      Entities := Parser.ParseUnit(TempFile);
      
      Employee := FindEntity(Entities, 'TEmployee');
      Should(Employee).NotBeNull;
      
      // Check Department (Join + Include + BelongsTo)
      DeptMember := FindMember(Employee, 'Department');
      Should(DeptMember).NotBeNull;
      Should(DeptMember.HasJoin).BeTrue;
      Should(DeptMember.HasInclude).BeTrue;
      Should(DeptMember.RelationType).Be('BelongsTo');
      Should(DeptMember.JoinColumn).Be('dept_id');
      Should(DeptMember.JoinTargetColumn).Be('id');

      // Check Tasks (HasMany)
      TasksMember := FindMember(Employee, 'Tasks');
      Should(TasksMember).NotBeNull;
      Should(TasksMember.RelationType).Be('HasMany');

      // Check Contract (HasOne)
      ContractMember := FindMember(Employee, 'Contract');
      Should(ContractMember).NotBeNull;
      Should(ContractMember.RelationType).Be('HasOne');
    finally
      Parser.Free;
      if FileExists(TempFile) then TFile.Delete(TempFile);
    end;
  finally
    Source.Free;
  end;
end;

procedure TEntityArchitectureTests.Test_LazyLoading_Proxy_Calls_ILazyLoader;
var
  Proxy: TClassProxy;
  Employee: TEmployee;
  Dept: TObject;
begin
  Proxy := TEntityProxyFactory.CreateProxyObject<TEmployee>(Mock);
  Should(Proxy).NotBeNull;
  
  Employee := TEmployee(Proxy.Instance);
  try
    Should(Employee).NotBeNull;
    
    // Accessing the lazy property should trigger the loader
    Dept := Employee.Department;
    try
      Should(Dept).NotBeNull;
      Should(TDepartment(Dept).Name).Be('Mock Department');

      // Check if the mock was called with the correct property name
      // Check if the mock was called with the correct property name
      Should(FMockObj.LastLoadProperty).Be('Department');
    finally
      // Dept is a regular object created by our Mock
      Dept.Free;
    end;
  finally
    // Note: In real ORM, TDbContext tracks this.
    // Here we manually free the Proxy, which will free the Instance too
    // because TEntityProxyFactory.CreateProxyObject uses OwnsInstance := True.
    Proxy.Free;
  end;
end;

end.
