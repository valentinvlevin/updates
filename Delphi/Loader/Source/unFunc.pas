unit unFunc;

interface

uses
  Windows, SysUtils;

procedure StrToArray(const strValue: string; var CharArray: array of Char);
function ArrayToStr(CharArray: array of Char): string;

implementation

procedure StrToArray(const strValue: string; var CharArray: array of Char);
var
  Index, strLen: Integer;
begin
  strLen := Length(strValue);
  for Index:=1 to strLen do
    CharArray[Index-1] := strValue[Index];
  CharArray[strLen]:=#0;
end;

function ArrayToStr(CharArray: array of Char): string;
var
  Index, ArrayLen: Integer;
begin
  Result := '';
  ArrayLen := Length(CharArray);
  Index := 0;
  while (Index<ArrayLen) and (CharArray[Index]<>#0) do
  begin
    Result := Result + CharArray[Index];
    inc(Index);
  end;
end;

end.
