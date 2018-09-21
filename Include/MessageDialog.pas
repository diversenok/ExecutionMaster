{ Copyright (C) 2018 diversenok

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/> }

unit MessageDialog;

interface

uses
  Winapi.Windows;

{$WARN SYMBOL_PLATFORM OFF}

type
  TMessageIcon = (miNone, miInformation, miWarning, miError, miShield);
  TMessageButtons = set of (mbOk, mbYes, mbNo, mbCancel, mbRetry, mbClose);

/// <summary>
/// Uses TaskDialog (if availible) or MessageBox to display a custom message.
/// </summary>
function ShowMessageEx(hWndParent: HWND; Title, MainInstruction,
  Content: String; Icon: TMessageIcon; Buttons: TMessageButtons): Integer;

/// <summary> See <see cref="ShowMessageEx" />. </summary>
function ShowMessageOk(Title, MainInstruction, Content: String;
  Icon: TMessageIcon): Integer;

/// <summary> See <see cref="ShowMessageEx" />. </summary>
function ShowMessageYesNo(Title, MainInstruction, Content: String;
  Icon: TMessageIcon): Integer;

var
  MessageBoxFlags: Cardinal = MB_TOPMOST;

implementation

const
  TDCBF_OK_BUTTON = $0001;
  TDCBF_YES_BUTTON = $0002;
  TDCBF_NO_BUTTON = $0004;
  TDCBF_CANCEL_BUTTON = $0008;
  TDCBF_RETRY_BUTTON = $0010;
  TDCBF_CLOSE_BUTTON = $0020;

  TD_WARNING_ICON = MAKEINTRESOURCEW(Word(-1));
  TD_ERROR_ICON = MAKEINTRESOURCEW(Word(-2));
  TD_INFORMATION_ICON = MAKEINTRESOURCEW(Word(-3));
  TD_SHIELD_ICON = MAKEINTRESOURCEW(Word(-4));

  GetIconTD: array [TMessageIcon] of PWChar = (nil, TD_INFORMATION_ICON,
    TD_WARNING_ICON, TD_ERROR_ICON, TD_SHIELD_ICON);

  GetIconMB: array [TMessageIcon] of UINT = (0, MB_ICONINFORMATION,
    MB_ICONWARNING, MB_ICONERROR, 0);

function TaskDialog(hWndParent: HWND; hInstance: HINST;
  pszWindowTitle, pszMainInstruction, pszContent: PWChar;
  dwCommonButtons: DWORD; pszIcon: PWChar; out pnButton: Integer): HRESULT;
  stdcall; external comctl32 delayed;

type
  TTaskDialogMode = (dmUnknown, dmAvailible, dmUnAvailible);

var
  TaskDialogMode: TTaskDialogMode = dmUnknown;

function IsTaskDialogAvailible: Boolean;
var
  hComctl: HMODULE;
begin
  if TaskDialogMode = dmUnknown then
  begin
    TaskDialogMode := dmUnAvailible;
    hComctl := GetModuleHandle(comctl32);

    if hComctl = 0 then
      hComctl := LoadLibraryEx(comctl32, 0, 0);

    if hComctl <> 0 then
      if GetProcAddress(hComctl, 'TaskDialog') <> nil then
        TaskDialogMode := dmAvailible;
  end;

  Result := TaskDialogMode = dmAvailible;
end;

function GetButtonsTD(Buttons: TMessageButtons): DWORD;
begin
  Result := 0;
  if mbOk in Buttons then
    Result := Result or TDCBF_OK_BUTTON;
  if mbYes in Buttons then
    Result := Result or TDCBF_YES_BUTTON;
  if mbNo in Buttons then
    Result := Result or TDCBF_NO_BUTTON;
  if mbCancel in Buttons then
    Result := Result or TDCBF_CANCEL_BUTTON;
  if mbRetry in Buttons then
    Result := Result or TDCBF_RETRY_BUTTON;
  if mbClose in Buttons then
    Result := Result or TDCBF_CLOSE_BUTTON;
end;

function GetButtonsMB(Buttons: TMessageButtons): UINT;
begin
  if Buttons = [mbOk] then
    Result := MB_OK
  else if Buttons = [mbOk, mbCancel] then
    Result := MB_OKCANCEL
  else if Buttons = [mbYes, mbNo, mbCancel] then
    Result := MB_YESNOCANCEL
  else if Buttons = [mbYes, mbNo] then
    Result := MB_YESNO
  else if Buttons = [mbRetry, mbCancel] then
    Result := MB_RETRYCANCEL
  else
    Result := MB_OK;
end;

function ShowMessageEx(hWndParent: HWND; Title, MainInstruction,
  Content: String; Icon: TMessageIcon; Buttons: TMessageButtons): Integer;
begin
  if IsTaskDialogAvailible then
    if TaskDialog(hWndParent, hInstance, PWChar(Title), PWChar(MainInstruction),
      PWChar(Content), GetButtonsTD(Buttons), GetIconTD[Icon], Result) = S_OK
    then
      Exit;

  Result := MessageBox(hWndParent, PWChar(MainInstruction + #13#10#13#10 +
    Content), PWChar(Title), MessageBoxFlags or GetIconMB[Icon] or
    GetButtonsMB(Buttons));
end;

function ShowMessageOk(Title, MainInstruction, Content: String;
  Icon: TMessageIcon): Integer;
begin
  Result := ShowMessageEx(0, Title, MainInstruction, Content, Icon, [mbOk]);
end;

function ShowMessageYesNo(Title, MainInstruction, Content: String;
  Icon: TMessageIcon): Integer;
begin
  Result := ShowMessageEx(0, Title, MainInstruction, Content, Icon,
    [mbYes, mbNo]);
end;

end.
