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
unit Dext.WebSocket.Tests;

{$I Dext.inc}

interface

uses
  System.SysUtils,
  Dext.Testing.Attributes,
  Dext.Testing.Fluent,
  Dext.Testing,
  Dext.WebSocket.Protocol,
  Dext.WebSocket.Handshake;

type
  [TestFixture]
  TWebSocketTests = class
  public
    [Test]
    procedure TestHandshakeVector;
    [Test]
    procedure TestTextFrameRoundtrip;
    [Test]
    procedure TestBinaryFrameRoundtrip;
    [Test]
    procedure TestMaskingRoundtrip;
    [Test]
    procedure TestCloseFrame;
    [Test]
    procedure TestPingPongFrames;
  end;

implementation

{ TWebSocketTests }

procedure TWebSocketTests.TestHandshakeVector;
var
  Key: string;
  Accept: string;
begin
  // RFC 6455 §4.2.2 standard test vector
  Key := 'dGhlIHNhbXBsZSBub25jZQ==';
  Accept := TWebSocketHandshake.ComputeAcceptKey(Key);
  Should(Accept).Be('s3pPLMBiTxaQ9kYGzzhZRbK+xOo=');
end;

procedure TWebSocketTests.TestTextFrameRoundtrip;
var
  Encoded: TBytes;
  Frame: TWebSocketFrame;
  Consumed: Integer;
  DecodedText: string;
begin
  Encoded := TWebSocketFrameCodec.EncodeText('Hello, WebSocket!');
  
  Should(TWebSocketFrameCodec.TryDecode(Encoded, 0, Length(Encoded), Frame, Consumed)).BeTrue;
  Should(Consumed).Be(Length(Encoded));
  Should(Frame.FIN).BeTrue;
  Should(Ord(Frame.Opcode)).Be(Ord(wsText));
  Should(Frame.Masked).BeFalse;
  
  DecodedText := TEncoding.UTF8.GetString(Frame.Payload);
  Should(DecodedText).Be('Hello, WebSocket!');
end;

procedure TWebSocketTests.TestBinaryFrameRoundtrip;
var
  Data: TBytes;
  Encoded: TBytes;
  Frame: TWebSocketFrame;
  Consumed: Integer;
  I: Integer;
begin
  SetLength(Data, 256);
  for I := 0 to 255 do
    Data[I] := Byte(I);
    
  Encoded := TWebSocketFrameCodec.EncodeBinary(Data);
  
  Should(TWebSocketFrameCodec.TryDecode(Encoded, 0, Length(Encoded), Frame, Consumed)).BeTrue;
  Should(Consumed).Be(Length(Encoded));
  Should(Frame.FIN).BeTrue;
  Should(Ord(Frame.Opcode)).Be(Ord(wsBinary));
  Should(Length(Frame.Payload)).Be(256);
  
  for I := 0 to 255 do
    Should(Frame.Payload[I]).Be(Byte(I));
end;

procedure TWebSocketTests.TestMaskingRoundtrip;
var
  Frame: TWebSocketFrame;
  Encoded: TBytes;
  Decoded: TWebSocketFrame;
  Consumed: Integer;
begin
  Frame.FIN := True;
  Frame.Opcode := wsText;
  Frame.Masked := True;
  Frame.MaskKey[0] := $DE;
  Frame.MaskKey[1] := $AD;
  Frame.MaskKey[2] := $BE;
  Frame.MaskKey[3] := $EF;
  Frame.Payload := TEncoding.UTF8.GetBytes('Masked Payload');
  Frame.PayloadLength := Length(Frame.Payload);
  
  // Before encoding, client payload is masked in transit.
  // Our codec unmasks automatically upon decoding if TryDecode is used.
  Encoded := TWebSocketFrameCodec.Encode(Frame);
  
  Should(TWebSocketFrameCodec.TryDecode(Encoded, 0, Length(Encoded), Decoded, Consumed)).BeTrue;
  Should(Consumed).Be(Length(Encoded));
  Should(Decoded.Masked).BeTrue;
  Should(Ord(Decoded.Opcode)).Be(Ord(wsText));
  Should(TEncoding.UTF8.GetString(Decoded.Payload)).Be('Masked Payload');
end;

procedure TWebSocketTests.TestCloseFrame;
var
  Encoded: TBytes;
  Frame: TWebSocketFrame;
  Consumed: Integer;
  CloseCode: Word;
  Reason: string;
begin
  Encoded := TWebSocketFrameCodec.EncodeClose(1001, 'Going Away');
  
  Should(TWebSocketFrameCodec.TryDecode(Encoded, 0, Length(Encoded), Frame, Consumed)).BeTrue;
  Should(Consumed).Be(Length(Encoded));
  Should(Ord(Frame.Opcode)).Be(Ord(wsClose));
  
  CloseCode := (Frame.Payload[0] shl 8) or Frame.Payload[1];
  Reason := TEncoding.UTF8.GetString(Frame.Payload, 2, Length(Frame.Payload) - 2);
  
  Should(CloseCode).Be(1001);
  Should(Reason).Be('Going Away');
end;

procedure TWebSocketTests.TestPingPongFrames;
var
  PingBytes: TBytes;
  PongBytes: TBytes;
  Frame: TWebSocketFrame;
  Consumed: Integer;
  Payload: TBytes;
begin
  Payload := TEncoding.UTF8.GetBytes('ping-data');
  PingBytes := TWebSocketFrameCodec.EncodePing(Payload);
  
  Should(TWebSocketFrameCodec.TryDecode(PingBytes, 0, Length(PingBytes), Frame, Consumed)).BeTrue;
  Should(Ord(Frame.Opcode)).Be(Ord(wsPing));
  Should(TEncoding.UTF8.GetString(Frame.Payload)).Be('ping-data');
  
  PongBytes := TWebSocketFrameCodec.EncodePong(Payload);
  Should(TWebSocketFrameCodec.TryDecode(PongBytes, 0, Length(PongBytes), Frame, Consumed)).BeTrue;
  Should(Ord(Frame.Opcode)).Be(Ord(wsPong));
  Should(TEncoding.UTF8.GetString(Frame.Payload)).Be('ping-data');
end;

end.
