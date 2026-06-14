# Issue #117 Notes: FluentQuery `.Join(...)` Patterns in `Orm.EntityDemo`

## Issue Summary

Issue: `Documentation / Example request: FluentQuery .Join(...) patterns in Orm.EntityDemo #117`

Requester asks for practical examples showing how to use join overloads in `TFluentQuery<T>`, especially:

- SQL-style joins (`Join` with table/alias/type + condition)
- Optional LINQ-style generic join overload (`Join<TInner, TKey, TResult>(...)`)

Requested placement:

- Example/test under `Examples/03-Data/Orm.EntityDemo` (new unit or extending advanced query tests)
- Short README note under advanced queries linking to the demo behavior

Main motivation:

- Reduce friction and confusion between SQL join overloads vs in-memory generic join behavior, especially across API changes.

## Current Analysis and Considerations

1. The issue is valid and high value for users.
- It is a documentation/examples gap, not necessarily a core ORM bug.
- It directly impacts onboarding and reduces issue noise.

2. The scope is clear and actionable.
- Add focused demos in `Orm.EntityDemo`.
- Add concise README guidance.

3. Most important teaching point:
- Clearly separate:
  - SQL join chain (translated to SQL in provider)
  - Generic/LINQ-style `Join<TInner,...>` (materializes and correlates in memory)

4. About the proposed fork change (`Join(..., ACondition: string)` parser):
- Good ergonomics for simple cases.
- Should be considered secondary to #117 (docs/examples first).
- String parser is necessarily limited (e.g., only simple `"left = right"` patterns).
- If accepted, it should be documented as a simple predicate helper.

## Suggested Implementation Plan

1. Add a focused SQL join demo test unit (recommended: `EntityDemo.Tests.Join.pas`):
- Use minimal existing relational entities + seeded data.
- Show a readable chain with:
  - `AsNoTracking`
  - `Join('table', 'alias', <condition>, <join type>)`
  - `Where`
  - `OrderBy`
  - `ToList`
- Add a one-line comment explaining qualified columns/predicates.

2. Add a short generic join demo test:
- Demonstrate `Join<TInner, TKey, TResult>(...)`.
- Add explicit warning comment:
  - This path materializes outer and inner sequences and correlates in memory.
  - It is not a drop-in replacement for SQL join at scale.

3. Update `Examples/03-Data/Orm.EntityDemo/README.md`:
- Add 2 short bullets under advanced queries:
  - SQL Join demo test
  - Generic in-memory Join demo test

4. Optional follow-up (separate PR/issue):
- Introduce/keep a simple string condition overload parser for SQL join helper.
- Document strict format and limitations.

## Final Recommendation

For Issue #117, prioritize documentation and examples first:

- Deliver copy-pasteable SQL join and generic join demos in `Orm.EntityDemo`.
- Explicitly call out execution model differences (SQL vs in-memory).
- Keep API sugar (`string` join condition parser) as optional and separate to avoid conflating concerns.

This should fully address the user request and materially reduce downstream confusion.

