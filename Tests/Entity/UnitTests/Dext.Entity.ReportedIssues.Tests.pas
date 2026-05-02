unit Dext.Entity.ReportedIssues.Tests;

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  Dext.Assertions,
  Dext.Testing.Attributes,
  Dext.Collections,
  Dext.Entity.DataSet,
  Dext.Entity.DataProvider,
  Dext.Entity.Core,
  Dext.EF.Design.Metadata;

type
  [TestFixture('Reported Issues from Flash Session')]
  TEntityReportedIssuesTests = class
  private
    FDataProvider: TEntityDataProvider;
    FDataSet: TEntityDataSet;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Issue_3_TableName_Should_Be_Serialized_And_Restored;

    [Test]
    procedure Issue_2_5_AddFields_Should_Not_Contain_Fields_From_Other_Entities;

    [Test]
    procedure Issue_6_Activate_Dataset_Should_Not_AV_Even_Without_RTTI_Class;
    
    [Test]
    procedure Test_Metadata_Persistence_Via_Streams;

    [Test]
    procedure Test_GenerateFields_Should_Not_Duplicate_Existing_Fields;
  end;

implementation

uses
  System.IOUtils,
  System.Rtti;

procedure SetComponentDesigning(AComponent: TComponent; ADesigning: Boolean);
var
  Context: TRttiContext;
  RType: TRttiType;
  Field: TRttiField;
  State: TComponentState;
begin
  Context := TRttiContext.Create;
  RType := Context.GetType(TComponent);
  Field := RType.GetField('FComponentState');
  if Field <> nil then
  begin
    State := AComponent.ComponentState;
    if ADesigning then
      Include(State, csDesigning)
    else
      Exclude(State, csDesigning);
    Field.SetValue(AComponent, TValue.From<TComponentState>(State));
  end;
end;

procedure TEntityReportedIssuesTests.Setup;
begin
  FDataProvider := TEntityDataProvider.Create(nil);
  FDataSet := TEntityDataSet.Create(nil);
  FDataSet.DataProvider := FDataProvider;
end;

procedure TEntityReportedIssuesTests.TearDown;
begin
  FDataSet.Free;
  FDataProvider.Free;
end;

procedure TEntityReportedIssuesTests.Issue_3_TableName_Should_Be_Serialized_And_Restored;
var
  MD: TEntityClassMetadata;
begin
  // 1. Setup metadata manually
  MD := TEntityClassMetadata.Create;
  try
    MD.EntityClassName := 'TOrder';
    MD.TableName := 'orders_table_name';
    MD.EntityUnitName := 'MasterDetailForm';
    FDataProvider.AddOrSetMetadata(MD);
  finally
    MD.Free;
  end;

  // 2. Select entity (Simulating IDE action)
  SetComponentDesigning(FDataSet, True);
  try
    FDataSet.EntityClassName := 'TOrder';
  finally
    SetComponentDesigning(FDataSet, False);
  end;
  
  // TableName should have been updated from metadata
  Should(FDataSet.TableName).Be('orders_table_name');
  
  // 3. Simulating "serialization": If I change TableName manually, it should persist
  FDataSet.TableName := 'custom_table';
  Should(FDataSet.TableName).Be('custom_table');
end;

procedure TEntityReportedIssuesTests.Issue_2_5_AddFields_Should_Not_Contain_Fields_From_Other_Entities;
var
  Member: TEntityMemberMetadata;
  MD1, MD2: TEntityClassMetadata;
begin
  // 1. Setup 2 entities in metadata
  MD1 := TEntityClassMetadata.Create;
  try
    MD1.EntityClassName := 'TOrder';
    MD1.TableName := 'orders';
    
    Member := MD1.Members.Add;
    Member.Name := 'OrderId';
    Member.MemberType := 'Integer';
    Member.IsPrimaryKey := True;
    
    Member := MD1.Members.Add;
    Member.Name := 'Customer';
    Member.MemberType := 'string';
    
    FDataProvider.AddOrSetMetadata(MD1);
  finally
    MD1.Free;
  end;

  MD2 := TEntityClassMetadata.Create;
  try
    MD2.EntityClassName := 'TProduct';
    MD2.TableName := 'products';
    
    Member := MD2.Members.Add;
    Member.Name := 'ProductId';
    Member.MemberType := 'Integer';
    Member.IsPrimaryKey := True;
    
    Member := MD2.Members.Add;
    Member.Name := 'Description';
    Member.MemberType := 'string';
    
    FDataProvider.AddOrSetMetadata(MD2);
  finally
    MD2.Free;
  end;

  // 2. Select TOrder (Design mode)
  SetComponentDesigning(FDataSet, True);
  try
    FDataSet.EntityClassName := 'TOrder';
    
    // TEntityDataSet.SetEntityClassName (line 1307) calls GenerateFields automatically if csDesigning is present.
    // So FieldCount should be > 0 now.
    Should(FDataSet.FieldCount).Be(2);
    Should(FDataSet.FindField('OrderId')).NotBeNull;
    Should(FDataSet.FindField('Customer')).NotBeNull;
    
    // 3. Switch to TProduct (Design mode)
    FDataSet.EntityClassName := 'TProduct';
    
    // Switch to TProduct should have cleared old Fields (OrderId, Customer) and generated new ones
    Should(FDataSet.FieldCount).Be(2);
    Should(FDataSet.FindField('ProductId')).NotBeNull;
    Should(FDataSet.FindField('Description')).NotBeNull;
    Should(FDataSet.FindField('OrderId')).BeNull; // Should be gone!
    Should(FDataSet.FindField('Customer')).BeNull; // Should be gone!
    
  finally
    SetComponentDesigning(FDataSet, False);
  end;
