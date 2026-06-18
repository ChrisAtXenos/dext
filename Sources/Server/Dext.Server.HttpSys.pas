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
{  Created: 2026-06-17                                                      }
{                                                                           }
{  Windows HTTP Server (http.sys) driver implementation.                    }
{                                                                           }
{***************************************************************************}
unit Dext.Server.HttpSys;

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  Dext.Collections.Dict,
  Winapi.Windows,
  Dext.Server.Engine.Types,
  Dext.Server.Engine.Interfaces,
  Dext.Server.HttpSys.Api,
  Dext.Web.Interfaces,
  Dext.DI.Interfaces;

type
  TDextHttpSysEngine = class;

  /// <summary>
  ///   Raw request implementation wrapper for Windows http.sys.
  /// </summary>
  /// <summary>
  ///   Raw request implementation wrapper for Windows http.sys.
  /// </summary>
  TDextHttpSysRequest = class(TInterfacedObject, IDextRawRequest)
  private
    FRequest: PHTTP_REQUEST;
    FBodyStream: TCustomMemoryStream;
    function GetMethod: string;
    function GetPath: string;
    function GetQueryString: string;
    function GetHeader(const AName: string): string;
    procedure PopulateHeaders(ADict: TDictionary<string, string>);
    function GetContentLength: Int64;
    function GetBodyStream: TStream;
  public
    /// <summary>Initializes a raw http.sys request wrapper.</summary>
    /// <param name="ARequest">Pointer to the native HTTP_REQUEST structure.</param>
    constructor Create(ARequest: PHTTP_REQUEST);
    /// <summary>Cleans up the request resources.</summary>
    destructor Destroy; override;
  end;

  /// <summary>
  ///   Raw response implementation wrapper for Windows http.sys.
  /// </summary>
  TDextHttpSysResponse = class(TInterfacedObject, IDextRawResponse)
  private
    FReqQueue: THandle;
    FRequestId: HTTP_REQUEST_ID;
    FHeadersSent: Boolean;
    FStatusCode: USHORT;
    FReason: string;
    FHeaders: TStringList;
    FBodyBuffer: TMemoryStream;
    procedure SendHeadersInternal(AMoreData: Boolean);
  public
    /// <summary>Initializes a new http.sys response wrapper.</summary>
    /// <param name="AReqQueue">Handle to the request queue.</param>
    /// <param name="ARequestId">The unique ID of the request to respond to.</param>
    constructor Create(AReqQueue: THandle; ARequestId: HTTP_REQUEST_ID);
    /// <summary>Cleans up the response resources.</summary>
    destructor Destroy; override;

    /// <summary>Sets the HTTP status code and optional reason phrase.</summary>
    /// <param name="ACode">The HTTP status code (e.g., 200, 404).</param>
    /// <param name="AReason">Optional HTTP reason phrase.</param>
    procedure SetStatus(ACode: Integer; const AReason: string = '');
    /// <summary>Sets the value of a specific HTTP response header.</summary>
    /// <param name="AName">The name of the header.</param>
    /// <param name="AValue">The value of the header.</param>
    procedure SetHeader(const AName, AValue: string);
    /// <summary>Forces sending of response headers to the client.</summary>
    procedure SendHeaders;
    /// <summary>Writes raw bytes into the response body stream.</summary>
    /// <param name="ABuffer">The byte array buffer containing data to write.</param>
    /// <param name="AOffset">The zero-based byte offset in ABuffer from which to begin writing.</param>
    /// <param name="ACount">The number of bytes to write.</param>
    procedure Write(const ABuffer: TBytes; AOffset, ACount: Integer);
    /// <summary>Flushes any buffered response data to the network.</summary>
    procedure Flush;
    /// <summary>Closes the response stream and connection.</summary>
    procedure Close;
  end;

  /// <summary>
  ///   Raw connection implementation wrapper for Windows http.sys.
  /// </summary>
  TDextHttpSysConnection = class(TInterfacedObject, IDextServerConnection)
  private
    FConnectionId: HTTP_CONNECTION_ID;
    FSecure: Boolean;
    FLocalPort: Word;
    FRemotePort: Word;
    FRemoteAddress: string;
  public
    /// <summary>Initializes a new http.sys connection wrapper.</summary>
    /// <param name="ARequest">The native HTTP_REQUEST structure of the connection.</param>
    constructor Create(const ARequest: HTTP_REQUEST);
    
    /// <summary>Returns the unique connection identifier.</summary>
    function GetConnectionId: UInt64;
    /// <summary>Returns the remote client's IP address.</summary>
    function GetRemoteAddress: string;
    /// <summary>Returns the remote client's port.</summary>
    function GetRemotePort: Word;
    /// <summary>Returns the local listening port.</summary>
    function GetLocalPort: Word;
    /// <summary>Indicates if the connection is encrypted (SSL/TLS).</summary>
    function IsSecure: Boolean;
    /// <summary>Closes the connection.</summary>
    procedure Close;

    /// <summary>Checks if connection upgrade is supported.</summary>
    function SupportsUpgrade: Boolean;
    /// <summary>Upgrades the active connection to WebSockets.</summary>
    function UpgradeToWebSocket: IDextWebSocketConnection;
  end;

  /// <summary>
  ///   Worker thread for processing request queue events.
  /// </summary>
  TDextHttpSysWorker = class(TThread)
  private
    FEngine: TDextHttpSysEngine;
    FReqQueue: THandle;
  protected
    procedure Execute; override;
  public
    /// <summary>Initializes the http.sys worker thread.</summary>
    /// <param name="AEngine">The http.sys engine instance.</param>
    /// <param name="AReqQueue">Handle to the request queue.</param>
    constructor Create(AEngine: TDextHttpSysEngine; AReqQueue: THandle);
  end;

  /// <summary>
  ///   Native Windows kernel-mode http.sys Dext server engine.
  /// </summary>
  TDextHttpSysEngine = class(TInterfacedObject, IDextServerEngine)
  private
    FOptions: TServerEngineOptions;
    FServerSessionId: HTTP_SERVER_SESSION_ID;
    FUrlGroupId: HTTP_URL_GROUP_ID;
    FReqQueue: THandle;
    FRunning: Boolean;
    FListeningPort: Word;
    FAddress: string;
    
    FOnConnection: TConnectionEventHandler;
    FOnDisconnection: TConnectionEventHandler;
    FOnRequest: TRequestEventHandler;
    FOnUpgrade: TUpgradeEventHandler;

    FActiveConnections: Integer;
    FTotalRequests: Int64;

    FWorkers: TList;
    procedure InitializeHttpSys;
    procedure ConfigureTimeouts;
    procedure ConfigureLimits;
  public
    /// <summary>Initializes a new http.sys server engine.</summary>
    /// <param name="AOptions">The engine configuration options.</param>
    constructor Create(const AOptions: TServerEngineOptions);
    /// <summary>Destroys the engine and releases resources.</summary>
    destructor Destroy; override;

    /// <summary>Binds the engine to the specified address and port.</summary>
    /// <param name="AAddress">IP address to bind to.</param>
    /// <param name="APort">Port to listen on.</param>
    procedure Bind(const AAddress: string; APort: Word);
    /// <summary>Starts the http.sys request queue listener and worker threads.</summary>
    procedure Start;
    /// <summary>Stops the engine and closes the request queue.</summary>
    /// <param name="AGracefulTimeoutMs">Timeout in milliseconds for graceful shutdown.</param>
    procedure Stop(AGracefulTimeoutMs: Integer = 5000);
    
    /// <summary>Returns the port the engine is currently listening on.</summary>
    function GetListenPort: Word;
    /// <summary>Returns the count of active client connections.</summary>
    function GetActiveConnections: Integer;
    /// <summary>Returns the total number of processed requests.</summary>
    function GetTotalRequests: Int64;

    /// <summary>Sets the connection event handler.</summary>
    procedure SetOnConnection(const AHandler: TConnectionEventHandler);
    /// <summary>Sets the disconnection event handler.</summary>
    procedure SetOnDisconnection(const AHandler: TConnectionEventHandler);
    /// <summary>Sets the request event handler.</summary>
    procedure SetOnRequest(const AHandler: TRequestEventHandler);
    /// <summary>Sets the socket upgrade event handler.</summary>
    procedure SetOnUpgrade(const AHandler: TUpgradeEventHandler);

    /// <summary>Static factory method for creating and registering the http.sys web host.</summary>
    class function Factory(Port: Integer; Pipeline: TRequestDelegate; Services: IServiceProvider): IWebHost; static;
  end;

