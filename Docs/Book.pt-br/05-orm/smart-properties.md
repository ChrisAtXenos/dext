# Smart Properties

Expressões de consulta type-safe usando `Prop<T>`. Permite escrever queries verificadas em tempo de compilação, eliminando "magic strings".

> 📦 **Exemplo**: [Web.SmartPropsDemo](../../../Examples/Web.SmartPropsDemo/)

## O que são Smart Properties?

Smart Properties são propriedades de entidade declaradas com o tipo `Prop<T>` (ou seus aliases como `StringType`, `IntType`, etc.) em vez dos tipos Delphi simples (`string`, `Integer`).

Elas carregam **metadados** em tempo de execução — nome da propriedade, type info e capacidade de construção de expressões — o que torna possível expressões de query type-safe.

```pascal
type
  [Table('users')]
  TUser = class
  private
    FName: StringType;   // ✅ Smart Property — carrega metadados
    FAge:  IntType;      // ✅ Smart Property
    FEmail: string;      // ⚠️ Propriedade simples — sem metadados para expressões
  public
    property Name: StringType read FName write FName;
    property Age:  IntType    read FAge  write FAge;
    property Email: string    read FEmail write FEmail;
  end;
```

> [!IMPORTANT]
> Apenas propriedades declaradas como `Prop<T>` (ou seus aliases) carregam metadados.  
> `Nullable<T>` **não** é uma Smart Property — representa apenas o estado de nulidade de um valor e não fornece metadados para expressões.

## Aliases de Tipos

Para definições de entidade mais limpas, use os aliases de `Dext.Core.SmartTypes`:

| Tipo | Equivalente Delphi |
|------|-------------------|
| `StringType` | `string` |
| `IntType` | `Integer` |
| `Int64Type` | `Int64` |
| `BoolType` | `Boolean` |
| `DateTimeType` | `TDateTime` |
| `CurrencyType` | `Currency` |

Para tipos customizados (ex: enums), defina seu próprio alias:

```pascal
type
  StatusType = Prop<TOrderStatus>;
```

## Consultando com Smart Properties

### Padrão 1: `class function Props` na entidade (Recomendado)

O padrão mais limpo é adicionar uma `class function Props` (ou `class function Prototype`) à sua entidade que retorna a classe companheira de metadados. Isso evita usar `Prototype.Entity<T>` no ponto de uso e encapsula o conhecimento da classe de metadados na própria entidade.

**Declaração da entidade:**

```pascal
type
  TUserType = class(TEntityType<TUser>)
  public
    class var Name:  TPropExpression;
    class var Age:   TPropExpression;
    class var Email: TPropExpression;
    class constructor Create;
  end;

  [Table('users')]
  TUser = class
  private
    FName: StringType;
    FAge:  IntType;
    FEmail: string;
  public
    property Name:  StringType read FName write FName;
    property Age:   IntType    read FAge  write FAge;
    property Email: string     read FEmail write FEmail;

    /// Retorna o companheiro de metadados para expressões de query type-safe.
    class function Props: TUserType; static; inline;
  end;
```

**Implementação:**

```pascal
class function TUser.Props: TUserType;
begin
  Result := TUserType.Default;
end;

class constructor TUserType.Create;
begin
  Name  := TPropExpression.Create('Name');
  Age   := TPropExpression.Create('Age');
  Email := TPropExpression.Create('Email');
end;
```

**Uso:**

```pascal
var u := TUser.Props;

var Adultos := Context.Users
  .Where(u.Age > 18)
  .OrderBy(u.Name.Asc)
  .ToList;
```

> [!TIP]
> Você também pode nomear como `class function Prototype` se preferir:
> ```pascal
> var u := TUser.Prototype;
> ```

### Padrão 2: `Prototype.Entity<T>` (Sem alterações na entidade)

Quando a entidade já possui campos `Prop<T>`, você pode usar `Prototype.Entity<T>` diretamente sem definir nenhuma classe companheira:

```pascal
uses Dext.Entity.Prototype;

var u := Prototype.Entity<TUser>;
var Adultos := Context.Users
  .Where(u.Age > 18)
  .ToList;
```

