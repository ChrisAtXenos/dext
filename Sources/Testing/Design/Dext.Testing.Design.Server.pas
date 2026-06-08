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
  TGetSelectedTestsEvent = function: string of object;

  { Lightweight Winsock TCP Server running in background to receive test results }
  TTestRunnerServerThread = class(TThread)
  private
    FPort: Word;
    FSocket: TSocket;
    FOnTestResult: TTestResultEvent;
    FOnGetSelectedTests: TGetSelectedTestsEvent;
    procedure TriggerTestResult(const AData: string);
  protected
    procedure Execute; override;
  public
    constructor Create(APort: Word; AOnTestResult: TTestResultEvent; AOnGetSelectedTests: TGetSelectedTestsEvent);
    destructor Destroy; override;
  end;

  TTestRunnerServer = class
  private
    FThread: TTestRunnerServerThread;
    FPort: Word;
    FOnTestResult: TTestResultEvent;
    FSelectedTestsJSON: string;
    function HandleGetSelectedTests: string;
    function GetPort: Word;
  public
    constructor Create(APort: Word = 8102);
    destructor Destroy; override;
    procedure Start(AOnTestResult: TTestResultEvent);
    procedure Stop;
    property Port: Word read GetPort;
    property SelectedTestsJSON: string read FSelectedTestsJSON write FSelectedTestsJSON;
  end;

implementation

uses
  System.IOUtils;

procedure LogServerDebug(const AMsg: string);
var
  LFile: string;
begin
  LFile := 'C:\dev\Dext\dext_server_debug.log';
  try
    TFile.AppendAllText(LFile, DateTimeToStr(Now) + ' [Thread:' + GetCurrentThreadId.ToString + ']: ' + AMsg + sLineBreak, TEncoding.UTF8);
  except
    // ignore
  end;
end;

{ TTestRunnerServerThread }

constructor TTestRunnerServerThread.Create(APort: Word; AOnTestResult: TTestResultEvent; AOnGetSelectedTests: TGetSelectedTestsEvent);
begin
  inherited Create(True);
  FPort := APort;
  FOnTestResult := AOnTestResult;
  FOnGetSelectedTests := AOnGetSelectedTests;
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
  ResponseStr: string;
  AddrLen: Integer;
