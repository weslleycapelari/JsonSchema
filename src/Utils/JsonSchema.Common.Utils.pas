unit JsonSchema.Common.Utils;

interface

uses
  System.JSON,
  System.Classes,
  System.SysUtils;

type
  /// <summary>
  ///   Stateless helpers for JSON comparison, numeric extraction, URI generation,
  ///   regex normalization, and JSON Pointer path utilities.
  /// </summary>
  TUtils = class
  public
    /// <summary>Performs a deep equality check between two JSON values.</summary>
    class function JsonEquals(const pA: TJSONValue; const pB: TJSONValue): Boolean; static;

    /// <summary>Performs a deep equality check between two JSON arrays, ignoring order.</summary>
    class function JsonArrayEquals(const pA: TJSONArray; const pB: TJSONArray): Boolean; static;

    /// <summary>Performs a deep equality check between two JSON objects.</summary>
    class function JsonObjectEquals(const pA: TJSONObject; const pB: TJSONObject): Boolean; static;

    /// <summary>Extracts an integer value from a JSON value.</summary>
    class function JsonGetInteger(const pValue: TJSONValue): Int64; static;

    /// <summary>Extracts a floating-point value from a JSON value.</summary>
    class function JsonGetFloat(const pValue: TJSONValue): Extended; static;

    /// <summary>Determines the JSON Schema type of a JSON value as a string.</summary>
    class function JsonGetType(const pValue: TJSONValue): string; static;

    /// <summary>Encodes a string as an array of UTF-32 code points.</summary>
    class function Utf32Encode(const pValue: string): TArray<Cardinal>; static;

    /// <summary>Normalizes a regular expression pattern for compatibility with Delphi's TRegEx engine.</summary>
    class function RegexNormalizePattern(const pPattern: string): string; static;

    /// <summary>Generates a random URI string, typically used for creating unique base URIs for schema resources.</summary>
    class function UriGenerateRandom: string; static;

    /// <summary>Parses a JSON Pointer-like instance path into its individual segments.</summary>
    class function ParseInstancePath(const pPath: string): TArray<string>; static;

    /// <summary>Decodes a JSON Pointer segment by unescaping '~1' to '/' and '~0' to '~'.</summary>
    class function DecodeJsonPointerSegment(const pSegment: string; out pDecodedSegment: string): Boolean; static;

    /// <summary>Appends pItem to pArray in place.</summary>
    class procedure AddArray<T>(var pArray: TArray<T>; const pItem: T); static;

    /// <summary>Concatenates multiple arrays into a single flat array.</summary>
    class function MergeArray<T>(const pArrays: TArray<TArray<T>>): TArray<T>; static;
  end;

implementation

uses
  System.Character,
  System.RegularExpressions,
  System.TypInfo,
  System.Generics.Collections,
  JsonSchema.Registry.Uri;

{ TUtils }

class function TUtils.JsonEquals(const pA, pB: TJSONValue): Boolean;
begin
  if not Assigned(pA) and not Assigned(pB) then
    Exit(True);

  if not Assigned(pA) or not Assigned(pB) then
    Exit(False);

  if pA.ClassType <> pB.ClassType then
    Exit(False);

  if pA is TJSONObject then
    Result := JsonObjectEquals(TJSONObject(pA), TJSONObject(pB))
  else if pA is TJSONArray then
    Result := JsonArrayEquals(TJSONArray(pA), TJSONArray(pB))
  else if pA is TJSONNumber then
    Result := JsonGetFloat(pA) = JsonGetFloat(pB)
  else if pA is TJSONString then
    Result := TJSONString(pA).Value = TJSONString(pB).Value
  else
    Result := pA.ToJSON = pB.ToJSON;
end;

class function TUtils.JsonArrayEquals(const pA, pB: TJSONArray): Boolean;
var
  lUsed: TBits;
  lI: Integer;
  lJ: Integer;
  lFound: Boolean;
begin
  Result := False;

  if pA.Count <> pB.Count then
    Exit;

  lUsed := TBits.Create;
  try
    lUsed.Size := pB.Count;
    Result := True;

    for lI := 0 to pA.Count - 1 do
    begin
      lFound := False;

      for lJ := 0 to pB.Count - 1 do
      begin
        if not lUsed[lJ] and JsonEquals(pA.Items[lI], pB.Items[lJ]) then
        begin
          lUsed[lJ] := True;
          lFound := True;
          Break;
        end;
      end;

      if not lFound then
      begin
        Result := False;
        Break;
      end;
    end;
  finally
    lUsed.Free;
  end;
end;

class function TUtils.JsonObjectEquals(const pA, pB: TJSONObject): Boolean;
var
  lI: Integer;
  lPair: TJSONPair;
  lOtherValue: TJSONValue;
begin
  Result := False;

  if pA.Count <> pB.Count then
    Exit;

  Result := True;

  for lI := 0 to pA.Count - 1 do
  begin
    lPair := pA.Pairs[lI];
    lOtherValue := pB.GetValue(lPair.JsonString.Value);

    if (lOtherValue = nil) or not JsonEquals(lPair.JsonValue, lOtherValue) then
    begin
      Result := False;
      Break;
    end;
  end;
