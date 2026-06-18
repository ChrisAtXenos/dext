# 📑 S40: WebSocket Transport & SignalR Hub Integration

**Status:** 📝 Draft
**Owner:** Cesar Romero & Engineering Team
**Created:** 2026-06-17
**Dependencies:** S39 (Native Server Engine — for `IDextWebSocketConnection` and `SupportsUpgrade`)
**Enables:** S02 (gRPC streaming via WebSocket fallback), Real-time Dext.Hubs

---

## 1. Goal

Implement a **native WebSocket transport** (RFC 6455) for the Dext Framework and integrate it as the **primary transport** for the existing `Dext.Web.Hubs` SignalR-compatible infrastructure.

Currently, Hubs only support SSE (Server-Sent Events) and Long Polling — both are unidirectional (server → client). WebSocket provides the **full-duplex, low-latency** channel required for real-time applications.

### 1.1 Objectives

1. Implement RFC 6455 WebSocket frame encoding/decoding in 100% Pascal.
2. Implement the HTTP/1.1 → WebSocket upgrade handshake.
3. Create a new `IHubTransport` implementation for WebSocket.
4. Update the negotiate endpoint to advertise WebSocket as the preferred transport.
5. Ensure backward compatibility — SSE remains as fallback.
6. Validate with the existing JavaScript client (`dext-hubs.js`).

### 1.2 Non-Goals

- WebSocket compression (`permessage-deflate`) — Phase 2.
- WebSocket Secure (WSS) over native IOCP/epoll — depends on S39 TLS (Phase 2). Works immediately with http.sys.
- MessagePack Hub Protocol — future spec.

---

## 2. Current State

### 2.1 Hubs Architecture

The `Dext.Web.Hubs` package implements a **SignalR-compatible** hub system:

```
Dext.Web.Hubs
├── Dext.Web.Hubs.Interfaces.pas      ← IClientProxy, IHubClients, IGroupManager, IHubContext
├── Dext.Web.Hubs.Types.pas           ← TTransportType, THubMessage, THandshakeRequest
├── Dext.Web.Hubs.ConnectionManager.pas← Connection tracking & lifecycle
├── Dext.Web.Hubs.Protocol.Json.pas   ← JSON Hub Protocol (SignalR wire format)
├── Dext.Web.Hubs.Transport.SSE.pas   ← Server-Sent Events transport ✅
├── Dext.Web.Hubs.Transport.LongPolling.pas ← Long Polling transport ✅
├── Dext.Web.Hubs.Middleware.pas       ← HTTP middleware integration
└── wwwroot/dext-hubs.js              ← JavaScript client
```

**What exists:**
- Full SignalR JSON Wire Protocol (invocation, completion, stream, ping)
- Connection negotiate endpoint (returns connectionId + available transports)
- SSE transport (`text/event-stream`)
- Group management (`IGroupManager.Add/Remove`)
- Client invocation (`IClientProxy.SendAsync`)

**What is missing:**
- `TTransportType.WebSockets` is defined but **not implemented**
- `Dext.Web.Hubs.Transport.WebSocket.pas` does **not exist**
- The negotiate endpoint does **not** include WebSocket in `availableTransports`

### 2.2 WebSocket in DCS Adapter

The DCS adapter (`Dext.Web.DCS.pas`) wraps `ICrossWebSocketServer` from Delphi-Cross-Socket, which already handles WebSocket at the socket level. However, this is **not exposed** to the Hubs layer — the DCS adapter only maps HTTP requests to `IHttpContext`.

---

## 3. Architecture

### 3.1 WebSocket Protocol Stack

```
┌─────────────────────────────────────┐
│         Dext.Web.Hubs               │  ← Application Layer (Hub methods)
├─────────────────────────────────────┤
│    IHubTransport (WebSocket)        │  ← Transport Layer (this spec)
├─────────────────────────────────────┤
│  Dext.WebSocket.Protocol            │  ← Framing Layer (RFC 6455)
├─────────────────────────────────────┤
│  Dext.WebSocket.Handshake           │  ← Upgrade Layer (HTTP → WS)
├─────────────────────────────────────┤
│  IDextServerConnection              │  ← Connection Layer (from S39)
│  (http.sys / IOCP / epoll)          │
└─────────────────────────────────────┘
```

