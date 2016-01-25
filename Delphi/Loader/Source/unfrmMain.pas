unit unfrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants,
  Classes, Graphics,
  Controls, Forms, Dialogs,
  Grids, DBGrids, ExtCtrls, StdCtrls, clHttpRequest,
  clTcpClient, clHttp, ComCtrls, TPLB3.Signatory, TPLB3.Hash,
  TPLB3.CryptographicLibrary, TPLB3.BaseNonVisualComponent, TPLB3.Codec,
  Buttons, ActnList, DBGridEhGrouping, ToolCtrlsEh,
  DBGridEhToolCtrls, DynVarsEh, MemTableDataEh, DB, MemTableEh, GridsEh,
  DBAxisGridsEh, DBGridEh, unConst, TPLB3.Asymetric, undmUpd, Db, ActnList,
  Buttons, EhLibVCL;

type
  TfrmMain = class(TForm)
    DBGrid: TDBGridEh;
    dsUpdates: TDataSource;
    pnlBottom: TPanel;
    btnDownloadUpdate: TBitBtn;
    clHttp: TclHttp;
    clHttpRequest: TclHttpRequest;
    pnlExit: TPanel;
    btnCancel: TBitBtn;
    Actions: TActionList;
    cmDownload: TAction;
    md: TMemTableEh;
    procedure clHttpReceiveProgress(Sender: TObject; ABytesProceed,
      ATotalBytes: Int64);
    procedure cmDownloadExecute(Sender: TObject);
    procedure DBGrid1Columns1AdvDrawDataCell(Sender: TCustomDBGridEh; Cell,
      AreaCell: TGridCoord; Column: TColumnEh; const ARect: TRect;
      var Params: TColCellParamsEh; var Processed: Boolean);
  private
    FAppInfo: TAppInfo;
    FDBVersion: Integer;
    FHostName: string;
    FIsLoader: Boolean;

    function OpenAppVer(var AAppInfo: TAppInfo): Boolean;
    function GetDBVersion(const AExeName: string;
      out ADBVersion: Integer): Boolean;

    function HaveAliveServer(const AReceiverId: string;
      out AAliveHostName: string): Boolean;

    function HaveNewUpdates(const AHostName, AReceiverId, AProjectName: string;
      const AAppVersion, ADBVersion: Integer): Boolean;

    procedure LoadUpdateList(const AUpdates: TJSONArray;
      const AAppVersion, ADBVersion: Integer);

    function DownloadUpdates(const AReceiverId: string): Boolean;
    function InstallUpdates: Boolean;

    procedure SetProxyParams(AclHTTP: TclHttp);

    function InstallUpdate(const AFileName: string;
      out AErrorMsg: string): Boolean;

    procedure UpdateAppVersion(const AUpdateTo: Integer);
  public
    { Public declarations }
  end;

  function CheckUpdates(var AExeName: string): Boolean;

implementation

uses unProxyParams, unFunc, TPLB3.StreamUtils, zLibEx, StrUtils;

function CheckUpdates(var AExeName: string): Boolean;
var
  f: TfrmMain;
begin
  Result := False;
  if FileExists(GetAppPath + AppFileName) then
  begin
    Application.CreateForm(TfrmMain, f);
    try
      with f do
      begin
        if OpenAppVer(FAppInfo) then
        begin
          Result := True;
          AExeName := string(FAppInfo.ExeName);
          if HaveAliveServer(string(FAppInfo.ReceiverId), FHostName) then
          begin
            FIsLoader := True;
            if HaveNewUpdates(FHostName, string(FAppInfo.ReceiverId), LoaderProjectName, LoaderVersion, 0) then
            begin
              if ShowModal = mrOk then
                RunProcess(GetAppPath + AExeName + ' UPDATELOADER '+IntToStr(LoaderVersion), SW_SHOW, False, nil);
              Exit;
            end;

            FIsLoader := False;

            if GetDBVersion(string(FAppInfo.ExeName), FDBVersion)
              and HaveNewUpdates(FHostName, string(FAppInfo.ReceiverId), string(FAppInfo.ProjectName),
                  FAppInfo.AppVersion, FDBVersion) then
            ShowModal;
          end;
        end;
      end;
    finally
      FreeAndNil(f);
    end;
  end;