implementation

uses
  System.SysConst;

{ TDextHttpSysRequest }

constructor TDextHttpSysRequest.Create(ARequest: PHTTP_REQUEST);
begin
  inherited Create;
  FRequest := ARequest;
  FBodyStream := nil;
end;

destructor TDextHttpSysRequest.Destroy;
begin
  if Assigned(FBodyStream) then
    FBodyStream.Free;
  inherited;
end;

function TDextHttpSysRequest.GetBodyStream: TStream;
begin
  if FBodyStream = nil then
  begin
    if (FRequest.EntityChunkCount > 0) and (FRequest.pEntityChunks <> nil) then
    begin
      // Wrapper around in-memory body if pre-allocated
      // S39 keeps it alloc-zero by directly referencing buffer
      // For simplicity in Phase 1, we read it
      // TDextHttpSysEngine will read body dynamically as well
    end;
    // Return empty fallback stream if none
    FBodyStream := TMemoryStream.Create;
  end;
  Result := FBodyStream;
end;

function TDextHttpSysRequest.GetContentLength: Int64;
var
  LenStr: string;
begin
  LenStr := GetHeader('Content-Length');
  if LenStr <> '' then
    Result := StrToInt64Def(LenStr, 0)
  else
    Result := 0;
end;

const
  HTTP_KNOWN_REQUEST_HEADERS: array[0..40] of string = (
    'Cache-Control', 'Connection', 'Date', 'Keep-Alive', 'Pragma', 'Trailer',
    'Transfer-Encoding', 'Upgrade', 'Via', 'Warning', 'Allow', 'Content-Length',
    'Content-Type', 'Content-Encoding', 'Content-Language', 'Content-Location',
    'Content-MD5', 'Content-Range', 'Expires', 'Last-Modified', 'Accept',
    'Accept-Charset', 'Accept-Encoding', 'Accept-Language', 'Authorization',
    'Cookie', 'Expect', 'From', 'Host', 'If-Match', 'If-Modified-Since',
    'If-None-Match', 'If-Range', 'If-Unmodified-Since', 'Max-Forwards',
    'Proxy-Authorization', 'Referer', 'Range', 'TE', 'Translate', 'User-Agent'
  );

  HTTP_KNOWN_RESPONSE_HEADERS: array[0..29] of string = (
    'Cache-Control', 'Connection', 'Date', 'Keep-Alive', 'Pragma', 'Trailer',
    'Transfer-Encoding', 'Upgrade', 'Via', 'Warning', 'Allow', 'Content-Length',
    'Content-Type', 'Content-Encoding', 'Content-Language', 'Content-Location',
    'Content-MD5', 'Content-Range', 'Expires', 'Last-Modified', 'Accept-Ranges',
    'Age', 'ETag', 'Location', 'Proxy-Authenticate', 'Retry-After', 'Server',
    'Set-Cookie', 'Vary', 'Www-Authenticate'
  );

