program Dext.BasicAuthTest;

{$APPTYPE CONSOLE}

uses
  Dext.MM,
  Dext.Utils,
  System.SysUtils,
  System.Rtti,
  Dext.Web,
  Dext.Auth.BasicAuth,
  Dext.Web.Interfaces,
  Dext.Assertions,
  Dext.Collections,
  Dext.Collections.Dict,
  Dext.Mocks,
  Dext.Mocks.Matching,
  Dext.Web.Mocks in '..\Common\Dext.Web.Mocks.pas';

function MakeContext(const APath: string; const AHeaders: IDictionary<string, string> = nil): IHttpContext;
var
  MockReq: Mock<IHttpRequest>;
  QueryParams: IStringDictionary;
  EmptyCookies: IStringDictionary;
  EmptyRoute: TRouteValueDictionary;
  HeadersDict: IStringDictionary;
  Pair: TPair<string, string>;
begin
  MockReq := Mock<IHttpRequest>.Create;

  QueryParams := TCollections.CreateStringDictionary;
  EmptyCookies := TCollections.CreateStringDictionary;
  EmptyRoute.Clear;
  HeadersDict := TCollections.CreateStringDictionary;

  if Assigned(AHeaders) then
  begin
    for Pair in AHeaders do
      HeadersDict.AddOrSetValue(Pair.Key, Pair.Value);
  end;

  MockReq.Setup.Returns(TValue.From<IStringDictionary>(QueryParams)).When.GetQuery;
  MockReq.Setup.Returns(TValue.From<IStringDictionary>(HeadersDict)).When.GetHeaders;
  MockReq.Setup.Returns(TValue.From<IStringDictionary>(EmptyCookies)).When.GetCookies;
  MockReq.Setup.Returns(TValue.From<TRouteValueDictionary>(EmptyRoute)).When.GetRouteParams;

  MockReq.Setup.Returns(TValue.From<string>('GET')).When.GetMethod;
  MockReq.Setup.Returns(TValue.From<string>(APath)).When.GetPath;
  MockReq.Setup.Returns(TValue.From<string>('127.0.0.1')).When.GetRemoteIpAddress;

  Result := TMockHttpContext.Create(MockReq.Instance, TMockHttpResponse.Create, nil);
end;

function MakeContextWithPath(const APath: string): IHttpContext;
begin
  Result := MakeContext(APath);
end;

function MakeContextWithPathAndAuth(const APath, AAuthHeader: string): IHttpContext;
var
  Headers: IDictionary<string, string>;
begin
  Headers := TCollections.CreateDictionary<string, string>;
  Headers.Add('Authorization', AAuthHeader);
  Result := MakeContext(APath, Headers);
end;

procedure RunTests;
var
  App: IWebApplication;
  Pipeline: TRequestDelegate;
  Context: IHttpContext;
  I: Integer;
  Meta: TEndpointMetadata;
begin
  Writeln('🧪 Basic Auth Tests Starting...');

  App := TWebApplication.Create;

  // 1. Configure Basic Auth
  App.Builder.UseBasicAuthentication(
    'Test Realm',
    function(const Username, Password: string): Boolean
    begin
      Result := (Username = 'testuser') and (Password = 'testpass');
    end);

  // 2. Protected route
  App.Builder.MapGet('/protected', procedure(Ctx: IHttpContext)
  begin
    Ctx.Response.Write('Authorized access');
  end).RequireAuthorization;

  // 3. Public route
  App.Builder.MapGet('/public', procedure(Ctx: IHttpContext)
  begin
    Ctx.Response.Write('Public access');
  end);

  // 4. Build pipeline
  Writeln('--- Route Metadata Debug ---');
  for I := 0 to High(App.Builder.Unwrap.GetRoutes) do
  begin
    Meta := App.Builder.Unwrap.GetRoutes[I];
    Writeln(Format('Route: %s, Security Schemes: %d', [Meta.Path, Length(Meta.Security)]));
  end;
  Writeln('---------------------------');

  Pipeline := App.Builder.Unwrap.Build;

  // --- Scenario 1: Public endpoint, no credentials ---
  Writeln('Scenario 1: Public endpoint, no credentials (expect 200)');
  Context := MakeContextWithPath('/public');
  Pipeline(Context);
  Should(Context.Response.StatusCode).Be(200);
  Writeln('  PASS');

  // --- Scenario 2: Protected endpoint, no credentials ---
  Writeln('Scenario 2: Protected endpoint, no credentials (expect 401)');
  Context := MakeContextWithPath('/protected');
  Pipeline(Context);
  Should(Context.Response.StatusCode).Be(401);
  Writeln('  PASS');

  // --- Scenario 3: Protected endpoint, valid credentials ---
  Writeln('Scenario 3: Protected endpoint, valid credentials (expect 200)');
  // testuser:testpass -> Base64 = dGVzdHVzZXI6dGVzdHBhc3M=
  Context := MakeContextWithPathAndAuth('/protected', 'Basic dGVzdHVzZXI6dGVzdHBhc3M=');
  Pipeline(Context);
  Should(Context.Response.StatusCode).Be(200);
  Writeln('  PASS');

  // --- Scenario 4: Protected endpoint, wrong credentials ---
  Writeln('Scenario 4: Protected endpoint, wrong credentials (expect 401)');
  // user:wrong -> Base64 = dXNlcjp3cm9uZw==
  Context := MakeContextWithPathAndAuth('/protected', 'Basic dXNlcjp3cm9uZw==');
  Pipeline(Context);
  Should(Context.Response.StatusCode).Be(401);
  Writeln('  PASS');

  Writeln('');
  Writeln('✅ All tests passed!');
end;

begin
  try
    SetConsoleCharSet;
    RunTests;
    Writeln('Press Enter to exit...');
    ConsolePause;
  except
    on E: Exception do
    begin
      Writeln('❌ TEST FAILED: ', E.ClassName, ': ', E.Message);
      ConsolePause;
    end;
  end;
end.
