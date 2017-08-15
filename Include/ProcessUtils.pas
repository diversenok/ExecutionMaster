{   ExecutionMaster component.
    Copyright (C) 2017 diversenok

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>    }

unit ProcessUtils;
{$WARN SYMBOL_PLATFORM OFF}

interface

uses Winapi.Windows;

{ winternl.h }

{$MINENUMSIZE 4}

type
  TProcessInformationClass = (
    ProcessBasicInformation = 0,
    ProcessDebugObjectHandle = 30
  );

  NTSTATUS = LongWord;

  TProcessBasicInformation = record
    ExitStatus: NTSTATUS;
    PebBaseAddress: Pointer;
    AffinityMask: NativeUInt;
    BasePriority: LongInt;
    UniqueProcessId: THandle;
    InheritedFromUniqueProcessId: THandle;
  end;

function NtRemoveProcessDebug(ProcessHandle: THandle;
  DebugObjectHandle: THandle): NTSTATUS; stdcall;
  external 'ntdll.dll' name 'NtRemoveProcessDebug';

function NtQueryInformationProcess(ProcessHandle: THandle;
  ProcessInformationClass: TProcessInformationClass;
  ProcessInformation: Pointer; ProcessInformationLength: Cardinal;
  var ReturnLength: Cardinal): NTSTATUS; stdcall;
  external 'ntdll.dll' name 'NtQueryInformationProcess';

{ WinBase.h }

const
  /// <summary>
  ///  <c>TStartupInfoEx</c> flag for <c>CreateProcess</c>.
  /// </summary>
  EXTENDED_STARTUPINFO_PRESENT = $80000;

  // Replaces parent process
  PROC_THREAD_ATTRIBUTE_PARENT_PROCESS = $20000;

type
  PProcThreadAttributeEntry = Pointer;

  /// <remarks>
  ///  Be sure to set <c>cb</c> member of <c>TStartupInfo</c> structure to
  ///  <c>SizeOf(TStartupInfoEx)</c> and to enable
  ///  <c>EXTENDED_STARTUPINFO_PRESENT</c> flag for <c>CreateProcess</c>.
  /// </remarks>
  TStartupInfoEx = record
    StartupInfo: TStartupInfo;
    lpAttributeList: PProcThreadAttributeEntry;
  end;

  /// <summary>
  ///  Initializes the specified list of attributes for process and thread
  ///  creation.
  /// </summary>
function InitializeProcThreadAttributeList(lpAttributeList
  : PProcThreadAttributeEntry; dwAttributeCount: DWORD; dwFlags: DWORD;
  var lpSize: SIZE_T): BOOL; stdcall;
  external kernel32 name 'InitializeProcThreadAttributeList';

/// <summary>
///  Updates the specified attribute in a list of attributes for process and
///  thread creation.
/// </summary>
function UpdateProcThreadAttribute(lpAttributeList: PProcThreadAttributeEntry;
  dwFlags: DWORD; Attribute: DWORD_PTR; lpValue: PVOID; cbSize: SIZE_T;
  lpPreviousValue: PVOID = nil; lpReturnSize: PSIZE_T = nil): BOOL; stdcall;
  external kernel32 name 'UpdateProcThreadAttribute';

/// <summary>
///  Deletes the specified list of attributes for process and thread creation.
/// </summary>
procedure DeleteProcThreadAttributeList(lpAttributeList
  : PProcThreadAttributeEntry);
  external kernel32 name 'DeleteProcThreadAttributeList';

/// <summary> Extended version of <c>CreateProcessW</c>. </summary>
/// <remarks>
///  Always include <c>EXTENDED_STARTUPINFO_PRESENT</c> flag.
/// </remarks>
function CreateProcessExW(lpApplicationName: LPCWSTR; lpCommandLine: LPWSTR;
  lpProcessAttributes: PSecurityAttributes;
  lpThreadAttributes: PSecurityAttributes; bInheritHandles: BOOL;
  dwCreationFlags: DWORD; lpEnvironment: Pointer; lpCurrentDirectory: LPCWSTR;
  const lpStartupInfo: TStartupInfoEx;
  var lpProcessInformation: TProcessInformation): BOOL; stdcall;
  external kernelbase name 'CreateProcessW';