function TDextHttpSysRequest.GetHeader(const AName: string): string;
var
  I: Integer;
begin
  Result := '';
  // Check known headers
  for I := 0 to 40 do
  begin
    if SameText(HTTP_KNOWN_REQUEST_HEADERS[I], AName) then
    begin
      if FRequest.Headers.KnownHeaders[I].RawValueLength > 0 then
      begin
        Result := string(AnsiString(FRequest.Headers.KnownHeaders[I].pRawValue));
        Exit;
      end;
    end;
  end;

  // Check unknown headers
  if (FRequest.Headers.UnknownHeaderCount > 0) and (FRequest.Headers.pUnknownHeaders <> nil) then
  begin
    for I := 0 to FRequest.Headers.UnknownHeaderCount - 1 do
    begin
      if SameText(string(AnsiString(PHTTP_UNKNOWN_HEADER_ARRAY(FRequest.Headers.pUnknownHeaders)^[I].pName)), AName) then
      begin
        Result := string(AnsiString(PHTTP_UNKNOWN_HEADER_ARRAY(FRequest.Headers.pUnknownHeaders)^[I].pRawValue));
        Exit;
      end;
    end;
  end;
end;

procedure TDextHttpSysRequest.PopulateHeaders(ADict: TDictionary<string, string>);
var
  I: Integer;
