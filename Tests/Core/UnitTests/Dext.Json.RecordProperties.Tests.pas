unit Dext.Json.RecordProperties.Tests;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  Dext.Collections,
  Dext.Core.Activator,
  Dext.Core.Reflection,
  Dext.Testing.Attributes,
  Dext.Assertions,
  Dext.Json,
  Dext.Json.Types;

type
  { Scenario A: Direct mapping with public fields matching JSON names }
  TGeminiPartDirect = record
  public
    text: string;
  end;

  TGeminiContentDirect = record
  public
    parts: IList<TGeminiPartDirect>;
    role: string;
    class function Create(const AText: string; const ARole: string = ''): TGeminiContentDirect; static;
  end;

  TGeminiRequestDirect = record
  public
    contents: IList<TGeminiContentDirect>;
    class function Create(const AQuestion: string): TGeminiRequestDirect; static;
  end;

  { Scenario B: Mapping with PascalCase fields and JsonName attributes }
  TGeminiPartAttr = record
  public
    [JsonName('text')]Text: string;
  end;

  TGeminiContentAttr = record
  public
    [JsonName('parts')]Parts: IList<TGeminiPartAttr>;
    [JsonName('role')]Role: string;
    class function Create(const AText: string; const ARole: string = ''): TGeminiContentAttr; static;
  end;

  TGeminiRequestAttr = record
  public
    [JsonName('contents')]Contents: IList<TGeminiContentAttr>;
    class function Create(const AQuestion: string): TGeminiRequestAttr; static;
  end;

  [TestFixture('JSON Record Properties Tests')]
  TJsonRecordPropertiesTests = class
  public
    [Test('Should deserialize using direct public fields')]
    procedure TestDeserialize_DirectFields;

    [Test('Should deserialize using JsonName attributes on public fields')]
    procedure TestDeserialize_WithAttributes;

    [Test('Should deserialize empty array into IList field')]
    procedure TestDeserialize_EmptyArray;

    [Test('Pure RTTI: TValue.Make + direct field write must preserve interface')]
    procedure TestRtti_InterfaceFieldInRecord;

    [Test('Activator must return tkInterface TValue for IList<T>')]
    procedure TestRtti_ActivatorCreatesValidInterface;

    [Test('Should handle nested lists in records')]
    procedure TestDeepSerialization;
  end;

implementation

{ TGeminiContentDirect }

class function TGeminiContentDirect.Create(const AText: string; const ARole: string): TGeminiContentDirect;
begin
  Result.parts := TCollections.CreateList<TGeminiPartDirect>;
  var Part: TGeminiPartDirect;
  Part.text := AText;
  Result.parts.Add(Part);
  Result.role := ARole;
end;

{ TGeminiRequestDirect }

class function TGeminiRequestDirect.Create(const AQuestion: string): TGeminiRequestDirect;
begin
  Result.contents := TCollections.CreateList<TGeminiContentDirect>;
  Result.contents.Add(TGeminiContentDirect.Create(AQuestion));
end;

{ TGeminiContentAttr }

class function TGeminiContentAttr.Create(const AText: string; const ARole: string): TGeminiContentAttr;
begin
  Result.Parts := TCollections.CreateList<TGeminiPartAttr>;
  var Part: TGeminiPartAttr;
  Part.Text := AText;
  Result.Parts.Add(Part);
  Result.Role := ARole;
end;

{ TGeminiRequestAttr }

class function TGeminiRequestAttr.Create(const AQuestion: string): TGeminiRequestAttr;
begin
  Result.Contents := TCollections.CreateList<TGeminiContentAttr>;
  Result.Contents.Add(TGeminiContentAttr.Create(AQuestion));
end;

{ TJsonRecordPropertiesTests }

procedure TJsonRecordPropertiesTests.TestDeserialize_DirectFields;
var
  Json: string;
  Req: TGeminiRequestDirect;
  Settings: TJsonSettings;
begin
  Settings := TJsonSettings.Default;
  
  Json := '{"contents":[{"parts":[{"text":"Olá"}]}]}';

  Req := TDextJson.Deserialize<TGeminiRequestDirect>(Json, Settings);
  
  Should(Assigned(Req.contents)).BeTrue;
  Should(Req.contents.Count).Be(1);
  Should(Req.contents[0].parts[0].text).Be('Olá');
end;

procedure TJsonRecordPropertiesTests.TestDeserialize_WithAttributes;
var
  Json: string;
  Req: TGeminiRequestAttr;
  Settings: TJsonSettings;
