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

unit IFEO;

interface

uses Winapi.Windows;

type
  TAction = (aAsk, aDrop, aElevate, aNoSleep, aDisplayOn,
    aDenyAndNotify, // Launch Deny.exe
    aDenySilently,  // Raise code 0 by launching Deny.exe in silent mode
    aDenyNotFound,  // Raise code 2
    aDenyAccess,    // Raise code 5
    aDenyShared,    // Raise code 32
    aDenyExecute,   // Raise code 87
    aDenyNotWin32,  // Raise code 129
    aDenyNotValid,  // Raise code 193
    aExecuteEx      // A.exe /param  |-->  B.exe A.exe /param
  );
  // Note: aExecuteEx should be the last action

  TFileBasedAction = aAsk..aDenySilently;

const
  // Command-line short names
  ActionShortNames: array [TAction] of string = ('ask', 'drop', 'elevate',
    'nosleep', 'display-on', 'deny', 'deny-success', 'deny-not-found',
    'deny-access', 'deny-shared', 'deny-execution', 'deny-not-win32',
    'deny-not-valid', 'execute');

  /// <summary> You shouldn't mess with them. </summary>
  DangerousProcesses: array [0 .. 18] of string = ('csrss.exe', 'dwm.exe',
    'lsm.exe', 'logonui.exe', 'lsass.exe', 'services.exe', 'userinit.exe',
    'winlogon.exe', 'wininit.exe', 'smss.exe', 'svchost.exe', 'wlanext.exe',
    'conhost.exe', 'audiodg.exe', 'wlanext.exe', 'explorer.exe', 'dwm.exe',
    'consent.exe', 'dllhost.exe');

  /// <summary> Warning for <c>DangerousProcesses</c>. </summary>
  WARN_SYSPROC = '%s is a part of the system. Performing this action may ' +
    'cause system instability. Are you sure?';
  WARN_SYSPROC_CAPTION = 'System component';

  /// <summary> Some compatibility problems with specified processes. </summary>
  CompatibilityProblems: array [0 .. 3] of String = ('chrome.exe',
    'firefox.exe', 'browser.exe', 'iexplore.exe');

  /// <summary> Warning for <c>CompatibilityProblems</c>. </summary>
  WARN_COMPAT = 'There are some compatibility problems with setting ' +
  'actions on %s' + #$D#$A + 'This program may start to work incorrectly. ' +
  'Are you sure?';
  WARN_COMPAT_CAPTION = 'Compatibility problems';

var
  EMDebuggers: array [TAction] of string;

const
  ERR_ACTION = 'Can''t find executable file that performs specified action.' +
    #$D#$A + 'Some components of Execution Master are missing.';

type
  /// <summary>
  ///  Represents settings of a debugger to register with
  ///  Image-File-Execution-Options. Use constructor instead of setting values.
  /// </summary>
  TIFEORec = record
    Action: TAction;
    TreatedFile: string;
    DebuggerStr: string;
    constructor Create(AAction: TAction; const ATreatedFile: string;
      const ADebugger: string = ''); overload;
    constructor Create(const ATreatedFile, ADebugger: string); overload;
    function GetCaption: string;
  end;

  /// <summary>
  ///  Main class for querying/setting information related to IFEO.
  /// </summary>
  TImageFileExecutionOptions = class
  protected
  type
    TExecConfigArray = array of TIFEORec;
  var
    Arr: TExecConfigArray;
    class function GetKey(const ATreatedFile: string): string;
    /// <summary>
    ///  Escapes all quotes and the last backslash for use with reg.exe
    /// </summary>
    class function EscapeStr(const Str: string): string;
    /// <summary>
    ///  Checks if there are any other settings for specified file that
    ///  shouldn't be deleted.
    /// </summary>
    class function NeedDeleteValueOnly(const ATreatedFile: string): Boolean;
    procedure Add(const Debugger: TIFEORec);
    function GetDebugger(ind: integer): TIFEORec;
    function GetCount: integer;
  public
    /// <summary>
    ///   Overwrites previous settings for specified file. Don't call it from
    ///   object - use AddDebugger in that case instead.
    ///  </summary>
    class procedure RegisterDebugger(const Debugger: TIFEORec);
    /// <summary>
    ///   Don't call it from object - use DeleteDebugger in that case instead.
    ///  </summary>
    class procedure UnregisterDebugger(const ATreatedFile: string);
    /// <summary>
    ///  Reads settings of IFEO from registry.
    /// </summary>
    constructor Create;
    /// <summary>
    ///  Overwrites previous settings for specified file.
    ///  Returns index of new or modified item.
    /// </summary>
    function AddDebugger(const Debugger: TIFEORec): integer;
    procedure DeleteDebugger(index: integer);
    property Count: integer read GetCount;
    property Debuggers[ind: integer]: TIFEORec read GetDebugger; default;
  end;


  /// <summary>
  ///  Converts an error code that you want to raise with IFEO into a
  ///  well-known action.
  /// </summary>
