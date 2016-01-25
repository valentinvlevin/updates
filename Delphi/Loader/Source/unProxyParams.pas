unit unProxyParams;

interface

uses
  SysUtils, Classes, Windows;

  procedure GetProxyServerParams(const Protocol: string; var ProxyServer: string;
    var ProxyPort: Integer);

implementation

uses
  WinInet, StrUtils;

function GetProxyInformation: string;
var
  ProxyInfo: PInternetProxyInfo;
  Len: LongWord;
begin
  Result := '';
  Len := 4096;
  GetMem(ProxyInfo, Len);
  try
    if InternetQueryOption(nil, INTERNET_OPTION_PROXY, ProxyInfo, Len)
      and (ProxyInfo^.dwAccessType = INTERNET_OPEN_TYPE_PROXY) then
      Result := string(ProxyInfo^.lpszProxy)
  finally
    FreeMem(ProxyInfo);
  end;
end;
{**************************************************************************
* NAME:    GetProxyServer
* DESC:    Proxy-Server Einstellungen abfragen
* PARAMS:  protocol => z.B. 'http' oder 'ftp'
* RESULT:  [-]
* CREATED: 08-04-2004/shmia
*************************************************************************}
procedure GetProxyServerParams(const Protocol: string; var ProxyServer: string;
  var ProxyPort: Integer);
var
  StartIndex, EndIndex: Integer;
  proxyinfo: string;
begin
  ProxyServer := '';
  ProxyPort := 0;
  proxyinfo := GetProxyInformation;
  if proxyinfo = '' then
    Exit;
  StartIndex := Pos(protocol+'=', proxyinfo);
  if StartIndex > 0 then
  begin
    Delete(proxyinfo, 1, StartIndex + Length(protocol));
    StartIndex := Pos(';', ProxyServer);
    if StartIndex > 0 then
      proxyinfo := Copy(proxyinfo, 1, StartIndex - 1);
  end;
  StartIndex := Pos(':', proxyinfo);
  if StartIndex > 0 then
  begin
    EndIndex := Pos(' ', proxyInfo)-1;
    if EndIndex<0 then
      EndIndex := Length(proxyInfo);
    ProxyPort := StrToIntDef(Copy(proxyinfo, StartIndex + 1, EndIndex - StartIndex), 0);
    ProxyServer := Copy(proxyinfo, 1, StartIndex - 1)
  end
end;

end.
