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
  CmdUtils in '..\Include\CmdUtils.pas';

const
  FLAGS = MB_YESNO or MB_TOPMOST or MB_ICONWARNING; // MessageBox design

resourcestring
  CAPTION = 'User''s approvement is required';
  TEXT = 'Confirm the program to start:';

procedure Run;
begin
  if RunIgnoringIFEOAndWait(ParamsStartingFrom(1)) = pcsElevationRequired then
    RunElevatedAndWait(ParamsStartingFrom(1));
end;

begin
  try
    // Actually, Image-File-Execution-Options always pass one or more parameters
    ExitCode := ERROR_INVALID_PARAMETER;
    if ParamCount = 0 then
      Exit;

    ExitCode := STATUS_DLL_INIT_FAILED; // Run overwrites it on success

    { User can't normally interact with Session 0 (except UI0Detect, but we
      can't rely on it, and it also doesn't cover \Winlogon Desktop), so we
      automatically accept "Yes" in that case. If you want "No" — use Deny.exe
      instead. }
    if IsZeroSession or ParentRequestedElevation then
      Run
    else if MessageBoxW(0, PWideChar(Text + #$D#$A + ParamsStartingFrom(1)),
      PWideChar(CAPTION), FLAGS) = IDYES then
      Run;
  except
    ExitCode := STATUS_UNHANDLED_EXCEPTION;
  end;
end.