function ErrorCodeToAction(CodeToRaise: Integer): TAction;
procedure ElevetedExecute(const AWnd: HWND; const AFileName: WideString;
  const AParameters: WideString = ''; WaitProcess: Boolean = False;
  const npShow: integer = SW_HIDE);

var
  /// <summary>
  ///  This handle is used with ShellExecuteEx.
  ///  Set it, if you have a main window.
  /// </summary>
  ElvationHandle: UIntPtr = 0;
  ProcessIsElevated: Boolean;

implementation

uses System.SysUtils, Winapi.ShellApi, ProcessUtils, Registry2;

function ErrorCodeToAction(CodeToRaise: Integer): TAction;
begin
  case CodeToRaise of
    0: Result := aDenySilently;
    2: Result := aDenyNotFound;
    5: Result := aDenyAccess;
    32: Result := aDenyShared;
    87: Result := aDenyExecute;
    129: Result := aDenyNotWin32;
    193: Result := aDenyNotValid;
  else
    raise Exception.Create('The specified error code has no associated ' +
      'action. It can''t be raised');
  end;
end;

  { ShellApi }

procedure ElevetedExecute;
var
  ExecInfo: TShellExecuteInfoW;
  ExitCode: Cardinal;
begin
  { By the way: ShellExecuteEx initializes COM, so if we want to call it from
    secondary thread we should use CoUninitialize. Otherwise we will get
    RPC_E_THREAD_NOT_INIT error. In our case we call it from main thread. }
  FillChar(ExecInfo, SizeOf(ExecInfo), 0);
  with ExecInfo do
  begin
    cbSize := SizeOf(ExecInfo);
    Wnd := AWnd;
    lpVerb := PWideChar('runas');
    lpFile := PWideChar(AFileName);
    lpParameters := PWideChar(AParameters);
    lpDirectory := PWideChar(GetCurrentDir);
    nShow := npShow;
    fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_UNICODE;
    if AWnd <> 0 then
      fMask := fMask or SEE_MASK_FLAG_NO_UI;
    if WaitProcess then
      fMask := fMask or SEE_MASK_NOCLOSEPROCESS;
    if not ShellExecuteExW(@ExecInfo) then
      RaiseLastOSError;
    if WaitProcess and (ExecInfo.hProcess <> 0) then
    begin
      WaitForSingleObject(hProcess, INFINITE);
      GetExitCodeProcess(hProcess, ExitCode);
      CloseHandle(hProcess);
      if ExitCode <> 0 then
        raise Exception.Create('Process exited with error code: ' +
          IntToStr(ExitCode));
    end;
  end;
end;

  { TImageFileOptionsRec }

constructor TIFEORec.Create(AAction: TAction; const ATreatedFile: string;
  const ADebugger: string = '');
begin
  Action := AAction;
  TreatedFile := ATreatedFile;
  if AAction = aExecuteEx then
    DebuggerStr := ADebugger
  else
    DebuggerStr := EMDebuggers[AAction];
end;

