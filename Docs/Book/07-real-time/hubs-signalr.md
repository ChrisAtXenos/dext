# Hubs (SignalR)

Two-way real-time communication between client and server.

> 📦 **Example**: [Hubs](../../../Examples/Hubs/)

## What are Hubs?

Hubs are a high-level abstraction for WebSockets that allow:
- Server to call methods on the client (browser/mobile).
- Client to call methods on the server.
- Broadcast to everyone or specific groups.

## Defining a Hub

```pascal
type
  [HubName('notifications')]
  TNotificationHub = class(THub)
  public
    // Method called by the client
    procedure SendGlobal(Msg: string);
  end;

procedure TNotificationHub.SendGlobal(Msg: string);
begin
  // Calls 'ReceiveNotification' on all connected clients
  Clients.All.Invoke('ReceiveNotification', [Msg]);
end;
```

## Groups and Users

You can segment messages:

```pascal
// Send only to the caller
Clients.Caller.Invoke('Confirmation', ['Received']);

// Send to a group (e.g., chat room)
Clients.Group('room-123').Invoke('NewMessage', [User, Msg]);

// Send to a specific user
Clients.User('user-guid').Invoke('Private', [Msg]);
```

## Lifecycle

Hubs have connection events:

```pascal
procedure TNotificationHub.OnConnected;
begin
  Log('Client connected: ' + Context.ConnectionId);
end;

procedure TNotificationHub.OnDisconnected(Exception: Exception);
begin
  Log('Client disconnected');
end;
```

## Pipeline Mapping

```pascal
App.Configure(procedure(App: IApplicationBuilder)
  begin
    App.MapHub<TNotificationHub>('/hubs/notifications');
  end);
```

## Transports & WebSockets

Dext Hubs support two primary transport protocols:
1. **WebSockets (`ttWebSockets`)** - High-performance, native full-duplex communication upgraded using opaque mode in the web server engine.
2. **Server-Sent Events (`ttServerSentEvents`)** - Unidirectional server-to-client fallback.

The JavaScript client attempts to negotiate and connect via `webSockets` by default if available.

### JavaScript Client Example

```javascript
const connection = new DextHubConnection('/hubs/notifications', {
  transport: 'webSockets' // Default is 'webSockets', falls back to 'serverSentEvents'
});

connection.on('ReceiveNotification', (msg) => {
  console.log('Received:', msg);
});

await connection.start();
await connection.invoke('SendGlobal', 'Hello from WebSockets!');
```

---

[← Real-Time](README.md) | [Next: Testing →](../08-testing/README.md)
