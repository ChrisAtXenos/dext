unit Dext.Web.Htmx.Tests;

interface

uses
  System.SysUtils,
  Dext.Testing.Attributes,
  Dext.Assertions,
  Dext.Web.Interfaces,
  Dext.Web.Mocks,
  Dext.Collections.Dict;

type
  [TestFixture('HTMX Fluent Response Tests (S23)')]
  THtmxResponseTests = class
  public
    [Test('Should set HX-Trigger header')]
    procedure TestTrigger;
    
    [Test('Should set HX-Retarget header')]
    procedure TestRetarget;
    
    [Test('Should set HX-Reswap header')]
    procedure TestReswap;
    
    [Test('Should set HX-Redirect header')]
    procedure TestRedirect;
    
    [Test('Should set HX-Refresh header')]
    procedure TestRefresh;
    
    [Test('Should set HX-Push-Url header')]
    procedure TestPushUrl;
    
    [Test('Should set HX-Replace-Url header')]
    procedure TestReplaceUrl;
    
    [Test('Should set HX-Location header')]
    procedure TestLocation;
    
    [Test('Should allow chaining multiple HTMX headers')]
    procedure TestChaining;
  end;

implementation

{ THtmxResponseTests }

procedure THtmxResponseTests.TestTrigger;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  
  Response.Htmx.Trigger('myEvent');
  
  Should(Response.Headers['HX-Trigger']).Be('myEvent');
end;

procedure THtmxResponseTests.TestRetarget;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  
  Response.Htmx.Retarget('#target');
  
  Should(Response.Headers['HX-Retarget']).Be('#target');
end;

procedure THtmxResponseTests.TestReswap;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  
  Response.Htmx.Reswap('outerHTML');
  
  Should(Response.Headers['HX-Reswap']).Be('outerHTML');
end;

procedure THtmxResponseTests.TestRedirect;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  
  Response.Htmx.Redirect('/new-path');
  
  Should(Response.Headers['HX-Redirect']).Be('/new-path');
end;

procedure THtmxResponseTests.TestRefresh;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  
  Response.Htmx.Refresh;
  
  Should(Response.Headers['HX-Refresh']).Be('true');
end;

procedure THtmxResponseTests.TestPushUrl;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  
  Response.Htmx.PushUrl('/new-url');
  
  Should(Response.Headers['HX-Push-Url']).Be('/new-url');
end;

procedure THtmxResponseTests.TestReplaceUrl;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  
  Response.Htmx.ReplaceUrl('/replaced-url');
  
  Should(Response.Headers['HX-Replace-Url']).Be('/replaced-url');
end;

procedure THtmxResponseTests.TestLocation;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  
  Response.Htmx.Location('/location');
  
  Should(Response.Headers['HX-Location']).Be('/location');
end;

procedure THtmxResponseTests.TestChaining;
var
  Response: IHttpResponse;
begin
  Response := TMockHttpResponse.Create;
  
  Response.Htmx
    .Trigger('event1')
    .Retarget('#div1')
    .Reswap('innerHTML');
    
  Should(Response.Headers['HX-Trigger']).Be('event1');
  Should(Response.Headers['HX-Retarget']).Be('#div1');
  Should(Response.Headers['HX-Reswap']).Be('innerHTML');
end;

end.
