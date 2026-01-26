{***************************************************************************}
{                                                                           }
{           Dext Framework - Example                                        }
{                                                                           }
{           Counter Model - MVU State representation                        }
{                                                                           }
{***************************************************************************}
unit Counter.Model;

interface

type
  /// <summary>
  /// The Model represents the entire state of the counter feature.
  /// It is immutable - we never modify it, we create a new one.
  /// </summary>
  TCounterModel = record
    Count: Integer;
    Step: Integer;
    History: string;
    
    /// <summary>Creates a new model with default values</summary>
    class function Init: TCounterModel; static;
    
    /// <summary>Creates a copy with Count updated</summary>
    function WithCount(const NewCount: Integer): TCounterModel;
    
    /// <summary>Creates a copy with Step updated</summary>
    function WithStep(const NewStep: Integer): TCounterModel;
    
    /// <summary>Creates a copy with History appended</summary>
    function WithHistory(const Action: string): TCounterModel;
  end;

implementation

uses
  System.SysUtils;

class function TCounterModel.Init: TCounterModel;
begin
  Result.Count := 0;
  Result.Step := 1;
  Result.History := '';
end;

function TCounterModel.WithCount(const NewCount: Integer): TCounterModel;
begin
  Result := Self;
  Result.Count := NewCount;
end;

function TCounterModel.WithStep(const NewStep: Integer): TCounterModel;
begin
  Result := Self;
  Result.Step := NewStep;
end;

function TCounterModel.WithHistory(const Action: string): TCounterModel;
begin
  Result := Self;
  if Result.History <> '' then
    Result.History := Action + sLineBreak + Result.History
  else
    Result.History := Action;
end;

end.
