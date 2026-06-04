# S34 — Dynamic Query Filters (ORM Bypass)

This architectural specification details the design for dynamically bypassing global query filters (like Multi-Tenancy and Soft Delete) at the query level in Dext ORM.

---

## 1. Context & Motivation

Dext ORM supports Global Query Filters (such as automatic soft-delete filter `IsDeleted = 0` or tenant isolation `TenantId = X`). While extremely useful for security and convenience, administrative queries or specific reports often need to bypass these filters to access raw historical records or query across tenants.

Currently, bypassing these filters requires writing manual raw SQL commands. This specification defines a type-safe fluent mechanism to bypass query filters at the `DbSet<T>` level dynamically.

---

## 2. Fluent API Design

We introduce the `.IgnoreQueryFilters` chainable method to the `TFluentQuery<T>` query builder:

```pascal
var AllUsers := Db.Users.IgnoreQueryFilters.ToList;
```

### Underlying Execution Mechanism

1. **State Flag**: `TFluentQuery<T>` and `ISpecification<T>` are updated to maintain a boolean flag `FIgnoreQueryFilters` (default: `False`).
2. **Ignored Injection**: When query filters are applied in `TDbSet<T>.ToList`, the method checks if the specification has `IgnoreQueryFilters` enabled:
   ```pascal
   procedure TDbSet<T>.ApplyTenantFilter(var ASpec: ISpecification<T>);
   begin
     if (ASpec <> nil) and ASpec.IsQueryFilterIgnored then Exit;
     // ... otherwise proceed to inject TenantId filter
   end;
   ```
3. **Soft Delete Filter**: The soft delete compiler handler similarly skips appending the exclusion predicate if the flag is set.

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
```

---
*Dext Specifications — S34 Dynamic Query Filters | June 2026*
