{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{                                                                           }
{           Copyright (C) 2026 Cesar Romero & Dext Contributors             }
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
unit Dext.Testing.Integration;

interface

uses
  System.SysUtils,
  System.Classes;

type
  ITestRunnerIntegration = interface
    ['{BCB5C2DF-E81D-4A59-BF26-6DF4804FEA97}']
    function GetName: string;
    procedure Execute(const APort: Integer);
  end;

  TTestRunnerRegistry = class
  private
    class var FIntegrations: TInterfaceList;
    class function GetIntegrations: TInterfaceList; static;
  public
    class procedure RegisterIntegration(const AIntegration: ITestRunnerIntegration); static;
    class function TryExecuteFromCommandLine: Boolean; static;
  end;

implementation

{ TTestRunnerRegistry }

class function TTestRunnerRegistry.GetIntegrations: TInterfaceList;
begin
  if FIntegrations = nil then
    FIntegrations := TInterfaceList.Create;
  Result := FIntegrations;
end;

class procedure TTestRunnerRegistry.RegisterIntegration(const AIntegration: ITestRunnerIntegration);
begin
  GetIntegrations.Add(AIntegration);
end;

class function TTestRunnerRegistry.TryExecuteFromCommandLine: Boolean;
var
  PortStr: string;
  Port: Integer;
  Intf: IInterface;
  Runner: ITestRunnerIntegration;
begin
  Result := False;
  if FindCmdLineSwitch('port', PortStr, True) then
  begin
    Port := StrToIntDef(PortStr, 8102);
    if GetIntegrations.Count > 0 then
    begin
      Intf := GetIntegrations[0];
      if Supports(Intf, ITestRunnerIntegration, Runner) then
      begin
        Runner.Execute(Port);
        Result := True;
      end;
    end;
  end;
end;

initialization

finalization
  if TTestRunnerRegistry.FIntegrations <> nil then
    TTestRunnerRegistry.FIntegrations.Free;

end.