### 3.2 WebSocket Frame Format (RFC 6455)

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-------+-+-------------+-------------------------------+
|F|R|R|R| opcode|M| Payload len |    Extended payload length    |
|I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
|N|V|V|V|       |S|             |   (if payload len==126/127)   |
| |1|2|3|       |K|             |                               |
+-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
|     Extended payload length continued, if payload len == 127  |
+ - - - - - - - - - - - - - - - +-------------------------------+
|                               |Masking-key, if MASK set to 1  |
+-------------------------------+-------------------------------+
| Masking-key (continued)       |          Payload Data         |
+-------------------------------- - - - - - - - - - - - - - - - +
:                     Payload Data continued ...                :
+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
|                     Payload Data (continued)                  |
+---------------------------------------------------------------+
```

**Opcodes:**
- `$0` — Continuation frame
- `$1` — Text frame (UTF-8)
- `$2` — Binary frame
- `$8` — Close
- `$9` — Ping
- `$A` — Pong

---

## 4. Proposed API Surface

### 4.1 WebSocket Protocol (`Dext.WebSocket.Protocol.pas`)

```pascal
type
  TWebSocketOpcode = (
    wsContinuation = $0,
    wsText         = $1,
    wsBinary       = $2,
    wsClose        = $8,
    wsPing         = $9,
    wsPong         = $A
  );

  TWebSocketCloseCode = (
    wsCloseNormal           = 1000,
    wsCloseGoingAway        = 1001,
    wsCloseProtocolError     = 1002,
    wsCloseUnsupportedData   = 1003,
    wsCloseNoStatus          = 1005,
    wsCloseAbnormal          = 1006,
    wsCloseInvalidPayload    = 1007,
    wsClosePolicyViolation   = 1008,
    wsCloseMessageTooBig     = 1009,
    wsCloseMandatoryExtension = 1010,
    wsCloseInternalServerError = 1011
  );

  TWebSocketFrame = record
    FIN: Boolean;
    Opcode: TWebSocketOpcode;
    Masked: Boolean;
    MaskKey: array[0..3] of Byte;
    PayloadLength: UInt64;
    Payload: TBytes;
  end;

  TWebSocketFrameCodec = class
  public
    /// Encode a frame to bytes (server → client: no masking)
    class function Encode(const AFrame: TWebSocketFrame): TBytes; static;
    class function EncodeText(const AData: string; AFIN: Boolean = True): TBytes; static;
    class function EncodeBinary(const AData: TBytes; AFIN: Boolean = True): TBytes; static;
    class function EncodeClose(ACode: Word = 1000; const AReason: string = ''): TBytes; static;
    class function EncodePing(const AData: TBytes = nil): TBytes; static;
    class function EncodePong(const AData: TBytes = nil): TBytes; static;

    /// Decode a frame from a byte buffer (incremental — may need more data)
    /// Returns the number of bytes consumed, or 0 if more data is needed
    class function TryDecode(const ABuffer: TBytes; AOffset: Integer;
      ALength: Integer; out AFrame: TWebSocketFrame;
      out ABytesConsumed: Integer): Boolean; static;

    /// Unmask payload in-place
    class procedure Unmask(var APayload: TBytes; const AMaskKey: array of Byte); static;
  end;
```

### 4.2 WebSocket Handshake (`Dext.WebSocket.Handshake.pas`)

```pascal
type
  TWebSocketHandshake = class
  public
    /// Validate an incoming HTTP request as a WebSocket upgrade request
    class function IsUpgradeRequest(const ARequest: IHttpRequest): Boolean; static;

    /// Generate the Sec-WebSocket-Accept header value
    /// Accept = Base64(SHA1(Key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
    class function ComputeAcceptKey(const ASecWebSocketKey: string): string; static;

    /// Build the 101 Switching Protocols response headers
    class function BuildUpgradeResponse(const ASecWebSocketKey: string;
      const AProtocol: string = ''): string; static;
  end;
```

### 4.3 Hub WebSocket Transport (`Dext.Web.Hubs.Transport.WebSocket.pas`)

```pascal
type
  TWebSocketHubTransport = class(TInterfacedObject, IHubTransport)
  private
    FConnectionManager: IConnectionManager;
    FProtocol: IHubProtocol;
    FPingInterval: Integer; // seconds (default: 15)
  public
    constructor Create(const AConnectionManager: IConnectionManager;
      const AProtocol: IHubProtocol);

    /// IHubTransport
    function GetTransportType: TTransportType;
    procedure ProcessConnection(const AContext: IHttpContext);
    procedure SendMessage(const AConnectionId: string; const AMessage: THubMessage);
    procedure CloseConnection(const AConnectionId: string);
  end;
