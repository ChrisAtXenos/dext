{***************************************************************************}
{                                                                           }
{           Dext Framework - Navigator Unit Tests                           }
{                                                                           }
{           Copyright (C) 2025 Cesar Romero & Dext Contributors             }
{                                                                           }
{***************************************************************************}
unit Dext.UI.Navigator.Tests;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Dext.Testing.Attributes,
  Dext.Assertions,
  Dext.UI.Navigator.Types;

type
  /// <summary>
  /// Tests for TNavParams - Navigation parameter container
  /// </summary>
  [TestFixture('Navigator - TNavParams')]
  TNavParamsTests = class
  public
    [Test]
    procedure TestCreateEmpty;
    
    [Test]
    procedure TestAddAndGetString;
    
    [Test]
    procedure TestAddAndGetInteger;
    
    [Test]
    procedure TestAddAndGetBoolean;
    
    [Test]
    procedure TestFluentAdd;
    
    [Test]
    procedure TestTryGetExisting;
    
    [Test]
    procedure TestTryGetNotFound;
    
    [Test]
    procedure TestGetOrDefault;
    
    [Test]
    procedure TestContains;
    
    [Test]
    procedure TestKeys;
    
    [Test]
    procedure TestCount;
    
    [Test]
    procedure TestClear;
    
    [Test]
    procedure TestNewFactory;
  end;

  /// <summary>
  /// Tests for TNavigationResult - Modal navigation result
  /// </summary>
  [TestFixture('Navigator - TNavigationResult')]
  TNavigationResultTests = class
  public
    [Test]
    procedure TestOKWithoutData;
    
    [Test]
    procedure TestOKWithIntegerData;
    
    [Test]
    procedure TestOKWithStringData;
    
    [Test]
    procedure TestCancel;
    
    [Test]
    procedure TestGetDataTyped;
    
    [Test]
    procedure TestTryGetDataSuccess;
    
    [Test]
    procedure TestTryGetDataEmpty;
  end;

  /// <summary>
  /// Tests for TNavigationContext - Middleware pipeline context
  /// </summary>
  [TestFixture('Navigator - TNavigationContext')]
  TNavigationContextTests = class
  public
    [Test]
    procedure TestCreateNotCanceled;
    
    [Test]
    procedure TestCancel;
    
    [Test]
    procedure TestSetResult;
    
    [Test]
    procedure TestSetAndGetItem;
    
    [Test]
    procedure TestTryGetItemSuccess;
    
    [Test]
    procedure TestTryGetItemNotFound;
    
    [Test]
    procedure TestProperties;
  end;

  /// <summary>
  /// Tests for THistoryEntry - Navigation history record
  /// </summary>
  [TestFixture('Navigator - THistoryEntry')]
  THistoryEntryTests = class
  public
    [Test]
    procedure TestCreate;
    
    [Test]
    procedure TestCreateWithParams;
  end;

implementation

{ TNavParamsTests }

procedure TNavParamsTests.TestCreateEmpty;
var
  Params: TNavParams;
begin
  Params := TNavParams.Create;
  try
    Should(Params.Count).Be(0);
  finally
    Params.Free;
  end;
end;

procedure TNavParamsTests.TestAddAndGetString;
var
  Params: TNavParams;
begin
  Params := TNavParams.Create;
  try
    Params.Add('name', 'John');
    Should(Params.Get<string>('name')).Be('John');
  finally
    Params.Free;
  end;
end;

procedure TNavParamsTests.TestAddAndGetInteger;
var
  Params: TNavParams;
begin
  Params := TNavParams.Create;
  try
    Params.Add('id', 42);
    Should(Params.Get<Integer>('id')).Be(42);
  finally
    Params.Free;
  end;
end;

procedure TNavParamsTests.TestAddAndGetBoolean;
var
  Params: TNavParams;
begin
  Params := TNavParams.Create;
  try
    Params.Add('active', True);
    Should(Params.Get<Boolean>('active')).BeTrue;
  finally
    Params.Free;
  end;
end;

procedure TNavParamsTests.TestFluentAdd;
var
  Params: TNavParams;
