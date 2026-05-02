unit Dext.Entity.FormatSettings.Tests;

interface

{$I Dext.inc}

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  Dext.Assertions,
  Dext.Testing.Attributes,
  Dext.Entity.DataSet,
  Dext.Entity.Attributes,
  Dext.Core.DateUtils,
  Dext.Collections;

type
  [Table('format_test_products')]
  TFormatTestProduct = class
  private
    FId: Integer;
    FCreatedAt: TDateTime;
    FPrice: Double;
  public
    [PrimaryKey, Column('id')]
    property Id: Integer read FId write FId;
    [Column('created_at')]
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    [Column('price')]
    property Price: Double read FPrice write FPrice;
    
    constructor Create(AId: Integer; ACreatedAt: TDateTime; APrice: Double);
  end;

  [TestFixture('TEntityDataSet Format Settings Support')]
  TEntityFormatSettingsTests = class
  private
    FDataSet: TEntityDataSet;
    procedure PopulateDataSet;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Test_Export_With_Invariant_DecimalSeparator;
    
    [Test]
    procedure Test_Import_From_Json_Should_Handle_Dot_Decimal_Regardless_Of_OS_Locale;

    [Test]
    procedure Test_TryParseCommonDate_Should_Handle_German_Locale_Issue_101;
  end;

implementation

uses
  Dext.Json;

{ TFormatTestProduct }

constructor TFormatTestProduct.Create(AId: Integer; ACreatedAt: TDateTime; APrice: Double);
begin
  FId := AId;
  FCreatedAt := ACreatedAt;
  FPrice := APrice;
end;

{ TEntityFormatSettingsTests }

procedure TEntityFormatSettingsTests.Setup;
begin
  FDataSet := TEntityDataSet.Create(nil);
end;

procedure TEntityFormatSettingsTests.TearDown;
begin
  FDataSet.Free;
end;

procedure TEntityFormatSettingsTests.PopulateDataSet;
var
  L: IList<TFormatTestProduct>;
begin
  L := TCollections.CreateList<TFormatTestProduct>(False);
  L.Add(TFormatTestProduct.Create(1, EncodeDate(2026, 10, 15) + EncodeTime(14, 30, 0, 0), 1234.56));
  
  FDataSet.Load<TFormatTestProduct>(L, True);
  FDataSet.Open;
end;

procedure TEntityFormatSettingsTests.Test_Export_With_Invariant_DecimalSeparator;
var
  JsonStr: string;
  OldSettings: TFormatSettings;
begin
  // Save OS format
  OldSettings := FormatSettings;
  try
    // Force a comma separator (e.g., pt-BR or de-DE) to ensure JSON exporter ignores it
    FormatSettings.DecimalSeparator := ',';
    FormatSettings.ThousandSeparator := '.';

    PopulateDataSet;
    
    JsonStr := FDataSet.AsJsonArray;
    
    // JSON must always use '.' for decimals
    Should(JsonStr).Contain('"Price":1234.56');
    Should(JsonStr).NotContain('"Price":1234,56');
    Should(JsonStr).NotContain('"Price":"1234,56"');
  finally
    // Restore
    FormatSettings := OldSettings;
  end;
end;

procedure TEntityFormatSettingsTests.Test_Import_From_Json_Should_Handle_Dot_Decimal_Regardless_Of_OS_Locale;
var
  JsonStr: string;
  OldSettings: TFormatSettings;
begin
  // Save OS format
  OldSettings := FormatSettings;
  try
    // Force a comma separator
    FormatSettings.DecimalSeparator := ','  ;
    FormatSettings.ThousandSeparator := '.';

    JsonStr := '[{"Id":2,"CreatedAt":"2026-10-15T14:30:00","Price":999.99}]';
    
    FDataSet.LoadFromJson<TFormatTestProduct>(JsonStr);
    FDataSet.Open;
    FDataSet.First;
    
    // Should parse the dot correctly even if OS uses comma
    Should(FDataSet.FieldByName('Price').AsFloat).Be(999.99);
  finally
    // Restore
    FormatSettings := OldSettings;
  end;
end;

procedure TEntityFormatSettingsTests.Test_TryParseCommonDate_Should_Handle_German_Locale_Issue_101;
var
  ParsedDate: TDateTime;
  IsSuccess: Boolean;
  GermanFS: TFormatSettings;
  ExpectedDate: TDateTime;
begin
  // The issue was that DateUtils failed to parse when OS had a different date separator.
  // We simulate a German/European locale context explicitly
  GermanFS := TFormatSettings.Create;
  GermanFS.DateSeparator := '.';
  GermanFS.ShortDateFormat := 'dd.mm.yyyy';
  
  // Try to parse using our explicit context overload
  IsSuccess := TryParseCommonDate('15.10.2026', ParsedDate, GermanFS);
  
  ExpectedDate := EncodeDate(2026, 10, 15);
  
  Should(IsSuccess).Because('Should parse German date format using custom FormatSettings').BeTrue;
  Should(ParsedDate).Be(ExpectedDate);
end;

end.
