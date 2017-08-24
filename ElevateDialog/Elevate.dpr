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

program Elevate;

{$R *.res}

uses
  Winapi.Windows,
  ProcessUtils in '..\Include\ProcessUtils.pas',
  CmdUtils in '..\Include\CmdUtils.pas';

begin
  try
    // Actually, Image-File-Execution-Options always pass one or more parameters
    if ParamCount = 0 then
      ExitProcess(ERROR_INVALID_PARAMETER);

    if IsElevated then
      RunIgnoringIFEO(ParamsStartingFrom(1))
    else
      RunElevated(ParamsStartingFrom(1));
  except
    ExitProcess(STATUS_DLL_INIT_FAILED);
  end;
end.