end;

class function TUtils.JsonGetFloat(const pValue: TJSONValue): Extended;
var
  lFormat: TFormatSettings;
begin
  lFormat := TFormatSettings.Create('en');
  if not TryStrToFloat(pValue.Value, Result, lFormat) then
    Result := 0;
end;

class function TUtils.JsonGetInteger(const pValue: TJSONValue): Int64;
begin
  if not TryStrToInt64(pValue.Value, Result) then
  begin
    if Frac(JsonGetFloat(pValue)) <> 0 then
      Result := 0;
  end;
end;

class function TUtils.JsonGetType(const pValue: TJSONValue): string;
begin
  if not Assigned(pValue) or (pValue is TJSONNull) then
    Result := 'null'
  else if (pValue is TJSONNumber) and (Frac(TUtils.JsonGetFloat(pValue)) = 0) then
    Result := 'integer'
  else if pValue is TJSONNumber then
    Result := 'number'
  else if pValue is TJSONObject then
    Result := 'object'
  else if pValue is TJSONArray then
    Result := 'array'
  else if (pValue is TJSONTrue) or (pValue is TJSONFalse) then
    Result := 'boolean'
  else if pValue is TJSONString then
    Result := 'string'
  else
    Result := 'unknown';
end;

class function TUtils.Utf32Encode(const pValue: string): TArray<Cardinal>;
var
  lIndex: Integer;
  lCodePoint: Cardinal;
begin
  Result := [];
  lIndex := 1;

  while lIndex <= Length(pValue) do
  begin
    lCodePoint := Char.ConvertToUtf32(pValue, lIndex - 1);
    Result := Result + [lCodePoint];

    if pValue[lIndex].IsHighSurrogate then
      Inc(lIndex, 2)
    else
      Inc(lIndex);
  end;
end;

class function TUtils.RegexNormalizePattern(const pPattern: string): string;
const
  ECMA_WHITESPACE_CLASS = '[\x09\x0A\x0B\x0C\x0D\x20\xA0\x{1680}\x{2000}-\x{200A}\x{2028}\x{2029}\x{202F}\x{205F}\x{3000}\x{FEFF}]';
begin
  Result := pPattern
    .Replace('\p{Letter}', '\p{L}', [rfReplaceAll])
    .Replace('\p{digit}', '\p{N}', [rfReplaceAll])
    .Replace('\s', ECMA_WHITESPACE_CLASS, [rfReplaceAll])
    .Replace('\S', '[^' + ECMA_WHITESPACE_CLASS.Substring(1, ECMA_WHITESPACE_CLASS.Length - 2) + ']', [rfReplaceAll]);
end;

class function TUtils.UriGenerateRandom: string;
var
  lGuid: TGUID;
begin
  lGuid := TGUID.NewGuid;
  Result := TURIReference.From('urn:uuid:' + lGuid.ToString.Substring(1, 36)).Unsplit;
end;

class function TUtils.ParseInstancePath(const pPath: string): TArray<string>;
var
  lPath: string;
  lSegments: TArray<string>;
  lSegment: string;
  lCleanSegment: string;
begin
  Result := [];

  if pPath.StartsWith('#.') then
    lPath := pPath.Substring(2)
  else if pPath.StartsWith('#') then
    lPath := pPath.Substring(1)
  else
    lPath := pPath;

  lSegments := lPath.Split(['.']);

  for lSegment in lSegments do
  begin
    lCleanSegment := TRegEx.Replace(lSegment, '\[\d+\]', '');
    if not lCleanSegment.IsEmpty then
      Result := Result + [lCleanSegment];
  end;
end;

class function TUtils.DecodeJsonPointerSegment(const pSegment: string; out pDecodedSegment: string): Boolean;
var
  lIndex: Integer;
begin
  pDecodedSegment := '';
  lIndex := 1;
  Result := True;

  while (lIndex <= Length(pSegment)) and Result do
  begin
    if pSegment[lIndex] = '~' then
    begin
      if lIndex = Length(pSegment) then
        Result := False
      else
      begin
        case pSegment[lIndex + 1] of
          '0':
            pDecodedSegment := pDecodedSegment + '~';
          '1':
            pDecodedSegment := pDecodedSegment + '/';
        else
          Result := False;
        end;
        Inc(lIndex, 2);
      end;
    end
    else
    begin
      pDecodedSegment := pDecodedSegment + pSegment[lIndex];
      Inc(lIndex);
    end;
  end;
end;

class procedure TUtils.AddArray<T>(var pArray: TArray<T>; const pItem: T);
begin
  SetLength(pArray, Length(pArray) + 1);
  pArray[High(pArray)] := pItem;
end;

class function TUtils.MergeArray<T>(const pArrays: TArray<TArray<T>>): TArray<T>;
var
  lTotal: Integer;
  lSrc: TArray<T>;
  lItem: T;
begin
  lTotal := 0;
  for lSrc in pArrays do
    Inc(lTotal, Length(lSrc));
  SetLength(Result, lTotal);
  lTotal := 0;
  for lSrc in pArrays do
    for lItem in lSrc do
    begin
      Result[lTotal] := lItem;
      Inc(lTotal);
    end;
end;

end.