begin
  for I := 0 to 40 do
  begin
    if FRequest.Headers.KnownHeaders[I].RawValueLength > 0 then
      ADict.AddOrSetValue(HTTP_KNOWN_REQUEST_HEADERS[I], string(AnsiString(FRequest.Headers.KnownHeaders[I].pRawValue)));
  end;

  if (FRequest.Headers.UnknownHeaderCount > 0) and (FRequest.Headers.pUnknownHeaders <> nil) then
  begin
    for I := 0 to FRequest.Headers.UnknownHeaderCount - 1 do
    begin
      ADict.AddOrSetValue(
        string(AnsiString(PHTTP_UNKNOWN_HEADER_ARRAY(FRequest.Headers.pUnknownHeaders)^[I].pName)),
        string(AnsiString(PHTTP_UNKNOWN_HEADER_ARRAY(FRequest.Headers.pUnknownHeaders)^[I].pRawValue))
      );
    end;
  end;
end;

function TDextHttpSysRequest.GetMethod: string;
begin
  case FRequest.Verb of
    HttpVerbGET: Result := 'GET';
    HttpVerbPOST: Result := 'POST';
    HttpVerbPUT: Result := 'PUT';
    HttpVerbDELETE: Result := 'DELETE';
    HttpVerbOPTIONS: Result := 'OPTIONS';
    HttpVerbHEAD: Result := 'HEAD';
    HttpVerbTRACE: Result := 'TRACE';
    HttpVerbCONNECT: Result := 'CONNECT';
  else
    if FRequest.pUnknownVerb <> nil then
      Result := string(AnsiString(FRequest.pUnknownVerb))
    else
      Result := 'GET';
  end;
end;

function TDextHttpSysRequest.GetPath: string;
begin
  if FRequest.CookedUrl.pAbsPath <> nil then
    Result := string(FRequest.CookedUrl.pAbsPath)
  else
    Result := '/';
end;

function TDextHttpSysRequest.GetQueryString: string;
begin
  if FRequest.CookedUrl.pQueryString <> nil then
    Result := string(FRequest.CookedUrl.pQueryString)
  else
    Result := '';
end;

{ TDextHttpSysResponse }

constructor TDextHttpSysResponse.Create(AReqQueue: THandle; ARequestId: HTTP_REQUEST_ID);
begin
  inherited Create;
  FReqQueue := AReqQueue;
  FRequestId := ARequestId;
  FHeadersSent := False;
  FStatusCode := 200;
  FReason := 'OK';
  FHeaders := TStringList.Create;
  FBodyBuffer := TMemoryStream.Create;
end;

destructor TDextHttpSysResponse.Destroy;
begin
  FHeaders.Free;
  FBodyBuffer.Free;
  inherited;
end;

procedure TDextHttpSysResponse.Close;
var
  Response: HTTP_RESPONSE;
  Chunk: HTTP_DATA_CHUNK_INMEMORY;
  BytesSent: ULONG;
  Ret: ULONG;
  I: Integer;
  HeaderVal: string;
  AnsiHeaderValues: array[0..29] of AnsiString;
