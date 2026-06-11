# Dext Framework Installation Guide

This guide covers the installation of the Dext Framework. You can choose between the **Automated Setup** (recommended via TMS Smart Setup) or the **Manual Setup**.

## 1. Automated Setup (TMS Smart Setup)

If you use **TMS Smart Setup**, the installation, compilation, and IDE configuration of the framework is fully automated.

Simply run the following command in your terminal at the root of the cloned repository:
```bash
tms install cesarliws.dext
```
The Smart Setup tool will read the `tmsbuild.yaml` manifest, build all packages for all supported platforms, and automatically configure all Library Paths, Browsing Paths, environment variables, and BPL directory path overrides in your Delphi IDE.

---

## 2. Manual Setup

If you prefer to compile and configure the framework manually, follow the steps below.

### 2.1. Customizing the Framework (Dext.inc)

Before compiling the Dext Framework, you can customize its behavior and active database drivers/integrations by editing the `Sources\Common\Dext.inc` file. This file centralizes all global compilation directives:

#### A. Database Drivers (Dext.Entity)
By default, Dext is configured with only the **SQLite** driver enabled, ensuring full compatibility with the **Delphi Community Edition**. If you use Delphi Enterprise/Architect and want to enable other database drivers, uncomment the corresponding lines:
```pascal
{$DEFINE DEXT_ENABLE_DB_SQLITE}      // Enabled by default
{.$DEFINE DEXT_ENABLE_DB_POSTGRES}   // Remove the dot (.) to enable
{.$DEFINE DEXT_ENABLE_DB_MYSQL}
{.$DEFINE DEXT_ENABLE_DB_MSSQL}
{.$DEFINE DEXT_ENABLE_DB_ORACLE}
{.$DEFINE DEXT_ENABLE_DB_FIREBIRD}
```
*Important:* When enabling other databases, add the `Dext.Entity.Drivers.FireDAC.Links` unit to your project (e.g., in the `.dpr` or Main Form `uses` clause) to ensure that the active drivers are correctly linked.

#### B. TestInsight Integration (`DEXT_TESTINSIGHT`)
If you use **TestInsight** to manage and execute unit tests directly inside the Delphi IDE, uncomment the following line to enable native integration:
```pascal
{.$DEFINE DEXT_TESTINSIGHT}
```
*Note: Requires `TestInsight.Client.pas` to be in your IDE's Library Path.*

#### C. Web Stencils (`DEXT_ENABLE_WEB_STENCILS`)
For projects developed in **Delphi 12.2 or higher** on Windows, Dext supports native integration with Embarcadero's **Web Stencils** template engine:
```pascal
{$IFDEF DEXT_DELPHI12_UP}
  {$IFDEF MSWINDOWS}
    {$DEFINE DEXT_ENABLE_WEB_STENCILS}
  {$ENDIF}
{$ENDIF}
```

> [!NOTE]
> **Web Stencils** support is conditional. The `Dext.Web.Core.dpk` package includes the `Dext.inc` file and conditionally declares the package dependency on Embarcadero's `inetstn` only if `DEXT_ENABLE_WEB_STENCILS` is active. On versions prior to 12.2 or other platforms, this dependency and the related code are completely disabled/ignored by the compiler transparently, without any warnings.


#### D. Component Naming Conflicts (`DEXT_USE_ENTITY_PREFIX`)
If you have other libraries installed (such as Devart EntityDAC) that use the same component names (`TEntityDataSet`, `TEntityDataProvider`), uncomment the following line to avoid IDE registration conflicts:
```pascal
{.$DEFINE DEXT_USE_ENTITY_PREFIX}
```
This registers them as **`TDextEntityDataSet`** and **`TDextEntityDataProvider`**.

---

### 2.2. Build the Project Group

Once you have adjusted `Dext.inc` to suit your needs:

1. Open the main project group in Delphi:
    - `Sources\DextFramework.groupproj`
2. In the Project Manager, right-click the root node (**ProjectGroup**) and select **Build All**.
3. Wait for the compilation of all packages to complete.

The compiled files will be automatically generated in the following folders:
- DCUs: `Output\$(ProductVersion)\$(Platform)\$(Config)`
- BPLs and DCPs: `Output\Bin\$(ProductVersion)\$(Platform)\$(Config)`

*Example for Delphi 12 Athens Win32 Debug:*
- DCUs: `Output\23.0\Win32\Debug`
- BPLs/DCPs: `Output\Bin\23.0\Win32\Debug`

> **Note:** The `Dext.inc` file resides in the `Sources\Common` folder, which is added to the Library Path so that both the framework and your applications can include and inherit it directly via search path.

---

### 2.3. Environment Variable Configuration (Recommended)

Using an environment variable simplifies your Library Paths and allows you to switch between different versions/forks of Dext easily.

