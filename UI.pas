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

unit UI;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  VCL.Graphics, VCL.Controls, VCL.Forms, VCL.Dialogs, VCL.ComCtrls,
  VCL.StdCtrls, VCL.ExtCtrls, VCL.Buttons, Vcl.Menus, IFEO;

type
  TExecListDialog = class(TForm)
    PanelRight: TPanel;
    GroupBoxActions: TGroupBox;
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
    MainMenu: TMainMenu;
    MenuFile: TMenuItem;
    MenuRunAsAdmin: TMenuItem;
    MenuSource: TMenuItem;
    N1: TMenuItem;
    MenuReg: TMenuItem;
    MenuUnreg: TMenuItem;
    N2: TMenuItem;
    PanelTopRight: TPanel;
    RadioButtonAsk: TRadioButton;
    RadioButtonBlock: TRadioButton;
    RadioButtonElevate: TRadioButton;
    RadioButtonNoSleep: TRadioButton;
    RadioButtonDisplayOn: TRadioButton;
    RadioButtonDrop: TRadioButton;
    RadioButtonError: TRadioButton;
    ComboBoxErrorCodes: TComboBox;
    RadioButtonExecute: TRadioButton;
    procedure ButtonBrowseClick(Sender: TObject);
    procedure ButtonBrowseExecClick(Sender: TObject);
    procedure RadioButtonClick(Sender: TObject);
    procedure ComboBoxErrorCodesClick(Sender: TObject);
    procedure Refresh(Sender: TObject);
    procedure ButtonAddClick(Sender: TObject);
    procedure ButtonDeleteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ListViewExecChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure MenuRunAsAdminClick(Sender: TObject);
    procedure MenuRegClick(Sender: TObject);
    procedure MenuUnregClick(Sender: TObject);
    procedure MenuSourceClick(Sender: TObject);
  private
    Core: TImageFileExecutionOptions;
    CurrentAction: TAction;
    procedure DisableActions;
  end;

var
  ExecListDialog: TExecListDialog;

implementation

uses ProcessUtils, Winapi.ShellApi, ShellExtension;

const
  GITHUB_PAGE = 'https://github.com/diversenok/ExecutionMaster';

  ERR_ONLYNAME = '"Executable name" should contain only file name, not a path.';
  ERR_ONLYNAME_CAPTION = 'Executable name';
  ERR_ACTION_CAPTION = 'Specified action not found';
  ERR_EMCSHELL = 'EMCShell component is missing.';
  ERR_WOW64 = 'Looks like you are using a 32-bit version of the program on a ' +
    '64-bit operating system. You should use the 64-bit version of ' +
    'ExecutionMaster, otherwise, only denial actions will be available.';
  ERR_WOW64_CAPTION = 'WOW64 is detected';

  INFO_REG = 'Shell extension was successfully registered.';
  INFO_UNREG = 'Shell extension was successfully uninstalled.';
  INFO_REG_CAPTION = 'Success';

{$R *.dfm}

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

procedure TExecListDialog.RadioButtonClick(Sender: TObject);
begin
  if Sender is TRadioButton then
    CurrentAction := TAction((Sender as TRadioButton).Tag);

  if RadioButtonError.Checked then
    CurrentAction := TAction(Integer(aDenySilently) +
      ComboBoxErrorCodes.ItemIndex);

  EditExec.Enabled := RadioButtonExecute.Checked;
  ButtonBrowseExec.Enabled := RadioButtonExecute.Checked;
end;

procedure TExecListDialog.ComboBoxErrorCodesClick(Sender: TObject);
begin
  RadioButtonError.Checked := True;
  RadioButtonClick(RadioButtonError);
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
      SubItems.Add(Core.Debuggers[i].GetCaption)
    end;
  ListViewExec.Items.EndUpdate;
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
        case Action of
          aAsk: RadioButtonAsk.Checked := True;
          aDrop: RadioButtonDrop.Checked := True;
          aElevate: RadioButtonElevate.Checked := True;
          aNoSleep: RadioButtonNoSleep.Checked := True;
          aDisplayOn: RadioButtonDisplayOn.Checked := True;
          aDenyAndNotify: RadioButtonBlock.Checked := True;
          aDenySilently..aDenyNotWin32:
          begin
            RadioButtonError.Checked := True;
            ComboBoxErrorCodes.ItemIndex := Integer(Action) - Integer(aDenySilently);
          end;
          aExecuteEx:
          begin
            RadioButtonExecute.Checked := True;
            EditExec.Text := DebuggerStr;
          end;
        end;
      end;
  end;
