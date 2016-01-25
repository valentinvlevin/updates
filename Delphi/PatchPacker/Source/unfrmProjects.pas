unit unfrmProjects;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Forms,

  DBGridEhGrouping, ToolCtrlsEh, DBGridEhToolCtrls, DynVarsEh, MemTableDataEh,
  DB, MemTableEh, GridsEh, DBAxisGridsEh, DBGridEh, unDM,
  TPLB3.CryptographicLibrary,
  TPLB3.BaseNonVisualComponent, TPLB3.Hash, uADStanIntf, uADStanOption,
  uADStanParam, uADStanError, uADDatSManager, uADPhysIntf, uADDAptIntf,
  uADStanAsync, uADDAptManager, ActnList, uADCompDataSet, uADCompClient,
  EhLibVCL, StdCtrls, Buttons, Controls, ExtCtrls;

type
  TfrmProjects = class(TForm)
    pnlBottom: TPanel;
    pnlExit: TPanel;
    btnExit: TBitBtn;
    dbg: TDBGridEh;
    ds: TDataSource;
    md: TMemTableEh;
    fdQry: TADQuery;
    btnAdd: TBitBtn;
    btnEdit: TBitBtn;
    btnDelete: TBitBtn;
    Actions: TActionList;
    cmAdd: TAction;
    cmEdit: TAction;
    cmDelete: TAction;
    BitBtn1: TBitBtn;
    cmGetAppVerFile: TAction;
    lbHash: THash;
    lbCryptographicLibrary: TCryptographicLibrary;
    procedure cmAddExecute(Sender: TObject);
    procedure cmEditExecute(Sender: TObject);
    procedure cmDeleteExecute(Sender: TObject);
    procedure cmGetAppVerFileExecute(Sender: TObject);
  private
    FHaveChanges: Boolean;

    procedure LoadProjectList(const AIDProject: Integer = 0);
    procedure Prepare;
  public
    { Public declarations }
  end;

  function ShowProjectForm(const AIDProject: Integer): Boolean;

implementation

uses
  unSQLiteDSUtils_FD, unfrmProjectEdit, unConst;

{$R *.dfm}

function ShowProjectForm(const AIDProject: Integer): Boolean;
var
  f: TfrmProjects;
begin
  Application.CreateForm(TfrmProjects, f);
  try
    with f do
    begin
      Prepare;
      ShowModal;
      Result := FHaveChanges;
    end;
  finally
    FreeAndNil(f);
  end;
end;

{ TfrmProjects }

procedure TfrmProjects.cmAddExecute(Sender: TObject);
var
  NewIDProject: Integer;
begin
  if AddProject(NewIDProject) then
  begin
    LoadProjectList(NewIDProject);
    FHaveChanges := True;
  end;
end;

