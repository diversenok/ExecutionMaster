{ 2017 © diversenok@gmail.com }

unit UI;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Buttons, IFEO;

type
  TExecListDialog = class(TForm)
    PanelRight: TPanel;
    GroupBoxAction: TGroupBox;
    ListViewExec: TListView;
    EditImagePath: TEdit;
    LabelImagePath: TLabel;
    ButtonBrowse: TButton;
    EditExec: TEdit;
    ButtonBrowseExec: TButton;
    OpenDlg: TOpenDialog;
    LabelNote: TLabel;
    PanelLeft: TPanel;
    PanelBottom: TPanel;
    ButtonRefresh: TBitBtn;
    ButtonDelete: TButton;
    ButtonAdd: TButton;
    PanelAdd: TPanel;
    procedure ActionButtonsClick(Sender: TObject);
    procedure ButtonBrowseClick(Sender: TObject);
    procedure ButtonBrowseExecClick(Sender: TObject);
    procedure Refresh(Sender: TObject);
    procedure ButtonAddClick(Sender: TObject);
    procedure ButtonDeleteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ListViewExecChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
  private
    Core: TImageFileExecutionOptions;
    ActionButtons: array [TAction] of TRadioButton;
    function GetTAction: TAction;
  end;

var
  ExecListDialog: TExecListDialog;

implementation

uses ProcessUtils;

const
  WARN_SYSTPROC = '%s is a system process. Performing this action may ' +
    'cause system instability. Are you sure?';
  WARN_SYSTPROC_CAPTION = 'System process';

  ActionHints: array [TAction] of string =
    ('Ask user permission to launch executable',
     'Deny process to start and notify user',
     'Deny process to start without notification',
     'Drop administrative privileges of process',
     'Elevates process to run as Administrator',
     'Force computer not to sleep until process exits',
     'Force display to be on until process exits',
     'Execute another program instead');

{$R *.dfm}

procedure TExecListDialog.ActionButtonsClick(Sender: TObject);
begin
  EditExec.Enabled := ActionButtons[aExecuteEx].Checked;
  ButtonBrowseExec.Enabled := ActionButtons[aExecuteEx].Checked;
end;

procedure TExecListDialog.ButtonBrowseClick(Sender: TObject);
begin
  if OpenDlg.Execute then
    EditImagePath.Text := ExtractFileName(OpenDlg.FileName);
end;

procedure TExecListDialog.ButtonBrowseExecClick(Sender: TObject);
begin
  if OpenDlg.Execute then
    EditExec.Text := '"' + OpenDlg.FileName + '"';
end;

procedure TExecListDialog.Refresh(Sender: TObject);
var
  i: integer;
begin
  if (Sender <> ButtonAdd) and (Sender <> ButtonDelete) then
  begin
    Core.Free;
    Core := TImageFileExecutionOptions.Create;
  end;
  ListViewExec.Items.BeginUpdate;
  ListViewExec.Items.Clear;
  for i := 0 to Core.Count - 1 do
    with ListViewExec.Items.Add do
    begin
      Caption := Core.Debuggers[i].TreatedFile;
      if Core.Debuggers[i].Action = aExecuteEx then
        SubItems.Add(ActionCaptions[Core.Debuggers[i].Action] +
          Core.Debuggers[i].ExecStr)
      else
        SubItems.Add(ActionCaptions[Core.Debuggers[i].Action]);
    end;
  ListViewExec.Items.EndUpdate;
end;

function TExecListDialog.GetTAction;
var
  a: TAction;
begin
  Result := aExecuteEx;
  for a := Low(ActionButtons) to High(ActionButtons) do
    if ActionButtons[a].Checked then
    begin
      Result := a;
      Break;
    end;
end;

procedure TExecListDialog.ListViewExecChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
  if Change = ctState then
  begin
    ButtonDelete.Enabled := ListViewExec.SelCount <> 0;
    if ListViewExec.SelCount <> 0 then
      with Core.Debuggers[ListViewExec.Selected.Index] do
      begin
        EditImagePath.Text := TreatedFile;
        ActionButtons[Action].Checked := True;
        if Action = aExecuteEx then
          EditExec.Text := ExecStr;
      end;
  end;
end;

procedure TExecListDialog.ButtonAddClick(Sender: TObject);
var
  i: integer;
begin
  for i := Low(DangerousProcesses) to High(DangerousProcesses) do
    if LowerCase(EditImagePath.Text) = DangerousProcesses[i] then
      if MessageBox(Handle, PChar(Format(WARN_SYSTPROC, [EditImagePath.Text])),
        PChar(WARN_SYSTPROC_CAPTION), MB_YESNO or MB_ICONWARNING) <> IDYES then
        Exit;
  Core.AddDebugger(TIFEORec.Create(GetTAction, EditImagePath.Text,
    EditExec.Text));
  Refresh(ButtonAdd);
  ListViewExecChange(Sender, ListViewExec.Selected, ctState);
end;

procedure TExecListDialog.ButtonDeleteClick(Sender: TObject);
begin
  if ListViewExec.SelCount = 0 then
  begin
    ListViewExecChange(Sender, ListViewExec.Selected, ctState);
    Exit;
  end;
  Core.DeleteDebugger(ListViewExec.Selected.Index);
  Refresh(ButtonDelete);
  ListViewExecChange(Sender, ListViewExec.Selected, ctState);
end;

procedure TExecListDialog.FormCreate(Sender: TObject);
const
  BCM_SETSHIELD = $160C;
var
  a: TAction;
begin
  ElvationHandle := Handle;
  for a := Low(ActionButtons) to High(ActionButtons) do
  begin
    ActionButtons[a] := TRadioButton.Create(GroupBoxAction);
    ActionButtons[a].Caption := ActionCaptions[a];
    ActionButtons[a].Width := 220;
    ActionButtons[a].Top := 20 + 21 * Integer(a);
    ActionButtons[a].Left := 10;
    ActionButtons[a].Parent := GroupBoxAction;
    ActionButtons[a].OnClick := ActionButtonsClick;
    ActionButtons[a].Hint := ActionHints[a];
  end;
  ActionButtons[Low(ActionButtons)].Checked := True;
  EditExec.Top := 22 + 21 * Length(ActionButtons);
  LabelNote.Top := 50 + 21 * Length(ActionButtons);
  ButtonBrowseExec.Top := 50 + 21 * Length(ActionButtons);
  GroupBoxAction.Height := 96 + 21 * Length(ActionButtons);
  ClientHeight := GroupBoxAction.Top + GroupBoxAction.Height + 3;
  Constraints.MinHeight := Height;
  if not ProcessIsElevated then
  begin
    SendMessage(ButtonDelete.Handle, BCM_SETSHIELD, 0, 1);
    SendMessage(ButtonAdd.Handle, BCM_SETSHIELD, 0, 1);
  end;

  Refresh(Sender);
end;

end.