1. In Delphi, go to **Tools** > **Options** > **IDE** > **Environment Variables**.
2. Under **User System Overrides**, click **New...**
3. **Variable Name**: `DEXT`
4. **Value**: The full path to the `Sources` directory inside your cloned repository.
    - *Example*: `C:\dev\Dext\DextRepository\Sources`
    - *Note*: Ensure it points to the `Sources` folder, not the root.

    ![DEXT Environment Variable](../../Images/ide-env-var.png)

---

### 2.4. Configure Library Path (DCUs & DCPs)

Add the paths to the compiled files in the Library Path of the IDE.

> [!IMPORTANT]
> The Delphi IDE **does not expand** dynamic project variables like `$(Platform)`, `$(Config)`, or `$(ProductVersion)` in global Library Path settings. Therefore, you must specify the exact paths for each configuration and Delphi version you wish to use.
>
> Common `$(ProductVersion)` values:
> - **21.0** for Delphi 10.4 Sydney
> - **22.0** for Delphi 11 Alexandria
> - **23.0** for Delphi 12 Athens

1. In Delphi, go to **Tools** > **Options** > **Language** > **Delphi** > **Library**.
2. Select your target **Platform** (e.g., Windows 32-bit).
3. In the **Library Path** field, add the following paths. Use the `$(DEXT)` variable to simplify:
    - `$(DEXT)\Common` (for the IDE to locate `Dext.inc` and the `Dext.MM` unit)
    - `$(DEXT)\..\Output\23.0\Win32\Debug` (for DCUs)
    - `$(DEXT)\..\Output\Bin\23.0\Win32\Debug` (for DCPs/BPLs)

*Note: Repeat for other platforms (e.g., Win64) or configurations (e.g., Release), adjusting the version and platform name accordingly.*

---

### 2.5. Configure Execution Path (BPLs)

Since the runtime packages (BPLs) are generated under the `Output\Bin` folder, the Delphi IDE needs to locate them when loading design-time packages (such as `Dext.EF.Design370.bpl` and `Dext.Testing.Design370.bpl`). Otherwise, you will receive a *"Specified module could not be found"* error when attempting to install the packages.

To resolve this, you must add the BPL output paths to the IDE's internal `PATH` environment variable:

1. In Delphi, go to **Tools** > **Options** > **IDE** > **Environment Variables**.
2. Under **User System Overrides**, select the **PATH** variable and click **Edit** (or click **New...** if it does not exist).
3. Append the following paths to the end of the existing value, separated by a semicolon (`;`), adjusting `C:\dev\Dext\DextRepository` to match your installation directory and `37.0` to match your compiler version:
    - For the 32-bit IDE (Delphi 11 or older):
      `;C:\dev\Dext\DextRepository\Output\Bin\37.0\Win32\Release`
    - For the 64-bit IDE (Delphi 12 or newer):
      `;C:\dev\Dext\DextRepository\Output\Bin\37.0\Win64\Release`

    *Tip*: It is recommended to add both paths to ensure compatibility with compiles and runs on both architectures.

    ![PATH Override](../../Images/ide-env-var.png)

---

### 2.5.1. Configure Memory Manager (Dext.MM)

The Dext memory manager (`Dext.MM.pas`) resides in the `Sources\Common` folder. To use it in your executable applications:

1. Ensure the `$(DEXT)\Common` folder is added to your Library Path (as shown in Step 2.4).
2. In your main application file (the `.dpr` of your executable), add `Dext.MM` as the **very first** unit in the `uses` clause.
   - *Example*:
     ```pascal
     program MyProject;

     uses
       Dext.MM, // Must always be the first unit!
       Vcl.Forms,
       ...
     ```

### 2.5.2. Optional Integrations (WebStencils and TestInsight)

For portability and automated installation compatibility, optional integration units are not statically included in the main packages of the framework:

* **Web Stencils**: The `Dext.Web.View.WebStencils.pas` unit resides in `Sources\Web` and is only compiled when the `DEXT_ENABLE_WEB_STENCILS` conditional is enabled in your `Dext.inc`.
* **TestInsight**: The `Dext.Testing.TestInsight.pas` unit resides in `Sources\Testing`. To use it in your test projects, add it directly to your test `.dpr` project's `uses` list (conditioned on `{$IFDEF TESTINSIGHT}`) and make sure the TestInsight client library is added to your IDE's library path.


---

### 2.6. Configure Browsing Path (Source Code)

Add the following paths to your **Browsing Path** (Tools > Options > Language > Delphi > Library) for your target platforms.
This allows the IDE to find the source code for debugging and "Ctrl+Click" navigation.

> [!WARNING]
> **DO NOT put these source folders in the Library Path field!**  
> If you place source folders in the Library Path, the Delphi compiler will recompile parts of Dext every time you compile your development project. This will result in different versions of `.dcu` files scattered throughout your project directories, causing hard-to-debug compilation errors (such as `F2051`).  
> **Dext should only be compiled during its installation.**

