unit unfrmUpdateFilePartEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, Buttons, ExtCtrls,
  unDM, DB, uADStanIntf, uADStanOption, uADStanParam, uADStanError,
  uADDatSManager, uADPhysIntf, uADDAptIntf, uADStanAsync, uADDAptManager,
  uADCompDataSet, uADCompClient;

type
  TfrmUpdateFilePartEdit = class(TForm)
    pnlBottom: TPanel;
    pnlCancel: TPanel;
    btnCancel: TBitBtn;
    btnSave: TBitBtn;
    lblFromFilePath: TLabel;
    lblFileName: TLabel;
    lblToFilePath: TLabel;
    chbIsDoExec: TCheckBox;
    edFromFilePath: TEdit;
    edFileName: TEdit;
    edToFilePath: TEdit;
    btnSelectFile: TSpeedButton;
    bvlFromFilePath: TBevel;
    OpenDialog: TOpenDialog;
    fdQry: TADQuery;
    procedure btnSelectFileClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    FIsEdit: Boolean;
    FIDUpdate, FIDPart, FOrd: Integer;

    procedure Prepare;
  public
    { Public declarations }
  end;

  function AddUpdateFilePart(const AIDUpdate: Integer;
    var AOrd: Integer): Boolean;

  function EditUpdateFilePart(const AIDUpdate, AIDPart: Integer): Boolean;

implementation

{$R *.dfm}

uses unSQLiteDSUtils_FD, Math;

function AddUpdateFilePart(const AIDUpdate: Integer;
  var AOrd: Integer): Boolean;
var
  f: TfrmUpdateFilePartEdit;
begin
  Application.CreateForm(TfrmUpdateFilePartEdit, f);
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

function EditUpdateFilePart(const AIDUpdate, AIDPart: Integer): Boolean;
var
  f: TfrmUpdateFilePartEdit;
begin
  Application.CreateForm(TfrmUpdateFilePartEdit, f);
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

procedure TfrmUpdateFilePartEdit.btnSaveClick(Sender: TObject);
begin
  if Trim(edFromFilePath.Text)='' then
  begin
    Application.MessageBox('Не задан исходный файл', 'Внимание',
      MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if not FileExists(edFromFilePath.Text) then
  begin
    Application.MessageBox('Не найден исходный файл', 'Внимание',
      MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if Trim(edFileName.Text)='' then
  begin
    Application.MessageBox('Не задано имя конечного файла', 'Внимание',
      MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if not FIsEdit then
  begin
    if GetInt(DM.fdCon, 'select count(ID) from UpdateSQLParts where IDUpdate=:IDUpdate', [FIDUpdate])>0 then
      FOrd := GetInt(DM.fdCon, 'select max(Ord) from UpdateSQLParts where IDUpdate=:IDUpdate', [FIDUpdate])+1
    else
      FOrd := 1;
    if GetInt(DM.fdCon, 'select count(ID) from UpdateFileParts where IDUpdate=:IDUpdate', [FIDUpdate])>0 then
      FOrd := max(FOrd, GetInt(DM.fdCon, 'select max(Ord) from UpdateFileParts where IDUpdate=:IDUpdate', [FIDUpdate])+1);

    ExecuteSQL(DM.fdCon,
      'insert into UpdateFileParts(IDUpdate, Ord, FileName, FromFilePath, ToFilePath, IsDoExec) '+
      'values(:IDUpdate, :Ord, :FileName, :FromFilePath, :ToFilePath, :IsDoExec) ',
      [ftInteger, ftSmallInt, ftString, ftWideString, ftWideString, ftSmallInt],
      [FIDUpdate, FOrd, Trim(edFileName.Text), Trim(edFromFilePath.Text),
       Trim(edToFilePath.Text), IfThen(chbIsDoExec.Checked, 1, 0)]);
  end
  else
    ExecuteSQL(DM.fdCon,
      'update UpdateFileParts '+
      'set '+
      ' FromFilePath = :FromFilePath, '+
      ' FileName = :FileName, '+
      ' ToFilePath = :ToFilePath, '+
      ' IsDoExec = :IsDoExec '+
      'where ID=:ID ',
      [ftWideString, ftString, ftWideString, ftSmallInt, ftInteger],
      [Trim(edFromFilePath.Text), Trim(edFileName.Text), Trim(edToFilePath.Text),
       IfThen(chbIsDoExec.Checked, 1, 0), FIDPart]);

  ModalResult := mrOk;

end;

procedure TfrmUpdateFilePartEdit.btnSelectFileClick(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    edFromFilePath.Text := OpenDialog.FileName;
    if edFileName.Text = '' then
      edFileName.Text := ExtractFileName(OpenDialog.FileName);
  end;
end;

procedure TfrmUpdateFilePartEdit.Prepare;
begin
  if FIsEdit then
  begin
    FillDataSet(fdQry,
      'select FileName, FromFilePath, ToFilePath, IsDoExec '+
      'from UpdateFileParts '+
      'where ID=:ID', [FIDPart]);
    try
      edFromFilePath.Text := fdQry.FieldByName('FromFilePath').AsString;
      edFileName.Text := fdQry.FieldByName('FileName').AsString;
      edToFilePath.Text := fdQry.FieldByName('ToFilePath').AsString;
    finally
      fdQry.Close;
    end;
  end
  else
  begin
    edFromFilePath.Clear;
    edFileName.Clear;
    edToFilePath.Clear;
  end;
end;

end.
