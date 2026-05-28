unit JsonSchema.Common.Utils;

interface

uses
  System.JSON,
  System.Classes,
  System.SysUtils;

type
  /// <summary>
  ///   Static helpers for JSON comparison, numeric value extraction,
  ///   URI generation, regular expression normalization, and generic array manipulation.
  /// </summary>
  /// <remarks>
  ///   All methods are static and thread-safe. The class has no state and does not need to be instantiated.
  ///
  ///   Architectural note: the generic helpers <c>AddArray</c> and <c>MergeArray</c> are here for historical reasons.
  ///   Collection operations with deduplication are found in <c>TCollectionUtils</c> (JsonSchema.CollectionUtils).
  /// </remarks>
  TUtils = class
  public
    /// <summary>
    ///   Performs a deep equality comparison between two JSON values.
    ///   Delegates to <c>JsonObjectEquals</c> or <c>JsonArrayEquals</c> depending on the specific type;
    ///   arrays are compared without considering the order of the elements.
    ///
    ///   The concrete type; arrays are compared without considering the order of the elements.
    /// </summary>
    class function JsonEquals(const pA: TJSONValue; const pB: TJSONValue): Boolean; static;

    /// <summary>
    ///   Compares two JSON arrays as sets, ignoring the order of the elements.
    ///   Uses a bitmask to track already paired elements in
    ///   <paramref name="pB"/>, ensuring O(n²) in the worst case without extra allocations.
    /// </summary>
    class function JsonArrayEquals(const pA: TJSONArray; const pB: TJSONArray): Boolean; static;

    /// <summary>
    ///   Compares two JSON objects, checking if they have exactly the same keys with the same values (deep comparison on each pair).
    /// </summary>
    class function JsonObjectEquals(const pA: TJSONObject; const pB: TJSONObject): Boolean; static;

    /// <summary>
    ///   Extracts an integer value from a <c>TJSONValue</c>.
    ///   If the value is a floating-point number without a fractional part
    ///   (e.g., <c>5.0</c>), returns the truncated value. Returns <c>0</c> for
    ///   non-numeric values ​​or values ​​with a non-zero fractional part.
    /// </summary>
    class function JsonGetInteger(const pValue: TJSONValue): Int64; static;

    /// <summary>
    ///   Extracts a floating-point value from a <c>TJSONValue</c>.
    ///   Uses English formatting settings so that the period is recognized as a decimal separator regardless of the system locale.
    ///   Returns <c>0</c> if the conversion fails.
    /// </summary>
    class function JsonGetFloat(const pValue: TJSONValue): Extended; static;

    /// <summary>
    ///   Determines the JSON Schema type of a JSON value as a string.
    ///   Possible values: <c>'null'</c>, <c>'boolean'</c>, <c>'integer'</c>,
    ///   <c>'number'</c>, <c>'string'</c>, <c>'array'</c>, <c>'object'</c>,
    ///   <c>'unknown'</c>.
    /// </summary>
    class function JsonGetType(const pValue: TJSONValue): string; static;

    /// <summary>
    ///   Encodes a Delphi string (UTF-16) as an array of UTF-32 code points.
    ///   Surrogate pairs are combined into a single Cardinal.
    /// </summary>
    class function Utf32Encode(const pValue: string): TArray<Cardinal>; static;

    /// <summary>
    ///   Normalizes a regular expression pattern for compatibility with the Delphi TRegEx engine,
    ///   mapping Unicode categories and the ECMAScript whitespace class to PCRE equivalents.
    /// </summary>
    class function RegexNormalizePattern(const pPattern: string): string; static;

    /// <summary>
    ///   Generates a random URI in the format <c>urn:uuid:<GUID></c>, typically used to create
    ///   unique base URIs for schema resources without an explicit identifier.
    /// </summary>
    class function UriGenerateRandom: string; static;

    /// <summary>
    ///   Analyzes an instance path in the style <c>#.foo.bar</c> or
    ///   <c>#/foo/bar</c> and returns its segments without separators.
    ///   Array indices (e.g., <c>[0]</c>) are removed from each segment.
    /// </summary>
    class function ParseInstancePath(const pPath: string): TArray<string>; static;

    /// <summary>
    ///   Decodes a segment of JSON Pointer (RFC 6901), replacing
    ///   <c>'~1'</c> with <c>'/'</c> and <c>'~0'</c> with <c>'~'</c>, in that order.
    /// </summary>
    /// <param name="pSegment">Encoded segment.</param>
    /// <param name="pDecodedSegment">Decoded segment (output parameter).</param>
    /// <returns>
    ///   <c>False</c> if the segment contains an escape character <c>'~'</c> followed by an
    ///   invalid character (other than <c>'0'</c> or <c>'1'</c>), or <c>'~'</c>
    ///   at the end of the string without a following character.
    /// </returns>
    class function DecodeJsonPointerSegment(const pSegment: string; out pDecodedSegment: string): Boolean; static;

    /// <summary>
    ///   Add <paramref name="pItem"/> to the end of <paramref name="pArray"/>,
    ///   relocating the array to accommodate the new element.
    /// </summary>
    class procedure AddArray<T>(var pArray: TArray<T>; const pItem: T); static;

    /// <summary>
    ///   Concatenates multiple arrays into a single flat array, preserving the order and all elements (including duplicates).
    ///   Pre-calculates the total size to perform a single allocation.
    /// </summary>
    class function MergeArray<T>(const pArrays: TArray<TArray<T>>): TArray<T>; static;
  end;

implementation

uses
  System.Character,
  System.RegularExpressions,
  System.Generics.Collections,
  JsonSchema.Registry.Uri;

