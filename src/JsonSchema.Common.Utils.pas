unit JsonSchema.Common.Utils;

interface

uses
  System.JSON;

type
  TUtils = class
    class function JsonEquals(pA, B: TJSONValue): Boolean; static;
    class function JsonArrayEquals(pA, pB: TJSONArray): Boolean; static;
    class function JsonObjectEquals(pA, pB: TJSONObject): Boolean; static;
    class function JsonGetInteger(pValue: TJSONValue): Int64; static;
    class function JsonGetFloat(pValue: TJSONValue): Extended; static;
    class function JsonGetType(pValue: TJSONValue): string; static;
    class function Utf32Encode(const pValue: string): TArray<Cardinal>; static;
    class function RegexNormalizePattern(const pPattern: string): string; static;
    class function UriGenerateRandom: string; static;
    class function MergeArray<T>(const pArrays: array of TArray<T>): TArray<T>;
    class procedure AddArray<T>(var pArray: TArray<T>; const pValue: T);
    class function ParseInstancePath(const pPath: string): TArray<string>; static;
    class function DecodeJsonPointerSegment(const pSegment: string; out pDecodedSegment: string): Boolean; static;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  System.Character,
  System.RegularExpressions,
  System.Generics.Collections,
  JsonSchema.Registry.Uri;

{ TUtils }

class procedure TUtils.AddArray<T>(var pArray: TArray<T>; const pValue: T);
begin
  SetLength(pArray, Length(pArray) + 1);
  pArray[Length(pArray) - 1] := pValue;
end;

class function TUtils.DecodeJsonPointerSegment(const pSegment: string; out pDecodedSegment: string): Boolean;
var
  lCount: Integer;
begin
  pDecodedSegment := '';
  lCount := 1;
  while lCount <= Length(pSegment) do
  begin
    if pSegment[lCount] = '~' then
    begin
      if lCount = Length(pSegment) then
        Exit(False);

      case pSegment[lCount + 1] of
        '0': pDecodedSegment := pDecodedSegment + '~';
        '1': pDecodedSegment := pDecodedSegment + '/';
      else
        Exit(False);
      end;
      Inc(lCount, 2);
    end
    else
    begin
      pDecodedSegment := pDecodedSegment + pSegment[lCount];
      Inc(lCount);
    end;
  end;

  Result := True;
end;

class function TUtils.JsonArrayEquals(pA, pB: TJSONArray): Boolean;
var
  lUsed: TBits;
  I, J: Integer;
  lFound: Boolean;
begin
  if pA.Count <> pB.Count then
    Exit(False);

  lUsed := TBits.Create;
  try
    lUsed.Size := pB.Count;

    for I := 0 to pA.Count - 1 do
    begin
      lFound := False;

      for J := 0 to pB.Count - 1 do
      begin
        if not lUsed[J] and JSONEquals(pA.Items[I], pB.Items[J]) then
        begin
          lUsed[J] := True; // marca como usado
          lFound := True;
          Break;
        end;
      end;

      if not lFound then
        Exit(False);
    end;

    Result := True;
  finally
    lUsed.Free;
  end;
end;

class function TUtils.JsonEquals(pA, B: TJSONValue): Boolean;
begin
  if not Assigned(pA) and not Assigned(B) then
    Exit(True);

  if not Assigned(pA) or not Assigned(B) then
    Exit(False);

  if pA.ClassType <> B.ClassType then
    Exit(False);

       if pA is TJSONObject then Exit(JsonObjectEquals(TJSONObject(pA), TJSONObject(B)))
  else if pA is TJSONArray then  Exit(JsonArrayEquals(TJSONArray(pA), TJSONArray(B)))
  else if pA is TJSONNumber then Exit(JsonGetFloat(pA) = JsonGetFloat(B))
  else if pA is TJSONString then Exit(TJSONString(pA).Value = TJSONString(B).Value)
  else                           Exit(pA.ToJSON = B.ToJSON);
end;

class function TUtils.JsonGetFloat(pValue: TJSONValue): Extended;
begin
  if not TryStrToFloat(pValue.Value, Result, TFormatSettings.Create('en')) then
    Result := 0;
end;

