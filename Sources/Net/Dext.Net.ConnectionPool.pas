unit Dext.Net.ConnectionPool;

interface

uses
  System.Classes,
  Dext.Collections,
  Dext.Collections.Stack,
  Dext.Net.Engine,
  System.SyncObjs,
  System.SysUtils;

type
  /// <summary>
  ///   Connection Pool for IDextHttpEngine instances to improve performance through reuse.
  /// </summary>
  TConnectionPool = class
  private
    FPool: IStack<IDextHttpEngine>;
    FLock: TCriticalSection;
    FMaxPoolSize: Integer;
    FCount: Integer;
  public
    constructor Create(AMaxPoolSize: Integer = 32);
    destructor Destroy; override;
    
    function Acquire: IDextHttpEngine;
    procedure Release(AClient: IDextHttpEngine);
    procedure Clear;
    
    property MaxPoolSize: Integer read FMaxPoolSize write FMaxPoolSize;
    property CurrentCount: Integer read FCount;
  end;

implementation

{ TConnectionPool }

constructor TConnectionPool.Create(AMaxPoolSize: Integer);
begin
  inherited Create;
  FMaxPoolSize := AMaxPoolSize;
  FPool := TCollections.CreateStack<IDextHttpEngine>;
  FLock := TCriticalSection.Create;
  FCount := 0;
end;

destructor TConnectionPool.Destroy;
begin
  Clear;
  // FPool is ARC managed
  FLock.Free;
  inherited;
end;

function TConnectionPool.Acquire: IDextHttpEngine;
begin
  FLock.Enter;
  try
    if FPool.Count > 0 then
    begin
      Result := FPool.Pop;
    end
    else
    begin
      Result := CreateHttpEngine;
      Inc(FCount);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TConnectionPool.Release(AClient: IDextHttpEngine);
begin
  if not Assigned(AClient) then Exit;
  
  FLock.Enter;
  try
    if FPool.Count < FMaxPoolSize then
    begin
      FPool.Push(AClient);
    end
    else
    begin
      Dec(FCount);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TConnectionPool.Clear;
begin
  FLock.Enter;
  try
    while FPool.Count > 0 do
      FPool.Pop;
    FCount := 0;
  finally
    FLock.Leave;
  end;
end;

end.
