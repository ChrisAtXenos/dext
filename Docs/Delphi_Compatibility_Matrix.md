# Dext Framework: Delphi Compatibility Matrix

This document defines the supported Delphi versions for the Dext Framework and maps specific features to the required compiler and RTL versions.

## 1. Version Support Overview

| Version Tier | Delphi Versions | Support Level | Notes |
| :--- | :--- | :--- | :--- |
| **Tier 1 (Main)** | 10.4 Sydney to 12 Athens | Full Support | Primary development and testing environment. Supports inline variables and managed records. |
| **Tier 2 (Legacy)** | 10.1 Berlin to 10.3 Rio | Supported | No inline variables. Uses `Dext.Threading.Sync` for backported locking. |
| **Tier 3 (Extended/Minimal)** | XE2 to 10 Seattle | Supported | Requires Indy fallback (`TDextIndyHttpEngine` automatically resolved for versions < XE8) for outbound HTTP. |

---

## 2. Feature vs. Version Mapping

| Feature | Min Delphi Version | Required For | Fallback / Workaround |
| :--- | :--- | :--- | :--- |
| **Generics & Anon Methods** | 2009 | Collections, DI, Reflection | None (Hard Requirement) |
| **Attributes & RTTI** | 2010 | DI, ORM, Web API | None (Hard Requirement) |
| **TInterlocked / Atomic** | XE | Collections, Sync | Manual ASM (Not implemented) |
| **PPL (Parallel Library)** | XE7 | `Dext.Threading.Async` | Simplified Task Runner |
| **JSON `TryGetValue<T>`** | XE7 | `Dext.Json` | Manual parsing fallback |
| **TNetHTTPClient** | XE8 | `Dext.Net.RestClient` | Indy (`TDextIndyHttpEngine` automatically resolved) |
| **System.Hash** | XE8 | Core Utils | Indy / Custom |
| **`[Weak]` Attribute** | 10.1 Berlin | ORM (Lazy Loading) | Manual reference management / disabled under legacy |
| **Inline Variables** | 10.3 Rio | Code Aesthetics | Refactored to scoped vars |
| **TLightweightMREW** | 10.4 Sydney | High-Perf Sync | `TSpinLock` / `TMREWSync` |
| **Managed Records** | 10.4 Sydney | Performance Ops | Traditional Records |

---

## 3. Technical Rationale for XE2 Baseline

Dext can be compiled on legacy versions from **Delphi XE2** and higher thanks to the following architectural changes:

1.  **Indy HTTP Engine Fallback**: The REST Client and OAuth providers abstract connection management via `IDextHttpEngine`. Older versions below XE8 automatically compile with `TDextIndyHttpEngine` based on Indy (`TIdHTTP`), removing the hard requirement for `System.Net.HttpClient`.
2.  **Reference Counting Safety ([Weak])**: The ORM's Lazy Loading mechanism falls back gracefully if `[Weak]` attributes are not fully supported by the compiler, allowing execution without memory cycles under older platforms.
3.  **Backported Concurrency**: Memory structures and lock contention managers automatically fall back to standard `TSpinLock` or `TMREWSync` under Sydney (10.4) versions.

---

## 4. How to Support Older Versions (XE2 - 10 Seattle)

To compile Dext on legacy versions, the package synchronization script maps package references and handles directives:

-   `DEXT_FORCE_INDY`: Can be defined manually to force Indy usage on newer IDEs, otherwise resolved automatically for compiler versions < 29.0 (XE8).
-   `DEXT_LEGACY_SYNC`: Resolved automatically to fall back to older thread-safety structures.
-   `DEXT_NO_WEAK`: Disables `[Weak]` attribute usage on compilers that lack stable support.

---

*Last Updated: June 2026*

