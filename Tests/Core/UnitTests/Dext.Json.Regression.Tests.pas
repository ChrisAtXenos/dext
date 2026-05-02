unit Dext.Json.Regression.Tests;

interface

uses
  System.SysUtils,
  System.Rtti,
  Dext.Testing.Attributes,
  Dext.Assertions,
  Dext.Json,
  Dext.Json.Types;

type
  TMyRecord = record
    IdRecord: Integer;
    Descricao: string;
  end;

  // -------------------------------------------------------------------------
  // Types for issue #108 regression:
  // Dext.Json should NOT serialize internal 'refCount' / 'FRefCount' fields
  // when the serialized class inherits from TInterfacedObject.
  // -------------------------------------------------------------------------

  /// <summary>Data-contract interface (issue #108)</summary>
  IMyData108 = interface
    ['{8A9B1A2C-D3E4-4F5A-B6C7-D8E9F0A1B2C3}']
    function GetName: string;
    procedure SetName(const Value: string);
    property Name: string read GetName write SetName;
  end;

  /// <summary>Class implementing IMyData108 via TInterfacedObject (introduces FRefCount)</summary>
  TMyData108 = class(TInterfacedObject, IMyData108)
  private
    FName: string;
  public
    function GetName: string;
    procedure SetName(const Value: string);
    property Name: string read GetName write SetName;
  end;

  /// <summary>Generic result wrapper (issue #108)</summary>
  IPaginatedResult108<T> = interface
    function GetData: T;
    property Data: T read GetData;
  end;

  TPaginatedResult108<T> = class(TInterfacedObject, IPaginatedResult108<T>)
  private
    FData: T;
  public
    constructor Create(const AData: T);
    function GetData: T;
  end;

  /// <summary>Generic helper that reproduces the exact bug scenario (issue #108)</summary>
  TPaginatedJsonHelper108<T> = class
  public
    class function ToEnvelope(PData: IPaginatedResult108<T>): string;
  end;

  [TestFixture('JSON Regression Tests')]
  TJsonRegressionTests = class
  public
    [Test('Should produce indented JSON when TJsonSettings.Indented is used')]
    procedure TestIndentedFormatting;

    [Test('Should produce compact JSON when TJsonSettings.Default is used')]
    procedure TestCompactFormatting;

    [Test('Should produce indented JSON for arrays when TJsonSettings.Indented is used')]
    procedure TestArrayIndention;
  end;

  /// <summary>
  /// Regression suite for GitHub issue #108:
  /// Dext.Json serializes internal 'refCount' property when using Generics
  /// with Classes implementing Interfaces.
  /// </summary>
  [TestFixture('JSON Regression - Issue #108: refCount leak on TInterfacedObject')]
  TJsonIssue108RegressionTests = class
  public
    [Test('#108 - Serialize<T> must NOT include refCount when T is a TInterfacedObject subclass')]
    procedure TestSerializeGeneric_MustNotLeakRefCount;

    [Test('#108 - Serialize<T> via generic helper must NOT include refCount')]
    procedure TestSerializeViaGenericHelper_MustNotLeakRefCount;

    [Test('#108 - Serialize<T> result must contain only declared business properties')]
    procedure TestSerializeGeneric_OnlyContainsDeclaredProperties;
  end;

implementation

{ TPaginatedResult108<T> }

constructor TPaginatedResult108<T>.Create(const AData: T);
begin
  inherited Create;
  FData := AData;
end;

function TPaginatedResult108<T>.GetData: T;
begin
  Result := FData;
end;

{ TPaginatedJsonHelper108<T> }

class function TPaginatedJsonHelper108<T>.ToEnvelope(PData: IPaginatedResult108<T>): string;
begin
  // This is the exact call path from the bug report
  Result := TDextJson.Serialize<T>(PData.GetData);
end;

{ TMyData108 }

function TMyData108.GetName: string;
begin
  Result := FName;
end;

procedure TMyData108.SetName(const Value: string);
begin
  FName := Value;
end;

{ TJsonRegressionTests }

procedure TJsonRegressionTests.TestIndentedFormatting;
var
  LMyRecord: TMyRecord;
  LJsonIndented: string;
