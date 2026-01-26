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
/// Dext.UI.Navigator.Middlewares - Built-in navigation middlewares
///
/// This unit provides ready-to-use middlewares:
/// - TLoggingMiddleware: Logs all navigation events
/// - TAuthMiddleware: Checks authentication before navigation
/// - TRoleMiddleware: Checks user roles for protected routes
/// - TAnalyticsMiddleware: Tracks navigation for analytics
/// </summary>
unit Dext.UI.Navigator.Middlewares;

interface

uses
  System.SysUtils,
  System.Classes,
  Dext.Logging,
  Dext.UI.Navigator.Types,
  Dext.UI.Navigator.Interfaces;

type
  /// <summary>
  /// Logs all navigation events using ILogger
  /// </summary>
  TLoggingMiddleware = class(TInterfacedObject, INavigationMiddleware)
  private
    FLogger: ILogger;
  public
    constructor Create(const ALogger: ILogger);
    procedure Execute(Context: TNavigationContext; Next: TNavigationNext);
  end;

  /// <summary>
  /// Checks if user is authenticated before allowing navigation
  /// </summary>
  TAuthMiddleware = class(TInterfacedObject, INavigationMiddleware)
  private
    FAuthService: IAuthService;
    FLoginRoute: string;
  public
    constructor Create(const AAuthService: IAuthService; const ALoginRoute: string = '/login');
    procedure Execute(Context: TNavigationContext; Next: TNavigationNext);
  end;

  /// <summary>
  /// Checks if user has required role for the route
  /// </summary>
  TRoleMiddleware = class(TInterfacedObject, INavigationMiddleware)
  private
    FAuthService: IAuthService;
    FRequiredRole: string;
    FAccessDeniedRoute: string;
  public
    constructor Create(const AAuthService: IAuthService; const ARequiredRole: string;
      const AAccessDeniedRoute: string = '/access-denied');
    procedure Execute(Context: TNavigationContext; Next: TNavigationNext);
  end;

  /// <summary>
  /// Tracks navigation events for analytics purposes
  /// </summary>
  TAnalyticsMiddleware = class(TInterfacedObject, INavigationMiddleware)
  private
    FOnTrack: TProc<string, string, TNavParams>;
  public
    constructor Create(const AOnTrack: TProc<string, string, TNavParams>);
    procedure Execute(Context: TNavigationContext; Next: TNavigationNext);
  end;

  /// <summary>
  /// Confirms navigation away from views with unsaved changes
  /// </summary>
  TConfirmNavigationMiddleware = class(TInterfacedObject, INavigationMiddleware)
  private
    FConfirmFunc: TFunc<string, Boolean>;
    FMessage: string;
  public
    constructor Create(const AConfirmFunc: TFunc<string, Boolean>; 
      const AMessage: string = 'You have unsaved changes. Leave anyway?');
    procedure Execute(Context: TNavigationContext; Next: TNavigationNext);
  end;

  /// <summary>
  /// Base class for creating custom guards
  /// </summary>
  TBaseNavigationGuard = class(TInterfacedObject, INavigationGuard)
  protected
    function DoCanActivate(Context: TNavigationContext): Boolean; virtual; abstract;
  public
    function CanActivate(Context: TNavigationContext): Boolean;
  end;

  /// <summary>
  /// Guard that requires authentication
  /// </summary>
  TAuthGuard = class(TBaseNavigationGuard)
  private
    FAuthService: IAuthService;
  protected
    function DoCanActivate(Context: TNavigationContext): Boolean; override;
  public
    constructor Create(const AAuthService: IAuthService);
  end;

  /// <summary>
  /// Guard that requires a specific role
  /// </summary>
  TRoleGuard = class(TBaseNavigationGuard)
  private
    FAuthService: IAuthService;
    FRole: string;
  protected
    function DoCanActivate(Context: TNavigationContext): Boolean; override;
  public
    constructor Create(const AAuthService: IAuthService; const ARole: string);
  end;

implementation

{ TLoggingMiddleware }

constructor TLoggingMiddleware.Create(const ALogger: ILogger);
begin
  inherited Create;
  FLogger := ALogger;
end;

procedure TLoggingMiddleware.Execute(Context: TNavigationContext; Next: TNavigationNext);
var
  ActionStr: string;
