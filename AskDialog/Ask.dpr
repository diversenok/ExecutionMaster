{ 2017 © diversenok@gmail.com }

program Ask;

{$R *.res}

uses
  Windows,
  ProcessUtils in '..\Include\ProcessUtils.pas',
  CmdUtils in '..\Include\CmdUtils.pas';

const
  FLAGS = MB_YESNO or MB_TOPMOST or MB_ICONWARNING; // MessageBox design

resourcestring
  CAPTION = 'Launch confirmation';
  TEXT = 'Confirm program to start:';

procedure Run;
begin
  if RunUnderDebuggerW(ParamsStartingFrom(1)) then
    RunElevatedW(ParamsStartingFrom(1), True)
  else
    ExitProcess(STATUS_DLL_INIT_FAILED);
end;

begin
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
end.

