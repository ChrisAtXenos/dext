{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{                                                                           }
{           Copyright (C) 2025 Cesar Romero & Dext Contributors             }
{                                                                           }
{           Licensed under the Apache License, Version 2.0 (the "License"); }
{           you may not use this file except in compliance with the License.}
{           You may obtain a copy of the License at                         }
{                                                                           }
{               http://www.apache.org/licenses/LICENSE-2.0                  }
{                                                                           }
{           Unless required by applicable law or agreed to in writing,      }
{           software distributed under the License is distributed on an     }
{           "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,    }
{           either express or implied. See the License for the specific     }
{           language governing permissions and limitations under the        }
{           License.                                                        }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Author:  Cesar Romero                                                    }
{  Created: 2026-01-19                                                      }
{                                                                           }
{***************************************************************************}

/// <summary>
/// Dext.UI.State - State management for MVU pattern
///
/// Provides a centralized state store that can be shared across modules.
/// Supports subscriptions for reactive updates.
/// </summary>
unit Dext.UI.State;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.Rtti,
  System.TypInfo;

type
  /// <summary>
  /// Callback type for state change notifications
  /// </summary>
  TStateChangeHandler = reference to procedure(const Value: TValue);
  
  /// <summary>
  /// Interface for state storage and subscriptions.
  /// Uses TValue for type-agnostic storage (interfaces can't have generic methods).
  /// </summary>
  IStateStore = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    /// <summary>Get the current state for a given type</summary>
    function GetState(TypeInfo: PTypeInfo): TValue;
    
    /// <summary>Update the state with a new value</summary>
    procedure SetState(TypeInfo: PTypeInfo; const Value: TValue);
    
    /// <summary>Subscribe to state changes for a given type</summary>
    procedure Subscribe(TypeInfo: PTypeInfo; Handler: TStateChangeHandler);
    
    /// <summary>Unsubscribe from state changes</summary>
    procedure Unsubscribe(TypeInfo: PTypeInfo; Handler: TStateChangeHandler);
  end;
  
  /// <summary>
  /// In-memory implementation of IStateStore.
  /// </summary>
  TStateStore = class(TInterfacedObject, IStateStore)
  private
    FStates: TDictionary<PTypeInfo, TValue>;
    FSubscriptions: TDictionary<PTypeInfo, TList<TStateChangeHandler>>;
  public
    constructor Create;
    destructor Destroy; override;
    
    function GetState(TypeInfo: PTypeInfo): TValue;
    procedure SetState(TypeInfo: PTypeInfo; const Value: TValue);
    procedure Subscribe(TypeInfo: PTypeInfo; Handler: TStateChangeHandler);
    procedure Unsubscribe(TypeInfo: PTypeInfo; Handler: TStateChangeHandler);
    
    /// <summary>Type-safe helper to get state</summary>
    function Get<T>: T;
    
    /// <summary>Type-safe helper to set state</summary>
    procedure Put<T>(const Value: T);
    
    /// <summary>Type-safe helper to subscribe</summary>
    procedure Watch<T>(Handler: TProc<T>);
  end;

implementation

{ TStateStore }

constructor TStateStore.Create;
begin
  inherited;
  FStates := TDictionary<PTypeInfo, TValue>.Create;
  FSubscriptions := TDictionary<PTypeInfo, TList<TStateChangeHandler>>.Create;
end;

destructor TStateStore.Destroy;
var
  List: TList<TStateChangeHandler>;
begin
  for List in FSubscriptions.Values do
    List.Free;
  FSubscriptions.Free;
  FStates.Free;
  inherited;
end;

function TStateStore.GetState(TypeInfo: PTypeInfo): TValue;
begin
  if not FStates.TryGetValue(TypeInfo, Result) then
    Result := TValue.Empty;
end;

procedure TStateStore.SetState(TypeInfo: PTypeInfo; const Value: TValue);
var
  Subscribers: TList<TStateChangeHandler>;
  Handler: TStateChangeHandler;
begin
  FStates.AddOrSetValue(TypeInfo, Value);
  
  // Notify subscribers
  if FSubscriptions.TryGetValue(TypeInfo, Subscribers) then
  begin
    for Handler in Subscribers do
      Handler(Value);
  end;
end;

procedure TStateStore.Subscribe(TypeInfo: PTypeInfo; Handler: TStateChangeHandler);
var
  Subscribers: TList<TStateChangeHandler>;
begin
  if not FSubscriptions.TryGetValue(TypeInfo, Subscribers) then
  begin
    Subscribers := TList<TStateChangeHandler>.Create;
    FSubscriptions.Add(TypeInfo, Subscribers);
  end;
  
  Subscribers.Add(Handler);
end;

procedure TStateStore.Unsubscribe(TypeInfo: PTypeInfo; Handler: TStateChangeHandler);
var
  Subscribers: TList<TStateChangeHandler>;
begin
  if FSubscriptions.TryGetValue(TypeInfo, Subscribers) then
  begin
    // Note: Comparing anonymous methods directly is unreliable
    // In production, consider using subscription tokens
  end;
end;

{ Type-safe helpers (on the class, not interface) }

function TStateStore.Get<T>: T;
var
  Value: TValue;
begin
  Value := GetState(System.TypeInfo(T));
  if Value.IsEmpty then
    Result := Default(T)
  else
    Result := Value.AsType<T>;
end;

procedure TStateStore.Put<T>(const Value: T);
begin
  SetState(System.TypeInfo(T), TValue.From<T>(Value));
end;

procedure TStateStore.Watch<T>(Handler: TProc<T>);
begin
  Subscribe(System.TypeInfo(T), 
    procedure(const Value: TValue)
    begin
      Handler(Value.AsType<T>);
    end);
end;

end.
