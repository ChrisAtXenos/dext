# S38: Legacy Package Synchronization — Own Solution (tmsdev-free)

- **Status**: ✅ Completed
- **Author**: Cesar Romero & Antigravity
- **Created**: 2026-06-17
- **Last Updated**: 2026-06-17

---

## 1. Goal

Replace the dependency on the TMS `tmsdev` third-party utility with a **self-contained PowerShell script** that correctly generates and maintains Delphi package files (`.dpk`, `.dproj`, `DextFramework.groupproj`) for all legacy Delphi versions supported by the Dext Framework, from XE2 through Delphi 12.

---

## 2. Background & Problem Analysis

### 2.1 Directory Structure

The repository organizes packages by Delphi version at the same depth relative to the repository root:

```
DextRepository/
├── Packages/
│   ├── d13/        ← source of truth (always the most recent Delphi version; currently Delphi 13 Athens)
│   ├── d12/        ← Delphi 12 Athens
│   ├── d11/        ← Delphi 11 Alexandria
│   ├── dsydney/    ← Delphi 10.4 Sydney
│   ├── drio/       ← Delphi 10.3 Rio
│   ├── dtokyo/     ← Delphi 10.2 Tokyo
│   ├── dberlin/    ← Delphi 10.1 Berlin
│   ├── dseattle/   ← Delphi 10 Seattle
│   ├── dxe8/       ← Delphi XE8
│   ├── dxe7/       ← Delphi XE7
│   ├── dxe6/       ← Delphi XE6
│   ├── dxe5/       ← Delphi XE5
│   ├── dxe4/       ← Delphi XE4
│   ├── dxe3/       ← Delphi XE3
│   └── dxe2/       ← Delphi XE2
├── Sources/        ← source units
├── External/       ← third-party sources (DelphiAST, etc.)
└── Output/         ← compiled output
```

**Key insight**: Because all version folders are at the same depth (`Packages/<version>/`), the relative paths from any package file to `Sources/`, `External/`, or `Output/` are **always identical**:
- `..\..\Sources\...` (2 levels up to repo root)
- `..\..\External\...` (2 levels up to repo root)
- `..\..\Output\...` (2 levels up to repo root)

### 2.2 Why `tmsdev` Was Abandoned

The `tmsdev` tool presented the following unacceptable behaviors:

1. **Corrupts source unit paths in `.dpk` files**: adds an extra `..` segment, changing `'..\..\External\...'` to `'..\..\..\External\...'`, which causes fatal compilation errors.

2. **Resets output paths in `.dproj` files**: overwrites the correct `..\..\Output\$(ProductVersion)\$(Platform)\$(Config)` with a default `.\$(Platform)\$(Config)`.

3. **Corrupts `DextFramework.groupproj`**: strips the `.Core` suffix from project names (e.g. `Dext.Core.dproj` → `Dext.dproj`) causing "project not found" errors in the IDE.

4. **Not a public tool**: creates a non-negotiable external dependency with no availability guarantees.

5. **Cannot handle legacy variable substitution**: does not substitute `$(ProductVersion)` or `$(Auto)` (DllSuffix) for versions that do not support these MSBuild variables.

---

## 3. Version Metadata Table

The following table defines the version-specific values that must be hardcoded in `.dproj` files for Delphi versions **prior to Delphi 10.4 Sydney** (where `$(ProductVersion)` and `$(Auto)` are not available):

| Folder      | Delphi Version              | ProductVersion | PackageVersion | LibSuffix (DllSuffix) | Conditional |
|-------------|-----------------------------|---------------|----------------|----------------------|-------------|
| `d13`       | Delphi 13 Athens (13.0)     | 24.0          | 300            | `$(Auto)` ✅         | VER370      |
| `d12`       | Delphi 12 Athens (12.0)     | 23.0          | 290            | `$(Auto)` ✅         | VER360      |
| `d11`       | Delphi 11 Alexandria (11.0) | 22.0          | 280            | `$(Auto)` ✅         | VER350      |
| `dsydney`   | Delphi 10.4 Sydney (10.4)   | 21.0          | 270            | `$(Auto)` ✅         | VER340      |
| `drio`      | Delphi 10.3 Rio (10.3)      | 20.0          | 260            | `260`                | VER330      |
| `dtokyo`    | Delphi 10.2 Tokyo (10.2)    | 19.0          | 250            | `250`                | VER320      |
| `dberlin`   | Delphi 10.1 Berlin (10.1)   | 18.0          | 240            | `240`                | VER310      |
| `dseattle`  | Delphi 10 Seattle (10.0)    | 17.0          | 230            | `230`                | VER300      |
| `dxe8`      | Delphi XE8                  | 16.0          | 220            | `220`                | VER290      |
| `dxe7`      | Delphi XE7                  | 15.0          | 210            | `210`                | VER280      |
| `dxe6`      | Delphi XE6                  | 14.0          | 200            | `200`                | VER270      |
| `dxe5`      | Delphi XE5                  | 12.0          | 190            | `190`                | VER260      |
| `dxe4`      | Delphi XE4                  | 11.0          | 180            | `180`                | VER250      |
| `dxe3`      | Delphi XE3                  | 10.0          | 170            | `170`                | VER240      |
| `dxe2`      | Delphi XE2                  | 9.0           | 160            | `160`                | VER230      |

