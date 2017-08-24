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

program emc;

{$APPTYPE CONSOLE}
{$WEAKLINKRTTI ON}

{$R *.res}

uses
  System.SysUtils,
  Winapi.Windows,
  System.Masks,
  IFEO in 'Include\IFEO.pas',
  ProcessUtils in 'Include\ProcessUtils.pas',
  CmdUtils in 'Include\CmdUtils.pas';

resourcestring
  USAGE = {$INCLUDE emcusage.txt};

procedure Help;
begin
  writeln(USAGE);
  ExitProcess(ERROR_BAD_COMMAND);
end;

procedure ActionQuery;
var
  Core: TImageFileExecutionOptions;
  i: integer;
begin
  try
    Core := TImageFileExecutionOptions.Create;
    for i := 0 to Core.Count - 1 do
    with Core[i] do
      begin
        if ParamCount >= 2 then
          if not MatchesMask(TreatedFile, ParamStr(2)) then
            Continue;
        writeln(Format('[*] %s --> %s', [TreatedFile, GetCaption]));
      end;
  finally
    FreeAndNil(Core);
  end;
end;

procedure ActionReset;
var
  Core: TImageFileExecutionOptions;
  i: integer;
begin
  Core := TImageFileExecutionOptions.Create;
  try
    for i := 0 to Core.Count - 1 do
    with Core[i] do
    begin
      if ParamCount >= 2 then
        if not MatchesMask(TreatedFile, ParamStr(2)) then
          Continue;
      writeln(Format('[-] Deleting action for %s', [TreatedFile]));
      Core.UnregisterDebugger(TreatedFile);
    end;
  finally
    FreeAndNil(Core);
  end;
end;

const
  ActionNames: array [TAction] of string = ('ask', 'deny', 'deny-quiet',
    'drop', 'elevate', 'nosleep', 'display-on', 'execute');

{ We don't need to parse this part of command line — user is free at using
  quotes and spaces now. }
function GetExec: string;
begin
  if ParamCount < 4 then
    raise Exception.Create('Need command line for "execute" action. See help.');
  Result := ParamsStartingFrom(4);
end;

procedure CheckForProblems(S: String);
const
  WARN = ' [y/n]: ';
var
  Answer: string;
  i: integer;
begin
  for i := Low(DangerousProcesses) to High(DangerousProcesses) do
    if LowerCase(S) = DangerousProcesses[i] then
    begin
      write(Format(WARN_SYSPROC + WARN, [S]));
      readln(Answer);
      if LowerCase(Answer) <> 'y' then
        raise Exception.Create('Canceled by user.');
      Break;
    end;

  for i := Low(CompatibilityProblems) to High(CompatibilityProblems) do
    if LowerCase(S) = CompatibilityProblems[i] then
    begin
      write(Format(WARN_COMPAT + WARN, [S]));
      readln(Answer);
      if LowerCase(Answer) <> 'y' then
        raise Exception.Create('Canceled by user.');
      break;
    end;
end;

procedure ActionSet;
var
  a: TAction;
  Dbg: TIFEORec;
begin
  if ParamCount < 3 then
    raise Exception.Create('Not enough parameters.');

  for a := Low(TAction) to High(TAction) do
    if LowerCase(ParamStr(3)) = ActionNames[a] then
      Break;
  if a = Succ(High(TAction)) then
    raise Exception.Create('Unknown action.');

  CheckForProblems(ParamStr(2));

  if a = aExecuteEx then
    Dbg := TIFEOREC.Create(a, ParamStr(2), GetExec)
  else
    Dbg := TIFEOREC.Create(a, ParamStr(2));
  writeln(Format('[+] %s --> %s', [Dbg.TreatedFile, Dbg.GetCaption]));
  TImageFileExecutionOptions.RegisterDebugger(Dbg);
end;

begin
  try
    write('ExecutionMaster ');
    {$IFDEF WIN64}
      write('x64');
    {$ELSE}
      write('x86');
    {$ENDIF}
    writeln(' [console] v0.8 Copyright (C) 2017 diversenok');
    if IsElevated then
      writeln('Current process: elevated')
    else
      writeln('Current process: non-elevated');
    writeln;

    if ParamCount = 0 then
      Help;

    if LowerCase(ParamStr(1)) = 'query' then
      ActionQuery
    else if LowerCase(ParamStr(1)) = 'set' then
      ActionSet
    else if LowerCase(ParamStr(1)) = 'reset' then
      ActionReset
    else
      Help;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
