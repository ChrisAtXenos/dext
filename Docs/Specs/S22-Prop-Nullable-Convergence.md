# S22: Prop<T> and Nullable<T> Convergence

**Status**: Finalized
**Authors**: Cesar Romero, Antigravity
**Date**: 2026-05-14
**Related Issues**: #PropNullableInterop

## 1. Abstract
This specification defines the strategy for resolving type incompatibility and null-state loss between `Prop<T>` (Smart Properties) and `Nullable<T>` (Value Type Wrapper) within the Dext Framework. It documents the evolution from internal storage refactoring to an opt-in composition model.

## 2. The Problem
Currently, `Prop<T>` and `Nullable<T>` operate as parallel structures with limited interoperability. Specifically:
- **Type Incompatibility**: `Nullable<Prop<T>> := Nullable<T>` fails to compile due to Delphi's limitations on chaining implicit operators for nested generic types.
- **Null State Loss**: Assigning a `Nullable<T>` to a `Prop<T>` results in `FValue := Default(T)`, losing the distinction between `0/Empty` and `Null` in runtime mode.

## 3. Investigated Approaches

### Approach A: Internal Nullable Storage
Refactoring `Prop<T>` to use `Nullable<T>` as its primary storage field (`FValue: Nullable<T>`).

#### Pros:
- Native null support for all properties.
- Fixes the "null loss" issue automatically.
- Simplifies operator implementation.

#### Cons:
- **Memory Overhead**: Adds 4-8 bytes (plus alignment) to every property. Since 95% of database columns are often `NOT NULL`, this is considered significant over-engineering for the core `Prop<T>` type.
- **Complexity**: Forces `Nullable` logic into every property access.

### Approach B: Opt-in Composition (`Prop<Nullable<T>>`)
Moving to a model where nullability is handled by wrapping the type `T` as a `Nullable<T>` inside the `Prop<T>`.

#### Pros:
- **Zero Overhead**: Standard `Prop<Integer>` remains lightweight (12-16 bytes).
- **Opt-in**: Only pay the memory/logic price for fields explicitly declared as nullable.
- **Clean Semantic**: `Prop<Nullable<T>>` is literally a "Smart Property of a Nullable Value".

#### Cons:
- Requires `Prop<T>` to be "Nullable-aware" via RTTI/TypeInfo to provide shortcuts (e.g., `IsNull` check in runtime mode).
- Potential clunky syntax like `Prop.Value.Value` (to be solved via implicit operators).

## 4. Implementation Strategy (Draft)

### 4.1. Smart Property Awareness
`Prop<T>` should implement internal logic to detect if `T` is an instantiation of `Nullable<T>`.

```pascal
function Prop<T>.IsNull: BooleanExpression;
begin
  if IsQueryMode then
    Result := BooleanExpression.FromQuery(...)
  else if IsTypeNullable(TypeInfo(T)) then
    Result := BooleanExpression.FromRuntime(GetNullableHasValue(FValue))
  else
    Result := BooleanExpression.FromRuntime(False);
end;
```

### 4.2. Implicit Operator Refinement
Refine existing operators to ensure that if `T` matches the source type (e.g., assigning `Nullable<Integer>` to `Prop<Nullable<Integer>>`), the assignment is direct and lossless.

## 5. GitHub Discussion Points
- Should `Prop<T>` be nullable by default?
- Performance impact of `TypeInfo` checks vs. explicit specialized records.
- User preference: `Nullable<Prop<T>>` (Old mindset) vs. `Prop<Nullable<T>>` (New mindset).

## 6. Conclusion
The framework will favor **Approach B (Composition)** to maintain the performance-first philosophy of Dext, providing a robust path for nullability without penalizing standard properties.
