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
{  Created: 2025-12-21                                                      }
{                                                                           }
{***************************************************************************}
unit Dext.Web.Middleware.StartupLock;

interface

uses
  System.SysUtils,
  Dext.Web.Core,
  Dext.Web.Interfaces,
  Dext.Hosting.AppState,
  Dext.Logging;

type
  /// <summary>
  ///   Middleware that returns 503 Service Unavailable if the application is not in 'asReady' state.
  /// </summary>
  TStartupLockMiddleware = class(TMiddleware)
  private
    FStateObserver: IAppStateObserver;
    FLogger: ILogger;
  public
    constructor Create(AppState: IAppStateObserver; Logger: ILogger);
    procedure Invoke(AContext: IHttpContext; ANext: TRequestDelegate); override;
  end;

implementation

{ TStartupLockMiddleware }

constructor TStartupLockMiddleware.Create(AppState: IAppStateObserver; Logger: ILogger);
begin
  inherited Create;
  FStateObserver := AppState;
  FLogger := Logger;
end;

procedure TStartupLockMiddleware.Invoke(AContext: IHttpContext; ANext: TRequestDelegate);
var
  State: TApplicationState;
  StateStr: string;
begin
  // If app is not ready (Starting, Migrating, Seeding, Stopping)
  if not FStateObserver.IsReady then
  begin
    State := FStateObserver.State;
    StateStr := '';
    case State of
      asStarting: StateStr := 'Starting';
      asMigrating: StateStr := 'Migrating Database';
      asSeeding: StateStr := 'Seeding Data';
      asStopping: StateStr := 'Shutting Down';
      asStopped: StateStr := 'Stopped';
    end;
    
    // Log the rejection
    FLogger.LogWarning('Request rejected with 503. Application is in state: {State}', [StateStr]);

    // Set 503 Service Unavailable
    AContext.Response.StatusCode := 503;
    
    // Retry-After header: 5 seconds (client should retry)
    AContext.Response.AddHeader('Retry-After', '5');
    
    // Plain text response
    AContext.Response.SetContentType('text/plain');
    AContext.Response.Write(Format('Service Unavailable: Application is %s. Please try again in a few seconds.', [StateStr]));
    
    // Do NOT call Next (Short-circuit pipeline)
    Exit;
  end;

  ANext(AContext);
end;

end.
