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

unit ShellExtension;

interface

/// <summary> Adds shell context menu with actipons list. </summary>
procedure RegShellMenu(ShellExe: string);
/// <summary> Removes shell context menu items. </summary>
procedure UnregShellMenu;

implementation

uses System.SysUtils, Winapi.Windows, Registry2, IFEO;

const
  K0 = 'Software\Classes\exefile\shell\EMc'; // HKCU
  K1 = K0 + '\shell\%0.2d';

// Extracts only file from ActionsExe
function GetIcon(S: string): string;
begin
  Result := Copy(S, 1, LastDelimiter('"', S)) + ',0';
end;

procedure RegShellMenu(ShellExe: string);
const
  ActionCaptionsGUI: array [TAction] of string = ('&Ask user''s permission',
    'Dro&p admin rights', '&Elevate', 'No sleep &until exit',
    'Force d&isplay on', '&Deny and notify user', '', '',
    'Raise a&ccess denied', '', '', '', '', ''
    );
var
  a: TAction;
begin
  with TRegistry.Create do
    try
      begin
        RootKey := HKEY_CURRENT_USER;
        if not OpenKey(K0, True) then
          raise Exception.Create('Unable to create registry key.');
        WriteString('Icon', '"' + ShellExe + '",0');
        WriteString('MUIVerb', 'Set &launch action');
        WriteString('ExtendedSubCommandsKey', 'exefile\shell\EMC');
        WriteString('HasLUAShield', '');
        CloseKey;
        OpenKey(Format(K1, [0]), True);
        WriteString('MUIVerb', '&None');
        OpenKey('command', True);
        WriteString('', '"' + ShellExe + '" reset "%1"');
        CloseKey;
        for a in [aAsk..aDenyAndNotify, aDenyAccess] do
        begin
          OpenKey(Format(K1, [Integer(a) + 1]), True);
          if a = aDenyAccess then
            WriteString('Icon', GetIcon(EMDebuggers[aDenyAndNotify]))
          else
            WriteString('Icon', GetIcon(EMDebuggers[a]));
          WriteString('MUIVerb', ActionCaptionsGUI[a]);
          OpenKey('command', True);
          WriteString('', '"' + ShellExe + '" set "%1" ' + ActionShortNames[a]);
          CloseKey;
        end;
      end;
    finally
      Free;
    end;
end;

procedure UnregShellMenu;
begin
  with TRegistry.Create do
    try
    begin
      RootKey := HKEY_CURRENT_USER;
      if KeyExists(K0) then
        if not DeleteKey(K0) then
          raise Exception.Create('Unable to delete registry key.');
    end;
    finally
      Free;
    end;
end;

end.