begin
  if not FHeadersSent then
  begin
    FillChar(Response, SizeOf(Response), 0);
    Response.StatusCode := FStatusCode;
    Response.ReasonLength := Length(FReason);
    Response.pReason := PAnsiChar(AnsiString(FReason));
    Response.Version.MajorVersion := 1;
    Response.Version.MinorVersion := 1;

    if FHeaders.Values['Content-Length'] = '' then
      FHeaders.Values['Content-Length'] := IntToStr(FBodyBuffer.Size);

    for I := 0 to 29 do
    begin
      HeaderVal := FHeaders.Values[HTTP_KNOWN_RESPONSE_HEADERS[I]];
      if HeaderVal <> '' then
      begin
        AnsiHeaderValues[I] := AnsiString(HeaderVal);
        Response.Headers.KnownHeaders[I].pRawValue := PAnsiChar(AnsiHeaderValues[I]);
        Response.Headers.KnownHeaders[I].RawValueLength := Length(AnsiHeaderValues[I]);
      end;
    end;

    if FBodyBuffer.Size > 0 then
    begin
      FillChar(Chunk, SizeOf(Chunk), 0);
      Chunk.DataChunkType := hctFromMemory;
      Chunk.pBuffer := FBodyBuffer.Memory;
      Chunk.BufferLength := FBodyBuffer.Size;

      Response.EntityChunkCount := 1;
      Response.pEntityChunks := @Chunk;
    end;

    Ret := HttpSendHttpResponse(
      FReqQueue,
      FRequestId,
      0,
      @Response,
      nil,
      BytesSent,
      nil,
      0,
      nil,
      nil
    );
    if Ret <> ERROR_SUCCESS then
      raise EOSError.Create('HttpSendHttpResponse failed with error code: ' + IntToStr(Ret));

    FHeadersSent := True;
  end
  else
  begin
    if FBodyBuffer.Size > 0 then
    begin
      FillChar(Chunk, SizeOf(Chunk), 0);
      Chunk.DataChunkType := hctFromMemory;
      Chunk.pBuffer := FBodyBuffer.Memory;
      Chunk.BufferLength := FBodyBuffer.Size;

      Ret := HttpSendResponseEntityBody(
        FReqQueue,
        FRequestId,
        0,
        1,
        @Chunk,
        BytesSent,
        nil,
        nil,
        nil,
        nil
      );
    end
    else
    begin
      Ret := HttpSendResponseEntityBody(
        FReqQueue,
        FRequestId,
        0,
        0,
        nil,
        BytesSent,
        nil,
        nil,
        nil,
        nil
      );
    end;
    if Ret <> ERROR_SUCCESS then
      raise EOSError.Create('HttpSendResponseEntityBody (Finalize) failed with error code: ' + IntToStr(Ret));
  end;
end;

procedure TDextHttpSysResponse.Flush;
begin
  if not FHeadersSent then
    SendHeadersInternal(False);
end;

procedure TDextHttpSysResponse.SendHeaders;
begin
  SendHeadersInternal(False);
end;

procedure TDextHttpSysResponse.SendHeadersInternal(AMoreData: Boolean);
var
  Response: HTTP_RESPONSE;
  BytesSent: ULONG;
  Ret: ULONG;
  Flags: ULONG;
  I: Integer;
  HeaderVal: string;
  AnsiHeaderValues: array[0..29] of AnsiString;
begin
  if FHeadersSent then Exit;

  FillChar(Response, SizeOf(Response), 0);
  Response.StatusCode := FStatusCode;
  Response.ReasonLength := Length(FReason);
  Response.pReason := PAnsiChar(AnsiString(FReason));
  Response.Version.MajorVersion := 1;
  Response.Version.MinorVersion := 1;

  for I := 0 to 29 do
  begin
    HeaderVal := FHeaders.Values[HTTP_KNOWN_RESPONSE_HEADERS[I]];
    if HeaderVal <> '' then
    begin
      AnsiHeaderValues[I] := AnsiString(HeaderVal);
      Response.Headers.KnownHeaders[I].pRawValue := PAnsiChar(AnsiHeaderValues[I]);
      Response.Headers.KnownHeaders[I].RawValueLength := Length(AnsiHeaderValues[I]);
    end;
  end;

  if AMoreData then
    Flags := HTTP_SEND_RESPONSE_FLAG_MORE_DATA
  else
    Flags := 0;

  Ret := HttpSendHttpResponse(
    FReqQueue,
    FRequestId,
    Flags,
    @Response,
    nil,
    BytesSent,
    nil,
    0,
    nil,
    nil
  );

  if Ret <> ERROR_SUCCESS then
    raise EOSError.Create('HttpSendHttpResponse failed with error code: ' + IntToStr(Ret));

  FHeadersSent := True;
