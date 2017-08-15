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

unit IFEO;

interface

type
  TAction = (aAsk, aDeny, aDenySilent, aDrop, aElevate, aNoSleep, aDisplayOn,
    aExecuteEx);
  // Note: aExecuteEx should be the last action

const
  // In common case use GetCaption function of TIFEORec
  ActionCaptions: array [TAction] of string = ('Ask', 'Deny',
    'Deny (silent mode)', 'Drop admin rights', 'Elevate', 'No sleep until exit',
    'Force display on', 'Execute: ');

  /// <summary> You shouldn't mess with them. </summary>
  DangerousProcesses: array [0 .. 18] of string = ('csrss.exe', 'dwm.exe',
    'lsm.exe', 'logonui.exe', 'lsass.exe', 'services.exe', 'userinit.exe',
    'winlogon.exe', 'wininit.exe', 'smss.exe', 'svchost.exe', 'wlanext.exe',
    'conhost.exe', 'audiodg.exe', 'wlanext.exe', 'explorer.exe', 'dwm.exe',
    'consent.exe', 'dllhost.exe');

  /// <summary> Warning for <c>DangerousProcesses</c>. </summary>
  WARN_SYSPROC = '%s is a system process. Performing this action may ' +
    'cause system instability. Are you sure?';

  /// <summary> Some compatibility problems with specified processes. </summary>
  CompatibilityProblems: array [0 .. 2] of String = ('chrome.exe',
    'firefox.exe', 'browser.exe');

  /// <summary> Warning for <c>CompatibilityProblems</c>. </summary>
  WARN_COMPAT = 'There are several compatibility problems with setting ' +
  'actions on %s' + #$D#$A + 'This program may start to work incorrectly. ' +
  'Are you sure?';

type
  /// <summary>
  ///  Represents settings of a debugger to register with
  ///  Image-File-Execution-Options. Use constructor instead of setting values.
  /// </summary>
  TIFEORec = record
    Action: TAction;
    TreatedFile: string;
    ExecStr: string;
    constructor Create(AAction: TAction; const ATreatedFile: string;
      const AExecStr: string = ''); overload;
    constructor Create(const ATreatedFile, AExecStr: string); overload;
    function GetCaption: string;
  end;

  /// <summary>
  ///  Main class to querying/setting information related to IFEO.
  /// </summary>
  TImageFileExecutionOptions = class
  protected
  type
    TExecConfigArray = array of TIFEORec;
  var
    Arr: TExecConfigArray;
    class function GetKey(const ATreatedFile: string): string;
    /// <summary>
    ///  Escapes all quotes and last backslash for use with reg.exe
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

var
  /// <summary>
  ///  This handle is used with ShellExecuteEx.
  ///  Set it, if you have a main window.
  /// </summary>
  ElvationHandle: UIntPtr = 0;
  ProcessIsElevated: Boolean;

implementation

uses Winapi.Windows, System.Win.Registry, System.Classes, System.SysUtils,
  Winapi.ShellApi, ProcessUtils;

resourcestring
  ActionRel0 = '"%sActions\Ask.exe"';
  ActionRel1 = '"%sActions\Deny.exe"';
  ActionRel2 = '"%sActions\Deny.exe" /quiet';
  ActionRel3 = '"%sActions\Drop.exe" /IFEO';
  ActionRel4 = '"%sActions\Elevate.exe"';
  ActionRel5 = '"%sActions\PowerRequest.exe"';
  ActionRel6 = '"%sActions\PowerRequest.exe" /display';

const
  ActionsRelExe: array [TAction] of string = (ActionRel0, ActionRel1,
    ActionRel2, ActionRel3, ActionRel4, ActionRel5, ActionRel6, '');

var
  ActionsExe: array [TAction] of string;

  { ShellApi }

function ElevetedExecute(const AWnd: HWND; const AFileName: WideString;
  const AParameters: WideString = ''): Boolean;