end;

{$R *.dfm}


procedure TfrmMain.clHttpReceiveProgress(Sender: TObject; ABytesProceed,
  ATotalBytes: Int64);
begin
  if md.Active
    and (md.RecordCount>0)
    and (md.FieldByName('Status').AsInteger = psDownloading) then
  begin
    md.Edit;
    md.FieldByName('ReceivedBytes').AsInteger := ABytesProceed;
    md.FieldByName('sStatus').AsString := '';
    md.Post;

    DBGrid.Repaint;
  end;
end;

procedure TfrmMain.cmDownloadExecute(Sender: TObject);
var
  OldRecNo: Integer;
begin
  OldRecNo := md.RecNo;
  md.DisableControls;
  cmDownload.Enabled := False;

  try
    if DownloadUpdates(string(FAppInfo.ReceiverId)) then
    begin
      if not FIsLoader then
      begin
        if InstallUpdates then
        begin
          Application.MessageBox('Установка обновлений завершена', 'Внимание',
            MB_TASKMODAL or MB_ICONASTERISK);
          ModalResult := mrOk;
        end;
      end
      else
        ModalResult := mrOk;
    end;

  finally
    md.RecNo := OldRecNo;
    md.EnableControls;

    cmDownload.Enabled := True;
  end;
end;

procedure TfrmMain.DBGrid1Columns1AdvDrawDataCell(Sender: TCustomDBGridEh; Cell,
  AreaCell: TGridCoord; Column: TColumnEh; const ARect: TRect;
  var Params: TColCellParamsEh; var Processed: Boolean);
begin
  Sender.DefaultDrawColumnDataCell(Cell, AreaCell, Column, ARect, Params);
  if md.Active
    and (md.RecordCount>0)
    and (md.FieldbyName('Status').AsInteger = psDownloading) then
  begin
    DrawProgressBarEh(md.FieldByName('ReceivedBytes').AsInteger, 0,
      md.FieldByName('FileSize').AsInteger, Sender.Canvas, ARect,
      clSkyBlue, cl3DDkShadow, clNone);
    Processed := True;
  end;
end;

function TfrmMain.DownloadUpdates(const AReceiverId: string): Boolean;
const
  ResourceName = 'update';
var
  ms: TMemoryStream;
  UpdateFilePath: string;
