{ 2017 © diversenok@gmail.com }

program Deny;

{$R *.res}

uses
  Windows,
  ProcessUtils in '..\Include\ProcessUtils.pas',
  CmdUtils in '..\Include\CmdUtils.pas';

const
  FLAGS = MB_OK or MB_TOPMOST or MB_ICONSTOP; // MessageBox design
  KEY_QUIET = '/quiet'; // Parameter: do not show dialog

resourcestring
  CAPTION = 'Launch rejected';
  TEXT = 'Program start denied:';

begin
  if ParamCount = 0 then
    ExitProcess(ERROR_INVALID_PARAMETER);

  if ParamStr(1) = KEY_QUIET then
    ExitProcess(STATUS_DLL_INIT_FAILED);

  { User can't normally interact with Session 0 (except UI0Detect, but we
    can't rely on it, and it also doesn't cover \Winlogon Desktop), so we
    wouldn't show any messages in that case. }
  if not IsZeroSession then
    MessageBoxW(0, PWideChar(WideString(Text) + #$D#$A +
      WideString(ParamsStartingFrom(1))), PWideChar(WideString(CAPTION)), FLAGS);
   ExitProcess(STATUS_DLL_INIT_FAILED);
end.

