unit unfrmUpdateEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, Buttons, ExtCtrls,
  unDM, DB, uADStanIntf, uADStanOption, uADStanParam, uADStanError,
  uADDatSManager, uADPhysIntf, uADDAptIntf, uADStanAsync, uADDAptManager,
  uADCompDataSet, uADCompClient;

type
  TfrmUpdateEdit = class(TForm)
    pnlBottom: TPanel;
    pnlCancel: TPanel;
    btnCancel: TBitBtn;
    btnSave: TBitBtn;
    lblOrd: TLabel;
    lblFileName: TLabel;
    lblFileDesc: TLabel;
    cmbOrd: TComboBox;
    edFileName: TEdit;
    mmUpdateDesc: TMemo;
    fdQry: TADQuery;
    gbUpdateDBTo: TGroupBox;
    chbDoNotUpdateDB: TCheckBox;
    cmbDBNextVersion: TComboBox;
    lblDBNextVersion: TLabel;
    gbUpdateAppTo: TGroupBox;
    lblAppNextVersion: TLabel;
    chbDoNotUpdateApp: TCheckBox;
    cmbAppNextVersion: TComboBox;
    procedure btnSaveClick(Sender: TObject);
    procedure chbDoNotUpdateDBClick(Sender: TObject);
    procedure chbDoNotUpdateAppClick(Sender: TObject);
  private
    FIsEdit: Boolean;
    FIDProject, FIDUpdate: Integer;

    procedure Prepare;

    procedure LoadUpdateOrdList(const AOrd: Integer = 0);
    function GetOrd: Integer;

    procedure LoadNextDBVersionList(const ADBVersion: Integer = 0);
    function GetNextDBVersion: Integer;

    procedure LoadNextAppVersionList(const AAppVersion: Integer = 0);
    function GetNextAppVersion: Integer;
  public
    { Public declarations }
  end;

  function AddUpdate(const AIDProject: Integer;
    var ANewIDUpdate: Integer): Boolean;

  function EditUpdate(const AIDProject, AIDUpdate: Integer): Boolean;

implementation

{$R *.dfm}

uses unSQLiteDSUtils_FD, Math;

function AddUpdate(const AIDProject: Integer;
  var ANewIDUpdate: Integer): Boolean;
var
  f: TfrmUpdateEdit;
begin
  Application.CreateForm(TfrmUpdateEdit, f);
  try
    with f do
    begin
      FIsEdit := False;
      FIDProject := AIDProject;
      Prepare;
      Result := ShowModal = mrOk;
      if Result then
        ANewIDUpdate := FIDUpdate;
    end;
  finally
    FreeAndNil(f);
  end;
end;

function EditUpdate(const AIDProject, AIDUpdate: Integer): Boolean;
var
  f: TfrmUpdateEdit;
begin
  Application.CreateForm(TfrmUpdateEdit, f);
  try
    with f do
    begin
      FIsEdit := True;
      FIDProject := AIDProject;
      FIDUpdate := AIDUpdate;
      Prepare;
      Result := ShowModal = mrOk;
    end;
  finally
    FreeAndNil(f);
  end;
end;

{ TfrmUpdateEdit }

procedure TfrmUpdateEdit.btnSaveClick(Sender: TObject);

  function HaveOnlyAlowedChars(const AValue: string): Boolean;
  const
    AllowedChars = ['A'..'Z', 'a'..'z', '0'..'9', '_'];
  var
    CharIndex: Integer;
  begin
    Result := True;
    for CharIndex := 1 to Length(AValue)-1 do
      if not CharInSet(AValue[CharIndex], AllowedChars) then
      begin
        Result := False;
        Break;
      end;
  end;

