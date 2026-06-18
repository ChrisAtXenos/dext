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
unit Dext.WebSocket.Handshake;

{$I Dext.inc}

interface

uses
  System.SysUtils,
  System.Hash,
  System.NetEncoding,
  Dext.Server.Engine.Interfaces;

type
  TWebSocketHandshake = class
  public
    /// <summary>Validates if an incoming HTTP request is a WebSocket upgrade request.</summary>
    class function IsUpgradeRequest(const ARequest: IDextRawRequest): Boolean; static;

    /// <summary>Computes the Sec-WebSocket-Accept header value (RFC 6455 §4.2.2).</summary>
    class function ComputeAcceptKey(const ASecWebSocketKey: string): string; static;

    /// <summary>Builds the 101 Switching Protocols response message.</summary>
    class function BuildUpgradeResponse(const ASecWebSocketKey: string;
      const AProtocol: string = ''): string; static;
  end;

implementation

{ TWebSocketHandshake }

class function TWebSocketHandshake.IsUpgradeRequest(const ARequest: IDextRawRequest): Boolean;
var
  UpgradeHeader: string;
  ConnectionHeader: string;
  Method: string;
begin
  Result := False;
  if ARequest = nil then Exit;

  Method := ARequest.Method;
  if not SameText(Method, 'GET') then Exit;

  UpgradeHeader := ARequest.GetHeader('Upgrade');
  if not SameText(UpgradeHeader, 'websocket') then Exit;

  ConnectionHeader := ARequest.GetHeader('Connection');
  if (ConnectionHeader = '') or (Pos('upgrade', LowerCase(ConnectionHeader)) = 0) then Exit;

  if ARequest.GetHeader('Sec-WebSocket-Key') = '' then Exit;

  Result := True;
end;

class function TWebSocketHandshake.ComputeAcceptKey(const ASecWebSocketKey: string): string;
const
  WS_GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
var
  Combined: string;
  HashBytes: TBytes;
  SHA1: THashSHA1;
begin
  Combined := ASecWebSocketKey.Trim + WS_GUID;
  SHA1 := THashSHA1.Create;
  SHA1.Update(TEncoding.UTF8.GetBytes(Combined));
  HashBytes := SHA1.HashAsBytes;
  Result := TNetEncoding.Base64.EncodeBytesToString(HashBytes).Trim;
  // Strip any newlines just in case
  Result := Result.Replace(#13, '').Replace(#10, '');
end;

class function TWebSocketHandshake.BuildUpgradeResponse(const ASecWebSocketKey: string; const AProtocol: string): string;
var
  AcceptKey: string;
begin
  AcceptKey := ComputeAcceptKey(ASecWebSocketKey);
  Result := 'HTTP/1.1 101 Switching Protocols' + #13#10 +
            'Upgrade: websocket' + #13#10 +
            'Connection: Upgrade' + #13#10 +
            'Sec-WebSocket-Accept: ' + AcceptKey + #13#10;
  if AProtocol <> '' then
    Result := Result + 'Sec-WebSocket-Protocol: ' + AProtocol + #13#10;
  Result := Result + #13#10;
end;

end.
