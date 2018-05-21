{   ExecutionMaster component.
    Copyright (C) 2017-2018 diversenok

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

uses Winapi.Windows, Winapi.ShellAPI;

const
  // Let the caller think process failed to start if the user has chosen "No".
  STATUS_DLL_INIT_FAILED = -1073741502; // $C0000142;

  STATUS_UNHANDLED_EXCEPTION = -1073741500; // $C0000144;

type
  TProcessCreationStatus = (pcsSuccess, pcsElevationRequired, pcsFailed);

  TTokenIntegrityLevel = (
    ilUntrusted = $0000,
    ilLow = $1000,
    ilMedium = $2000,
    ilHigh = $3000,
    ilSystem = $4000
  );

/// <summary>
///  Checks if the current process runs in zero session.
/// </summary>
/// <remarks>
///  Returns <c>False</c> if failed to obtain information.
/// </remarks>
function IsZeroSession: Boolean;

/// <summary>
///  Checks if the current process runs with en elevated token.
/// </summary>
/// <remarks>
///  Returns <c>False</c> if failed to obtain information.
/// </remarks>
function IsElevated: Boolean;

/// <summary> Returns PID of the parent process or zero on failure. </summary>
function GetParentPID(ProcessHandle: THandle): Cardinal;

/// <summary>
///  Returns PID of the process that initiated execution chain or zero on failure.
/// </summary>
function InitiatorPID: Cardinal;

/// <summary>
///  Uses <c>CreateProcess</c> with debugging flags to bypass
///  Image-File-Execution-Options.
/// </summary>
function RunIgnoringIFEO(out PI: TProcessInformation;
  const Cmd: WideString; hToken: THandle = 0;
  CurrentDir: WideString = ''): TProcessCreationStatus;

/// <summary>
///  Calls <c>RunIgnoringIFEO</c> and waits for the newly created process.
/// </summary>
function RunIgnoringIFEOAndWait(const Cmd: WideString;
  hToken: THandle = 0; CurrentDir: WideString = ''): TProcessCreationStatus;

/// <summary> Requests UAC to run the app at the highest privileges. </summary>
function RunElevated(out EI: TShellExecuteInfoW; out ElevationMutex: THandle;
  const Cmd: WideString; const CurrentDir: WideString = ''): TProcessCreationStatus;

/// <summary>
///  Calls <c>RunElevated</c> and waits for the newly created process.
/// </summary>
function RunElevatedAndWait(const Cmd: WideString;
  const CurrentDir: WideString = ''): TProcessCreationStatus;

/// <summary>
///  Checks if our parent process is informing us that it used
///  <c>ShellExecuteEx</c> because of lack of privileges.
/// </summary>
function ParentRequestedElevation: Boolean;

/// <summary>
///  Sets new integrity level of the token.
///  The token should have <c>TOKEN_QUERY</c>
///  and <c>TOKEN_ADJUST_DEFAULT</c> access.
/// </summary>
function SetTokenIntegrity(hToken: THandle;
  IntegrityLevel: TTokenIntegrityLevel): Boolean;

// From SysUtils
function GetCurrentDir: string;

implementation

{ -------- winternl.h -------- }

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

function NtQueryInformationProcess(ProcessHandle: THandle;
  ProcessInformationClass: TProcessInformationClass;
  ProcessInformation: Pointer; ProcessInformationLength: Cardinal;
  var ReturnLength: Cardinal): NTSTATUS; stdcall;
  external 'ntdll.dll' name 'NtQueryInformationProcess';

{ -------- WinBase.h -------- }

const
  /// <summary>
  ///  <c>CreateProcess</c> should be replaced with <c>ShellExecuteEx</c>
  ///  with "runas" verb.
  /// </summary>
  ERROR_ELEVATION_REQUIRED = 740;

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
  ///  <c>SizeOf(TStartupInfoExW)</c> and to enable
  ///  <c>EXTENDED_STARTUPINFO_PRESENT</c> flag for <c>CreateProcess</c>.
  /// </remarks>
  TStartupInfoExW = record
    StartupInfo: TStartupInfoW;
    lpAttributeList: PProcThreadAttributeEntry;
  end;

/// <summary>
///  Sets the action to be performed when the calling thread exits.
/// </summary>
/// <param name="KillOnExit"> If this parameter is TRUE, the thread terminates
///  all attached processes on exit (default behaviour). Otherwise,
///  the thread detaches from all processes being debugged on exit. </param>
function DebugSetProcessKillOnExit(KillOnExit: BOOL): BOOL; stdcall;
  external kernel32 name 'DebugSetProcessKillOnExit';

/// <summary> Stops us from debugging the specified process. </summary>
/// <remarks>
///  If you don't want to kill the process use
///  <c>DebugSetProcessKillOnExit(False)</c> before detaching debugger.
/// </remarks>
function DebugActiveProcessStop(dwProcessId: DWORD): BOOL; stdcall;
  external kernel32 name 'DebugActiveProcessStop';

/// <summary> Extended version of <c>CreateProcessW</c>. </summary>
/// <remarks>
///  Always include <c>EXTENDED_STARTUPINFO_PRESENT</c> flag!
/// </remarks>
function CreateProcessExW(lpApplicationName: LPCWSTR; lpCommandLine: LPWSTR;
  lpProcessAttributes: PSecurityAttributes;
  lpThreadAttributes: PSecurityAttributes; bInheritHandles: BOOL;
  dwCreationFlags: DWORD; lpEnvironment: Pointer; lpCurrentDirectory: LPCWSTR;
  const lpStartupInfo: TStartupInfoExW;
  var lpProcessInformation: TProcessInformation): BOOL; stdcall;
  external kernelbase name 'CreateProcessW';

/// <summary> Extended version of <c>CreateProcessAsUserW</c>. </summary>
/// <remarks>
///  Always include <c>EXTENDED_STARTUPINFO_PRESENT</c> flag!
/// </remarks>
function CreateProcessAsUserExW(hToken: THandle; lpApplicationName: LPCWSTR;
  lpCommandLine: LPWSTR; lpProcessAttributes: PSecurityAttributes;
  lpThreadAttributes: PSecurityAttributes; bInheritHandles: BOOL;
  dwCreationFlags: DWORD; lpEnvironment: Pointer; lpCurrentDirectory: LPCWSTR;
  const lpStartupInfo: TStartupInfoExW;
  var lpProcessInformation: TProcessInformation): BOOL; stdcall;
  external advapi32 name 'CreateProcessAsUserW';

/// <summary>
///  Initializes the specified list of attributes for process and thread
///  creation.
/// </summary>
function InitializeProcThreadAttributeList(lpAttributeList
  : PProcThreadAttributeEntry; dwAttributeCount: DWORD; dwFlags: DWORD;
  var lpSize: SIZE_T): BOOL; stdcall;
  external kernel32 name 'InitializeProcThreadAttributeList' delayed;

/// <summary>
///  Updates the specified attribute in a list of attributes for process and
///  thread creation.
/// </summary>
function UpdateProcThreadAttribute(lpAttributeList: PProcThreadAttributeEntry;
  dwFlags: DWORD; Attribute: DWORD_PTR; lpValue: PVOID; cbSize: SIZE_T;
  lpPreviousValue: PVOID = nil; lpReturnSize: PSIZE_T = nil): BOOL; stdcall;
  external kernel32 name 'UpdateProcThreadAttribute' delayed;

/// <summary>
///  Deletes the specified list of attributes for process and thread creation.
/// </summary>
procedure DeleteProcThreadAttributeList(lpAttributeList
  : PProcThreadAttributeEntry);
  external kernel32 name 'DeleteProcThreadAttributeList' delayed;

{ -------- User defined -------- }

const
  /// <summary> See <c>RunElevated</c>. </summary>
  MUTEX_NAME: AnsiString = 'Elevating:';

function IsBelowVista: Boolean;
var
  Version: OSVERSIONINFO;
begin
  Result := GetVersionEx(Version) and (Version.dwMajorVersion < 6);
end;

function IsZeroSession: Boolean;
var
  TokenHandle: THandle;
  Session, BufferSize: DWORD;
begin
  Result := False;
  if IsBelowVista then // Lie for Windows XP
    Exit;
  if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, TokenHandle) then
  begin
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