```

**`ProcessConnection` lifecycle:**

```
1. Validate upgrade request (IsUpgradeRequest)
2. Send 101 Switching Protocols (BuildUpgradeResponse)
3. Register connection (IConnectionManager.Add)
4. Enter read loop:
   a. Read WebSocket frame (TryDecode)
   b. If Text/Binary: parse Hub message (IHubProtocol.ParseMessage)
   c. If Ping: send Pong
   d. If Close: send Close, break
5. Unregister connection (IConnectionManager.Remove)
6. Trigger OnDisconnected on Hub
```

---

## 5. Implementation Phases

### Phase 1: WebSocket Protocol Core (10 days)

**Files:**
- `Sources/Server/Dext.WebSocket.Protocol.pas` — Frame codec
- `Sources/Server/Dext.WebSocket.Handshake.pas` — Upgrade handshake

**Tests:**
- Frame encoding roundtrip (text, binary, control)
- Fragmentation (multi-frame messages)
- Masking/unmasking (client → server)
- Close code encoding/decoding
- Handshake key computation against known test vectors (RFC 6455 §4.2.2)

### Phase 2: Hub Transport Integration (7 days)

**Files:**
- `Sources/Hubs/Transports/Dext.Web.Hubs.Transport.WebSocket.pas`

**Changes to existing files:**
- `Dext.Web.Hubs.Types.pas` — Add `WebSockets` to default `AvailableTransports`
- `Dext.Web.Hubs.Middleware.pas` — Add WebSocket upgrade detection before SSE/LP routing

### Phase 3: JavaScript Client Update (3 days)

**Files:**
- `Sources/Hubs/wwwroot/dext-hubs.js`

**Changes:**
- Add WebSocket transport class (`DextWebSocketTransport`)
- Update negotiate logic: prefer WebSocket → SSE → Long Polling
- WebSocket reconnection with exponential backoff
- Binary frame support (for future MessagePack protocol)

---

## 6. Acceptance Criteria

- [ ] WebSocket frames encode/decode correctly for all opcodes (text, binary, ping, pong, close).
- [ ] Fragmented messages reassemble correctly.
- [ ] Client-to-server masking is properly handled.
- [ ] HTTP/1.1 → WebSocket upgrade handshake completes successfully.
- [ ] Sec-WebSocket-Accept key matches RFC test vectors.
- [ ] Hub methods (Invoke/Send/Broadcast) work over WebSocket transport.
- [ ] Groups (IGroupManager) work over WebSocket transport.
- [ ] JavaScript client negotiates WebSocket as primary transport.
- [ ] SSE fallback works when WebSocket is unavailable.
- [ ] Connection lifecycle events fire correctly (OnConnected, OnDisconnected).
- [ ] Ping/Pong keepalive prevents idle disconnections.
- [ ] 1000+ simultaneous WebSocket connections sustained without leaks.

---

## 7. Wire Format: SignalR JSON Protocol over WebSocket

Each Hub message is sent as a **text WebSocket frame** containing JSON terminated by `\x1e` (Record Separator):

```
{"type":1,"target":"SendMessage","arguments":["hello","world"]}\x1e
```

Message types:
- `1` — Invocation
- `2` — StreamItem
- `3` — Completion
- `4` — StreamInvocation
- `5` — CancelInvocation
- `6` — Ping
- `7` — Close

The Handshake uses the same framing:
```
Client → Server: {"protocol":"json","version":1}\x1e
Server → Client: {}\x1e
```

This is **already implemented** in `Dext.Web.Hubs.Protocol.Json.pas`. The WebSocket transport simply pipes these messages through WebSocket text frames instead of SSE data events.

---

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| WebSocket frame parser buffer overflow | Security vulnerability | Enforce max frame size (configurable, default 1MB), fuzz testing |
| Fragmented message reassembly memory | Memory exhaustion | Max assembled message size limit |
| Concurrent send from multiple Hub calls | Corrupted frames | Serialize WebSocket sends per connection (lock or queue) |
| Browser compatibility issues | Client failures | Test with Chrome, Firefox, Safari, Edge |
| UTF-8 validation on text frames | Protocol violation | Validate UTF-8 on text frame payloads per RFC 6455 §5.6 |

---

*Created by Cesar Romero & Antigravity AI — June 2026*
