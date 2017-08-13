{ 2017 © diversenok@gmail.com }

program ExecutionMaster;

uses
  Vcl.Forms,
  UI in 'UI.pas' {ExecListDialog},
  IFEO in 'Include\IFEO.pas',
  ProcessUtils in 'Include\ProcessUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TExecListDialog, ExecListDialog);
  Application.Run;
end.
