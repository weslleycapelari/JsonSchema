unit JsonSchema.JsonPathUtils;

interface

uses
  System.JSON,
  System.Generics.Collections;

type
  /// <summary>
  ///   Utility class for JSON Pointer operations, path normalization,
  ///   and segment encoding/decoding as per RFC 6901.
  ///   All methods are thread-safe and stateless.
  /// </summary>
  TJsonPathUtils = class
  public
    /// <summary>Normalizes a property path to a canonical slash‑delimited form.</summary>
    /// <param name="pPath">The path string (e.g. "#/foo/bar" or "#.foo.bar").</param>
    /// <returns>Canonical path starting with '/' (e.g. "/foo/bar").</returns>
    class function NormalizeToCanonical(const pPath: string): string; static;

    /// <summary>
    ///   Splits a canonical path into its decoded segments.
    ///   Example: "/foo/bar~1baz" -> ["foo", "bar/baz"]
    /// </summary>
    class function SplitPathIntoSegments(const pPath: string): TArray<string>; static;

    /// <summary>
    ///   Encodes a segment for use in a JSON Pointer.
    ///   Replaces '~' with '~0' and '/' with '~1'.
    /// </summary>
    class function EncodeSegment(const pSegment: string): string; static;

    /// <summary>
    ///   Decodes a JSON Pointer segment.
    ///   Replaces '~1' with '/' and '~0' with '~'.
    /// </summary>
    class function DecodeSegment(const pSegment: string): string; static;

    /// <summary>
    ///   Validates that a string is a syntactically correct JSON Pointer (RFC 6901).
    /// </summary>
    class function IsValidPointer(const pPointer: string): Boolean; static;

    /// <summary>
    ///   Navigates a JSON document using a JSON Pointer and returns the referenced node.
    ///   Returns nil if the pointer does not resolve to an existing node.
    /// </summary>
    class function EvaluatePointer(const pRoot: TJSONValue; const pPointer: string): TJSONValue; static;

    /// <summary>
    ///   Builds a set of evaluated property paths from a validation result
    ///   for use in unevaluatedProperties/unevaluatedItems.
    /// </summary>
    class function BuildEvaluatedSet(const pBasePath: string;
      const pEvaluatedProperties: TEnumerable<string>;
      const pCoveredProperties: TArray<string>;
      const pCoveredItems: TArray<Integer>): THashSet<string>; static;

    /// <summary>
    ///   Joins a base path with a suffix, ensuring exactly one '/' separator.
    /// </summary>
    class function JoinPath(const pBasePath, pSuffix: string): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.RegularExpressions,
  JsonSchema.Common.Utils;

{ TJsonPathUtils }

class function TJsonPathUtils.NormalizeToCanonical(const pPath: string): string;
begin
  Result := Trim(pPath);

  if Result.IsEmpty or (Result = '#') then
    Exit('/');

  if Result.StartsWith('#/') then
    Result := Result.Substring(1)
  else if Result.StartsWith('#.') then
    Result := '/' + StringReplace(Result.Substring(2), '.', '/', [rfReplaceAll])
  else if Result.StartsWith('.') then
    Result := '/' + StringReplace(Result.Substring(1), '.', '/', [rfReplaceAll])
  else if Result.StartsWith('#') then
    Result := '/' + Result.Substring(1)
  else if not Result.StartsWith('/') then
    Result := '/' + Result;

  // Remove multiple consecutive slashes
  while Pos('//', Result) > 0 do
    Result := StringReplace(Result, '//', '/', [rfReplaceAll]);

  // Remove trailing slash except when path is exactly "/"
  if Result.EndsWith('/') and (Result <> '/') then
    Delete(Result, Length(Result), 1);
end;

class function TJsonPathUtils.SplitPathIntoSegments(const pPath: string): TArray<string>;
var
  lCanonical: string;
  lSegments: TArray<string>;
  lSegment: string;
begin
  Result := [];
  lCanonical := NormalizeToCanonical(pPath);

  if (lCanonical = '/') or lCanonical.IsEmpty then
    Exit;

  // Remove leading '/'
  lCanonical := lCanonical.Substring(1);
  lSegments := lCanonical.Split(['/']);

  for lSegment in lSegments do
    Result := Result + [DecodeSegment(lSegment)];
