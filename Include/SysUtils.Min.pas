{ ExecutionMaster component.
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
  along with this program. If not, see <http://www.gnu.org/licenses/> }

unit SysUtils.Min;

// DO NOT INCLUDE THIS UNIT IF YOU USE System.SysUtils.

interface

implementation

uses
  Winapi.Windows;

const
  STATUS_UNHANDLED_EXCEPTION: Integer = Integer($C0000144);

function _IntToStr(i: NativeUInt): ShortString; inline;
begin
  Str(i, Result);
end;

function IntToStr(i: NativeUInt): String;
begin
  Result := String(_IntToStr(i));
end;

// Since try..except doesn't work without System.SysUtils
// we should handle all exceptions on our own.
function HaltOnException(P: PExceptionRecord): IntPtr;
begin
  Result := 0;
  OutputDebugStringW(
    PWideChar(
      'Exception occured: code = ' + IntToStr(P.ExceptionCode) +
      '; address = ' + IntToStr(NativeUInt(P.ExceptionAddress))
    )
  );
  Halt(STATUS_UNHANDLED_EXCEPTION);
end;

initialization

ExceptObjProc := @HaltOnException;

end.
