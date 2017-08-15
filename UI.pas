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

unit UI;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  VCL.Graphics, VCL.Controls, VCL.Forms, VCL.Dialogs, VCL.ComCtrls,
  VCL.StdCtrls, VCL.ExtCtrls, VCL.Buttons, IFEO;

type
  TExecListDialog = class(TForm)
    PanelRight: TPanel;
    GroupBoxAction: TGroupBox;
    ListViewExec: TListView;
    EditImage: TEdit;
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
  WARN_SYSPROC_CAPTION = 'System process';
  WARN_COMPAT_CAPTION = 'Compatibility problems';

  ERR_ONLYNAME = '"Executable name" should contain only file name, not a path.';
  ERR_ONLYNAME_CAPTION = 'Executable name';

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
    EditImage.Text := ExtractFileName(OpenDlg.FileName);
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
        EditImage.Text := TreatedFile;
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
  if (Length(EditImage.Text) = 0) or (Pos('\', EditImage.Text) <> 0) or
     (Pos('/', EditImage.Text) <> 0) or (Pos('"', EditImage.Text) <> 0) then
  begin
    MessageBox(Handle, PChar(ERR_ONLYNAME), PChar(ERR_ONLYNAME_CAPTION),
     MB_OK or MB_ICONERROR);
    Exit;
  end;

  for i := Low(DangerousProcesses) to High(DangerousProcesses) do
    if LowerCase(EditImage.Text) = DangerousProcesses[i] then
      if MessageBox(Handle, PChar(Format(WARN_SYSPROC, [EditImage.Text])),
        PChar(WARN_SYSPROC_CAPTION), MB_YESNO or MB_ICONWARNING) <> IDYES then
        Exit;

  for i := Low(CompatibilityProblems) to High(CompatibilityProblems) do
    if LowerCase(EditImage.Text) = CompatibilityProblems[i] then
      if MessageBox(Handle, PChar(Format(WARN_COMPAT, [EditImage.Text])),
        PChar(WARN_COMPAT_CAPTION), MB_YESNO or MB_ICONWARNING) <> IDYES then
        Exit;

  Core.AddDebugger(TIFEORec.Create(GetTAction, EditImage.Text,
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
