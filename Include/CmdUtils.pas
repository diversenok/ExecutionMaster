{ 2017 © diversenok@gmail.com }

unit CmdUtils;

interface

/// <summary>
///   Preserves quotes for nonzero-index parameters.
/// </summary>
function ParamStr(const index: integer): string;
function ParamCount:integer;

/// <summary>
///  Returns the whole command line starting from indexed parameter.
/// </summary>
function ParamsStartingFrom(const index: integer): string;

implementation

uses Windows;

var
  FInitialized: Boolean = False;
  FCmd: string;
  FStart, FEnd: array of integer;

{ TCmdHelper }

procedure Init;
var
  i: integer;
  Quoted: Boolean;
  LastIsNonspace: Boolean;
begin
  FCmd := GetCommandLine;
  SetLength(FStart, 1);
  FStart[0] := 1;
  SetLength(FEnd, 0);
  Quoted := False;
  LastIsNonspace := True;
  for i := 1 to Length(FCmd) do
  begin
    if not Quoted then
    begin
      if (FCmd[i] = ' ') and LastIsNonspace then
      begin // we have found the end of the last parameter
        SetLength(FEnd, Length(FEnd) + 1);
        FEnd[High(FEnd)] := i - 1;
      end;
      if (FCmd[i] <> ' ') and (not LastIsNonspace) then
      begin // we have found a new parameter
        SetLength(FStart, Length(FStart) + 1);
        FStart[High(FStart)] := i;
      end;
    end;
    if FCmd[i] = '"' then
      Quoted := not Quoted;
    LastIsNonspace := FCmd[i] <> ' ';
  end;
  if Length(FStart) <> Length(FEnd) then
  begin
    SetLength(FEnd, Length(FEnd) + 1);
    FEnd[High(FEnd)] := Length(FCmd);
  end;
  FInitialized := True;
end;

function ParamCount: integer;
begin
  if not FInitialized then
    Init;
  Result := Length(FStart) - 1;
end;

function ParamStr(const index: integer): string;
begin
  if not FInitialized then
    Init;
  if index = 0 then
    Result := System.ParamStr(0)
  else if (Low(FStart) <= index) and (index <= High(FStart)) then
    Result := Copy(FCmd, FStart[index], FEnd[index] - FStart[index] + 1)
  else
    Result := '';
end;

function ParamsStartingFrom(const index: integer): string;
begin
  if not FInitialized then
    Init;
  if (Low(FStart) <= index) and (index <= High(FStart)) then
    Result := Copy(FCmd, FStart[index], Length(FCmd) - FStart[index] + 1)
  else
    Result := '';
end;

end.