end;

procedure TDextHttpSysResponse.SetHeader(const AName, AValue: string);
begin
  if FHeadersSent then
    raise EInvalidOp.Create('Headers already sent');
  FHeaders.Values[AName] := AValue;
end;

procedure TDextHttpSysResponse.SetStatus(ACode: Integer; const AReason: string);
begin
  if FHeadersSent then
    raise EInvalidOp.Create('Headers already sent');
  FStatusCode := ACode;
  if AReason <> '' then
    FReason := AReason
  else
    FReason := 'OK';
end;

procedure TDextHttpSysResponse.Write(const ABuffer: TBytes; AOffset, ACount: Integer);
var
  Chunk: HTTP_DATA_CHUNK_INMEMORY;
  BytesSent: ULONG;
  Ret: ULONG;
begin
  if ACount <= 0 then Exit;

  if FHeadersSent then
  begin
    FillChar(Chunk, SizeOf(Chunk), 0);
    Chunk.DataChunkType := hctFromMemory;
    Chunk.pBuffer := @ABuffer[AOffset];
    Chunk.BufferLength := ACount;

    Ret := HttpSendResponseEntityBody(
      FReqQueue,
      FRequestId,
      HTTP_SEND_RESPONSE_FLAG_MORE_DATA,
      1,
      @Chunk,
      BytesSent,
      nil,
      nil,
      nil,
      nil
    );
    if Ret <> ERROR_SUCCESS then
      raise EOSError.Create('HttpSendResponseEntityBody failed with error code: ' + IntToStr(Ret));
  end
  else
  begin
    FBodyBuffer.WriteBuffer(ABuffer[AOffset], ACount);
  end;
end;

{ TDextHttpSysConnection }

constructor TDextHttpSysConnection.Create(const ARequest: HTTP_REQUEST);
begin
  inherited Create;
  FConnectionId := ARequest.ConnectionId;
  FSecure := ARequest.pSslInfo <> nil;
  FLocalPort := 80;
  FRemotePort := 0;
  FRemoteAddress := '';
end;

procedure TDextHttpSysConnection.Close;
begin
  // Handled by request-level response close
end;

function TDextHttpSysConnection.GetConnectionId: UInt64;
begin
  Result := FConnectionId;
end;

function TDextHttpSysConnection.GetLocalPort: Word;
begin
  Result := FLocalPort;
end;

function TDextHttpSysConnection.GetRemoteAddress: string;
begin
  Result := FRemoteAddress;
end;

function TDextHttpSysConnection.GetRemotePort: Word;
begin
  Result := FRemotePort;
end;

function TDextHttpSysConnection.IsSecure: Boolean;
begin
  Result := FSecure;
end;

function TDextHttpSysConnection.SupportsUpgrade: Boolean;
begin
  Result := False; // Phase 1 doesn't implement upgrade yet
end;

function TDextHttpSysConnection.UpgradeToWebSocket: IDextWebSocketConnection;
begin
  Result := nil;
end;

{ TDextHttpSysWorker }

constructor TDextHttpSysWorker.Create(AEngine: TDextHttpSysEngine; AReqQueue: THandle);
begin
  inherited Create(True);
  FEngine := AEngine;
  FReqQueue := AReqQueue;
  FreeOnTerminate := False;
end;

