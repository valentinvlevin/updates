unit unUpdateSQLPartEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, Buttons, ExtCtrls,
  unDM, DB, uADStanIntf, uADStanOption, uADStanParam, uADStanError,
  uADDatSManager, uADPhysIntf, uADDAptIntf, uADStanAsync, uADDAptManager,
  uADCompDataSet, uADCompClient;

type
  TfrmUpdateSQLPartEdit = class(TForm)
    pnlBottom: TPanel;
    pnlCancel: TPanel;
    btnCancel: TBitBtn;
    btnSave: TBitBtn;
    mmSQL: TMemo;
    fdQry: TADQuery;
    pnlPartDesc: TPanel;
    lblPartDesc: TLabel;
    edPartDesc: TEdit;
    procedure btnSaveClick(Sender: TObject);
  private
    FIsEdit: Boolean;
    FIDUpdate, FIDPart, FOrd: Integer;

    procedure Prepare;
  public
    { Public declarations }
  end;

  function AddUpdateSQLPart(const AIDUpdate: Integer;
    var AOrd: Integer): Boolean;

  function EditUpdateSQLPart(const AIDUpdate, AIDPart: Integer): Boolean;

implementation

{$R *.dfm}

uses unSQLiteDSUtils_FD, zLibEx, Math;

function AddUpdateSQLPart(const AIDUpdate: Integer;
  var AOrd: Integer): Boolean;
var
  f: TfrmUpdateSQLPartEdit;
begin
  Application.CreateForm(TfrmUpdateSQLPartEdit, f);
  try
    with f do
    begin
      FIsEdit := False;
      FIDUpdate := AIDUpdate;
      Prepare;
      Result := ShowModal = mrOk;
      if Result then
        AOrd := FOrd;
    end;
  finally
    FreeAndNil(f);
  end;
end;

function EditUpdateSQLPart(const AIDUpdate, AIDPart: Integer): Boolean;
var
  f: TfrmUpdateSQLPartEdit;
begin
  Application.CreateForm(TfrmUpdateSQLPartEdit, f);
  try
    with f do
    begin
      FIsEdit := True;
      FIDUpdate := AIDUpdate;
      FIDPart := AIDPart;
      Prepare;
      Result := ShowModal = mrOk;
    end;
  finally
    FreeAndNil(f);
  end;
end;

{ TfrmUpdateSQLPartEdit }

procedure TfrmUpdateSQLPartEdit.btnSaveClick(Sender: TObject);
var
  RawData, CompressedData: TMemoryStream;
begin
  if Trim(edPartDesc.Text)='' then
  begin
    Application.MessageBox('Не задано описание SQL скрипта', 'Внимание',
      MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if Trim(mmSQL.Text)='' then
  begin
    Application.MessageBox('Не указан текст SQL скрипта', 'Внимание',
      MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if fdQry.Active then
    fdQry.Close;

  RawData := TMemoryStream.Create;
  CompressedData := TMemoryStream.Create;

  try
    mmSQL.Lines.SaveToStream(RawData);
    RawData.Seek(0, soFromBeginning);
    ZCompressStream(RawData, CompressedData, zcMax);
    CompressedData.Seek(0, soFromBeginning);
    if FIsEdit then
    begin
      fdQry.SQL.Text :=
        'update UpdateSQLParts '+
        'set SQLText=:SQLText '+
        'where ID=:ID ';
      fdQry.Params.ParamByName('ID').AsInteger := FIDPart;
    end
    else
    begin
      fdQry.SQL.Text :=
        'insert into UpdateSQLParts(IDUpdate, Ord, SQLText) '+
        'values(:IDUpdate, :Ord, :SQLText) ';
      fdQry.Params.ParamByName('IDUpdate').AsInteger := FIDUpdate;

      if GetInt(DM.fdCon, 'select count(ID) from UpdateSQLParts where IDUpdate=:IDUpdate', [FIDUpdate])>0 then
        FOrd := GetInt(DM.fdCon, 'select max(Ord) from UpdateSQLParts where IDUpdate=:IDUpdate', [FIDUpdate])+1
      else
        FOrd := 1;
      if GetInt(DM.fdCon, 'select count(ID) from UpdateFileParts where IDUpdate=:IDUpdate', [FIDUpdate])>0 then
        FOrd := max(FOrd, GetInt(DM.fdCon, 'select max(Ord) from UpdateFileParts where IDUpdate=:IDUpdate', [FIDUpdate])+1);

      fdQry.Params.ParamByName('Ord').AsInteger := FOrd;
    end;

    fdQry.Params.ParamByName('SQLText').LoadFromStream(CompressedData, ftBlob);

    StartTransaction(DM.fdCon);
    try
      fdQry.ExecSQL;
      CommitTransaction(DM.fdCon);
    except
      on e: Exception do
      begin
        RollbackTransaction(DM.fdCon);
        Application.MessageBox(PChar('Ошибка при работе с БД:'#13+e.Message),
          'Внимание', MB_TASKMODAL or MB_ICONWARNING);
        Exit;
      end;
    end;
  finally
    FreeAndNil(RawData);
    FreeAndNil(CompressedData);
  end;

  ModalResult := mrOk;
end;

procedure TfrmUpdateSQLPartEdit.Prepare;
var
  CompressedData, RawData: TMemoryStream;
begin
  if FIsEdit then
  begin
    FillDataSet(fdQry, 'select SQLText, PartDesc from UpdateSQLParts where ID=:ID', [FIDPart]);
    CompressedData := TMemoryStream.Create;
    RawData := TMemoryStream.Create;
    try
      edPartDesc.Text := fdQry.FieldByName('PartDesc').AsString;
      TBlobField(fdQry.FieldByName('SQLText')).SaveToStream(CompressedData);
      CompressedData.Seek(0, soFromBeginning);
      ZDecompressStream(CompressedData, RawData);
      RawData.Seek(0, soFromBeginning);

      mmSQL.Lines.LoadFromStream(RawData);
    finally
      fdQry.Close;
      FreeAndNil(CompressedData);
      FreeAndNil(RawData);
    end;
  end
  else
    mmSQL.Clear;
end;

end.
