unit Dext.Web.Sessions.Streamable;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.SyncObjs,
  Dext.Collections,
  Dext.Collections.Dict,
  Dext.Collections.Queue,
  Dext.Web.Interfaces,
  Dext.Threading.CancellationToken,
  Dext.Threading.Sync;

type
  TSseEvent = record
    EventName: string;
    Data: string;
    constructor Create(const AEventName, AData: string);
  end;

  TStreamableSession = class(TInterfacedObject, IStreamableSession)
  private
    FId: string;
    FState: IDictionary<string, TValue>;
    FEvents: IQueue<TSseEvent>;
    FLock: TDextMREW;
    FLastAccessed: TDateTime;
    FClosed: Boolean;
    function GetId: string;
  public
    constructor Create(const AId: string);
    destructor Destroy; override;

    // State management
    procedure SetState(const AKey: string; const AValue: TValue);
    function GetState(const AKey: string): TValue;
    procedure RemoveState(const AKey: string);
    
    // Server-Side Event Methods
    procedure SendSseEvent(const AEventName, AData: string);
    function HasEvents: Boolean;
    function TryDequeueEvent(out AEventName, AData: string): Boolean;
    
    // Internal Lifecycle
    procedure Touch;
    function IsExpired(AIdleTimeoutMinutes: Integer): Boolean;
    procedure Close;
    property LastAccessed: TDateTime read FLastAccessed;
  end;

  TInMemoryStreamableSessionManager = class(TInterfacedObject, IStreamableSessionManager, IEventStreamer)

  private
    FSessions: IDictionary<string, IStreamableSession>;
    FLock: TDextMREW;
    FStopEvent: TEvent;             // signaled by StopScavenger for immediate wake
    FStoppingToken: ICancellationToken; // host ApplicationStopping token
  public
    constructor Create;
    destructor Destroy; override;

    function CreateSession: IStreamableSession;
    function GetSession(const ASessionId: string): IStreamableSession;
    procedure DestroySession(const ASessionId: string);

    // GC can be called from a background task or during requests
    procedure CollectGarbage(AIdleTimeoutMinutes: Integer);

    // Lifecycle control
    procedure StartScavenger(AIntervalSeconds: Integer = 60; ATimeoutMinutes: Integer = 30;
      const AStoppingToken: ICancellationToken = nil);
    procedure StopScavenger;

    // IEventStreamer
    procedure PushEvent(const AEventName, AData: string);
    procedure PushEventTo(const ASessionId, AEventName, AData: string);

  private
    FScavengerThread: TThread;
    FScavengerInterval: Integer;
    FScavengerTimeout: Integer;
  end;

  TScavengerThread = class(TThread)
  private
    [Weak] FManager: IStreamableSessionManager;
    FStopEvent: TEvent;
    FInterval: Integer;
    FTimeout: Integer;
    FToken: ICancellationToken;
  public
    constructor Create(AManager: IStreamableSessionManager; AStopEvent: TEvent;
      AInterval, ATimeout: Integer; const AToken: ICancellationToken);
    procedure Execute; override;
  end;

implementation

{ TSseEvent }

constructor TSseEvent.Create(const AEventName, AData: string);
begin
  EventName := AEventName;
  Data := AData;
end;

{ TStreamableSession }

constructor TStreamableSession.Create(const AId: string);
begin
  inherited Create;
  FId := AId;
  FState := TCollections.CreateDictionary<string, TValue>;
  FEvents := TCollections.CreateQueue<TSseEvent>;
  FLastAccessed := Now;
  FClosed := False;
end;

destructor TStreamableSession.Destroy;
begin
  FState := nil;
  FEvents := nil;
  inherited;
end;

procedure TStreamableSession.Touch;
begin
  FLock.BeginWrite;
  try
    FLastAccessed := Now;
  finally
    FLock.EndWrite;
  end;
end;

procedure TStreamableSession.Close;
begin
  FLock.BeginWrite;
  try
    FClosed := True;
  finally
    FLock.EndWrite;
  end;
