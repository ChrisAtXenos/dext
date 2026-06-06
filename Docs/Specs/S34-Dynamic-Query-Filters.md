# S34 — Dynamic Query Filters (ORM Bypass)

**Status:** ✅ Finalized — Implemented in `Dext.Entity.DbSet` and `Dext.Specifications.SQL.Generator`

This architectural specification details the design for dynamically bypassing global query filters (like Multi-Tenancy and Soft Delete) at the query level in Dext ORM.

---

## 1. Context & Motivation

Dext ORM supports Global Query Filters (such as automatic soft-delete filter `IsDeleted = 0` or tenant isolation `TenantId = X`). While extremely useful for security and convenience, administrative queries or specific reports often need to bypass these filters to access raw historical records or query across tenants.

Bypassing these filters required writing manual raw SQL commands. This specification defined a type-safe fluent mechanism to bypass query filters at the `DbSet<T>` level dynamically.

---

## 2. Fluent API Design

The `.IgnoreQueryFilters` chainable method is available on both `IDbSet<T>` and `TFluentQuery<T>`:

```pascal
// Via DbSet directly
var AllTasks := Db.Tasks.IgnoreQueryFilters.ToList;

// Via Specification
var Spec := TSpecification<TUser>.Create;
Spec.IgnoreQueryFilters;
var AllUsers := Db.Users.ToList(Spec);
```

### Underlying Execution Mechanism

1. **State Flag**: `TFluentQuery<T>` and `ISpecification<T>` maintain a boolean flag `FIgnoreQueryFilters` (default: `False`).
2. **Spec Propagation**: In `TDbSet<T>.ToList(ASpec)`, the spec's `IsIgnoringFilters` flag is read and applied to the DbSet's internal state before executing the query. The `ResetQueryFlags` in the `finally` block ensures this is scoped to a single call.
3. **Soft Delete Filter**: `TSQLGenerator<T>.GetSoftDeleteFilter` returns an empty string when `FIgnoreQueryFilters` is `True`.
4. **Tenant Filter**: `TDbSet<T>.ApplyTenantFilter` skips injection when `FIgnoreQueryFilters` is `True`.
5. **Global Query Filters**: `TSQLGenerator<T>.GetQueryFiltersSQL` exits early when `FIgnoreQueryFilters` is `True`.

---

## 3. Specification Integration

The specification pattern supports ignoring query filters explicitly, enabling clean reuse of administrative specs:

```pascal
type
  TAdminUserListSpec = class(TSpecification<TUser>)
  public
    constructor Create;
  end;

constructor TAdminUserListSpec.Create;
begin
  inherited Create;
  IgnoreQueryFilters; // Bypasses Soft Delete & Tenancy automatically
  Where(TPropExpression.Create('Role').Equal('SuperAdmin'));
end;

// Usage
var AllAdmins := Db.Users.ToList(TAdminUserListSpec.Create);
```

---

## 4. Implementation Summary

| File | Change |
|---|---|
| `Dext.Entity.DbSet.pas` | `ToList(ASpec)` now propagates `IsIgnoringFilters` and `IsOnlyDeleted` from `ISpecification` to `FIgnoreQueryFilters`/`FOnlyDeleted` before calling `ApplyTenantFilter` and `CreateGenerator`. |
| `Dext.Entity.Query.pas` | `TFluentQuery<T>.IgnoreQueryFilters` already propagated to `ISpecification` — no change needed. |
| `Dext.Specifications.SQL.Generator.pas` | Already respected `FIgnoreQueryFilters` — no change needed. |
| `Dext.Entity.DynamicQueryFilter.Tests.pas` | New test file with 4 unit tests and 4 integration tests. |
| `Dext.Entity.UnitTests.dpr` | Registered `TFluentQueryTests`, `TDynamicQueryFilterUnitTests`, and `TDynamicQueryFilterIntegrationTests`. |

---
*Dext Specifications — S34 Dynamic Query Filters | June 2026 — Finalized*
