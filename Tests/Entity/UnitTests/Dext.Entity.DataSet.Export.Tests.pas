unit Dext.Entity.DataSet.Export.Tests;

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  Dext.Testing,
  Dext.Entity.DataSet,
  Dext.Entity.Attributes,
  Dext.Collections,
  Dext.Json;

type
  [Table('export_products')]
  TExportProduct = class
  private
    FId: Integer;
    FName: string;
    FCategory: string;
    FPrice: Double;
  public
    [PrimaryKey, Column('id')]
    property Id: Integer read FId write FId;
    [Column('name')]
    property Name: string read FName write FName;
    [Column('category')]
    property Category: string read FCategory write FCategory;
    [Column('price')]
    property Price: Double read FPrice write FPrice;
    
    constructor Create(AId: Integer; const AName: string; const ACategory: string; APrice: Double);
  end;

  [TestFixture('TEntityDataSet Export Features')]
  TEntityDataSetExportTests = class
  private
    FDataSet: TEntityDataSet;
    procedure PopulateDataSet;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Test_AsJsonArray_Full;
    [Test]
    procedure Test_AsJsonArray_Filtered;
    [Test]
    procedure Test_AsJsonArray_Sorted;
    [Test]
    procedure Test_AsJsonArray_FilteredAndSorted;
    [Test]
    procedure Test_AsJsonObject_CurrentRecord;
  end;

implementation

{ TExportProduct }

constructor TExportProduct.Create(AId: Integer; const AName: string; const ACategory: string; APrice: Double);
begin
  FId := AId;
  FName := AName;
  FCategory := ACategory;
  FPrice := APrice;
end;

{ TEntityDataSetExportTests }

procedure TEntityDataSetExportTests.Setup;
begin
  FDataSet := TEntityDataSet.Create(nil);
end;

procedure TEntityDataSetExportTests.TearDown;
begin
  FDataSet.Free;
end;

procedure TEntityDataSetExportTests.PopulateDataSet;
var
  L: IList<TExportProduct>;
begin
  L := TCollections.CreateList<TExportProduct>(False); // NÃ£o assumir a posse aqui
  L.Add(TExportProduct.Create(1, 'Notebook', 'Tech', 5000));
  L.Add(TExportProduct.Create(2, 'Smartphone', 'Tech', 3000));
  L.Add(TExportProduct.Create(3, 'Monitor', 'Hardware', 1500));
  L.Add(TExportProduct.Create(4, 'Mouse', 'Hardware', 100));
  L.Add(TExportProduct.Create(5, 'Keyboard', 'Hardware', 200));
  
  FDataSet.Load<TExportProduct>(L, True); // DataSet assume a posse
  FDataSet.Open;
end;

procedure TEntityDataSetExportTests.Test_AsJsonArray_Full;
var
  Json: string;
begin
  PopulateDataSet;
  
  Json := FDataSet.AsJsonArray;
  
  Should(Json).Contain('"Name":"Notebook"');
  Should(Json).Contain('"Name":"Smartphone"');
  Should(Json).Contain('"Name":"Monitor"');
  Should(Json).Contain('"Name":"Mouse"');
  Should(Json).Contain('"Name":"Keyboard"');
end;

procedure TEntityDataSetExportTests.Test_AsJsonArray_Filtered;
var
  Json: string;
begin
  PopulateDataSet;
  
  FDataSet.Filter := 'Category = ''Hardware''';
  FDataSet.Filtered := True;
  
  Json := FDataSet.AsJsonArray;
  
  Should(Json).NotContain('"Name":"Notebook"');
  Should(Json).NotContain('"Name":"Smartphone"');
  Should(Json).Contain('"Name":"Monitor"');
  Should(Json).Contain('"Name":"Mouse"');
  Should(Json).Contain('"Name":"Keyboard"');
end;

procedure TEntityDataSetExportTests.Test_AsJsonArray_Sorted;
var
  Json: string;
begin
  PopulateDataSet;
  
  FDataSet.IndexFieldNames := 'Name';
  
  Json := FDataSet.AsJsonArray;
  
  // Ordem alfabÃ©tica: Keyboard, Monitor, Mouse, Notebook, Smartphone
  Should(Json.IndexOf('Keyboard')).BeLessThan(Json.IndexOf('Monitor'));
  Should(Json.IndexOf('Monitor')).BeLessThan(Json.IndexOf('Mouse'));
  Should(Json.IndexOf('Mouse')).BeLessThan(Json.IndexOf('Notebook'));
  Should(Json.IndexOf('Notebook')).BeLessThan(Json.IndexOf('Smartphone'));
end;

procedure TEntityDataSetExportTests.Test_AsJsonArray_FilteredAndSorted;
var
  Json: string;
begin
  PopulateDataSet;
  
  FDataSet.Filter := 'Price > 200';
  FDataSet.Filtered := True;
  FDataSet.IndexFieldNames := 'Price DESC';
  
  Json := FDataSet.AsJsonArray;
  
  //Notebook (5000), Smartphone (3000), Monitor (1500)
  Should(Json).Contain('Notebook');
  Should(Json).Contain('Smartphone');
  Should(Json).Contain('Monitor');
  Should(Json).NotContain('Mouse');
  Should(Json).NotContain('Keyboard');
  
  Should(Json.IndexOf('Notebook')).BeLessThan(Json.IndexOf('Smartphone'));
  Should(Json.IndexOf('Smartphone')).BeLessThan(Json.IndexOf('Monitor'));
end;

procedure TEntityDataSetExportTests.Test_AsJsonObject_CurrentRecord;
var
  Json: string;
begin
  PopulateDataSet;
  
  FDataSet.First;
  FDataSet.Next; // Smartphone
  
  Json := FDataSet.AsJsonObject;
  
  Should(Json).Contain('"Name":"Smartphone"');
  Should(Json).NotContain('Notebook');
end;

end.
