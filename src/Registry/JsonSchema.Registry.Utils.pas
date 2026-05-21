unit JsonSchema.Registry.Utils;

interface

uses
  System.JSON;

type
  /// <summary>
  ///   Utility methods for URI normalization, validation, percent-encoding,
  ///   and JSON Pointer evaluation.
  ///   All methods are thread-safe and stateless.
  /// </summary>
  TURIUtils = class
  public
    /// <summary>Normalizes a URI string by parsing and reassembling its components.</summary>
    class function NormalizeURI(const pURIString: string): string; static;

    /// <summary>Returns True if pURIString is a syntactically valid absolute URI (scheme + authority/path).</summary>
    class function IsValidURI(const pURIString: string): Boolean; static;

    /// <summary>
    ///   Returns True if pURIString is a syntactically valid URI-reference
    ///   (absolute, relative, or fragment‑only).
    /// </summary>
    class function IsValidURIReference(const pURIString: string): Boolean; static;

    /// <summary>
    ///   Merges a base path with a relative path per RFC 3986, Section 5.2.3.
    ///   Example: MergePaths("/a/b/c", "d/e") -> "/a/b/d/e"
    /// </summary>
    class function MergePaths(const pBasePath, pRelativePath: string): string; static;

    /// <summary>
    ///   Splits an authority component into userInfo, host and port sub-components.
    ///   Example: "user:pass@example.com:8080" -> userInfo="user:pass", host="example.com", port="8080"
    /// </summary>
    class procedure ParseAuthority(const pAuthority: string; out pUserInfo, pHost, pPort: string); static;

    /// <summary>
    ///   Splits a userInfo string into username and password.
    ///   Example: "user:pass" -> username="user", password="pass"
    /// </summary>
    class procedure ParseUserInfo(const pUserInfo: string; out pUsername, pPassword: string); static;

    /// <summary>
    ///   Removes '.' and '..' segments from a path per RFC 3986, Section 5.2.4.
    /// </summary>
    class function RemoveDotSegments(const pPath: string): string; static;

    /// <summary>
    ///   Normalizes percent-encoding sequences to uppercase (e.g., "%2F" → "%2f").
    ///   Also decodes unreserved characters (RFC 3986, Section 6.2.2.2).
    /// </summary>
    class function NormalizePercentEncoding(const pValue: string): string; static;

    /// <summary>Normalizes the scheme to lowercase per RFC 3986, Section 6.2.2.1.</summary>
    class function NormalizeScheme(const pScheme: string): string; static;

    /// <summary>
    ///   Encodes a string applying percent-encoding rules for the given set of
    ///   unreserved characters. Reserved characters are percent-encoded.
    /// </summary>
    class function Encoding(const pValue, pCustomUnreserved: string): string; static;

    /// <summary>
    ///   Encodes a string for use in the userinfo sub-component (RFC 3986, Section 3.2.1).
    ///   Preserves unreserved characters, sub-delims, and ':'.
    /// </summary>
    class function EncodingUserInfo(const pValue: string): string; static;

    /// <summary>
    ///   Navigates a JSON document using an RFC 6901 JSON Pointer and returns the referenced node.
    ///   Returns nil if the pointer is invalid or the node does not exist.
    /// </summary>
    class function EvaluateJsonPointer(const pRootNode: TJSONValue; const pPointer: string): TJSONValue; static;

    /// <summary>Returns True if the supplied string is a syntactically valid RFC 6901 JSON Pointer.</summary>
    class function IsValidJsonPointer(const pPointer: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  System.Character,
  System.Generics.Collections,
  JsonSchema.Common.Utils,
  JsonSchema.Registry.Types,
  JsonSchema.Registry.Uri;

{ TURIUtils }

class function TURIUtils.NormalizeURI(const pURIString: string): string;
var
  lURI: TURIReference;
begin
  lURI := TURIReference.From(pURIString);
  Result := lURI.Normalize.Unsplit;
end;

class function TURIUtils.IsValidURI(const pURIString: string): Boolean;
var
  lURI: TURIReference;
begin
  if not IsValidURIReference(pURIString) then
    Exit(False);

  try
    lURI := TURIReference.From(pURIString);
    Result := lURI.Scheme <> '';
  except
    Result := False;
  end;
end;

class function TURIUtils.IsValidURIReference(const pURIString: string): Boolean;
var
  lChar: Char;
  lURI: TURIReference;
begin
  // Spaces and control characters are not allowed in a URI without percent-encoding
  for lChar in pURIString do
    if (Ord(lChar) <= 32) or (Ord(lChar) = 127) then
      Exit(False);

  try
    lURI := TURIReference.From(pURIString);
    lURI.Normalize;
    Result := True;
  except
    Result := False;
  end;
end;

class function TURIUtils.MergePaths(const pBasePath, pRelativePath: string): string;
var
  lPos: Integer;
begin
  if pBasePath.IsEmpty then
    Exit(pRelativePath);

  lPos := pBasePath.LastIndexOf('/');
  if lPos < 0 then
    Result := pRelativePath
  else
    Result := pBasePath.Substring(0, lPos + 1) + pRelativePath;
end;

class procedure TURIUtils.ParseAuthority(const pAuthority: string; out pUserInfo, pHost, pPort: string);
var
  lRest: string;
  lAtPos: Integer;
  lColonPos: Integer;
  lBracketPos: Integer;
begin
  pUserInfo := '';
  pHost := '';
  pPort := '';

  if pAuthority.IsEmpty then
    Exit;

  lRest := pAuthority;

  // Extract userinfo (everything before the last '@')
  lAtPos := lRest.LastIndexOf('@');
  if lAtPos > -1 then
  begin
    pUserInfo := lRest.Substring(0, lAtPos);
    lRest := lRest.Substring(lAtPos + 1);
  end;

  // Check for IPv6 literal (enclosed in brackets)
  if lRest.StartsWith('[') then
  begin
    lBracketPos := lRest.IndexOf(']');
    if lBracketPos > 0 then
    begin
      pHost := lRest.Substring(0, lBracketPos + 1);
      lRest := lRest.Substring(lBracketPos + 1);
      if lRest.StartsWith(':') then
        pPort := lRest.Substring(1);
      Exit;
    end;
  end;

  // Regular host:port
  lColonPos := lRest.LastIndexOf(':');
  if (lColonPos > -1) and (lRest.IndexOf(']') < lColonPos) then
  begin
    pHost := lRest.Substring(0, lColonPos);
    pPort := lRest.Substring(lColonPos + 1);
  end
  else
  begin
    pHost := lRest;
    pPort := '';
  end;
end;

class procedure TURIUtils.ParseUserInfo(const pUserInfo: string; out pUsername, pPassword: string);
var
  lColonPos: Integer;
begin
  pUsername := '';
  pPassword := '';

  if pUserInfo.IsEmpty then
    Exit;

  lColonPos := pUserInfo.IndexOf(':');
  if lColonPos > -1 then
  begin
    pUsername := pUserInfo.Substring(0, lColonPos);
    pPassword := pUserInfo.Substring(lColonPos + 1);
  end
  else
    pUsername := pUserInfo;
end;

class function TURIUtils.RemoveDotSegments(const pPath: string): string;
var
  lInput: TStringList;
  lOutput: TStringList;
  lSegment: string;
  lIsAbsolute: Boolean;
  lEndsWithSlash: Boolean;
begin
  Result := '';

  if pPath.IsEmpty then
    Exit;

  lIsAbsolute := pPath.StartsWith('/');
  lEndsWithSlash := pPath.EndsWith('/');

  lInput := TStringList.Create;
  lOutput := TStringList.Create;
  try
    lInput.Delimiter := '/';
    lInput.StrictDelimiter := True;
    lInput.DelimitedText := pPath;

    for lSegment in lInput do
    begin
      if lSegment = '..' then
      begin
        if lOutput.Count > 0 then
          lOutput.Delete(lOutput.Count - 1);
      end
      else if (lSegment <> '.') and (lSegment <> '') then
        lOutput.Add(lSegment);
    end;

    Result := lOutput.DelimitedText;
    if lIsAbsolute and not Result.IsEmpty then
      Result := '/' + Result;
    if lEndsWithSlash and not Result.IsEmpty and not Result.EndsWith('/') then
      Result := Result + '/';
  finally
    lInput.Free;
    lOutput.Free;
  end;
end;

class function TURIUtils.NormalizePercentEncoding(const pValue: string): string;
const
  UNRESERVED_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
var
  lIndex: Integer;
  lBuilder: TStringBuilder;
  lHex: string;
  lByte: Integer;
begin
  if pValue.IsEmpty then
    Exit('');

  lBuilder := TStringBuilder.Create;
  try
    lIndex := 1;
    while lIndex <= Length(pValue) do
    begin
      if (pValue[lIndex] = '%') and (lIndex + 2 <= Length(pValue)) then
      begin
        lHex := pValue.Substring(lIndex, 2);
        if TryStrToInt('$' + lHex, lByte) then
        begin
          // Unreserved characters are decoded to their literal representation
          if Pos(Char(lByte), UNRESERVED_CHARS) > 0 then
            lBuilder.Append(Char(lByte))
          else
            lBuilder.Append('%' + lHex.ToUpper);
          Inc(lIndex, 3);
        end
        else
        begin
          lBuilder.Append(pValue[lIndex]);
          Inc(lIndex);
        end;
      end
      else
      begin
        lBuilder.Append(pValue[lIndex]);
        Inc(lIndex);
      end;
    end;
    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

class function TURIUtils.NormalizeScheme(const pScheme: string): string;
begin
  Result := pScheme.ToLower;
end;

class function TURIUtils.Encoding(const pValue, pCustomUnreserved: string): string;
const
  UNRESERVED_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
var
  lIndex: Integer;
  lBuilder: TStringBuilder;

  function IsReserved(const pChar: Char): Boolean;
  begin
    Result := not ((Pos(pChar, UNRESERVED_CHARS) > 0) or (Pos(pChar, pCustomUnreserved) > 0));
  end;
begin
  if pValue.IsEmpty then
    Exit('');

  lBuilder := TStringBuilder.Create;
  try
    lIndex := 1;
    while lIndex <= Length(pValue) do
    begin
      if IsReserved(pValue[lIndex]) then
      begin
        lBuilder.Append('%' + IntToHex(Ord(pValue[lIndex]), 2));
        Inc(lIndex);
      end
      else
      begin
        lBuilder.Append(pValue[lIndex]);
        Inc(lIndex);
      end;
    end;
    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

class function TURIUtils.EncodingUserInfo(const pValue: string): string;
begin
  // userinfo preserves sub-delims and ':'
  Result := Encoding(pValue, '!$&''()*+,;=:');
end;

class function TURIUtils.EvaluateJsonPointer(const pRootNode: TJSONValue;
  const pPointer: string): TJSONValue;
var
  lSegments: TArray<string>;
  lSegment: string;
  lDecoded: string;
  lCurrent: TJSONValue;
  lIndex: Integer;
begin
  if not Assigned(pRootNode) then
    Exit(nil);

  if pPointer.IsEmpty then
    Exit(pRootNode);

  if not IsValidJsonPointer(pPointer) then
    Exit(nil);

  lCurrent := pRootNode;
  // Remove leading '/'
  lSegments := pPointer.Substring(1).Split(['/']);

  for lSegment in lSegments do
  begin
    if not Assigned(lCurrent) then
      Exit(nil);

    if not TUtils.DecodeJsonPointerSegment(lSegment, lDecoded) then
      Exit(nil);

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

class function TURIUtils.IsValidJsonPointer(const pPointer: string): Boolean;
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

end.
