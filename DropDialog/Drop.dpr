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

program Drop;

{$R *.res}

uses
  Winapi.Windows,
  Winapi.Winsafer,
  ProcessUtils in '..\Include\ProcessUtils.pas',
  CmdUtils in '..\Include\CmdUtils.pas';

// Since try..except doesn't work without System.SysUtils
// we should handle all exceptions on our own.
function HaltOnException(P: PExceptionRecord): IntPtr;
begin
  Halt(STATUS_UNHANDLED_EXCEPTION);
end;

const
  IFEO_KEY = '/IFEO'; // Makes sure we were launched from IFEO

var
  IFEO_Enabled: Boolean;
  StartFrom: integer;
  hLevel, hToken: THandle;
  UIAccess: DWORD;

begin
  ExceptObjProc := @HaltOnException;

  // Actually, Image-File-Execution-Options always pass one or more parameters
  ExitCode := ERROR_INVALID_PARAMETER;
  if ParamCount = 0 then
    Exit;

  // making sure we were launched by IFEO
  IFEO_Enabled := ParamStr(1) = IFEO_KEY;
  if IFEO_Enabled and (ParamCount = 1) then
    Exit;

  if IFEO_Enabled then
    StartFrom := 2
  else
    StartFrom := 1;

  ExitCode := STATUS_DLL_INIT_FAILED; // It will be overwritten on success

  // Trying to handle it without UAC
  SetEnvironmentVariable('__COMPAT_LAYER', 'RunAsInvoker');

  // Creating restricted token
  if not SaferCreateLevel(SAFER_SCOPEID_USER, SAFER_LEVELID_NORMALUSER,
    SAFER_LEVEL_OPEN, hLevel, nil) then
    Exit;
  if not SaferComputeTokenFromLevel(hLevel, 0, @hToken, 0, nil) then
    Exit;
  SaferCloseLevel(hLevel);

  // Now we should fix the integrity level and set it to medium
  SetTokenIntegrity(hToken, ilMedium);

  // And also disable UIAccess flag
  UIAccess := 0;
  SetTokenInformation(hToken, TokenUIAccess, @UIAccess, SizeOf(UIAccess));

  if RunIgnoringIFEOAndWait(ParamsStartingFrom(StartFrom), hToken) =
    pcsElevationRequired then
  begin
    if IFEO_Enabled then
      RunElevatedAndWait(ParamsStartingFrom(StartFrom))
    else // We can't rely on Image-File-Execution-Options
      RunElevatedAndWait('"' + ParamStr(0) + '" ' + ParamsStartingFrom(1))
      { In this case the only way to launch the program with restricted but
        elevated token is to start it from another instance of Drop.exe
        with higher privileges.}
  end;
  CloseHandle(hToken);
end.