begin
  Params := TNavParams.Create;
  try
    Params
      .Add('name', 'Alice')
      .Add('age', 30)
      .Add('active', True);
      
    Should(Params.Count).Be(3);
    Should(Params.Get<string>('name')).Be('Alice');
    Should(Params.Get<Integer>('age')).Be(30);
  finally
    Params.Free;
  end;
end;

procedure TNavParamsTests.TestTryGetExisting;
var
  Params: TNavParams;
  Value: string;
begin
  Params := TNavParams.Create;
  try
    Params.Add('key', 'value');
    Should(Params.TryGet<string>('key', Value)).BeTrue;
    Should(Value).Be('value');
  finally
    Params.Free;
  end;
end;

procedure TNavParamsTests.TestTryGetNotFound;
var
  Params: TNavParams;
  Value: string;
begin
  Params := TNavParams.Create;
  try
    Should(Params.TryGet<string>('missing', Value)).BeFalse;
  finally
    Params.Free;
  end;
end;

procedure TNavParamsTests.TestGetOrDefault;
var
  Params: TNavParams;
begin
  Params := TNavParams.Create;
  try
    Params.Add('existing', 100);
    Should(Params.GetOrDefault<Integer>('existing', 0)).Be(100);
    Should(Params.GetOrDefault<Integer>('missing', 999)).Be(999);
  finally
    Params.Free;
  end;
end;

procedure TNavParamsTests.TestContains;
var
  Params: TNavParams;
begin
  Params := TNavParams.Create;
  try
    Params.Add('key', 'value');
    Should(Params.Contains('key')).BeTrue;
    Should(Params.Contains('other')).BeFalse;
  finally
    Params.Free;
  end;
end;

procedure TNavParamsTests.TestKeys;
var
  Params: TNavParams;
  Keys: TArray<string>;
begin
  Params := TNavParams.Create;
  try
    Params.Add('a', 1).Add('b', 2).Add('c', 3);
    Keys := Params.Keys;
    Should(Length(Keys)).Be(3);
  finally
    Params.Free;
  end;
end;

procedure TNavParamsTests.TestCount;
var
  Params: TNavParams;
begin
  Params := TNavParams.Create;
  try
    Should(Params.Count).Be(0);
    Params.Add('one', 1);
    Should(Params.Count).Be(1);
    Params.Add('two', 2);
    Should(Params.Count).Be(2);
  finally
    Params.Free;
  end;
end;

procedure TNavParamsTests.TestClear;
var
  Params: TNavParams;
begin
  Params := TNavParams.Create;
  try
    Params.Add('a', 1).Add('b', 2);
    Should(Params.Count).Be(2);
    Params.Clear;
    Should(Params.Count).Be(0);
  finally
    Params.Free;
  end;
end;

procedure TNavParamsTests.TestNewFactory;
var
  Params: TNavParams;
begin
  Params := TNavParams.New.Add('test', 123);
  try
    Should(Params.Get<Integer>('test')).Be(123);
  finally
    Params.Free;
  end;
end;

{ TNavigationResultTests }

procedure TNavigationResultTests.TestOKWithoutData;
var
  Result: TNavigationResult;
begin
  Result := TNavigationResult.OK;
  Should(Result.Success).BeTrue;
  Should(Result.Data.IsEmpty).BeTrue;
end;

procedure TNavigationResultTests.TestOKWithIntegerData;
var
  Result: TNavigationResult;
begin
  Result := TNavigationResult.OK(TValue.From<Integer>(42));
  Should(Result.Success).BeTrue;
  Should(Result.Data.AsInteger).Be(42);
end;

procedure TNavigationResultTests.TestOKWithStringData;
var
  Result: TNavigationResult;
begin
  Result := TNavigationResult.OK(TValue.From<string>('saved'));
  Should(Result.Success).BeTrue;
  Should(Result.Data.AsString).Be('saved');
end;

procedure TNavigationResultTests.TestCancel;
var
  Result: TNavigationResult;
begin
  Result := TNavigationResult.Cancel;
  Should(Result.Success).BeFalse;
  Should(Result.Data.IsEmpty).BeTrue;
end;

procedure TNavigationResultTests.TestGetDataTyped;
var
  Result: TNavigationResult;