procedure TfrmProjects.cmDeleteExecute(Sender: TObject);
begin
  if (md.RecordCount>0)
    and (Application.MessageBox(Pchar('Удалить проект '+md.FieldByName('ProjectName').AsString+'?'),
          'Подтверждение', MB_TASKMODAL or MB_ICONQUESTION or MB_YESNO or MB_DEFBUTTON2)=id_yes) then
  begin
    StartTransaction(DM.fdCon);
    try
      ExecuteSQL(DM.fdCon,
        'delete from UpdateFileParts '+
        'where IDUpdate in '+
        ' ( '+
        '   select ID from Updates where IDProject=:IDProject '+
        ' ) ', [ftInteger], [md.FieldByName('ID').AsInteger], False);

      ExecuteSQL(DM.fdCon,
        'delete from UpdateSQLParts '+
        'where IDUpdate in '+
        ' ( '+
        '   select ID from Updates where IDProject=:IDProject '+
        ' ) ', [ftInteger], [md.FieldByName('ID').AsInteger], False);
      ExecuteSQL(DM.fdCon,
        'delete from Updates '+
        'where IDProject=:IDProject ',
        [ftInteger], [md.FieldByName('ID').AsInteger], False);
      ExecuteSQL(DM.fdCon,
        'delete from Projects where ID=:IDProject ',
        [ftInteger], [md.FieldByName('ID').AsInteger], False);

      md.Delete;

      CommitTransaction(DM.fdCon);

      FHaveChanges := True;
    except
      on e: Exception do
      begin
        RollbackTransaction(DM.fdCon);
        Application.MessageBox(PChar('Ошибка при работе с БД: '#13+e.Message),
          'Ошибка', MB_TASKMODAL or MB_ICONWARNING);
        Exit;
      end;
    end;
  end;
end;

procedure TfrmProjects.cmEditExecute(Sender: TObject);
begin
  if (md.RecordCount>0)
    and EditProject(md.FieldByName('ID').AsInteger) then
  begin
    FHaveChanges := True;
    LoadProjectList(md.FieldByName('ID').AsInteger);
  end;
end;

procedure TfrmProjects.cmGetAppVerFileExecute(Sender: TObject);
var
  FilePath: string;
  fs: TFileStream;
  AppInfoFileHeader: TAppInfoFileHeader;
  AppInfo: TAppInfo;
begin
  if md.Active
    and (md.RecordCount>0) then
  begin
    FilePath := GetAppPath + UpdateFileDir + '\' + md.FieldByName('ProjectName').AsString+'\';
    if not DirectoryExists(FilePath) then
      ForceDirectories(FilePath);

    fs := TFileStream.Create(FilePath + AppFileName, fmCreate);
    try
      AppInfoFileHeader.FileSign := AppFileSign;
      AppInfoFileHeader.CreateDateTime := Now;

      AppInfo.ProjectName := md.FieldByName('ProjectName').AsAnsiString;
      AppInfo.AppVersion := 1;
      AppInfo.ExeName := md.FieldByName('ExeName').AsAnsiString;

      lbHash.HashBytes(BytesOf(@AppInfo, SizeOf(AppInfo)));

      lbHash.HashOutputValue.Seek(0, soFromBeginning);
      lbHash.HashOutputValue.ReadBuffer(AppInfoFileHeader.FileHash[0], HashSize);

      lbHash.Burn;

      fs.WriteBuffer(AppInfoFileHeader, SizeOf(AppInfoFileHeader));
      fs.WriteBuffer(AppInfo, SizeOf(AppInfo));
    finally
      FreeAndNil(fs);
    end;

    Application.MessageBox('Завершено', 'Внимание',
      MB_TASKMODAL or MB_ICONASTERISK);
  end;
end;

procedure TfrmProjects.LoadProjectList(const AIDProject: Integer);
begin
  if not md.Active then
    md.Open;
  md.EmptyTable;

  md.DisableControls;

  FillDataSet(fdQry,
    'select ID, ProjectName, ProjectDesc, ExeName, IsEnabled '+
    'from Projects '+
    'order by ID', []);

  try
    while not fdQry.Eof do
    begin
      md.Append;
      md.FieldByName('ID').AsInteger := fdQry.FieldByName('ID').AsInteger;
      md.FieldByName('ProjectName').AsString := fdQry.FieldByName('ProjectName').AsString;
      md.FieldByName('ProjectDesc').AsString := fdQry.FieldByName('ProjectDesc').AsString;
      md.FieldByName('ExeName').AsString := fdQry.FieldByName('ExeName').AsString;
      if fdQry.FieldByName('IsEnabled').AsInteger = 1 then
        md.FieldByName('IsEnabled').AsString := 'да'
      else
        md.FieldByName('IsEnabled').AsString := 'нет';
      md.Post;

      fdQry.Next;
    end;
  finally
    if fdQry.Active then
      fdQry.Close;
    md.First;
    md.EnableControls;
  end;
end;

procedure TfrmProjects.Prepare;
begin
  FHaveChanges := False;
  LoadProjectList;
end;

end.