begin
  LogServerDebug('Execute started. Port: ' + FPort.ToString);
  if WSAStartup(MakeWord(2, 2), WSAData) <> 0 then
  begin
    LogServerDebug('WSAStartup failed');
    Exit;
  end;

  try
    FSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if FSocket = INVALID_SOCKET then
    begin
      LogServerDebug('Socket creation failed');
      Exit;
    end;

    Addr.sin_family := AF_INET;
    Addr.sin_port := htons(FPort);
    Addr.sin_addr.S_addr := INADDR_ANY;

    if bind(FSocket, PSockAddr(@Addr)^, SizeOf(Addr)) = SOCKET_ERROR then
    begin
      LogServerDebug('Bind failed on port ' + FPort.ToString + '. Error: ' + WSAGetLastError.ToString + '. Trying port 0 (dynamic)...');
      Addr.sin_port := htons(0);
      if bind(FSocket, PSockAddr(@Addr)^, SizeOf(Addr)) = SOCKET_ERROR then
      begin
        LogServerDebug('Bind failed on port 0. Error: ' + WSAGetLastError.ToString);
        Exit;
      end;
    end;

    // Retrieve the actual bound port
    AddrLen := SizeOf(Addr);
    if getsockname(FSocket, PSockAddr(@Addr)^, AddrLen) = 0 then
    begin
      FPort := ntohs(Addr.sin_port);
      LogServerDebug('Successfully bound to port: ' + FPort.ToString);
    end
    else
    begin
      LogServerDebug('getsockname failed. Error: ' + WSAGetLastError.ToString);
    end;

    if listen(FSocket, SOMAXCONN) = SOCKET_ERROR then
    begin
      LogServerDebug('Listen failed. Error: ' + WSAGetLastError.ToString);
      Exit;
    end;

    LogServerDebug('Server successfully listening on port ' + FPort.ToString);

    while not Terminated do
    begin
      ClientSock := accept(FSocket, nil, nil);
      if ClientSock = INVALID_SOCKET then
      begin
        if Terminated then Break;
        LogServerDebug('Accept failed or socket closed');
        Continue;
      end;

      LogServerDebug('Connection accepted');

      // Read HTTP Request
      RequestStr := '';
      repeat
        BytesReceived := recv(ClientSock, Buffer[0], SizeOf(Buffer) - 1, 0);
        if BytesReceived <= 0 then Break;
        Buffer[BytesReceived] := #0;
        RequestStr := RequestStr + string(AnsiString(Buffer));
      until (BytesReceived < SizeOf(Buffer) - 1) or (Pos(#13#10#13#10, RequestStr) > 0);

      LogServerDebug('Request header read. Bytes: ' + Length(RequestStr).ToString);

      // Simple HTTP POST and GET parser
      if RequestStr.StartsWith('POST') then
      begin
        BodyPos := Pos(#13#10#13#10, RequestStr);
        if BodyPos > 0 then
        begin
          ContentLength := 0;
          HeaderPos := Pos('content-length:', LowerCase(RequestStr));
          if HeaderPos > 0 then
          begin
            LenStr := Copy(RequestStr, HeaderPos + 15, 20);
            HeaderPos := Pos(#13#10, LenStr);
            if HeaderPos > 0 then
              LenStr := Copy(LenStr, 1, HeaderPos - 1);
            ContentLength := StrToIntDef(Trim(LenStr), 0);
          end;

          JSONBody := Copy(RequestStr, BodyPos + 4, Length(RequestStr));
          LogServerDebug('POST detected. BodyPos: ' + BodyPos.ToString + ', parsed Content-Length: ' + ContentLength.ToString + ', current JSONBody length: ' + Length(JSONBody).ToString);
          
          // If we haven't read the full body yet, read the remaining
          while (Length(JSONBody) < ContentLength) and not Terminated do
          begin
            BytesReceived := recv(ClientSock, Buffer[0], SizeOf(Buffer) - 1, 0);
            if BytesReceived <= 0 then Break;
            Buffer[BytesReceived] := #0;
            JSONBody := JSONBody + string(AnsiString(Buffer));
          end;

          LogServerDebug('JSONBody complete: ' + JSONBody);

          // Dispatch result to Main UI Thread
          if JSONBody <> '' then
          begin
            LogServerDebug('Queueing TriggerTestResult to main thread');
            TThread.Queue(nil, TThreadProcedure(procedure
              begin
                TriggerTestResult(JSONBody);
              end));
          end;
        end;

        // Send 200 OK Response
        ResponseStr := 'HTTP/1.1 200 OK'#13#10 +
                       'Content-Type: application/json'#13#10 +
                       'Content-Length: 15'#13#10 +
                       'Connection: close'#13#10#13#10 +
                       '{"status":"ok"}';
        send(ClientSock, PAnsiChar(AnsiString(ResponseStr))[0], Length(ResponseStr), 0);
      end
      else if RequestStr.StartsWith('GET') then
      begin
        LogServerDebug('GET detected: ' + RequestStr);
        if Pos('/options', RequestStr) > 0 then
        begin
          ResponseStr := 'HTTP/1.1 200 OK'#13#10 +
                        'Content-Type: application/json'#13#10 +
                        'Connection: close'#13#10#13#10 +
                        '{"executeTests":true,"showProgress":true}';
          send(ClientSock, PAnsiChar(AnsiString(ResponseStr))[0], Length(ResponseStr), 0);
        end
        else if Pos('/tests', RequestStr) > 0 then
        begin
          JSONBody := '[]';
          if Assigned(FOnGetSelectedTests) then
            JSONBody := FOnGetSelectedTests();

          ResponseStr := 'HTTP/1.1 200 OK'#13#10 +
                        'Content-Type: application/json'#13#10 +
                        'Connection: close'#13#10#13#10 +
                        JSONBody;
          send(ClientSock, PAnsiChar(AnsiString(ResponseStr))[0], Length(ResponseStr), 0);
        end
        else
        begin
          ResponseStr := 'HTTP/1.1 404 Not Found'#13#10 +
                        'Content-Length: 0'#13#10 +
                        'Connection: close'#13#10#13#10;
          send(ClientSock, PAnsiChar(AnsiString(ResponseStr))[0], Length(ResponseStr), 0);
        end;
      end;

      closesocket(ClientSock);
    end;

  finally
    LogServerDebug('Execute finished. Closing listening socket.');
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
  FSelectedTestsJSON := '[]';
end;

destructor TTestRunnerServer.Destroy;
begin
  Stop;
  inherited;
end;

function TTestRunnerServer.HandleGetSelectedTests: string;
begin
  Result := FSelectedTestsJSON;
end;

function TTestRunnerServer.GetPort: Word;
begin
  if Assigned(FThread) then
    Result := FThread.FPort
  else
    Result := FPort;
end;

procedure TTestRunnerServer.Start(AOnTestResult: TTestResultEvent);
begin
  Stop;
  FOnTestResult := AOnTestResult;
  FThread := TTestRunnerServerThread.Create(FPort, FOnTestResult, HandleGetSelectedTests);
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
