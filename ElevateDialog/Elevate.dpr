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

program Elevate;

{$R *.res}

uses
  Winapi.Windows,
  ProcessUtils in '..\Include\ProcessUtils.pas',
  CmdUtils in '..\Include\CmdUtils.pas',
  SysUtils.Min in '..\Include\SysUtils.Min.pas';

var
  hToken: THandle;

begin
  // Actually, Image-File-Execution-Options always pass one or more parameters
  ExitCode := ERROR_INVALID_PARAMETER;
  if ParamCount = 0 then
    Exit;

  ExitCode := STATUS_DLL_INIT_FAILED; // It will be overwritten on success
  if IsElevated then
  begin
    if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY or TOKEN_ASSIGN_PRIMARY
      or TOKEN_DUPLICATE,
      hToken) then
    begin
      RunIgnoringIFEOAndWait(ParamsStartingFrom(1), hToken);
      CloseHandle(hToken);
    end
    else
      LogError(GetLastError, 'OpenProcessToken');
  end
  else
    RunElevatedAndWait(ParamsStartingFrom(1));
end.
