program PatchPacker;

uses
  Forms,
  unfrmMain in 'unfrmMain.pas' {frmMain},
  unConst in 'unConst.pas',
  unDM in 'unDM.pas' {DM: TDataModule},
  unfrmProjects in 'unfrmProjects.pas' {frmProjects},
  unfrmProjectEdit in 'unfrmProjectEdit.pas' {frmProjectEdit},
  unfrmUpdateEdit in 'unfrmUpdateEdit.pas' {frmUpdateEdit},
  unUpdateSQLPartEdit in 'unUpdateSQLPartEdit.pas' {frmUpdateSQLPartEdit},
  unfrmUpdateFilePartEdit in 'unfrmUpdateFilePartEdit.pas' {frmUpdateFilePartEdit};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  if ConnectDB then
  begin
    unConst.Prepare;
    Application.CreateForm(TfrmMain, frmMain);
    Application.Run;
  end;
end.