/// <summary> Extended version of CreateProcessAsUserW. </summary>
/// <remarks>
///  Always include <c>EXTENDED_STARTUPINFO_PRESENT</c> flag.
/// </remarks>
function CreateProcessAsUserExW(hToken: THandle; lpApplicationName: LPCWSTR;
  lpCommandLine: LPWSTR; lpProcessAttributes: PSecurityAttributes;
  lpThreadAttributes: PSecurityAttributes; bInheritHandles: BOOL;
  dwCreationFlags: DWORD; lpEnvironment: Pointer; lpCurrentDirectory: LPCWSTR;
  const lpStartupInfo: TStartupInfoEx;
  var lpProcessInformation: TProcessInformation): BOOL; stdcall;
  external advapi32 name 'CreateProcessAsUserW';

{ User defined }

const
  // Let caller think process failed to start if user choose "No"
  STATUS_DLL_INIT_FAILED = $C0000142;

  /// <summary>
  ///  <c>CreateProcess</c> should be replaced with <c>ShellExecuteEx</c>
  ///  with "runas" verb.
  /// </summary>
  ERROR_ELEVATION_REQUIRED = 740;

  /// <summary>
  ///  Checks if current process runs in zero session.
  /// </summary>
  /// <remarks>
  ///  Returns <c>False</c> if failed to obtain information.
  /// </remarks>
function IsZeroSession: Boolean;

/// <summary>
///  Checks if current process runs with elevated token.
/// </summary>
/// <remarks>
///  Returns <c>False</c> if failed to obtain information.
/// </remarks>
function IsElevated: Boolean;

/// <summary> Returns PID of parent process or zero on fail. </summary>
function GetParentPID(ProcessHandle: THandle): Cardinal;

/// <summary>
///  Returns PID of process that initiated our chain execution or zero on fail.
/// </summary>
function InitiatorPID: Cardinal;

/// <summary>
///  Uses <c>CreateProcess</c> with debugging flags to bypass
///  Image-File-Execution-Options and waits for new process.
/// </summary>
/// <returns>
///  <para> On <c>ERROR_ELEVATION_REQUIRED</c> returns <c>True</c> </para>
///  <para> On other error returns <c>False</c> </para>
///  <para> On success exits current process with the same exit code </para>
/// </returns>
function RunUnderDebuggerW(const Cmd: WideString; hToken: THandle = 0): Boolean;

/// <summary>
///  Runs application at highest privileges and waits for it.
/// </summary>
/// <returns>
///  <para>
///   On fail exits current process with <c>STATUS_DLL_INIT_FAILED</c> code
///  </para>
///  <para> On success exits with the same code </para>
/// </returns>
procedure RunElevatedW(const Cmd: WideString);

/// <summary>
///  Checks if parent process is informing us that it has used
///  <c>ShellExecuteEx</c> because of lack of privileges.
/// </summary>
function ParentRequestedElevation: Boolean;

implementation

uses Winapi.ShellAPI;

const
  /// <summary> See <see cref="RunElevatedW"/> procedure </summary>
  MUTEX_NAME: AnsiString = 'Elevating:';

function IsZeroSession: Boolean;
var
  TokenHandle: THandle;
  Session, BufferSize: DWORD;
begin
  Result := False;
  BufferSize := SizeOf(Session);
  if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, TokenHandle) then
  begin
    BufferSize := SizeOf(Session);
    if GetTokenInformation(TokenHandle, TokenSessionId, @Session,
      SizeOf(Session), BufferSize) then
      Result := Session = 0;
    CloseHandle(TokenHandle);
  end;
end;

function IsElevated: Boolean;
var
  TokenHandle: THandle;
  Elevation: TOKEN_ELEVATION;
  BufferSize: DWORD;