begin
  Settings := TJsonSettings.Default;
  
  Json := '{"contents":[{"parts":[{"text":"Olá"}]}]}';
  Req := TDextJson.Deserialize<TGeminiRequestAttr>(Json, Settings);
  
  Should(Assigned(Req.Contents)).BeTrue;
  Should(Req.Contents.Count).Be(1);
  Should(Req.Contents[0].Parts[0].Text).Be('Olá');
end;

procedure TJsonRecordPropertiesTests.TestDeserialize_EmptyArray;
var
  Json: string;
  Req: TGeminiRequestDirect;
  Settings: TJsonSettings;
  ErrorMsg: string;
begin
  Settings := TJsonSettings.Default;
  Json := '{"contents":[]}';
  ErrorMsg := 'no exception';
  try
    Req := TDextJson.Deserialize<TGeminiRequestDirect>(Json, Settings);
  except
    on E: Exception do
      ErrorMsg := E.ClassName + ': ' + E.Message;
  end;
  Should(ErrorMsg).Be('no exception'); 
  Should(Assigned(Req.contents)).BeTrue;
  Should(Req.contents.Count).Be(0);
end;

procedure TJsonRecordPropertiesTests.TestRtti_InterfaceFieldInRecord;
var
  ReqVal: TValue;
  Req: TGeminiRequestDirect;
  Field: TRttiField;
  RttiType: TRttiType;
  List: IList<TGeminiContentDirect>;
  ListVal: TValue;
  FieldPtr: ^IInterface;
begin
  List := TCollections.CreateList<TGeminiContentDirect>;
  ListVal := TValue.From<IList<TGeminiContentDirect>>(List);

  TValue.Make(nil, TypeInfo(TGeminiRequestDirect), ReqVal);
  RttiType := TReflection.Context.GetType(TypeInfo(TGeminiRequestDirect));
  Field := RttiType.GetField('contents');

  Should(Field <> nil).BeTrue;

  Field.SetValue(ReqVal.GetReferenceToRawData, ListVal);
  Req := ReqVal.AsType<TGeminiRequestDirect>;
  Should(Assigned(Req.contents)).BeTrue;

  TValue.Make(nil, TypeInfo(TGeminiRequestDirect), ReqVal);
  FieldPtr := Pointer(PByte(ReqVal.GetReferenceToRawData) + Field.Offset);
  FieldPtr^ := List;
  Req := ReqVal.AsType<TGeminiRequestDirect>;
  Should(Assigned(Req.contents)).BeTrue;
end;

procedure TJsonRecordPropertiesTests.TestRtti_ActivatorCreatesValidInterface;
var
  ReqVal: TValue;
  Req: TGeminiRequestDirect;
  Field: TRttiField;
  RttiType: TRttiType;
  ListVal: TValue;
  FieldPtr: ^IInterface;
begin
  ListVal := TActivator.CreateInstanceRttiOnly(TypeInfo(IList<TGeminiContentDirect>));

  Should(ListVal.IsEmpty).BeFalse;
  Should(Ord(ListVal.Kind)).Be(Ord(tkInterface));
  var TmpIntf: IInterface := ListVal.AsInterface;
  Should(TmpIntf <> nil).BeTrue;

  TValue.Make(nil, TypeInfo(TGeminiRequestDirect), ReqVal);
  RttiType := TReflection.Context.GetType(TypeInfo(TGeminiRequestDirect));
  Field := RttiType.GetField('contents');

  FieldPtr := Pointer(PByte(ReqVal.GetReferenceToRawData) + Field.Offset);
  FieldPtr^ := ListVal.AsInterface;

  Req := ReqVal.AsType<TGeminiRequestDirect>;
  Should(Assigned(Req.contents)).BeTrue;
end;

procedure TJsonRecordPropertiesTests.TestDeepSerialization;
var
  Req: TGeminiRequestDirect;
  Json: string;
  Settings: TJsonSettings;
begin
  Settings := TJsonSettings.Default;
  Settings.CaseStyle := TCaseStyle.CamelCase;

  Req := TGeminiRequestDirect.Create('Part 1');
  var Content := TGeminiContentDirect.Create('Part 2');
  Req.contents.Add(Content);
  
  Json := TDextJson.Serialize(Req, Settings);
  
  Should(Json).Contain('"Part 1"');
  Should(Json).Contain('"Part 2"');
  Should(Json).Contain('"contents"');
end;

initialization
  TActivator.RegisterDefault<IList<TGeminiPartDirect>, TList<TGeminiPartDirect>>;
  TActivator.RegisterDefault<IList<TGeminiContentDirect>, TList<TGeminiContentDirect>>;
  TActivator.RegisterDefault<IList<TGeminiPartAttr>, TList<TGeminiPartAttr>>;
  TActivator.RegisterDefault<IList<TGeminiContentAttr>, TList<TGeminiContentAttr>>;

end.
