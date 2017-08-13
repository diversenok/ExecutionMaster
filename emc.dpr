{ 2017 © diversenok@gmail.com }

program emc;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SysUtils,
  Windows,
  Masks,
  IFEO in 'Include\IFEO.pas',
  ProcessUtils in 'Include\ProcessUtils.pas';

resourcestring
  USAGE = {$INCLUDE emcusage.txt};

procedure Help;
begin
  write('Execution Master ');
  {$IFDEF WIN64}
    write('x64');
  {$ELSE}
    write('x86');
  {$ENDIF}
  writeln(' [console]: v0.8 (c) diversenok 2017');
  if IsElevated then
    writeln('Process: elevated')
  else
    writeln('Process: non-elevated');
  writeln;
  writeln(USAGE);
  ExitProcess(ERROR_BAD_COMMAND);
end;

procedure ActionQuery;
var
  Core: TImageFileExecutionOptions;
  i: integer;
begin
  try
    Core := TImageFileExecutionOptions.Create;
    for i := 0 to Core.Count - 1 do
    with Core[i] do
      begin
        if ParamCount >= 2 then
          if not MatchesMask(TreatedFile, ParamStr(2)) then
            Continue;
        writeln(Format('[*] %s --> %s', [TreatedFile, GetCaption]));
      end;
  finally
    FreeAndNil(Core);
  end;
end;

procedure ActionReset;
var
  Core: TImageFileExecutionOptions;
  i: integer;
begin
  Core := TImageFileExecutionOptions.Create;
  try
    for i := 0 to Core.Count - 1 do
    with Core[i] do
    begin
      if ParamCount >= 2 then
        if not MatchesMask(TreatedFile, ParamStr(2)) then
          Continue;
      writeln(Format('[-] Deleting action for %s', [TreatedFile]));
      Core.UnregisterDebugger(TreatedFile);
    end;
  finally
    FreeAndNil(Core);
  end;
end;

const
  ActionNames: array [TAction] of string = ('ask', 'deny', 'deny-quiet',
    'drop', 'elevate', 'nosleep', 'display-on', 'execute');

{ We don't need to parse this part of command line — user is free at using
  quotes and spaces now. }
function GetExec: string;
const
  DELIM = ' : ';
var
  ind: integer;
begin
  Result := GetCommandLine;
  ind := Pos(DELIM, Result);
  if ind = -1 then
    raise Exception.Create('Need command line for execute action. See help.')
  else
    Result := Copy(Result, ind + Length(DELIM), Length(Result) - ind -
      Length(DELIM) + 1);
end;

procedure CheckForDangerous(S: String);
const
  WARN = 'WARNING: %s is a system process.'#$D#$A +
   'Performing this action may cause system instability. Are you sure? [y/n]: ';
var
  Answer: string;
  i: integer;
begin
  for i := Low(DangerousProcesses) to High(DangerousProcesses) do
    if LowerCase(S) = DangerousProcesses[i] then
    begin
      write(Format(WARN, [S]));
      readln(Answer);
      if LowerCase(Answer) <> 'y' then
        raise Exception.Create('Canceled by user.');
      break;
    end;
end;

procedure ActionSet;
var
  a: TAction;
  Dbg: TIFEORec;
begin
  if ParamCount < 3 then
    raise Exception.Create('Not enough parameters.');

  for a := Low(TAction) to High(TAction) do
    if LowerCase(ParamStr(3)) = ActionNames[a] then
      Break;
  if a = Succ(High(TAction)) then
    raise Exception.Create('Unknown action.');

  CheckForDangerous(ParamStr(2));

  if a = aExecuteEx then
    Dbg := TIFEOREC.Create(a, ParamStr(2), GetExec)
  else
    Dbg := TIFEOREC.Create(a, ParamStr(2));
  writeln(Format('[+] %s --> %s', [Dbg.TreatedFile, Dbg.GetCaption]));
  TImageFileExecutionOptions.RegisterDebugger(Dbg);
end;

begin
  try
    if ParamCount = 0 then
      Help;

    if LowerCase(ParamStr(1)) = 'query' then
      ActionQuery
    else if LowerCase(ParamStr(1)) = 'set' then
      ActionSet
    else if LowerCase(ParamStr(1)) = 'reset' then
      ActionReset
    else
      Help;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
