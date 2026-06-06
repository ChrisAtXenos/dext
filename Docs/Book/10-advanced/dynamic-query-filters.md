# Dynamic Query Filters

Dext ORM applies **global query filters** automatically on every query. The most common ones are:

- **Soft Delete** — records marked as deleted are hidden (`WHERE IsDeleted = 0`).
- **Multi-Tenancy** — queries are scoped to the current tenant (`WHERE TenantId = 'x'`).

Sometimes you need to bypass these filters — for audits, admin panels, or recovery workflows. Dynamic Query Filters give you a type-safe, one-line escape hatch.

---

## Bypassing Filters — Three Approaches

### 1. Directly on DbSet

```pascal
// Returns ALL records, including soft-deleted ones
var AllTasks := Db.Tasks.IgnoreQueryFilters.ToList;

// Or: return only the soft-deleted ones
var Trash := Db.Tasks.OnlyDeleted.ToList;
```

`IgnoreQueryFilters` is scoped to the single call. Subsequent calls to `Db.Tasks.ToList` will still apply all filters normally.

---

### 2. Via Specification

```pascal
uses Dext.Specifications;

var Spec := TSpecification<TTask>.Create;
Spec.IgnoreQueryFilters;

var AllTasks := Db.Tasks.ToList(Spec);
```

The `IsIgnoringFilters` flag on the spec is automatically propagated to the `DbSet` before SQL generation, and reset immediately after.

---

### 3. Self-Contained Admin Spec (Recommended Pattern)

For recurring administrative queries, embed the flag in the spec constructor:

```pascal
type
  TAllTasksSpec = class(TSpecification<TTask>)
  public
    constructor Create;
  end;

constructor TAllTasksSpec.Create;
begin
  inherited Create;
  IgnoreQueryFilters; // Declared once, reusable everywhere
  OrderBy(TPropExpression.Create('Id').Desc);
end;

// Usage — clean, no magic strings
var AllTasks := Db.Tasks.ToList(TAllTasksSpec.Create);
```

---

## Multi-Tenancy Bypass

`IgnoreQueryFilters` bypasses **both** Soft Delete and Multi-Tenancy filters simultaneously. This is ideal for super-admin operations that need cross-tenant access.

```pascal
// Cross-tenant admin query
var AllOrders := Db.Orders.IgnoreQueryFilters.ToList;
```

> [!CAUTION]
> Only use `IgnoreQueryFilters` in trusted administrative contexts. Never expose it on public API endpoints without explicit authorization checks.

---

## How It Works

```
DbSet.IgnoreQueryFilters.ToList
│
├── TFluentQuery.IgnoreQueryFilters
│     └── Sets ISpecification.FIgnoreQueryFilters = True
│
└── TDbSet<T>.ToList(ASpec)
      ├── Reads Spec.IsIgnoringFilters
      ├── Sets FIgnoreQueryFilters = True on DbSet (scoped)
      ├── TSQLGenerator skips GetSoftDeleteFilter  → no WHERE IsDeleted
      ├── TSQLGenerator skips GetQueryFiltersSQL   → no tenant filter
      └── finally: ResetQueryFlags (restores state)
```

The entire mechanism is **call-scoped**: each `ToList` call is independent.

---

## API Reference

| API | Description |
|---|---|
| `DbSet.IgnoreQueryFilters.ToList` | Bypasses all global filters for this query |
| `DbSet.OnlyDeleted.ToList` | Returns only soft-deleted records |
| `ISpecification.IgnoreQueryFilters` | Sets the flag on the spec object |
| `ISpecification.IsIgnoringFilters` | Reads the flag (used internally by `ToList`) |
| `ISpecification.IsOnlyDeleted` | Reads the OnlyDeleted flag (used internally by `ToList`) |

---

[← Background Jobs](background-jobs.md) | [Advanced Topics →](README.md)