var
  ExecInfo: TShellExecuteInfoW;
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
    nShow := SW_HIDE;
    fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_UNICODE;
    if AWnd <> 0 then
      fMask := fMask or SEE_MASK_FLAG_NO_UI;
  end;
  Result := ShellExecuteExW(@ExecInfo);
end;

  { TImageFileOptionsRec }

constructor TIFEORec.Create(AAction: TAction; const ATreatedFile: string;
  const AExecStr: string = '');
begin
  Action := AAction;
  TreatedFile := ATreatedFile;
  if AAction = aExecuteEx then
    ExecStr := AExecStr
  else
    ExecStr := ActionsExe[AAction];
end;

constructor TIFEORec.Create(const ATreatedFile, AExecStr: string);
var
  a: TAction;
begin
  TreatedFile := ATreatedFile;
  ExecStr := AExecStr;
  Action := aExecuteEx;
  for a := Low(ActionsExe) to Pred(High(ActionsExe)) do
    if AExecStr = ActionsExe[a] then
    begin
      Action := a;
      ExecStr := ActionsExe[a]; // reference to existing string, not a copy
      Break;
    end;
end;

function TIFEORec.GetCaption: string;
begin
  if Action = aExecuteEx then
    Result := ActionCaptions[aExecuteEx] + ExecStr
  else
    Result := ActionCaptions[Action];
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
  AllKeys, AllValues: TStringList;
  i: integer;
begin
  Result := True;
  reg := TRegistry.Create(KEY_READ);
  AllKeys := TStringList.Create;
  AllValues := TStringList.Create;
  try

    reg.RootKey := HKEY_LOCAL_MACHINE;
    if not reg.OpenKey(GetKey(ATreatedFile), False) then
      raise Exception.Create('DeleteValueOnly::TRegistry.OpenKey failed');

    // Collection all setting for specified program
    reg.GetKeyNames(AllKeys);
    reg.GetValueNames(AllValues);

    // Searching for settings that we don't want to delete
    Result := reg.ValueExists('') or (AllKeys.Count > 0);
    for i := 1 to AllValues.Count - 1 do
      if AllValues[i] <> REG_VALUE then
        Result := True;
  finally
    reg.Free;
    AllKeys.Free;
    AllValues.Free;
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
      reg.WriteString(REG_VALUE, Debugger.ExecStr); // can raise excetion itself
    finally
      reg.Free;
    end
  end
  else if not ElevetedExecute(ElvationHandle, REG_EXE, Format(PARAMS,
    [GetKey(Debugger.TreatedFile), EscapeStr(Debugger.ExecStr)]))
  then
    RaiseLastOSError;
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
  else if not ElevetedExecute(ElvationHandle, REG_EXE,
    Format(GetParams, [GetKey(ATreatedFile)])) then
    RaiseLastOSError;
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
  AllKeys: TStringList;
  i: integer;
begin
  SetLength(Arr, 0);
  reg := TRegistry.Create(KEY_READ);
  reg.RootKey := HKEY_LOCAL_MACHINE;
  if not reg.OpenKey(REG_KEY, False) then
    Exit;

  // Collecting all executables with special settings
  AllKeys := TStringList.Create;
  reg.GetKeyNames(AllKeys);
  reg.CloseKey;

  // Finding and saving debugged ones
  for i := 0 to AllKeys.Count - 1 do
  begin
    reg.OpenKey(REG_KEY + '\' + AllKeys[i], False);
    if reg.ValueExists(REG_VALUE) then
      case reg.GetDataType(REG_VALUE) of
        rdString, rdExpandString:
          Add(TIFEORec.Create(AllKeys[i], reg.ReadString(REG_VALUE)));
      end;
    reg.CloseKey;
  end;
  AllKeys.Free;
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

var
  a: TAction;

initialization
  ProcessIsElevated := ProcessUtils.IsElevated;
  for a := Low(ActionsExe) to Pred(High(ActionsExe)) do
    ActionsExe[a] := Format(ActionsRelExe[a], [ExtractFilePath(ParamStr(0))]);
  { ExtractFileDir behave different at drive root and other folders.
    So ExtractFilePath is better}
end.
