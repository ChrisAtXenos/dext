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
/// Dext.UI.Navigator.Adapters - Container adapters for different view hosts
///
/// This unit provides adapters for different container types:
/// - TCustomContainerAdapter: For panel/scrollbox based containers
/// - TPageControlAdapter: For PageControl/TabSheet based navigation
/// - TMDIAdapter: For MDI (Multiple Document Interface) windows
///
/// These adapters are cross-platform compatible (VCL/FMX) where the
/// container classes exist.
/// </summary>
unit Dext.UI.Navigator.Adapters;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Dext.UI.Navigator.Interfaces;

type
  /// <summary>
  /// Base adapter class with common functionality
  /// </summary>
  TBaseNavigatorAdapter = class(TInterfacedObject, INavigatorAdapter)
  protected
    FContainer: TComponent;
    FActiveView: TObject;
    FViews: TDictionary<string, TObject>;
    
    /// <summary>
    /// Template method: actually show the view in the container
    /// </summary>
    procedure DoShowView(View: TObject); virtual; abstract;
    
    /// <summary>
    /// Template method: actually hide the view
    /// </summary>
    procedure DoHideView(View: TObject); virtual; abstract;
    
    /// <summary>
    /// Template method: remove and destroy the view
    /// </summary>
    procedure DoRemoveView(View: TObject); virtual; abstract;
  public
    constructor Create(AContainer: TComponent);
    destructor Destroy; override;
    
    // INavigatorAdapter
    procedure ShowView(View: TObject; const Route: string); virtual;
    procedure HideView(View: TObject); virtual;
    procedure RemoveView(View: TObject); virtual;
    function GetActiveView: TObject; virtual;
    
    // Animation hooks - override for custom animations
    procedure OnBeforeShow(View: TObject); virtual;
    procedure OnAfterShow(View: TObject); virtual;
    procedure OnBeforeHide(View: TObject); virtual;
    procedure OnAfterHide(View: TObject); virtual;
  end;

  /// <summary>
  /// Adapter for custom container (Panel, ScrollBox, etc.)
  /// Views are shown as child controls of the container.
  /// </summary>
  TCustomContainerAdapter = class(TBaseNavigatorAdapter)
  protected
    procedure DoShowView(View: TObject); override;
    procedure DoHideView(View: TObject); override;
    procedure DoRemoveView(View: TObject); override;
  public
    constructor Create(AContainer: TComponent);
  end;

  {$IFDEF VCL}
  /// <summary>
  /// Adapter for TPageControl-based navigation (VCL)
  /// Each view is placed in its own TabSheet.
  /// </summary>
  TPageControlAdapter = class(TBaseNavigatorAdapter)
  private
    FTabSheets: TDictionary<TObject, TTabSheet>;
  protected
    procedure DoShowView(View: TObject); override;
    procedure DoHideView(View: TObject); override;
    procedure DoRemoveView(View: TObject); override;
  public
    constructor Create(APageControl: TPageControl);
    destructor Destroy; override;
  end;

  /// <summary>
  /// Adapter for MDI (Multiple Document Interface) navigation
  /// Each view is shown as an MDI child form.
  /// </summary>
  TMDIAdapter = class(TBaseNavigatorAdapter)
  protected
    procedure DoShowView(View: TObject); override;
    procedure DoHideView(View: TObject); override;
    procedure DoRemoveView(View: TObject); override;
  public
    constructor Create(AMDIParent: TForm);
  end;
  {$ENDIF}

implementation

uses
  {$IFDEF VCL}
  Vcl.Controls,
  Vcl.Forms,
  Vcl.ComCtrls,
  Vcl.ExtCtrls,
  {$ENDIF}
  {$IFDEF FMX}
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.TabControl,
  {$ENDIF}
  System.Rtti;

{ TBaseNavigatorAdapter }

constructor TBaseNavigatorAdapter.Create(AContainer: TComponent);
begin
  inherited Create;
  FContainer := AContainer;
  FViews := TDictionary<string, TObject>.Create;
end;

destructor TBaseNavigatorAdapter.Destroy;
begin
  FViews.Free;
  inherited;
end;

procedure TBaseNavigatorAdapter.ShowView(View: TObject; const Route: string);
begin
  FViews.AddOrSetValue(Route, View);
  FActiveView := View;
  DoShowView(View);
end;

procedure TBaseNavigatorAdapter.HideView(View: TObject);
begin
  DoHideView(View);
end;

procedure TBaseNavigatorAdapter.RemoveView(View: TObject);
var
  Pair: TPair<string, TObject>;
  RouteToRemove: string;
begin
  // Find and remove from dictionary
  RouteToRemove := '';
  for Pair in FViews do
  begin
    if Pair.Value = View then
    begin
      RouteToRemove := Pair.Key;
      Break;
    end;
  end;
  
  if RouteToRemove <> '' then
    FViews.Remove(RouteToRemove);
    
  if FActiveView = View then
    FActiveView := nil;
    
  DoRemoveView(View);
end;

function TBaseNavigatorAdapter.GetActiveView: TObject;
begin
  Result := FActiveView;
end;

procedure TBaseNavigatorAdapter.OnBeforeShow(View: TObject);
begin
  // Override for animations
