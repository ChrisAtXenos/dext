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
{  Created: 2026-01-20                                                      }
{                                                                           }
{***************************************************************************}

/// <summary>
/// Dext.UI.Navigator.Types - Fundamental types for the Navigator framework
///
/// This unit defines the core types used throughout the navigation system:
/// - TNavigationAction: enum for navigation operations
/// - TNavParams: parameter container for passing data between views
/// - TNavigationResult: return value from modal-style navigations
/// - TNavigationContext: context object passed through the middleware pipeline
/// - TRouteInfo: metadata about registered routes
/// </summary>
unit Dext.UI.Navigator.Types;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.Generics.Collections;

type
  /// <summary>
  /// Navigation action types
  /// </summary>
  TNavigationAction = (
    naPush,      // Add new view to stack
    naPop,       // Remove current view from stack
    naReplace,   // Replace current view (no history entry)
    naPopUntil   // Pop until a specific view type
  );

  /// <summary>
  /// Result returned from modal-style navigation
  /// </summary>
  TNavigationResult = record
  private
    FSuccess: Boolean;
    FData: TValue;
  public
    property Success: Boolean read FSuccess;
    property Data: TValue read FData;
    
    /// <summary>
    /// Get typed data from the result
    /// </summary>
    function GetData<T>: T;
    
    /// <summary>
    /// Try to get typed data, returns False if not available or wrong type
    /// </summary>
    function TryGetData<T>(out Value: T): Boolean;
    
    /// <summary>
    /// Create a successful result with data
    /// </summary>
    class function OK: TNavigationResult; overload; static;
    class function OK(const AData: TValue): TNavigationResult; overload; static;
    
    /// <summary>
    /// Create a cancelled/failed result
    /// </summary>
    class function Cancel: TNavigationResult; static;
  end;

  /// <summary>
  /// Parameter container for passing data between views during navigation.
  /// Supports fluent API for building parameters.
  /// </summary>
  TNavParams = class
  private
    FParams: TDictionary<string, TValue>;
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// Add a parameter value (fluent)
    /// </summary>
    function Add(const Key: string; const Value: TValue): TNavParams; overload;
    function Add(const Key: string; const Value: Integer): TNavParams; overload;
    function Add(const Key: string; const Value: string): TNavParams; overload;
    function Add(const Key: string; const Value: Boolean): TNavParams; overload;
    function Add(const Key: string; const Value: TObject): TNavParams; overload;
    
    /// <summary>
    /// Get a typed parameter value. Raises exception if not found.
    /// </summary>
    function Get<T>(const Key: string): T;
    
    /// <summary>
    /// Try to get a typed parameter value. Returns False if not found.
    /// </summary>
    function TryGet<T>(const Key: string; out Value: T): Boolean;
    
    /// <summary>
    /// Get a typed parameter value with a default if not found.
    /// </summary>
    function GetOrDefault<T>(const Key: string; const Default: T): T;
    
    /// <summary>
    /// Check if a parameter exists
    /// </summary>
    function Contains(const Key: string): Boolean;
    
    /// <summary>
    /// Get all parameter keys
    /// </summary>
    function Keys: TArray<string>;
    
    /// <summary>
    /// Get parameter count
    /// </summary>
    function Count: Integer;
    
    /// <summary>
    /// Clear all parameters
    /// </summary>
    procedure Clear;
    
    /// <summary>
    /// Static factory for fluent creation
    /// </summary>
    class function New: TNavParams; static;
  end;

  // Forward declaration
  TNavigationContext = class;

  /// <summary>
  /// Procedure type for middleware chain continuation
  /// </summary>
  TNavigationNext = reference to procedure;

  /// <summary>
  /// Context object passed through the navigation middleware pipeline.
  /// Contains all information about the current navigation operation.
  /// </summary>
  TNavigationContext = class
  private
    FAction: TNavigationAction;
    FSourceRoute: string;
    FTargetRoute: string;
    FParams: TNavParams;
    FResult: TNavigationResult;
    FCanceled: Boolean;
    FTargetViewClass: TClass;
    FSourceView: TObject;
    FTargetView: TObject;
    FItems: TDictionary<string, TValue>;
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// Cancel the navigation operation
    /// </summary>
    procedure Cancel;
    
    /// <summary>
    /// Set the navigation result (for modal returns)
    /// </summary>
    procedure SetResult(const AResult: TNavigationResult);
    
    /// <summary>
    /// Store arbitrary data in the context (for middleware communication)
    /// </summary>
    procedure SetItem(const Key: string; const Value: TValue);
    
    /// <summary>
    /// Retrieve arbitrary data from the context
    /// </summary>
    function GetItem<T>(const Key: string): T;
    function TryGetItem<T>(const Key: string; out Value: T): Boolean;
    
    /// <summary>
    /// Navigation action being performed
    /// </summary>
    property Action: TNavigationAction read FAction write FAction;
    
    /// <summary>
    /// Route being navigated from (may be empty)
    /// </summary>
    property SourceRoute: string read FSourceRoute write FSourceRoute;
    
    /// <summary>
    /// Route being navigated to
    /// </summary>
    property TargetRoute: string read FTargetRoute write FTargetRoute;
    
    /// <summary>
    /// Parameters passed to the target view
    /// </summary>
    property Params: TNavParams read FParams write FParams;
    
    /// <summary>
    /// Result from modal navigation
    /// </summary>
    property Result: TNavigationResult read FResult write FResult;
    
    /// <summary>
    /// Whether the navigation was canceled by a guard or middleware
    /// </summary>
    property Canceled: Boolean read FCanceled;
    
    /// <summary>
    /// Class type of the target view
    /// </summary>
    property TargetViewClass: TClass read FTargetViewClass write FTargetViewClass;
    
    /// <summary>
    /// Current/source view instance
    /// </summary>
    property SourceView: TObject read FSourceView write FSourceView;
    
    /// <summary>
    /// Target view instance (set after view creation)
    /// </summary>
    property TargetView: TObject read FTargetView write FTargetView;
  end;

  /// <summary>
  /// History entry for navigation stack
  /// </summary>
  THistoryEntry = record
    Route: string;
    ViewClass: TClass;
    View: TObject;
    Params: TNavParams;
    
    class function Create(const ARoute: string; AViewClass: TClass; 
      AView: TObject; AParams: TNavParams): THistoryEntry; static;
  end;