begin
  Result := False;

  SetProxyParams(clHttp);
  clHttpRequest.Header.Accept := 'application/octet-stream';

  ms := TMemoryStream.Create;
  clHttp.OnReceiveProgress := clHttpReceiveProgress;

  try
    md.First;
    while not md.Eof do
    begin
      if md.FieldByName('Status').AsInteger in [psNone, psError] then
      begin
        UpdateFilePath := GetAppPath + UpdateFileDir + '\' +
          IfThen(FIsLoader, '0', md.FieldByName('Ord').AsString) + '\';
        if not DirectoryExists(UpdateFilePath) then
          ForceDirectories(UpdateFilePath);

        if FileExists(UpdateFilePath + md.FieldByName('FileName').AsString)
          and not DeleteFile(UpdateFilePath + md.FieldByName('FileName').AsString) then
        begin
          md.Edit;
          md.FieldByName('Status').AsInteger := psError;
          md.FieldByName('sStatus').AsString := 'Не удален старый файл';
          md.Post;
        end;

        md.Edit;
        md.FieldByName('Status').AsInteger := psDownloading;
        md.FieldByName('sStatus').AsString := 'Производится скачивание';
        md.Post;

        if ms.Size>0 then
          ms.Clear;

        try
          clHttp.Get(FHostName + ResourceName +
          '?updateId='+md.FieldByName('ID').AsString+
          '&receiverId='+IfThen(AReceiverId='', 'none', string(AReceiverId)), ms);
        except
          on e: Exception do
          begin
            md.Edit;
            md.FieldByName('Status').AsInteger := psError;
            md.FieldByName('sStatus').AsString := 'Ошибка при скачивании: '+e.Message;
            md.Post;

            Exit;
          end;
        end;

        if clHttp.StatusCode = 200 then
        begin
          ms.Seek(0, soFromBeginning);

          if CheckUpdateInStream(ms) then
          begin
            ms.Seek(0, soFromBeginning);
            ms.SaveToFile(UpdateFilePath+md.FieldByName('FileName').AsString);

            md.Edit;
            md.FieldbyName('Status').AsInteger := psDownloaded;
            md.FieldbyName('sStatus').AsString := 'Загружен';
            md.Post;
          end
          else
          begin
            md.Edit;
            md.FieldbyName('Status').AsInteger := psError;
            md.FieldbyName('sStatus').AsString := 'Ошибки в полученном файле';
            md.Post;

            Exit;
          end;
        end
        else
        begin
          md.Edit;
          md.FieldByName('Status').AsInteger := psError;
          md.FieldByName('sStatus').AsString := 'Ошибка при скачивании';
          md.Post;

          Exit;
        end;

        ms.Clear;
      end;
      md.Next;
    end;

    Result := True;
  finally
    FreeAndNil(ms);
    clHttp.OnReceiveProgress := nil;
  end;

end;

function TfrmMain.GetDBVersion(const AExeName: string;
  out ADBVersion: Integer): Boolean;
var
  ProcID: Cardinal;
  ExitCode: LongWord;
begin
  Result := False;
  if FileExists(GetAppPath + AExeName) then
  begin
    ExitCode := RunProcess(GetAppPath + AExeName+' DBVersion', SW_HIDE, True, @ProcID);
    Result := ExitCode <> WAIT_FAILED;
    if Result then
      ADBVersion := ExitCode;
  end;
end;

function TfrmMain.HaveNewUpdates(const AHostName, AReceiverId: string;
  const AProjectName: string; const AAppVersion, ADBVersion: Integer): Boolean;
const
  ResourceName = 'updates';
var
  sUpdates: TStringList;
  jsonUpdates: TJSONArray;
  jsonUpdate: TJSONObject;
  UpdateIndex: Integer;
begin
  Result := False;

  sUpdates := TStringList.Create;

  try
    SetProxyParams(clHttp);
    clHttpRequest.Header.Accept := 'application/json';
    try
      clHttp.Get(FHostName+ResourceName+'?projectName='+AProjectName+
        '&receiverId='+IfThen(AReceiverId='', 'none', AReceiverId), sUpdates);
    except
      Exit;
    end;

    if clHttp.StatusCode = 200 then
    begin
      jsonUpdates := TJSONObject.ParseJSONValue(UTF8ToWideString(RawByteString(sUpdates.Text))) as TJSONArray;

      UpdateIndex := 0;
      while (jsonUpdates.Count>UpdateIndex) and not Result do
      begin
        jsonUpdate := jsonUpdates.Items[UpdateIndex] as TJSONObject;

        Result := ((jsonUpdate.Values['updateDBVersionTo'] as TJSONNumber).AsInt>ADBVersion)
          or ((jsonUpdate.Values['updateAppVersionTo'] as TJSONNumber).AsInt>AAppVersion);

        inc(UpdateIndex);
      end;

      if Result then
        LoadUpdateList(jsonUpdates, AAppVersion, ADBVersion);
    end;
  finally
    FreeAndNil(sUpdates);
  end;

end;

