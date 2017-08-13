{ 2017 © diversenok@gmail.com }

program Drop;

{$R *.res}

uses
  Windows,
  Winsafer,
  ProcessUtils in '..\Include\ProcessUtils.pas',
  CmdUtils in '..\Include\CmdUtils.pas';

const
  IFEO_KEY = '/IFEO'; // Makes sure we were launched from IFEO

var
  IFEO_Enabled: Boolean;
  hLevel, hToken: THandle;

var
  StartFrom: integer;

begin
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

  if RunUnderDebuggerW(ParamsStartingFrom(StartFrom), hToken) then
    if IFEO_Enabled then
      RunElevatedW(ParamsStartingFrom(StartFrom))
    else // We can't rely on Image-File-Execution-Options
      RunElevatedW('"' + ParamStr(0) + '" ' + ParamsStartingFrom(1))
      { The only way to launch program with restricted but elevated token is to
      start it from another instance of Drop.exe with higher privileges.}
  else
    ExitThread(STATUS_DLL_INIT_FAILED);
end.