begin
  LMyRecord.IdRecord := 1;
  LMyRecord.Descricao := 'Descricao';

  LJsonIndented := TDextJson.Serialize(TValue.From<TMyRecord>(LMyRecord), TJsonSettings.Indented);

  Should(LJsonIndented).NotBeEmpty;
  // Indented JSON should have line breaks.
  // We check for presence of at least one line break (\r or \n)
  Should(LJsonIndented.Contains(#13) or LJsonIndented.Contains(#10)).BeTrue;
  Should(LJsonIndented.Contains(' "IdRecord": 1') or LJsonIndented.Contains(#9'"IdRecord": 1'));
end;

procedure TJsonRegressionTests.TestCompactFormatting;
var
  LMyRecord: TMyRecord;
  LJsonCompact: string;
begin
  LMyRecord.IdRecord := 1;
  LMyRecord.Descricao := 'Descricao';

  LJsonCompact := TDextJson.Serialize(TValue.From<TMyRecord>(LMyRecord), TJsonSettings.Default);

  Should(LJsonCompact).NotBeEmpty;
  // Compact JSON should NOT have line breaks
  Should(LJsonCompact.Contains(#13)).BeFalse;
  Should(LJsonCompact.Contains(#10)).BeFalse;
  Should(LJsonCompact).Be('{"IdRecord":1,"Descricao":"Descricao"}');
end;

procedure TJsonRegressionTests.TestArrayIndention;
var
  LArray: TArray<Integer>;
  LJson: string;
begin
  LArray := [1, 2, 3];
  LJson := TDextJson.Serialize(TValue.From<TArray<Integer>>(LArray), TJsonSettings.Indented);

  Should(LJson).NotBeEmpty;
  Should(LJson.Contains(#13) or LJson.Contains(#10)).BeTrue;
  Should(LJson).Contain('1');
  Should(LJson).Contain('2');
  Should(LJson).Contain('3');
end;

{ TJsonIssue108RegressionTests }

procedure TJsonIssue108RegressionTests.TestSerializeGeneric_MustNotLeakRefCount;
var
  LData: TMyData108;
  LJson: string;
begin
  // Arrange: create a TInterfacedObject subclass with a single business property
  LData := TMyData108.Create;
  try
    LData.Name := 'Dext User';

    // Act: serialize using the generic overload (exact bug trigger)
    LJson := TDextJson.Serialize<TMyData108>(LData);

    // Assert: refCount must NOT appear in output
    Should(LJson).NotBeEmpty;
    Should(LJson.ToLower.Contains('refcount')).BeFalse;
    Should(LJson.ToLower.Contains('frefcount')).BeFalse;
  finally
    LData.Free;
  end;
end;

procedure TJsonIssue108RegressionTests.TestSerializeViaGenericHelper_MustNotLeakRefCount;
var
  LData: TMyData108;
  LPaginated: IPaginatedResult108<TMyData108>;
  LJson: string;
begin
  // Arrange: replicate the exact scenario from the issue report
  LData := TMyData108.Create;
  try
    LData.Name := 'Dext User';
    LPaginated := TPaginatedResult108<TMyData108>.Create(LData);

    // Act: serialize via the generic helper (this was the original failing path)
    LJson := TPaginatedJsonHelper108<TMyData108>.ToEnvelope(LPaginated);

    // Assert: refCount must NOT appear in output
    Should(LJson).NotBeEmpty;
    Should(LJson.ToLower.Contains('refcount')).BeFalse;
    Should(LJson.ToLower.Contains('frefcount')).BeFalse;
  finally
    LData.Free;
  end;
end;

procedure TJsonIssue108RegressionTests.TestSerializeGeneric_OnlyContainsDeclaredProperties;
var
  LData: TMyData108;
  LJson: string;
begin
  // Arrange
  LData := TMyData108.Create;
  try
    LData.Name := 'Dext User';

    // Act: default settings preserve PascalCase names
    LJson := TDextJson.Serialize<TMyData108>(LData);

    // Assert: output must contain the business property key (quoted, PascalCase)
    // and its value. Using quoted '"Name"' avoids a false-positive match on the
    // value 'Dext User' which also contains letters.
    Should(LJson).Contain('"Name"');
    Should(LJson).Contain('Dext User');

    // The compact output must be exactly this -- no extra fields allowed.
    // If refCount were leaking, the JSON would have more keys.
    Should(LJson).Be('{"Name":"Dext User"}');

    // Belt-and-suspenders: key names from TInterfacedObject must be absent
    Should(LJson.ToLower.Contains('refcount')).BeFalse;
    Should(LJson.ToLower.Contains('frefcount')).BeFalse;
  finally
    LData.Free;
  end;
end;

end.