end;

class function TJsonPathUtils.EncodeSegment(const pSegment: string): string;
begin
  Result := pSegment.Replace('~', '~0', [rfReplaceAll]);
  Result := Result.Replace('/', '~1', [rfReplaceAll]);
end;

class function TJsonPathUtils.DecodeSegment(const pSegment: string): string;
begin
  Result := pSegment.Replace('~1', '/', [rfReplaceAll]);
  Result := Result.Replace('~0', '~', [rfReplaceAll]);
end;

class function TJsonPathUtils.IsValidPointer(const pPointer: string): Boolean;
var
  lSegments: TArray<string>;
  lSegment: string;
  lIndex: Integer;
begin
  if pPointer.IsEmpty then
    Exit(True);

  if not pPointer.StartsWith('/') then
    Exit(False);

  lSegments := pPointer.Substring(1).Split(['/']);
  for lSegment in lSegments do
  begin
    lIndex := 1;
    while lIndex <= lSegment.Length do
    begin
      if lSegment[lIndex] = '~' then
      begin
        if (lIndex = lSegment.Length) or
           ((lSegment[lIndex + 1] <> '0') and (lSegment[lIndex + 1] <> '1')) then
          Exit(False);
        Inc(lIndex, 2);
      end
      else
        Inc(lIndex);
    end;
  end;

  Result := True;
end;

class function TJsonPathUtils.EvaluatePointer(const pRoot: TJSONValue; const pPointer: string): TJSONValue;
var
  lSegments: TArray<string>;
  lSegment: string;
  lDecoded: string;
  lCurrent: TJSONValue;
  lIndex: Integer;
begin
  if not Assigned(pRoot) then
    Exit(nil);

  if pPointer.IsEmpty or (pPointer = '#') then
    Exit(pRoot);

  if not IsValidPointer(pPointer) then
    Exit(nil);

  lCurrent := pRoot;
  lSegments := SplitPathIntoSegments(pPointer);

  for lSegment in lSegments do
  begin
    if not Assigned(lCurrent) then
      Exit(nil);

    lDecoded := DecodeSegment(lSegment);

    if lCurrent is TJSONObject then
      lCurrent := TJSONObject(lCurrent).GetValue(lDecoded)
    else if lCurrent is TJSONArray then
    begin
      if TryStrToInt(lDecoded, lIndex) and
         (lIndex >= 0) and
         (lIndex < TJSONArray(lCurrent).Count) then
        lCurrent := TJSONArray(lCurrent).Items[lIndex]
      else
        Exit(nil);
    end
    else
      Exit(nil);
  end;

  Result := lCurrent;
end;

class function TJsonPathUtils.BuildEvaluatedSet(const pBasePath: string;
  const pEvaluatedProperties: TEnumerable<string>;
  const pCoveredProperties: TArray<string>;
  const pCoveredItems: TArray<Integer>): THashSet<string>;
var
  lCanonicalBase: string;
  lItem: string;
  lIndex: Integer;
begin
  Result := THashSet<string>.Create;
  lCanonicalBase := NormalizeToCanonical(pBasePath);

  if not lCanonicalBase.EndsWith('/') and (lCanonicalBase <> '/') then
    lCanonicalBase := lCanonicalBase + '/';

  if Assigned(pEvaluatedProperties) then
    for lItem in pEvaluatedProperties do
      Result.Add(NormalizeToCanonical(lItem));

  for lItem in pCoveredProperties do
    Result.Add(lCanonicalBase + lItem);

  for lIndex in pCoveredItems do
    Result.Add(lCanonicalBase + lIndex.ToString);
end;

class function TJsonPathUtils.JoinPath(const pBasePath, pSuffix: string): string;
var
  lBase: string;
begin
  lBase := NormalizeToCanonical(pBasePath);

  if lBase = '/' then
    Result := '/' + pSuffix
  else if lBase.EndsWith('/') then
    Result := lBase + pSuffix
  else
    Result := lBase + '/' + pSuffix;
end;

end.
