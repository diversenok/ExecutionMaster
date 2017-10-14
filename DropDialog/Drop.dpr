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

program Drop;

{$R *.res}

uses
  Winapi.Windows,
  Winapi.Winsafer,
  ProcessUtils in '..\Include\ProcessUtils.pas',
  CmdUtils in '..\Include\CmdUtils.pas';

//TODO: Set integrity to medium. See tokprp.c near line 870 from ProcessHacker

const
  IFEO_KEY = '/IFEO'; // Makes sure we were launched from IFEO

var
  IFEO_Enabled: Boolean;
  hLevel, hToken: THandle;

var
  StartFrom: integer;

begin
  try
    // Actually, Image-File-Execution-Options always pass one or more parameters
    if ParamCount = 0 then
      ExitProcess(ERROR_INVALID_PARAMETER);

    // making sure we were launched by IFEO
    IFEO_Enabled := ParamStr(1) = IFEO_KEY;
    if IFEO_Enabled and (ParamCount = 1) then
      ExitProcess(ERROR_INVALID_PARAMETER);

    if IFEO_Enabled then
      StartFrom := 2
    else
      StartFrom := 1;

    // Trying to handle it without UAC
    SetEnvironmentVariable('__COMPAT_LAYER', 'RunAsInvoker');

    // Creating restricted token
    if not SaferCreateLevel(SAFER_SCOPEID_USER, SAFER_LEVELID_NORMALUSER,
      SAFER_LEVEL_OPEN, hLevel, nil) then
      ExitProcess(STATUS_DLL_INIT_FAILED);
    if not SaferComputeTokenFromLevel(hLevel, 0, @hToken, 0, nil) then
      ExitProcess(STATUS_DLL_INIT_FAILED);
    SaferCloseLevel(hLevel);

    if RunIgnoringIFEO(ParamsStartingFrom(StartFrom), hToken) then
      if IFEO_Enabled then
        RunElevated(ParamsStartingFrom(StartFrom))
      else // We can't rely on Image-File-Execution-Options
        RunElevated('"' + ParamStr(0) + '" ' + ParamsStartingFrom(1))
        { The only way to launch program with restricted but elevated token is to
        start it from another instance of Drop.exe with higher privileges.}
    else
      ExitProcess(STATUS_DLL_INIT_FAILED);
  except
    ExitProcess(STATUS_DLL_INIT_FAILED);
  end;
end.