```text
$(DEXT)
$(DEXT)\AI
$(DEXT)\AI\MCP
$(DEXT)\Core
$(DEXT)\Core\Base
$(DEXT)\Core\Interception
$(DEXT)\Core\Json
$(DEXT)\Dashboard
$(DEXT)\Data
$(DEXT)\Debug
$(DEXT)\Design
$(DEXT)\Events
$(DEXT)\Hosting
$(DEXT)\Hosting\CLI
$(DEXT)\Hosting\CLI\Logger
$(DEXT)\Hosting\CLI\Tools
$(DEXT)\Hubs
$(DEXT)\Hubs\Transports
$(DEXT)\Net
$(DEXT)\Testing
$(DEXT)\UI
$(DEXT)\Web
$(DEXT)\Web\Caching
$(DEXT)\Web\Hosting
$(DEXT)\Web\Indy
$(DEXT)\Web\Middleware
$(DEXT)\Web\Mvc
$(DEXT)\..\Apps\CLI\Commands
```

> [!TIP]
> **Tip:** Adding each item manually is tedious, so you can copy the line below and paste it directly at the end of your **Browsing Path** field:
> ```text
> ;$(DEXT);$(DEXT)\AI;$(DEXT)\AI\MCP;$(DEXT)\Core;$(DEXT)\Core\Base;$(DEXT)\Core\Interception;$(DEXT)\Core\Json;$(DEXT)\Dashboard;$(DEXT)\Data;$(DEXT)\Debug;$(DEXT)\Design;$(DEXT)\Events;$(DEXT)\Hosting;$(DEXT)\Hosting\CLI;$(DEXT)\Hosting\CLI\Logger;$(DEXT)\Hosting\CLI\Tools;$(DEXT)\Hubs;$(DEXT)\Hubs\Transports;$(DEXT)\Net;$(DEXT)\Testing;$(DEXT)\UI;$(DEXT)\Web;$(DEXT)\Web\Caching;$(DEXT)\Web\Hosting;$(DEXT)\Web\Indy;$(DEXT)\Web\Middleware;$(DEXT)\Web\Mvc;$(DEXT)\..\Apps\CLI\Commands
> ```

---

### 2.7. Multi-Platform Installation (Linux, Win64, Android, iOS...)

Dext Framework supports multi-platform compilation. If you want to use Dext on platforms like Linux, Windows 64-bit, or mobile, follow these instructions:

1. **Add the Target Platform (if needed):**
   In the Delphi Project Manager, if the desired platform is not listed under **Target Platforms** for the package, right-click **Target Platforms**, select **Add Platform...**, and add your target platform.
2. **Select the Active Platform via the Toolbar:**
   To compile Dext packages for the desired platform, select the target platform in the active platform drop-down menu in Delphi's main toolbar.
3. **Build the Project Group:**
   With your desired active platform selected, right-click the root node (**ProjectGroup**) in the Project Manager and select **Build All**.
4. **Configure Paths for the New Platform:**
   Repeat the **Library Path** (Step 2.4) and **Browsing Path** (Step 2.6) configuration steps for each of the new platforms in the Delphi IDE Library Options.

---

## Troubleshooting

### F2051: Unit was compiled with a different version

**Cause:**  
This occurs when the compiler finds a mismatch between pre-compiled `.dcu` files and raw `.pas` source files, usually because the source paths (`Sources`) were incorrectly added to the global **Library Path** instead of the **Browsing Path**.

**Solution:**
1. Go to **Tools** > **Options** > **Language** > **Delphi** > **Library**.
2. Verify your **Library Path**:
    - ✅ Must contain **only** the compiled output folders (e.g., `Output\23.0\Win32\Debug` and `Output\Bin\23.0\Win32\Debug`).
    - ❌ Remove any `Sources\*` directories from the Library Path.
3. Verify your **Browsing Path**:
    - ✅ Must contain the source paths (e.g., `Sources\*` paths).
4. Clean and rebuild:
    - Delete any `.dcu` files under your application project directories.
    - Rebuild the Dext framework (`Sources\DextFramework.groupproj` > **Build All**).
    - Rebuild your application.

### Compilation fails with "File not found"

**Cause:**  
The Library Path does not contain the compiled DCU or DCP output directory, or the framework has not been built for the active target platform/configuration.

**Solution:**
1. Ensure you have built the Dext framework for the target platform and build configuration.
2. Check that your Library Path includes the compiled DCU and DCP folders:
    - `$(DEXT)\..\Output\23.0\Win32\Debug`
    - `$(DEXT)\..\Output\Bin\23.0\Win32\Debug`

---

### Quick Reference: Path Configuration Summary

| Path Type         | What to Add                                    | Purpose                                  |
|-------------------|------------------------------------------------|------------------------------------------|
| **Library Path**  | `Output\23.0\Win32\Debug`                      | Locate compiled `.dcu` files             |
| **Library Path**  | `Output\Bin\23.0\Win32\Debug`                  | Locate compiled `.dcp` files             |
| **System PATH**   | `Output\Bin\23.0\Win32\Debug`                  | Locate runtime `.bpl` packages at runtime|
| **Browsing Path** | All `Sources\*` folders                        | Code navigation and debugging            |

---

[← Back to Getting Started](README.md) | [Next: Hello World →](hello-world.md)
