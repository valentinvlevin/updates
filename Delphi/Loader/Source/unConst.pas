unit unConst;

interface

uses
  Windows, SysUtils, Forms;

const
  {$I ../../Common/PublicKey.inc}

  LoaderVersion = 3;
  LoaderProjectName = 'LOADER';

  HostCount = 1;

  HostNames: array[0..HostCount-1] of string =
    (
      'http://eduserver.dyndns.info:28080/Updates/rest/'
    );

  // Этап обработки обновления
  psNone = 0;
  psDownloading = 1;
  psDownloaded = 2;
  psProcessing = 3;
  psProcessed = 4;
  psError = 5;

  ReceiverIDLength = 20;

procedure Prepare;

function GetAppPath: string;

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

end.
