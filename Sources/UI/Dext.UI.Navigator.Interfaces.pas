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
/// Dext.UI.Navigator.Interfaces - Core interfaces for the Navigator framework
///
/// This unit defines the interfaces that form the contract for navigation:
/// - INavigableView: Views that can receive navigation events
/// - INavigationMiddleware: Middleware in the navigation pipeline
/// - INavigationGuard: Guards that protect routes
/// - INavigatorAdapter: Adapters for different view containers
/// - INavigator: The main navigation service
/// - IRouteBuilder: Fluent builder for route configuration
/// </summary>
unit Dext.UI.Navigator.Interfaces;

interface

uses
  System.SysUtils,
  System.Classes,
  Dext.UI.Navigator.Types;

type
  // Forward declarations
  INavigator = interface;
  IRouteBuilder = interface;

  /// <summary>
  /// Interface for views that can receive navigation events.
  /// Implement this on Frames/Forms that need to know about navigation.
  /// </summary>
  INavigableView = interface
    ['{B7E206D4-A6A4-4A2D-A2A6-D2C979E9B9A7}']
    
    /// <summary>
    /// Called when the view is navigated to
    /// </summary>
    procedure OnNavigatedTo(const Params: TNavParams);
    
    /// <summary>
    /// Called when navigating away from this view
    /// </summary>
    procedure OnNavigatedFrom;
    
    /// <summary>
    /// Check if the view allows navigation away (for unsaved changes, etc.)
    /// </summary>
    function CanNavigateAway: Boolean;
  end;

  /// <summary>
  /// Middleware interface for the navigation pipeline.
  /// Middlewares are executed in order for each navigation.
  /// </summary>
  INavigationMiddleware = interface
    ['{C8F317E5-B7B5-5B3E-B3B7-E3D080F0C0B8}']
    
    /// <summary>
    /// Execute the middleware logic.
    /// Call Next() to continue the pipeline, or don't call it to short-circuit.
    /// </summary>
    procedure Execute(Context: TNavigationContext; Next: TNavigationNext);
  end;

  /// <summary>
  /// Guard interface for protecting routes.
  /// Guards are checked before navigation proceeds.
  /// </summary>
  INavigationGuard = interface
    ['{38E86192-9DBC-4B7D-8001-3574F99BB2E5}']
    
    /// <summary>
    /// Check if navigation can proceed to this route
    /// </summary>
    function CanActivate(Context: TNavigationContext): Boolean;
  end;

  /// <summary>
  /// Adapter interface for view containers.
  /// Implement this to support different container types (PageControl, MDI, etc.)
  /// </summary>
  INavigatorAdapter = interface
    ['{1D481482-4E37-4D20-96FF-446D9D6183E2}']
    
    /// <summary>
    /// Show a view in the container
    /// </summary>
    procedure ShowView(View: TObject; const Route: string);
    
    /// <summary>
    /// Hide a view (but keep it in memory for history)
    /// </summary>
    procedure HideView(View: TObject);
    
    /// <summary>
    /// Remove and destroy a view from the container
    /// </summary>
    procedure RemoveView(View: TObject);
    
    /// <summary>
    /// Get the currently active/visible view
    /// </summary>
    function GetActiveView: TObject;
    
    /// <summary>
    /// Animation/transition hooks - called before showing a view
    /// </summary>
    procedure OnBeforeShow(View: TObject);
    
    /// <summary>
    /// Animation/transition hooks - called after showing a view
    /// </summary>
    procedure OnAfterShow(View: TObject);
    
    /// <summary>
    /// Animation/transition hooks - called before hiding a view
    /// </summary>
    procedure OnBeforeHide(View: TObject);
    
    /// <summary>
    /// Animation/transition hooks - called after hiding a view
    /// </summary>
    procedure OnAfterHide(View: TObject);
  end;

  /// <summary>
  /// Main Navigator interface.
  /// Provides navigation methods and configuration.
  /// </summary>
  INavigator = interface
    ['{221C9F39-DC6F-4DEE-953E-BEB99A6BE5E7}']
    
    // === Navigation Methods ===
    
    /// <summary>
    /// Push a new view onto the navigation stack
    /// </summary>
    function Push(ViewClass: TClass): INavigator; overload;
    function Push(ViewClass: TClass; const Params: TNavParams): INavigator; overload;
    
    /// <summary>
    /// Push using a registered route name
    /// </summary>
    function PushNamed(const Route: string): INavigator; overload;
    function PushNamed(const Route: string; const Params: TNavParams): INavigator; overload;
    
    /// <summary>
    /// Pop the current view and return to the previous one
    /// </summary>
    procedure Pop; overload;
    procedure Pop(const Result: TNavigationResult); overload;
    
    /// <summary>
    /// Pop views until reaching a specific view type
    /// </summary>
    procedure PopUntil(ViewClass: TClass);
    
    /// <summary>
    /// Replace the current view without adding to history
    /// </summary>
    function Replace(ViewClass: TClass): INavigator; overload;
    function Replace(ViewClass: TClass; const Params: TNavParams): INavigator; overload;
    
    /// <summary>
    /// Pop all views and push a new root view
    /// </summary>
    function PopAndPush(ViewClass: TClass): INavigator; overload;
    function PopAndPush(ViewClass: TClass; const Params: TNavParams): INavigator; overload;
    
    // === Configuration ===
    
    /// <summary>
    /// Set the adapter for view container management
    /// </summary>
    function UseAdapter(const Adapter: INavigatorAdapter): INavigator;
    
    /// <summary>
    /// Add a global middleware to the navigation pipeline
    /// </summary>
    function UseMiddleware(const Middleware: INavigationMiddleware): INavigator;
    
    /// <summary>
    /// Register a named route
    /// </summary>
    function Route(const Path: string): IRouteBuilder;
    
    /// <summary>
    /// Set the initial/home route
    /// </summary>
    function SetInitialRoute(ViewClass: TClass): INavigator;
    
    // === State ===
    
    /// <summary>
    /// Check if there's a view to go back to
    /// </summary>
    function CanGoBack: Boolean;
    
    /// <summary>
    /// Get the current route name
    /// </summary>
    function CurrentRoute: string;
    
    /// <summary>
    /// Get the current view instance
    /// </summary>
    function CurrentView: TObject;
    
    /// <summary>
    /// Get the navigation history as route names
    /// </summary>
    function History: TArray<string>;
    
    /// <summary>
    /// Get the number of views in the stack
    /// </summary>
    function StackDepth: Integer;
    
    // === Events ===
    
    /// <summary>
    /// Event fired before navigation (can be used for analytics)
    /// </summary>
    function OnNavigating(const Handler: TProc<TNavigationContext>): INavigator;
    
    /// <summary>
    /// Event fired after successful navigation
    /// </summary>
    function OnNavigated(const Handler: TProc<TNavigationContext>): INavigator;
  end;

  /// <summary>
  /// Fluent builder for route configuration
  /// </summary>
  IRouteBuilder = interface
    ['{A9201629-1E36-4C64-BF11-EEB350D97F8D}']
    
    /// <summary>
    /// Require authentication for this route
    /// </summary>
    function RequireAuth: IRouteBuilder;
    
    /// <summary>
    /// Require a specific role for this route
    /// </summary>
    function RequireRole(const Role: string): IRouteBuilder;
    
    /// <summary>
    /// Add a guard to this route
    /// </summary>
    function UseGuard(const Guard: INavigationGuard): IRouteBuilder;
    
    /// <summary>
    /// Add a middleware to this route
    /// </summary>
    function UseMiddleware(const Middleware: INavigationMiddleware): IRouteBuilder;
    
    /// <summary>
    /// Map this route to a view class
    /// </summary>
    function MapTo(ViewClass: TClass): IRouteBuilder;
    
    /// <summary>
    /// Return to the navigator for chaining
    /// </summary>
    function Build: INavigator;
  end;

  /// <summary>
  /// Authentication service interface for auth middleware
  /// </summary>
  IAuthService = interface
    ['{981A86E9-1FE6-441B-857D-90B0A70EF4CE}']
    function IsAuthenticated: Boolean;
    function HasRole(const Role: string): Boolean;
    function GetCurrentUser: TObject;
  end;

implementation

end.