begin
  Result := False;
  BufferSize := SizeOf(Elevation);
  if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, TokenHandle) then
  begin
    BufferSize := SizeOf(Elevation);
    if GetTokenInformation(TokenHandle, TokenElevation, @Elevation,
      SizeOf(Elevation), BufferSize) then
      Result := Elevation.TokenIsElevated <> 0;
    CloseHandle(TokenHandle);
  end;
end;

function GetParentPID(ProcessHandle: THandle): Cardinal;
var
  Info: TProcessBasicInformation;
  BufferSize: DWORD;
begin
  Result := 0;
  BufferSize := SizeOf(Info);
  if NtQueryInformationProcess(ProcessHandle, ProcessBasicInformation, @Info,
    SizeOf(Info), BufferSize) = 0 then
    Result := Info.InheritedFromUniqueProcessId;
end;

/// <summary> Detaches debugger from process. </summary>
function DebuggerDetach(const H: THandle): Boolean;
var
  DbgObj: THandle;
  BufferSize: DWORD;
begin
  Result := False;
  BufferSize := SizeOf(DbgObj);
  if NtQueryInformationProcess(H, ProcessDebugObjectHandle, @DbgObj,
    SizeOf(DbgObj), BufferSize) = 0 then
  // May be I shoud use NT_SUCCESS() instead
  begin
    { Note: in our situation kill-on-exit is already disabled
      No need to use NtSetInformationDebugObject. }
    if NtRemoveProcessDebug(H, DbgObj) = 0 then
      Result := True;
  end;
end;

/// <summary>
///  Allows you to run process without detaching debugger.
/// </summary>
/// <remarks>
///  Works correctly only with <c>DEBUG_ONLY_THIS_PROCESS</c> flag.
/// </remarks>
procedure DebuggerRunAttached;
var
  DBG: DEBUG_EVENT;
begin
  repeat
    WaitForDebugEvent(DBG, INFINITE);
    ContinueDebugEvent(DBG.dwProcessId, DBG.dwThreadId, DBG_CONTINUE);
  until DBG.dwDebugEventCode = EXIT_PROCESS_DEBUG_EVENT;
end;

// Code from SysUtils
function GetCurrentDir: string;
begin
  GetDir(0, Result);
end;

