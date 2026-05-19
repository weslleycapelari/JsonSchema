unit JsonSchema.Common.Utils;

interface

uses
  System.JSON;

type
  /// <summary>
  /// Stateless helpers for JSON comparison, numeric extraction, URI generation,
  /// regex normalization, and JSON Pointer path utilities.
  /// </summary>
  TUtils = class
    /// <summary>Deep structural equality comparison between two JSON values.</summary>
    class function JsonEquals(const pA, pB: TJSONValue): Boolean; static;
    /// <summary>Deep structural equality for JSON arrays, order-independent.</summary>
    class function JsonArrayEquals(const pA, pB: TJSONArray): Boolean; static;
    /// <summary>Deep structural equality for JSON objects.</summary>
    class function JsonObjectEquals(const pA, pB: TJSONObject): Boolean; static;
    /// <summary>Extracts an Int64 from a JSON number value.</summary>
    class function JsonGetInteger(const pValue: TJSONValue): Int64; static;
    /// <summary>Extracts an Extended from a JSON number value using the English locale.</summary>
    class function JsonGetFloat(const pValue: TJSONValue): Extended; static;
    /// <summary>Returns the JSON Schema type name string for a given JSON value.</summary>
    class function JsonGetType(const pValue: TJSONValue): string; static;
    /// <summary>Encodes a UTF-16 string to a sequence of UTF-32 code points.</summary>
    class function Utf32Encode(const pValue: string): TArray<Cardinal>; static;
    /// <summary>
    /// Normalizes an ECMA-262 regex pattern for use with Delphi's TRegEx,
    /// mapping \s/\S to the ECMA-262 whitespace character class.
    /// </summary>
    class function RegexNormalizePattern(const pPattern: string): string; static;
    /// <summary>Generates a random URN UUID suitable for use as a schema base URI.</summary>
    class function UriGenerateRandom: string; static;
    /// <summary>Merges multiple arrays into one retaining only unique values.</summary>
    class function MergeArray<T>(const pArrays: array of TArray<T>): TArray<T>;
    /// <summary>Appends a value to a dynamic array in place.</summary>
    class procedure AddArray<T>(var pArray: TArray<T>; const pValue: T);
    /// <summary>
    /// Parses an instance path string into path segments, stripping array indices.
    /// Accepts paths in the form '#.field[0].sub' or 'field.sub'.
    /// </summary>
    class function ParseInstancePath(const pPath: string): TArray<string>; static;
    /// <summary>
    /// Decodes a JSON Pointer segment, converting ~0 to ~ and ~1 to /.
    /// Returns False if the segment contains an invalid escape sequence.
    /// </summary>
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

class function TUtils.JsonArrayEquals(const pA, pB: TJSONArray): Boolean;
var
  lUsed: TBits;
  lI, lJ: Integer;
  lFound: Boolean;
begin
  if pA.Count <> pB.Count then
    Exit(False);

  lUsed := TBits.Create;
  try
    lUsed.Size := pB.Count;

    for lI := 0 to pA.Count - 1 do
    begin
      lFound := False;
      lJ := 0;
      while (lJ < pB.Count) and not lFound do
      begin
        if not lUsed[lJ] and JsonEquals(pA.Items[lI], pB.Items[lJ]) then
        begin
          lUsed[lJ] := True;
          lFound := True;
        end
        else
          Inc(lJ);
      end;

      if not lFound then
        Exit(False);
    end;

    Result := True;
  finally
    lUsed.Free;
  end;
end;

class function TUtils.JsonEquals(const pA, pB: TJSONValue): Boolean;
begin
  if not Assigned(pA) and not Assigned(pB) then
    Exit(True);

  if not Assigned(pA) or not Assigned(pB) then
    Exit(False);

  if pA.ClassType <> pB.ClassType then
    Exit(False);

       if pA is TJSONObject then Exit(JsonObjectEquals(TJSONObject(pA), TJSONObject(pB)))
  else if pA is TJSONArray  then Exit(JsonArrayEquals(TJSONArray(pA), TJSONArray(pB)))
  else if pA is TJSONNumber then Exit(JsonGetFloat(pA) = JsonGetFloat(pB))
  else if pA is TJSONString then Exit(TJSONString(pA).Value = TJSONString(pB).Value)
  else                           Exit(pA.ToJSON = pB.ToJSON);
end;

class function TUtils.JsonGetFloat(const pValue: TJSONValue): Extended;
begin
  if not TryStrToFloat(pValue.Value, Result, TFormatSettings.Create('en')) then
    Result := 0;
end;

class function TUtils.JsonGetInteger(const pValue: TJSONValue): Int64;
begin
  if not TryStrToInt64(pValue.Value, Result) then
    if Frac(JsonGetFloat(pValue)) <> 0 then
      Result := 0;
end;

class function TUtils.JsonGetType(const pValue: TJSONValue): string;
begin
       if not Assigned(pValue) or (pValue is TJSONNull) then                       Result := 'null'
  else if (pValue is TJSONNumber) and (Frac(TUtils.JsonGetFloat(pValue)) = 0) then Result := 'integer'
  else if (pValue is TJSONNumber) then                                             Result := 'number'
  else if pValue is TJSONObject then                                               Result := 'object'
  else if pValue is TJSONArray then                                                Result := 'array'
  else if (pValue is TJSONTrue) or (pValue is TJSONFalse) then                     Result := 'boolean'
  else if pValue is TJSONString then                                               Result := 'string';
end;

class function TUtils.JsonObjectEquals(const pA, pB: TJSONObject): Boolean;
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

    if not JsonEquals(lPair.JsonValue, lOtherValue) then
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
      for lValue in lArray do
        lDict.AddOrSetValue(lValue, True);
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
  if pPath.StartsWith('#.') then
    lSegments := pPath.Substring(2).Split(['.'])
  else if pPath.StartsWith('#') then
    lSegments := pPath.Substring(1).Split(['.'])
  else
    lSegments := pPath.Split(['.']);

  for lSegment in lSegments do
  begin
    var lCleanSegment := TRegEx.Replace(lSegment, '\[\d+\]', '');
    if not lCleanSegment.IsEmpty then
      Result := Result + [lCleanSegment];
  end;
end;

class function TUtils.RegexNormalizePattern(const pPattern: string): string;
const
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