function TfrmMain.InstallUpdate(const AFileName: string;
  out AErrorMsg: string): Boolean;

type
  TReplacedFile = record
    BakFilePath: string;
    ToFilePath: string;
    FileName: string;
  end;

  procedure RestoreFiles(const AReplacedFiles: array of TReplacedFile;
    const AReplacedFileCount: Integer);
  var
    Index: Integer;
  begin
    for Index := 0 to AReplacedFileCount - 1 do
    begin
      if FileExists(AReplacedFiles[Index].ToFilePath + AReplacedFiles[Index].FileName) then
        DeleteFile(AReplacedFiles[Index].ToFilePath + AReplacedFiles[Index].FileName);
      MoveFile(PChar(AReplacedFiles[Index].BakFilePath + AReplacedFiles[Index].FileName),
        PChar(AReplacedFiles[Index].ToFilePath + AReplacedFiles[Index].FileName));
    end;
  end;

var
  BakFilePath, ToFilePath, FileName: string;
  fs: TFileStream;
  CompressedData, RawData: TMemoryStream;
  PatchFileHeader: TPatchFileHeader;
  PatchPartInfo: TPatchPartInfo;
  PatchFilePart: TPatchFilePart;

  PartIndex: Integer;

  ProcID: Cardinal;
  ExitCode: LongWord;

  ReplacedFileCount: Integer;
  ReplacedFiles: array of TReplacedFile;