constructor TIFEORec.Create(const ATreatedFile, ADebugger: string);
var
  a: TAction;
begin
  TreatedFile := ATreatedFile;
  DebuggerStr := ADebugger;
  Action := aExecuteEx;
  for a := Low(EMDebuggers) to Pred(High(EMDebuggers)) do
    if ADebugger = EMDebuggers[a] then
    begin
      Action := a;
      DebuggerStr := EMDebuggers[a]; // a reference to existing string, not a copy
      Break;
    end;
end;

function TIFEORec.GetCaption: string;
const
  ActionCaptions: array [TAction] of string = ('Ask', 'Drop admin rights',
    'Elevate', 'No sleep until exit', 'Force display on', 'Deny and notify user',
    'Raise error 0',
    'Raise error 2',
    'Raise access denied',
    'Raise error 32',
    'Raise error 87',
    'Raise error 129',
    'Raise error 193',
    'Execute: '
    );
begin
  Result := ActionCaptions[Action];
  if Action = aExecuteEx then
    Result := Result + DebuggerStr;
end;

{ Registry constants }

const
  REG_KEY = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion' +
    '\Image File Execution Options';
  REG_VALUE = 'Debugger';
  REG_EXE = 'reg.exe';

  { TImageFileExecutionOptions class metods }

class function TImageFileExecutionOptions.GetKey;
begin
  Result := REG_KEY + '\' + ATreatedFile;
end;

class function TImageFileExecutionOptions.EscapeStr;
var
  i: integer;
begin
  for i := 1 to Length(Str) do
    if Str[i] = '"' then
      Result := Result + '\' + Str[i]
    else
      Result := Result + Str[i];
  if Str[Length(Str)] = '\' then
    Result := Result + '\';
end;

class function TImageFileExecutionOptions.NeedDeleteValueOnly;
var
  reg: TRegistry;
  KeyInfo: TRegKeyInfo;
begin
  Result := True;
  reg := TRegistry.Create(KEY_READ);
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    if not reg.OpenKey(GetKey(ATreatedFile), False) then
      raise Exception.Create('DeleteValueOnly::TRegistry.OpenKey failed');

    if not reg.ValueExists(REG_VALUE) then
      raise Exception.Create('There is no action set already.');

    if not reg.GetKeyInfo(KeyInfo) then
      raise Exception.Create('DeleteValueOnly::TRegistry.GetKeyInfo failed');

    Result := (KeyInfo.NumSubKeys <> 0) or (KeyInfo.NumValues > 1);
  finally
    reg.Free;
  end;
end;

class procedure TImageFileExecutionOptions.RegisterDebugger;
const
  PARAMS = 'ADD "HKLM\%s" /v Debugger /d "%s" /f';
var
  reg: TRegistry;
begin
  if ProcessIsElevated then
  begin
    reg := TRegistry.Create;
    reg.RootKey := HKEY_LOCAL_MACHINE;
    try
      if not reg.OpenKey(GetKey(Debugger.TreatedFile), True) then
        raise Exception.Create('Unable to open registry key while registering');
      reg.WriteString(REG_VALUE, Debugger.DebuggerStr); // can raise excetion itself
    finally
      reg.Free;
    end
  end
  else ElevetedExecute(ElvationHandle, REG_EXE, Format(PARAMS,
    [GetKey(Debugger.TreatedFile), EscapeStr(Debugger.DebuggerStr)]));
end;

class procedure TImageFileExecutionOptions.UnregisterDebugger;
var
  reg: TRegistry;
  FDelValueOnly: Boolean;
  function GetParams: string;
  begin
    if FDelValueOnly then
      Result := 'DELETE "HKLM\%s" /v Debugger /f'
    else
      Result := 'DELETE "HKLM\%s" /f';
  end;