begin
  if cmbOrd.ItemIndex=-1 then
  begin
    Application.MessageBox('Не указан порядковый номер', 'Внимание',
      MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if Trim(edFileName.Text)='' then
  begin
    Application.MessageBox('Не указано имя файла', 'Внимание',
      MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if not chbDoNotUpdateDB.Checked
    and (cmbDBNextVersion.ItemIndex=-1) then
  begin
    Application.MessageBox('Не указана следующая версия БД', 'Внимание',
      MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if not chbDoNotUpdateApp.Checked
    and (cmbAppNextVersion.ItemIndex=-1) then
  begin
    Application.MessageBox('Не указана следующая версия приложения', 'Внимание',
      MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if not HaveOnlyAlowedChars(edFileName.Text) then
  begin
    Application.MessageBox('Имя файла содержит недопустимые символы', 'Внимание',
      MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if Trim(mmUpdateDesc.Lines.Text)='' then
  begin
    Application.MessageBox('Не задано описание файла', 'Внимание',
      MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if FIsEdit then
    ExecuteSQL(DM.fdCon,
      'update Updates '+
      'set '+
      ' Ord=:Ord, '+
      ' FileName=:FileName, '+
      ' UpdateDesc=:UpdateDesc, '+
      ' UpdateDBVersionTo=:UpdateDBVersionTo, '+
      ' UpdateAppVersionTo=:UpdateAppVersionTo '+
      'where ID=:IDUpdate',
      [ftSmallInt, ftString, ftWideString, ftSmallInt, ftSmallInt, ftInteger],
      [GetOrd, Trim(edFileName.Text), Trim(mmUpdateDesc.Lines.Text),
       GetNextDBVersion, GetNextAppVersion, FIDUpdate])
  else
  begin
    ExecuteSQL(DM.fdCon,
      'insert into Updates(IDProject, Ord, FileName, UpdateDesc, UpdateDBVersionTo, UpdateAppVersionTo, CreateDateTime) '+
      'values(:IDProject, :Ord, :FileName, :UpdateDesc, :UpdateDBVersionTo, :UpdateAppVersionTo, :CreateDateTime)',
      [ftInteger, ftSmallInt, ftString, ftWideString, ftSmallInt, ftSmallInt, ftDateTime],
      [FIDProject, GetOrd, Trim(edFileName.Text), Trim(mmUpdateDesc.Lines.Text),
       GetNextDBVersion, GetNextAppVersion, Now]);
    FIDUpdate := GetInt(DM.fdCon, 'select max(ID) from Updates', []);
  end;

  ModalResult := mrOk;
end;

procedure TfrmUpdateEdit.chbDoNotUpdateAppClick(Sender: TObject);
begin
  lblAppNextVersion.Enabled := not chbDoNotUpdateApp.Checked;
  cmbAppNextVersion.Enabled := not chbDoNotUpdateApp.Checked;
end;

procedure TfrmUpdateEdit.chbDoNotUpdateDBClick(Sender: TObject);
begin
  lblDBNextVersion.Enabled := not chbDoNotUpdateDB.Checked;
  cmbDBNextVersion.Enabled := not chbDoNotUpdateDB.Checked;
end;

function TfrmUpdateEdit.GetNextAppVersion: Integer;
begin
  if (cmbAppNextVersion.ItemIndex=-1)
    or chbDoNotUpdateApp.Checked then
    Result := 0
  else
    Result := Integer(cmbAppNextVersion.Items.Objects[cmbAppNextVersion.ItemIndex]);
end;

function TfrmUpdateEdit.GetNextDBVersion: Integer;
begin
  if (cmbDBNextVersion.ItemIndex=-1)
    or chbDoNotUpdateDB.Checked then
    Result := 0
  else
    Result := Integer(cmbDBNextVersion.Items.Objects[cmbDBNextVersion.ItemIndex]);
end;

function TfrmUpdateEdit.GetOrd: Integer;
begin
  if (cmbOrd.ItemIndex=-1)
    or chbDoNotUpdateApp.Checked then
    Result := 0
  else
    Result := Integer(cmbOrd.Items.Objects[cmbOrd.ItemIndex]);
end;

procedure TfrmUpdateEdit.LoadNextAppVersionList(const AAppVersion: Integer);
const
  MaxVersion = 100;
  StartNextVersion = 2;
var
  LastVersion, ver: Integer;
begin
  if GetInt(DM.fdCon,
      'select count(ID) '+
      'from Updates '+
      'where IDProject=:IDProject and UpdateAppVersionTo<>0 and ID<>:IDUpdate',
      [FIDProject, ifThen(FIsEdit, FIDUpdate, 0)])>0 then
    LastVersion :=
      GetInt(DM.fdCon,
        'select max(UpdateAppVersionTo) '+
        'from Updates '+
        'where IDProject=:IDProject and ID<>:IDUpdate and UpdateAppVersionTo<>0 ',
        [FIDProject, ifThen(FIsEdit, FIDUpdate, 0)])+1
  else
    LastVersion := StartNextVersion;

  for ver := LastVersion to MaxVersion do
    cmbAppNextVersion.Items.AddObject(IntToStr(Ver), TObject(ver));

  if cmbAppNextVersion.Items.Count>0 then
  begin
    cmbAppNextVersion.ItemIndex := cmbAppNextVersion.Items.IndexOfObject(TObject(AAppVersion));
    if cmbAppNextVersion.ItemIndex = -1 then
      cmbAppNextVersion.ItemIndex := 0;
  end;
end;

procedure TfrmUpdateEdit.LoadNextDBVersionList(const ADBVersion: Integer);
const
  MaxVersion = 100;
  StartNextVersion = 2;
var
  LastVersion, ver: Integer;
begin
  if GetInt(DM.fdCon,
      'select count(ID) '+
      'from Updates '+
      'where IDProject=:IDProject and UpdateAppVersionTo<>0 and ID<>:IDUpdate',
      [FIDProject, ifThen(FIsEdit, FIDUpdate, 0)])>0 then
    LastVersion :=
      GetInt(DM.fdCon,
        'select max(UpdateAppVersionTo) '+
        'from Updates '+
        'where IDProject=:IDProject and ID<>:IDUpdate and UpdateAppVersionTo<>0 ',
        [FIDProject, ifThen(FIsEdit, FIDUpdate, 0)])+1
  else
    LastVersion := StartNextVersion;

  for ver := LastVersion to MaxVersion do
    cmbDBNextVersion.Items.AddObject(IntToStr(Ver), TObject(ver));

  if cmbDBNextVersion.Items.Count>0 then
  begin
    cmbDBNextVersion.ItemIndex := cmbDBNextVersion.Items.IndexOfObject(TObject(ADBVersion));
    if cmbDBNextVersion.ItemIndex = -1 then
      cmbDBNextVersion.ItemIndex := 0;
  end;
end;

procedure TfrmUpdateEdit.LoadUpdateOrdList(const AOrd: Integer);
const
  MaxOrd = 100;
var
  Ord: Integer;
  ds: TDataSet;
begin
  cmbOrd.Clear;
  ds := GetDataSet(DM.fdCon,
          'select Ord, ID '+
          'from Updates '+
          'where IDProject=:IDProject '+
          'order by 1', [FIDProject]);
  try
    for Ord := 1 to MaxOrd do
      if not ds.Locate('Ord', Ord, [])
        or (FIsEdit and (ds.FieldByName('ID').AsInteger=FIDUpdate)) then
        cmbOrd.Items.AddObject(IntToStr(Ord), TObject(Ord));
  finally
    ds.Close;
    FreeAndNil(ds);
  end;

  if cmbOrd.Items.Count>0 then
  begin
    cmbOrd.ItemIndex := cmbOrd.Items.IndexOfObject(TObject(AOrd));
    if cmbOrd.ItemIndex = -1 then
      cmbOrd.ItemIndex := 0;
  end;
end;

procedure TfrmUpdateEdit.Prepare;
begin
  if FIsEdit then
  begin
    FillDataSet(fdQry,
      'select Ord, FileName, UpdateDesc, UpdateDBVersionTo, UpdateAppVersionTo '+
      'from Updates '+
      'where ID=:IDUpdate', [FIDUpdate]);
    try
      LoadUpdateOrdList(fdQry.FieldByName('Ord').AsInteger);
      edFileName.Text := fdQry.FieldByName('FileName').AsString;

      chbDoNotUpdateDB.Checked := fdQry.FieldByName('UpdateDBVersionTo').AsInteger=0;
      LoadNextDBVersionList(fdQry.FieldByName('UpdateDBVersionTo').AsInteger);

      chbDoNotUpdateApp.Checked := fdQry.FieldByName('UpdateAppVersionTo').AsInteger=0;
      LoadNextAppVersionList(fdQry.FieldByName('UpdateAppVersionTo').AsInteger);

      mmUpdateDesc.Lines.Text := fdQry.FieldByName('UpdateDesc').AsString;
    finally
      fdQry.Close;
    end;
  end
  else
  begin
    LoadUpdateOrdList;
    edFileName.Clear;
    LoadNextDBVersionList;
    LoadNextAppVersionList;
    mmUpdateDesc.Clear;
  end;
end;

end.
