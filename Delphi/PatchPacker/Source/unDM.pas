unit unDM;

interface

uses
  SysUtils, Classes, Windows, Forms, uADStanIntf,
  uADStanOption, uADStanError, uADGUIxIntf, uADPhysIntf, uADStanDef,
  uADStanPool, uADStanAsync, uADPhysManager, uADGUIxFormsWait, uADCompGUIx,
  DB, uADCompClient, uADStanExprFuncs, uADPhysSQLite;

type
  TDM = class(TDataModule)
    fdCon: TADConnection;
    FDGUIxWaitCursor: TADGUIxWaitCursor;
    ADPhysSQLiteDriverLink: TADPhysSQLiteDriverLink;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DM: TDM;

function ConnectDB: Boolean;

implementation

{$R *.dfm}

function ConnectDB: Boolean;
begin
  Result := False;

  Application.CreateForm(TDM, DM);
  with DM do
  begin
    fdCon.Params.Values['Database'] := ExtractFilePath(Application.ExeName) + 'updates.db';
    if not FileExists(fdCon.Params.Values['Database']) then
    begin
      Application.MessageBox('Не найден файл БД', 'Внимание',
        MB_TASKMODAL or MB_TASKMODAL);
      Exit;
    end;

    try
      fdCon.Open;
    except
      on E: Exception do
      begin
        Application.MessageBox(PChar('Ошибка при открытии БД: '+e.Message),
          'Внимание', MB_TASKMODAL or MB_ICONWARNING);
        Exit;
      end;
    end;

    Result := fdCon.Connected;
  end;
end;

end.
