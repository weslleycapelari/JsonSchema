unit JsonSchema.Common.Utils;

interface

uses
  System.JSON;

type
  /// <summary>
  ///   Stateless helpers for JSON comparison, numeric extraction, URI generation,
  ///   regex normalization, and JSON Pointer path utilities.
  /// </summary>
  TUtils = class
  public
    /// <summary>Performs a deep equality check between two JSON values.</summary>
    /// <param name="pA">First JSON value.</param>
    /// <param name="pB">Second JSON value.</param>
    /// <returns>True if the values are deeply equal, false otherwise.</returns>
    class function JsonEquals(const pA: TJSONValue; const pB: TJSONValue): Boolean; static;

    /// <summary>Performs a deep equality check between two JSON arrays, ignoring order.</summary>
    /// <param name="pA">First JSON array.</param>
    /// <param name="pB">Second JSON array.</param>
    /// <returns>True if the arrays contain the same elements (regardless of order), false otherwise.</returns>
    class function JsonArrayEquals(const pA: TJSONArray; const pB: TJSONArray): Boolean; static;

    /// <summary>Performs a deep equality check between two JSON objects.</summary>
    /// <param name="pA">First JSON object.</param>
    /// <param name="pB">Second JSON object.</param>
    /// <returns>True if the objects have the same properties with deeply equal values, false otherwise.</returns>
    class function JsonObjectEquals(const pA: TJSONObject; const pB: TJSONObject): Boolean; static;

    /// <summary>Extracts an integer value from a JSON value.</summary>
    /// <param name="pValue">The JSON value to extract from.</param>
    /// <returns>The integer value if extraction is successful, or 0 if not.</returns
    class function JsonGetInteger(const pValue: TJSONValue): Int64; static;

    /// <summary>Extracts a floating-point value from a JSON value.</summary>
    /// <param name="pValue">The JSON value to extract from.</param>
    /// <returns>The floating-point value if extraction is successful, or 0 if not.</returns>
    class function JsonGetFloat(const pValue: TJSONValue): Extended; static;

    /// <summary>Determines the JSON Schema type of a JSON value as a string.</summary>
    /// <param name="pValue">The JSON value to check.</param>
    /// <returns>A string representing the JSON Schema type ("null", "boolean", "object", "array", "number", "integer", or "string").</returns>
    class function JsonGetType(const pValue: TJSONValue): string; static;

    /// <summary>Encodes a string as an array of UTF-32 code points.</summary>
    /// <param name="pValue">The string to encode.</param>
    /// <returns>An array of UTF-32 code points representing the input string.</returns>
    class function Utf32Encode(const pValue: string): TArray<Cardinal>; static;

    /// <summary>Normalizes a regular expression pattern for compatibility with Delphi's TRegEx engine.</summary>
    /// <param name="pPattern">The original regex pattern from a JSON Schema.</param>
    /// <returns>A normalized regex pattern that can be used with TRegEx.</returns>
    class function RegexNormalizePattern(const pPattern: string): string; static;

    /// <summary>Generates a random URI string, typically used for creating unique base URIs for schema resources.</summary>
    /// <returns>A random URI string.</returns>
    class function UriGenerateRandom: string; static;

    /// <summary>Merges multiple arrays of the same type into a single array containing unique values.</summary>
    /// <param name="pArrays">An array of arrays to merge.</param>
    /// <returns>A single array containing all unique values from the input arrays.</returns>
    class function MergeArray<T>(const pArrays: array of TArray<T>): TArray<T>;

    /// <summary>Adds a value to an array, resizing it if necessary.</summary>
    /// <param name="pArray">The array to add to. This will be resized to accommodate the new value.</param>
    /// <param name="pValue">The value to add to the array.</param>
    class procedure AddArray<T>(var pArray: TArray<T>; const pValue: T);

    /// <summary>Parses a JSON Pointer-like instance path into its individual segments.</summary>
    /// <param name="pPath">The instance path string (e.g., "#/foo/bar").</param>
    /// <returns>An array of path segments (e.g., ["foo", "bar"]).</returns>
    class function ParseInstancePath(const pPath: string): TArray<string>; static;

    /// <summary>Decodes a JSON Pointer segment by unescaping '~1' to '/' and '~0' to '~'.</summary>
    /// <param name="pSegment">The JSON Pointer segment to decode.</param>
    /// <param name="pDecodedSegment">The output parameter that receives the decoded segment.</param>
    /// <returns>True if decoding is successful, false if the segment contains invalid escape sequences.</returns>
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
  pArray := pArray + [pValue];
end;

class function TUtils.DecodeJsonPointerSegment(const pSegment: string; out pDecodedSegment: string): Boolean;
var
  lCount: Integer;
