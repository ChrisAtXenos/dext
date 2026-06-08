unit Dext.Json.Utf8.Serializer.Tests;

{***************************************************************************}
{                                                                           }
{  Dext Framework - Unit Tests                                              }
{                                                                           }
{  Bug #93: Currency field not deserialized correctly when parsing JSON     }
{  to record via TUtf8JsonSerializer                                        }
{                                                                           }
{  Root Cause: Currency in Delphi is tkFloat with ftCurr sub-type.         }
{  It is stored internally as Int64 * 10000 (fixed-point, 4 decimal        }
{  places). The current deserializer treats it as a plain Double via        }
{  PDouble^ which writes raw IEEE-754 bits into the Currency memory slot,  }
{  producing a completely wrong value.                                      }
{                                                                           }
{  These tests are written BEFORE any fix so they are expected to FAIL     }
{  on the current codebase (regression / red phase of TDD).                }
{                                                                           }
{***************************************************************************}

interface

uses
  System.SysUtils,
  System.Classes,
  System.TypInfo,
  Dext.Testing.Attributes,
  Dext.Assertions,
  Dext.Core.Span,
  Dext.Json.Utf8.Serializer;

type
  // ---------------------------------------------------------
  // Record definitions used across test cases
  // ---------------------------------------------------------

  /// <summary>Exact reproduction of the record from bug report #93.</summary>
  TBugReportRecord = record
    descricao: string;
    vlrTaxa: Currency;
  end;

  /// <summary>Record with a single Currency field (isolates the type).</summary>
  TCurrencyOnlyRecord = record
    valor: Currency;
  end;

  /// <summary>Multiple Currency fields side-by-side.</summary>
  TMultiCurrencyRecord = record
    preco: Currency;
    desconto: Currency;
    total: Currency;
  end;

  /// <summary>Mixed field types including Currency, Integer, Double and Boolean.</summary>
  TMixedTypesRecord = record
    nome: string;
    quantidade: Integer;
    preco: Currency;
    peso: Double;
    ativo: Boolean;
  end;

  /// <summary>Record used to prove the Double workaround still compiles and works.</summary>
  TDoubleWorkaroundRecord = record
    descricao: string;
    vlrTaxa: Double;
  end;

  // ---------------------------------------------------------
  // Test fixture
  // ---------------------------------------------------------

  [TestFixture('Bug #93 - TUtf8JsonSerializer Currency Deserialization')]
  TUtf8SerializerCurrencyTests = class
  private
    class function DeserializeFromJson<T>(const AJSON: string): T; static;
  public
    // --- Bug Reproduction (from the issue report) ---

    [Test('TC-01 [BUG #93] Currency 8.00 should deserialize correctly')]
    procedure TestBugReport_Currency8_00;

    [Test('TC-02 [BUG #93] String field alongside Currency should both deserialize correctly')]
    procedure TestBugReport_StringFieldAlongsideCurrency;

    // --- Currency boundary and precision ---

    [Test('TC-03 Currency integer value 1 should produce 1.0000')]
    procedure TestCurrency_IntegerValue;

    [Test('TC-04 Currency zero value should produce 0.0000')]
    procedure TestCurrency_ZeroValue;

    [Test('TC-05 Currency with 4 decimal places (1.2345) should round-trip')]
    procedure TestCurrency_FourDecimalPlaces;

    [Test('TC-06 Currency large value (999999.99) should deserialize correctly')]
    procedure TestCurrency_LargeValue;

    [Test('TC-07 Currency negative value (-123.45) should deserialize correctly')]
    procedure TestCurrency_NegativeValue;

    // --- Multiple Currency fields ---

    [Test('TC-08 Multiple Currency fields in same record should all deserialize correctly')]
    procedure TestMultipleCurrencyFields;

    // --- Mixed types ---

    [Test('TC-09 Mixed record: Currency among other types - all fields correct')]
    procedure TestMixedTypes_AllFieldsCorrect;

    [Test('TC-10 Currency field must not corrupt an adjacent Double field in memory')]
    procedure TestCurrencyDoesNotCorruptAdjacentDouble;

    // --- Workaround verification ---

    [Test('TC-11 [WORKAROUND] Double field with same JSON produces the correct value')]
    procedure TestDoubleWorkaroundProducesCorrectValue;

    // --- Edge cases ---

    [Test('TC-12 Currency with scientific notation 1.5e2 should be 150.00')]
    procedure TestCurrency_ScientificNotation;

    [Test('TC-13 Currency field missing from JSON should default to 0')]
    procedure TestCurrency_MissingFieldDefaultsToZero;

    [Test('TC-14 Currency smallest non-zero value (0.0001) should round-trip')]
    procedure TestCurrency_SmallestNonZero;

    [Test('TC-15 Two Currency fields interleaved with strings should all be correct')]
    procedure TestCurrency_InterleavedWithStrings;
  end;

implementation

{ TUtf8SerializerCurrencyTests - Private Helpers }

class function TUtf8SerializerCurrencyTests.DeserializeFromJson<T>(const AJSON: string): T;
var
  LBytes: TBytes;
  LSpan: TByteSpan;
begin
  LBytes := TEncoding.UTF8.GetBytes(AJSON);
  LSpan  := TByteSpan.FromBytes(LBytes);
  Result := TUtf8JsonSerializer.Deserialize<T>(LSpan);
end;

{ TUtf8SerializerCurrencyTests - Test Implementations }

procedure TUtf8SerializerCurrencyTests.TestBugReport_Currency8_00;
// Exact reproduction from bug report #93
// Expected to FAIL on current codebase (bug not yet fixed)
var
  LRecord: TBugReportRecord;
begin
  LRecord := DeserializeFromJson<TBugReportRecord>(
    '{"descricao":"Minha descri\u00e7\u00e3o","vlrTaxa":8.00}');

  Should(LRecord.vlrTaxa = 8.00)
    .Because('Bug #93: vlrTaxa must be 8.00 after deserialization from JSON. ' +
             'Got: ' + CurrToStr(LRecord.vlrTaxa))
    .BeTrue;
end;

procedure TUtf8SerializerCurrencyTests.TestBugReport_StringFieldAlongsideCurrency;
var
  LRecord: TBugReportRecord;
begin
  LRecord := DeserializeFromJson<TBugReportRecord>(
    '{"descricao":"Minha descricao","vlrTaxa":8.00}');

  Should(LRecord.descricao).Be('Minha descricao');
  Should(LRecord.vlrTaxa = 8.00)
    .Because('vlrTaxa must be 8.00; got ' + CurrToStr(LRecord.vlrTaxa))
    .BeTrue;
end;

procedure TUtf8SerializerCurrencyTests.TestCurrency_IntegerValue;
var
  LRecord: TCurrencyOnlyRecord;
begin
  LRecord := DeserializeFromJson<TCurrencyOnlyRecord>('{"valor":1}');
  Should(LRecord.valor = 1.0)
    .Because('Integer JSON 1 should deserialize to Currency 1.0000; got ' +
             CurrToStr(LRecord.valor))
    .BeTrue;
end;

procedure TUtf8SerializerCurrencyTests.TestCurrency_ZeroValue;
var
  LRecord: TCurrencyOnlyRecord;
begin
  LRecord := DeserializeFromJson<TCurrencyOnlyRecord>('{"valor":0}');
  Should(LRecord.valor = 0.0)
    .Because('Zero JSON should deserialize to Currency 0.0000; got ' +
             CurrToStr(LRecord.valor))
    .BeTrue;
end;

procedure TUtf8SerializerCurrencyTests.TestCurrency_FourDecimalPlaces;
// Currency supports exactly 4 decimal places
var
  LRecord: TCurrencyOnlyRecord;
begin
  LRecord := DeserializeFromJson<TCurrencyOnlyRecord>('{"valor":1.2345}');
  Should(LRecord.valor = 1.2345)
    .Because('1.2345 fits exactly in Currency 4-decimal-place precision; got ' +
             CurrToStr(LRecord.valor))
    .BeTrue;
end;

procedure TUtf8SerializerCurrencyTests.TestCurrency_LargeValue;
var
  LRecord: TCurrencyOnlyRecord;
begin
  LRecord := DeserializeFromJson<TCurrencyOnlyRecord>('{"valor":999999.99}');
  Should(LRecord.valor = 999999.99)
    .Because('Expected 999999.99; got ' + CurrToStr(LRecord.valor))
    .BeTrue;
end;

procedure TUtf8SerializerCurrencyTests.TestCurrency_NegativeValue;
var
  LRecord: TCurrencyOnlyRecord;
begin
  LRecord := DeserializeFromJson<TCurrencyOnlyRecord>('{"valor":-123.45}');
  Should(LRecord.valor = -123.45)
    .Because('Expected -123.45; got ' + CurrToStr(LRecord.valor))
    .BeTrue;
end;

procedure TUtf8SerializerCurrencyTests.TestMultipleCurrencyFields;
var
  LRecord: TMultiCurrencyRecord;
begin
  LRecord := DeserializeFromJson<TMultiCurrencyRecord>(
    '{"preco":99.99,"desconto":10.00,"total":89.99}');

  Should(LRecord.preco = 99.99)
    .Because('preco: expected 99.99; got ' + CurrToStr(LRecord.preco))
    .BeTrue;
  Should(LRecord.desconto = 10.00)
    .Because('desconto: expected 10.00; got ' + CurrToStr(LRecord.desconto))
    .BeTrue;
  Should(LRecord.total = 89.99)
    .Because('total: expected 89.99; got ' + CurrToStr(LRecord.total))
    .BeTrue;
end;

procedure TUtf8SerializerCurrencyTests.TestMixedTypes_AllFieldsCorrect;
var
  LRecord: TMixedTypesRecord;
begin
  LRecord := DeserializeFromJson<TMixedTypesRecord>(
    '{"nome":"Produto A","quantidade":5,"preco":29.90,"peso":1.5,"ativo":true}');

  Should(LRecord.nome).Be('Produto A');
  Should(LRecord.quantidade).Be(5);
  Should(LRecord.preco = 29.90)
    .Because('preco: expected 29.90; got ' + CurrToStr(LRecord.preco))
    .BeTrue;
  Should(LRecord.peso).BeApproximately(1.5, 0.0001);
  Should(LRecord.ativo).BeTrue;
end;

procedure TUtf8SerializerCurrencyTests.TestCurrencyDoesNotCorruptAdjacentDouble;
// Even if Currency deserialization is wrong, it must not corrupt the adjacent Double
// in memory layout. This test isolates the memory-corruption side of the bug.
var
  LRecord: TMixedTypesRecord;
begin
  LRecord := DeserializeFromJson<TMixedTypesRecord>(
    '{"nome":"X","quantidade":1,"preco":10.00,"peso":2.5,"ativo":false}');

  Should(LRecord.peso)
    .Because('Double field "peso" must not be corrupted by adjacent Currency assignment')
    .BeApproximately(2.5, 0.001);
end;

procedure TUtf8SerializerCurrencyTests.TestDoubleWorkaroundProducesCorrectValue;
// This test MUST PASS (workaround from bug report - Double field in place of Currency)
var
  LRecord: TDoubleWorkaroundRecord;
begin
  LRecord := DeserializeFromJson<TDoubleWorkaroundRecord>(
    '{"descricao":"Teste","vlrTaxa":8.00}');

  Should(LRecord.descricao).Be('Teste');
  Should(LRecord.vlrTaxa).BeApproximately(8.00, 0.0001);
end;

procedure TUtf8SerializerCurrencyTests.TestCurrency_ScientificNotation;
// JSON allows scientific notation; Currency should handle 1.5e2 = 150.00
var
  LRecord: TCurrencyOnlyRecord;
begin
  LRecord := DeserializeFromJson<TCurrencyOnlyRecord>('{"valor":1.5e2}');
  Should(LRecord.valor = 150.00)
    .Because('1.5e2 (scientific notation) should equal Currency 150.00; got ' +
             CurrToStr(LRecord.valor))
    .BeTrue;
end;

procedure TUtf8SerializerCurrencyTests.TestCurrency_MissingFieldDefaultsToZero;
// Field absent from JSON → Default(Currency) = 0
var
  LRecord: TCurrencyOnlyRecord;
begin
  LRecord := DeserializeFromJson<TCurrencyOnlyRecord>('{}');
  Should(LRecord.valor = 0.0)
    .Because('Missing Currency field should default to 0.0000; got ' +
             CurrToStr(LRecord.valor))
    .BeTrue;
end;

procedure TUtf8SerializerCurrencyTests.TestCurrency_SmallestNonZero;
// 0.0001 is the smallest positive Currency value (1 / 10000)
var
  LRecord: TCurrencyOnlyRecord;
begin
  LRecord := DeserializeFromJson<TCurrencyOnlyRecord>('{"valor":0.0001}');
  Should(LRecord.valor = 0.0001)
    .Because('0.0001 is the smallest positive Currency unit; got ' +
             CurrToStr(LRecord.valor))
    .BeTrue;
end;

procedure TUtf8SerializerCurrencyTests.TestCurrency_InterleavedWithStrings;
// A record where Currency fields are interleaved with string fields
// Verifies that field offset tracking is not broken for non-trivial layouts
type
  TInterleavedRecord = record
    nome: string;
    preco: Currency;
    descricao: string;
    desconto: Currency;
  end;
var
  LRecord: TInterleavedRecord;
begin
  LRecord := DeserializeFromJson<TInterleavedRecord>(
    '{"nome":"Item","preco":15.00,"descricao":"Um item","desconto":1.50}');

  Should(LRecord.nome).Be('Item');
  Should(LRecord.preco = 15.00)
    .Because('preco: expected 15.00; got ' + CurrToStr(LRecord.preco))
    .BeTrue;
  Should(LRecord.descricao).Be('Um item');
  Should(LRecord.desconto = 1.50)
    .Because('desconto: expected 1.50; got ' + CurrToStr(LRecord.desconto))
    .BeTrue;
end;

end.
