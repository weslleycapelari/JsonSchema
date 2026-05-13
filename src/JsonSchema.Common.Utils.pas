unit JsonSchema.Common.Utils;

interface

uses
  System.JSON;

type
  TUtils = class
    class function JsonEquals(A, B: TJSONValue): Boolean; static;
    class function JsonArrayEquals(A, B: TJSONArray): Boolean; static;
    class function JsonObjectEquals(A, B: TJSONObject): Boolean; static;
    class function JsonGetInteger(AValue: TJSONValue): Int64; static;
    class function JsonGetFloat(AValue: TJSONValue): Extended; static;
    class function JsonGetType(AValue: TJSONValue): string; static;
    class function Utf32Encode(const AValue: string): TArray<Cardinal>; static;
    class function RegexNormalizePattern(const APattern: string): string; static;
    class function UriGenerateRandom: string; static;
    class function MergeArray<T>(const AArrays: array of TArray<T>): TArray<T>;
    class procedure AddArray<T>(var AArray: TArray<T>; const AValue: T);
    class function ParseInstancePath(const APath: string): TArray<string>; static;
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

class procedure TUtils.AddArray<T>(var AArray: TArray<T>; const AValue: T);
begin
  SetLength(AArray, Length(AArray) + 1);
  AArray[Length(AArray) - 1] := AValue;
end;

class function TUtils.JsonArrayEquals(A, B: TJSONArray): Boolean;
var
  LUsed: TBits;
  I, J: Integer;
  LFound: Boolean;
begin
  if A.Count <> B.Count then
    Exit(False);

  LUsed := TBits.Create;
  try
    LUsed.Size := B.Count;

    for I := 0 to A.Count - 1 do
    begin
      LFound := False;

      for J := 0 to B.Count - 1 do
      begin
        if not LUsed[J] and JSONEquals(A.Items[I], B.Items[J]) then
        begin
          LUsed[J] := True; // marca como usado
          LFound := True;
          Break;
        end;
      end;

      if not LFound then
        Exit(False);
    end;

    Result := True;
  finally
    LUsed.Free;
  end;
end;

class function TUtils.JsonEquals(A, B: TJSONValue): Boolean;
begin
  if not Assigned(A) and not Assigned(B) then
    Exit(True);

  if not Assigned(A) or not Assigned(B) then
    Exit(False);

  if A.ClassType <> B.ClassType then
    Exit(False);

       if A is TJSONObject then Exit(JsonObjectEquals(TJSONObject(A), TJSONObject(B)))
  else if A is TJSONArray then  Exit(JsonArrayEquals(TJSONArray(A), TJSONArray(B)))
  else if A is TJSONNumber then Exit(JsonGetFloat(A) = JsonGetFloat(B))
  else if A is TJSONString then Exit(TJSONString(A).Value = TJSONString(B).Value)
  else                          Exit(A.ToJSON = B.ToJSON);
end;

class function TUtils.JsonGetFloat(AValue: TJSONValue): Extended;
begin
  if not TryStrToFloat(AValue.Value, Result, TFormatSettings.Create('en')) then
    Result := 0;
end;

class function TUtils.JsonGetInteger(AValue: TJSONValue): Int64;
begin
  if not TryStrToInt64(AValue.Value, Result) then
    if Frac(JsonGetFloat(AValue)) <> 0 then
      Result := 0;
end;

class function TUtils.JsonGetType(AValue: TJSONValue): string;
begin
       if not Assigned(AValue) or (AValue is TJSONNull) then                       Result := 'null'
  else if (AValue is TJSONNumber) and (Frac(TUtils.JsonGetFloat(AValue)) = 0) then Result := 'integer'
  else if (AValue is TJSONNumber) then                                             Result := 'number'
  else if AValue is TJSONObject then                                               Result := 'object'
  else if AValue is TJSONArray then                                                Result := 'array'
  else if (AValue is TJSONTrue) or (AValue is TJSONFalse) then                     Result := 'boolean'
  else if AValue is TJSONString then                                               Result := 'string';
end;

class function TUtils.JsonObjectEquals(A, B: TJSONObject): Boolean;
var
  LPair: TJSONPair;
  LOtherValue: TJSONValue;
begin
  Result := False;

  if A.Count <> B.Count then
    Exit;

  for LPair in A do
  begin
    LOtherValue := B.GetValue(LPair.JsonString.Value);
    if LOtherValue = nil then
      Exit;

    if not JSONEquals(LPair.JsonValue, LOtherValue) then
      Exit;
  end;

  Result := True;
end;

class function TUtils.MergeArray<T>(const AArrays: array of TArray<T>): TArray<T>;
var
  LDict: TDictionary<T, Boolean>;
  LArray: TArray<T>;
  LValue: T;
begin
  LDict := TDictionary<T, Boolean>.Create;
  try
    for LArray in AArrays do
    begin
      for LValue in LArray do
      begin
        LDict.AddOrSetValue(LValue, True);
      end;
    end;
    Result := LDict.Keys.ToArray;
  finally
    LDict.Free;
  end;
end;

class function TUtils.ParseInstancePath(const APath: string): TArray<string>;
var
  LSegments: TArray<string>;
  LSegment: string;
begin
  // Remove o início '#.' ou '#'
  if APath.StartsWith('#.') then
    LSegments := APath.Substring(2).Split(['.'])
  else if APath.StartsWith('#') then
    LSegments := APath.Substring(1).Split(['.'])
  else
    LSegments := APath.Split(['.']);

  // Remove os índices de array, pois nosso JSON de dicas não os terá
  for LSegment in LSegments do
  begin
    var LCleanSegment := TRegEx.Replace(LSegment, '\[\d+\]', '');
    if not LCleanSegment.IsEmpty then
      Result := Result + [LCleanSegment];
  end;
end;

class function TUtils.RegexNormalizePattern(const APattern: string): string;
begin
  Result := APattern.Replace('\p{Letter}', '\p{L}', [rfReplaceAll]).Replace('\p{digit}', '\p{N}', [rfReplaceAll]);
end;

class function TUtils.UriGenerateRandom: string;
begin
  Result := TURIReference.From('urn:uuid:' + TGUID.NewGuid.ToString.Substring(1, 36)).Unsplit;
end;

class function TUtils.Utf32Encode(const AValue: string): TArray<Cardinal>;
var
  LCount: Integer;
  LCodePoint: Cardinal;
begin
  LCount := 1;
  while LCount <= Length(AValue) do
  begin
    LCodePoint := Char.ConvertToUtf32(AValue, LCount - 1);
    Result := Result + [LCodePoint];

    if AValue[LCount].IsHighSurrogate then
      Inc(LCount, 2)
    else
      Inc(LCount);
  end;
end;

end.
