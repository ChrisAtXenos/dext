{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{                                                                           }
{           Copyright (c) 2024 Dext Framework                               }
{                                                                           }
{           https://github.com/dext-framework/dext                          }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

unit Dext.Collections.Stack;

interface

uses
  System.SysUtils,
  System.TypInfo,
  Dext.Collections.Base,
  Dext.Collections.Memory,
  Dext.Collections.Raw,
  Dext.Collections.Comparers,
  Dext.Collections;

type
  /// <summary>High-performance record-based enumerator for TStack<T></summary>
  TStackRecordEnumerator<T> = record
  private
    FCore: TRawList;
    FIndex: Integer;
  public
    constructor Create(ACore: TRawList);
    function MoveNext: Boolean; inline;
    function GetCurrent: T; inline;
    property Current: T read GetCurrent;
  end;

  /// <summary>Base class avoiding Delphi explicit interface method mapping bug</summary>
  TStackBase<T> = class(TInterfacedObject, IEnumerable<T>)
  public
    function GetInterfaceEnumerator: IEnumerator<T>; virtual; abstract;
    function GetEnumerator: IEnumerator<T>;
  end;


  /// <summary>Stack implementation backed by TRawList</summary>
  TStack<T> = class(TStackBase<T>, IStack<T>)
  private
    type P_T = ^T;
  private
    FCore: TRawList;
    function GetCount: Integer; inline;
  public
    function GetInterfaceEnumerator: IEnumerator<T>; override;

    constructor Create;
    destructor Destroy; override;

    procedure Push(const Value: T); inline;
    function Pop: T; inline;
    function Peek: T; inline;
    function TryPop(out Value: T): Boolean; inline;
    function TryPeek(out Value: T): Boolean; inline;
    procedure Clear; inline;
    function Contains(const Value: T): Boolean;
    function ToArray: TArray<T>;

    function GetEnumerator: TStackRecordEnumerator<T>; reintroduce; inline;
  end;

  /// <summary>Simple LIFO enumerator (Class-based for interface compatibility)</summary>
  TStackEnumerator<T> = class(TInterfacedObject, IEnumerator<T>)
  private
    FCore: TRawList;
    FIndex: Integer;
  public
    constructor Create(ACore: TRawList);
    function GetCurrent: T;
    function MoveNext: Boolean;
    procedure Reset;
    property Current: T read GetCurrent;
  end;

implementation

{ TStackBase<T> }

function TStackBase<T>.GetEnumerator: IEnumerator<T>;
begin
  Result := GetInterfaceEnumerator;
end;

{ TStack<T> }

constructor TStack<T>.Create;
begin
  inherited Create;
  FCore := TRawList.Create(SizeOf(T), TypeInfo(T), IsManagedType(TypeInfo(T)));
end;

destructor TStack<T>.Destroy;
begin
  FCore.Free;
  inherited;
end;

procedure TStack<T>.Clear;
begin
  FCore.Clear;
end;

function TStack<T>.Contains(const Value: T): Boolean;
var
  I: Integer;
  Comp: IEqualityComparer<T>;
  VP: Pointer;
begin
  VP := @Value;
  Comp := TEqualityComparer<T>.Default;
  for I := FCore.Count - 1 downto 0 do
    if Comp.Equals(P_T(FCore.GetItemPtr(I))^, P_T(VP)^) then
      Exit(True);
  Result := False;
end;

function TStack<T>.GetCount: Integer;
begin
  Result := FCore.Count;
end;

function TStack<T>.GetEnumerator: TStackRecordEnumerator<T>;
begin
  Result := TStackRecordEnumerator<T>.Create(FCore);
end;

function TStack<T>.GetInterfaceEnumerator: IEnumerator<T>;
begin
  Result := TStackEnumerator<T>.Create(FCore);
end;

function TStack<T>.Peek: T;
begin
  if FCore.Count = 0 then
    raise Exception.Create('Stack is empty');
  FCore.GetRawItem(FCore.Count - 1, @Result);
end;

function TStack<T>.Pop: T;
begin
  Result := Peek;
  FCore.DeleteRaw(FCore.Count - 1);
end;

procedure TStack<T>.Push(const Value: T);
begin
  FCore.AddRaw(@Value);
end;

function TStack<T>.ToArray: TArray<T>;
var
  I: Integer;
begin
  SetLength(Result, FCore.Count);
  for I := 0 to FCore.Count - 1 do
    FCore.GetRawItem(FCore.Count - 1 - I, @Result[I]);
end;

function TStack<T>.TryPeek(out Value: T): Boolean;
begin
  if FCore.Count = 0 then
  begin
    Value := Default(T);
    Exit(False);
  end;
  FCore.GetRawItem(FCore.Count - 1, @Value);
  Result := True;
end;

function TStack<T>.TryPop(out Value: T): Boolean;
begin
  if TryPeek(Value) then
  begin
    FCore.DeleteRaw(FCore.Count - 1);
    Exit(True);
  end;
  Result := False;
end;

{ TStackRecordEnumerator<T> }

constructor TStackRecordEnumerator<T>.Create(ACore: TRawList);
begin
  FCore := ACore;
  FIndex := FCore.Count;
end;

function TStackRecordEnumerator<T>.GetCurrent: T;
begin
  FCore.GetRawItem(FIndex, @Result);
end;

function TStackRecordEnumerator<T>.MoveNext: Boolean;
begin
  Dec(FIndex);
  Result := FIndex >= 0;
end;

{ TStackEnumerator<T> }

constructor TStackEnumerator<T>.Create(ACore: TRawList);
begin
  inherited Create;
  FCore := ACore;
  FIndex := FCore.Count;
end;

function TStackEnumerator<T>.GetCurrent: T;
begin
  FCore.GetRawItem(FIndex, @Result);
end;

function TStackEnumerator<T>.MoveNext: Boolean;
begin
  Dec(FIndex);
  Result := FIndex >= 0;
end;

procedure TStackEnumerator<T>.Reset;
begin
  FIndex := FCore.Count;
end;

end.
