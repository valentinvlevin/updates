unit unDM;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait,
  FireDAC.Comp.UI, Data.DB, FireDAC.Comp.Client, Forms, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.DApt, Windows,
  TPLB3.Codec, TPLB3.Signatory, TPLB3.Hash, TPLB3.BaseNonVisualComponent,
  TPLB3.CryptographicLibrary;

type
  TDM = class(TDataModule)
    fdCon: TADConnection;
    FDGUIxWaitCursor: TFDGUIxWaitCursor;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DM: TDM;

function ConnectDB(const AShowExceptions: Boolean = False): Boolean;

function GetDBVersion(const AConnection: TADConnection): Integer;
function ExecUpdSQL(const AConnection: TADConnection;
  const AFilePath: string): Boolean;


implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses
  unSQLiteDSUtils_FD, undmUpd, zLibEx;

function ConnectDB(const AShowExceptions: Boolean): Boolean;
begin
  Result := False;

  Application.CreateForm(TDM, DM);
  with DM do
  begin
    fdCon.Params.Database := ExtractFilePath(Application.ExeName) + 'TestDB.db';
    if not FileExists(fdCon.Params.Database) then
    begin
      if AShowExceptions then
        Application.MessageBox('Не найден файл БД', 'Внимание',
          MB_TASKMODAL or MB_TASKMODAL);
      Exit;
    end;

    try
      fdCon.Open;
    except
      on E: Exception do
      begin
        if AShowExceptions then
          Application.MessageBox(PChar('Ошибка при открытии БД: '+e.Message),
            'Внимание', MB_TASKMODAL or MB_ICONWARNING);
        Exit;
      end;
    end;

    Result := fdCon.Connected;
  end;
end;

function GetDBVersion(const AConnection: TADConnection): Integer;
begin
  try
    Result := GetInt(AConnection, 'select DBVersion from InfoSelf', []);
  except
    Result := -1;
  end
end;

function ExecUpdSQL(const AConnection: TADConnection;
  const AFilePath: string): Boolean;
var
  fs: TFileStream;
  PatchFileHeader: TPatchFileHeader;
  PatchPartInfo: TPatchPartInfo;
  CompressedData, RawData, SQL: TMemoryStream;
  SQLText: TStringList;
  PartIndex: Integer;
begin
  Result := False;

  if not CheckUpdateInFile(AFilePath) then
    Exit;

  CompressedData := TMemoryStream.Create;
  RawData := TMemoryStream.Create;
  SQL := TMemoryStream.Create;
  SQLText := TStringList.Create;

  try
    fs := TFileStream.Create(AFilePath, fmOpenRead);
    fs.ReadBuffer(PatchFileHeader, SizeOf(TPatchFileHeader));
    try
      CompressedData.CopyFrom(fs, fs.Size - fs.Position);
    finally
      FreeAndNil(fs);
    end;
    CompressedData.Seek(0, soFromBeginning);
    ZDecompressStream(CompressedData, RawData);
    CompressedData.Clear;
    RawData.Seek(0, soFromBeginning);

    StartTransaction(AConnection);;
    try
      for PartIndex := 0 to PatchFileHeader.PartCount-1 do
      begin
        RawData.ReadBuffer(PatchPartInfo, SizeOf(PatchPartInfo));
        if PatchPartInfo.PartType = updSQL then
        begin
          CompressedData.CopyFrom(RawData, PatchPartInfo.PartSize);
          CompressedData.Seek(0, soFromBeginning);
          SQL.Clear;
          ZDecompressStream(CompressedData, SQL);
          CompressedData.Clear;
          SQL.Seek(0, soFromBeginning);

          SQLText.LoadFromStream(SQL);

          try
            ExecuteSQL(AConnection, SQLText.Text, [], [], False);
          except
            Exit;
          end;
        end
        else
          RawData.Seek(PatchPartInfo.NextPartPos, soFromBeginning);
      end;

      ExecuteSQL(AConnection,
        'update InfoSelf set DBVersion=:DBVersion ',
          [ftInteger], [PatchFileHeader.UpdateDBVersionTo], False);

      CommitTransaction(AConnection);
    except
      RollbackTransaction(AConnection);
      Exit;
    end;
  finally
    FreeAndNil(CompressedData);
    FreeAndNil(RawData);
    FreeAndNil(SQL);
    FreeAndNil(SQLText);
  end;

  Result := True;
end;

end.
