unit Dext.Web.Validation.Tests;

interface

uses
  Dext.Testing,
  Dext.Validation,
  Dext.Web.HandlerInvoker,
  Dext.Web.ModelBinding,
  Dext.Web.Interfaces,
  Dext.Web.Mocks,
  Dext.DI.Interfaces,
  Dext.DI.Core,
  System.SysUtils,
  System.Rtti;

type
  TWebTestModel = class
  private
    FName: string;
    FEmail: string;
  published
    property Name: string read FName write FName;
    property Email: string read FEmail write FEmail;
  end;

  TWebTestModelValidator = class(TAbstractValidator<TWebTestModel>)
  public
    constructor Create; override;
  end;

  [TestFixture]
  TWebValidationTests = class
  public
    [Test]
    procedure Test_HandlerInvoker_AutoValidation_Fluent;
  end;

implementation

{ TWebTestModelValidator }

constructor TWebTestModelValidator.Create;
begin
  inherited Create;
  RuleFor('Name').Required.Length(3, 50);
  RuleFor('Email').EmailAddress;
end;

{ TWebValidationTests }

procedure TWebValidationTests.Test_HandlerInvoker_AutoValidation_Fluent;
var
  Services: TDextServices;
  Provider: IServiceProvider;
  Context: IHttpContext;
  Invoker: THandlerInvoker;
  Binder: IModelBinder;
begin
  Services := TDextServices.New;
  Services.AddTransient<IValidator<TWebTestModel>, TWebTestModelValidator>;
  Provider := Services.BuildServiceProvider;
  try
    Context := TMockFactory.CreateHttpContextWithServices('Name=Ab&Email=invalid-email', Provider);
    Binder := TModelBinder.Create;
    Invoker := THandlerInvoker.Create(Context, Binder);
    try
      Invoker.Invoke<TWebTestModel>(
        procedure(Arg: TWebTestModel)
        begin
          // This should NOT be executed because validation fails
        end
      );
      
      Should(Context.Response.StatusCode).Be(400);
    finally
      Invoker.Free;
    end;
  finally
    Provider := nil;
  end;
end;

end.
