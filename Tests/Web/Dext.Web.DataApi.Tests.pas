unit Dext.Web.DataApi.Tests;

{$RTTI EXPLICIT METHODS([vcPublic]) FIELDS([vcPublic])}

interface

uses
  System.SysUtils,
  Dext.Testing.Attributes,
  Dext.Assertions,
  Dext.Web.Interfaces,
  Dext.Web.Builder,
  Dext.Web.DataApi,
  Dext.Entity,
  System.Classes,
  Dext.Web.Pipeline,
  Dext.Core.SmartTypes,
  Dext.Json,
  Dext.Collections,
  Dext.Core.Reflection,
  System.Rtti;

type
  [DataApi] // Deve resultar em /api/conventiontest
  TConventionTest = class(TPersistent)
  private
    FId: Integer;
    FName: string;
  public
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
  end;

  [DataApi('/api/custom')]
  TCustomPathTest = class(TPersistent)
  private
    FId: Integer;
  public
    property Id: Integer read FId write FId;
  end;

  TSmartEntityTest = class(TPersistent)
  private
    FId: Integer;
    FName: StringType;
    FAge: IntType;
  public
    property Id: Integer read FId write FId;
    property Name: StringType read FName write FName;
    property Age: IntType read FAge write FAge;
  end;

  TBaseCollisionEntity = class(TPersistent)
  protected
    FId: Integer;
  public
    property Id: Integer read FId write FId;
  end;

  TCollisionEntityTest = class(TBaseCollisionEntity)
  private
    FValue: string;
  public
    property ID: Integer read FId write FId;
    property Value: string read FValue write FValue;
  end;

  [TestFixture('DataAPI List Serialization Tests')]
  TDataApiSerializationTests = class
  public
    [Test('Should serialize SmartEntity with populated values')]
    procedure Should_Serialize_SmartEntity_With_Populated_Values;
    [Test('Should serialize SmartEntity with uninitialized/null values without AV')]
    procedure Should_Serialize_SmartEntity_With_Null_Values;
    [Test('Should serialize entity with naming collisions without Access Violation')]
    procedure Should_Serialize_CollisionEntity_Without_Access_Violation;
  end;

  [TestFixture('DataAPI RTTI Convention Tests')]
  TDataApiConventionTests = class
  public
    [Test('Should register APIs automatically using [DataApi] attribute')]
    procedure Should_Register_Apis_By_Attribute_Convention;
    [Test('Should respect custom path defined in [DataApi] attribute')]
    procedure Should_Respect_Custom_Path_In_Attribute;
    [Test('Should strip "T" prefix from class name by default')]
    procedure Should_Strip_T_Prefix_From_Class_Name;
  end;

implementation

uses
  Dext.Web.Routing;

{ TDataApiSerializationTests }

procedure TDataApiSerializationTests.Should_Serialize_SmartEntity_With_Populated_Values;
var
  List: IList<TSmartEntityTest>;
  Entity: TSmartEntityTest;
  Serializer: TDextSerializer;
  Json: string;
begin
  List := TCollections.CreateList<TSmartEntityTest>(True);
  Entity := TSmartEntityTest.Create;
  Entity.Id := 1;
  Entity.Name := 'John Doe';
  Entity.Age := 30;
  List.Add(Entity);

  Serializer := TDextSerializer.Create(TJsonSettings.Default);
  try
    Json := Serializer.Serialize(TValue.From<IObjectList>(List as IObjectList));
    Should(Json).Contain('"Id":1');
    Should(Json).Contain('"Name":"John Doe"');
    Should(Json).Contain('"Age":30');
  finally
    Serializer.Free;
  end;
end;

procedure TDataApiSerializationTests.Should_Serialize_SmartEntity_With_Null_Values;
var
  List: IList<TSmartEntityTest>;
  Entity: TSmartEntityTest;
  Serializer: TDextSerializer;
  Json: string;
begin
  List := TCollections.CreateList<TSmartEntityTest>(True);
  Entity := TSmartEntityTest.Create;
  Entity.Id := 2;
  List.Add(Entity);

  Serializer := TDextSerializer.Create(TJsonSettings.Default);
  try
    Json := Serializer.Serialize(TValue.From<IObjectList>(List as IObjectList));
    Should(Json).Contain('"Id":2');
    Should(Json).Contain('"Name":""');
    Should(Json).Contain('"Age":0');
  finally
    Serializer.Free;
  end;
end;

procedure TDataApiSerializationTests.Should_Serialize_CollisionEntity_Without_Access_Violation;
var
  List: IList<TCollisionEntityTest>;
  Entity: TCollisionEntityTest;
  Serializer: TDextSerializer;
  Json: string;
begin
  TReflection.GetMetadata(TypeInfo(TCollisionEntityTest)).GetHandlerBySnakeCase('id');

  List := TCollections.CreateList<TCollisionEntityTest>(True);
  Entity := TCollisionEntityTest.Create;
  Entity.Id := 10;
  Entity.Value := 'Test';
  List.Add(Entity);

  Serializer := TDextSerializer.Create(TJsonSettings.Default);
  try
    Json := Serializer.Serialize(TValue.From<IObjectList>(List as IObjectList));
    Should(Json).Contain('"Value":"Test"');
  finally
    Serializer.Free;
  end;
end;

procedure TDataApiConventionTests.Should_Register_Apis_By_Attribute_Convention;
var
  App: IApplicationBuilder;
  Routes: TArray<TEndpointMetadata>;
  Found: Boolean;
  Route: TEndpointMetadata;
begin
  App := TApplicationBuilder.Create(nil);
  
  // Act
  TDataApi.MapAll(App); 
  
  // Assert
  Routes := App.GetRoutes;
  Found := False;
  for Route in Routes do
    if Route.Path.StartsWith('/api/conventiontest') then
    begin
      Found := True;
      Break;
    end;
    
  Should(Found).BeTrue;
end;

procedure TDataApiConventionTests.Should_Respect_Custom_Path_In_Attribute;
var
  App: IApplicationBuilder;
  Routes: TArray<TEndpointMetadata>;
  Found: Boolean;
  Route: TEndpointMetadata;
begin
  App := TApplicationBuilder.Create(nil);
  
  // Act
  TDataApi.MapAll(App);
  
  // Assert
  Routes := App.GetRoutes;
  Found := False;
  for Route in Routes do
    if Route.Path.StartsWith('/api/custom') then
    begin
      Found := True;
      Break;
    end;
    
  Should(Found).BeTrue;
end;

procedure TDataApiConventionTests.Should_Strip_T_Prefix_From_Class_Name;
var
  App: IApplicationBuilder;
  Routes: TArray<TEndpointMetadata>;
  Found: Boolean;
  Route: TEndpointMetadata;
begin
  App := TApplicationBuilder.Create(nil);
  
  TDataApi.MapAll(App);
  
  Routes := App.GetRoutes;
  Found := False;
  for Route in Routes do
    if Route.Path.Equals('/api/conventiontest') then // Sem o 'T'
    begin
      Found := True;
      Break;
    end;
    
  Should(Found).BeTrue;
end;

initialization
  RegisterClass(TConventionTest);
  RegisterClass(TCustomPathTest);
  RegisterClass(TSmartEntityTest);
  RegisterClass(TBaseCollisionEntity);
  RegisterClass(TCollisionEntityTest);

end.