begin
  FDelValueOnly := NeedDeleteValueOnly(ATreatedFile);
  if ProcessIsElevated then
  begin
    reg := TRegistry.Create;
    reg.RootKey := HKEY_LOCAL_MACHINE;
    try
      if not FDelValueOnly then
        reg.DeleteKey(GetKey(ATreatedFile))
      else if reg.OpenKey(GetKey(ATreatedFile), False) then
        reg.DeleteValue(REG_VALUE);
    finally
      reg.Free;
    end
  end
  else ElevetedExecute(ElvationHandle, REG_EXE,
    Format(GetParams, [GetKey(ATreatedFile)]));
end;

  { TImageFileExecutionOptions object }

procedure TImageFileExecutionOptions.Add;
begin
  SetLength(Arr, Length(Arr) + 1);
  Arr[High(Arr)] := Debugger;
end;

constructor TImageFileExecutionOptions.Create;
var
  reg: TRegistry;
  AllKeys: TStringArray;
  i: integer;
begin
  SetLength(Arr, 0);
  reg := TRegistry.Create(KEY_READ);
  reg.RootKey := HKEY_LOCAL_MACHINE;
  if not reg.OpenKey(REG_KEY, False) then
    Exit;

  // Collecting all executables with special settings
  reg.GetKeyNames(AllKeys);
  reg.CloseKey;

  // Finding and saving debugged ones
  for i := 0 to High(AllKeys) do
  begin
    reg.OpenKey(REG_KEY + '\' + AllKeys[i], False);
    if reg.ValueExists(REG_VALUE) then
      case reg.GetDataType(REG_VALUE) of
        rdString, rdExpandString:
          Add(TIFEORec.Create(AllKeys[i], reg.ReadString(REG_VALUE)));
      end;
    reg.CloseKey;
  end;
  reg.Free;
end;

function TImageFileExecutionOptions.AddDebugger;
begin
  RegisterDebugger(Debugger);
  for Result := 0 to High(Arr) do
    if Arr[Result].TreatedFile = Debugger.TreatedFile then
    begin
      Arr[Result] := Debugger;
      Break;
    end;
  if Result = Length(Arr) then
    Add(Debugger);
end;

procedure TImageFileExecutionOptions.DeleteDebugger;
var
  i: integer;
begin
  UnregisterDebugger(Arr[index].TreatedFile);

  for i := index + 1 to High(Arr) do
    Arr[i - 1] := Arr[i];
  SetLength(Arr, Length(Arr) - 1);
end;

function TImageFileExecutionOptions.GetDebugger;
begin
  Result := Arr[ind];
end;

function TImageFileExecutionOptions.GetCount;
begin
  Result := Length(Arr);
end;

procedure DoInitialization;
const
  FileBasedActions: array [TFileBasedAction] of string = (
    '"%sActions\Ask.exe"',
    '"%sActions\Drop.exe" /IFEO',
    '"%sActions\Elevate.exe"',
    '"%sActions\PowerRequest.exe"',
    '"%sActions\PowerRequest.exe" /display',
    '"%sActions\Deny.exe"',
    '"%sActions\Deny.exe" /quiet');
var
  a: TAction;
  ActionsFolder, SysDrive: string;
begin
  ProcessIsElevated := ProcessUtils.IsElevated;
  SysDrive := '"' + GetEnvironmentVariable('SystemDrive');
  // TODO -cInstaller: Moving actions to Common Files
  ActionsFolder := ExtractFilePath(ParamStr(0));
  //ActionsFolder := GetEnvironmentVariable('CommonProgramW6432') + '\';

  for a := Low(FileBasedActions) to High(FileBasedActions) do
    EMDebuggers[a] := Format(FileBasedActions[a], [ActionsFolder]);

  EMDebuggers[aDenyNotFound] := '*';
  EMDebuggers[aDenyAccess] := '.';
  EMDebuggers[aDenyShared] := SysDrive + '\pagefile.sys"';
  EMDebuggers[aDenyExecute] := '""';
  EMDebuggers[aDenyNotWin32] := SysDrive + '\Windows\System32\ntoskrnl.exe"';
  EMDebuggers[aDenyNotValid] := SysDrive + '\Windows\System32\ntdll.dll"';
end;

initialization
  DoInitialization;
end.
