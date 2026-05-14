# S21 - Soft Delete Evolution: Timestamp-based Audit

## Status
- **Date**: 2026-05-14
- **Author**: Antigravity & Cesar Romero
- **Status**: Draft (Implementation Pending)
- **Issue Reference**: Internal Feedback

## 1. Context & Rationale
Currently, Dext Framework supports Soft Delete exclusively via fixed-value flags (typically a `Boolean` or `Integer`). While this is highly performant for indexing and simple "is deleted" checks, it lacks crucial audit information requested by enterprise users: **When was this record deleted?**

Storing the deletion timestamp is a common industry pattern that provides both the "deleted status" (Presence of value vs. NULL) and audit trail without requiring a separate audit table for basic cleanup operations.

## 2. Goals
- **Auditability**: Allow users to track the exact moment of record deletion.
- **Performance/Audit Trade-off**: Maintain the existing Boolean-based Soft Delete for high-performance scenarios while offering Timestamp-based Soft Delete for audit-heavy scenarios.
- **Inferred Behavior**: The presence of a `DeletedAt` field should automatically imply Soft Delete behavior for the entity.
- **Zero Configuration**: Adhere to the "Convention over Configuration" principle where possible.

## 3. Technical Design

### 3.1. New Attribute: `[DeletedAt]`
A new specialized attribute will be introduced to mark the timestamp column.

```pascal
[Table('Customers')]
TCustomer = class
  [PK, AutoInc] Id: Integer;
  Name: string;
  
  [DeletedAt] 
  DeletedAt: TDateTime; // Marks this as the Soft Delete field
end;
```

### 3.2. Mapping Evolution
The mapping engine (`Dext.Entity.Mapping.pas`) will be updated to recognize `[DeletedAt]`.
- If `[DeletedAt]` is found, `IsSoftDelete` is set to `True`.
- The soft delete column is automatically mapped to this property.
- The "Not Deleted" value is implicitly `NULL`.
- The "Deleted" value is dynamic (the current timestamp at the moment of deletion).

### 3.3. SQL Generation Logic
`TSQLGenerator<T>` must be adjusted to handle `NULL` checks for timestamps:
- **Filter**: Instead of `Column = 0`, it will generate `Column IS NULL` for active records.
- **Exclusion**: In the "Update" payload during a Soft Delete operation, the value will be the current server time (or local time via ORM).

### 3.4. Deletion Logic (TDbSet)
In `PersistRemove`, if the entity is mapped via `[DeletedAt]`:
1. The ORM captures the current date/time (`Now`).
2. It assigns this value to the property marked with `[DeletedAt]`.
3. It triggers a `PersistUpdate` instead of a physical `DELETE`.

## 4. Design Principles: Performance vs. Audit

| Feature | Boolean Soft Delete (`SoftDeleteAttribute`) | Timestamp Soft Delete (`DeletedAtAttribute`) |
| :--- | :--- | :--- |
| **Index Size** | Small (often bitmapped or high cardinality) | Larger (datetime index) |
| **Query Speed** | Slightly Faster (equality check) | Fast (NULL check) |
| **Audit Trail** | No (only status) | Yes (deletion date/time) |
| **Complexity** | Low | Low |

**Guideline**: Use `[SoftDelete]` for massive tables where query speed is the only concern. Use `[DeletedAt]` for business entities where knowing the deletion time is required for reporting or compliance.

## 5. Files Impacted
- `Sources\Data\Dext.Entity.Attributes.pas`: New `DeletedAtAttribute` class.
- `Sources\Data\Dext.Entity.Mapping.pas`: Logic to detect and store `DeletedAt` metadata.
- `Sources\Data\Dext.Specifications.SQL.Generator.pas`: Support for `IS NULL` filters in `GetSoftDeleteFilter`.
- `Sources\Data\Dext.Entity.DbSet.pas`: Dynamic assignment of `Now` during `PersistRemove`.

## 6. Acceptance Criteria
- [ ] Entities with `[DeletedAt]` are not physically deleted from the database.
- [ ] Deleting an entity with `[DeletedAt]` populates the field with the current timestamp.
- [ ] Default queries automatically exclude records where `DeletedAt IS NOT NULL`.
- [ ] `IgnoreQueryFilters` correctly brings back records with the deletion timestamp populated.
- [ ] Traditional `[SoftDelete('IsDeleted')]` continues to work with `0/1` values as before.