> [!WARNING]
> Este padrão **só funciona se a entidade tiver pelo menos um campo `Prop<T>`**.  
> Se a entidade usa apenas tipos Delphi simples, `Prototype.Entity<T>` lançará uma exceção em tempo de execução.  
> Veja [Entidades sem Smart Properties](#entidades-sem-smart-properties) abaixo.

## Entidades sem Smart Properties

### Por que existem

Muitas entidades em bases de código existentes foram escritas com tipos Delphi simples:

```pascal
// Entidade simples — sem Smart Properties
[Table('products')]
TProduct = class
  property Id:    Integer read FId write FId;
  property Name:  string  read FName write FName;
  property Price: Double  read FPrice write FPrice;
end;
```

Essas entidades são **totalmente funcionais** para CRUD, `ToList`, `Find`, `Any` e `Count`. Smart Properties não são necessárias para essas operações.

### O que acontece com expressões

Chamar `Prototype.Entity<TProduct>` em uma entidade simples lança uma exceção descritiva em tempo de execução:

```
Entity "TProduct" does not contain any Smart Properties (Prop<T>).
Expressions using Prototype.Entity<TProduct> will fail because standard Delphi
properties compare at compile-time.
To query this entity, please use its metadata class (inheriting from
TEntityType<TProduct>) or string-based properties (e.g. Prop('PropertyName')).
```

### Soluções para entidades simples

**Opção A — Adicionar uma classe `TEntityType<T>` com uma `class function Props` ou `Prototype` (recomendado)**

Crie uma classe companheira e a exponha diretamente da entidade. Isso oferece uma API familiar e descobrível sem alterar as propriedades simples da entidade:

```pascal
type
  TProductType = class(TEntityType<TProduct>)
  public
    class var Name:  TPropExpression;
    class var Price: TPropExpression;
    class constructor Create;
  end;

  TProduct = class
  public
    property Id:    Integer read FId write FId;
    property Name:  string  read FName write FName;
    property Price: Double  read FPrice write FPrice;

    // Expõe metadados diretamente da entidade
    class function Props: TProductType; static; inline;
  end;
```

Uso:

```pascal
var p := TProduct.Props;

var Baratos := Context.Products
  .Where(p.Price < 10)
  .ToList;
```

**Opção B — Usar expressões baseadas em string**

Para queries pontuais sem criar uma classe companheira, use `Prop('NomeDaPropriedade')`:

```pascal
var Baratos := Context.Products
  .Where(Prop('Price') < 10)
  .ToList;
```

> [!CAUTION]
> Expressões baseadas em string não são verificadas em tempo de compilação. Erros de digitação nos nomes de propriedades só aparecem como erros em tempo de execução.

## Queries de retorno total sempre funcionam

Consultar **todos os registros** sem cláusula `Where` nunca requer Smart Properties:

```pascal
// ✅ Sempre funciona, independente dos tipos de propriedade
var Todos  := Context.Products.ToList;
var Existe := Context.Products.Any;
var N      := Context.Products.Count;
```

Apenas `.Where(expressão)` e `.OrderBy(prop)` se beneficiam de Smart Properties.

## Operações Suportadas

### Comparações
- `=`, `<>`, `>`, `>=`, `<`, `<=`
- `In([V1, V2])`, `NotIn([V1, V2])`
- `IsNull`, `IsNotNull`

### Lógica de String
- `Contains('texto')`
- `StartsWith('texto')`
- `EndsWith('texto')`
- `Like('%texto%')`

### Lógica Booleana
```pascal
var u := TUser.Props;
Context.Users.Where((u.Age > 18) and (u.IsActive = True)).ToList;
```

## Por que usar Smart Properties?

1. **Segurança de Refatoração**: Renomear uma propriedade é detectado em tempo de compilação em todas as queries.
2. **Legibilidade**: O código fica próximo do SQL mas permanece 100% Pascal.
3. **Suporte de IDE**: Code completion funciona para todos os campos disponíveis na query.
4. **Descobribilidade**: `TUser.Props` é autodocumentável — desenvolvedores sabem imediatamente quais campos são consultáveis.

---

[← Consultas](consultas.md) | [Próximo: Specifications →](specifications.md)
