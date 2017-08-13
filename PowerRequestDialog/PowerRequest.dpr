{ 2017 © diversenok@gmail.com }

program PowerRequest;

{$R *.res}

uses
  Windows,
  CmdUtils in '..\Include\CmdUtils.pas',
  ProcessUtils in '..\Include\ProcessUtils.pas';

const
  KEY_DISPLAY = '/display';

var
  StartFrom: integer;

begin
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

  if RunUnderDebuggerW(ParamsStartingFrom(StartFrom)) then
    RunElevatedW(ParamsStartingFrom(StartFrom))
  else
    ExitProcess(STATUS_DLL_INIT_FAILED);
end.
