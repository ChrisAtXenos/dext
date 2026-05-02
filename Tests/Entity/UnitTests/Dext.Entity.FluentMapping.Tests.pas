unit Dext.Entity.FluentMapping.Tests;

interface

uses
  Dext.Testing.Attributes,
  Dext.Assertions,
  Dext.Entity,
  Dext.Entity.Mapping,
  Dext.Entity.Core,
  Dext.Entity.Dialects,
  Dext.Entity.Attributes,
  Dext.Entity.ProxyFactory,
  Dext.Entity.Context,
  Dext.Entity.Setup,
  FireDAC.Comp.Client,
  FireDAC.Stan.Intf,
  FireDAC.Phys.SQLite,
  System.SysUtils;

type
  TFluentOrder = class;

  TFluentCustomer = class
  private
    FId: Integer;
    FName: string;
  public
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
  end;

  TFluentOrder = class
  private
    FId: Integer;
    FCustomerId: Integer;
    FDescription: string;
    FCreatedAt: TDateTime;
    FVersion: Integer;
    FCustomer: TFluentCustomer;
  public
    property Id: Integer read FId write FId;
    property CustomerId: Integer read FCustomerId write FCustomerId;
    property Description: string read FDescription write FDescription;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    property Version: Integer read FVersion write FVersion;
    
    // Auto-Proxy requirement: virtual getter
    function GetCustomer: TFluentCustomer; virtual;
    property Customer: TFluentCustomer read GetCustomer;
  end;

  TFluentMappingConfig = class(TEntityTypeConfiguration<TFluentOrder>)
  public
    procedure Configure(Builder: IEntityTypeBuilder<TFluentOrder>); override;
  end;

  [TestFixture]
  TFluentMappingTests = class
  public
    [Test]
    [Description('Verify typed property selectors in Fluent API')]
    procedure TestTypedSelectors;

    [Test]
    [Description('Verify Auto-Proxy creation for IsLazy properties')]
    procedure TestAutoProxyDetection;

    [Test]
    [Description('Verify Audit and Version markers in Mapping')]
    procedure TestMappingMarkers;

    [Test]
    [Description('Verify real proxy interception and loading')]
    procedure TestFunctionalAutoProxy;
  end;

implementation

{ TFluentOrder }

function TFluentOrder.GetCustomer: TFluentCustomer;
begin
  Result := FCustomer;
end;

{ TFluentMappingConfig }

procedure TFluentMappingConfig.Configure(Builder: IEntityTypeBuilder<TFluentOrder>);
begin
  Builder.ToTable('Orders');
  Builder.HasKey('Id');  
  Builder.Prop('Description').HasColumnName('Desc');
  Builder.Prop('CreatedAt').IsCreatedAt;
  Builder.Prop('Version').IsVersion;
  Builder.Prop('Customer').IsLazy;
end;

{ TFluentMappingTests }

procedure TFluentMappingTests.TestTypedSelectors;
var
  Model: TModelBuilder;
  Map: TEntityMap;
  Prop: TPropertyMap;
begin
  Model := TModelBuilder.Create;
  try
    Model.ApplyConfiguration<TFluentOrder>(TFluentMappingConfig.Create);
    Map := TEntityMap(Model.GetMap(TypeInfo(TFluentOrder)));
    
    Should(Map.TableName).Be('Orders');
    
    // Check property override by name
    if Map.Properties.TryGetValue('Description', Prop) then
      Should(Prop.ColumnName).Be('Desc')
    else
      Assert.Fail('Property Description not found in Map');
  finally
    Model.Free;
  end;
end;

procedure TFluentMappingTests.TestAutoProxyDetection;
var
  Model: TModelBuilder;
  Map: TEntityMap;
  Prop: TPropertyMap;
begin
  Model := TModelBuilder.Create;
  try
    Model.ApplyConfiguration<TFluentOrder>(TFluentMappingConfig.Create);
    
    // Manual check for NeedsProxy
    // In a real scenario, this is called by TDbSet via TEntityProxyFactory
    // But here we can't easily mock IDbContext perfectly without more code, 
    // so we verify the map flag which is the trigger.
    
    Map := TEntityMap(Model.GetMap(TypeInfo(TFluentOrder)));
    Map.Properties.TryGetValue('Customer', Prop);
    
    Should(Prop.IsLazy).BeTrue;
  finally
    Model.Free;
  end;
end;

procedure TFluentMappingTests.TestMappingMarkers;
var
  Model: TModelBuilder;
  Map: TEntityMap;
  Prop: TPropertyMap;
begin
  Model := TModelBuilder.Create;
  try
    Model.ApplyConfiguration<TFluentOrder>(TFluentMappingConfig.Create);
    Map := TEntityMap(Model.GetMap(TypeInfo(TFluentOrder)));
    
    Map.Properties.TryGetValue('CreatedAt', Prop);
    Should(Prop.IsCreatedAt).BeTrue;
    
    Map.Properties.TryGetValue('Version', Prop);
    Should(Prop.IsVersion).BeTrue;
  finally
    Model.Free;
  end;
end;

procedure TFluentMappingTests.TestFunctionalAutoProxy;
var
  Options: TDbContextOptions;
  Ctx: TDbContext;
  Order: TFluentOrder;
  Cust: TFluentCustomer;
  Ord: TFluentOrder;
  LoadedCustomer: TFluentCustomer;
begin
  // Set up an in-memory context with the configuration
  Options := TDbContextOptions.Create;
  try
    Options.UseSQLite(':memory:');
    Ctx := TDbContext.Create(Options, nil);
    try
      // 1. Configure Mapping
      Ctx.ModelBuilder.ApplyConfiguration<TFluentOrder>(TFluentMappingConfig.Create);
      Ctx.ModelBuilder.Entity<TFluentCustomer>(); // Register second entity needed for the test
      
      // Ensure schema exists (Dext simple schema creation)
      Ctx.EnsureCreated;
      
      // 2. Seed data
      Cust := TFluentCustomer.Create;
      Cust.Id := 10;
      Cust.Name := 'Cesar';
      Ctx.Entities<TFluentCustomer>.Add(Cust);

      Ord := TFluentOrder.Create;
      Ord.Id := 1;
      Ord.CustomerId := 10;
      Ord.Description := 'Test Auto Proxy';
      Ctx.Entities<TFluentOrder>.Add(Ord);
      
      Ctx.SaveChanges;
      
      // 3. Test Lazy Load
      Ctx.DetachAll; // Clear cache
      
      // This should return a Proxy
      Order := Ctx.Entities<TFluentOrder>.Find(1);
      
      Should(Order).NotBeNull;
      // Depending on implementation, proxy might be a subclass or wrapper.
      // We check if it's the requested type first.
      Should(Order).BeOfType<TFluentOrder>;
      
      // Act: Access the virtual property
      LoadedCustomer := Order.Customer;
      
      // Assert
      Should(LoadedCustomer).NotBeNull;
      Should(LoadedCustomer.Id).Be(10);
      Should(LoadedCustomer.Name).Be('Cesar');     
    finally
      Ctx.Free;
    end;
  finally
    Options.Free;
  end;
end;

end.
