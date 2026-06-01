# S30 — Automatic DbContext Hydration & TDbOptions Builder Evolution

This architectural specification details the design for introducing **Automatic DbContext Hydration** (Wave 2/3 productivity) to eliminate boilerplate code inside custom `TDbContext` classes, and defines the builder record syntax evolution for fluent configuration initialization.

---

## 1. Context & Motivation

Currently in Dext, developers map entity tables to `IDbSet<T>` repositories inside a custom `TDbContext` subclass. A typical best-practice context requires explicit property declarations paired with manual getters returning the generic `Entity<T>` call:

```pascal
type
  TAppDbContext = class(TDbContext)
  private
    function GetProducts: IDbSet<TProduct>;
    function GetOrders: IDbSet<TOrder>;
  public
    property Products: IDbSet<TProduct> read GetProducts;
    property Orders: IDbSet<TOrder> read GetOrders;
  end;

function TAppDbContext.GetProducts: IDbSet<TProduct>;
begin
  Result := Entity<TProduct>;
end;
```

While extremely clean compared to legacy Delphi, this still introduces redundant getter methods for large databases with dozens of tables. 

Our goal is to build an **Automatic Hydration Factory** into `TDbContext` using RTTI scanning at instantiation. During class construction, Dext should automatically inspect all generic fields/properties of type `IDbSet<T>`, resolve their mapping, and populate them automatically, eliminating getters entirely.

Additionally, we address the initialization syntax of configuration builders. The previous mock syntax:
```pascal
var Db := TAppDbContext.Create(
  DbOptions.UsePostgreSQL(ConnectionString)
);
```
needs to be fully resolved. In Pascal, `DbOptions` is either a class that requires a `.Create` call (introducing boilerplate), or it can be engineered as a **fluent Builder Record** utilizing a global inline constructor function and **Implicit Operator Overloading** to yield the concrete configuration instance.

---

## 2. Part A: DbContext Auto-Hydration Patterns

We analyze three candidate patterns to support automatic instantiation of repositories during DbContext construction.

### Pattern 1: Public/Published Fields (Direct Auto-Binding)
```pascal
type
  TAppDbContext = class(TDbContext)
  public
    Products: IDbSet<TProduct>;
    Orders: IDbSet<TOrder>;
  end;
```
* **Pros**: 
  - Absolute minimum code footprint. 
  - No getters, no private fields, no properties. Very clean, close to C# `DbSet<T>` fields.
* **Cons**: 
  - **Critical Architectural Risk**: Fields are read-write. An accidental assignment in user code (e.g., `Db.Products := nil;` or overriding it with another instance) breaks context consistency and change-tracking tracking, causing runtime AVs that are hard to debug.

### Pattern 2: Private Fields + Public Read-Only Properties (Highly Safe & Recommended)
```pascal
type
  TAppDbContext = class(TDbContext)
  private
    FProducts: IDbSet<TProduct>;
    FOrders: IDbSet<TOrder>;
  public
    property Products: IDbSet<TProduct> read FProducts;
    property Orders: IDbSet<TOrder> read FOrders;
  end;
```
* **Pros**:
  - **Complete Architectural Safety**: The property is strictly read-only. User code cannot accidentally assign, overwrite, or clear the repository instance.
  - Highly idiomatic Delphi.
* **Cons**:
  - Slightly more verbose than Pattern 1 (requires writing the private field and property wrapper).

---

## 3. The Implementation Specification (Pattern 2)

Dext implements **Pattern 2** natively inside `TDbContext`.

### RTTI Hydration Factory Implementation
When `TDbContext` is constructed, it will scan its own class structure using `Dext.Core.Reflection` (specifically the optimized type cache from [S07](S07-High-Perf-Reflection.md)):

1. Scan all private fields of the instance (`TRttiField`).
2. Identify fields where the type is a generic interface matching `IDbSet<T>`.
3. Extract the generic parameter type `T` from `PTypeInfo`.
4. Call `Entity<T>` internally to obtain or instantiate the corresponding repository.
5. Inject the instantiated `IDbSet<T>` directly into the private field using low-level field write offsets (`TRttiField.SetValue`).

This process happens once per class layout, cached in the global RTTI cache, ensuring that instantiation overhead is sub-microsecond and completely negligible.

---

## 4. Part B: TDbOptions Builder Evolution

To support the highly ergonomic initialization syntax:
```pascal
var Db := TAppDbContext.Create(
  DbOptions.UsePostgreSQL(ConnectionString)
);
```
We define the structure of `DbOptions`. 

### The Under-the-Hood Architecture
1. **`DbOptions` (Global Constructor Function)**: A global inline function returning a `TDbOptionsBuilder` record.
2. **`TDbOptionsBuilder` (Fluent Record)**: A record that contains chainable configuration methods: `.UsePostgreSQL(ConnectionString)`, `.UseSQLite(ConnectionString)`, etc.
3. **Implicit Operator Overloading**: The record implements an implicit operator to convert `TDbOptionsBuilder` to the concrete, allocated class `TDbOptions` required by the `TDbContext` constructor.

```pascal
type
  TDbOptions = class
  private
    FDriverId: string;
    FConnectionString: string;
  public
    property DriverId: string read FDriverId write FDriverId;
    property ConnectionString: string read FConnectionString write FConnectionString;
  end;

  TDbOptionsBuilder = record
  private
    FDriverId: string;
    FConnectionString: string;
  public
    function UsePostgreSQL(const AConnStr: string): TDbOptionsBuilder;
    function UseSQLite(const AConnStr: string): TDbOptionsBuilder;
    
    class operator Implicit(const ABuilder: TDbOptionsBuilder): TDbOptions;
  end;

// Global Constructor Function
function DbOptions: TDbOptionsBuilder; inline;

implementation

function DbOptions: TDbOptionsBuilder;
begin
  Result := Default(TDbOptionsBuilder);
end;

function TDbOptionsBuilder.UsePostgreSQL(const AConnStr: string): TDbOptionsBuilder;
begin
  Result := Self;
  Result.FDriverId := 'PG';
  Result.FConnectionString := AConnStr;
end;

class operator TDbOptionsBuilder.Implicit(const ABuilder: TDbOptionsBuilder): TDbOptions;
begin
  Result := TDbOptions.Create;
  Result.DriverId := ABuilder.FDriverId;
  Result.ConnectionString := ABuilder.FConnectionString;
end;
```

This ensures that the final user syntax is extremely elegant and 100% compile-safe, completely hiding manual instantiation and resource cleanup of options from the end-user.

---

*Dext Specifications — S30 Automatic Context Hydration | May 2026*