end;

function TStreamableSession.IsExpired(AIdleTimeoutMinutes: Integer): Boolean;
var
  Diff: Double;
begin
  FLock.BeginRead;
  try
    if FClosed then Exit(True);
    Diff := (Now - FLastAccessed) * 24 * 60; // diff in minutes
    Result := Diff >= AIdleTimeoutMinutes;
  finally
    FLock.EndRead;
  end;
end;

function TStreamableSession.GetId: string;
begin
  Result := FId;
end;

function TStreamableSession.GetState(const AKey: string): TValue;
begin
  FLock.BeginRead;
  try
    if not FState.TryGetValue(AKey, Result) then
      Result := TValue.Empty;
  finally
    FLock.EndRead;
  end;
end;

procedure TStreamableSession.SetState(const AKey: string; const AValue: TValue);
begin
  FLock.BeginWrite;
  try
    FState.AddOrSetValue(AKey, AValue);
    FLastAccessed := Now;
  finally
    FLock.EndWrite;
  end;
end;

procedure TStreamableSession.RemoveState(const AKey: string);
begin
  FLock.BeginWrite;
  try
    FState.Remove(AKey);
    FLastAccessed := Now;
  finally
    FLock.EndWrite;
  end;
end;

procedure TStreamableSession.SendSseEvent(const AEventName, AData: string);
begin
  FLock.BeginWrite;
  try
    if not FClosed then
    begin
      FEvents.Enqueue(TSseEvent.Create(AEventName, AData));
      FLastAccessed := Now;
    end;
  finally
    FLock.EndWrite;
  end;
end;

function TStreamableSession.HasEvents: Boolean;
begin
  FLock.BeginRead;
  try
    Result := (not FClosed) and (FEvents.Count > 0);
  finally
    FLock.EndRead;
  end;
end;

function TStreamableSession.TryDequeueEvent(out AEventName, AData: string): Boolean;
var
  Evt: TSseEvent;
begin
  AEventName := '';
  AData := '';
  
  FLock.BeginWrite;
  try
    if FClosed or (FEvents.Count = 0) then
      Exit(False);
      
    Evt := FEvents.Dequeue;
    AEventName := Evt.EventName;
    AData := Evt.Data;
    Result := True;
  finally
    FLock.EndWrite;
  end;
end;

{ TInMemoryStreamableSessionManager }

constructor TInMemoryStreamableSessionManager.Create;
begin
  inherited Create;
  FSessions   := TCollections.CreateDictionary<string, IStreamableSession>;
  FStopEvent  := TEvent.Create(nil, True, False, ''); // manual-reset, initially unsignaled
  FScavengerThread := nil;
end;

destructor TInMemoryStreamableSessionManager.Destroy;
begin
  StopScavenger;
  FSessions  := nil;
  FStopEvent.Free;
  inherited;
end;

function TInMemoryStreamableSessionManager.CreateSession: IStreamableSession;
var
  LId: string;
  LSession: TStreamableSession;
begin
  LId := TGUID.NewGuid.ToString.Replace('{', '').Replace('}', '').Replace('-', '').ToLower;
  LSession := TStreamableSession.Create(LId);

  FLock.BeginWrite;
  try
    FSessions.Add(LId, LSession); // interface ref keeps object alive
  finally
    FLock.EndWrite;
  end;

  Result := LSession;
end;

function TInMemoryStreamableSessionManager.GetSession(const ASessionId: string): IStreamableSession;
begin
  FLock.BeginRead;
  try
    if not FSessions.TryGetValue(ASessionId, Result) then
      Result := nil
    else
      (Result as TStreamableSession).Touch;
  finally
    FLock.EndRead;
  end;
end;

procedure TInMemoryStreamableSessionManager.DestroySession(const ASessionId: string);
var
  LSession: IStreamableSession;
