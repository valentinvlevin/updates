unit undmUpd;

interface

uses
  Windows, Messages, SysUtils, Variants,
  Classes, Graphics, ShellApi,
  Controls, Forms, Dialogs, TPLB3.Codec, TPLB3.Signatory,
  TPLB3.Hash, TPLB3.BaseNonVisualComponent, TPLB3.CryptographicLibrary;

const
  AppFileSign = 'APPINFO';
  PatchFileSign = 'UPDATE';

  AppFileName = 'App.ver';

  UpdateFileDir = 'Updates';

  FileSignLength = 30;
  ProjectNameLength = 30;
  ExeNameLength = 30;

// Тип обновления
  updSQL = 1;
  updFile = 2;
  updExec = 3;

  HashSize = 16;
  SignSize = 128;

  ReceiverIDLength = 20;

  PartFileNameLength = 50;
  PartFilePathLength = 255;

  PublicKey =
    'TgpMb2NrQm94MwEAAAADgAAAABcnRXytobCMrrSqfFFKcIn3Det/XbQKIYRFyC7z5b5CeK+yO'+
    'u8tzGX5IxX3Bxec61BvLLLthUyj1EwU1RG4f2hzt4XwsdaCB9Rjpl0T3j6p0VIaKyNLweDT4H'+
    'AWwQ+WIT0gNwv8m6acf/JUcT6OVVLIVebiwC8Wu5Q5xZ2sE1J+AwAAAAEAAU4KTG9ja0JveDM'+
    'BAAAAA4AAAABfBgenQw/6KqP6MXig8ZHO6vCG+HEWwf5nz7qe5vo/FphByk/RNfPwCo0LWcFS'+
    'ulWPxyGtSY7Jvg9UuWiyWlUXPBhr26ONijhG3R6WiMRUN8mfOo/X4tQlecEcNIixVxv1H1i/w'+
    'rk/gFgexk21UFQCVI06RPrjPpCjdEGrG4TwcwMAAAABAAE=';

type
  TAppInfoFileHeader = packed record
    FileSign: string[FileSignLength];
    FileHash: array[0..HashSize-1] of Byte;
    CreateDateTime: TDateTime;
  end;

  TAppInfo = packed record
    ProjectName: string[ProjectNameLength];
    AppVersion: Integer;
    ExeName: string[ExeNameLength];
    ReceiverId: string[ReceiverIDLength];
  end;

  TPatchFileHeader = packed record
    FileSign: string[FileSignLength];
    ProjectName: string[ProjectNameLength];
    Ord: Word;
    UpdateDBVersionTo: Byte;
    UpdateAppVersionTo: Byte;
    PartCount: Word;
    CreateDateTime: TDateTime;
    FileHash: array[0..HashSize-1] of Byte;{MD5 HashSize(=16)}
    Signature: array[0..SignSize-1] of Byte;{Signarure(=128)}
  end;

  TPatchPartInfo = packed record
    PartType: Byte;
    PartSize: Integer;
    NextPartPos: Integer;
  end;

  TPatchFilePart = packed record
    FileName: array[0..PartFileNameLength-1] of Char;
    ToFilePath: array[0..PartFilePathLength-1] of Char;
    IsDoExec: Byte;
  end;

type
  TdmUpd = class(TDataModule)
    lbCryptographicLibrary: TCryptographicLibrary;
    lbHash: THash;
    lbSignatory: TSignatory;
    lbCodec: TCodec;
  private

  public
    { Public declarations }
  end;

  function CheckUpdateInFile(const AFilePath: string): Boolean;
  function CheckUpdateInStream(const AStream: TStream): Boolean;

  function CheckAppVerInFile(const AFilePath: string): Boolean;
  function CheckAppVerInStream(const AStream: TStream): Boolean;

  procedure CreateAppInfoFile(const AFilePath: string;
    const AAppInfo: TAppInfo);

  function UpdateLoader(const ALoaderVersion: Integer): Boolean;

  function RunProcess(FileName: string; ShowCmd: DWORD; wait: Boolean;
    ProcID: PDWORD): Longword;

  function JavaTimeToDateTime(javatime:Int64):TDateTime;

implementation

{$R *.dfm}

uses
  TPLB3.StreamUtils, TPLB3.Asymetric, zLibEx;

function CheckUpdateInStream(const AStream: TStream): Boolean;
var
  PatchFileHeader: TPatchFileHeader;
  FileHash: array [0..HashSize-1] of Byte;
  KeyStore, SignData, UpdData: TMemoryStream;

  f: TdmUpd;
