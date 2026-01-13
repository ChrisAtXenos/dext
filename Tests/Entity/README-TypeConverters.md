# Type Converters Tests

## Overview

This test suite validates the Type Converter system for database-specific type mappings.

## Running Tests

```bash
# Compile and run
dcc32 TestTypeConverters.dpr
TestTypeConverters.exe
```

## Test Coverage

### ✅ GUID Converter
- CanConvert detection
- ToDatabase conversion (TGUID → String)
- FromDatabase conversion (String → TGUID)
- SQL Cast generation for all dialects:
  - PostgreSQL: `:param::uuid`
  - SQL Server: `CAST(:param AS UNIQUEIDENTIFIER)`
  - MySQL/SQLite: `:param`

### ✅ Enum Converter
- Integer mode (default)
- String mode (`[EnumAsString]`)
- Bidirectional conversion
- Error handling for invalid values

### ✅ JSON Converter
- Object serialization to JSON
- JSONB vs JSON mode
- SQL Cast for PostgreSQL

### ✅ Array Converter
- PostgreSQL native array format
- JSON fallback for other databases

### ✅ Type Converter Registry
- Built-in converter registration
- Custom converter registration
- Per-type overrides
- Converter lookup

## Expected Output

```
📊 Dext Type Converters Test Suite
===================================

► Testing GUID Converter...
  Original GUID: {830C3664-027D-4B87-8C98-76FB0AAC08EC}
  Converted:     {830C3664-027D-4B87-8C98-76FB0AAC08EC}
  PostgreSQL cast: :id::uuid
  SQL Server cast: CAST(:id AS UNIQUEIDENTIFIER)
  MySQL cast:      :id
✓ GUID Converter tests passed

► Testing Enum Converter (Integer mode)...
  Enum value: urAdmin
  As integer: 2
✓ Enum Converter (Integer) tests passed

► Testing Enum Converter (String mode)...
  Enum value: urSuperAdmin
  As string:  urSuperAdmin
✓ Enum Converter (String) tests passed

► Testing Type Converter Registry...
  ✓ Got GUID converter
  ✓ Registered and retrieved custom converter
  ✓ Cleared custom converters
✓ Type Converter Registry tests passed

► Testing JSON Converter...
  Object serialized to JSON:
  {"Name":"Test","Value":123}
  PostgreSQL cast: :metadata::jsonb
✓ JSON Converter tests passed

► Testing Array Converter...
  Array as PostgreSQL literal:
  ARRAY['delphi','orm','framework']
✓ Array Converter tests passed

✅ All tests passed!
```

## See Also

- [ORM Type System Guide](../../Docs/orm-type-system-guide.md)
- [Type System Enhancement Design](../../Docs/Roadmap/orm-type-system-enhancement.md)
