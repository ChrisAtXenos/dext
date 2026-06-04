# Validação

O Dext fornece um mecanismo de validação de alto desempenho que suporta tanto a **Validação baseada em Atributos** (declarativa) quanto a **Validação Fluente** (fortemente tipada).

---

## 1. Validação Baseada em Atributos

Você pode decorar os campos ou propriedades do seu modelo com atributos de validação integrados via RTTI:

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

Para validar uma instância programaticamente:
```pascal
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

## 2. API de Validação Fluente (Fluent Validation)

Para regras de negócio mais complexas, condições dinâmicas ou tipagem forte e limpa, utilize a **API de Validação Fluente**.

Herde de `TAbstractValidator<T>` e defina suas regras no construtor utilizando `RuleFor`:

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
  
  // Validação Must customizada
  RuleFor('Active', function(Model: TUser): TValue
    begin
      Result := Model.Active;
    end).Must(function(Val: TValue): Boolean
    begin
      Result := Val.AsBoolean;
    end).WithMessage('User must be active');

  // Validação condicional
  RuleFor('Email').Required.When(function(Model: TUser): Boolean
    begin
      Result := Model.Age > 50;
    end);
end;
```

---

## 3. Integração com Smart Properties (Tipagem Forte)

Se os seus modelos usam Smart Properties (`Prop<T>`), você pode eliminar completamente magic strings mapeando as regras de validação diretamente às suas propriedades através de uma entidade fantasma gerada por `Prototype`:

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

## 4. Registro de Padrões (`TValidationPatterns`)

O registro global `TValidationPatterns` permite reutilizar e organizar expressões regulares localizadas para diferentes culturas/locales:

```pascal
// Registro de padrão customizado
TValidationPatterns.Register('PostalCode', '^\d{5}$', 'fr-FR');

// Referência no validador
RuleFor(m.PostalCode).MatchesPattern('PostalCode', 'fr-FR');
```

---

## 5. Validação Automática no Model Binding Web

Ao realizar o bind de uma requisição HTTP de entrada para um parâmetro do endpoint:
1. Registre sua classe validadora nos serviços DI durante o startup:
   ```pascal
   Builder.Services.AddSingleton<IValidator<TUser>, TUserValidator>;
   ```
2. O Dext detectará automaticamente o validador registrado e o executará no pipeline de model binding.
3. Se a validação falhar, uma exceção `TWebValidationException` é gerada, retornando automaticamente um HTTP 400 Bad Request com uma estrutura JSON contendo os erros de validação correspondentes.
