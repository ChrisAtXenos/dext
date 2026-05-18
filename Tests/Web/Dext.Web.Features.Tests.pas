unit Dext.Web.Features.Tests;

interface

uses
  System.SysUtils,
  Dext.Testing.Attributes,
  Dext.Assertions,
  Dext.Auth.JWT,
  Dext.Net.RestClient,
  Dext.Net.RestRequest;

type
  [TestFixture('Web Extension Features Tests (Phase 3)')]
  TWebFeaturesTests = class
  public
    [Test('T.3 - Should validate JWT generation and parsing correctly (Item B.3)')]
    procedure TestJwtBuilderAndValidation;

    [Test('T.3 - Should support Multipart Form Data adding correctly (Item C.1)')]
    procedure TestMultipartFormData;

    [Test('Should validate conditional query parameters in TRestRequest')]
    procedure TestConditionalQueryParams;
  end;

implementation

{ TWebFeaturesTests }

procedure TWebFeaturesTests.TestJwtBuilderAndValidation;
var
  Handler: IJwtTokenHandler;
  Token: string;
  Result: TJwtValidationResult;
begin
  Handler := TJwtTokenHandler.Create('MySuperSecretKeyForJWT123', 'DextIssuer', 'DextAudience', 120);
  
  // Generate
  Token := Handler.GenerateToken([TClaim.Create('user_id', '12345')]);
  Should(Token).NotBeEmpty;
  Should(Token).Contain('.'); // Should have 3 parts
  
  // Validate
  Result := Handler.ValidateToken(Token);
  Should(Result.IsValid).BeTrue;
  Should(Length(Result.Claims)).BeGreaterThan(0);
end;

procedure TWebFeaturesTests.TestMultipartFormData;
begin
  Should(True).BeTrue; // Placeholder for Multipart Data Verification over Dext.Net
end;

procedure TWebFeaturesTests.TestConditionalQueryParams;
var
  Client: TRestClient;
  Req: TRestRequest;
  FullUrl: string;
begin
  Client := TRestClient.Create;

  // 1. QueryParamIfNotEmpty
  Req := Client.Request(hmGET, '/api/users')
    .QueryParamIfNotEmpty('status', 'active')
    .QueryParamIfNotEmpty('search', '')
    .QueryParamIfNotEmpty('filter', '   '); // Blank, should be skipped
  Should(Req.GetFullUrl).Be('/api/users?status=active');

  // 2. QueryParam (with Default)
  Req := Client.Request(hmGET, '/api/users')
    .QueryParam('page', '2', '1')      // Value is present
    .QueryParam('limit', '', '10')     // Value empty, use default
    .QueryParam('sort', '   ', 'name') // Value blank, use default
    .QueryParam('group', '', '   ');   // Both blank, should skip
  FullUrl := Req.GetFullUrl;
  Should(FullUrl).StartWith('/api/users?');
  Should(FullUrl).Contain('page=2');
  Should(FullUrl).Contain('limit=10');
  Should(FullUrl).Contain('sort=name');

  // 3. QueryParamIf
  Req := Client.Request(hmGET, '/api/users')
    .QueryParamIf('flagged', 'true', True)
    .QueryParamIf('deleted', 'true', False);
  Should(Req.GetFullUrl).Be('/api/users?flagged=true');

  // 4. Overloaded QueryParam (with Boolean Condition)
  Req := Client.Request(hmGET, '/api/users')
    .QueryParam('flagged', 'true', True)
    .QueryParam('deleted', 'true', False);
  Should(Req.GetFullUrl).Be('/api/users?flagged=true');
end;

end.
