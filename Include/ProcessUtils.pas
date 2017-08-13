{ 2017 © diversenok@gmail.com }

unit ProcessUtils;
{$WARN SYMBOL_PLATFORM OFF}

interface

uses Windows;

{ winternl.h }

{$MINENUMSIZE 4}

type
  TProcessInformationClass = (
    ProcessBasicInformation = 0,
    ProcessDebugObjectHandle = 30
  );

type
  NTSTATUS = LongWord;

  PROCESS_BASIC_INFORMATION = record
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

{ User defined }

const
  // Let caller think process failed to start if user choose "No"
  STATUS_DLL_INIT_FAILED = $C0000142;

  /// <summary>
  ///   CreateProcess should be replaced with ShellExecuteEx with "runas" verb.
  /// </summary>
  ERROR_ELEVATION_REQUIRED = 740;

  // See RunElevated
  MUTEX_NAME: AnsiString = 'Elevating:';

/// <summary>
///   Checks if current process runs in zero session.
///   Returns false if failed to obtain information.
/// </summary>
function IsZeroSession: Boolean;

/// <summary>
///   Checks if current process runs with elevated token.
///   Returns false if failed to obtain information.
/// </summary>
function IsElevated: Boolean;

/// <summary> Returns PID of parent process or zero on fail. </summary>
function GetParentPID: Cardinal;

/// <summary>
///   Uses CreateProcess with debugging flag to bypass
///   Image-File-Execution-Options and waits for new process:
///     On ERROR_ELEVATION_REQUIRED returns True;
///     On other error returns False;
///     On success exits current process with same exit code.
/// </summary>
function RunUnderDebuggerW(const Cmd: WideString;
  hToken: THandle = 0): Boolean;

/// <summary>
///   Runs application at highest privileges and waits for it:
///     On fail exits current process with STATUS_DLL_INIT_FAILED code
///     On success exits with the same code.
/// </summary>
procedure RunElevatedW(const Cmd: WideString;
  CreateInfoMutex: Boolean = False);

/// <summary>
///   Checks if parent process is informing us that it has used
///   ShellExecuteEx because of lack of privileges.
/// </summary>
function ParentRequestedElevation: Boolean;

implementation

uses ShellAPI;

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

function GetParentPID: Cardinal;
var
  Info: PROCESS_BASIC_INFORMATION;
  BufferSize: DWORD;
begin
  Result := 0;
  BufferSize := SizeOf(Info);
  if NtQueryInformationProcess(GetCurrentProcess, ProcessBasicInformation,
    @Info, SizeOf(Info), BufferSize) = 0 then
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
///   Allows you to run process without detaching debugger.
///   Works correctly only with DEBUG_ONLY_THIS_PROCESS flag.
/// </summary>
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

function RunUnderDebuggerW(const Cmd: WideString;
  hToken: THandle = 0): Boolean;
var
  { Actually, we should use TStartupInfoW. But it has the same size as
    TStartupInfoA, so it will be ok. Simply, old Delphi doesn't have that type. }
  SI: TStartupInfo;
  PI: TProcessInformation;
  ExitCode: Cardinal;
  lpCommandLine: string;
begin
  Result := False;
  lpCommandLine := Cmd;
  UniqueString(lpCommandLine); // CreateProcessW can modify lpCommandLine
  FillChar(PI, SizeOf(PI), 0);
  GetStartupInfoW(SI); // MSDN: The Unicode version does not fail.
  if hToken = 0 then
    if not OpenProcessToken(GetCurrentProcess, TOKEN_ALL_ACCESS_P, hToken) then
      Exit(False);

  { Creating process under debugger. This action wouldn't be intercepted by
    Image-File-Execution-Options, so we wouldn't launch ourselves again. }
  if CreateProcessAsUserW(hToken, nil, PWideChar(Cmd), nil, nil,
    True, DEBUG_PROCESS or DEBUG_ONLY_THIS_PROCESS, nil,
    PWideChar(GetCurrentDir), SI, PI) then
  begin
    { Now we can:
      - Run process under debugger by calling DebuggerRunAttached
      - Detach it (not all programs like debuggers, right?) by calling
      DebuggerDetach. I have chosen that one. }
    if not DebuggerDetach(PI.hProcess) then
      DebuggerRunAttached; { This really shouldn't happen if we called
      DebuggerDetach, but who knows... }
    CloseHandle(hToken);
    WaitForSingleObject(PI.hProcess, INFINITE);
    GetExitCodeProcess(PI.hProcess, ExitCode);
    CloseHandle(PI.hProcess);
    CloseHandle(PI.hThread);
    ExitProcess(ExitCode);
  end
  else if GetLastError = ERROR_ELEVATION_REQUIRED then
    Result := True;
end;

function IntToStr(i: Integer): ShortString;
begin
  Str(i, Result);
end;

// From SysUtils
function FileExists(const FileName: string): Boolean;
const
  faSymLink     = $00000400;
  faDirectory   = $00000010;
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
      Result := false;
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
        Exit(false)
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
function DelimFirstFile(const S: String): integer;
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

procedure RunElevatedW(const Cmd: WideString;
  CreateInfoMutex: Boolean = False);
var
  App, Params: String;
  delim: integer;
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
  if CreateInfoMutex then
    ElevationMutex := CreateMutexA(nil, False,
      PAnsiChar(MUTEX_NAME + IntToStr(GetCurrentProcessId)))
  else
    ElevationMutex := 0;
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
    PAnsiChar(MUTEX_NAME + IntToStr(GetParentPID)));
  Result := ElevationMutex <> 0;
  if Result then
    CloseHandle(ElevationMutex);
end;

end.
