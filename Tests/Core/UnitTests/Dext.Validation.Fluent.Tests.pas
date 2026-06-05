unit Dext.Validation.Fluent.Tests;

interface

uses
  Dext.Testing,
  Dext.Validation,
  System.SysUtils,
  System.Rtti,
  Dext.Core.SmartTypes,
  Dext.Entity.Prototype,
  Dext.Entity.Mapping,
  Dext.Entity.Attributes;

type
  TTestModel = class
  private
    FName: string;
    FEmail: string;
    FAge: Integer;
    FScore: Double;
    FActive: Boolean;
    FPhone: string;
  public
    property Name: string read FName write FName;
    property Email: string read FEmail write FEmail;
    property Age: Integer read FAge write FAge;
    property Score: Double read FScore write FScore;
    property Active: Boolean read FActive write FActive;
    property Phone: string read FPhone write FPhone;
  end;

  TTestModelValidator = class(TAbstractValidator<TTestModel>)
  public
    constructor Create; override;
  end;

  TSmartTestModel = class
  private
    FId: Integer;
    FName: Prop<string>;
    FEmail: Prop<string>;
    FPhone: Prop<string>;
  public
    [PK]
    property Id: Integer read FId write FId;
    property Name: Prop<string> read FName write FName;
    property Email: Prop<string> read FEmail write FEmail;
    property Phone: Prop<string> read FPhone write FPhone;
  end;

  TSmartTestModelValidator = class(TAbstractValidator<TSmartTestModel>)
  public
    constructor Create; override;
  end;

  TSmartTestModelExpressionValidator = class(TAbstractValidator<TSmartTestModel>)
  public
    constructor Create; override;
  end;

  [TestFixture]
  TValidationFluentTests = class
  public
    [Test]
    procedure Test_Required_Validation;
    [Test]
    procedure Test_Length_Validation;
    [Test]
    procedure Test_Email_Validation;
    [Test]
    procedure Test_Range_Validation;
    [Test]
    procedure Test_Must_Validation;
    [Test]
    procedure Test_When_Condition;
    [Test]
    procedure Test_Custom_Message;
    [Test]
    procedure Test_Matches_Validation;
    [Test]
    procedure Test_SmartProperty_Validation;
    [Test]
    procedure Test_PatternRegistry_Validation;
    [Test]
    procedure Test_SmartProperty_Expression_Validation;
    [Test]
    procedure Test_SmartProperty_When_Expression_Validation;
    [Test]
    procedure Test_ErrorMessage_Concatenation;
  end;

implementation

{ TTestModelValidator }

constructor TTestModelValidator.Create;
begin
  inherited Create;
  RuleFor('Name').Required.Length(3, 50);
  RuleFor('Email').EmailAddress;
  RuleFor('Age').Range(18, 99);
  RuleFor('Score').Range(0.0, 100.0);
  
  // Custom Must validation
  RuleFor('Active', function(Model: TTestModel): TValue
    begin
      Result := Model.Active;
    end).Must(function(Val: TValue): Boolean
    begin
      Result := Val.AsBoolean;
    end).WithMessage('Model must be active');

  // Conditional validation
  RuleFor('Email').Required.When(function(Model: TTestModel): Boolean
    begin
      Result := Model.Age > 50;
    end);

  RuleFor('Phone').Matches('^\+\d{2}\s\d{2}\s\d{9}$');
end;

{ TSmartTestModelValidator }

constructor TSmartTestModelValidator.Create;
var
  m: TSmartTestModel;
begin
  inherited Create;
  m := Prototype.Entity<TSmartTestModel>;
  RuleFor(m.Name).Required.Length(3, 50);
  RuleFor(m.Email).EmailAddress;
  RuleFor(m.Phone).MatchesPattern('Phone', 'pt-BR');
end;

{ TSmartTestModelExpressionValidator }

constructor TSmartTestModelExpressionValidator.Create;
begin
  inherited Create;
  RuleFor(Model.Name.Contains('Dext')).WithMessage('Name must contain Dext');
  RuleFor(Model.Email).Required.When(Model.Name.StartsWith('Admin'));
end;

{ TValidationFluentTests }

procedure TValidationFluentTests.Test_Required_Validation;
var
  Model: TTestModel;
  Validator: TTestModelValidator;
  Result: TValidationResult;
begin
  Model := TTestModel.Create;
  Validator := TTestModelValidator.Create;
  try
    Model.Name := '';
    Model.Email := 'test@example.com';
    Model.Age := 20;
    Model.Score := 50.0;
    Model.Active := True;

    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeFalse;
      Should.List<TValidationError>(Result.Errors).HaveCount(1);
      Should(Result.Errors[0].FieldName).Be('Name');
      Should(Result.Errors[0].ErrorMessage).Contain('required');
    finally
      Result.Free;
    end;
  finally
    Validator.Free;
    Model.Free;
  end;
end;