end;

procedure TBaseNavigatorAdapter.OnAfterShow(View: TObject);
begin
  // Override for animations
end;

procedure TBaseNavigatorAdapter.OnBeforeHide(View: TObject);
begin
  // Override for animations
end;

procedure TBaseNavigatorAdapter.OnAfterHide(View: TObject);
begin
  // Override for animations
end;

{ TCustomContainerAdapter }

constructor TCustomContainerAdapter.Create(AContainer: TComponent);
begin
  inherited Create(AContainer);
end;

procedure TCustomContainerAdapter.DoShowView(View: TObject);
{$IFDEF VCL}
var
  WinControl: TWinControl;
  Frame: TFrame;
{$ENDIF}
begin
  {$IFDEF VCL}
  if View is TFrame then
  begin
    Frame := View as TFrame;
    
    if FContainer is TWinControl then
    begin
      WinControl := FContainer as TWinControl;
      Frame.Parent := WinControl;
      Frame.Align := alClient;
      Frame.Visible := True;
      Frame.BringToFront;
    end;
  end;
  {$ENDIF}
  
  {$IFDEF FMX}
  if View is TFrame then
  begin
    var FMXFrame := View as TFrame;
    if FContainer is TControl then
    begin
      FMXFrame.Parent := FContainer as TFmxObject;
      FMXFrame.Align := TAlignLayout.Client;
      FMXFrame.Visible := True;
      FMXFrame.BringToFront;
    end;
  end;
  {$ENDIF}
end;

procedure TCustomContainerAdapter.DoHideView(View: TObject);
{$IFDEF VCL}
var
  Control: TControl;
{$ENDIF}
begin
  {$IFDEF VCL}
  if View is TControl then
  begin
    Control := View as TControl;
    Control.Visible := False;
    Control.SendToBack;
  end;
  {$ENDIF}
  
  {$IFDEF FMX}
  if View is TControl then
  begin
    (View as TControl).Visible := False;
  end;
  {$ENDIF}
end;

procedure TCustomContainerAdapter.DoRemoveView(View: TObject);
{$IFDEF VCL}
var
  Control: TControl;
{$ENDIF}
begin
  {$IFDEF VCL}
  if View is TControl then
  begin
    Control := View as TControl;
    Control.Parent := nil;
    Control.Free;
  end;
  {$ENDIF}
  
  {$IFDEF FMX}
  if View is TControl then
  begin
    (View as TFmxObject).Parent := nil;
    View.Free;
  end;
  {$ENDIF}
end;

{$IFDEF VCL}
{ TPageControlAdapter }

constructor TPageControlAdapter.Create(APageControl: TPageControl);
begin
  inherited Create(APageControl);
  FTabSheets := TDictionary<TObject, TTabSheet>.Create;
end;

destructor TPageControlAdapter.Destroy;
begin
  FTabSheets.Free;
  inherited;
end;

procedure TPageControlAdapter.DoShowView(View: TObject);
var
  PageControl: TPageControl;
  TabSheet: TTabSheet;
  Frame: TFrame;
begin
  PageControl := FContainer as TPageControl;
  
  // Check if view already has a tab
  if FTabSheets.TryGetValue(View, TabSheet) then
  begin
    PageControl.ActivePage := TabSheet;
    Exit;
  end;
  
  // Create new tab
  TabSheet := TTabSheet.Create(PageControl);
  TabSheet.PageControl := PageControl;
  TabSheet.Caption := View.ClassName;
  
  if View is TFrame then
  begin
    Frame := View as TFrame;
    Frame.Parent := TabSheet;
    Frame.Align := alClient;
  end;
  
  FTabSheets.Add(View, TabSheet);
  PageControl.ActivePage := TabSheet;
end;

procedure TPageControlAdapter.DoHideView(View: TObject);
var
  TabSheet: TTabSheet;
begin
  if FTabSheets.TryGetValue(View, TabSheet) then
    TabSheet.TabVisible := False;
end;

procedure TPageControlAdapter.DoRemoveView(View: TObject);
var
  TabSheet: TTabSheet;
begin
  if FTabSheets.TryGetValue(View, TabSheet) then
  begin
    FTabSheets.Remove(View);
    TabSheet.Free;
  end;
  
  if View is TFrame then
    (View as TFrame).Free;
end;

{ TMDIAdapter }

constructor TMDIAdapter.Create(AMDIParent: TForm);
begin
  inherited Create(AMDIParent);
end;

procedure TMDIAdapter.DoShowView(View: TObject);
var
  Form: TForm;
begin
  if View is TForm then
  begin
    Form := View as TForm;
    Form.FormStyle := fsMDIChild;
    Form.Show;
    Form.BringToFront;
  end;
end;

procedure TMDIAdapter.DoHideView(View: TObject);
var
  Form: TForm;
begin
  if View is TForm then
  begin
    Form := View as TForm;
    Form.Hide;
  end;
end;

procedure TMDIAdapter.DoRemoveView(View: TObject);
var
  Form: TForm;
begin
  if View is TForm then
  begin
    Form := View as TForm;
    Form.Close;
    Form.Free;
  end;
end;
{$ENDIF}

end.
