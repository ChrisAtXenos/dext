# S31 — Fluent Validation API & Smart Property Integration

This architectural specification details the design and integration of the **Fluent Validation API** in Dext, offering a type-safe, fluent alternative to attribute-based validation.

---

## 1. Context & Motivation

Dext originally relied on attribute-based validation (e.g., `[Required]`, `[StringLength(3, 50)]`) on model properties. While declarative, attribute-based validation introduces two limitations:
1. **Magic Strings**: Custom rules or property lookups are based on string literals.
2. **Conditional Validation**: Attributes are static and cannot easily support runtime conditional checks (e.g. validate a field only if another field has a specific value).

The **Fluent Validation API** solves these issues by introducing a programmatic, builder-based validator definition. In addition, it integrates with `Prop<T>` Smart Properties to completely eliminate magic strings and automatically hooks into the web model binding pipeline to validate incoming HTTP requests.

---

## 2. Architectural Design

The validation engine consists of three key architectural blocks:

### 1. Fluent Builder Record (`TValidationRuleBuilder<T>`)
To prevent heap allocations and memory leaks when building rules, the builder is implemented as a **Delphi record** rather than a class. It wraps a rule instance and returns `Self` on builder methods, enabling fluent chaining:
```pascal
RuleFor('Name').Required.Length(3, 50);
```

### 2. Smart Property Integration
By matching the properties from a Prototype ghost entity, validation rules are strongly typed:
```pascal
var m := Prototype.Entity<TTestModel>;
RuleFor(m.Name).Required.Length(3, 50);
```
To avoid implicit casting issues (where the compiler converts a smart property `Prop<string>` to `string` and invokes the string overload with an empty value), the `TAbstractValidator<T>` implements specific overloads for all common smart property types (`Prop<string>`, `Prop<Integer>`, `Prop<Boolean>`, etc.).

### 3. Localized Pattern Registry (`TValidationPatterns`)
A localized patterns registry maps key-locale combinations to regex expressions (e.g. Pt-BR and En-US phone/zipcodes):
```pascal
RuleFor(m.Phone).MatchesPattern('Phone', 'pt-BR');
```

---

## 3. Web Model Binding Integration

The web layer automatically triggers validation during action parameters resolution in [Dext.Web.HandlerInvoker.pas](file:///C:/dev/Dext/DextRepository/Sources/Web/Dext.Web.HandlerInvoker.pas):
1. When a model parameter is bound, the invoker queries the Dependency Injection (DI) container for a registered validator matching `IValidator<ModelType>`.
2. If found, the validator executes. If validation fails, it raises a `TWebValidationException`, producing a standard JSON/HTMX error payload (e.g., HTTP 400 Bad Request) automatically.

---

*Dext Specifications — S31 Fluent Validation API | June 2026*
