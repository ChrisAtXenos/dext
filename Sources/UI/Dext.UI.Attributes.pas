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
/// Dext.UI.Attributes - Binding attributes for MVU pattern
///
/// These attributes enable declarative binding between UI controls
/// and the Model, reducing boilerplate code significantly.
///
/// Usage:
///   [BindText('PropertyName')]
///   MyLabel: TLabel;
///
///   [OnClickMsg(TMyMessage)]
///   MyButton: TButton;
/// </summary>
unit Dext.UI.Attributes;

interface

type
  {$REGION 'Model Binding Attributes'}
  
  /// <summary>
  /// Binds a Model property to a control's text/caption.
  /// Works with TLabel.Caption, TEdit.Text, TMemo.Text, etc.
  /// </summary>
  /// <example>
  /// [BindText('Count')]
  /// CountLabel: TLabel;  // Will display Model.Count
  ///
  /// [BindText('Price', '%.2f')]
  /// PriceLabel: TLabel;  // Will display formatted Model.Price
  /// </example>
  BindTextAttribute = class(TCustomAttribute)
  private
    FPropertyPath: string;
    FFormat: string;
  public
    constructor Create(const APropertyPath: string); overload;
    constructor Create(const APropertyPath, AFormat: string); overload;
    property PropertyPath: string read FPropertyPath;
    property Format: string read FFormat;
  end;
  
  /// <summary>
  /// Binds a Model boolean property to a control's Checked state.
  /// Works with TCheckBox, TRadioButton, etc.
  /// </summary>
  BindCheckedAttribute = class(TCustomAttribute)
  private
    FPropertyPath: string;
  public
    constructor Create(const APropertyPath: string);
    property PropertyPath: string read FPropertyPath;
  end;
  
  /// <summary>
  /// Binds a Model boolean property to a control's Enabled state.
  /// </summary>
  BindEnabledAttribute = class(TCustomAttribute)
  private
    FPropertyPath: string;
    FInvert: Boolean;
  public
    constructor Create(const APropertyPath: string; AInvert: Boolean = False);
    property PropertyPath: string read FPropertyPath;
    property Invert: Boolean read FInvert;
  end;
  
  /// <summary>
  /// Binds a Model boolean property to a control's Visible state.
  /// </summary>
  BindVisibleAttribute = class(TCustomAttribute)
  private
    FPropertyPath: string;
    FInvert: Boolean;
  public
    constructor Create(const APropertyPath: string; AInvert: Boolean = False);
    property PropertyPath: string read FPropertyPath;
    property Invert: Boolean read FInvert;
  end;
  
  /// <summary>
  /// Binds a Model list/array property to a listbox/combobox items.
  /// </summary>
  BindItemsAttribute = class(TCustomAttribute)
  private
    FPropertyPath: string;
    FDisplayMember: string;
  public
    constructor Create(const APropertyPath: string; const ADisplayMember: string = '');
    property PropertyPath: string read FPropertyPath;
    property DisplayMember: string read FDisplayMember;
  end;

  /// <summary>
  /// Binds a Model property to a TEdit.Text with two-way binding.
  /// </summary>
  BindEditAttribute = class(TCustomAttribute)
  private
    FPropertyPath: string;
  public
    constructor Create(const APropertyPath: string);
    property PropertyPath: string read FPropertyPath;
  end;

  /// <summary>
  /// Binds a Model property to a TMemo.Lines.Text with two-way binding.
  /// </summary>
  BindMemoAttribute = class(TCustomAttribute)
  private
    FPropertyPath: string;
  public
    constructor Create(const APropertyPath: string);
    property PropertyPath: string read FPropertyPath;
  end;
  
  {$ENDREGION}
  
  {$REGION 'Event/Message Attributes'}
  
  /// <summary>
  /// Dispatches a message when the control is clicked.
  /// The message type must have a parameterless constructor.
  /// </summary>
  /// <example>
  /// [OnClickMsg(TIncrementMessage)]
  /// IncrementButton: TButton;
  /// </example>
  OnClickMsgAttribute = class(TCustomAttribute)
  private
    FMessageClass: TClass;
  public
    constructor Create(AMessageClass: TClass);
    property MessageClass: TClass read FMessageClass;
  end;
  
  /// <summary>
  /// Dispatches a message when the control's value changes.
  /// The message class should accept the new value in constructor.
  /// </summary>
  OnChangeMsgAttribute = class(TCustomAttribute)
  private
    FMessageClass: TClass;
  public
    constructor Create(AMessageClass: TClass);
    property MessageClass: TClass read FMessageClass;
  end;
  
  /// <summary>
  /// Dispatches a message when the control gains focus.
  /// </summary>
  OnFocusMsgAttribute = class(TCustomAttribute)
  private
    FMessageClass: TClass;
  public
    constructor Create(AMessageClass: TClass);
    property MessageClass: TClass read FMessageClass;
  end;
  
  {$ENDREGION}

implementation

{ BindTextAttribute }

constructor BindTextAttribute.Create(const APropertyPath: string);
begin
  FPropertyPath := APropertyPath;
  FFormat := '';
end;

constructor BindTextAttribute.Create(const APropertyPath, AFormat: string);
begin
  FPropertyPath := APropertyPath;
  FFormat := AFormat;
end;

{ BindCheckedAttribute }

constructor BindCheckedAttribute.Create(const APropertyPath: string);
begin
  FPropertyPath := APropertyPath;
end;

{ BindEnabledAttribute }

constructor BindEnabledAttribute.Create(const APropertyPath: string; AInvert: Boolean);
begin
  FPropertyPath := APropertyPath;
  FInvert := AInvert;
end;

{ BindVisibleAttribute }

constructor BindVisibleAttribute.Create(const APropertyPath: string; AInvert: Boolean);
begin
  FPropertyPath := APropertyPath;
  FInvert := AInvert;
end;

{ BindItemsAttribute }

constructor BindItemsAttribute.Create(const APropertyPath: string; const ADisplayMember: string);
begin
  FPropertyPath := APropertyPath;
  FDisplayMember := ADisplayMember;
end;

{ BindEditAttribute }

constructor BindEditAttribute.Create(const APropertyPath: string);
begin
  FPropertyPath := APropertyPath;
end;

{ BindMemoAttribute }

constructor BindMemoAttribute.Create(const APropertyPath: string);
begin
  FPropertyPath := APropertyPath;
end;

{ OnClickMsgAttribute }

constructor OnClickMsgAttribute.Create(AMessageClass: TClass);
begin
  FMessageClass := AMessageClass;
end;

{ OnChangeMsgAttribute }

constructor OnChangeMsgAttribute.Create(AMessageClass: TClass);
begin
  FMessageClass := AMessageClass;
end;

{ OnFocusMsgAttribute }

constructor OnFocusMsgAttribute.Create(AMessageClass: TClass);
begin
  FMessageClass := AMessageClass;
end;

end.
