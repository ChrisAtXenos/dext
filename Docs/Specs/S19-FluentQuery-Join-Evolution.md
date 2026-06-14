# S19: FluentQuery Join Evolution (Post V1 Final)

## Status
- **Completed** (Implementation Phase A fully executed)
- **Current release phase**: post-V1 Final / Evolution
- **Execution window**: June 2026 (Completed)

## Objective
Define a safe and high-performance evolution path for `TFluentQuery` join capabilities, preserving ecosystem consistency and Dext principles:
- High performance
- Minimal/zero allocations in hot paths
- Backward compatibility
- Predictable behavior across ORM, specs, SQL generation, docs, and examples

This spec is intentionally separated from Issue #117 delivery.  
**Issue #117 remains the immediate focus for V1 RC1** (examples + docs).

---

## Context
Current join surface mixes two distinct execution models:
1. **SQL Join** via `Join(table, alias, joinType, condition)` (provider-translated SQL)
2. **Generic Join** via `Join<TInner, TKey, TResult>` (in-memory correlation)

Issue #117 highlighted discoverability and usage confusion between these two models.

---

## Non-Goals (for RC1)
The following are **not** to be shipped in RC1:
- Large API redesign of `TFluentQuery`
- Breaking changes in existing Join signatures
- SQL parser expansion beyond simple, deterministic cases
- New behavior that risks ORM performance regressions before V1 Final

---

## Scope (Post V1 Final)

## 1) API Clarity and Discoverability
### Goals
- Make SQL Join and in-memory Join behavior explicit in API and docs.
- Reduce ambiguity in naming and overload intent.

### Candidate actions
- Keep existing APIs source-compatible.
- Add explicit aliases (example: `JoinInMemory`) while preserving legacy `Join<TInner,...>`.
- Add XML docs warning for in-memory materialization behavior.

### Proposed DSL Evolution (Primary Path)
Current SQL join shape:
```pascal
.Join('order_items', 'oi', 'products.id = oi.product_id', jtInner)
```

Proposed fluent/type-safe shape:
```pascal
var p := Prototype.Entity<TProduct>;
var oi := Prototype.Entity<TOrderItem>; // default alias auto-generated

// 1. Explicit condition Join
Context.Entities<TProduct>
  .AsNoTracking
  .JoinInner<TOrderItem>(p.Id = oi.ProductId)
  .Where(TProductType.Price > 10)
  .ToList;

// 2. Implicit relationship-based Join (auto-resolves ON condition from metadata)
Context.Entities<TProduct>
  .JoinInner<TOrderItem> // Automatically uses mapping: Product.Id = OrderItem.ProductId
  .ToList;

// 3. Cross Join (no condition)
Context.Entities<TProduct>
  .JoinCross<TOrderItem>
  .ToList;
```

Optional alias override:
```pascal
Context.Entities<TProduct>
  .JoinInner<TOrderItem>('oi', p.Id = oi.ProductId);
```

#### Design intent
- Prefer expressive DSL over multi-string/multi-parameter signatures.
- Keep join condition strongly typed through expression tree.
- Eliminate fragile string parsing from preferred path.
- Preserve low-level API for compatibility/interoperability.
- Automatically resolve ON conditions using Dext relationship metadata mapping (ForeignKey/Navigation attributes).

#### Candidate signatures (additive)
```pascal
// Automatic ON condition resolution via metadata
function JoinInner<TInner: class>: TFluentQuery<T>; overload;
function JoinLeft<TInner: class>: TFluentQuery<T>; overload;
function JoinRight<TInner: class>: TFluentQuery<T>; overload;
function JoinFull<TInner: class>: TFluentQuery<T>; overload;

// Explicit ON conditions
function JoinInner<TInner: class>(const AOn: IExpression): TFluentQuery<T>; overload;
function JoinLeft<TInner: class>(const AOn: IExpression): TFluentQuery<T>; overload;
function JoinRight<TInner: class>(const AOn: IExpression): TFluentQuery<T>; overload;
function JoinFull<TInner: class>(const AOn: IExpression): TFluentQuery<T>; overload;

// Alias overrides + Automatic ON resolution
function JoinInner<TInner: class>(const AAlias: string): TFluentQuery<T>; overload;
function JoinLeft<TInner: class>(const AAlias: string): TFluentQuery<T>; overload;
function JoinRight<TInner: class>(const AAlias: string): TFluentQuery<T>; overload;
function JoinFull<TInner: class>(const AAlias: string): TFluentQuery<T>; overload;

// Alias overrides + Explicit ON conditions
function JoinInner<TInner: class>(const AAlias: string; const AOn: IExpression): TFluentQuery<T>; overload;
function JoinLeft<TInner: class>(const AAlias: string; const AOn: IExpression): TFluentQuery<T>; overload;
function JoinRight<TInner: class>(const AAlias: string; const AOn: IExpression): TFluentQuery<T>; overload;
function JoinFull<TInner: class>(const AAlias: string; const AOn: IExpression): TFluentQuery<T>; overload;

// Cross Joins (No ON condition)
function JoinCross<TInner: class>: TFluentQuery<T>; overload;
function JoinCross<TInner: class>(const AAlias: string): TFluentQuery<T>; overload;
```

#### Alias policy
- Default alias must be deterministic and collision-safe.
- Suggested default strategy:
  1. start from type/table short name (`OrderItem` -> `oi`)
  2. if collision, suffix increment (`oi2`, `oi3`)
- Explicit alias always wins.
- Alias allocation must be cached in query build context to avoid repeated work.

