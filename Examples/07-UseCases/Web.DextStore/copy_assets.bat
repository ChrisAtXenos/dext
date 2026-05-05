@echo off
:: This script copies the assets (wwwroot, appsettings*.json) to the output directory
:: It is intended to be called as a Post-Build event in the Delphi project

set PROJECT_DIR=%~dp0
set TARGET_DIR=%~1

if "%TARGET_DIR%"=="" (
    set TARGET_DIR=%PROJECT_DIR%..\..\Output\
)

echo Deploying assets from %PROJECT_DIR% to %TARGET_DIR%...

:: Copy wwwroot if it exists
if exist "%PROJECT_DIR%wwwroot" (
    echo Copying wwwroot...
    if not exist "%TARGET_DIR%wwwroot" mkdir "%TARGET_DIR%wwwroot"
    xcopy "%PROJECT_DIR%wwwroot\*" "%TARGET_DIR%wwwroot\" /S /E /Y /D
)

:: Copy appsettings*.json if they exist
if exist "%PROJECT_DIR%appsettings*.json" (
    echo Copying appsettings...
    copy /Y "%PROJECT_DIR%appsettings*.json" "%TARGET_DIR%"
)

echo Done.