begin
  FLock.BeginWrite;
  try
    if FSessions.TryGetValue(ASessionId, LSession) then
    begin
      (LSession as TStreamableSession).Close;
      FSessions.Remove(ASessionId);
    end;
  finally
    FLock.EndWrite;
  end;
end;

procedure TInMemoryStreamableSessionManager.CollectGarbage(AIdleTimeoutMinutes: Integer);
var
  LPair: TPair<string, IStreamableSession>;
  LToRemove: IList<string>;
  LSessionId: string;
  LSession: IStreamableSession;
begin
  LToRemove := TCollections.CreateList<string>;
  FLock.BeginRead;
  try
    for LPair in FSessions do
    begin
      if (LPair.Value as TStreamableSession).IsExpired(AIdleTimeoutMinutes) then
        LToRemove.Add(LPair.Key);
    end;
  finally
    FLock.EndRead;
  end;

  if LToRemove.Count > 0 then
  begin
    FLock.BeginWrite;
    try
      for LSessionId in LToRemove do
      begin
        if FSessions.TryGetValue(LSessionId, LSession) then
        begin
          (LSession as TStreamableSession).Close;
          FSessions.Remove(LSessionId);
        end;
      end;
    finally
      FLock.EndWrite;
    end;
  end;
end;

procedure TInMemoryStreamableSessionManager.StartScavenger(AIntervalSeconds,
  ATimeoutMinutes: Integer; const AStoppingToken: ICancellationToken);
begin
  StopScavenger;
  FScavengerInterval := AIntervalSeconds;
  FScavengerTimeout  := ATimeoutMinutes;
  FStoppingToken     := AStoppingToken;
  FStopEvent.ResetEvent;

  FScavengerThread := TScavengerThread.Create(Self, FStopEvent, FScavengerInterval, 
    FScavengerTimeout, FStoppingToken);
  FScavengerThread.Start;
end;

{ TScavengerThread }

constructor TScavengerThread.Create(AManager: IStreamableSessionManager;
  AStopEvent: TEvent; AInterval, ATimeout: Integer; const AToken: ICancellationToken);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FManager := AManager;
  FStopEvent := AStopEvent;
  FInterval := AInterval;
  FTimeout := ATimeout;
  FToken := AToken;
end;

procedure TScavengerThread.Execute;
var
  Elapsed, TargetMs: Cardinal;
  Mgr: IStreamableSessionManager;
begin
  TargetMs := Cardinal(FInterval) * 1000;
  Elapsed  := 0;

  while not Terminated and (FStopEvent.WaitFor(500) = wrTimeout) do
  begin
    if (FToken <> nil) and FToken.IsCancellationRequested then Exit;

    Inc(Elapsed, 500);
    if Elapsed >= TargetMs then
    begin
      Elapsed := 0;
      Mgr := FManager;
      if Mgr <> nil then
        (Mgr as TInMemoryStreamableSessionManager).CollectGarbage(FTimeout);
    end;
  end;
end;

procedure TInMemoryStreamableSessionManager.StopScavenger;
begin
  if FScavengerThread <> nil then
  begin
    FStopEvent.SetEvent;        // wake thread immediately
    FScavengerThread.Terminate;
    FScavengerThread.WaitFor;   // returns in ms, not 60s
    FreeAndNil(FScavengerThread);
  end;
end;

procedure TInMemoryStreamableSessionManager.PushEvent(const AEventName, AData: string);
var
  LPair: TPair<string, IStreamableSession>;
begin
  FLock.BeginRead;
  try
    for LPair in FSessions do
      LPair.Value.SendSseEvent(AEventName, AData);
  finally
    FLock.EndRead;
  end;
end;

procedure TInMemoryStreamableSessionManager.PushEventTo(const ASessionId, AEventName,
  AData: string);
var
  LSession: IStreamableSession;
begin
  FLock.BeginRead;
  try
    if FSessions.TryGetValue(ASessionId, LSession) then
      LSession.SendSseEvent(AEventName, AData);
  finally
    FLock.EndRead;
  end;
end;


end.
