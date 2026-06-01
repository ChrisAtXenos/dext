# Multi-Mapping (Nested Objects) & Hydration Engine

Dext supports **Multi-Mapping** (similar to Dapper's multi-mapping), allowing you to hydrate complex, multi-level object graphs from a single flat SQL query with multiple joins. This is achieved using the `[Nested]` attribute.

Unlike other ORMs or micro-mappers that require complex lambda functions or manual splitting strings, Dext implements a **convention-driven, highly optimized recursive hydration engine**.

---

## The [Nested] Attribute

The `[Nested]` attribute tells the ORM that a property represents a nested object that should be hydrated from the columns of the current result set, rather than being loaded via a separate query (Lazy Loading) or an `Include` join.

### Basic Example

```pascal
type
  TAddress = class
  private
    FStreet: string;
    FCity: string;
  public
    property Street: string read FStreet write FStreet;
    property City: string read FCity write FCity;
  end;

  [Table('Users')]
  TUser = class
  private
    FId: Integer;
    FName: string;
    FAddress: TAddress;
  public
    [PK, AutoInc]
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;

    [Nested]
    property Address: TAddress read FAddress write FAddress;
  end;
```

---

## Hydration Logic Under the Hood

When you execute a query, Dext reads the flat list of column names returned by the database. 

Instead of requiring a manual C# Dapper-style `splitOn` string configuration (e.g. `splitOn: 'Id'`), Dext's `TReflection` and `TDbSet` engines work via **Convention-Based Path Routing**:

1. **Path Scanning**: The hydrator encounters columns with separators like `_` or `.` (e.g. `Address_Street`, `Address_City` or `Address.Street`).
2. **Auto-Instantiation**: The hydrator checks the prefix `Address`. If the property exists on the target entity (`TUser`), is class-typed, and currently `nil`, the hydrator **automatically instantiates it** on-the-fly using the optimized, thread-safe `TActivator` cache.
3. **Direct Field Writing**: During hydration, Dext bypasses slow property setters. It writes directly to the private backing fields (e.g. `FStreet`, `FCity`) resolved via RTTI cache, preventing side-effects or dirty-tracking overhead on the change tracker.

```pascal
// Executing a flat raw SQL query with joined tables
var Users := Db.Users.FromSql(
  'SELECT u.Id, u.Name, a.Street AS Address_Street, a.City AS Address_City ' +
  'FROM Users u INNER JOIN Addresses a ON u.AddressId = a.Id'
).ToList;

// Result: Each TUser object is created, its FAddress object is automatically
// allocated, and the nested fields are fully hydrated.
```

---

## Advanced Multi-Mapping with Prefixes

You can specify a custom prefix in the `[Nested]` attribute to map columns that don't match the property name exactly:

```pascal
type
  TUser = class
  private
    FAddress: TAddress;
  public
    [Nested('addr_')]
    property Address: TAddress read FAddress write FAddress;
  end;

// The hydrator now expects columns starting with: addr_Street, addr_City
```

---

## Recursive Nesting to Infinite Depth

Because Dext's `TReflection.SetValueByPath` is fully recursive, it supports mapping deep object trees. The hydration engine will traverse and automatically allocate nested classes to any depth as long as matching column paths are found in the query result.

### Deep Nesting Example

```pascal
type
  TCountry = class
  private
    FName: string;
  public
    property Name: string read FName write FName;
  end;

  TAddress = class
  private
    FCity: string;
    FCountry: TCountry;
  public
    property City: string read FCity write FCity;
    
    [Nested]
    property Country: TCountry read FCountry write FCountry;
  end;

  TUser = class
  private
    FAddress: TAddress;
  public
    [Nested]
    property Address: TAddress read FAddress write FAddress;
  end;
```

**Columns to query**:
* `Address_City`
* `Address_Country_Name` (or `Address.Country.Name`)

When Dext hydrator processes the column `Address_Country_Name`, it splits it into segments (`Address` -> `Country` -> `Name`). It will automatically instantiate `FAddress` (if `nil`), then instantiate `FCountry` (if `nil`), and finally set the `Name` field of the country instance.

---

## When to use Multi-Mapping vs Include

*   **Use `Include`**: For standard database relationships (1:1, 1:N) where the related entity is a tracked DB entity with its own independent lifecycle and primary keys.
*   **Use `[Nested]`**:
    *   For **Value Objects** (DDD pattern) that don't have their own database identity and are stored in the same table as the owner.
    *   To manually optimize complex joins when executing raw SQL queries via `FromSql`.
    *   To completely bypass entity tracking overhead and pull complex, read-only DTOs/projections in a single flat database trip.