> **Note on `$(Auto)` availability**: `{$LIBSUFFIX AUTO}` and `$(Auto)` for `DllSuffix` in `.dproj` are supported from Delphi 10.4 Sydney onwards (`d13`, `d12`, `d11`, `dsydney`). Versions before that require the numeric `PackageVersion` value as a literal string.

> **Note on `$(ProductVersion)` availability**: `$(ProductVersion)` in MSBuild output paths is supported from Delphi Sydney (10.4) onwards. For older versions, the output path must use the hardcoded `ProductVersion` value.

---

## 4. Synchronization Rules

### Rule 1: `.dpk` files — Copy verbatim from the most recent version folder

The `.dpk` (Delphi package source) files are **copied identically** from the most recent version folder (currently `Packages/d13`) to each target version folder. No path modifications are needed because:

- All version folders are at the same depth relative to the repository root.
- The `contains` unit paths (e.g. `'..\..\External\...'`, `'..\..\Sources\...'`) are valid from any `Packages/<version>/` folder.
- The `requires` section lists package names only (no paths), which are resolved by the IDE from library paths.

**⚠️ Exception**: The `{$LIBSUFFIX AUTO}` directive inside `.dpk` files for versions prior to `dsydney` (drio and older). These versions do not support `{$LIBSUFFIX AUTO}`. The `.dpk` files must use the numeric suffix (e.g. `{$LIBSUFFIX '260'}` for Rio).

### Rule 2: `.dproj` files — Copy from the most recent version with targeted substitutions

The `.dproj` (MSBuild project) files are **copied from `d13`** and adapted per version with the following substitutions:

#### 2a. Output paths — All versions use the same fixed relative path:
```
..\..\Output\<ProductVersion>\$(Platform)\$(Config)
```

- For `d13`, `d12`, `d11`, `dsydney`: MSBuild variable `$(ProductVersion)` is used (native support).
- For `drio` through `dxe2`: `$(ProductVersion)` is **substituted** with the hardcoded value (e.g. `20.0` for Rio).

Affected XML tags in the Base `<PropertyGroup>`:
- `<DCC_DcuOutput>`
- `<DCC_DcpOutput>`
- `<DCC_BplOutput>`
- `<DCC_ExeOutput>`
- `<DCC_BpiOutput>`
- `<DCC_HppOutput>`
- `<DCC_ObjOutput>`
- `<BRCC_OutputDir>`

#### 2b. DllSuffix — Replaced for pre-Sydney versions:
```xml
<!-- d13/d12/d11/dsydney (keep as-is): -->
<DllSuffix>$(Auto)</DllSuffix>

<!-- drio through dxe2 (replace with numeric value): -->
<DllSuffix>260</DllSuffix>  <!-- example for drio -->
```

#### 2c. Modern platform sections — Kept as-is

The `.dproj` sections for modern platforms (Android, iOS, macOS, Linux, Win64x) are **kept as-is** in all legacy versions. These sections are ignored by older compilers that do not recognize the platform conditions. This approach avoids complex selective removal while being harmless to the build.

### Rule 3: `DextFramework.groupproj` — Copy verbatim from the most recent version

The `DextFramework.groupproj` file is **copied identically** from the most recent version folder (currently `Packages/d13`) to each target version folder. It already uses relative paths to `.dproj` files without version-specific prefixes (e.g. `Dext.Core.dproj`, not `Packages\d13\Dext.Core.dproj`), so it is valid from any `Packages/<version>/` location.

### Rule 4: `.res` resource files — Copy verbatim from the most recent version

Binary resource files (`.res`) are **copied identically** from the most recent version folder. These are version-agnostic.

### Rule 5: No other files are generated or modified