procedure TValidationFluentTests.Test_Length_Validation;
var
  Model: TTestModel;
  Validator: TTestModelValidator;
  Result: TValidationResult;
begin
  Model := TTestModel.Create;
  Validator := TTestModelValidator.Create;
  try
    Model.Name := 'Ab'; // Too short
    Model.Email := 'test@example.com';
    Model.Age := 20;
    Model.Score := 50.0;
    Model.Active := True;

    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeFalse;
      Should.List<TValidationError>(Result.Errors).HaveCount(1);
      Should(Result.Errors[0].FieldName).Be('Name');
      Should(Result.Errors[0].ErrorMessage).Contain('between');
    finally
      Result.Free;
    end;
  finally
    Validator.Free;
    Model.Free;
  end;
end;

procedure TValidationFluentTests.Test_Email_Validation;
var
  Model: TTestModel;
  Validator: TTestModelValidator;
  Result: TValidationResult;
begin
  Model := TTestModel.Create;
  Validator := TTestModelValidator.Create;
  try
    Model.Name := 'John Doe';
    Model.Email := 'invalid-email'; // Invalid format
    Model.Age := 20;
    Model.Score := 50.0;
    Model.Active := True;

    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeFalse;
      Should.List<TValidationError>(Result.Errors).HaveCount(1);
      Should(Result.Errors[0].FieldName).Be('Email');
      Should(Result.Errors[0].ErrorMessage).Contain('email address');
    finally
      Result.Free;
    end;
  finally
    Validator.Free;
    Model.Free;
  end;
end;

procedure TValidationFluentTests.Test_Range_Validation;
var
  Model: TTestModel;
  Validator: TTestModelValidator;
  Result: TValidationResult;
begin
  Model := TTestModel.Create;
  Validator := TTestModelValidator.Create;
  try
    Model.Name := 'John Doe';
    Model.Email := 'test@example.com';
    Model.Age := 15; // Too young
    Model.Score := 150.0; // Too high
    Model.Active := True;

    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeFalse;
      Should.List<TValidationError>(Result.Errors).HaveCount(2);
    finally
      Result.Free;
    end;
  finally
    Validator.Free;
    Model.Free;
  end;
end;

procedure TValidationFluentTests.Test_Must_Validation;
var
  Model: TTestModel;
  Validator: TTestModelValidator;
  Result: TValidationResult;
begin
  Model := TTestModel.Create;
  Validator := TTestModelValidator.Create;
  try
    Model.Name := 'John Doe';
    Model.Email := 'test@example.com';
    Model.Age := 25;
    Model.Score := 50.0;
    Model.Active := False; // Fails Must validation

    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeFalse;
      Should.List<TValidationError>(Result.Errors).HaveCount(1);
      Should(Result.Errors[0].FieldName).Be('Active');
      Should(Result.Errors[0].ErrorMessage).Be('Model must be active');
    finally
      Result.Free;
    end;
  finally
    Validator.Free;
    Model.Free;
  end;
end;

procedure TValidationFluentTests.Test_When_Condition;
var
  Model: TTestModel;
  Validator: TTestModelValidator;
  Result: TValidationResult;
begin
  Model := TTestModel.Create;
  Validator := TTestModelValidator.Create;
  try
    Model.Name := 'John Doe';
    Model.Email := ''; // Email is empty, but required only if Age > 50
    Model.Age := 30;   // Under 50, should pass
    Model.Score := 50.0;
    Model.Active := True;

    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeTrue;
    finally
      Result.Free;
    end;

    // Now set Age > 50
    Model.Age := 55;
    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeFalse;
      Should.List<TValidationError>(Result.Errors).HaveCount(1);
      Should(Result.Errors[0].FieldName).Be('Email');
    finally
      Result.Free;
    end;
  finally
    Validator.Free;
    Model.Free;
  end;
end;

procedure TValidationFluentTests.Test_Custom_Message;
var
  Model: TTestModel;
  Validator: TTestModelValidator;
  Result: TValidationResult;
begin
  Model := TTestModel.Create;
  Validator := TTestModelValidator.Create;
  try
    Model.Name := 'John Doe';
    Model.Email := 'test@example.com';
    Model.Age := 25;
    Model.Score := 50.0;
    Model.Active := False;

    Result := Validator.Validate(Model);
    try
      Should(Result.Errors[0].ErrorMessage).Be('Model must be active');
    finally
      Result.Free;
    end;
  finally
    Validator.Free;
    Model.Free;
  end;
end;

procedure TValidationFluentTests.Test_Matches_Validation;
var
  Model: TTestModel;
  Validator: TTestModelValidator;
  Result: TValidationResult;
