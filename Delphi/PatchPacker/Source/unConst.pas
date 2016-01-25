unit unConst;

interface

uses
  SysUtils, Classes, Windows, Forms;

const
  {$I ../../Common/PrivateKey.inc}

  UpdateFileDir = 'Updates';

  PatchFileSign = 'UPDATE';
  AppFileSign = 'APPINFO';
  AppFileName = 'App.ver';

  FileSignLength = 30;
  ProjectNameLength = 30;
  ExeNameLength = 30;

  PartFileNameLength = 50;
  PartFilePathLength = 255;

// Тип обновления
  updSQL = 1;
  updFile = 2;
  updExec = 3;

  HashSize = 16;
  SignSize = 128;

  ReceiverIDLength = 20;

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

  procedure Prepare;

  function GetAppPath: string;

  procedure StrToArray(const strValue: string; var CharArray: array of Char);

implementation

var
  FAppPath: string;

procedure Prepare;
begin
  FAppPath := ExtractFilePath(Application.ExeName);
end;

function GetAppPath: string;
begin
  Result := FAppPath;
end;

procedure StrToArray(const strValue: string; var CharArray: array of Char);
var
  Index, strLen: Integer;
begin
  strLen := Length(strValue);
  for Index:=1 to strLen do
    CharArray[Index-1] := strValue[Index];
  CharArray[strLen]:=#0;
end;

end.
