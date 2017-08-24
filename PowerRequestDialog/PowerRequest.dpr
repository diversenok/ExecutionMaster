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

program PowerRequest;

{$R *.res}

uses
  Winapi.Windows,
  CmdUtils in '..\Include\CmdUtils.pas',
  ProcessUtils in '..\Include\ProcessUtils.pas';

const
  KEY_DISPLAY = '/display';

var
  StartFrom: integer;

begin
  try
    // Actually, Image-File-Execution-Options always pass one or more parameters
    if ParamCount = 0 then
      ExitProcess(ERROR_INVALID_PARAMETER);

    if ParamStr(1) = KEY_DISPLAY then
    begin
      if ParamCount = 1 then
        ExitProcess(ERROR_INVALID_PARAMETER);
      StartFrom := 2;
      SetThreadExecutionState(ES_DISPLAY_REQUIRED or ES_CONTINUOUS);
    end
    else
    begin
      StartFrom := 1;
      SetThreadExecutionState(ES_SYSTEM_REQUIRED or ES_CONTINUOUS);
    end;

    if RunIgnoringIFEO(ParamsStartingFrom(StartFrom)) then
      RunElevated(ParamsStartingFrom(StartFrom))
    else
      ExitProcess(STATUS_DLL_INIT_FAILED);
  except
    ExitProcess(STATUS_DLL_INIT_FAILED);
  end;
end.
