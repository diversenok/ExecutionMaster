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

program Ask;

{$R *.res}

uses
  Winapi.Windows,
  ProcessUtils in '..\Include\ProcessUtils.pas',
  CmdUtils in '..\Include\CmdUtils.pas';

const
  FLAGS = MB_YESNO or MB_TOPMOST or MB_ICONWARNING; // MessageBox design

resourcestring
  CAPTION = 'Launch confirmation';
  TEXT = 'Confirm program to start:';

procedure Run;
begin
  if RunIgnoringIFEO(ParamsStartingFrom(1)) then
    RunElevated(ParamsStartingFrom(1))
  else
    ExitProcess(STATUS_DLL_INIT_FAILED);
end;

begin
  try
    // Actually, Image-File-Execution-Options always pass one or more parameters
    if ParamCount = 0 then
      ExitProcess(ERROR_INVALID_PARAMETER);

    { User can't normally interact with Session 0 (except UI0Detect, but we
      can't rely on it, and it also doesn't cover \Winlogon Desktop), so we
      automatically accept "Yes" in that case. If you want "No" — use Deny.exe
      instead. }
    if IsZeroSession or ParentRequestedElevation then
      Run
    else if MessageBoxW(0, PWideChar(WideString(Text) + #$D#$A +
      ParamsStartingFrom(1)), PWideChar(WideString(CAPTION)), FLAGS) = IDYES then
      Run;
  except
    ExitProcess(STATUS_DLL_INIT_FAILED);
  end;
end.

