{ ExecutionMaster component.
  Copyright (C) 2018 diversenok

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/> }

program EMCShell;

{$WEAKLINKRTTI ON}
{$R *.res}

uses
  System.SysUtils,
  Winapi.Windows,
  IFEO in 'Include\IFEO.pas',
  Registry2 in 'Include\Registry2.pas',
  CmdUtils in 'Include\CmdUtils.pas',
  ProcessUtils in 'Include\ProcessUtils.pas',
  ShellExtension in 'Include\ShellExtension.pas',
  MessageDialog in 'Include\MessageDialog.pas';

const
  PROGRAM_NAME = 'Execution Master shell extension';

procedure ShowStatusMessage(Verb: String; Text: String = '';
  Icon: TMessageIcon = miInformation);
begin
  ShowMessageOk(PROGRAM_NAME, Verb, Text, Icon);
end;

procedure ActionReset;
var
  Core: TImageFileExecutionOptions;
  executable: String;
  i: integer;
begin
  executable := ExtractFileName(ParamStr(2));
  try
    Core := TImageFileExecutionOptions.Create;
    for i := 0 to Core.Count - 1 do
    begin
      if ParamCount >= 2 then
        if Core[i].TreatedFile <> executable then
          Continue;
      Core.UnregisterDebugger(Core[i].TreatedFile);
      Break;
    end;
  finally
    FreeAndNil(Core);
  end;
  ShowStatusMessage('The action was successfully reset.', executable);
end;

procedure CheckerUI(Text: string);
begin
  if ShowMessageYesNo(PROGRAM_NAME, 'Are you sure?', Text, miWarning) <> IDYES
    then
    raise Exception.Create('The operation was canceled by the user.');
end;

procedure CheckForProblems(S: String);
var
  i: integer;
begin
  for i := Low(DangerousProcesses) to High(DangerousProcesses) do
    if LowerCase(S) = DangerousProcesses[i] then
    begin
      CheckerUI(Format(WARN_SYSPROC, [S]));
      Break;
    end;

  for i := Low(CompatibilityProblems) to High(CompatibilityProblems) do
    if LowerCase(S) = CompatibilityProblems[i] then
    begin
      CheckerUI(Format(WARN_COMPAT, [S]));
      Break;
    end;
end;

procedure ActionSet;
var
  a: TAction;
  Dbg: TIFEORec;
  executable: string;
begin
  if ParamCount < 3 then
    raise Exception.Create('Not enough parameters.');

  for a := Low(TAction) to Pred(High(TAction)) do // not including aExecuteEx!
    if LowerCase(ParamStr(3)) = ActionShortNames[a] then
      Break;
  if a = High(TAction) then // for-cycle finished without breaking
    raise Exception.Create('Unknown action.');

  if a in [Low(TFileBasedAction)..High(TFileBasedAction)] then
    if not FileExists(Copy(EMDebuggers[a], 2,
      Pos('"', EMDebuggers[a], 2) - 2)) then // Only file without params
    raise Exception.Create(ERR_ACTION);

  executable := ExtractFileName(ParamStr(2));
  CheckForProblems(executable);
  Dbg := TIFEORec.Create(a, executable);
  TImageFileExecutionOptions.RegisterDebugger(Dbg);
  ShowStatusMessage('The action was successfully set.', executable + '  →  ' +
    Dbg.GetCaption);
end;

begin
  try
    if ParamCount >= 1 then
    begin
      if LowerCase(ParamStr(1)) = 'set' then
        ActionSet
      else if LowerCase(ParamStr(1)) = 'reset' then
        ActionReset
      else if LowerCase(ParamStr(1)) = '/reg' then
      begin
        RegShellMenu(ParamStr(0));
        ShowStatusMessage('Shell extension was successfully registered.');
      end
      else if LowerCase(ParamStr(1)) = '/unreg' then
      begin
        UnregShellMenu;
        ShowStatusMessage('Shell extension was successfully unregistered.');
      end;
    end
    else
      ShowStatusMessage('Usage:',
        'EMCShell.exe /reg - register shell extension;'#$D#$A +
        'EMCShell.exe /unreg - unregister shell extension.'#$D#$A);
  except
    on E: Exception do
      ShowStatusMessage('The action was not registered:', E.ToString, miError);
  end;
end.
