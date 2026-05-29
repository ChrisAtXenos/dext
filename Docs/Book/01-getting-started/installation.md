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

### 3. Build

1. Open `Sources\DextFramework.groupproj`.
2. Right-click **ProjectGroup** > **Build All**.

### 4. Database Drivers Configuration (Optional)

By default, Dext is configured with only the **SQLite** driver enabled. This ensures full compatibility with **Delphi Community Edition**.

If you are using Delphi Enterprise/Architect and want to use other databases (PostgreSQL, SQL Server, Oracle, MySQL, etc.), follow these steps:

1. Open the file `Sources\Dext.inc`.
2. Uncomment the directives for the databases you want to use:

    ```pascal
    {$DEFINE DEXT_ENABLE_DB_SQLITE}      // Active by default
    {.$DEFINE DEXT_ENABLE_DB_POSTGRES}   // Remove the dot (.) to enable
    {.$DEFINE DEXT_ENABLE_DB_MYSQL}
    {.$DEFINE DEXT_ENABLE_DB_MSSQL}
    {.$DEFINE DEXT_ENABLE_DB_ORACLE}
    {.$DEFINE DEXT_ENABLE_DB_FIREBIRD}
    {.$DEFINE DEXT_ENABLE_DB_IB}         // InterBase
    {.$DEFINE DEXT_ENABLE_DB_ODBC}
    ```

3. **Rebuild** the framework (`DextFramework.groupproj` > **Build All**) to apply the changes.
4. **Important:** Add the unit `Dext.Entity.Drivers.FireDAC.Links` to your project (e.g., in your DPR or Main Form `uses` clause). This ensures that the enabled drivers are correctly linked to your application.

> **Note:** The `Dext.inc` file is automatically copied to the output folder (`Output`) during the Build process, ensuring that your applications use the same directive definitions as the compiled framework.

### 5. Component Naming Conflicts (e.g., Devart EntityDAC)

If you have other libraries installed (like Devart EntityDAC) that use the same component names (`TEntityDataSet`, `TEntityDataProvider`), you will encounter an IDE conflict during installation.

To resolve this, Dext provides a naming prefix option:

1. Open `Sources\Dext.inc`.
2. Uncomment the directive: `{$DEFINE DEXT_USE_ENTITY_PREFIX}`.
3. Rebuild the framework.

This will register the components as **`TDextEntityDataSet`** and **`TDextEntityDataProvider`**, allowing them to coexist with other libraries in the same IDE.

---

## Troubleshooting

- **"File not found" during Manual Build**: Ensure all subdirectories in `Sources` are covered by your Library Path or the `$(DEXT)` expansion.

---

[← Back to Getting Started](README.md) | [Next: Hello World →](hello-world.md)
