program GASH;

uses
  Vcl.Forms,
  SysUtils,
  Windows,
  unDM in 'unDM.pas' {DM: TDataModule},
  unSQLiteDSUtils_FD in '..\..\Common\unSQLiteDSUtils_FD.pas',
  undmUpd in '..\..\Common\Upd\undmUpd.pas' {dmUpd};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  if ParamCount>0 then
  begin
    if UpperCase(ParamStr(1))='DBVERSION' then
    begin
      if ConnectDB(False) then
        ExitCode := GetDBVersion(DM.fdCon)
      else
        ExitCode := -1;
    end
    else
      if (UpperCase(ParamStr(1))='EXECSQL')
        and (ParamCount=2) then
      begin
        if ConnectDB(False)
          and ExecUpdSQL(DM.fdCon, ParamStr(2)) then
          ExitCode := 1
        else
          ExitCode := -1;
      end
    else
      if (UpperCase(ParamStr(1))='UPDATELOADER')
        and (ParamCount=2) then
      begin
        if (StrToIntDef(ParamStr(2), 0)>0)
          and UpdateLoader(StrToInt(ParamStr(2))) then
          ExitCode := 1
        else
          ExitCode := -1;
        RunProcess(ExtractFilePath(Application.ExeName) + 'Loader.exe', SW_SHOW, False, nil);
      end;
  end
  else
    if ConnectDB(True) then
    begin
//      Application.MessageBox('Запуск приложения', 'Внимание', 0);
      Application.Run;
    end
end.
