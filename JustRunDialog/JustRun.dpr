{ ExecutionMaster component.
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
  along with this program.  If not, see <http://www.gnu.org/licenses/> }

program JustRun;

{$R *.res}

uses
  Winapi.Windows,
  Winapi.ShellApi,
  CmdUtils in '..\Include\CmdUtils.pas',
  ProcessUtils in '..\Include\ProcessUtils.pas',
  SysUtils.Min in '..\Include\SysUtils.Min.pas';

resourcestring
  NO_WAIT = '/nowait';

function RunIgnoringIFEOAndNoWait(const Cmd: WideString): Cardinal;
var
  PI: TProcessInformation;
begin
  Result := RunIgnoringIFEO(PI, Cmd);
  if Result = ERROR_SUCCESS then
  begin
    CloseHandle(PI.hProcess);
    CloseHandle(PI.hThread);
  end;
end;

function RunElevatedAndNoWait(const Cmd: WideString): Cardinal;
var
  EI: TShellExecuteInfoW;
  ElevationMutex: THandle;
begin
  Result := RunElevated(EI, ElevationMutex, Cmd);
  if Result = ERROR_SUCCESS then
  begin
    CloseHandle(EI.hProcess);
    CloseHandle(ElevationMutex);
  end;
end;

begin
  if ParamCount = 0 then
    Halt(ERROR_INVALID_PARAMETER);

  if ParamStr(1) = NO_WAIT then
  begin
    if ParamCount < 2 then
      Halt(ERROR_INVALID_PARAMETER);

    if RunIgnoringIFEOAndNoWait(ParamsStartingFrom(2)) =
      ERROR_ELEVATION_REQUIRED then
      RunElevatedAndNoWait(ParamsStartingFrom(2));
  end
  else
  begin
    if RunIgnoringIFEOAndWait(ParamsStartingFrom(1)) =
      ERROR_ELEVATION_REQUIRED then
      RunElevatedAndWait(ParamsStartingFrom(1));
  end;
end.
