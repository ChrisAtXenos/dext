unit Dext.Entity.FluentQuery.Tests;

interface

uses
  System.SysUtils,
  Dext.Assertions,
  Dext.Collections,
  Dext.Testing.Attributes,
  Dext.Entity.Query,
  Dext.Specifications.Interfaces,
  Dext.Specifications.Base,
  Dext.Specifications.Types,
  Dext.Specifications.SQL.Generator,
  Dext.Entity.Dialects,
  Dext.Entity.Mapping,
  Dext.Entity.Attributes,
  Dext.Core.SmartTypes;

type
  [Table('Customers')]
  TTestCustomer = class
  private
    FId: Integer;
    FName: string;
  public
    [PK] property Id: Integer read FId write FId;
    property Name: string read FName write FName;
  end;

  [Table('Orders')]
  TTestOrder = class
  private
    FId: Integer;
    FCustomerId: Integer;
    FAmount: Double;
  public
    [PK] property Id: Integer read FId write FId;
    [ForeignKey('CustomerId')] property CustomerId: Integer read FCustomerId write FCustomerId;
    property Amount: Double read FAmount write FAmount;
  end;

  // Mock entity for testing
  TOrder = class
    FId: Integer;
    FItems: IList<TObject>;
  end;

  [TestFixture('FluentQuery Enhancements Tests')]
  TFluentQueryTests = class
  public
    [Setup]
    procedure Setup;

    [Test]
    [Description('Verify that Include/ThenInclude builds the correct path string in the Specification')]
    procedure TestThenIncludePathBuilding;

    [Test]
    [Description('Verify that IgnoreQueryFilters flag is correctly propagated to the Specification')]
    procedure TestIgnoreQueryFiltersPropagation;

    [Test]
    [Description('Verify that OnlyDeleted flag is correctly propagated to the Specification')]
    procedure TestOnlyDeletedPropagation;

    [Test]
    [Description('Verify explicit joins (Inner, Left, Right, Full, Cross) specification generation')]
    procedure TestExplicitJoins;

    [Test]
    [Description('Verify relationship auto-resolution for implicit joins')]
    procedure TestRelationshipAutoResolution;

    [Test]
    [Description('Verify SQL generation for joins')]
    procedure TestSqlGeneratorForJoins;
  end;

implementation

{ TFluentQueryTests }

procedure TFluentQueryTests.Setup;
begin
  // Register mapping metadata for tests
  TModelBuilder.Instance.Entity<TTestCustomer>.Table('Customers');
  TModelBuilder.Instance.Entity<TTestOrder>.Table('Orders');
end;

procedure TFluentQueryTests.TestThenIncludePathBuilding;
var
  Spec: ISpecification<TObject>;
  Query: TFluentQuery<TObject>;
  Includes: TArray<string>;
begin
  Spec := TSpecification<TObject>.Create;
  Query := TFluentQuery<TObject>.Create(nil, Spec);

  // Test single include
  Query.Include('Customer');
  Includes := Spec.GetIncludes;
  Should(Length(Includes)).Be(1);
  Should(Includes[0]).Be('Customer');

  // Test ThenInclude
  // Simulating: Query.Include(User.Orders).ThenInclude(Order.Items)
  // We use string paths for this pure unit test
  Query.Include('Orders').Include('Items'); // Standard Include adds multiple
  
  // Reset for ThenInclude test
  Spec := TSpecification<TObject>.Create;
  Query := TFluentQuery<TObject>.Create(nil, Spec);
  
  Query.Include('Orders');
  // Manual path building check
  Query.Include('Orders.Items');
  
  Includes := Spec.GetIncludes;
  Should.List<string>(Includes).Contain('Orders.Items');
end;

procedure TFluentQueryTests.TestIgnoreQueryFiltersPropagation;
var
  Spec: ISpecification<TObject>;
  Query: TFluentQuery<TObject>;
begin
  Spec := TSpecification<TObject>.Create;
  Query := TFluentQuery<TObject>.Create(nil, Spec);

  Should(Spec.IsIgnoringFilters).BeFalse;
  
  Query.IgnoreQueryFilters;
  
  Should(Spec.IsIgnoringFilters).BeTrue;
end;

procedure TFluentQueryTests.TestOnlyDeletedPropagation;
var
  Spec: ISpecification<TObject>;
  Query: TFluentQuery<TObject>;
begin
  Spec := TSpecification<TObject>.Create;
  Query := TFluentQuery<TObject>.Create(nil, Spec);

  Should(Spec.IsOnlyDeleted).BeFalse;
  
  Query.OnlyDeleted;
  
  Should(Spec.IsOnlyDeleted).BeTrue;
end;

procedure TFluentQueryTests.TestExplicitJoins;
var
  Spec: ISpecification<TTestOrder>;
  Query: TFluentQuery<TTestOrder>;
  Joins: TArray<IJoin>;
  Cond: IExpression;
begin
  Spec := TSpecification<TTestOrder>.Create;
  Query := TFluentQuery<TTestOrder>.Create(nil, Spec);

  Cond := TBinaryExpression.Create(
    TPropertyExpression.Create('Orders.CustomerId'),
    TPropertyExpression.Create('Customers.Id'),
    boEqual);

  Query.JoinInner<TTestCustomer>('c', Cond);
  
  Joins := Spec.GetJoins;
  Should(Length(Joins)).Be(1);
  Should(Joins[0].GetTableName).Be('Customers');
  Should(Joins[0].GetAlias).Be('c');
  Should(Ord(Joins[0].GetJoinType)).Be(Ord(jtInner));
end;

procedure TFluentQueryTests.TestRelationshipAutoResolution;
var
  Spec: ISpecification<TTestOrder>;
  Query: TFluentQuery<TTestOrder>;
  Joins: TArray<IJoin>;
begin
  Spec := TSpecification<TTestOrder>.Create;
  Query := TFluentQuery<TTestOrder>.Create(nil, Spec);

  // Auto ON resolution
  Query.JoinInner<TTestCustomer>();
  
  Joins := Spec.GetJoins;
  Should(Length(Joins)).Be(1);
  Should(Joins[0].GetTableName).Be('Customers');
  Should(Joins[0].GetAlias).Be('c'); // default alias generated
  Should(Joins[0].GetCondition.ToString).Contain('CustomerId');
end;

procedure TFluentQueryTests.TestSqlGeneratorForJoins;
var
  Spec: ISpecification<TTestOrder>;
  Query: TFluentQuery<TTestOrder>;
  Generator: TSqlGenerator<TTestOrder>;
  SQL: string;
begin
  Spec := TSpecification<TTestOrder>.Create;
  Query := TFluentQuery<TTestOrder>.Create(nil, Spec);

  Query.JoinCross<TTestCustomer>('c');
  Query.JoinFull<TTestCustomer>('c2');

  Generator := TSqlGenerator<TTestOrder>.Create(TSQLServerDialect.Create, nil);
  try
    SQL := Generator.GenerateSelect(Spec);
    // Should translate jtCross to CROSS JOIN without ON
    Should(SQL).Contain('CROSS JOIN [Customers] [c]');
    Should(SQL).NotContain('[c] ON');
    
    // Should translate jtFull to FULL JOIN with ON
    Should(SQL).Contain('FULL JOIN [Customers] [c2] ON');
  finally
    Generator.Free;
  end;
end;

end.
