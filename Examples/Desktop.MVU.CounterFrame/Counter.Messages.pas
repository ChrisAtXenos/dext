{***************************************************************************}
{                                                                           }
{           Dext Framework - Example                                        }
{                                                                           }
{           Counter Messages - All possible user actions                    }
{                                                                           }
{***************************************************************************}
unit Counter.Messages;

interface

uses
  Dext.UI.Message;

type
  /// <summary>Base class for all counter messages</summary>
  TCounterMsg = class(TMessage)
  end;
  
  /// <summary>Increment count by 1</summary>
  TIncrementMsg = class(TCounterMsg)
  end;
  
  /// <summary>Decrement count by 1</summary>
  TDecrementMsg = class(TCounterMsg)
  end;
  
  /// <summary>Increment count by current step</summary>
  TIncrementByStepMsg = class(TCounterMsg)
  end;
  
  /// <summary>Decrement count by current step</summary>
  TDecrementByStepMsg = class(TCounterMsg)
  end;
  
  /// <summary>Reset count to zero</summary>
  TResetMsg = class(TCounterMsg)
  end;
  
  /// <summary>Set step to a specific value</summary>
  TSetStepMsg = class(TCounterMsg)
  private
    FStep: Integer;
  public
    constructor Create(AStep: Integer); reintroduce;
    property Step: Integer read FStep;
  end;

implementation

{ TSetStepMsg }

constructor TSetStepMsg.Create(AStep: Integer);
begin
  inherited Create;
  FStep := AStep;
end;

end.
