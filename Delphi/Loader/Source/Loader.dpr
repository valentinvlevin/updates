program Loader;

uses
  Windows,
  Forms,
  SysUtils,
  unfrmMain in 'unfrmMain.pas' {frmMain},
  unProxyParams in 'unProxyParams.pas',
  unConst in 'unConst.pas',
  unFunc in 'unFunc.pas',
  ShellApi,
  undmUpd in '..\..\Common\Upd\undmUpd.pas' {dmUpd};

{$R *.res}

var
  NextAppExeName: string;
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  if (ParamCount>0)
    and (UpperCase(ParamStr(1))='VERSION') then
  begin
    ExitCode := LoaderVersion;
    Exit;
  end;

  Application.Run;
  unConst.Prepare;
  if CheckUpdates(NextAppExeName) then
    RunProcess(GetAppPath + NextAppExeName, SW_SHOW, False, nil);
end.