Only the four file types above are processed. No `.dof`, `.cfg`, `.identcache`, or `.backup` files are generated.

---

## 5. Script Architecture

### File: `Scripts/sync-legacy-packages.ps1`

The script must be self-contained (no external tool dependencies) and organized in the following phases:

#### Phase 1 — Define version metadata map
A static hashtable/array mapping each target folder to its version-specific values:
- `Folder` name (e.g. `d12`)
- `ProductVersion` (e.g. `23.0`)
- `PackageVersion` (e.g. `290`)
- `UseAutoSuffix` (boolean: true for Sydney+, false for older)

#### Phase 2 — Validate source (most recent version folder)
- Detect the most recent version folder automatically by finding the highest `delphi<N>+` entry in `tmsbuild.yaml` (currently `Packages/d13`).
- Verify that this folder exists and contains `.dpk`, `.dproj`, `.res` and `DextFramework.groupproj` files.
- Abort with a clear error message if validation fails.

#### Phase 3 — Clean target folders
- Delete all existing files in each target version folder (if it exists).
- Create the folder if it does not exist.

#### Phase 4 — Copy and adapt files per version
For each target version:

1. **Copy `.dpk` files verbatim** (then apply LibSuffix fix if `UseAutoSuffix = false`).
2. **Copy and adapt `.dproj` files** (apply output path substitution and DllSuffix substitution as per Rules 2a and 2b).
3. **Copy `DextFramework.groupproj` verbatim**.
4. **Copy `.res` files verbatim**.

#### Phase 5 — Report
Print a summary of all files copied/adapted per version folder.

---

## 6. Validation Plan

### 6.1 File content checks (automated)

After running the script, verify the following in the generated files:

- **`.dpk` contains**: all unit paths start with `'..\..\` (exactly 2 levels up — no 3-level paths).
- **`.dproj` outputs**: all `DCC_DcuOutput`, `DCC_DcpOutput`, `DCC_BplOutput` tags contain `..\..\Output\`.
- **`.dproj` DllSuffix**: for `drio` through `dxe2`, `<DllSuffix>` must not contain `$(Auto)`.
- **`DextFramework.groupproj`**: contains `Dext.Core.dproj` (not `Dext.dproj`).
- **All target folders** exist and contain the expected files.

### 6.2 Build verification (manual, by Wagner)

The customer (Wagner) will validate by building the generated packages in the corresponding Delphi IDE version and confirming no fatal errors.

Expected test matrix:
- `dxe2`: Delphi XE2 — compile `Dext.Core`
- `d12`: Delphi 12 Athens — compile `Dext.Core`
- At least one intermediate version (e.g. `drio`) — compile `Dext.Core`

**Results (2026-06-17)**:
- `dsydney` (10.4): ✅ Build OK
- `d12` (12.2 Athens): ✅ Build OK
- `d13` (13 Athens): ✅ Build OK
- TMS Smart Setup (parallel multi-version build): 🔄 In progress

---

## 7. Proposed Changes

### [MODIFY] [sync-legacy-packages.ps1](file:///C:/dev/Dext/DextRepository/Scripts/sync-legacy-packages.ps1)
Full rewrite to remove `tmsdev` dependency and implement the self-contained synchronization logic described above. The source folder is resolved dynamically as the most recent version folder (currently `d13`), not hardcoded.

### [NEW] (none)
No new files are required. The script is self-contained.

### [DELETE] scratch files
The `scratch/restructure_and_sync.ps1` scratch file (used during exploration) should be removed after the new script is validated.

---

## 8. Open Questions

> **Q1**: Should `{$LIBSUFFIX AUTO}` inside `.dpk` files be replaced with numeric values for pre-Sydney versions, or is it acceptable to leave it as-is and let the compiler ignore it?
> - **To confirm with Wagner** during build testing.

> **Q2**: The `DextSidecar.dpk` and `DextTool.dpk` files appear in `tmsdev`-generated folders but do **not** exist in `d13`. Should these be generated for legacy versions?
> - Likely not needed for legacy builds — confirm before including.

---

## 9. References

- [Delphi Version Conditional Table](https://docwiki.embarcadero.com/RADStudio/en/Compiler_Versions)
- [Packages Synchronization Guide](file:///C:/dev/Dext/DextRepository/Docs/Packages_Synchronization.md)
- [tmsbuild.yaml](file:///C:/dev/Dext/DextRepository/tmsbuild.yaml) — package folder mapping
- [Packages/d13](file:///C:/dev/Dext/DextRepository/Packages/d13) — source of truth
