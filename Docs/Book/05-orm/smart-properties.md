# Smart Properties

Type-safe query expressions using `Prop<T>`. This allows you to write queries that are checked at compile time, eliminating "magic strings".

> 📦 **Example**: [Web.SmartPropsDemo](../../../Examples/Web.SmartPropsDemo/)

## What are Smart Properties?

Smart Properties are entity properties declared with the `Prop<T>` record type (or its aliases like `StringType`, `IntType`, etc.) instead of plain Delphi types (`string`, `Integer`).

They carry **metadata** at runtime — property name, type info, and expression-building capability — that makes type-safe query expressions possible.

```pascal
type
  [Table('users')]
  TUser = class
  private
    FName: StringType;   // ✅ Smart Property — carries metadata
    FAge:  IntType;      // ✅ Smart Property
    FEmail: string;      // ⚠️ Plain property — no metadata for expressions
  public
    property Name: StringType read FName write FName;
    property Age:  IntType    read FAge  write FAge;
    property Email: string    read FEmail write FEmail;
  end;
```

> [!IMPORTANT]
> Only properties declared as `Prop<T>` (or its aliases) carry metadata.  
> `Nullable<T>` is **not** a Smart Property — it only represents the nullability state of a value and does not provide expression metadata.

## Type Aliases

For cleaner entity definitions, use the following aliases from `Dext.Core.SmartTypes`:

| Type | Delphi Equivalent |
|------|-------------------|
| `StringType` | `string` |
| `IntType` | `Integer` |
| `Int64Type` | `Int64` |
| `BoolType` | `Boolean` |
| `DateTimeType` | `TDateTime` |
| `CurrencyType` | `Currency` |

For custom types (e.g., enums), define your own alias:

```pascal
type
  StatusType = Prop<TOrderStatus>;
```

## Querying with Smart Properties

### Pattern 1: `Props` class function (Recommended)

The cleanest pattern is to add a `class function Props` (or `class function Prototype`) to your entity that returns the companion metadata class. This avoids using `Prototype.Entity<T>` at the call site and keeps the knowledge of the metadata class encapsulated in the entity itself.

**Entity declaration:**

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

    /// Returns the metadata companion for type-safe query expressions.
    class function Props: TUserType; static; inline;
  end;
```

**Implementation:**

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

**Usage:**

```pascal
var u := TUser.Props;

var Adults := Context.Users
  .Where(u.Age > 18)
  .OrderBy(u.Name.Asc)
  .ToList;
```

> [!TIP]
> You can also name it `class function Prototype` if you prefer:
> ```pascal
> var u := TUser.Prototype;
> ```

### Pattern 2: `Prototype.Entity<T>` (No changes to entity)

When the entity already has `Prop<T>` fields, you can use `Prototype.Entity<T>` directly without defining any companion class:

```pascal
uses Dext.Entity.Prototype;

var u := Prototype.Entity<TUser>;
var Adults := Context.Users
  .Where(u.Age > 18)
  .ToList;
```

> [!WARNING]
> This pattern **only works if the entity has at least one `Prop<T>` field**.  
> If the entity uses only plain Delphi types, `Prototype.Entity<T>` will raise an exception at runtime.  
> See [Entities without Smart Properties](#entities-without-smart-properties) below.

## Entities without Smart Properties

### Why they exist

Many entities in existing codebases were written with plain Delphi types:

```pascal
// Plain entity — no Smart Properties
[Table('products')]
TProduct = class
  property Id:    Integer read FId write FId;
  property Name:  string  read FName write FName;
  property Price: Double  read FPrice write FPrice;
end;
```

These entities are **fully functional** for CRUD, `ToList`, `Find`, `Any`, and `Count`. No Smart Properties are required for those operations.

### What happens with expressions

Calling `Prototype.Entity<TProduct>` on a plain entity raises a descriptive exception at runtime:

```
Entity "TProduct" does not contain any Smart Properties (Prop<T>).
Expressions using Prototype.Entity<TProduct> will fail because standard Delphi
properties compare at compile-time.
To query this entity, please use its metadata class (inheriting from
TEntityType<TProduct>) or string-based properties (e.g. Prop('PropertyName')).
```

### Solutions for plain entities

**Option A — Add a companion `TEntityType<T>` class with a `Props` or `Prototype` class function (recommended)**

This is the cleanest approach: create a companion class and expose it directly from the entity. This gives developers a familiar, discoverable API without touching the entity's plain properties:

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

    // Expose metadata directly from the entity
    class function Props: TProductType; static; inline;
  end;
```

Usage:

```pascal
var p := TProduct.Props;

var Cheap := Context.Products
  .Where(p.Price < 10)
  .ToList;
```

**Option B — Use string-based expressions**

For ad-hoc queries without creating a companion class, use `Prop('PropertyName')`:

```pascal
var Cheap := Context.Products
  .Where(Prop('Price') < 10)
  .ToList;
```

> [!CAUTION]
> String-based expressions are not verified at compile time. Typos in property names will only surface as runtime errors.

## Return-all queries always work

Querying **all records** without a `Where` clause never requires Smart Properties:

```pascal
// ✅ Always works, regardless of property types
var All := Context.Products.ToList;
var Any := Context.Products.Any;
var N   := Context.Products.Count;
```

Only `.Where(expression)` and `.OrderBy(prop)` benefit from Smart Properties.

## Supported Operations

### Comparisons
- `=`, `<>`, `>`, `>=`, `<`, `<=`
- `In([V1, V2])`, `NotIn([V1, V2])`
- `IsNull`, `IsNotNull`

### String Logic
- `Contains('text')`
- `StartsWith('text')`
- `EndsWith('text')`
- `Like('%text%')`

### Boolean Logic
```pascal
var u := TUser.Props;
Context.Users.Where((u.Age > 18) and (u.IsActive = True)).ToList;
```

## Why use Smart Properties?

1. **Refactoring Safety**: Renaming a property is caught at compile time across all queries.
2. **Readability**: Code reads close to SQL yet remains 100% Pascal.
3. **IDE Support**: Code completion works for all available fields in the query.
4. **Discoverability**: `TUser.Props` is self-documenting — developers immediately know which fields are queryable.

---

[← Querying](querying.md) | [Next: Specifications →](specifications.md)
