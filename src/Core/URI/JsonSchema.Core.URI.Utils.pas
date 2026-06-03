unit JsonSchema.Core.URI.Utils;

(*
--------------------------------------------------------------------------------
Provides helper methods for URI parsing, normalization, validation, and JSON Pointer evaluation.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.URI.Types,
  JsonSchema.Core.URI.Reference;

type
  /// <summary>Utility methods for URI normalization, validation, percent-encoding, and JSON Pointer evaluation.</summary>
  TURIUtils = class
  public
    /// <summary>Normalizes a URI string by parsing and reassembling its components.</summary>
    class function NormalizeURI(const pURIString: string): string; static;

    /// <summary>Returns True if pURIString is a syntactically valid absolute URI.</summary>
    class function IsValidURI(const pURIString: string): Boolean; static;

    /// <summary>Merges a base path with a relative path per RFC 3986, Section 5.2.3.</summary>
    class function MergePaths(const pBasePath, pRelativePath: string): string; static;

    /// <summary>Splits an authority component into userInfo, host and port sub-components.</summary>
    class procedure ParseAuthority(const pAuthority: string; out pUserInfo, pHost, pPort: string); static;

    /// <summary>Splits a userInfo string into username and password sub-components.</summary>
    class procedure ParseUserInfo(const pUserInfo: string; out pUsername, pPassword: string); static;

    /// <summary>Removes '.' and '..' segments from a path per RFC 3986, Section 5.2.4.</summary>
    class function RemoveDotSegments(const pPath: string): string; static;

    /// <summary>Normalizes percent-encoding sequences to uppercase per RFC 3986, Section 6.2.2.2.</summary>
    class function NormalizePercentEncoding(const pValue: string): string; static;

    /// <summary>Normalizes the scheme to lowercase per RFC 3986, Section 6.2.2.1.</summary>
    class function NormalizeScheme(const pScheme: string): string; static;

    /// <summary>Encodes a string value applying percent-encoding rules for the given set of unreserved characters.</summary>
    class function Encoding(const pValue, pCustomUnreserved: string): string; static;

    /// <summary>
    /// Encodes a string for use in the userinfo sub-component per RFC 3986, Section 3.2.1.
    /// Unreserved characters, sub-delims and ':' are preserved; all others are percent-encoded.
    /// </summary>
    class function EncodingUserInfo(const pValue: string): string; static;

    /// <summary>Navigates a JSON document using an RFC 6901 JSON Pointer and returns the referenced node.</summary>
    class function EvaluateJsonPointer(const pRootNode: TJSONValue; const pPointer: string): TJSONValue; static;
    /// <summary>Returns True if the supplied string is a syntactically valid RFC 6901 JSON Pointer.</summary>
    class function IsValidJsonPointer(const pPointer: string): Boolean; static;
    /// <summary>Returns True if the supplied string is a syntactically valid URI-reference.</summary>
    class function IsValidURIReference(const pURIString: string): Boolean; static;

    /// <summary>Decodes a JSON pointer segment according to RFC 6901 (~1 -> /, ~0 -> ~).</summary>
    class function DecodeJsonPointerSegment(const pInput: string; out pOutput: string): Boolean; static;
  end;

implementation

uses
  System.Classes,
  System.StrUtils,
  System.Character,
  System.Generics.Collections,
  JsonSchema.Core.URI.Validator;

{ TURIUtils }

class function TURIUtils.DecodeJsonPointerSegment(const pInput: string; out pOutput: string): Boolean;
begin
  pOutput := pInput.Replace('~1', '/').Replace('~0', '~');
  Result := True;
end;

class function TURIUtils.Encoding(const pValue, pCustomUnreserved: string): string;
const
  UNRESERVED_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
var
  lHex: string;
  lByte: Integer;
  lCount: Integer;
  lBuilder: TStringBuilder;

  function IsReserved(const pChar: Char): Boolean;
  begin
    Result := not (Pos(pChar, UNRESERVED_CHARS) + Pos(pChar, pCustomUnreserved) > 0);
  end;
begin
  if pValue.IsEmpty then
    Exit('');

  lBuilder := TStringBuilder.Create;
  try
    lCount := 1;
    while lCount <= Length(pValue) do
    begin
      if (pValue[lCount] = '%') and (lCount + 2 <= Length(pValue)) then
      begin
        lHex := pValue.Substring(lCount, 2);
        if TryStrToInt('$' + lHex, lByte) then
        begin
          if not IsReserved(Char(lByte)) then
            lBuilder.Append(Char(lByte))
          else
            lBuilder.Append('%' + lHex.ToUpper);
          Inc(lCount, 3);
        end else
        begin
          lBuilder.Append(pValue[lCount]);
          Inc(lCount);
        end;
      end else if IsReserved(pValue[lCount]) then
      begin
        lBuilder.Append('%' + IntToHex(Ord(pValue[lCount]), 2));
        Inc(lCount);
      end else
      begin
        lBuilder.Append(pValue[lCount]);
        Inc(lCount);
      end;
    end;
    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

class function TURIUtils.EncodingUserInfo(const pValue: string): string;
begin
  Result := Encoding(pValue, '!$&''()*+,;=');
end;

class function TURIUtils.EvaluateJsonPointer(const pRootNode: TJSONValue; const pPointer: string): TJSONValue;
var
  lSegments: TArray<string>;
  lSegment: string;
  lSegmentStr: string;
  lCurrentNode: TJSONValue;
  lIndex: Integer;
begin
  if not Assigned(pRootNode) then
    Exit(nil);

  if pPointer.IsEmpty then
    Exit(pRootNode);

  if not pPointer.StartsWith('/') then
    Exit(nil);

  lCurrentNode := pRootNode;
  lSegments := pPointer.Substring(1).Split(['/']);

  for lSegment in lSegments do
  begin
    if not Assigned(lCurrentNode) then
      Exit(nil);

    if not DecodeJsonPointerSegment(lSegment, lSegmentStr) then
      Exit(nil);

    if lCurrentNode is TJSONObject then
      lCurrentNode := (lCurrentNode as TJSONObject).GetValue(lSegmentStr)
    else if lCurrentNode is TJSONArray then
    begin
      if TryStrToInt(lSegmentStr, lIndex) and (lIndex >= 0) and (lIndex < (lCurrentNode as TJSONArray).Count) then
        lCurrentNode := (lCurrentNode as TJSONArray).Items[lIndex]
      else
        Exit(nil);
    end else
      Exit(nil);
  end;

  Result := lCurrentNode;
end;

class function TURIUtils.IsValidJsonPointer(const pPointer: string): Boolean;
var
  lSegments: TArray<string>;
  lSegment: string;
  lCount: Integer;
begin
  if pPointer = '' then
    Exit(True);

  if not pPointer.StartsWith('/') then
    Exit(False);

  lSegments := pPointer.Substring(1).Split(['/']);
  for lSegment in lSegments do
  begin
    lCount := 1;
    while lCount <= Length(lSegment) do
    begin
      if lSegment[lCount] = '~' then
      begin
        if (lCount = Length(lSegment)) or
           ((lSegment[lCount + 1] <> '0') and (lSegment[lCount + 1] <> '1')) then
          Exit(False);

        Inc(lCount, 2);
      end else
        Inc(lCount);
    end;
  end;

  Result := True;
end;

class function TURIUtils.IsValidURIReference(const pURIString: string): Boolean;
var
  lURI: TURIReference;
  lValidator: TURIValidator;
  lChar: Char;
begin
  for lChar in pURIString do
    if (Ord(lChar) <= 32) or (Ord(lChar) = 127) then
      Exit(False);

  try
    lURI := TURIReference.From(pURIString);
    lValidator := TURIValidator.Create;
    try
      lValidator.Validate(lURI);
    finally
      lValidator.Free;
    end;
    Result := True;
  except
    on ERFC3986Exception do
      Result := False;
  end;
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
    on ERFC3986Exception do
      Result := False;
  end;
end;

class function TURIUtils.MergePaths(const pBasePath, pRelativePath: string): string;
var
  lPos: Integer;
begin
  if pBasePath = '' then
    Exit(pRelativePath);

  lPos := pBasePath.LastIndexOf('/');
  if lPos < 0 then
    Exit(pRelativePath)
  else
    Result := pBasePath.Substring(0, lPos + 1) + pRelativePath;
end;

class function TURIUtils.NormalizePercentEncoding(const pValue: string): string;
const
  UNRESERVED_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
var
  lHex: string;
  lByte: Integer;
  lCount: Integer;
  lBuilder: TStringBuilder;
begin
  if pValue.IsEmpty then
    Exit('');

  lBuilder := TStringBuilder.Create;
  try
    lCount := 1;
    while lCount <= Length(pValue) do
    begin
      if (pValue[lCount] = '%') and (lCount + 2 <= Length(pValue)) then
      begin
        lHex := pValue.Substring(lCount, 2);
        if TryStrToInt('$' + lHex, lByte) then
        begin
          if Pos(Char(lByte), UNRESERVED_CHARS) > 0 then
            lBuilder.Append(Char(lByte))
          else
            lBuilder.Append('%' + lHex.ToUpper);
          Inc(lCount, 3);
        end else
        begin
          lBuilder.Append(pValue[lCount]);
          Inc(lCount);
        end;
      end else
      begin
        lBuilder.Append(pValue[lCount]);
        Inc(lCount);
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

class function TURIUtils.NormalizeURI(const pURIString: string): string;
var
  lURI, lNormalizedURI: TURIReference;
begin
  lURI := TURIReference.From(pURIString);
  lNormalizedURI := lURI.Normalize;
  Result := lNormalizedURI.Unsplit;
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

  if pAuthority = '' then
    Exit;

  lRest := pAuthority;

  lAtPos := lRest.LastIndexOf('@');
  if lAtPos > -1 then
  begin
    pUserInfo := lRest.Substring(0, lAtPos);
    lRest := lRest.Substring(lAtPos + 1);
  end;

  // Handle IPv6 literal hosts, e.g. [::1].
  lBracketPos := lRest.LastIndexOf(']');
  if lRest.StartsWith('[') and (lBracketPos > 0) then
  begin
    pHost := lRest.Substring(0, lBracketPos + 1);
    lRest := lRest.Substring(lBracketPos + 1);
    if lRest.StartsWith(':') then
      pPort := lRest.Substring(1)
    else
      pPort := '';
  end else
  begin
    lColonPos := lRest.LastIndexOf(':');
    if (lColonPos > -1) and (lRest.IndexOf(']') < lColonPos) then
    begin
      pHost := lRest.Substring(0, lColonPos);
      pPort := lRest.Substring(lColonPos + 1);
    end else
    begin
      pHost := lRest;
      pPort := '';
    end;
  end;
end;

class procedure TURIUtils.ParseUserInfo(const pUserInfo: string; out pUsername, pPassword: string);
var
  lAtPos: Integer;
begin
  pUsername := '';
  pPassword := '';

  if pUserInfo = '' then
    Exit;

  lAtPos := pUserInfo.IndexOf(':');
  if lAtPos > -1 then
  begin
    pUsername := pUserInfo.Substring(0, lAtPos);
    pPassword := pUserInfo.Substring(lAtPos + 1);
  end else
    pUsername := pUserInfo;
end;

class function TURIUtils.RemoveDotSegments(const pPath: string): string;
var
  lCount: Integer;
  lInput: TStringList;
  lOutput: TStringList;
begin
  if pPath = '' then
    Exit('');

  lInput := TStringList.Create;
  lOutput := TStringList.Create;
  try
    lInput.Text := pPath.Replace('/', sLineBreak);

    for lCount := 0 to lInput.Count - 1 do
    begin
      if lInput[lCount] = '..' then
      begin
        if lOutput.Count > 0 then
          lOutput.Delete(lOutput.Count - 1);
      end else if lInput[lCount] <> '.' then
        lOutput.Add(lInput[lCount]);
    end;

    Result := lOutput.Text.TrimRight.Replace(sLineBreak, '/');

    if pPath.StartsWith('/') and (Result <> '') and not Result.StartsWith('/') then
      Result := '/' + Result;

    if not Result.EndsWith('/') then
      if (pPath.EndsWith('/.') or pPath.EndsWith('/..') or pPath.EndsWith('/') or MatchStr(pPath, ['.', '..'])) then
        Result := Result + '/';
  finally
    lInput.Free;
    lOutput.Free;
  end;
end;

end.
