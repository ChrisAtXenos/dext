# Validation

Dext provides a dual-model, high-performance validation engine that supports both declarative **Attribute-Based Validation** and strongly-typed **Fluent Validation**.

---

## 1. Attribute-Based Validation

You can decorate your model fields or properties with built-in RTTI validation attributes:

```pascal
type
  TUser = class
  private
    FName: string;
    FAge: Integer;
    FEmail: string;
  public
    [Required]
    [StringLength(3, 50)]
    property Name: string read FName write FName;

    [Range(18, 99)]
    property Age: Integer read FAge write FAge;

    [EmailAddress]
    property Email: string read FEmail write FEmail;
  end;
```

To validate an instance programmatically:
```pascall
var Result := TValidator.Validate(User);
try
  if not Result.IsValid then
  begin
    for var Error in Result.Errors do
      Writeln(Error.FieldName, ': ', Error.ErrorMessage);
  end;
finally
  Result.Free;
end;
```

---

## 2. Fluent Validation API

For more complex business rules, dynamic conditions, or clean strong-typing, use the **Fluent Validation API**.

Inherit from `TAbstractValidator<T>` and define your rules in the constructor using `RuleFor`:

```pascal
type
  TUserValidator = class(TAbstractValidator<TUser>)
  public
    constructor Create; override;
  end;

constructor TUserValidator.Create;
begin
  inherited Create;
  
  RuleFor('Name').Required.Length(3, 50);
  RuleFor('Email').EmailAddress;
  RuleFor('Age').Range(18, 99);
  
  // Custom Must validation
  RuleFor('Active', function(Model: TUser): TValue
    begin
      Result := Model.Active;
    end).Must(function(Val: TValue): Boolean
    begin
      Result := Val.AsBoolean;
    end).WithMessage('User must be active');

  // Conditional validation
  RuleFor('Email').Required.When(function(Model: TUser): Boolean
    begin
      Result := Model.Age > 50;
    end);
end;
```

---

## 3. Smart Property Integration (Type-Safe Validation)

If your models use Dext `Prop<T>` Smart Properties, you can completely eliminate magic strings by mapping validation rules directly to your properties via a `Prototype` ghost entity:

```pascal
type
  TOrderValidator = class(TAbstractValidator<TOrder>)
  public
    constructor Create; override;
  end;

constructor TOrderValidator.Create;
begin
  inherited Create;
  var m := Prototype.Entity<TOrder>;
  
  RuleFor(m.CustomerName).Required.Length(3, 100);
  RuleFor(m.Total).Range(1.0, 10000.0);
  RuleFor(m.Phone).MatchesPattern('Phone', 'pt-BR');
end;
```

---

## 4. Pattern Registry (`TValidationPatterns`)

The global `TValidationPatterns` registry allows you to reuse and locate localized regular expressions:

```pascal
// Custom pattern registration
TValidationPatterns.Register('PostalCode', '^\d{5}$', 'fr-FR');

// Reference in validator
RuleFor(m.PostalCode).MatchesPattern('PostalCode', 'fr-FR');
```

---

## 5. Web Model Binding Auto-Validation

When an incoming request is bound to a model parameter in an endpoint:
1. Register your validator class in your DI setup during startup:
   ```pascal
   Builder.Services.AddSingleton<IValidator<TUser>, TUserValidator>;
   ```
2. Dext automatically detects the registered validator and executes it in the model binding pipeline.
3. If validation fails, a `TWebValidationException` is raised, automatically returning an HTTP 400 Bad Request with a structured JSON detailing the validation errors.
