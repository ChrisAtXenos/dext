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
/// Dext.UI - Facade unit for Dext UI Framework
///
/// This unit provides convenient aliases and re-exports for the
/// Model-View-Update (MVU) architecture components and Navigator.
///
/// Usage:
///   uses Dext.UI;
/// </summary>
unit Dext.UI;

interface

uses
  Dext.UI.Attributes,
  Dext.UI.Binder,
  Dext.UI.Message,
  Dext.UI.Module,
  Dext.UI.State,
  Dext.UI.Navigator.Types,
  Dext.UI.Navigator.Interfaces,
  Dext.UI.Navigator,
  Dext.UI.Navigator.Adapters,
  Dext.UI.Navigator.Middlewares;

type
  // ==========================================
  // Binding Attributes
  // ==========================================
  BindText = Dext.UI.Attributes.BindTextAttribute;
  BindChecked = Dext.UI.Attributes.BindCheckedAttribute;
  BindEnabled = Dext.UI.Attributes.BindEnabledAttribute;
  BindVisible = Dext.UI.Attributes.BindVisibleAttribute;
  BindItems = Dext.UI.Attributes.BindItemsAttribute;
  OnClickMsg = Dext.UI.Attributes.OnClickMsgAttribute;
  OnChangeMsg = Dext.UI.Attributes.OnChangeMsgAttribute;
  
  // ==========================================
  // Core MVU Types
  // ==========================================
  TMessage = Dext.UI.Message.TMessage;
  
  // Binder - use Dext.UI.Binder.TMVUBinder<TModel, TMsg> directly
  // (Delphi does not support generic type aliases)
  
  // State
  IStateStore = Dext.UI.State.IStateStore;
  TStateStore = Dext.UI.State.TStateStore;
  
  // ==========================================
  // Navigator Types
  // ==========================================
  TNavigationAction = Dext.UI.Navigator.Types.TNavigationAction;
  TNavParams = Dext.UI.Navigator.Types.TNavParams;
  TNavigationResult = Dext.UI.Navigator.Types.TNavigationResult;
  TNavigationContext = Dext.UI.Navigator.Types.TNavigationContext;
  TNavigationNext = Dext.UI.Navigator.Types.TNavigationNext;
  THistoryEntry = Dext.UI.Navigator.Types.THistoryEntry;
  
  // ==========================================
  // Navigator Interfaces
  // ==========================================
  INavigableView = Dext.UI.Navigator.Interfaces.INavigableView;
  INavigationMiddleware = Dext.UI.Navigator.Interfaces.INavigationMiddleware;
  INavigationGuard = Dext.UI.Navigator.Interfaces.INavigationGuard;
  INavigatorAdapter = Dext.UI.Navigator.Interfaces.INavigatorAdapter;
  INavigator = Dext.UI.Navigator.Interfaces.INavigator;
  IRouteBuilder = Dext.UI.Navigator.Interfaces.IRouteBuilder;
  IAuthService = Dext.UI.Navigator.Interfaces.IAuthService;
  
  // ==========================================
  // Navigator Implementation
  // ==========================================
  TNavigator = Dext.UI.Navigator.TNavigator;
  TRouteBuilder = Dext.UI.Navigator.TRouteBuilder;
  
  // ==========================================
  // Navigator Adapters
  // ==========================================
  TBaseNavigatorAdapter = Dext.UI.Navigator.Adapters.TBaseNavigatorAdapter;
  TCustomContainerAdapter = Dext.UI.Navigator.Adapters.TCustomContainerAdapter;
  {$IFDEF VCL}
  TPageControlAdapter = Dext.UI.Navigator.Adapters.TPageControlAdapter;
  TMDIAdapter = Dext.UI.Navigator.Adapters.TMDIAdapter;
  {$ENDIF}
  
  // ==========================================
  // Navigator Middlewares
  // ==========================================
  TLoggingMiddleware = Dext.UI.Navigator.Middlewares.TLoggingMiddleware;
  TAuthMiddleware = Dext.UI.Navigator.Middlewares.TAuthMiddleware;
  TRoleMiddleware = Dext.UI.Navigator.Middlewares.TRoleMiddleware;
  TAnalyticsMiddleware = Dext.UI.Navigator.Middlewares.TAnalyticsMiddleware;
  TConfirmNavigationMiddleware = Dext.UI.Navigator.Middlewares.TConfirmNavigationMiddleware;
  
  // ==========================================
  // Navigator Guards
  // ==========================================
  TBaseNavigationGuard = Dext.UI.Navigator.Middlewares.TBaseNavigationGuard;
  TAuthGuard = Dext.UI.Navigator.Middlewares.TAuthGuard;
  TRoleGuard = Dext.UI.Navigator.Middlewares.TRoleGuard;

implementation

end.