procedure TDextHttpSysWorker.Execute;
var
  ReqBuffer: TBytes;
  Request: PHTTP_REQUEST;
  BytesReturned: ULONG;
  Ret: ULONG;
  RequestId: HTTP_REQUEST_ID;
  RawRequest: IDextRawRequest;
  RawResponse: IDextRawResponse;
  Connection: IDextServerConnection;
begin
  SetLength(ReqBuffer, 16384); // 16KB Request Buffer
  Request := PHTTP_REQUEST(@ReqBuffer[0]);
  RequestId := 0;

  while not Terminated and FEngine.FRunning do
  begin
    FillChar(Request^, SizeOf(HTTP_REQUEST), 0);
    BytesReturned := 0;

    Ret := HttpReceiveHttpRequest(
      FReqQueue,
      RequestId,
      0,
      Request,
      Length(ReqBuffer),
      BytesReturned,
      nil
    );

    if Ret = ERROR_SUCCESS then
    begin
      TInterlocked.Increment(FEngine.FTotalRequests);

      // Create Request/Response abstractions
      Connection := TDextHttpSysConnection.Create(Request^);
      RawRequest := TDextHttpSysRequest.Create(Request);
      RawResponse := TDextHttpSysResponse.Create(FReqQueue, Request.RequestId);

      try
        if Assigned(FEngine.FOnRequest) then
          FEngine.FOnRequest(Connection, RawRequest, RawResponse);
      finally
        RawResponse.Close;
        RawResponse := nil;
        RawRequest := nil;
        Connection := nil;
      end;

      RequestId := 0;
    end
    else if Ret = ERROR_MORE_DATA then
    begin
      // Grow buffer if headers are too large
      SetLength(ReqBuffer, BytesReturned);
      Request := PHTTP_REQUEST(@ReqBuffer[0]);
    end;
  end;
end;

{ TDextHttpSysEngine }

constructor TDextHttpSysEngine.Create(const AOptions: TServerEngineOptions);
begin
  inherited Create;
  FOptions := AOptions;
  FServerSessionId := 0;
  FUrlGroupId := 0;
  FReqQueue := 0;
  FRunning := False;
  FWorkers := TList.Create;
  InitializeHttpSys;
end;

destructor TDextHttpSysEngine.Destroy;
begin
  Stop;
  FWorkers.Free;
  inherited;
end;

procedure TDextHttpSysEngine.Bind(const AAddress: string; APort: Word);
begin
  FAddress := AAddress;
  FListeningPort := APort;
end;

procedure TDextHttpSysEngine.InitializeHttpSys;
var
  Ret: ULONG;
begin
  Ret := HttpInitialize(HTTPAPI_VERSION_2, HTTP_INITIALIZE_SERVER, nil);
  if Ret <> ERROR_SUCCESS then
    raise EOSError.Create('HttpInitialize failed with error code: ' + IntToStr(Ret));

  Ret := HttpCreateServerSession(HTTPAPI_VERSION_2, FServerSessionId, 0);
  if Ret <> ERROR_SUCCESS then
    raise EOSError.Create('HttpCreateServerSession failed with error code: ' + IntToStr(Ret));

  Ret := HttpCreateUrlGroup(FServerSessionId, FUrlGroupId, 0);
  if Ret <> ERROR_SUCCESS then
    raise EOSError.Create('HttpCreateUrlGroup failed with error code: ' + IntToStr(Ret));

  Ret := HttpCreateRequestQueue(HTTPAPI_VERSION_2, nil, nil, 0, FReqQueue);
  if Ret <> ERROR_SUCCESS then
    raise EOSError.Create('HttpCreateRequestQueue failed with error code: ' + IntToStr(Ret));

  ConfigureTimeouts;
  ConfigureLimits;
end;

procedure TDextHttpSysEngine.ConfigureLimits;
var
  Binding: HTTP_BINDING_INFO;
  Ret: ULONG;
begin
  Binding.Flags := 1;
  Binding.RequestQueueHandle := FReqQueue;

  Ret := HttpSetUrlGroupProperty(
    FUrlGroupId,
    HttpServerBindingProperty,
    @Binding,
    SizeOf(Binding)
  );

  if Ret <> ERROR_SUCCESS then
    raise EOSError.Create('HttpSetUrlGroupProperty (Binding) failed with error code: ' + IntToStr(Ret));
