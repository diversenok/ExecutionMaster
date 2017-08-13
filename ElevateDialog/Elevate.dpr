{ 2017 © diversenok@gmail.com }

program Elevate;

{$R *.res}

uses
  Windows,
  ProcessUtils in '..\Include\ProcessUtils.pas',
  CmdUtils in '..\Include\CmdUtils.pas';

begin
  // Actually, Image-File-Execution-Options always pass one or more parameters
  if ParamCount = 0 then
    ExitProcess(ERROR_INVALID_PARAMETER);

  if IsElevated then
    RunUnderDebuggerW(ParamsStartingFrom(1))
  else
    RunElevatedW(ParamsStartingFrom(1));
end.
