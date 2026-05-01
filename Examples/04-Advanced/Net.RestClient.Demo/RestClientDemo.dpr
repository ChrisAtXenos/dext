program RestClientDemo;

{$APPTYPE CONSOLE}

uses
  Dext.MM,
  Dext.Utils,
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  Dext.Net.RestClient,
  Dext.Net.RestRequest,
  Dext.Threading.Async,
  Dext.Threading.CancellationToken,
  User.Entity in 'User.Entity.pas';

type
  TPost = class
  private
    FId: Integer;
    FTitle: string;
    FBody: string;
    FUserId: Integer;
  public
    property id: Integer read FId write FId;
    property title: string read FTitle write FTitle;
    property body: string read FBody write FBody;
    property userId: Integer read FUserId write FUserId;
  end;

var
  Countdown: TCountdownEvent;

procedure DemoFluentGet;
begin
  Writeln('--- Demo: Fluent GET (Typed) ---');
  Countdown.AddCount;
  
  RestClient('https://jsonplaceholder.typicode.com')
    .Get('/users/1')
    .OnCompleteAsync(
      procedure(Response: IRestResponse)
      begin
        Writeln('--- Demo: Fluent GET (Typed) Response ---');
        Writeln('Status: ', Response.StatusCode);
        Writeln('Content: ', Response.ContentString.Substring(0, 100) + '...');
        Countdown.Signal;
      end)
    .OnExceptionAsync(
      procedure(E: Exception)
      begin
        Writeln('--- Demo: Fluent GET (Typed) Error ---');
        Writeln('Error: ', E.Message);
        Countdown.Signal;
      end)
    .Start;
end;

procedure DemoRequestRequest;
var
  LRestClient: TRestClient;
begin
  Writeln('--- Demo: TRestRequest Builder ---');
  Countdown.AddCount;
  
  LRestClient := TRestClient.Create('https://jsonplaceholder.typicode.com');
  try
    TRestRequest
      .Create(LRestClient, hmPOST, '/posts')
      .Header('X-Custom-Header', 'DextValue')
      .JsonBody('{"title": "foo", "body": "bar", "userId": 1}')
      .Execute
      .OnCompleteAsync(
        procedure(Response: IRestResponse)
        begin
          Writeln('--- Demo: TRestRequest Response ---');
          Writeln('POST Status: ', Response.StatusCode);
          Writeln('POST Response: ', Response.ContentString);
          Countdown.Signal;
        end)
      .OnExceptionAsync(
        procedure(E: Exception)
        begin
          Writeln('--- Demo: TRestRequest Error ---');
          Writeln('Error: ', E.Message);
          Countdown.Signal;
        end)
      .Start;
  finally
    // TRestClient is a record wrapper over interface; no manual Free required.
  end;
end;

procedure DemoWithCancellation;
var
  CancelationTokenSource: TCancellationTokenSource;
begin
  Writeln('--- Demo: Cancellation ---');
  Countdown.AddCount;
  
  CancelationTokenSource := TCancellationTokenSource.Create;
  try
    RestClient('https://jsonplaceholder.typicode.com')
      .Get('/posts')
      .WithCancellation(CancelationTokenSource.Token)
      .OnCompleteAsync(
        procedure(Response: IRestResponse)
        begin
          Writeln('--- Demo: Cancellation Response ---');
          Writeln('Success (should not happen if canceled)');
          Countdown.Signal;
        end)
      .OnExceptionAsync(
        procedure(E: Exception)
        begin
          Writeln('--- Demo: Cancellation Error ---');
          Writeln('Expected Error: ', E.Message);
          Countdown.Signal;
        end)
      .Start;
      
    CancelationTokenSource.Cancel;
    Writeln('Requested Cancellation.');
  finally
    CancelationTokenSource.Free;
  end;
end;

procedure DemoSynchronous;
var
  Response: TPost;
begin
  Writeln('--- Demo: Synchronous Request ---');
  
  try
    Response := RestClient('https://jsonplaceholder.typicode.com')
      .Get<TPost>('/posts/1')
      .Await; // Blocks and runs on current thread
      
    try
      Writeln('--- Demo: Synchronous Response ---');
      Writeln('Synchronous success!');
      Writeln('ID: ', Response.id);
      Writeln('Title: ', Response.title);
    finally
      Response.Free;
    end;
  except
    on E: Exception do
      Writeln('Synchronous Error: ', E.Message);
  end;
end;

procedure DemoSynchronousList;
var
  posts: TList<TPost>;
  p: TPost;
begin
  Writeln('--- Demo: Synchronous List Request (TList) ---');
  Writeln;

  try
    posts := RestClient('https://jsonplaceholder.typicode.com')
      .Get<TList<TPost>>('/posts')
      .Await; // Blocks and runs on current thread

    try
      Writeln('--- Demo: Synchronous TList<TPost> ---');
      Writeln('--- Demo: Synchronous TList Count ' + posts.Count.ToString + ' ---');
      for p in posts do
      begin
        Writeln('Synchronous success (TList)!ID: ', p.id);
      end;
    finally
      if posts <> nil then
      begin
        for p in posts do
          p.Free;
        posts.Free;
      end;
    end;
  except
    on E: Exception do
      Writeln('Synchronous Error: ', E.Message);
  end;
  Writeln;
end;

procedure DemoSynchronousObjectList;
var
  posts: TObjectList<TPost>;
  p: TPost;
begin
  Writeln('--- Demo: Synchronous List Request (TObjectList) ---');
  Writeln;

  try
    posts := RestClient('https://jsonplaceholder.typicode.com')
      .Get<TObjectList<TPost>>('/posts')
      .Await; // Blocks and runs on current thread

    try
      Writeln('--- Demo: Synchronous TObjectList<TPost> ---');
      Writeln('--- Demo: Synchronous TObjectList Count ' + posts.Count.ToString + ' ---');
      for p in posts do
      begin
        Writeln('Synchronous success (TObjectList)!ID: ', p.id);
      end;
    finally
      posts.Free; // OwnsObjects := True por padrão
    end;
  except
    on E: Exception do
      Writeln('Synchronous Error: ', E.Message);
  end;
  Writeln;
end;

begin
  try
    Countdown := TCountdownEvent.Create(1);
    try
      DemoFluentGet;
      DemoRequestRequest;
      DemoWithCancellation;
      DemoSynchronous;
      DemoSynchronousList;
      DemoSynchronousObjectList;
      
      Writeln('Waiting for tasks...');
      Countdown.Signal; // Finish setup
      Countdown.WaitFor;
    finally
      Countdown.Free;
    end;
    
    ConsolePause;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ConsolePause;
    end;
  end;
end.

