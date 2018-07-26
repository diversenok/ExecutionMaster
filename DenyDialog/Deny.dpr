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

program Deny;

{$R *.res}

uses
  Winapi.Windows,
  ProcessUtils in '..\Include\ProcessUtils.pas',
  CmdUtils in '..\Include\CmdUtils.pas',
  MessageDialog in '..\Include\MessageDialog.pas';

// Since try..except doesn't work without System.SysUtils
// we should handle all exceptions on our own.
function HaltOnException(P: PExceptionRecord): IntPtr;
begin
  Halt(STATUS_UNHANDLED_EXCEPTION);
end;

const
  KEY_QUIET = '/quiet'; // Parameter: do not show dialog

resourcestring
  CAPTION = 'Execution Master: an attempt to run a blocked program';
  VERB = 'This program is not allowed to run:';

begin
  ExceptObjProc := @HaltOnException;
  ExitCode := STATUS_DLL_INIT_FAILED;
  if ParamStr(1) = KEY_QUIET then
    Exit;

  { User can't normally interact with Session 0 (except UI0Detect, but we
    can't rely on it, and it also doesn't cover \Winlogon Desktop), so we
    wouldn't show any messages in that case. }
  if not IsZeroSession then
    ShowMessageOk(CAPTION, VERB, ParamsStartingFrom(1), miError);
end.