/// <summary>
///  Allows you to run the process without detaching debugger.
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
///  Returns the delimiter index between the first existing file and other
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

function ParentRequestedElevation: Boolean;
var
  ElevationMutex: THandle;
begin // Don't ask the user again if our parent is another instance of Ask.exe
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

function SetNewParent(out hNewParent: THandle;
  var SIEX: TStartupInfoExW): Boolean;
var
  Buffer: SIZE_T;
begin
  Result := False;
  Buffer := 0;
  SIEX.lpAttributeList := nil;

  hNewParent := OpenProcess(PROCESS_CREATE_PROCESS, False, InitiatorPID);
  if hNewParent = 0 then
    Exit;
  if not InitializeProcThreadAttributeList(nil, 1, 0, Buffer) then
    if GetLastError <> ERROR_INSUFFICIENT_BUFFER then
      Exit;
  try
    GetMem(SIEX.lpAttributeList, Buffer);
    if not InitializeProcThreadAttributeList(SIEX.lpAttributeList, 1, 0, Buffer)
    then
      Exit;
    if not UpdateProcThreadAttribute(SIEX.lpAttributeList, 0,
      PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, @hNewParent, SizeOf(hNewParent))
    then
    begin
      DeleteProcThreadAttributeList(SIEX.lpAttributeList);
      Exit;
    end;
    Result := True;
  finally
    if not Result then // Clean up
    begin
      if SIEX.lpAttributeList <> nil then
      begin
        FreeMem(SIEX.lpAttributeList);
        SIEX.lpAttributeList := nil;
      end;
      if hNewParent <> 0 then
        CloseHandle(hNewParent);
      // Note, that if we succeeded new parent's handle shouldn't be closed
      // before calling DeleteProcThreadAttributeList.
    end;
  end;