function RunUnderDebuggerW(const Cmd: WideString; hToken: THandle = 0): Boolean;
var
  { Actually, we should use TStartupInfoW. But it has the same size as
    TStartupInfoA, so it will be ok. Simply, old Delphi doesn't have that type. }
  SIEX: TStartupInfoEx;
  PI: TProcessInformation;
  ExitCode: Cardinal;
  lpCommandLine: string;
  NewParent: THandle;
  ReplacingParent: Boolean;

  function OpenNewParent: Boolean;
  var
    Buffer: SIZE_T;
  begin
    Result := False;
    Buffer := 0;
    NewParent := OpenProcess(PROCESS_CREATE_PROCESS, False, InitiatorPID);
    if NewParent = 0 then
      Exit;
    if not InitializeProcThreadAttributeList(nil, 1, 0, Buffer) then
      if GetLastError <> ERROR_INSUFFICIENT_BUFFER then
        Exit;
    GetMem(SIEX.lpAttributeList, Buffer);
    if not InitializeProcThreadAttributeList(SIEX.lpAttributeList, 1, 0, Buffer)
    then
      Exit;
    if not UpdateProcThreadAttribute(SIEX.lpAttributeList, 0,
      PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, @NewParent, SizeOf(NewParent))
    then
      Exit;
    Result := True;
  end;

  procedure AfterCreation;
  begin
    { Now we can:
      - Run process under debugger by calling DebuggerRunAttached
      - Detach it (not all programs like debuggers, right?) by calling
      DebuggerDetach. I have chosen that one. }
    if not DebuggerDetach(PI.hProcess) then
      DebuggerRunAttached; { This really shouldn't happen if we called
      DebuggerDetach, but who knows... }
    CloseHandle(hToken);
    if NewParent <> 0 then
      CloseHandle(NewParent);
    WaitForSingleObject(PI.hProcess, INFINITE);
    GetExitCodeProcess(PI.hProcess, ExitCode);
    CloseHandle(PI.hProcess);
    CloseHandle(PI.hThread);
    ExitProcess(ExitCode);
  end;
begin
  Result := False;
  lpCommandLine := Cmd;
  UniqueString(lpCommandLine); // CreateProcessW can modify lpCommandLine
  FillChar(PI, SizeOf(PI), 0);
  GetStartupInfoW(SIEX.StartupInfo); // MSDN: The Unicode version does not fail.

  ReplacingParent := OpenNewParent; // Will try to prepare SIEX.lpAttributeList
  if ReplacingParent then
    SIEX.StartupInfo.cb := SizeOf(TStartupInfoEx)
  else
    SIEX.StartupInfo.cb := SizeOf(TStartupInfo);

  if hToken = 0 then
    if not OpenProcessToken(GetCurrentProcess, TOKEN_ALL_ACCESS_P, hToken) then
      Exit(False); // Impossible?

  { Creating process under debugger. This action wouldn't be intercepted by
    Image-File-Execution-Options, so we wouldn't launch ourselves again. }
  if ReplacingParent then
  begin
    // Using TStartupInfoEx with EXTENDED_STARTUPINFO_PRESENT
    if CreateProcessAsUserExW(hToken, nil, PWideChar(Cmd), nil, nil, True,
      DEBUG_PROCESS or DEBUG_ONLY_THIS_PROCESS or EXTENDED_STARTUPINFO_PRESENT,
      nil, PWideChar(GetCurrentDir), SIEX, PI) then
    begin
      // Deleting attributes list before closing NewParent handle
      DeleteProcThreadAttributeList(SIEX.lpAttributeList);
      FreeMem(SIEX.lpAttributeList);
      AfterCreation; // Waiting and closing handles.
    end
    else if GetLastError = ERROR_ELEVATION_REQUIRED then
      Result := True;
  end
  else
  begin
    // Using TStartupInfo
    if CreateProcessAsUserW(hToken, nil, PWideChar(Cmd), nil, nil, True,
      DEBUG_PROCESS or DEBUG_ONLY_THIS_PROCESS, nil, PWideChar(GetCurrentDir),
      SIEX.StartupInfo, PI) then
      AfterCreation // Waiting and closing handles.
    else if GetLastError = ERROR_ELEVATION_REQUIRED then
      Result := True;
  end;
end;

function IntToStr(i: Integer): ShortString;
begin
  Str(i, Result);
end;

// From SysUtils
function FileExists(const FileName: string): Boolean;
const
  faSymLink = $00000400;
  faDirectory = $00000010;
  function ExistsLockedOrShared(const FileName: string): Boolean;
  var
    FindData: TWin32FindData;
    LHandle: THandle;
  begin
    { Either the file is locked/share_exclusive or we got an access denied }
    LHandle := FindFirstFile(PChar(FileName), FindData);
    if LHandle <> INVALID_HANDLE_VALUE then
    begin
      FindClose(LHandle);
      Result := FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = 0;
    end
    else
      Result := False;
  end;

var
  Flags: Cardinal;
  Handle: THandle;
  LastError: Cardinal;
begin
  Flags := GetFileAttributes(PChar(FileName));
  if Flags <> INVALID_FILE_ATTRIBUTES then
  begin
    if faSymLink and Flags <> 0 then
    begin
      if faDirectory and Flags <> 0 then
        Exit(False)
      else
      begin
        Handle := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ,
          nil, OPEN_EXISTING, 0, 0);
        if Handle <> INVALID_HANDLE_VALUE then
        begin
          CloseHandle(Handle);
          Exit(True);
        end;
        Exit(GetLastError = ERROR_SHARING_VIOLATION);
      end;
    end;
    Exit(faDirectory and Flags = 0);
  end;
  LastError := GetLastError;
  Result := (LastError <> ERROR_FILE_NOT_FOUND) and
    (LastError <> ERROR_PATH_NOT_FOUND) and (LastError <> ERROR_INVALID_NAME)
    and ExistsLockedOrShared(FileName);
end;

/// <summary>
///  Returns the delimiter index between first existing file and other
///  parameters.
/// </summary>
function DelimFirstFile(const S: String): Integer;
begin
  if Length(S) = 0 then
    Exit(1);
  if S[1] = '"' then
  begin
    Result := Pos('"', S, 2) + 1;
    if Result = 1 then // not found
      Exit(Length(S) + 1)
    else
      Exit;
  end;
  for Result := 2 to Length(S) do
    if S[Result] = ' ' then
      if FileExists(Copy(S, 1, Result - 1)) then
        Break
      else if FileExists(Copy(S, 1, Result - 1) + '.exe') then
        Break;
end;

procedure RunElevatedW(const Cmd: WideString);
var
  App, Params: String;
  delim: Integer;
  EI: TShellExecuteInfoW;
  ExitCode: Cardinal;
  ElevationMutex: THandle;
begin
  delim := DelimFirstFile(Cmd);
  App := Copy(Cmd, 1, delim - 1);
  Params := Copy(Cmd, delim + 1, Length(Cmd) - delim);

  { Preparing parameters for ShellExecuteEx. As soon as this procedure is used
    in mono-thread application we don't need to call CoUninitialize. }
  FillChar(EI, SizeOf(EI), 0);
  with EI do
  begin
    cbSize := SizeOf(EI);
    lpVerb := PWideChar('runas');
    lpFile := PWideChar(App);
    lpParameters := PWideChar(Params);
    lpDirectory := PWideChar(GetCurrentDir);
    nShow := System.CmdShow;
    fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_UNICODE or
      SEE_MASK_NOCLOSEPROCESS; // We need process handle to wait for it
  end;
  { ShellExecuteEx doesn't provide a possibility to bypass Image-File-
    Execution-Options. So we rely on interception — it will show correct UAC,
    but launch ourselves with high privileges instead. In case of Ask.exe we
    need to force it accept "Yes" without asking. When process will exit — it's
    exit code will be transmitted through chain of processes to the caller. }
  ElevationMutex := CreateMutexA(nil, False,
    PAnsiChar(MUTEX_NAME + IntToStr(GetCurrentProcessId)));

  if ShellExecuteExW(@EI) then
    if EI.hProcess <> 0 then
    begin
      { We are responsible now for EI.hProcess handle because of
        SEE_MASK_NOCLOSEPROCESS flag }
      WaitForSingleObject(EI.hProcess, INFINITE);
      GetExitCodeProcess(EI.hProcess, ExitCode);
      CloseHandle(EI.hProcess);
      if ElevationMutex <> 0 then
        CloseHandle(ElevationMutex);
      ExitProcess(ExitCode);
    end;
  ExitProcess(STATUS_DLL_INIT_FAILED);
end;

function ParentRequestedElevation: Boolean;
var
  ElevationMutex: THandle;
begin // Don't ask user again if our parent is another instance of Ask.exe
  ElevationMutex := OpenMutexA(MUTEX_MODIFY_STATE, False,
    PAnsiChar(MUTEX_NAME + IntToStr(GetParentPID(GetCurrentProcess))));
  Result := ElevationMutex <> 0;
  if Result then
    CloseHandle(ElevationMutex);
end;

function InitiatorPID: Cardinal;
var
  H: THandle;
begin
  if ParentRequestedElevation then
  begin
    H := OpenProcess(PROCESS_QUERY_INFORMATION, False,
      GetParentPID(GetCurrentProcess)); // Opening parent to know it's parent
    if H <> 0 then
    begin
      Result := GetParentPID(H); // Getting parent of our parent
      CloseHandle(H);
    end
    else
      Result := 0;
  end
  else
    Result := GetParentPID(GetCurrentProcess); // Just our parent
end;

end.
