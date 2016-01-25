unit unfrmProjectEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, Buttons, ExtCtrls,
  unDM, DB;

type
  TfrmProjectEdit = class(TForm)
    pnlBottom: TPanel;
    pnlCancel: TPanel;
    btnCancel: TBitBtn;
    btnSave: TBitBtn;
    lblProjectName: TLabel;
    lblProjectDesc: TLabel;
    edProjectName: TEdit;
    mmProjectDesc: TMemo;
    chbIsEnabled: TCheckBox;
    lblExeName: TLabel;
    edExeName: TEdit;
    procedure btnSaveClick(Sender: TObject);
  private
    FIDProject: Integer;
    FIsEdit: Boolean;

    procedure Prepare;
  public
    { Public declarations }
  end;

  function AddProject(var ANewIDProject: Integer): Boolean;

  function EditProject(const AIDProject: Integer): Boolean;

implementation

{$R *.dfm}

uses unSQLiteDSUtils_FD, Math;

function AddProject(var ANewIDProject: Integer): Boolean;
var
  f: TfrmProjectEdit;
begin
  Application.CreateForm(TfrmProjectEdit, f);
  try
    with f do
    begin
      FIsEdit := False;
      Prepare;
      Result := ShowModal = mrOk;
      if Result then
        ANewIDProject := FIDProject;
    end;
  finally
    FreeAndNil(f);
  end;
end;

function EditProject(const AIDProject: Integer): Boolean;
var
  f: TfrmProjectEdit;
begin
  Application.CreateForm(TfrmProjectEdit, f);
  try
    with f do
    begin
      FIsEdit := True;
      FIDProject := AIDProject;
      Prepare;
      Result := ShowModal = mrOk;
    end;
  finally
    FreeAndNil(f);
  end;
end;

{ TfrmProjectEdit }

procedure TfrmProjectEdit.btnSaveClick(Sender: TObject);

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
  if Trim(edProjectName.Text)='' then
  begin
    Application.MessageBox('Не указано имя проекта', 'Внимание',
      MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if not HaveOnlyAlowedChars(Trim(edProjectName.Text)) then
  begin
    Application.MessageBox('В имени проекта имеются недопустимые символы',
      'Внимание', MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if Trim(mmProjectDesc.Lines.Text)='' then
  begin
    Application.MessageBox('Не описание проекта', 'Внимание',
      MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if GetInt(DM.fdCon,
      'select count(*) '+
      'from Projects '+
      'where ProjectName=:ProjectName and ID<>:IDProject',
      [Trim(edProjectName.Text), IfThen(FIsEdit, FIDProject, 0)])>0 then
  begin
    Application.MessageBox('В БД уже имеется проект с таким же именем',
      'Внимание', MB_TASKMODAL or MB_ICONWARNING);
    Exit;
  end;

  if FIsEdit then
    ExecuteSQL(DM.fdCon,
      'update Projects '+
      'set '+
      ' ProjectName=:ProjectName, '+
      ' ExeName=:ExeName, '+
      ' ProjectDesc=:ProjectDesc, '+
      ' IsEnabled=:IsEnabled '+
      'where ID=:IDProject',
      [ftString, ftString, ftWideString, ftSmallInt, ftSmallInt],
      [Trim(edProjectName.Text), Trim(edExeName.Text), Trim(mmProjectDesc.Lines.Text),
       IfThen(chbIsEnabled.Checked, 1, 0), FIDProject])
  else
    ExecuteSQL(DM.fdCon,
      'insert into Projects(ProjectName, ExeName, ProjectDesc, IsEnabled) '+
      'values(:ProjectName, :ExeName, :ProjectDesc, :IsEnabled)',
      [ftString, ftString, ftWideString, ftSmallInt],
      [Trim(edProjectName.Text), Trim(edExeName.Text), Trim(mmProjectDesc.LInes.Text),
       IfThen(chbIsEnabled.Checked, 1, 0)]);

  ModalResult := mrOk;
end;

procedure TfrmProjectEdit.Prepare;
var
  ds: TDataSet;
begin
  if FIsEdit then
  begin
    ds := GetDataSet(DM.fdCon,
            'select ProjectName, ProjectDesc, ExeName, IsEnabled '+
            'from Projects '+
            'where ID=:IDProject', [FIDProject]);
    try
      edProjectName.Text := ds.FieldByName('ProjectName').AsString;
      edExeName.Text := ds.FieldByName('ExeName').AsString;
      mmProjectDesc.Lines.Text := ds.FieldByName('ProjectDesc').AsString;
      chbIsEnabled.Checked := ds.FieldByName('IsEnabled').AsInteger = 1;
    finally
      ds.Close;
      FreeAndNil(ds);
    end;
  end
  else
  begin
    edProjectName.Clear;
    mmProjectDesc.Clear;
  end;
end;

end.
