unit unfrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, DBGridEhGrouping, ToolCtrlsEh,
  DBGridEhToolCtrls, DynVarsEh, MemTableDataEh, DB, MemTableEh, GridsEh,
  DBAxisGridsEh, DBGridEh, unDM, TPLB3.BaseNonVisualComponent, TPLB3.Signatory,
  TPLB3.CryptographicLibrary, TPLB3.Codec, TPLB3.Hash,
  ActnList, uADStanIntf, uADStanOption, uADStanParam, uADStanError,
  uADDatSManager, uADPhysIntf, uADDAptIntf, uADStanAsync, uADDAptManager,
  uADCompDataSet, uADCompClient, ExtCtrls, EhLibVCL, StdCtrls, Buttons;

type
  TfrmMain = class(TForm)
    pnlBottom: TPanel;
    pnlExit: TPanel;
    btnExit: TBitBtn;
    pnlTop: TPanel;
    dbgParts: TDBGridEh;
    mdParts: TMemTableEh;
    dsParts: TDataSource;
    lblProject: TLabel;
    cmbProjects: TComboBox;
    btnEditProjects: TSpeedButton;
    fdQry: TADQuery;
    pnlData: TPanel;
    dbgUpdates: TDBGridEh;
    Splitter1: TSplitter;
    dsUpdates: TDataSource;
    mdUpdates: TMemTableEh;
    pnlUpdates: TPanel;
    pnlUpdatesButtons: TPanel;
    btnAddUpdate: TSpeedButton;
    btnEditUpdate: TSpeedButton;
    btnDeleteUpdate: TSpeedButton;
    bvlUpdatesButtons: TBevel;
    btnGenUpdateFile: TSpeedButton;
    pnlParts: TPanel;
    pnlPartButtons: TPanel;
    btnAddFilePart: TSpeedButton;
    btnEditPart: TSpeedButton;
    btnDeletePart: TSpeedButton;
    SpeedButton1: TSpeedButton;
    Bevel1: TBevel;
    lbSignatory: TSignatory;
    lbCodec: TCodec;
    lbCryptographicLibrary: TCryptographicLibrary;
    lbHash: THash;
    ActionList: TActionList;
    cmProjectsEdit: TAction;
    cmAddUpdate: TAction;
    cmEditUpdate: TAction;
    cmDeleteUpdate: TAction;
    cmGenUpdateFile: TAction;
    cmAddSQLUpdatePart: TAction;
    cmAddFileUpdatePart: TAction;
    cmEditUpdatePart: TAction;
    cmDeleteUpdatePart: TAction;
    procedure cmbProjectsChange(Sender: TObject);
    procedure mdUpdatesAfterScroll(DataSet: TDataSet);
    procedure FormCreate(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure cmProjectsEditExecute(Sender: TObject);
    procedure cmAddUpdateExecute(Sender: TObject);
    procedure cmEditUpdateExecute(Sender: TObject);
    procedure cmDeleteUpdateExecute(Sender: TObject);
    procedure cmGenUpdateFileExecute(Sender: TObject);
    procedure cmAddFileUpdatePartExecute(Sender: TObject);
    procedure cmAddSQLUpdatePartExecute(Sender: TObject);
    procedure cmEditUpdatePartExecute(Sender: TObject);
    procedure cmDeleteUpdatePartExecute(Sender: TObject);
    procedure mdPartsAfterScroll(DataSet: TDataSet);
  private
    procedure LoadProjectList(const AIDProject: Integer = 0);
    function GetIDProject: Integer;

    procedure LoadUpdateList(const AIDProject: Integer;
      const AIDUpdate: Integer = 0);
    function GetIDUpdate: Integer;

    procedure LoadPartList(const AIDUpdate: Integer;
      const AOrd: Integer = 0);
    function GetIDPart: Integer;
    function GetPartOrd: Integer;

    procedure Prepare;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses MD5, unfrmProjects, unSQLiteDSUtils_FD, unfrmUpdateEdit, StrUtils,
  unUpdateSQLPartEdit, unfrmUpdateFilePartEdit, unConst, TPLB3.StreamUtils,
  TPLB3.Asymetric, zLibEx;

procedure TfrmMain.btnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.cmAddFileUpdatePartExecute(Sender: TObject);
var
  Ord: Integer;
begin
  if (mdUpdates.RecordCount>0)
    and AddUpdateFilePart(GetIDUpdate, Ord) then
  begin
    LoadPartList(GetIDUpdate, Ord);
    mdPartsAfterScroll(mdParts);
  end;
end;

procedure TfrmMain.cmAddSQLUpdatePartExecute(Sender: TObject);
var
  Ord: Integer;
begin
  if (mdUpdates.RecordCount>0)
    and AddUpdateSQLPart(GetIDUpdate, Ord) then
  begin
    LoadPartList(GetIDUpdate, Ord);
    mdPartsAfterScroll(mdParts);
  end;
end;

procedure TfrmMain.cmAddUpdateExecute(Sender: TObject);
var
  IDUpdate: Integer;
begin
  if (GetIDProject>0)
    and AddUpdate(GetIDProject, IDUpdate) then
  begin
    LoadUpdateList(GetIDProject, IDUpdate);
    mdUpdatesAfterScroll(mdUpdates);
  end;
end;

procedure TfrmMain.cmbProjectsChange(Sender: TObject);
begin
  LoadUpdateList(GetIDProject);
  mdUpdatesAfterScroll(mdUpdates);

  cmAddUpdate.Enabled := GetIDProject>0;
end;

procedure TfrmMain.cmDeleteUpdateExecute(Sender: TObject);
begin
  if (mdUpdates.RecordCount>0)
    and (Application.MessageBox('Удалить обновление?', 'Подтверждение',
          MB_TASKMODAL or MB_ICONQUESTION or MB_YESNO or MB_DEFBUTTON2)=ID_YES) then
  begin
    StartTransaction(DM.fdCon);
    try
      ExecuteSQL(DM.fdCon, 'delete from UpdateFileParts where IDUpdate=:IDUpdate',
        [ftInteger], [mdUpdates.FieldByName('ID').AsInteger], False);
      ExecuteSQL(DM.fdCon, 'delete from UpdateSQLParts where IDUpdate=:IDUpdate',
        [ftInteger], [mdUpdates.FieldByName('ID').AsInteger], False);
      ExecuteSQL(DM.fdCon, 'delete from Updates where ID=:IDUpdate',
        [ftInteger], [mdUpdates.FieldByName('ID').AsInteger], False);

      CommitTransaction(DM.fdCon);

      mdUpdates.Delete;
    except
      on e: Exception do
      begin
        RollbackTransaction(DM.fdCon);
        Application.MessageBox(PChar('Ошибка при работе с БД:'#13+e.Message),
          'Внимание', MB_TASKMODAL or MB_ICONWARNING);
      end;
    end;
  end;
end;

procedure TfrmMain.cmDeleteUpdatePartExecute(Sender: TObject);
begin
  if (mdParts.RecordCount>0)
    and (Application.MessageBox(PChar('Удалить часть №'+mdParts.FieldByName('Ord').AsString+'?'),
          'Подтверждение', MB_TASKMODAL or MB_YESNO or MB_DEFBUTTON2 or MB_ICONQUESTION)=ID_YES) then
  begin
    StartTransaction(DM.fdCon);
    try
      case mdParts.FieldByName('PartType').AsInteger of
        updSQL:
          ExecuteSQL(DM.fdCon, 'delete from UpdateSQLParts where ID=:ID',
            [ftInteger], [GetIDPart], False);
        updFile, updExec:
          ExecuteSQL(DM.fdCon, 'delete from UpdateFileParts where ID=:ID',
            [ftInteger], [mdPArts.FieldByName('ID').AsInteger], False);
      end;

      ExecuteSQL(DM.fdCon,
        'update UpdateSQLParts '+
        'set Ord=Ord-1 '+
        'where IDUpdate=:IDUpdate and Ord>:Ord',
        [ftInteger, ftSmallint], [GetIDUpdate, GetPartOrd], False);
      ExecuteSQL(DM.fdCon,
        'update UpdateFileParts '+
        'set Ord=Ord-1 '+
        'where IDUpdate=:IDUpdate and Ord>:Ord',
        [ftInteger, ftSmallint], [GetIDUpdate, GetPartOrd], False);

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
    LoadPartList(GetIDUpdate, GetIDPart);
    mdPartsAfterScroll(mdParts);
  end;
end;

procedure TfrmMain.cmEditUpdateExecute(Sender: TObject);
begin
  if (mdUpdates.RecordCount>0)
    and EditUpdate(GetIDProject, mdUpdates.FieldByName('ID').AsInteger) then
  begin
    LoadUpdateList(GetIDProject, mdUpdates.FieldByName('ID').AsInteger);
    mdUpdatesAfterScroll(mdUpdates);
  end;
end;

procedure TfrmMain.cmEditUpdatePartExecute(Sender: TObject);
begin
  if mdParts.RecordCount>0 then
  begin
    case mdParts.FieldByName('PartType').AsInteger of
      updSQL:
        if EditUpdateSQLPart(GetIDUpdate, mdParts.FieldByName('ID').AsInteger) then
          LoadPartList(GetIDUpdate, mdParts.FieldByName('Ord').AsInteger);
      updFile, updExec:
        if EditUpdateFilePart(GetIDUpdate, mdParts.FieldByName('ID').AsInteger) then
          LoadPartList(GetIDUpdate, mdParts.FieldByName('Ord').AsInteger);
    end;
    mdPartsAfterScroll(mdParts);
  end;
end;

procedure TfrmMain.cmGenUpdateFileExecute(Sender: TObject);
var
  UpdateFilePath, UpdateFileName: string;
  PatchFileHeader: TPatchFileHeader;
  Ord: Integer;
  dsUpd, dsFiles, dsSQL: TDataSet;
  CompressedData, RawData, Store, Sign: TMemoryStream;
  PatchPartInfo: TPatchPartInfo;
  PatchFilePart: TPatchFilePart;
  fs: TFileStream;
begin
  if mdUpdates.RecordCount=0 then
  begin
    Application.MessageBox('Не выбрано обновление', 'Внимание',
      MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  PatchFileHeader.ProjectName :=
    AnsiString(GetStr(DM.fdCon,
                'select ProjectName '+
                'from Projects '+
                'where ID=:IDProject ', [GetIDProject]));

  dsUpd := GetDataSet(DM.fdCon,
      'select upd.Ord, upd.FileName, upd.UpdateDBVersionTo, upd.UpdateAppVersionTo, '+
      ' case when SQLParts.IDUpdate is null then 0 else SQLParts.PartCount end as SQLPartCount, '+
      ' case when FileParts.IDUpdate is null then 0 else FileParts.PartCount end as FilePartCount '+
      'from Updates upd '+
      ' left join '+
      '   ('+
      '     select IDUpdate, count(*) as PartCount '+
      '     from UpdateSQLParts '+
      '     group by IDUpdate '+
      '   ) SQLParts on (SQLParts.IDUpdate=upd.ID) '+
      ' left join '+
      '   ('+
      '     select IDUpdate, count(*) as PartCount '+
      '     from UpdateFileParts '+
      '     group by IDUpdate '+
      '   ) FileParts on (FileParts.IDUpdate=upd.ID) '+
      'where ID=:IDUpdate ', [GetIDUpdate]);
  try
    if (dsUpd.FieldByName('UpdateDBVersionTo').AsInteger=0)
      and (dsUpd.FieldByName('SQLPartCount').AsInteger>0) then
    begin
      Application.MessageBox('В обновлении имеются обновления БД, но не указана следующая версия БД',
        'Внимание',MB_TASKMODAL or MB_ICONWARNING);
      Exit;
    end;

    if (dsUpd.FieldByName('UpdateDBVersionTo').AsInteger>0)
      and (dsUpd.FieldByName('SQLPartCount').AsInteger=0) then
    begin
      Application.MessageBox('В обновлении нет обновлений БД, но указана следующая версия БД',
        'Внимание',MB_TASKMODAL or MB_ICONWARNING);
      Exit;
    end;

    if (dsUpd.FieldByName('UpdateAppVersionTo').AsInteger=0)
      and (dsUpd.FieldByName('FilePartCount').AsInteger>0) then
    begin
      Application.MessageBox('В обновлении имеются обновления приложения, но не указана следующая версия приложения',
        'Внимание',MB_TASKMODAL or MB_ICONWARNING);
      Exit;
    end;

    if (dsUpd.FieldByName('UpdateAppVersionTo').AsInteger>0)
      and (dsUpd.FieldByName('FilePartCount').AsInteger=0) then
    begin
      Application.MessageBox('В обновлении нет обновлений приложения, но указана следующая версия приложения',
        'Внимание',MB_TASKMODAL or MB_ICONWARNING);
      Exit;
    end;

    UpdateFileName := dsUpd.FieldByName('FileName').AsString;

    PatchFileHeader.FileSign := PatchFileSign;
    PatchFileHeader.Ord := dsUpd.FieldByName('Ord').AsInteger;
    PatchFileHeader.UpdateDBVersionTo := dsUpd.FieldByName('UpdateDBVersionTo').AsInteger;
    PatchFileHeader.UpdateAppVersionTo := dsUpd.FieldByName('UpdateAppVersionTo').AsInteger;
    PatchFileHeader.PartCount := dsUpd.FieldByName('FilePartCount').AsInteger +
      dsUpd.FieldByName('SQLPartCount').AsInteger;
    PatchFileHeader.CreateDateTime := Now;
  finally
    dsUpd.Close;
    FreeAndNil(dsUpd);
  end;

  UpdateFilePath := GetAppPath + UpdateFileDir + '\' + string(PatchFileHeader.ProjectName) + '\';
  if not DirectoryExists(UpdateFilePath) then
    ForceDirectories(UpdateFilePath);

  dsSQL :=
    GetDataSet(DM.fdCon,
      'select Ord, SQLText '+
      'from UpdateSQLParts '+
      'where IDUpdate=:IDUpdate '+
      'order by Ord', [GetIDUpdate]);

  dsFiles :=
    GetDataSet(DM.fdCon,
      'select FromFilePath, FileName, ToFilePath, Ord, IsDoExec '+
      'from UpdateFileParts '+
      'where IDUpdate=:IDUpdate '+
      'order by Ord', [GetIDUpdate]);

  RawData := TMemoryStream.Create;
  CompressedData := TMemoryStream.Create;

  try
    if dsSQL.RecordCount+dsFiles.RecordCount=0 then
    begin
      Application.MessageBox('Для обновления не заданы составные части',
        'Внимание', MB_TASKMODAL or MB_ICONWARNING);
      Exit;
    end;

    while not dsFiles.Eof do
    begin
      if not FileExists(dsFiles.FieldByName('FromFilePath').AsString) then
      begin
        Application.MessageBox(PChar('Не найден файл "'+dsFiles.FieldByName('FromFilePath').AsString+'"'),
          'Внимание', MB_TASKMODAL or MB_ICONWARNING);
        Exit;
      end;

      dsFiles.Next;
    end;

    dsFiles.First;
    Ord := 1;

    while not (dsFiles.Eof and dsSQL.Eof) do
    begin
      if not dsFiles.Eof and
        (dsFiles.FieldByName('Ord').AsInteger = Ord) then
      begin
        if dsFiles.FieldByName('IsDoExec').AsInteger=0 then
          PatchPartInfo.PartType := updFile
        else
          PatchPartInfo.PartType := updExec;

        fs := TFileStream.Create(dsFiles.FieldByName('FromFilePath').AsString, fmOpenRead);
        CompressedData.Clear;
        try
          ZCompressStream(fs, CompressedData, zcMax);
        finally
          FreeAndNil(fs);
        end;
        CompressedData.Seek(0, soFromBeginning);

        PatchPartInfo.PartSize := CompressedData.Size;
        PatchPartInfo.NextPartPos := RawData.Size + SizeOf(PatchPartInfo) +
          SizeOf(PatchFilePart) + CompressedData.Size;

        StrToArray(dsFiles.FieldByName('FileName').AsString, PatchFilePart.FileName);
        StrToArray(dsFiles.FieldByName('ToFilePath').AsString, PatchFilePart.ToFilePath);
        PatchFilePart.IsDoExec := dsFiles.FieldByName('IsDoExec').AsInteger;

        RawData.WriteBuffer(PatchPartInfo, SizeOf(PatchPartInfo));
        RawData.WriteBuffer(PatchFilePart, SizeOf(PatchFilePart));
        RawData.CopyFrom(CompressedData, CompressedData.Size);

        CompressedData.Clear;

        dsFiles.Next;
      end
      else
      if not dsSQL.Eof and
        (dsSQL.FieldByName('Ord').AsInteger = Ord) then
      begin
        CompressedData.Clear;
        TBlobField(dsSQL.FieldByName('SQLText')).SaveToStream(CompressedData);
        CompressedData.Seek(0, soFromBeginning);

        PatchPartInfo.PartType := updSQL;
        PatchPartInfo.PartSize := CompressedData.Size;
        PatchPartInfo.NextPartPos := RawData.Size + Sizeof(PatchPartInfo) +
          CompressedData.Size;

        RawData.WriteBuffer(PatchPartInfo, Sizeof(PatchPartInfo));
        RawData.CopyFrom(CompressedData, CompressedData.Size);

        CompressedData.Clear;

        dsSQL.Next;
      end;

      inc(Ord);
    end;

    CompressedData.Clear;
    RawData.Seek(0, soFromBeginning);
    ZCompressStream(RawData, CompressedData, zcMax);

    RawData.Clear;

    Store := TMemoryStream.Create;
    Sign := TMemoryStream.Create;
    try
      Base64_to_stream(PrivateKey, Store);
      Store.Seek(0, soFromBeginning);
      lbSignatory.LoadKeysFromStream(Store, [partPrivate]);
      CompressedData.Seek(0, soFromBeginning);
      lbSignatory.Sign(CompressedData, Sign);

      Sign.Seek(0, soFromBeginning);
      Sign.ReadBuffer(PatchFileHeader.Signature[0], SignSize);

      CompressedData.Seek(0, soFromBeginning);
      lbHash.HashStream(CompressedData);
      lbHash.HashOutputValue.Seek(0, soFromBeginning);
      lbHash.HashOutputValue.ReadBuffer(PatchFileHeader.FileHash[0], HashSize);
      lbHash.Burn;
    finally
      FreeAndNil(Store);
      FreeAndNil(Sign);
    end;

    fs := TFileStream.Create(UpdateFilePath + UpdateFileName, fmCreate);
    try
      fs.WriteBuffer(PatchFileHeader, SizeOf(PatchFileHeader));
      CompressedData.Seek(0, soFromBeginning);
      fs.CopyFrom(CompressedData, CompressedData.Size);
    finally
      FreeAndNil(fs);
    end;
  finally
    dsFiles.Close;
    dsSQL.Close;

    FreeAndNil(dsFiles);
    FreeAndNil(dsSQL);

    FreeAndNil(RawData);
    FreeAndNil(CompressedData);
  end;

  Application.MessageBox('Формирование файла завершено', 'Внимание',
    MB_TASKMODAL or MB_ICONASTERISK);
end;

procedure TfrmMain.cmProjectsEditExecute(Sender: TObject);
begin
  if ShowProjectForm(GetIDProject) then
  begin
    LoadProjectList(GetIDProject);
    cmbProjectsChange(self);
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Prepare;
end;

function TfrmMain.GetIDPart: Integer;
begin
  if mdParts.RecordCount>0 then
    Result := mdParts.FieldByName('ID').AsInteger
  else
    Result := 0;
end;

function TfrmMain.GetPartOrd: Integer;
begin
  if mdParts.RecordCount>0 then
    Result := mdParts.FieldByName('Ord').AsInteger
  else
    Result := 0;
end;

function TfrmMain.GetIDProject: Integer;
begin
  if cmbProjects.ItemIndex>-1 then
    Result := Integer(cmbProjects.Items.Objects[cmbProjects.ItemIndex])
  else
    Result := 0;
end;

function TfrmMain.GetIDUpdate: Integer;
begin
  if mdUpdates.RecordCount>0 then
    Result := mdUpdates.FieldByName('ID').AsInteger
  else
    Result := 0;
end;

procedure TfrmMain.LoadPartList(const AIDUpdate, AOrd: Integer);
var
  tmpDS: TDataSet;
begin
  if not mdParts.Active then
    mdParts.Open;
  mdParts.EmptyTable;

  if AIDUpdate>0 then
  begin
    mdParts.DisableControls;

    tmpDS :=
      GetDataSet(DM.fdCon,
        'select Id, Ord, PartDesc '+
        'from UpdateSQLParts '+
        'where IDUpdate=:IDUpdate ',
        [AIDUpdate]);
    try
      while not tmpDS.Eof do
      begin
        mdParts.Append;
        mdParts.FieldByName('ID').AsInteger := tmpDS.FieldByName('ID').AsInteger;
        mdParts.FieldByName('Ord').AsInteger := tmpDS.FieldByName('Ord').AsInteger;
        mdParts.FieldByName('Desc').AsString := tmpDS.FieldByName('PartDesc').AsString;
        mdParts.FieldByName('PartType').AsInteger := updSQL;
        mdParts.FieldByName('PartTypeName').AsString := 'SQL скрипт';
        mdParts.Post;

        tmpDS.Next;
      end;
    finally
      tmpDS.Close;
      FreeAndNil(tmpDS);
    end;

    tmpDS := GetDataSet(DM.fdCon,
      'select ID, Ord, FileName, IsDoExec, FromFilePath, ToFilePath '+
      'from UpdateFileParts '+
      'where IDUpdate=:IDUpdate ',
      [AIDUpdate]);
    try
      while not tmpDS.Eof do
      begin
        mdParts.Append;
        mdParts.FieldByName('ID').AsInteger := tmpDS.FieldByName('ID').AsInteger;
        mdParts.FieldByName('Ord').AsInteger := tmpDS.FieldByName('Ord').AsInteger;
        if tmpDS.FieldByName('IsDoExec').AsInteger=0 then
        begin
          mdParts.FieldByName('PartType').AsInteger := updFile;
          mdParts.FieldByName('PartTypeName').AsString := 'Файл';
        end
        else
        begin
          mdParts.FieldByName('PartType').AsInteger := updExec;
          mdParts.FieldByName('PartTypeName').AsString := 'Выполнить';
        end;
        mdParts.FieldByName('Desc').AsString :=
          'Имя файла: '+tmpDS.FieldByName('FileName').AsString+#13#10+
          'Откуда: '+tmpDS.FieldByName('FromFilePath').AsString+#13#10+
          'Куда: '+tmpDS.FieldByName('ToFilePath').AsString;
        mdParts.Post;

        tmpDS.Next;
      end;

      mdParts.SortByFields('Ord');

      if (AOrd=0)
        or not mdParts.Locate('Ord', AOrd, []) then
        mdParts.First;
    finally
      mdParts.EnableControls;

      tmpDS.Close;
      FreeAndNil(tmpDS);
    end;
  end;
end;

procedure TfrmMain.LoadProjectList(const AIDProject: Integer);
begin
  cmbProjects.OnChange := nil;
  cmbProjects.Clear;

  FillDataSet(fdQry,
    'select ID, ProjectName, ProjectDesc '+
    'from Projects '+
    'where IsEnabled=1 '+
    'order by ProjectName ', []);

  try
    while not fdQry.Eof do
    begin
      cmbProjects.Items.AddObject(fdQry.FieldByName('ProjectName').AsString + ' - ' +
        fdQry.FieldByName('ProjectDesc').AsString,
        TObject(fdQry.FieldByName('ID').AsInteger));
      fdQry.Next;
    end;
  finally
    fdQry.Close;
  end;

  if cmbProjects.Items.Count>0 then
  begin
    cmbProjects.Items.indexOfObject(TObject(AIDProject));
    if cmbProjects.ItemIndex=-1 then
      cmbProjects.ItemIndex := 0;
  end;

  cmbProjects.OnChange := cmbProjectsChange;
end;

procedure TfrmMain.LoadUpdateList(const AIDProject, AIDUpdate: Integer);
begin
  mdUpdates.AfterScroll := nil;

  if not mdUpdates.Active then
    mdUpdates.Open;
  mdUpdates.EmptyTable;

  if AIDProject>0 then
  begin
    FillDataSet(fdQry,
      'select ID, Ord, FileName, UpdateDesc, CreateDateTime, UpdateDBVersionTo, UpdateAppVersionTo '+
      'from Updates '+
      'where IDProject=:IDProject '+
      'order by Ord', [AIDProject]);

    mdUpdates.DisableControls;

    try
      while not fdQry.Eof do
      begin
        mdUpdates.Append;
        mdUpdates.FieldByName('ID').AsInteger := fdQry.FieldByName('ID').AsInteger;
        mdUpdates.FieldByName('Ord').AsInteger := fdQry.FieldByName('Ord').AsInteger;
        mdUpdates.FieldByName('Desc').AsString :=
          'Файл: ' + fdQry.FieldByName('FileName').AsString + #13#10+
          'Создан: ' + FormatDateTime('dd.mm.yyyy, HH:mm', fdQry.FieldByName('CreateDateTime').AsDateTime) + #13#10+
          'Описание: ' + fdQry.FieldByName('UpdateDesc').AsString+#13#10 +
          'Версии: БД - '+IfThen(fdQry.FieldByName('UpdateDBVersionTo').AsInteger=0, '(нет)', fdQry.FieldByName('UpdateDBVersionTo').AsString)+
          ', прил. - '+IfThen(fdQry.FieldByName('UpdateAppVersionTo').AsInteger=0, '(нет)', fdQry.FieldByName('UpdateAppVersionTo').AsString);
        mdUpdates.Post;

        fdQry.Next;
      end;
    finally
      fdQry.Close;

      if (AIDUpdate=0)
        or not mdUpdates.Locate('ID', AIDUpdate, []) then
        mdUpdates.First;

      mdUpdates.EnableControls;
    end;
  end;

  mdUpdates.AfterScroll := mdUpdatesAfterScroll;
end;

procedure TfrmMain.mdPartsAfterScroll(DataSet: TDataSet);
begin
  cmEditUpdatePart.Enabled := mdParts.Active and (mdParts.RecordCount>0);
  cmDeleteUpdatePart.Enabled := mdParts.Active and (mdParts.RecordCount>0);
end;

procedure TfrmMain.mdUpdatesAfterScroll(DataSet: TDataSet);
begin
  LoadPartList(GetIDUpdate);

  cmEditUpdate.Enabled := mdUpdates.Active and (mdUpdates.RecordCount>0);
  cmDeleteUpdate.Enabled := mdUpdates.Active and (mdUpdates.RecordCount>0);
  cmGenUpdateFile.Enabled := mdUpdates.Active and (mdUpdates.RecordCount>0);

  cmAddSQLUpdatePart.Enabled := mdUpdates.Active and (mdUpdates.RecordCount>0);
  cmAddFileUpdatePart.Enabled := mdUpdates.Active and (mdUpdates.RecordCount>0);

  mdPartsAfterScroll(mdParts);
end;

procedure TfrmMain.Prepare;
begin
  LoadProjectList;
  LoadUpdateList(GetIDProject);
  LoadPartList(GetIDUpdate);
end;

end.
