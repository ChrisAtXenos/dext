unit EntityDemo.TypeConverterExample;

{***************************************************************************}
{                                                                           }
{  Example: Using TypeConverterAttribute for property-level conversion      }
{                                                                           }
{  This demonstrates how to use [TypeConverter] to override the default     }
{  type conversion for a specific property, without affecting other         }
{  properties of the same type.                                             }
{                                                                           }
{***************************************************************************}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  Dext.Entity,
  Dext.Entity.TypeConverters;

type
  /// <summary>
  ///   Example custom converter: Multiplies Integer by 1000 when storing.
  ///   This is a simple demonstration that the custom converter is actually
  ///   being used for the property.
  /// </summary>
  TMultiplyConverter = class(TTypeConverterBase)
  public
    function CanConvert(ATypeInfo: PTypeInfo): Boolean; override;
    function ToDatabase(const AValue: TValue; ADialect: TDatabaseDialect): TValue; override;
    function FromDatabase(const AValue: TValue; ATypeInfo: PTypeInfo): TValue; override;
  end;

  /// <summary>
  ///   Example entity demonstrating TypeConverterAttribute usage.
  ///   Two Integer properties with different storage:
  ///   - ValueMultiplied: Stored as value * 1000 using custom converter
  ///   - ValueNormal: Stored as-is (no custom converter)
  /// </summary>
  [Table('converter_test')]
  TConverterTestEntity = class
  private
    FId: Integer;
    FName: string;
    FValueMultiplied: Integer;
    FValueNormal: Integer;
  public
    [PK, AutoInc]
    property Id: Integer read FId write FId;
    
    [MaxLength(255)]
    property Name: string read FName write FName;
    
    /// <summary>
    ///   Stored as value * 1000 using custom converter
    /// </summary>
    [Column('value_multiplied'), TypeConverter(TMultiplyConverter)]
    property ValueMultiplied: Integer read FValueMultiplied write FValueMultiplied;
    
    /// <summary>
    ///   Stored as-is (no custom converter)
    /// </summary>
    [Column('value_normal')]
    property ValueNormal: Integer read FValueNormal write FValueNormal;
  end;

implementation

{ TMultiplyConverter }

function TMultiplyConverter.CanConvert(ATypeInfo: PTypeInfo): Boolean;
begin
  Result := ATypeInfo = TypeInfo(Integer);
end;

function TMultiplyConverter.ToDatabase(const AValue: TValue; ADialect: TDatabaseDialect): TValue;
var
  V: Integer;
begin
  if AValue.IsEmpty then
    Exit(TValue.From<Integer>(0));
    
  V := AValue.AsInteger;
  // Multiply by 1000 when storing
  Result := TValue.From<Integer>(V * 1000);
end;

function TMultiplyConverter.FromDatabase(const AValue: TValue; ATypeInfo: PTypeInfo): TValue;
var
  V: Integer;
begin
  if AValue.IsEmpty then
    Exit(TValue.From<Integer>(0));
    
  V := AValue.AsInteger;
  // Divide by 1000 when loading
  Result := TValue.From<Integer>(V div 1000);
end;

end.
