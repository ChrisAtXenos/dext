unit EntityDemo.Tests.TypeConverter;

{***************************************************************************}
{                                                                           }
{  Test: TypeConverterAttribute - Property-level Type Conversion            }
{                                                                           }
{  Demonstrates that [TypeConverter] on a property overrides the default    }
{  type converter for that specific property only.                          }
{                                                                           }
{***************************************************************************}

interface

uses
  System.SysUtils,
  EntityDemo.Tests.Base,
  EntityDemo.TypeConverterExample;

type
  TTypeConverterTest = class(TBaseTest)
  private
    procedure TestTypeConverterAttribute;
  public
    procedure Run; override;
  end;

implementation

uses
  Dext.Entity;

{ TTypeConverterTest }

procedure TTypeConverterTest.Run;
begin
  Log('');
  Log('===========================================');
  Log('📦 TypeConverterAttribute Test');
  Log('===========================================');

  TestTypeConverterAttribute;
end;

procedure TTypeConverterTest.TestTypeConverterAttribute;
var
  Entity: TConverterTestEntity;
  Loaded: TConverterTestEntity;
  EntityId: Integer;
  TestValue: Integer;
begin
  Log('');
  Log('🧪 Test: TypeConverter overrides global converter for specific property');

  // Test value
  TestValue := 42;

  // Insert an entity
  Entity := TConverterTestEntity.Create;
  Entity.Name := 'TypeConverter Test';
  Entity.ValueMultiplied := TestValue; // Will be stored as 42000 (x1000 converter)
  Entity.ValueNormal := TestValue;     // Will be stored as 42 (no converter)

  FContext.Entities<TConverterTestEntity>.Add(Entity);
  FContext.SaveChanges;

  EntityId := Entity.Id;
  Log(Format('  Inserted entity with Id=%d', [EntityId]));
  Log(Format('  ValueMultiplied input: %d (should be stored as %d in DB)', [TestValue, TestValue * 1000]));
  Log(Format('  ValueNormal input: %d (should be stored as %d in DB)', [TestValue, TestValue]));

  // Clear cache (this will also free managed entities)
  FContext.Clear;

  // Load the entity back
  Loaded := FContext.Entities<TConverterTestEntity>.Find(EntityId);

  AssertTrue(Loaded <> nil, 'Entity loaded successfully', 'Failed to load entity');

  if Loaded <> nil then
  begin
    Log(Format('  Loaded ValueMultiplied: %d', [Loaded.ValueMultiplied]));
    Log(Format('  Loaded ValueNormal: %d', [Loaded.ValueNormal]));

    // ValueMultiplied should be back to original (42 * 1000 / 1000 = 42)
    AssertTrue(
      Loaded.ValueMultiplied = TestValue,
      Format('ValueMultiplied converted correctly: stored %d, loaded %d', [TestValue * 1000, Loaded.ValueMultiplied]),
      Format('ValueMultiplied mismatch: expected %d, got %d', [TestValue, Loaded.ValueMultiplied])
    );

    // ValueNormal should be unchanged (42)
    AssertTrue(
      Loaded.ValueNormal = TestValue,
      Format('ValueNormal stored/loaded correctly: %d', [Loaded.ValueNormal]),
      Format('ValueNormal mismatch: expected %d, got %d', [TestValue, Loaded.ValueNormal])
    );
  end;

  Log('  ✅ TypeConverterAttribute test completed');
end;

end.
