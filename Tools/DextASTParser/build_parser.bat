@echo off
set ERRORLEVEL=0
set DELPHI_BIN=C:\Program Files (x86)\Embarcadero\Studio\23.0\bin
set DELPHI_LIB=C:\Program Files (x86)\Embarcadero\Studio\23.0\lib\win32\release

echo Building DextASTParser...
"%DELPHI_BIN%\dcc32.exe" DextASTParser.dpr -U"C:\dev\Dext\Libs\DelphiAST-sglienke\Source\SimpleParser;C:\dev\Dext\Libs\DelphiAST-sglienke\Source;%DELPHI_LIB%" -I"C:\dev\Dext\Libs\DelphiAST-sglienke\Source\SimpleParser" -NS"System;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win" > build_parser.log 2>&1

if %ERRORLEVEL% NEQ 0 (
  echo Build Failed!
  exit /b 1
)

echo Build Success!
