# Soft Delete

Mark records as deleted without physically removing them from the database.

## Enabling Soft Delete

Apply the `[SoftDelete]` attribute to your entity class. By default, it uses a Boolean flag where `True` means deleted.

```pascal
type
  [Table('tasks')]
  [SoftDelete('IsDeleted')] // Maps to the property below
  TTask = class
  private
    FIsDeleted: Boolean;
  public
    property IsDeleted: Boolean read FIsDeleted write FIsDeleted;
  end;
```

### Custom Values

You can also use integers or enums for states.

```pascal
[SoftDelete('Status', 99, 0)] // Deleted = 99, Active = 0
TUser = class
  property Status: Integer read FStatus write FStatus;
end;
```

## Deletion Timestamp (Audit)

If you need to track **when** a record was deleted, use the `[DeletedAt]` attribute. The presence of this attribute on a property automatically enables Soft Delete for the entire entity.

```pascal
type
  [Table('orders')]
  TOrder = class
  private
    FDeletedAt: DateTimeType; // Ideal: Smart Property (Dext unit)
  public
    [DeletedAt]
    property DeletedAt: DateTimeType read FDeletedAt write FDeletedAt;
  end;
```

> [!TIP]
> Ideally, use **Smart Properties** (`DateTimeType`), which provide native null support and type safety in queries. If you are not using Smart Properties, you must use `Nullable<TDateTime>` to ensure the field starts as `NULL`.

In this mode:
*   **Filter**: Dext automatically applies `WHERE DeletedAt IS NULL` for active records.
*   **Action**: When calling `.Remove()`, the field is automatically populated with the current timestamp (`Now`).

### Hybrid Mode (Performance + Audit)

For high-performance scenarios, you can combine both attributes. Use `[SoftDelete]` at the class level for fast filtering (boolean) and `[DeletedAt]` on a property for auditing:

```pascal
[SoftDelete('IsDeleted')] 
TOrder = class
  property IsDeleted: Boolean read FIsDeleted write FIsDeleted;

  [DeletedAt] 
  property DeletedAt: DateTimeType read FDeletedAt write FDeletedAt;
end;
```

> [!IMPORTANT]
> In hybrid mode, Dext prioritizes the boolean flag for generating SQL filters for performance reasons, but ensures that both fields are updated during deletion.

## Operations

### Deleting

The standard `.Remove()` method will now perform an `UPDATE` instead of a `DELETE`.

```pascal
Db.Tasks.Remove(Task);
Db.SaveChanges; 
// UPDATE tasks SET is_deleted = 1 WHERE id = ...
```

### Physical Delete (Hard Delete)

To bypass the soft delete rule and permanently remove a record:

```pascal
Db.Tasks.HardDelete(Task);
// DELETE FROM tasks WHERE id = ...
```

### Restoring

To "undelete" a record:

```pascal
Db.Tasks.Restore(Task);
// UPDATE tasks SET is_deleted = 0 WHERE id = ...
```

## Querying

By default, soft-deleted records are **hidden** from all queries.

```pascal
// Returns only active records
var Active := Db.Tasks.ToList;
```

### Including Deleted Records

To see everything (e.g., in an admin panel):

```pascal
var All := Db.Tasks.IgnoreQueryFilters.ToList;
```

### Trash Bin (Only Deleted)

To fetch only records that were deleted:

```pascal
var Trash := Db.Tasks.OnlyDeleted.ToList;
```

## Important Notes

- **Cascading**: Soft Delete does **not** automatically cascade to child relationships. You must handle child deletions manually or via database triggers.
- **IdentityMap**: Soft-deleted entities are removed from the memory cache after `SaveChanges` to maintain a consistent state.

---

[← Transactions](transactions.md) | [Next: Stored Procedures →](stored-procedures.md)
