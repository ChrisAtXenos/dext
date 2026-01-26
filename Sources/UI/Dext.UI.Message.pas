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
/// Dext.UI.Message - Base message types for MVU pattern
///
/// Messages represent user intentions and events that can change state.
/// They are the ONLY way to modify the Model in MVU architecture.
/// </summary>
unit Dext.UI.Message;

interface

uses
  System.SysUtils;

type
  /// <summary>
  /// Base class for all MVU messages.
  /// Extend this class to create your application-specific messages.
  /// </summary>
  TMessage = class
  private
    FTimestamp: TDateTime;
    FCorrelationId: string;
  public
    constructor Create; virtual;
    
    /// <summary>When the message was created</summary>
    property Timestamp: TDateTime read FTimestamp;
    
    /// <summary>Optional correlation ID for tracking message chains</summary>
    property CorrelationId: string read FCorrelationId write FCorrelationId;
  end;
  
  TMessageClass = class of TMessage;
  
  /// <summary>
  /// A message that carries a value payload.
  /// Useful for messages that transport data (e.g., text changed, item selected).
  /// </summary>
  TValueMessage<T> = class(TMessage)
  private
    FValue: T;
  public
    constructor Create(const AValue: T); reintroduce;
    property Value: T read FValue;
  end;

implementation

{ TMessage }

constructor TMessage.Create;
begin
  inherited Create;
  FTimestamp := Now;
  FCorrelationId := '';
end;

{ TValueMessage<T> }

constructor TValueMessage<T>.Create(const AValue: T);
begin
  inherited Create;
  FValue := AValue;
end;

end.
