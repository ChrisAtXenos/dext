{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{                                                                           }
{           Copyright (C) 2025 Cesar Romero & Dext Contributors             }
{                                                                           }
{           Licensed under the Apache License, Version 2.0 (the "License"); }
{           you may not use this file except in compliance with the License.}
{           You may obtain a copy of the License at                         }
{                                                                           }
{               http://www.apache.org/licenses/LICENSE-2.0                  }
{                                                                           }
{           Unless required by applicable law or agreed to in writing,      }
{           software distributed under the License is distributed on an     }
{           "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,    }
{           either express or implied. See the License for the specific     }
{           language governing permissions and limitations under the        }
{           License.                                                        }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Author:  Cesar Romero                                                    }
{  Created: 2025-12-08                                                      }
{                                                                           }
{***************************************************************************}
unit Dext.Utils;

interface

uses
{$IFDEF MSWINDOWS}
  WinApi.Windows,
  WinApi.TlHelp32,
{$ENDIF}
  Dext.Core.Writers;

/// <summary>Pauses the console execution unless the 'no-wait' switch is present.</summary>
function ConsolePause: Boolean;
/// <summary>Writes a message to the debug output and the console.</summary>
procedure DebugLog(const AMessage: string);
/// <summary>Sets the console output character set (UTF-8 by default).</summary>
procedure SetConsoleCharSet(CharSet: Cardinal = 65001);

/// <summary>
///   Attaches the application to the console of the parent process (CMD/Powershell)
///   or allocates a new console if none is available.
/// </summary>
procedure SafeAttachConsole;

/// <summary>Writes a message to a diagnostic log file for framework debugging.</summary>
procedure DiagnosticLog(const AMessage: string);
/// <summary>Returns the name of the parent process (e.g. 'bds.exe', 'cmd.exe').</summary>
function GetParentProcessName: string;

/// <summary>Hides the console window immediately.</summary>
procedure HideConsole;
/// <summary>Hides the console window only if it was automatically created for this process.</summary>
procedure HideConsoleIfAutocreated;

/// <summary>
///   Checks if console output is available. Returns False for GUI applications
///   (VCL/FMX) that don't have a console attached.
/// </summary>
function IsConsoleAvailable: Boolean;

/// <summary>
///   Writes a message to console only if console is available.
///   Silently does nothing in GUI applications to prevent I/O error 105.
/// </summary>
procedure SafeWriteLn(const AMessage: string); overload;
procedure SafeWriteLn; overload;
procedure SafeWrite(const AMessage: string);

/// <summary>
///   Initializes the standard framework output to route to the specified writer.
///   If nil, it chooses the best available writer (Console, Debugger, or Null).
/// </summary>
procedure InitializeDextWriter(ADextWriter:IDextWriter);

var
  DefaultConsoleCharset: Cardinal = 65001;

implementation

uses
  System.SysUtils,
  System.SyncObjs;

var
  ConsoleAvailable: Boolean = False;
  ConsoleChecked: Boolean = False;
  CurrentDextWriter : IDextWriter;

function IsConsoleAvailable: Boolean;
{$IFDEF MSWINDOWS}
var
  Handle: THandle;
{$ENDIF}
begin
  if not ConsoleChecked then
  begin
    ConsoleChecked := True;
    {$IFDEF MSWINDOWS}
      Handle := GetStdHandle(STD_OUTPUT_HANDLE);
      ConsoleAvailable := (Handle <> 0) and (Handle <> INVALID_HANDLE_VALUE);
    {$ELSE}
      {$IFDEF CONSOLE}
      ConsoleAvailable := True;
      {$ELSE}
      ConsoleAvailable := System.IsConsole;
      {$ENDIF}
    {$ENDIF}
  end;
  Result := ConsoleAvailable;
end;

var
  ConsoleLock: TCriticalSection;

procedure InternalWriteToConsole(const Message: string);
{$IFDEF MSWINDOWS}
var
  Handle: THandle;
  Written: DWORD;
  Mode: DWORD;
  Utf8: TBytes;
{$ENDIF}
begin
  if Message = '' then Exit;
  
  ConsoleLock.Enter;
  try
    {$IFDEF MSWINDOWS}
    Handle := GetStdHandle(STD_OUTPUT_HANDLE);
    if (Handle <> 0) and (Handle <> INVALID_HANDLE_VALUE) then
    begin
      // Check if it's a real console or a redirected pipe/file
      if GetConsoleMode(Handle, Mode) then
      begin
        // It's a real console - Use Unicode Native Writing (handles emojis perfectly)
        WriteConsoleW(Handle, PWideChar(Message), Length(Message), Written, nil);
      end
      else
      begin
        // It's a pipe/file - Use Binary UTF-8 Writing
        Utf8 := TEncoding.UTF8.GetBytes(Message);
        if Length(Utf8) > 0 then
          WriteFile(Handle, Utf8[0], Length(Utf8), Written, nil);
      end;
    end;
    {$ELSE}
    Write(Message);
    {$ENDIF}
  finally
    ConsoleLock.Leave;
  end;
end;

procedure SafeWriteLn(const AMessage: string);
begin
  if IsConsoleAvailable then
    InternalWriteToConsole(AMessage + sLineBreak)
  else if Assigned(CurrentDextWriter) then
    CurrentDextWriter.SafeWriteln(AMessage);
end;

procedure SafeWriteLn;
begin
  if IsConsoleAvailable then
    InternalWriteToConsole(sLineBreak)
  else if Assigned(CurrentDextWriter) then
    CurrentDextWriter.SafeWriteln('');
end;

procedure SafeWrite(const AMessage: string);
begin
  if IsConsoleAvailable then
    InternalWriteToConsole(AMessage)
  else if Assigned(CurrentDextWriter) then
    CurrentDextWriter.SafeWrite(AMessage);
end;

function ConsolePause: Boolean;
begin
  Result := FindCmdLineSwitch('no-wait', ['-', '\'], True);
  if not Result then
  begin
    {$WARN SYMBOL_PLATFORM OFF}
    if IsConsoleAvailable {$IFDEF MSWINDOWS}and (DebugHook <> 0){$ENDIF} then
    begin
      SafeWrite(sLineBreak + 'Press <ENTER> to continue...');
      System.ReadLn;
    end;
    {$WARN SYMBOL_PLATFORM ON}
  end;
end;

procedure DebugLog(const AMessage: string);
begin
  SafeWriteLn(AMessage);
end;

procedure SetConsoleCharSet(CharSet: Cardinal);
{$IFDEF MSWINDOWS}
var
  Handle: THandle;
  Mode: DWORD;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  // Setup both Output and Input to specified Charset (UTF-8 = 65001)
  SetConsoleOutputCP(CharSet);
  SetConsoleCP(CharSet);
  
  // Enable Virtual Terminal Processing (for emojis and colors in modern terminals)
  Handle := GetStdHandle(STD_OUTPUT_HANDLE);
  if (Handle <> 0) and (Handle <> INVALID_HANDLE_VALUE) then
  begin
    if GetConsoleMode(Handle, Mode) then
      SetConsoleMode(Handle, Mode or $0004); // ENABLE_VIRTUAL_TERMINAL_PROCESSING
  end;
  {$ENDIF}
end;

procedure SafeAttachConsole;
begin
  {$IFDEF MSWINDOWS}
  if not IsConsoleAvailable then
  begin
    DiagnosticLog('SafeAttachConsole: Console not available, attempting attach/alloc. Parent: ' + GetParentProcessName);
    // ATTACH_PARENT_PROCESS = -1
    // If we can't attach to parent, we MUST allocate a new one (important for Explorer/F9)
    if AttachConsole(DWORD(-1)) or (AllocConsole) then
    begin
       // 1. Tell Delphi RTL we are in console mode now
       System.IsConsole := True;

      ConsoleChecked := False; // Force re-check
      ConsoleAvailable := True; 
      
      SetConsoleCharSet(DefaultConsoleCharset);
      
      // If we are overriding the writer, only do it if it was TNullWriter or TConsoleWriter
      if (CurrentDextWriter is TNullWriter) then
         InitializeDextWriter(nil); 
         
      DiagnosticLog('SafeAttachConsole: SUCCESS. Handles rebound and CharSet set.');
    end
    else
      DiagnosticLog('SafeAttachConsole: FAILED to attach or allocate.');
  end;
  {$ENDIF}
end;

procedure DiagnosticLog(const AMessage: string);
var
  LogFile: string;
  F: TextFile;
begin
  try
    LogFile := ChangeFileExt(ParamStr(0), '.diag.log');
    AssignFile(F, LogFile);
    if FileExists(LogFile) then
      Append(F)
    else
      Rewrite(F);
    try
      Writeln(F, FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' [' + GetParentProcessName + '] ' + AMessage);
    finally
      CloseFile(F);
    end;
  except
    // Silent fail for diagnostics
  end;
end;

function GetParentProcessName: string;
{$IFDEF MSWINDOWS}
var
  Handle: THandle;
  ProcessEntry: TProcessEntry32;
  ParentID: DWORD;
  MyID: DWORD;
begin
  Result := 'unknown';
  MyID := GetCurrentProcessId;
  ParentID := 0;
  
  Handle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Handle <> INVALID_HANDLE_VALUE then
  begin
    try
      ProcessEntry.dwSize := SizeOf(TProcessEntry32);
      if Process32First(Handle, ProcessEntry) then
      begin
        repeat
          if ProcessEntry.th32ProcessID = MyID then
          begin
            ParentID := ProcessEntry.th32ParentProcessID;
            Break;
          end;
        until not Process32Next(Handle, ProcessEntry);
      end;
      
      if ParentID <> 0 then
      begin
        if Process32First(Handle, ProcessEntry) then
        begin
          repeat
            if ProcessEntry.th32ProcessID = ParentID then
            begin
              Result := LowerCase(ProcessEntry.szExeFile);
              Break;
            end;
          until not Process32Next(Handle, ProcessEntry);
        end;
      end;
    finally
      CloseHandle(Handle);
    end;
  end;
end;
{$ELSE}
begin
  Result := 'non-windows';
end;
{$ENDIF}

procedure HideConsole;
{$IFDEF MSWINDOWS}
var
  ConsoleWnd: HWND;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  ConsoleWnd := GetConsoleWindow;
  if ConsoleWnd <> 0 then
    ShowWindow(ConsoleWnd, SW_HIDE);
  {$ENDIF}
end;

procedure HideConsoleIfAutocreated;
{$IFDEF MSWINDOWS}
var
  ConsoleProcessList: array[0..1] of DWORD;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if GetConsoleProcessList(@ConsoleProcessList[0], 2) = 1 then
    HideConsole;
  {$ENDIF}
end;

procedure InitializeDextWriter(ADextWriter:IDextWriter);
begin
  if Assigned(ADextWriter) then
    CurrentDextWriter := ADextWriter
  else
  if IsConsoleAvailable then
    CurrentDextWriter := TConsoleWriter.create
  else
    CurrentDextWriter := TNullWriter.create;
end;

initialization
  ConsoleLock := TCriticalSection.Create;
  SetConsoleCharSet(DefaultConsoleCharset);
  InitializeDextWriter(Nil);

finalization
  ConsoleLock.Free;

end.

