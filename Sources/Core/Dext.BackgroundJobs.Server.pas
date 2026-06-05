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

unit Dext.BackgroundJobs.Server;

interface

uses
  System.SysUtils,
  System.Rtti,
  Dext.Threading.CancellationToken,
  Dext.Hosting.BackgroundService,
  Dext.DI.Interfaces,
  Dext.BackgroundJobs.Intf,
  Dext.BackgroundJobs.Config;

type
  TJobServer = class(TBackgroundService)
  private
    FStorage: IJobStorage;
    FServiceProvider: IServiceProvider;
    FOptions: TBackgroundJobsOptions;
    procedure ProcessJob(const Job: TJobInfo);
    function ResolveJobInstance(const AClassName: string): TObject;
  protected
    procedure Execute(Token: ICancellationToken); override;
  public
    constructor Create(const AStorage: IJobStorage; const AServiceProvider: IServiceProvider; const AOptions: TBackgroundJobsOptions);
  end;

implementation

uses
  System.Classes,
  Dext.Core.Activator;

{ TJobServer }

constructor TJobServer.Create(const AStorage: IJobStorage; const AServiceProvider: IServiceProvider; const AOptions: TBackgroundJobsOptions);
begin
  inherited Create;
  FStorage := AStorage;
  FServiceProvider := AServiceProvider;
  FOptions := AOptions;
end;

procedure TJobServer.Execute(Token: ICancellationToken);
var
  Job: TJobInfo;
  SleepCount: Integer;
  MaxSleep: Integer;
begin
  MaxSleep := FOptions.PollIntervalInSeconds * 10; // PollIntervalInSeconds * 1000ms divided by 100ms
  if MaxSleep <= 0 then
    MaxSleep := 50;

  while not Token.IsCancellationRequested do
  begin
    try
      if FStorage.GetNextJob('default', Job) then
      begin
        ProcessJob(Job);
      end
      else
      begin
        // Wait gracefully checking token every 100ms
        SleepCount := 0;
        while (SleepCount < MaxSleep) and (not Token.IsCancellationRequested) do
        begin
          Sleep(100);
          Inc(SleepCount);
        end;
      end;
    except
      on E: Exception do
      begin
        if Assigned(FLogger) then
          FLogger.LogError('Error in background job server execution loop: {0}', [E.Message]);
        Sleep(1000);
      end;
    end;
  end;
end;

function TJobServer.ResolveJobInstance(const AClassName: string): TObject;
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  ClassType: TClass;
begin
  RttiContext := TRttiContext.Create;
  try
    RttiType := RttiContext.FindType(AClassName);
    if not Assigned(RttiType) or (not (RttiType is TRttiInstanceType)) then
    begin
      // Try searching through loaded packages/units using class name
      for RttiType in RttiContext.GetTypes do
      begin
        if SameText(RttiType.Name, AClassName) and (RttiType is TRttiInstanceType) then
        begin
          ClassType := TRttiInstanceType(RttiType).MetaclassType;
          Result := TActivator.CreateInstance(FServiceProvider, ClassType);
          Exit;
        end;
      end;
      raise EClassNotFound.CreateFmt('Class %s not found in RTTI context.', [AClassName]);
    end;
    ClassType := TRttiInstanceType(RttiType).MetaclassType;
    Result := TActivator.CreateInstance(FServiceProvider, ClassType);
  finally
    RttiContext.Free;
  end;
end;

procedure TJobServer.ProcessJob(const Job: TJobInfo);
var
  Instance: TObject;
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiMethod: TRttiMethod;
  Params: TArray<TValue>;
begin
  Instance := nil;
  RttiContext := TRttiContext.Create;
  try
    try
      Instance := ResolveJobInstance(Job.JobType);
      if not Assigned(Instance) then
        raise EClassNotFound.CreateFmt('Could not instantiate job class: %s', [Job.JobType]);

      RttiType := RttiContext.GetType(Instance.ClassType);
      RttiMethod := RttiType.GetMethod(Job.MethodName);
      if not Assigned(RttiMethod) then
        raise Exception.CreateFmt('Method %s not found on class %s', [Job.MethodName, Job.JobType]);

      Params := TJobParamSerializer.Deserialize(Job.ParamsJson);
      
      // Invoke the method
      RttiMethod.Invoke(Instance, Params);

      FStorage.UpdateJobState(Job.Id, jsSucceeded);
    except
      on E: Exception do
      begin
        FStorage.UpdateJobState(Job.Id, jsFailed, E.Message);
        if Assigned(FLogger) then
          FLogger.LogError('Failed to process job {0}: {1}', [Job.Id, E.Message]);
      end;
    end;
  finally
    if Assigned(Instance) then
      Instance.Free;
    RttiContext.Free;
  end;
end;

end.