begin
  Result := TNavigationResult.OK(TValue.From<Integer>(100));
  Should(Result.GetData<Integer>).Be(100);
end;

procedure TNavigationResultTests.TestTryGetDataSuccess;
var
  Result: TNavigationResult;
  Value: Integer;
begin
  Result := TNavigationResult.OK(TValue.From<Integer>(50));
  Should(Result.TryGetData<Integer>(Value)).BeTrue;
  Should(Value).Be(50);
end;

procedure TNavigationResultTests.TestTryGetDataEmpty;
var
  Result: TNavigationResult;
  Value: Integer;
begin
  Result := TNavigationResult.Cancel;
  Should(Result.TryGetData<Integer>(Value)).BeFalse;
end;

{ TNavigationContextTests }

procedure TNavigationContextTests.TestCreateNotCanceled;
var
  Context: TNavigationContext;
begin
  Context := TNavigationContext.Create;
  try
    Should(Context.Canceled).BeFalse;
  finally
    Context.Free;
  end;
end;

procedure TNavigationContextTests.TestCancel;
var
  Context: TNavigationContext;
begin
  Context := TNavigationContext.Create;
  try
    Should(Context.Canceled).BeFalse;
    Context.Cancel;
    Should(Context.Canceled).BeTrue;
  finally
    Context.Free;
  end;
end;

procedure TNavigationContextTests.TestSetResult;
var
  Context: TNavigationContext;
begin
  Context := TNavigationContext.Create;
  try
    Context.SetResult(TNavigationResult.OK(TValue.From<string>('data')));
    Should(Context.Result.Success).BeTrue;
    Should(Context.Result.Data.AsString).Be('data');
  finally
    Context.Free;
  end;
end;

procedure TNavigationContextTests.TestSetAndGetItem;
var
  Context: TNavigationContext;
begin
  Context := TNavigationContext.Create;
  try
    Context.SetItem('user_id', TValue.From<Integer>(123));
    Should(Context.GetItem<Integer>('user_id')).Be(123);
  finally
    Context.Free;
  end;
end;

procedure TNavigationContextTests.TestTryGetItemSuccess;
var
  Context: TNavigationContext;
  Value: string;
begin
  Context := TNavigationContext.Create;
  try
    Context.SetItem('token', TValue.From<string>('abc123'));
    Should(Context.TryGetItem<string>('token', Value)).BeTrue;
    Should(Value).Be('abc123');
  finally
    Context.Free;
  end;
end;

procedure TNavigationContextTests.TestTryGetItemNotFound;
var
  Context: TNavigationContext;
  Value: Integer;
begin
  Context := TNavigationContext.Create;
  try
    Should(Context.TryGetItem<Integer>('missing', Value)).BeFalse;
  finally
    Context.Free;
  end;
end;

procedure TNavigationContextTests.TestProperties;
var
  Context: TNavigationContext;
begin
  Context := TNavigationContext.Create;
  try
    Context.Action := naPush;
    Context.SourceRoute := '/home';
    Context.TargetRoute := '/details';
    
    Should(Ord(Context.Action)).Be(Ord(naPush));
    Should(Context.SourceRoute).Be('/home');
    Should(Context.TargetRoute).Be('/details');
  finally
    Context.Free;
  end;
end;

{ THistoryEntryTests }

procedure THistoryEntryTests.TestCreate;
var
  Entry: THistoryEntry;
begin
  Entry := THistoryEntry.Create('/home', TObject, nil, nil);
  Should(Entry.Route).Be('/home');
  Should(Entry.ViewClass.ClassName).Be('TObject');
  Should(Entry.View).BeNil;
  Should(Entry.Params).BeNil;
end;

procedure THistoryEntryTests.TestCreateWithParams;
var
  Entry: THistoryEntry;
  Params: TNavParams;
begin
  Params := TNavParams.New.Add('id', 42);
  try
    Entry := THistoryEntry.Create('/detail', TObject, nil, Params);
    Should(Entry.Route).Be('/detail');
    Should(Entry.Params).NotBeNil;
    Should(Entry.Params.Get<Integer>('id')).Be(42);
  finally
    Params.Free;
  end;
end;

end.