class function TUtils.JsonGetInteger(pValue: TJSONValue): Int64;
begin
  if not TryStrToInt64(pValue.Value, Result) then
    if Frac(JsonGetFloat(pValue)) <> 0 then
      Result := 0;
end;

class function TUtils.JsonGetType(pValue: TJSONValue): string;
begin
       if not Assigned(pValue) or (pValue is TJSONNull) then                       Result := 'null'
  else if (pValue is TJSONNumber) and (Frac(TUtils.JsonGetFloat(pValue)) = 0) then Result := 'integer'
  else if (pValue is TJSONNumber) then                                             Result := 'number'
  else if pValue is TJSONObject then                                               Result := 'object'
  else if pValue is TJSONArray then                                                Result := 'array'
  else if (pValue is TJSONTrue) or (pValue is TJSONFalse) then                     Result := 'boolean'
  else if pValue is TJSONString then                                               Result := 'string';
end;

class function TUtils.JsonObjectEquals(pA, pB: TJSONObject): Boolean;
var
  lPair: TJSONPair;
  lOtherValue: TJSONValue;
begin
  Result := False;

  if pA.Count <> pB.Count then
    Exit;

  for lPair in pA do
  begin
    lOtherValue := pB.GetValue(lPair.JsonString.Value);
    if lOtherValue = nil then
      Exit;

    if not JSONEquals(lPair.JsonValue, lOtherValue) then
      Exit;
  end;

  Result := True;
end;

class function TUtils.MergeArray<T>(const pArrays: array of TArray<T>): TArray<T>;
var
  lDict: TDictionary<T, Boolean>;
  lArray: TArray<T>;
  lValue: T;
begin
  lDict := TDictionary<T, Boolean>.Create;
  try
    for lArray in pArrays do
    begin
      for lValue in lArray do
      begin
        lDict.AddOrSetValue(lValue, True);
      end;
    end;
    Result := lDict.Keys.ToArray;
  finally
    lDict.Free;
  end;
end;

class function TUtils.ParseInstancePath(const pPath: string): TArray<string>;
var
  lSegments: TArray<string>;
  lSegment: string;
begin
  // Remove o in�cio '#.' ou '#'
  if pPath.StartsWith('#.') then
    lSegments := pPath.Substring(2).Split(['.'])
  else if pPath.StartsWith('#') then
    lSegments := pPath.Substring(1).Split(['.'])
  else
    lSegments := pPath.Split(['.']);

  // Remove os �ndices de array, pois nosso JSON de dicas n�o os ter�
  for lSegment in lSegments do
  begin
    var lCleanSegment := TRegEx.Replace(lSegment, '\[\d+\]', '');
    if not lCleanSegment.IsEmpty then
      Result := Result + [lCleanSegment];
  end;
end;

class function TUtils.RegexNormalizePattern(const pPattern: string): string;
const
  // ECMA-262 whitespace set used by JSON Schema test suite for \s / \S.
  CECMAWhitespaceClass = '[\x09\x0A\x0B\x0C\x0D\x20\xA0\x{1680}\x{2000}-\x{200A}\x{2028}\x{2029}\x{202F}\x{205F}\x{3000}\x{FEFF}]';
begin
  Result := pPattern
    .Replace('\p{Letter}', '\p{L}', [rfReplaceAll])
    .Replace('\p{digit}', '\p{N}', [rfReplaceAll])
    .Replace('\s', CECMAWhitespaceClass, [rfReplaceAll])
    .Replace('\S', '[^' + CECMAWhitespaceClass.Substring(1, CECMAWhitespaceClass.Length - 2) + ']', [rfReplaceAll]);
end;

class function TUtils.UriGenerateRandom: string;
begin
  Result := TURIReference.From('urn:uuid:' + TGUID.NewGuid.ToString.Substring(1, 36)).Unsplit;
end;

class function TUtils.Utf32Encode(const pValue: string): TArray<Cardinal>;
var
  lCount: Integer;
  lCodePoint: Cardinal;
begin
  lCount := 1;
  while lCount <= Length(pValue) do
  begin
    lCodePoint := Char.ConvertToUtf32(pValue, lCount - 1);
    Result := Result + [lCodePoint];

    if pValue[lCount].IsHighSurrogate then
      Inc(lCount, 2)
    else
      Inc(lCount);
  end;
end;

end.