begin
  pDecodedSegment := '';
  lCount := 1;
  Result := True;

  while (lCount <= Length(pSegment)) and Result do
  begin
    if pSegment[lCount] = '~' then
    begin
      if lCount = Length(pSegment) then
      begin
        Result := False;
      end else
      begin
        case pSegment[lCount + 1] of
          '0':
            pDecodedSegment := pDecodedSegment + '~';
          '1':
            pDecodedSegment := pDecodedSegment + '/';
        else
          Result := False;
        end;
        Inc(lCount, 2);
      end;
    end else
    begin
      pDecodedSegment := pDecodedSegment + pSegment[lCount];
      Inc(lCount);
    end;
  end;
end;

class function TUtils.JsonArrayEquals(const pA, pB: TJSONArray): Boolean;
var
  lUsed: TBits;
  lI, lJ: Integer;
  lFound: Boolean;
begin
  Result := False;

  if pA.Count <> pB.Count then
    Exit;

  lUsed := TBits.Create;
  try
    lUsed.Size := pB.Count;
    Result := True;
    lI := 0;

    while (lI < pA.Count) and Result do
    begin
      lFound := False;
      lJ := 0;

      while (lJ < pB.Count) and not lFound do
      begin
        if not lUsed[lJ] and JsonEquals(pA.Items[lI], pB.Items[lJ]) then
        begin
          lUsed[lJ] := True;
          lFound := True;
        end;
        Inc(lJ);
      end;

      if not lFound then
        Result := False;

      Inc(lI);
    end;
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

  if pA is TJSONObject then
  begin
    Result := JsonObjectEquals(TJSONObject(pA), TJSONObject(pB));
  end else if pA is TJSONArray then
  begin
    Result := JsonArrayEquals(TJSONArray(pA), TJSONArray(pB));
  end else if pA is TJSONNumber then
  begin
    Result := JsonGetFloat(pA) = JsonGetFloat(pB);
  end else if pA is TJSONString then
  begin
    Result := TJSONString(pA).Value = TJSONString(pB).Value;
  end else
  begin
    Result := pA.ToJSON = pB.ToJSON;
  end;
end;

class function TUtils.JsonGetFloat(const pValue: TJSONValue): Extended;
begin
  if not TryStrToFloat(pValue.Value, Result, TFormatSettings.Create('en')) then
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
  begin
    Result := 'null';
  end else if (pValue is TJSONNumber) and (Frac(TUtils.JsonGetFloat(pValue)) = 0) then
  begin
    Result := 'integer';
  end else if (pValue is TJSONNumber) then
  begin
    Result := 'number';
  end else if pValue is TJSONObject then
  begin
    Result := 'object';
  end else if pValue is TJSONArray then
  begin
    Result := 'array';
  end else if (pValue is TJSONTrue) or (pValue is TJSONFalse) then
  begin
    Result := 'boolean';
  end else if pValue is TJSONString then
  begin
    Result := 'string';
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
  lI := 0;
  while (lI < pA.Count) and Result do
  begin
    lPair := pA.Pairs[lI];
    lOtherValue := pB.GetValue(lPair.JsonString.Value);

    if (lOtherValue = nil) or not JsonEquals(lPair.JsonValue, lOtherValue) then
    begin
      Result := False;
    end;

    Inc(lI);
  end;
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
  lCleanSegment: string;
begin
  if pPath.StartsWith('#.') then
  begin
    lSegments := pPath.Substring(2).Split(['.']);
  end else if pPath.StartsWith('#') then
  begin
    lSegments := pPath.Substring(1).Split(['.']);
  end else
  begin
    lSegments := pPath.Split(['.']);
  end;

  for lSegment in lSegments do
  begin
    lCleanSegment := TRegEx.Replace(lSegment, '\[\d+\]', '');
    if not lCleanSegment.IsEmpty then
    begin
      Result := Result + [lCleanSegment];
    end;
  end;
end;

class function TUtils.RegexNormalizePattern(const pPattern: string): string;
const
  C_ECMA_WHITESPACE_CLASS = '[\x09\x0A\x0B\x0C\x0D\x20\xA0\x{1680}\x{2000}-\x{200A}\x{2028}\x{2029}\x{202F}\x{205F}\x{3000}\x{FEFF}]';
begin
  Result := pPattern
    .Replace('\p{Letter}', '\p{L}', [rfReplaceAll])
    .Replace('\p{digit}', '\p{N}', [rfReplaceAll])
    .Replace('\s', C_ECMA_WHITESPACE_CLASS, [rfReplaceAll])
    .Replace('\S', '[^' + C_ECMA_WHITESPACE_CLASS.Substring(1, C_ECMA_WHITESPACE_CLASS.Length - 2) + ']', [rfReplaceAll]);
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
    begin
      Inc(lCount, 2);
    end else
    begin
      Inc(lCount);
    end;
  end;
end;

end.