begin
  Result := False;
  if AStream.Position>0 then
    AStream.Seek(0, soFromBeginning);

  if AStream.Size<=SizeOf(TPatchFileHeader) then
    Exit;

  AStream.ReadBuffer(PatchFileHeader, SizeOf(PatchFileHeader));
  if PatchFileHeader.FileSign <> PatchFileSign then
    Exit;

  UpdData := TMemoryStream.Create;

  Application.CreateForm(TdmUpd, f);

  try
    UpdData.CopyFrom(AStream, AStream.Size - AStream.Position);
    UpdData.Seek(0, soFromBeginning);

    f.lbHash.HashStream(UpdData);
    f.lbHash.HashOutputValue.Seek(0, soFromBeginning);
    f.lbHash.HashOutputValue.ReadBuffer(FileHash[0], HashSize);
    f.lbHash.Burn;

    if not CompareMem(@FileHash[0], @PatchFileHeader.FileHash[0], HashSize) then
      Exit;

    UpdData.Seek(0, soFromBeginning);
    KeyStore := TMemoryStream.Create;
    SignData := TMemoryStream.Create;
    try
      Base64_to_stream(PublicKey, KeyStore);
      KeyStore.Seek(0, soFromBeginning);
      f.lbSignatory.LoadKeysFromStream(KeyStore, [partPublic]);

      SignData.WriteBuffer(PatchFileHeader.Signature[0], SignSize);
      SignData.Seek(0, soFromBeginning);

      if f.lbSignatory.Verify(UpdData, SignData) <> vPass then
        Exit;
    finally
      FreeAndNil(KeyStore);
    end;
  finally
    FreeAndNil(UpdData);
    FreeAndNil(f);
  end;

  Result := True;
end;

function CheckUpdateInFile(const AFilePath: string): Boolean;
var
  fs: TFileStream;
begin
  Result := False;

  if FileExists(AFilePath) then
  begin
    fs := nil;
    try
      fs := TFileStream.Create(AFilePath, fmOpenRead);
      try
        Result := CheckUpdateInStream(fs);
      finally
        FreeAndNil(fs)
      end;
    except
      Result := False;
    end;
  end;
end;

function CheckAppVerInFile(const AFilePath: string): Boolean;
var
  fs: TFileStream;
begin
  Result := False;
  if FileExists(AFilePath) then
  begin
    fs := nil;
    try
      fs := TFileStream.Create(AFilePath, fmOpenRead);
      try
        Result := CheckUpdateInStream(fs);
      finally
        FreeAndNil(fs)
      end;
    except
      Result := False;
    end;
  end;
end;

function CheckAppVerInStream(const AStream: TStream): Boolean;
var
  AppInfoFileHeader: TAppInfoFileHeader;
  AppInfoHash: array[0..HashSize] of Byte;
  AppInfo: TAppInfo;
  f: TdmUpd;
begin
  Result := False;
  Application.CreateForm(TdmUpd, f);
  try
    if AStream.Size <> SizeOf(TAppInfoFileHeader) + SizeOf(TAppInfo) then
      Exit;

    AStream.Seek(0, soFromBeginning);

    AStream.ReadBuffer(AppInfoFileHeader, SizeOf(TAppInfoFileHeader));
    if AppInfoFileHeader.FileSign<>AppFileSign then
      Exit;

    AStream.ReadBuffer(AppInfo, SizeOf(TAppInfo));
    f.lbHash.HashBytes(BytesOf(@AppInfo, SizeOf(TAppInfo)));
    f.lbHash.HashOutputValue.Seek(0, soFromBeginning);
    f.lbHash.HashOutputValue.ReadBuffer(AppInfoHash[0], HashSize);

    if not CompareMem(@AppInfoHash[0], @AppInfoFileHeader.FileHash[0], HashSize) then
      Exit;

    Result := True;
  finally
    FreeAndNil(f);
  end;
end;

procedure CreateAppInfoFile(const AFilePath: string; const AAppInfo: TAppInfo);
var
  fs: TFileStream;
  AppInfoFileHeader: TAppInfoFileHeader;
  f: TdmUpd;
begin
  fs := TFileStream.Create(AFilePath, fmCreate);
  Application.CreateForm(TdmUpd, f);
  try
    AppInfoFileHeader.FileSign := AppFileSign;
    AppInfoFileHeader.CreateDateTime := Now;

    f.lbHash.HashBytes(BytesOf(@AAppInfo, SizeOf(AAppInfo)));

    f.lbHash.HashOutputValue.Seek(0, soFromBeginning);
    f.lbHash.HashOutputValue.ReadBuffer(AppInfoFileHeader.FileHash[0], HashSize);

    f.lbHash.Burn;

    fs.WriteBuffer(AppInfoFileHeader, SizeOf(AppInfoFileHeader));
    fs.WriteBuffer(AAppInfo, SizeOf(AAppInfo));
  finally
    FreeAndNil(fs);
    FreeAndNil(f);
  end;
