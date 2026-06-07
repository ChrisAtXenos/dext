unit Dext.Testing.Design.Server;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  Winapi.Windows,
  Winapi.WinSock2;

type
  TTestResultEvent = procedure(const AJSONData: string) of object;

  { Lightweight Winsock TCP Server running in background to receive test results }
  TTestRunnerServerThread = class(TThread)
  private
    FPort: Word;
    FSocket: TSocket;
    FOnTestResult: TTestResultEvent;
    procedure TriggerTestResult(const AData: string);
  protected
    procedure Execute; override;
  public
    constructor Create(APort: Word; AOnTestResult: TTestResultEvent);
    destructor Destroy; override;
  end;

  TTestRunnerServer = class
  private
    FThread: TTestRunnerServerThread;
    FPort: Word;
    FOnTestResult: TTestResultEvent;
  public
    constructor Create(APort: Word = 8102);
    destructor Destroy; override;
    procedure Start(AOnTestResult: TTestResultEvent);
    procedure Stop;
    property Port: Word read FPort;
  end;

implementation

{ TTestRunnerServerThread }

constructor TTestRunnerServerThread.Create(APort: Word; AOnTestResult: TTestResultEvent);
begin
  inherited Create(True);
  FPort := APort;
  FOnTestResult := AOnTestResult;
  FSocket := INVALID_SOCKET;
  FreeOnTerminate := False;
end;

destructor TTestRunnerServerThread.Destroy;
begin
  if FSocket <> INVALID_SOCKET then
  begin
    closesocket(FSocket);
  end;
  inherited;
end;

procedure TTestRunnerServerThread.TriggerTestResult(const AData: string);
begin
  if Assigned(FOnTestResult) then
    FOnTestResult(AData);
end;

procedure TTestRunnerServerThread.Execute;
var
  WSAData: TWSAData;
  Addr: TSockAddrIn;
  ClientSock: TSocket;
  Buffer: array[0..8191] of AnsiChar;
  BytesReceived: Integer;
  RequestStr: string;
  ContentLength: Integer;
  BodyPos: Integer;
  JSONBody: string;
  HeaderPos: Integer;
  LenStr: string;
begin
  if WSAStartup(MakeWord(2, 2), WSAData) <> 0 then
    Exit;

  try
    FSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if FSocket = INVALID_SOCKET then
      Exit;

    Addr.sin_family := AF_INET;
    Addr.sin_port := htons(FPort);
    Addr.sin_addr.S_addr := INADDR_ANY;

    if bind(FSocket, PSockAddr(@Addr)^, SizeOf(Addr)) = SOCKET_ERROR then
      Exit;

    if listen(FSocket, SOMAXCONN) = SOCKET_ERROR then
      Exit;

    while not Terminated do
    begin
      ClientSock := accept(FSocket, nil, nil);
      if ClientSock = INVALID_SOCKET then
      begin
        if Terminated then Break;
        Continue;
      end;

      // Read HTTP Request
      RequestStr := '';
      repeat
        BytesReceived := recv(ClientSock, Buffer[0], SizeOf(Buffer) - 1, 0);
        if BytesReceived <= 0 then Break;
        Buffer[BytesReceived] := #0;
        RequestStr := RequestStr + string(AnsiString(Buffer));
      until (BytesReceived < SizeOf(Buffer) - 1) or (Pos(#13#10#13#10, RequestStr) > 0);

      // Simple HTTP POST parser
      if (RequestStr.StartsWith('POST')) then
      begin
        BodyPos := Pos(#13#10#13#10, RequestStr);
        if BodyPos > 0 then
        begin
          ContentLength := 0;
          HeaderPos := Pos('Content-Length:', RequestStr);
          if HeaderPos > 0 then
          begin
            LenStr := Copy(RequestStr, HeaderPos + 15, 20);
            HeaderPos := Pos(#13#10, LenStr);
            if HeaderPos > 0 then
              LenStr := Copy(LenStr, 1, HeaderPos - 1);
            ContentLength := StrToIntDef(Trim(LenStr), 0);
          end;

          JSONBody := Copy(RequestStr, BodyPos + 4, Length(RequestStr));
          
          // If we haven't read the full body yet, read the remaining
          while (Length(JSONBody) < ContentLength) and not Terminated do
          begin
            BytesReceived := recv(ClientSock, Buffer[0], SizeOf(Buffer) - 1, 0);
            if BytesReceived <= 0 then Break;
            Buffer[BytesReceived] := #0;
            JSONBody := JSONBody + string(AnsiString(Buffer));
          end;

          // Dispatch result to Main UI Thread
          if JSONBody <> '' then
          begin
            TThread.Queue(nil, TThreadProcedure(procedure
              begin
                TriggerTestResult(JSONBody);
              end));
          end;
        end;

        // Send 200 OK Response
        RequestStr := 'HTTP/1.1 200 OK'#13#10 +
                      'Content-Type: application/json'#13#10 +
                      'Content-Length: 15'#13#10 +
                      'Connection: close'#13#10#13#10 +
                      '{"status":"ok"}';
        send(ClientSock, PAnsiChar(AnsiString(RequestStr))[0], Length(RequestStr), 0);
      end;

      closesocket(ClientSock);
    end;

  finally
    if FSocket <> INVALID_SOCKET then
      closesocket(FSocket);
    WSACleanup;
  end;
end;

{ TTestRunnerServer }

constructor TTestRunnerServer.Create(APort: Word);
begin
  FPort := APort;
  FThread := nil;
end;

destructor TTestRunnerServer.Destroy;
begin
  Stop;
  inherited;
end;

procedure TTestRunnerServer.Start(AOnTestResult: TTestResultEvent);
begin
  Stop;
  FOnTestResult := AOnTestResult;
  FThread := TTestRunnerServerThread.Create(FPort, FOnTestResult);
  FThread.Start;
end;

procedure TTestRunnerServer.Stop;
begin
  if Assigned(FThread) then
  begin
    FThread.Terminate;
    // Close listening socket to unblock accept()
    if FThread.FSocket <> INVALID_SOCKET then
      closesocket(FThread.FSocket);
    FThread.WaitFor;
    FreeAndNil(FThread);
  end;
end;

end.
