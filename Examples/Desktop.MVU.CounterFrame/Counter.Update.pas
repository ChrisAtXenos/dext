{***************************************************************************}
{                                                                           }
{           Dext Framework - Example                                        }
{                                                                           }
{           Counter Update - Pure update function                           }
{                                                                           }
{***************************************************************************}
unit Counter.Update;

interface

uses
  Counter.Model,
  Counter.Messages;

type
  /// <summary>
  /// The Update function is PURE - it only depends on its inputs
  /// and has no side effects. Given a Model and a Message, returns a new Model.
  /// </summary>
  TCounterUpdate = class
  public
    class function Update(const Model: TCounterModel; const Msg: TCounterMsg): TCounterModel; static;
  end;

implementation

uses
  System.SysUtils;

class function TCounterUpdate.Update(const Model: TCounterModel;
  const Msg: TCounterMsg): TCounterModel;
begin
  Result := Model;
  
  if Msg is TIncrementMsg then
  begin
    Result := Model
      .WithCount(Model.Count + 1)
      .WithHistory(Format('[%s] +1 → %d', [FormatDateTime('hh:nn:ss', Now), Model.Count + 1]));
  end
  else if Msg is TDecrementMsg then
  begin
    Result := Model
      .WithCount(Model.Count - 1)
      .WithHistory(Format('[%s] -1 → %d', [FormatDateTime('hh:nn:ss', Now), Model.Count - 1]));
  end
  else if Msg is TIncrementByStepMsg then
  begin
    Result := Model
      .WithCount(Model.Count + Model.Step)
      .WithHistory(Format('[%s] +%d → %d', [FormatDateTime('hh:nn:ss', Now), Model.Step, Model.Count + Model.Step]));
  end
  else if Msg is TDecrementByStepMsg then
  begin
    Result := Model
      .WithCount(Model.Count - Model.Step)
      .WithHistory(Format('[%s] -%d → %d', [FormatDateTime('hh:nn:ss', Now), Model.Step, Model.Count - Model.Step]));
  end
  else if Msg is TResetMsg then
  begin
    Result := TCounterModel.Init
      .WithHistory(Format('[%s] RESET → 0', [FormatDateTime('hh:nn:ss', Now)]));
  end
  else if Msg is TSetStepMsg then
  begin
    Result := Model
      .WithStep(TSetStepMsg(Msg).Step)
      .WithHistory(Format('[%s] Step = %d', [FormatDateTime('hh:nn:ss', Now), TSetStepMsg(Msg).Step]));
  end;
end;

end.