begin
  case Context.Action of
    naPush: ActionStr := 'Push';
    naPop: ActionStr := 'Pop';
    naReplace: ActionStr := 'Replace';
    naPopUntil: ActionStr := 'PopUntil';
  end;
  
  FLogger.Info('Navigation[%s]: %s -> %s', [ActionStr, Context.SourceRoute, Context.TargetRoute]);
  
  Next();
  
  if Context.Canceled then
    FLogger.Warn('Navigation canceled: %s', [Context.TargetRoute])
  else
    FLogger.Debug('Navigation completed: %s', [Context.TargetRoute]);
end;

{ TAuthMiddleware }

constructor TAuthMiddleware.Create(const AAuthService: IAuthService; const ALoginRoute: string);
begin
  inherited Create;
  FAuthService := AAuthService;
  FLoginRoute := ALoginRoute;
end;

procedure TAuthMiddleware.Execute(Context: TNavigationContext; Next: TNavigationNext);
begin
  // Skip auth check for login route
  if Context.TargetRoute = FLoginRoute then
  begin
    Next();
    Exit;
  end;
  
  if not FAuthService.IsAuthenticated then
  begin
    Context.Cancel;
    // Store intended destination for redirect after login
    Context.SetItem('redirectAfterLogin', Context.TargetRoute);
  end
  else
    Next();
end;

{ TRoleMiddleware }

constructor TRoleMiddleware.Create(const AAuthService: IAuthService; 
  const ARequiredRole: string; const AAccessDeniedRoute: string);
begin
  inherited Create;
  FAuthService := AAuthService;
  FRequiredRole := ARequiredRole;
  FAccessDeniedRoute := AAccessDeniedRoute;
end;

procedure TRoleMiddleware.Execute(Context: TNavigationContext; Next: TNavigationNext);
begin
  if not FAuthService.HasRole(FRequiredRole) then
  begin
    Context.Cancel;
    Context.SetItem('requiredRole', FRequiredRole);
  end
  else
    Next();
end;

{ TAnalyticsMiddleware }

constructor TAnalyticsMiddleware.Create(const AOnTrack: TProc<string, string, TNavParams>);
begin
  inherited Create;
  FOnTrack := AOnTrack;
end;

procedure TAnalyticsMiddleware.Execute(Context: TNavigationContext; Next: TNavigationNext);
begin
  // Track before navigation
  if Assigned(FOnTrack) then
    FOnTrack(Context.SourceRoute, Context.TargetRoute, Context.Params);
    
  Next();
end;

{ TConfirmNavigationMiddleware }

constructor TConfirmNavigationMiddleware.Create(const AConfirmFunc: TFunc<string, Boolean>;
  const AMessage: string);
begin
  inherited Create;
  FConfirmFunc := AConfirmFunc;
  FMessage := AMessage;
end;

procedure TConfirmNavigationMiddleware.Execute(Context: TNavigationContext; Next: TNavigationNext);
var
  Navigable: INavigableView;
begin
  // Check if source view has unsaved changes
  if Assigned(Context.SourceView) and Supports(Context.SourceView, INavigableView, Navigable) then
  begin
    if not Navigable.CanNavigateAway then
    begin
      // Ask for confirmation
      if Assigned(FConfirmFunc) and not FConfirmFunc(FMessage) then
      begin
        Context.Cancel;
        Exit;
      end;
    end;
  end;
  
  Next();
end;

{ TBaseNavigationGuard }

function TBaseNavigationGuard.CanActivate(Context: TNavigationContext): Boolean;
begin
  Result := DoCanActivate(Context);
end;

{ TAuthGuard }

constructor TAuthGuard.Create(const AAuthService: IAuthService);
begin
  inherited Create;
  FAuthService := AAuthService;
end;

function TAuthGuard.DoCanActivate(Context: TNavigationContext): Boolean;
begin
  Result := FAuthService.IsAuthenticated;
end;

{ TRoleGuard }

constructor TRoleGuard.Create(const AAuthService: IAuthService; const ARole: string);
begin
  inherited Create;
  FAuthService := AAuthService;
  FRole := ARole;
end;

function TRoleGuard.DoCanActivate(Context: TNavigationContext): Boolean;
begin
  Result := FAuthService.HasRole(FRole);
end;

end.
