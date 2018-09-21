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

program Ask;

{$R *.res}

uses
  Winapi.Windows,
  ProcessUtils in '..\Include\ProcessUtils.pas',
  CmdUtils in '..\Include\CmdUtils.pas',
  MessageDialog in '..\Include\MessageDialog.pas',
  SysUtils.Min in '..\Include\SysUtils.Min.pas';

resourcestring
  CAPTION = 'Execution Master: approval is required';
  VERB = 'Do you want to run this program?';
  YES_KEY = '/yes'; // don't ask the user

procedure Run;
begin
  if ParamCount = 0 then
  begin
    ExitCode := ERROR_INVALID_PARAMETER;
    Exit;
  end;

  if RunIgnoringIFEOAndWait(ParamsStartingFrom(1)) = pcsElevationRequired then
    RunElevatedAndWait(ParamsStartingFrom(1));
end;

begin
  ExitCode := STATUS_DLL_INIT_FAILED; // Run overwrites it on success

  { User can't normally interact with Session 0 (except UI0Detect, but we
    can't rely on it, and it also doesn't cover \Winlogon Desktop), so we
    automatically accept "Yes" in that case. If you want "No" — use Deny.exe
    instead. }
  if IsZeroSession or ParentRequestedElevation then
    Run
  else if ShowMessageYesNo(CAPTION, VERB, ParamsStartingFrom(1), miWarning) =
    IDYES then
    Run;
end.