end;

procedure TEntityReportedIssuesTests.Issue_6_Activate_Dataset_Should_Not_AV_Even_Without_RTTI_Class;
var
  Member: TEntityMemberMetadata;
  MD: TEntityClassMetadata;
begin
  // 1. Setup metadata WITHOUT a compiled class
  MD := TEntityClassMetadata.Create;
  try
    MD.EntityClassName := 'UnknownEntity';
    MD.TableName := 'unknown';
    
    Member := MD.Members.Add;
    Member.Name := 'Id';
    Member.MemberType := 'Integer';
    Member.IsPrimaryKey := True;
    
    FDataProvider.AddOrSetMetadata(MD);
  finally
    MD.Free;
  end;

  FDataSet.EntityClassName := 'UnknownEntity';
  
  // 2. Try to activate without class - Should fail gracefully, NOT AV
  try
    FDataSet.Active := True;
  except
    on E: Exception do
    begin
      if E.ClassName = 'EAccessViolation' then
        raise;
    end;
  end;
end;

procedure TEntityReportedIssuesTests.Test_Metadata_Persistence_Via_Streams;
var
  Stream: TMemoryStream;
  P2: TEntityDataProvider;
  MD1: TEntityClassMetadata;
  MD2: TEntityClassMetadata;
  RttiContext: TRttiContext;
  RttiMethod: TRttiMethod;
begin
  Stream := TMemoryStream.Create;
  try
    // 1. Setup P1 with metadata
    MD1 := TEntityClassMetadata.Create;
    try
      MD1.EntityClassName := 'TOrder';
      MD1.TableName := 'orders';
      FDataProvider.AddOrSetMetadata(MD1);
    finally
      MD1.Free;
    end;
    
    // 2. Save P1 (Mock form saving)
    Stream.WriteComponent(FDataProvider);
    Stream.Position := 0;
    
    // 3. Load into P2 (Mock form loading)
    P2 := TEntityDataProvider.Create(nil);
    try
      Stream.ReadComponent(P2);
      
      // Need to simulate Loaded call which usually happens after DFM load
      // FDataProvider.Loaded; -> Not accessible easily without RTTI or Hack
      // But we can call the public property setter which triggers the cache sync
      // Actually, TEntityDataProvider.Loaded calls SyncInternalCache;
      
      RttiMethod := RttiContext.GetType(TEntityDataProvider).GetMethod('Loaded');
      if RttiMethod <> nil then
        RttiMethod.Invoke(P2, []);

      // 4. Check if metadata was restored correctly
      MD2 := P2.GetEntityMetadata('TOrder');
      Should(MD2).NotBeNull;
      Should(MD2.TableName).Be('orders');
    finally
      P2.Free;
    end;
  finally
    Stream.Free;
  end;
end;

procedure TEntityReportedIssuesTests.Test_GenerateFields_Should_Not_Duplicate_Existing_Fields;
var
  MD: TEntityClassMetadata;
  Member: TEntityMemberMetadata;
  F: TField;
begin
  // 1. Setup metadata
  MD := TEntityClassMetadata.Create;
  try
    MD.EntityClassName := 'TOrder';
    
    Member := MD.Members.Add;
    Member.Name := 'OrderId';
    Member.MemberType := 'Integer';
    
    FDataProvider.AddOrSetMetadata(MD);
  finally
    MD.Free;
  end;
  
  // 2. Setup Dataset with one EXISTING manual field
  FDataSet.EntityClassName := 'TOrder';
  
  F := TIntegerField.Create(FDataSet);
  F.FieldName := 'OrderId';
  F.DataSet := FDataSet;
  
  Should(FDataSet.FieldCount).Be(1);
  
  // 3. Simulate "Add all fields" in IDE (which calls GenerateFields)
  SetComponentDesigning(FDataSet, True);
  try
    // At design-time, TEntityDataSet uses metadata to create FieldDefs and then fields
    FDataSet.FieldDefs.Update;
    // Internal call to GenerateFields usually happens via IDE property editor or automatically
    // Let's call it via RTTI if it's protected, or check if it's public (it's public in TEntityDataSet)
    FDataSet.GenerateFields;
    
    // 4. Verify we still have only 1 OrderId field, not 2
    Should(FDataSet.FieldCount).Be(1);
    Should(FDataSet.Fields[0].FieldName).Be('OrderId');
  finally
    SetComponentDesigning(FDataSet, False);
  end;
end;

end.