end;

function UpdateLoader(const ALoaderVersion: Integer): Boolean;
var
  UpdateFilesPath: string;
  UpdateFile: string;
  LastFileOrd: Integer;
  sr: TSearchRec;
  fs: TFileStream;
  CompressedData, RawData: TMemoryStream;
  PatchFileHeader: TPatchFileHeader;
  PatchPartInfo: TPatchPartInfo;
  PatchFilePartInfo: TPatchFilePart;
begin
  Result := False;

  UpdateFilesPath := ExtractFilePath(Application.ExeName) + UpdateFileDir + '\0\';

  if FindFirst(UpdateFilesPath+'*', faAnyFile, sr)=0 then
  begin
    LastFileOrd := 0;
    repeat
      if CheckUpdateInFile(UpdateFilesPath + '\' + sr.Name) then
      begin
        fs := TFileStream.Create(UpdateFilesPath + '\' + sr.Name, fmOpenRead);
        try
          fs.ReadBuffer(PatchFileHeader, SizeOf(TPatchFileHeader));
          if (PatchFileHeader.UpdateAppVersionTo>ALoaderVersion)
            and (LastFileOrd<PatchFileHeader.Ord) then
          begin
            LastFileOrd := PatchFileHeader.Ord;
            UpdateFile := UpdateFilesPath + '\' + sr.Name;
          end;
        finally
          FreeAndNil(fs);
        end;
      end;
    until FindNext(sr)<>0;

    FindClose(sr);

    if LastFileOrd>0 then
    begin
      try
        CompressedData := TMemoryStream.Create;
        RawData := TMemoryStream.Create;
        try
          fs := TFileStream.Create(UpdateFile, fmOpenRead);
          try
            fs.ReadBuffer(PatchFileHeader, SizeOf(TPatchFileHeader));
            CompressedData.CopyFrom(fs, fs.Size - fs.Position);
          finally
            FreeAndNil(fs);
          end;

          CompressedData.Seek(0, soFromBeginning);
          ZDecompressStream(CompressedData, RawData);
          CompressedData.Clear;
          RawData.Seek(0, soFromBeginning);
          RawData.ReadBuffer(PatchPartInfo, SizeOf(TPatchPartInfo));
          RawData.ReadBuffer(PatchFilePartInfo, SizeOf(TPatchFilePart));
          CompressedData.CopyFrom(RawData, PatchPartInfo.PartSize);
          CompressedData.Seek(0, soFromBeginning);

          while not DeleteFile(ExtractFilePath(Application.ExeName) + 'Loader.exe') do
            Sleep(1000);

          fs := TFileStream.Create(ExtractFilePath(Application.ExeName) + 'Loader.exe', fmCreate);
          try
            ZDecompressStream(CompressedData, fs);
          finally
            FreeAndNil(fs);
          end;
        finally
          FreeAndNil(CompressedData);
          FreeAndNil(RawData);
        end;

        Result := True;
      except

      end;
    end;
  end;

end;

function RunProcess(FileName: string; ShowCmd: DWORD; wait: Boolean;
  ProcID: PDWORD): Longword;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  FillChar(StartupInfo, SizeOf(StartupInfo), #0);
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK;
  StartupInfo.wShowWindow := ShowCmd;
  if not CreateProcess(nil,
    @Filename[1],
    nil,
    nil,
    False,
    CREATE_NEW_CONSOLE or
    NORMAL_PRIORITY_CLASS,
    nil,
    nil,
    StartupInfo,
    ProcessInfo)
    then
    Result := WAIT_FAILED
  else
  begin
    if wait = FALSE then
    begin
      if ProcID <> nil then
        ProcID^ := ProcessInfo.dwProcessId;
      result := WAIT_FAILED;
      exit;
    end;
    WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
    GetExitCodeProcess(ProcessInfo.hProcess, Result);
  end;
  if ProcessInfo.hProcess <> 0 then
    CloseHandle(ProcessInfo.hProcess);
  if ProcessInfo.hThread <> 0 then
    CloseHandle(ProcessInfo.hThread);
end;

function JavaTimeToDateTime(javatime:Int64):TDateTime;
// java time -> Win32 file time -> UTC time
// adjust to active time zone -> TDateTime
var
  UTCTime, LocalTime: TSystemTime;
begin
  FileTimeToSystemTime(TFileTime(Int64(javatime + 11644473600000) * 10000), UTCTime);
  SystemTimeToTzSpecificLocalTime(nil, UTCTime, LocalTime);
  Result := SystemTimeToDateTime(LocalTime);
end;

end.