end;

procedure TExecListDialog.ButtonAddClick(Sender: TObject);
var
  i: integer;
begin
  if CurrentAction in [Low(TFileBasedAction)..High(TFileBasedAction)] then
    if not FileExists(Copy(EMDebuggers[CurrentAction], 2,
      Pos('"', EMDebuggers[CurrentAction], 2) - 2)) then // Only file without params
      begin
        MessageBox(Handle, PChar(ERR_ACTION), PChar(ERR_ACTION_CAPTION),
         MB_OK or MB_ICONERROR);
        Exit;
      end;

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

  if CurrentAction in [aAsk..aDisplayOn, aExecuteEx] then
    for i := Low(CompatibilityProblems) to High(CompatibilityProblems) do
      if LowerCase(EditImage.Text) = CompatibilityProblems[i] then
        if MessageBox(Handle, PChar(Format(WARN_COMPAT, [EditImage.Text])),
          PChar(WARN_COMPAT_CAPTION), MB_YESNO or MB_ICONWARNING) <> IDYES then
          Exit;

  Core.AddDebugger(TIFEORec.Create(CurrentAction, EditImage.Text,
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

procedure TExecListDialog.DisableActions;
begin
  RadioButtonAsk.Enabled := False;
  RadioButtonDrop.Enabled := False;
  RadioButtonElevate.Enabled := False;
  RadioButtonNoSleep.Enabled := False;
  RadioButtonDisplayOn.Enabled := False;
  RadioButtonBlock.Checked := True;
end;

procedure TExecListDialog.FormCreate(Sender: TObject);
const
  BCM_SETSHIELD = $160C;
var
  IsWow64: LongBool;
begin
  if IsWow64Process(GetCurrentProcess, IsWow64) and IsWow64 then
  begin
    MessageBox(Handle, ERR_WOW64, ERR_WOW64_CAPTION, MB_OK or MB_ICONWARNING);
    DisableActions;
  end;

  ElvationHandle := Handle;
  Application.HintHidePause := 20000;
  Constraints.MinHeight := Height;
  MenuRunAsAdmin.Enabled := not ProcessIsElevated;
  if not ProcessIsElevated then
  begin // UAC Shield on buttons
    SendMessage(ButtonDelete.Handle, BCM_SETSHIELD, 0, 1);
    SendMessage(ButtonAdd.Handle, BCM_SETSHIELD, 0, 1);
  end;
  Refresh(Sender);
end;

{ Menu items}

procedure TExecListDialog.MenuRunAsAdminClick(Sender: TObject);
begin
  ElevetedExecute(Handle, ParamStr(0), '', False, SW_SHOWNORMAL);
  Close;
end;

procedure TExecListDialog.MenuRegClick(Sender: TObject);
begin
  if not FileExists(ExtractFilePath(ParamStr(0)) + 'EMCShell.exe') then
    raise Exception.Create(ERR_EMCSHELL);  
  RegShellMenu(ExtractFilePath(ParamStr(0)) + 'EMCShell.exe');
  MessageBox(Handle, INFO_REG, INFO_REG_CAPTION, MB_OK or MB_ICONINFORMATION);
end;

procedure TExecListDialog.MenuUnregClick(Sender: TObject);
begin
  UnregShellMenu;
  MessageBox(Handle, INFO_UNREG, INFO_REG_CAPTION, MB_OK or MB_ICONINFORMATION);
end;

procedure TExecListDialog.MenuSourceClick(Sender: TObject);
var
  ExecInfo: TShellExecuteInfoW;
begin
  FillChar(ExecInfo, SizeOf(ExecInfo), 0);
  with ExecInfo do
  begin
    cbSize := SizeOf(ExecInfo);
    Wnd := Handle;
    lpVerb := PWideChar('open');
    lpFile := PWideChar(GITHUB_PAGE);
    fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_UNICODE or SEE_MASK_FLAG_NO_UI;
    if not ShellExecuteExW(@ExecInfo) then
      RaiseLastOSError;
  end;
end;

end.
