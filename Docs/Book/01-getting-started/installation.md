# Dext Framework Installation Guide

This guide covers the installation of the Dext Framework. You can choose between the **Automated Setup** (recommended) or the **Manual Setup**.

## Prerequisites

- Delphi 11 Alexandria or newer.
- Git (to clone the repository).

---

## Installation Steps

### 1. Environment Variable Configuration (Best Practice)

Using an environment variable simplifies your Library Paths and allows you to switch between different versions/forks of Dext easily.

1. In Delphi, go to **Tools** > **Options** > **IDE** > **Environment Variables**.
2. Click **New...**
3. **Variable Name**: `DEXT`
4. **Value**: The full path to the `Sources` directory inside your cloned repository.
    - *Example*: `C:\dev\Dext\DextRepository\Sources`
    - *Note*: Ensure it points to the `Sources` folder, not the root, to match the paths below.

    ![DEXT Environment Variable](../../Images/ide-env-var.png)

### 2. Configure Library Path (DCUs)

Add the paths to the output folder (`Output`) for your target platforms (Win32, Win64).

> [!IMPORTANT]
> The Delphi IDE **does not expand** dynamic project variables like `$(Platform)` or `$(Config)` in global Library Path settings. Therefore, you must specify the exact paths for each configuration you wish to use.

1. In Delphi, go to **Tools** > **Options** > **Language** > **Delphi** > **Library**.
2. Select your target **Platform**.
3. In the **Library Path** field, add the path to where the `.dcu` files were generated. Use the `$(DEXT)` variable to simplify the path:
    - `$(DEXT)\..\Output\37.0_win32_debug` (for Debug)
    - `$(DEXT)\..\Output\37.0_win32_release` (for Release)

*Note: Repeat for other platforms (e.g., Win64), adjusting the folder name based on what was generated in Step 1.*

### 3. Configure Browsing Path

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

### 3.1 Installing Dext for Other Platforms (Linux, Win64, Android, iOS...)

Dext Framework supports multi-platform compilation. If you want to use Dext on platforms like Linux, Windows 64-bit, or mobile, follow these instructions:

1. **Add the Target Platform (if needed):**
   In the Delphi Project Manager, if the desired platform is not listed under **Target Platforms** for the package, right-click **Target Platforms**, select **Add Platform...**, and add your target platform.

2. **Select the Active Platform via the Toolbar:**
   To compile Dext packages for the desired platform, you do not need to do it package by package. In Delphi's main toolbar, select the target platform in the active platform drop-down menu (next to the Build/Run button). This will apply the active platform selection to all packages in the Project Group that support it.

3. **Build the Project Group:**
   With your desired active platform selected (e.g., `Linux 64-bit` or `Windows 64-bit`), right-click the root node (**ProjectGroup**) in the Project Manager and select **Build All**.

4. **Configure Paths for the New Platform:**
   Remember to repeat the **Library Path** (Step 2) and **Browsing Path** (Step 3) configuration steps for each of the new platforms, ensuring you select the respective platform in the Delphi IDE Library Options drop-down.

### 3.1 Customizing the Framework (Dext.inc)

Before compiling the Dext Framework, you can customize its behavior and active dependencies by editing the `Sources\Dext.inc` file. This file centralizes all global compilation directives:

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
#### D. Component Naming Conflicts (`DEXT_USE_ENTITY_PREFIX`)
If you have other libraries installed (such as Devart EntityDAC) that use the same component names (`TEntityDataSet`, `TEntityDataProvider`), uncomment the following line to avoid IDE registration conflicts:
```pascal
{.$DEFINE DEXT_USE_ENTITY_PREFIX}
```
This registers them as **`TDextEntityDataSet`** and **`TDextEntityDataProvider`**.

---

### 4. Build

Once you have adjusted `Dext.inc` to suit your needs:

1. Open `Sources\DextFramework.groupproj` in Delphi.
2. In the Project Manager, right-click the root node (**ProjectGroup**) and select **Build All**.
3. Wait for the compilation of all packages to complete.

The compiled files will be automatically generated in:
* `Output\$(Platform)\$(Config)`
* *Example:* `Output\Win32\Debug`

> **Note:** The customized `Dext.inc` file is automatically copied to the output folder (`Output`) during the build process, ensuring that your applications inherit the exact same framework settings.

---

## Troubleshooting

- **"File not found" during Manual Build**: Ensure all subdirectories in `Sources` are covered by your Library Path or the `$(DEXT)` expansion.

---

[← Back to Getting Started](README.md) | [Next: Hello World →](hello-world.md)
