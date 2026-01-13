# Dext Framework Documentation Guidelines

This document defines the standards for documenting Dext Framework source code using XML documentation comments compatible with PasDoc.

## Comment Formats
    
### Semantic XML Format (Preferred)

Use `/// <summary>` tags. This format is parsed by `DextASTParser` and displayed in the generated HTML reference.

```pascal
/// <summary>
///   Creates and returns a new service provider instance.
///   The service provider resolves dependencies using the configured services.
/// </summary>
function BuildServiceProvider: IServiceProvider;
```

### Legacy PasDoc Format (Deprecated)

Support for `{** ... *}` comments is deprecated as we have migrated to Semantic XML comments.

---

## XML Tags Reference
    
| Tag | Usage | Example |
|-----|-------|---------|
| `<summary>` | Brief description of the symbol | `/// <summary>Creates a new instance</summary>` |
| `<param name="Name">` | Parameter description | `/// <param name="AIndex">The index to access</param>` |
| `<returns>` | Return value description | `/// <returns>True if successful</returns>` |
| `<exception cref="EType">` | Exception that may be thrown | `/// <exception cref="EInvalidOp">If not ready</exception>` |
| `<see cref="Target"/>` | Cross-reference | `/// <see cref="TMyClass"/>` |
| `<remarks>` | Detailed notes/usage info | `/// <remarks>This method is thread-safe</remarks>` |
| `<example>` | Code example | `/// <example>var x := GetValue();</example>` |

---

## Documentation Levels

### 1. Unit Header
Every unit should have a header comment:

```pascal
/// <summary>
///   HTTP Request handling for Dext Web Framework.
///   This unit provides the core HTTP request abstraction including
///   headers, query parameters, form data, and file uploads.
/// </summary>
/// <see cref="Dext.Web.Response"/>
unit Dext.Web.Request;
```

### 2. Class/Interface Documentation

```pascal
/// <summary>
///   Represents a fluent query builder for database operations.
///   TFluentQuery provides a LINQ-style API for building type-safe
///   database queries with support for filtering, sorting, and pagination.
/// </summary>
/// <example>
///   var users := Context.Set<TUser>
///     .Where(u.Age > 18)
///     .OrderBy('Name')
///     .Take(10)
///     .ToList;
/// </example>
TFluentQuery<T: class> = class(TInterfacedObject, IQueryable<T>)
```

### 3. Method Documentation

```pascal
/// <summary>
///   Adds a WHERE clause to filter results.
/// </summary>
/// <param name="APredicate">Smart property expression for filtering</param>
/// <returns>The query instance for method chaining</returns>
/// <example>
///   query.Where(u.Status = 'Active')
/// </example>
function Where(const APredicate: IExpression): TFluentQuery<T>;
```

### 4. Property Documentation

```pascal
/// <summary>
///   Gets or sets the connection timeout in milliseconds.
///   Default value is 30000 (30 seconds).
/// </summary>
property Timeout: Integer read FTimeout write FTimeout;
```

---

## Priority Order for Documentation

Focus documentation efforts in this order:

1. **Public Interfaces** (`IServiceProvider`, `IHttpContext`, etc.)
2. **Public Classes** (`TFluentQuery<T>`, `TDextApplication`, etc.)
3. **Public Methods** (especially those in APIs)
4. **Public Properties**
5. **Protected Members** (for inheritance documentation)

---

## Best Practices

### ✅ Do

- Start with a verb for methods: "Creates", "Returns", "Validates"
- Be concise but complete
- Document all parameters and return values
- Include code examples for complex APIs
- Use `<see cref="..."/>` to cross-reference related types

### ❌ Don't

- Don't state the obvious: `// Increments counter by 1` for `Inc(Counter)`
- Don't duplicate the method signature in prose
- Don't leave empty `/// <summary>` blocks
- Don't use HTML tags (use Markdown instead)

---

## Generating Documentation
    
Run the full generation pipeline using the following commands:

```powershell
# 1. Generate XML files from Delphi source
./Tools/DextASTParser/DextASTParser.exe ./Docs/API/xml

# 2. Render HTML documentation from XML
cd Tools/DextDoc
node index.js ../../Docs/API/xml ../../Docs/API/html
```
    
The output will be placed in `Docs/API/html`.

---

## Verification Checklist

Before submitting code, verify:
    
- [ ] All public types have `/// <summary>` documentation
- [ ] Complex methods have `<param>` and `<returns>` tags
- [ ] Exception-throwing methods have `<exception>` tags
- [ ] Run `DextDoc` generator to verify no parsing errors