end;

function RunIgnoringIFEO;
var
  SIEX: TStartupInfoExW;
  hNewParent: THandle;
  lpCommandLine: string;
begin
  Result := pcsFailed;
  lpCommandLine := Cmd;
  UniqueString(lpCommandLine); // CreateProcessW can modify lpCommandLine
  FillChar(PI, SizeOf(PI), 0);
  GetStartupInfoW(SIEX.StartupInfo); // MSDN: The Unicode version does not fail.
  SIEX.lpAttributeList := nil;
  if CurrentDir = '' then
    CurrentDir := GetCurrentDir;

  { Creating process under the debugger. This action wouldn't be intercepted by
    Image-File-Execution-Options, so we wouldn't launch ourselves again. }

  // SetNewParent tries to prepare SIEX.lpAttributeList
  if not IsBelowVista and SetNewParent(hNewParent, SIEX) then
  begin
    // Using TStartupInfoExW with EXTENDED_STARTUPINFO_PRESENT
    SIEX.StartupInfo.cb := SizeOf(TStartupInfoExW);

    if hToken <> 0 then
    begin // An external token is provided
      if CreateProcessAsUserExW(hToken, nil, PWideChar(Cmd), nil, nil, True,
        DEBUG_PROCESS or DEBUG_ONLY_THIS_PROCESS or EXTENDED_STARTUPINFO_PRESENT,
        nil, PWideChar(CurrentDir), SIEX, PI) then
        Result := pcsSuccess
      else if GetLastError = ERROR_ELEVATION_REQUIRED then
        Result := pcsElevationRequired;
    end
    else
    begin // No token
      if CreateProcessExW(nil, PWideChar(Cmd), nil, nil, True,
        DEBUG_PROCESS or DEBUG_ONLY_THIS_PROCESS or EXTENDED_STARTUPINFO_PRESENT,
        nil, PWideChar(CurrentDir), SIEX, PI) then
        Result := pcsSuccess
      else if GetLastError = ERROR_ELEVATION_REQUIRED then
        Result := pcsElevationRequired;
    end;

    DeleteProcThreadAttributeList(SIEX.lpAttributeList);
    CloseHandle(hNewParent); // Only after deleting ProcThreadAttributes
  end
  else
  begin
    // Using TStartupInfo
    SIEX.StartupInfo.cb := SizeOf(TStartupInfo);
    if hToken <> 0 then
    begin
      if CreateProcessAsUserW(hToken, nil, PWideChar(Cmd), nil, nil, True,
        DEBUG_PROCESS or DEBUG_ONLY_THIS_PROCESS, nil, PWideChar(CurrentDir),
        SIEX.StartupInfo, PI) then
        Result := pcsSuccess
      else if GetLastError = ERROR_ELEVATION_REQUIRED then
        Result := pcsElevationRequired;
    end
    else
    begin
      if CreateProcessW(nil, PWideChar(Cmd), nil, nil, True,
        DEBUG_PROCESS or DEBUG_ONLY_THIS_PROCESS, nil, PWideChar(CurrentDir),
        SIEX.StartupInfo, PI) then
        Result := pcsSuccess
      else if GetLastError = ERROR_ELEVATION_REQUIRED then
        Result := pcsElevationRequired;
    end;
  end;

  if Result = pcsSuccess then
  begin
    DebugSetProcessKillOnExit(False); // Should be called after CreateProcess
    if not DebugActiveProcessStop(PI.dwProcessId) then // Detaching
      DebuggerRunAttached; // This really shouldn't happen, but who knows...
  end;
end;

function RunIgnoringIFEOAndWait;
var
  PI: TProcessInformation;
  UExitCode: Cardinal;
begin
  Result := RunIgnoringIFEO(PI, Cmd, hToken, CurrentDir);
  if Result = pcsSuccess then
  begin
    WaitForSingleObject(PI.hProcess, INFINITE);
    GetExitCodeProcess(PI.hProcess, UExitCode);
    // We can't pass ExitCode here due to incompatible types
    ExitCode := UExitCode;
    CloseHandle(PI.hProcess);
    CloseHandle(PI.hThread);
  end;
end;

function RunElevated;
var
  App, Params: String;
  delim: Integer;
begin
  Result := pcsFailed;
  delim := DelimFirstFile(Cmd);
  App := Copy(Cmd, 1, delim - 1);
  Params := Copy(Cmd, delim + 1, Length(Cmd) - delim);

  { Preparing parameters for ShellExecuteEx. As soon as this procedure is used
    in a mono-thread application we don't need to call CoUninitialize. }
  FillChar(EI, SizeOf(EI), 0);
  with EI do
  begin
    cbSize := SizeOf(EI);
    lpVerb := PWideChar('runas');
    lpFile := PWideChar(App);
    lpParameters := PWideChar(Params);
    if CurrentDir = '' then
      lpDirectory := PWideChar(GetCurrentDir)
    else
      lpDirectory := PWideChar(CurrentDir);
    nShow := System.CmdShow;
    fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_UNICODE or
      SEE_MASK_NOCLOSEPROCESS; // We need process handle to wait for it
  end;
  { ShellExecuteEx doesn't provide a possibility to bypass Image File Execution
    Options. So we rely on the interception — it will show the correct UAC, but
    launch ourselves with high privileges instead. In case of Ask.exe, we need
    to force it to accept "Yes" without asking. When process will exit — its
    exit code will be transmitted through the chain of processes to the caller. }
  ElevationMutex := CreateMutexA(nil, False,
    PAnsiChar(MUTEX_NAME + IntToStr(GetCurrentProcessId)));

  if ShellExecuteExW(@EI) then
    if EI.hProcess <> 0 then
      Result := pcsSuccess;
end;

function RunElevatedAndWait;
var
  EI: TShellExecuteInfoW;
  UExitCode: Cardinal;
  ElevationMutex: THandle;
begin
  Result := RunElevated(EI, ElevationMutex, Cmd, CurrentDir);
  if Result = pcsSuccess then
  begin
    WaitForSingleObject(EI.hProcess, INFINITE);
    GetExitCodeProcess(EI.hProcess, UExitCode);
    // We can't pass ExitCode here due to incompatible types
    ExitCode := UExitCode;
    CloseHandle(EI.hProcess);
    if ElevationMutex <> 0 then
      CloseHandle(ElevationMutex);
  end;
end;

function SetTokenIntegrity(hToken: THandle;
  IntegrityLevel: TTokenIntegrityLevel): Boolean;
const
  SE_GROUP_INTEGRITY = $20;
var
  mandatoryLabelAuthority: SID_IDENTIFIER_AUTHORITY;
  mandatoryLabel: TSIDAndAttributes;
begin
  FillChar(mandatoryLabelAuthority, SizeOf(mandatoryLabelAuthority), 0);
  mandatoryLabelAuthority.Value[5] := 16; // SECURITY_MANDATORY_LABEL_AUTHORITY
  mandatoryLabel.Sid := AllocMem(12);
  InitializeSid(mandatoryLabel.Sid, mandatoryLabelAuthority, 1);
  GetSidSubAuthority(mandatoryLabel.Sid, 0)^ := DWORD(IntegrityLevel);
  mandatoryLabel.Attributes := SE_GROUP_INTEGRITY;
  Result := SetTokenInformation(hToken, TokenIntegrityLevel, @mandatoryLabel,
    SizeOf(TSIDAndAttributes));
  FreeMem(mandatoryLabel.Sid);
end;

end.