begin
  Model := TTestModel.Create;
  Validator := TTestModelValidator.Create;
  try
    Model.Name := 'John Doe';
    Model.Email := 'test@example.com';
    Model.Age := 25;
    Model.Score := 50.0;
    Model.Active := True;
    Model.Phone := 'invalid-phone'; // Invalid regex format

    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeFalse;
      Should.List<TValidationError>(Result.Errors).HaveCount(1);
      Should(Result.Errors[0].FieldName).Be('Phone');
    finally
      Result.Free;
    end;

    // Now set valid phone format: +55 11 988887777
    Model.Phone := '+55 11 988887777';
    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeTrue;
    finally
      Result.Free;
    end;
  finally
    Validator.Free;
    Model.Free;
  end;
end;

procedure TValidationFluentTests.Test_SmartProperty_Validation;
var
  Model: TSmartTestModel;
  Validator: TSmartTestModelValidator;
  Result: TValidationResult;
begin
  Model := TSmartTestModel.Create;
  Validator := TSmartTestModelValidator.Create;
  try
    Model.Name := 'Ab';
    Model.Email := 'invalid-email';
    Model.Phone := '+55 11 988887777';

    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeFalse;
      Should.List<TValidationError>(Result.Errors).HaveCount(2);
    finally
      Result.Free;
    end;
  finally
    Validator.Free;
    Model.Free;
  end;
end;

procedure TValidationFluentTests.Test_PatternRegistry_Validation;
var
  Model: TSmartTestModel;
  Validator: TSmartTestModelValidator;
  Result: TValidationResult;
begin
  Model := TSmartTestModel.Create;
  Validator := TSmartTestModelValidator.Create;
  try
    Model.Name := 'John Doe';
    Model.Email := 'test@example.com';
    Model.Phone := 'invalid-phone-format';

    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeFalse;
      Should(Result.Errors[0].FieldName).Be('Phone');
    finally
      Result.Free;
    end;

    // Correct phone format for pt-BR: +55 11 988887777
    Model.Phone := '+55 11 988887777';
    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeTrue;
    finally
      Result.Free;
    end;
  finally
    Validator.Free;
    Model.Free;
  end;
end;

procedure TValidationFluentTests.Test_SmartProperty_Expression_Validation;
var
  Model: TSmartTestModel;
  Validator: TSmartTestModelExpressionValidator;
  Result: TValidationResult;
begin
  Model := TSmartTestModel.Create;
  Validator := TSmartTestModelExpressionValidator.Create;
  try
    Model.Name := 'Normal Name'; // Doesn't contain 'Dext'
    Model.Email := '';
    
    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeFalse;
      Should.List<TValidationError>(Result.Errors).HaveCount(1);
      Should(Result.Errors[0].FieldName).Be('Name');
      Should(Result.Errors[0].ErrorMessage).Be('Name must contain Dext');
    finally
      Result.Free;
    end;

    Model.Name := 'Special Dext User'; // Contains 'Dext'
    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeTrue;
    finally
      Result.Free;
    end;
  finally
    Validator.Free;
    Model.Free;
  end;
end;

procedure TValidationFluentTests.Test_SmartProperty_When_Expression_Validation;
var
  Model: TSmartTestModel;
  Validator: TSmartTestModelExpressionValidator;
  Result: TValidationResult;
begin
  Model := TSmartTestModel.Create;
  Validator := TSmartTestModelExpressionValidator.Create;
  try
    // Name is 'Admin User' (starts with 'Admin', contains 'Dext' to pass the Name rule)
    Model.Name := 'Admin User Dext';
    Model.Email := ''; // Email is required because Name starts with 'Admin'
    
    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeFalse;
      Should.List<TValidationError>(Result.Errors).HaveCount(1);
      Should(Result.Errors[0].FieldName).Be('Email');
    finally
      Result.Free;
    end;

    // Set Email
    Model.Email := 'admin@dext.com';
    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeTrue;
    finally
      Result.Free;
    end;
  finally
    Validator.Free;
    Model.Free;
  end;
end;

procedure TValidationFluentTests.Test_ErrorMessage_Concatenation;
var
  Model: TTestModel;
  Validator: TTestModelValidator;
  Result: TValidationResult;
  ErrMsgs: string;
begin
  Model := TTestModel.Create;
  Validator := TTestModelValidator.Create;
  try
    Model.Name := '';
    Model.Email := 'invalid-email';
    Model.Age := 10;
    Model.Score := 50.0;
    Model.Active := True;

    Result := Validator.Validate(Model);
    try
      Should(Result.IsValid).BeFalse;

      // Default delimiter (sLineBreak)
      ErrMsgs := Result.ErrorMessage;
      Should(ErrMsgs).Contain(sLineBreak);

      // Custom delimiter ('; ')
      ErrMsgs := Result.ErrorMessage('; ');
      Should(ErrMsgs).Contain('; ');
      Should(ErrMsgs).NotContain(sLineBreak);
    finally
      Result.Free;
    end;
  finally
    Validator.Free;
    Model.Free;
  end;
end;

initialization
  TModelBuilder.Instance.Entity<TSmartTestModel>;

end.