implementation

{ TNavigationResult }

function TNavigationResult.GetData<T>: T;
begin
  Result := FData.AsType<T>;
end;

function TNavigationResult.TryGetData<T>(out Value: T): Boolean;
begin
  Result := not FData.IsEmpty;
  if Result then
  try
    Value := FData.AsType<T>;
  except
    Result := False;
  end;
end;

class function TNavigationResult.OK: TNavigationResult;
begin
  Result.FSuccess := True;
  Result.FData := TValue.Empty;
end;

class function TNavigationResult.OK(const AData: TValue): TNavigationResult;
begin
  Result.FSuccess := True;
  Result.FData := AData;
end;

class function TNavigationResult.Cancel: TNavigationResult;
begin
  Result.FSuccess := False;
  Result.FData := TValue.Empty;
end;

{ TNavParams }

constructor TNavParams.Create;
begin
  inherited Create;
  FParams := TDictionary<string, TValue>.Create;
end;

destructor TNavParams.Destroy;
begin
  FParams.Free;
  inherited;
end;

function TNavParams.Add(const Key: string; const Value: TValue): TNavParams;
begin
  FParams.AddOrSetValue(Key, Value);
  Result := Self;
end;

function TNavParams.Add(const Key: string; const Value: Integer): TNavParams;
begin
  Result := Add(Key, TValue.From<Integer>(Value));
end;

function TNavParams.Add(const Key: string; const Value: string): TNavParams;
begin
  Result := Add(Key, TValue.From<string>(Value));
end;

function TNavParams.Add(const Key: string; const Value: Boolean): TNavParams;
begin
  Result := Add(Key, TValue.From<Boolean>(Value));
end;

function TNavParams.Add(const Key: string; const Value: TObject): TNavParams;
begin
  Result := Add(Key, TValue.From<TObject>(Value));
end;

function TNavParams.Get<T>(const Key: string): T;
var
  Value: TValue;
begin
  if not FParams.TryGetValue(Key, Value) then
    raise Exception.CreateFmt('Navigation parameter "%s" not found', [Key]);
  Result := Value.AsType<T>;
end;

function TNavParams.TryGet<T>(const Key: string; out Value: T): Boolean;
var
  TVal: TValue;
begin
  Result := FParams.TryGetValue(Key, TVal);
  if Result then
  try
    Value := TVal.AsType<T>;
  except
    Result := False;
  end;
end;

function TNavParams.GetOrDefault<T>(const Key: string; const Default: T): T;
begin
  if not TryGet<T>(Key, Result) then
    Result := Default;
end;

function TNavParams.Contains(const Key: string): Boolean;
begin
  Result := FParams.ContainsKey(Key);
end;

function TNavParams.Keys: TArray<string>;
begin
  Result := FParams.Keys.ToArray;
end;

function TNavParams.Count: Integer;
begin
  Result := FParams.Count;
end;

procedure TNavParams.Clear;
begin
  FParams.Clear;
end;

class function TNavParams.New: TNavParams;
begin
  Result := TNavParams.Create;
end;

{ TNavigationContext }

constructor TNavigationContext.Create;
begin
  inherited Create;
  FItems := TDictionary<string, TValue>.Create;
  FCanceled := False;
end;

destructor TNavigationContext.Destroy;
begin
  FItems.Free;
  // Note: FParams ownership is external - do not free
  inherited;
end;

procedure TNavigationContext.Cancel;
begin
  FCanceled := True;
end;

procedure TNavigationContext.SetResult(const AResult: TNavigationResult);
begin
  FResult := AResult;
end;

procedure TNavigationContext.SetItem(const Key: string; const Value: TValue);
begin
  FItems.AddOrSetValue(Key, Value);
end;

function TNavigationContext.GetItem<T>(const Key: string): T;
var
  Value: TValue;
begin
  if not FItems.TryGetValue(Key, Value) then
    raise Exception.CreateFmt('Context item "%s" not found', [Key]);
  Result := Value.AsType<T>;
end;

function TNavigationContext.TryGetItem<T>(const Key: string; out Value: T): Boolean;
var
  TVal: TValue;
begin
  Result := FItems.TryGetValue(Key, TVal);
  if Result then
  try
    Value := TVal.AsType<T>;
  except
    Result := False;
  end;
end;

{ THistoryEntry }

class function THistoryEntry.Create(const ARoute: string; AViewClass: TClass;
  AView: TObject; AParams: TNavParams): THistoryEntry;
begin
  Result.Route := ARoute;
  Result.ViewClass := AViewClass;
  Result.View := AView;
  Result.Params := AParams;
end;

end.