## 2) String Join Condition Helper
### Goals
- Keep ergonomic overload for simple `"left = right"` scenarios.
- Enforce strict and predictable parsing rules.

### Candidate actions
- Formalize grammar support for v1 helper:
  - exactly one equality predicate
  - no boolean chaining
  - no function parsing
- Clear exception messages for invalid formats.
- Document that complex ON expressions must use `IExpression`.

### Positioning after S19 DSL
- Keep `Join(table, alias, condition, type)` and `Join(..., condition: string, ...)` as **legacy/low-level path**.
- Mark strongly-typed `JoinInner/Left/Right` as **preferred path** in docs/examples.
- Deprecation policy (non-breaking):
  - Post-Final + 1 cycle: mark legacy path as "advanced/interop"
  - Post-Final + 2+ cycles: evaluate soft deprecation warnings (no hard removal)

## 3) SQL Join Projection Ergonomics
### Goals
- Improve practical usability for joined result shapes without compromising performance.

### Candidate actions
- Evaluate typed projection helpers for SQL joins.
- Avoid runtime reflection-heavy projection in hot paths.

### Candidate extension
Evaluate additive projection patterns that keep SQL-side execution:
```pascal
.SelectJoin<TResult>(...)
```
Constraints:
- no per-row reflection in materialization loop
- generated projector cached by query signature/type tuple

## 4) Diagnostics and Operability
### Goals
- Improve explainability/debugging of query translation.

### Candidate actions
- Evaluate `ToQueryString()`-style API for generated SQL + params.
- Query tagging (`TagWith`) for observability/tracing.

### Join-specific diagnostics
- Include resolved join metadata in debug trace:
  - join type
  - table and alias
  - ON expression SQL
- Optional strict mode for ambiguity detection before execution when possible.

---

## Ecosystem Impact Assessment
Any post-Final change must be validated across:
- `Sources/Data/Dext.Entity.Query.pas`
- `Sources/Core/Dext.Specifications.*`
- SQL generator (`Dext.Specifications.SQL.Generator`)
- DbContext/DbSet query execution pipeline
- Examples (`Orm.EntityDemo`, others)
- Dext Book EN/PT-BR
- Unit/integration/performance test suites

### Additional impact surface for DSL join evolution
- Prototype system (`Dext.Specifications.Types` and related builders)
- Expression translators that consume prototype-origin expressions
- Documentation examples currently using raw `Join('table',...)`

### Compatibility rules
1. No breaking signature removals in first post-Final iteration.
2. Legacy behavior preserved unless clearly versioned/deprecated.
3. New APIs must be additive and documented.

---

## Performance and Allocation Constraints
All proposed changes must satisfy:
- No extra allocations per-row in materialization paths.
- No reflection churn in tight loops (cache or pre-bind where possible).
- SQL Join pipeline overhead must remain effectively constant-time per query build step.
- In-memory Join path must document and preserve current complexity expectations.

### Required benchmarks (minimum)
1. Join query build overhead (before/after)
2. SQL generation overhead for joined specs
3. In-memory Join throughput for medium/large sets
4. Allocation snapshots (baseline vs proposed)

Use existing benchmark infra from S18.

### Additional zero-allocation guardrails for DSL joins
1. No transient string allocations in join condition hot path when using typed DSL.
2. Alias resolution should allocate once per query build at most.
3. Expression normalization for ON clause must use cached translators.
4. SQL qualification logic for joined base columns must remain O(n columns) with no hidden quadratic behavior.

---

## Risk Register
1. **API confusion risk**: same name, different execution model  
Mitigation: explicit aliases + docs + examples

2. **Regression risk** in SQL translation  
Mitigation: golden tests for generated SQL and parameterization

3. **Performance risk** from convenience APIs  
Mitigation: micro-benchmarks + allocation guards

4. **Ecosystem drift risk** (docs/examples/code mismatch)  
Mitigation: synchronized update checklist in PR template

---

## Delivery Phases (Post V1 Final)
1. **Phase A (Safe Additive)**
- Documentation and naming clarity
- Alias APIs (if approved)
- Non-breaking helper APIs
- Add typed `JoinInner/Left/Right` overload set (with and without explicit alias)
- Keep legacy join API fully functional

2. **Phase B (Diagnostics)**
- Query explain/inspect API
- Optional tagging support
- Join-specific debug payloads (resolved aliases/ON SQL)

3. **Phase C (Ergonomic Projection)**
- Typed SQL join projection patterns
- Performance validation and hardening
- Evaluate migration hints/tooling to promote typed DSL adoption

---

## Migration Strategy (No Breaking Changes)
1. Add typed join DSL as first-class documented approach.
2. Keep legacy API intact and covered by tests.
3. Update examples progressively:
   - RC docs: show both, emphasize behavior differences
   - Post-Final docs: put typed DSL first, legacy in advanced section
4. Add analyzer-style docs checklist to PR templates:
   - if new join example added, include SQL vs in-memory note
   - include ambiguity-safe SQL assertions where relevant

---

## Acceptance Criteria (for S19 implementation cycle)
1. All Join modes are explicitly documented with execution model.
2. No breaking changes to existing join consumers.
3. Benchmarks show no unacceptable degradation (threshold from S18 policy).
4. EN/PT-BR docs and examples remain synchronized.
5. Unit + integration + example suite pass in CI.

---

## Immediate Priority Note
While this spec defines the post-Final roadmap, the **current active priority in RC1** is:
- Deliver Issue #117 with focused examples and documentation.
