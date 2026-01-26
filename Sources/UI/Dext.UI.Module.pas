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
/// Dext.UI.Module - Base module class for MVU pattern
///
/// A Module encapsulates a feature with its own Model, Messages, and Update logic.
/// This enables modular, testable, and reusable UI components.
/// </summary>
unit Dext.UI.Module;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Vcl.Controls,
  Dext.UI.Message;

type
  /// <summary>
  /// Represents a side effect that should be executed after an update.
  /// Effects are commands that interact with the outside world (HTTP, DB, Timer, etc.)
  /// </summary>
  TEffect = class abstract
  public
    /// <summary>Called when the effect completes successfully</summary>
    OnSuccess: TClass;  // Message class to dispatch
    /// <summary>Called when the effect fails</summary>
    OnError: TClass;    // Message class to dispatch
  end;
  
  /// <summary>
  /// Result of an Update operation, containing the new Model and optional Effects.
  /// </summary>
  TUpdateResult<TModel> = record
    Model: TModel;
    Effects: TArray<TEffect>;
    
    /// <summary>Create a result with no side effects</summary>
    class function NoEffect(const AModel: TModel): TUpdateResult<TModel>; static;
    
    /// <summary>Create a result with side effects to execute</summary>
    class function WithEffects(const AModel: TModel; 
                                const AEffects: TArray<TEffect>): TUpdateResult<TModel>; static;
  end;
  
  /// <summary>
  /// Base class for MVU modules.
  /// Override Init, Update, and optionally View to create a complete feature.
  /// </summary>
  TModule<TModel; TMsg: TMessage> = class abstract
  private
    FDispatch: TProc<TMsg>;
  protected
    /// <summary>Dispatch a message to be processed</summary>
    procedure DispatchMessage(const Msg: TMsg);
  public
    constructor Create(ADispatch: TProc<TMsg>);
    
    /// <summary>Initialize the Model with default state</summary>
    function Init: TModel; virtual; abstract;
    
    /// <summary>
    /// Process a message and return a new Model.
    /// This should be a PURE function with no side effects.
    /// </summary>
    function Update(const Model: TModel; 
                    const Msg: TMsg): TUpdateResult<TModel>; virtual; abstract;
    
    /// <summary>
    /// Optional: Render the View imperatively.
    /// Prefer using TMVUBinder with declarative attributes instead.
    /// </summary>
    procedure View(const Model: TModel; const Container: TWinControl); virtual;
  end;

implementation

{ TUpdateResult<TModel> }

class function TUpdateResult<TModel>.NoEffect(const AModel: TModel): TUpdateResult<TModel>;
begin
  Result.Model := AModel;
  Result.Effects := nil;
end;

class function TUpdateResult<TModel>.WithEffects(const AModel: TModel;
  const AEffects: TArray<TEffect>): TUpdateResult<TModel>;
begin
  Result.Model := AModel;
  Result.Effects := AEffects;
end;

{ TModule<TModel, TMsg> }

constructor TModule<TModel, TMsg>.Create(ADispatch: TProc<TMsg>);
begin
  inherited Create;
  FDispatch := ADispatch;
end;

procedure TModule<TModel, TMsg>.DispatchMessage(const Msg: TMsg);
begin
  if Assigned(FDispatch) then
    FDispatch(Msg);
end;

procedure TModule<TModel, TMsg>.View(const Model: TModel; const Container: TWinControl);
begin
  // Default implementation does nothing
  // Override if you want imperative view rendering
end;

end.