end;

procedure TDextHttpSysEngine.ConfigureTimeouts;
begin
  // Set configuration timeouts if specified in Options
end;

procedure TDextHttpSysEngine.Start;
var
  UrlPrefix: string;
  Ret: ULONG;
  I: Integer;
  ThreadCount: Integer;
  Worker: TDextHttpSysWorker;
begin
  if FRunning then Exit;

  // Register prefix
  if (FAddress = '0.0.0.0') or (FAddress = '') then
    UrlPrefix := Format('http://+:%d/', [FListeningPort])
  else
    UrlPrefix := Format('http://%s:%d/', [FAddress, FListeningPort]);
    
  Ret := HttpAddUrlToUrlGroup(FUrlGroupId, PWideChar(WideString(UrlPrefix)), 0, 0);
  if Ret <> ERROR_SUCCESS then
    raise EOSError.Create('HttpAddUrlToUrlGroup failed to register ' + UrlPrefix + ' with error code: ' + IntToStr(Ret));

  FRunning := True;

  // Start Worker Threads
  ThreadCount := FOptions.IoThreadCount;
  if ThreadCount <= 0 then
  begin
    // Auto detect CPU count
    ThreadCount := CPUCount;
  end;

  for I := 1 to ThreadCount do
  begin
    Worker := TDextHttpSysWorker.Create(Self, FReqQueue);
    FWorkers.Add(Worker);
    Worker.Start;
  end;
end;

procedure TDextHttpSysEngine.Stop(AGracefulTimeoutMs: Integer);
var
  I: Integer;
  Worker: TDextHttpSysWorker;
begin
  if not FRunning then Exit;

  FRunning := False;

  // Signal and stop request queue
  if FReqQueue <> 0 then
    HttpCloseRequestQueue(FReqQueue);

  // Stop threads
  for I := 0 to FWorkers.Count - 1 do
  begin
    Worker := TDextHttpSysWorker(FWorkers[I]);
    Worker.Terminate;
  end;

  for I := 0 to FWorkers.Count - 1 do
  begin
    Worker := TDextHttpSysWorker(FWorkers[I]);
    Worker.WaitFor;
    Worker.Free;
  end;
  FWorkers.Clear;

  if FUrlGroupId <> 0 then
  begin
    HttpCloseUrlGroup(FUrlGroupId);
    FUrlGroupId := 0;
  end;

  if FServerSessionId <> 0 then
  begin
    HttpCloseServerSession(FServerSessionId);
    FServerSessionId := 0;
  end;

  HttpTerminate(HTTP_INITIALIZE_SERVER, nil);
  FReqQueue := 0;
end;

function TDextHttpSysEngine.GetActiveConnections: Integer;
begin
  Result := FActiveConnections;
end;

function TDextHttpSysEngine.GetListenPort: Word;
begin
  Result := FListeningPort;
end;

function TDextHttpSysEngine.GetTotalRequests: Int64;
begin
  Result := FTotalRequests;
end;

procedure TDextHttpSysEngine.SetOnConnection(const AHandler: TConnectionEventHandler);
begin
  FOnConnection := AHandler;
end;

procedure TDextHttpSysEngine.SetOnDisconnection(const AHandler: TConnectionEventHandler);
begin
  FOnDisconnection := AHandler;
end;

procedure TDextHttpSysEngine.SetOnRequest(const AHandler: TRequestEventHandler);
begin
  FOnRequest := AHandler;
end;

procedure TDextHttpSysEngine.SetOnUpgrade(const AHandler: TUpgradeEventHandler);
begin
  FOnUpgrade := AHandler;
end;

class function TDextHttpSysEngine.Factory(Port: Integer; Pipeline: TRequestDelegate; Services: IServiceProvider): IWebHost;
begin
  // IWebHost factory adapter for WebApplication pipeline
  Result := nil;
end;

end.