begin
  Result := False;

  if not CheckUpdateInFile(AFileName) then
  begin
    AErrorMsg := 'Файл испорчен';
    Exit;
  end;

  BakFilePath := ExtractFilePath(AFileName) + 'Bak\';

  CompressedData := TMemoryStream.Create;
  RawData := TMemoryStream.Create;

  ReplacedFileCount := 0;
  ReplacedFiles := nil;

  try
    try
      fs := TFileStream.Create(AFileName, fmOpenRead);
      fs.ReadBuffer(PatchFileHeader, SizeOf(TPatchFileHeader));
      try
        CompressedData.CopyFrom(fs, fs.Size - fs.Position);
      finally
        FreeAndNil(fs);
      end;
      CompressedData.Seek(0, soFromBeginning);
      ZDecompressStream(CompressedData, RawData);
      RawData.Seek(0, soFromBeginning);
      CompressedData.Clear;

      ReplacedFileCount := 0;
      SetLength(ReplacedFiles, PatchFileHeader.PartCount);

      for PartIndex := 0 to PatchFileHeader.PartCount-1 do
      begin
        RawData.ReadBuffer(PatchPartInfo, SizeOf(TPatchPartInfo));
        case PatchPartInfo.PartType of
          updFile, updExec:
            begin
              RawData.ReadBuffer(PatchFilePart, SizeOf(TPatchFilePart));

              if pos(':', ArrayToStr(PatchFilePart.ToFilePath))>0 then
                ToFilePath := ArrayToStr(PatchFilePart.ToFilePath)
              else
                ToFilePath := GetAppPath + ArrayToStr(PatchFilePart.ToFilePath);
              if ToFilePath[ToFilePath.Length]<>'\' then
                ToFilePath := ToFilePath + '\';
              FileName := ArrayToStr(PatchFilePart.FileName);

              if FileExists(ToFilePath + FileName) then
              begin
                if PatchPartInfo.PartType = updFile then
                begin
                  if not DirectoryExists(BakFilePath) then
                    ForceDirectories(BakFilePath);
                  if FileExists(BakFilePath + FileName)
                    and not DeleteFile(BakFilePath + FileName) then
                  begin
                    AErrorMsg := 'Не удалось удалить старую копию файла (1)';
                    Exit;
                  end;
                  if not MoveFile(PChar(ToFilePath + FileName), PChar(BakFilePath + FileName)) then
                  begin
                    AErrorMsg := 'Не удалось записать файл';
                    Exit;
                  end;
                end
                else
                  if not DeleteFile(ToFilePath + FileName) then
                  begin
                    AErrorMsg := 'Не удалось удалить старую копию файла (2)';
                    Exit;
                  end;

                inc(ReplacedFileCount);
                ReplacedFiles[ReplacedFileCount-1].BakFilePath := BakFilePath;
                ReplacedFiles[ReplacedFileCount-1].ToFilePath := ToFilePath;
                ReplacedFiles[ReplacedFileCount-1].FileName := FileName;
              end;

              fs := TFileStream.Create(ToFilePath + FileName, fmCreate);
              try
                CompressedData.CopyFrom(RawData, PatchPartInfo.PartSize);
                CompressedData.Seek(0, soFromBeginning);
                ZDecompressStream(CompressedData, fs);
              finally
                FreeAndNil(fs);
              end;

              if PatchPartInfo.PartType = updExec then
              begin
                try
                  RunProcess(GetAppPath + FileName, SW_SHOW, True, nil);
                except
                  on e: Exception do
                  begin
                    AErrorMsg := 'Ошибка при запуске файла: '+e.Message;
                    Exit;
                  end;
                end;

                DeleteFile(ToFilePath + FileName);
              end
            end;
          updSQL:
            RawData.Seek(PatchPartInfo.NextPartPos, soFromBeginning);
        end;
      end;

      if PatchFileHeader.UpdateDBVersionTo>FDBVersion then
      begin
        ExitCode := RunProcess(GetAppPath + string(FAppInfo.ExeName)+' EXECSQL "'+AFileName+'"',
                      SW_HIDE, True, @ProcID);
        if ExitCode <> 1 then
        begin
          AErrorMsg := 'Ошибка при обновлении базы данных';
          Exit;
        end;
      end;
    except
      on E: Exception do
      begin
        Application.MessageBox(PChar('Ошибка при работе: '#13+e.Message),
          'Внимание', MB_TASKMODAL or MB_ICONWARNING)
      end;
    end;

    UpdateAppVersion(PatchFileHeader.UpdateAppVersionTo);

    Result := True;
  finally
    FreeAndNil(CompressedData);
    FreeAndNil(RawData);

    if not Result
      and (ReplacedFileCount>0) then
      RestoreFiles(ReplacedFiles, ReplacedFileCount);
    ReplacedFiles := nil;
  end;
end;

function TfrmMain.InstallUpdates: Boolean;
var
  UpdateFilePath, ErrorStr: string;
begin
  Result := True;

  md.First;
  while not md.Eof do
  begin
    if md.FieldByName('Status').AsInteger = psDownloaded then
    begin
      md.Edit;
      md.FieldByName('Status').AsInteger := psProcessing;
      md.FieldByName('sStatus').AsString := 'В обработке';
      md.Post;

      UpdateFilePath := GetAppPath + UpdateFileDir + '\' + IfThen(FIsLoader, '0', md.FieldByName('Ord').AsString) + '\';
      if InstallUpdate(UpdateFilePath + md.FieldByName('FileName').AsString, ErrorStr) then
      begin
        md.Edit;
        md.FieldByName('Status').AsInteger := psProcessed;
        md.FieldByName('sStatus').AsString := 'Завершено';
        md.Post;
      end
      else
      begin
        md.Edit;
        md.FieldByName('Status').AsInteger := psError;
        md.FieldByName('sStatus').AsString := ErrorStr;
        md.Post;

        Result := False;

        Break;
      end;
    end;

    md.Next;
  end;
end;

function TfrmMain.HaveAliveServer(const AReceiverId: string;
  out AAliveHostName: string): Boolean;
const
  ResourceName = 'isServiceAlive';
var
  HostIndex: Integer;
begin
  clHttp.Request.Header.Accept := 'text/plain';
  SetProxyParams(clHttp);
  for HostIndex := 0 to HostCount-1 do
  begin
    try
      clHttp.Head(HostNames[HostIndex] + ResourceName + '?receiverId='+IfThen(AReceiverId='', 'none', AReceiverId));
    except

    end;

    Result := clHttp.StatusCode = 200;
    if Result then
      AAliveHostName := HostNames[HostIndex];
  end;
end;

procedure TfrmMain.LoadUpdateList(const AUpdates: TJSONArray;
  const AAppVersion, ADBVersion: Integer);
var
  jsonUpdate: TJSONObject;
  UpdateIndex: Integer;
  UpdateFilePath: string;
begin
  if not md.Active then
    md.Open;
  md.EmptyTable;

  md.DisableControls;

  UpdateFilePath := GetAppPath + UpdateFileDir + '\';

  try
    for UpdateIndex := 0 to AUpdates.Count-1 do
    begin
      jsonUpdate := AUpdates.Items[UpdateIndex] as TJSONObject;

      md.Append;
      md.FieldByName('ID').AsInteger := (jsonUpdate.Values['id'] as TJSONNumber).AsInt;
      md.FieldByName('Ord').AsInteger := (jsonUpdate.Values['ord'] as TJSONNumber).AsInt;
      md.FieldByName('Desc').AsString := jsonUpdate.Values['desc'].Value;
      md.FieldByName('FileName').AsString := jsonUpdate.Values['fileName'].Value;
      md.FieldByName('FileSize').AsInteger := (jsonUpdate.Values['fileSize'] as TJSONNumber).AsInt;
      if FileExists(UpdateFilePath + IfThen(FIsLoader, '0', md.FieldByName('Ord').AsString) + '\' + md.FieldByName('FileName').AsString)
        and CheckUpdateInFile(UpdateFilePath + IfThen(FIsLoader, '0', md.FieldByName('Ord').AsString) + '\' + md.FieldByName('FileName').AsString) then
      begin
        md.FieldByName('ReceivedBytes').AsInteger := md.FieldByName('FileSize').AsInteger;
        md.FieldByName('Status').AsInteger := psDownloaded;
        md.FieldByName('sStatus').AsString := 'Загружен';
      end
      else
      begin
        md.FieldByName('ReceivedBytes').AsInteger := md.FieldByName('FileSize').AsInteger;
        md.FieldByName('Status').AsInteger := psNone;
        md.FieldByName('sStatus').AsString := '';
      end;
      md.Post;
    end;

    md.SortByFields('Ord');
    md.First;

    if FIsLoader then
      while md.RecordCount>1 do
        md.Delete;

  finally
    md.EnableControls;
  end;
end;

function TfrmMain.OpenAppVer(var AAppInfo: TAppInfo): Boolean;
var
  AppInfoFileHeader: TAppInfoFileHeader;
  fs: TFileStream;
begin
  Result := False;
  fs := TFileStream.Create(GetAppPath + AppFileName, fmOpenRead);
  try
    if not CheckAppVerInStream(fs) then
      Exit;
    fs.Seek(0, soFromBeginning);
    fs.ReadBuffer(AppInfoFileHeader, SizeOf(TAppInfoFileHeader));
    fs.ReadBuffer(AAppInfo, SizeOf(TAppInfo));

    Result := True;
  finally
    FreeAndNil(fs);
  end;
end;

procedure TfrmMain.SetProxyParams(AclHTTP: TclHttp);
var
  ProxyHost: string;
  ProxyPort: Integer;
begin
  GetProxyServerParams('http', ProxyHost, ProxyPort);
  AclHTTP.ProxySettings.Server := ProxyHost;
  AclHTTP.ProxySettings.Port := ProxyPort;
end;

procedure TfrmMain.UpdateAppVersion(const AUpdateTo: Integer);
begin
  FAppInfo.AppVersion := AUpdateTo;
  CreateAppInfoFile(GetAppPath + AppFileName, FAppInfo);
end;

end.