{ TUtils }

class function TUtils.JsonEquals(const pA, pB: TJSONValue): Boolean;
begin
  // Custody clauses for void documents.
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
    lI := 0;
    Result := True;

    // It iterates through pA checking if each element has an unused pair in pB.
    // Uses a double while loop to avoid Break: the outer condition short-circuits
    // as soon as a mismatch is found.
    while Result and (lI < pA.Count) do
    begin
      lFound := False;
      lJ := 0;

      while not lFound and (lJ < pB.Count) do
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

class function TUtils.JsonObjectEquals(const pA, pB: TJSONObject): Boolean;
var
  lI: Integer;
  lPair: TJSONPair;
  lOtherValue: TJSONValue;
begin
  Result := False;

  if pA.Count <> pB.Count then
    Exit;

  lI := 0;
  Result := True;

  // A while loop with a double condition avoids a break when encountering the first divergence.
  while Result and (lI < pA.Count) do
  begin
    lPair := pA.Pairs[lI];
    lOtherValue := pB.GetValue(lPair.JsonString.Value);

    if (lOtherValue = nil) or not JsonEquals(lPair.JsonValue, lOtherValue) then
      Result := False;

    Inc(lI);
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
var
  lFloat: Extended;
begin
  // Quick path: the value is already representable as an integer in the string.
  if TryStrToInt64(pValue.Value, Result) then
    Exit;

  // The value can be a float without a fractional part (e.g., 5.0).
  // In this case, it is semantically complete and must be truncated correctly.
  // If there is a fraction, the value is not a valid integer → returns 0.
  lFloat := JsonGetFloat(pValue);

  if Frac(lFloat) = 0 then
    Result := Trunc(lFloat)
  else
    Result := 0;
end;

class function TUtils.JsonGetType(const pValue: TJSONValue): string;
begin
  if not Assigned(pValue) or (pValue is TJSONNull) then
    Result := 'null'
  else if (pValue is TJSONNumber) and (Frac(JsonGetFloat(pValue)) = 0) then
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
  lCodePoints: TList<Cardinal>;
  lIndex: Integer;
begin
  // TList avoids O(n²) reallocations that would occur with Result := Result + [x] in a loop.
  lCodePoints := TList<Cardinal>.Create;
  try
    lIndex := 1;

    while lIndex <= Length(pValue) do
    begin
      lCodePoints.Add(Char.ConvertToUtf32(pValue, lIndex - 1));

      // Substitute pairs occupy two UTF-16 positions; advance two indices.
      if pValue[lIndex].IsHighSurrogate then
        Inc(lIndex, 2)
      else
        Inc(lIndex);
    end;

    Result := lCodePoints.ToArray;
  finally
    lCodePoints.Free;
  end;
end;

class function TUtils.RegexNormalizePattern(const pPattern: string): string;
const
  // ECMAScript whitespace class (ECMA-262), required because
  // \s in PCRE/Delphi differs from the ECMAScript semantics used by JSON Schema.
  ECMA_WHITESPACE_CLASS =
    '[\x09\x0A\x0B\x0C\x0D\x20\xA0\x{1680}\x{2000}-\x{200A}' +
    '\x{2028}\x{2029}\x{202F}\x{205F}\x{3000}\x{FEFF}]';

  ECMA_NON_WHITESPACE_CLASS =
    '[^\x09\x0A\x0B\x0C\x0D\x20\xA0\x{1680}\x{2000}-\x{200A}' +
    '\x{2028}\x{2029}\x{202F}\x{205F}\x{3000}\x{FEFF}]';
begin
  Result := pPattern
    .Replace('\p{Letter}', '\p{L}', [rfReplaceAll])
    .Replace('\p{digit}', '\p{N}', [rfReplaceAll])
    .Replace('\s', ECMA_WHITESPACE_CLASS, [rfReplaceAll])
    .Replace('\S', ECMA_NON_WHITESPACE_CLASS, [rfReplaceAll]);
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
  lResult: TList<string>;
begin
  // Normalizes the prefixes '#.' and '#' before segmenting.
  if pPath.StartsWith('#.') then
    lPath := pPath.Substring(2)
  else if pPath.StartsWith('#') then
    lPath := pPath.Substring(1)
  else
    lPath := pPath;

  lSegments := lPath.Split(['.']);

  // TList avoids O(n²) reallocations that would occur with Result := Result + [x] in a loop.
  lResult := TList<string>.Create;
  try
    for lSegment in lSegments do
    begin
      lCleanSegment := TRegEx.Replace(lSegment, '\[\d+\]', '');

      if not lCleanSegment.IsEmpty then
        lResult.Add(lCleanSegment);
    end;

    Result := lResult.ToArray;
  finally
    lResult.Free;
  end;
end;

class function TUtils.DecodeJsonPointerSegment(
  const pSegment: string;
  out pDecodedSegment: string): Boolean;
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
      // '~' at the end of a string is always invalid (RFC 6901)
      if lIndex = Length(pSegment) then
      begin
        Result := False;
      end else
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
    end else
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
  lTotalCount: Integer;
  lSrc: TArray<T>;
  lItem: T;
  lDestIndex: Integer;
begin
  // Pre-calculates the total for a single allocation.
  lTotalCount := 0;

  for lSrc in pArrays do
    Inc(lTotalCount, Length(lSrc));

  SetLength(Result, lTotalCount);
  lDestIndex := 0;

  for lSrc in pArrays do
  begin
    for lItem in lSrc do
    begin
      Result[lDestIndex] := lItem;
      Inc(lDestIndex);
    end;
  end;
end;

end.
