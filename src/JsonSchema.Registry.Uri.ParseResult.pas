unit JsonSchema.Registry.Uri.ParseResult;

interface

type
  /// <summary>
  /// Parsed representation of a URI, offering access to all RFC 3986 components
  /// including the sub-parts of the authority (userinfo, host, port).
  /// Equivalent to Python's urlparse result.
  /// </summary>
  TURIParseResult = record
    Scheme: string;
    UserInfo: string;
    Host: string;
    Port: Word;
    Path: string;
    Query: string;
    Fragment: string;

    /// <summary>
    /// Parses a URI string into its components.
    /// </summary>
    /// <param name="pURIString">The URI string to parse.</param>
    /// <param name="pEncoding">Character encoding hint (default: utf-8).</param>
    class function From(const pURIString: string; const pEncoding: string = 'utf-8'): TURIParseResult; static;

    /// <summary>Returns the netloc (authority) string combining userinfo, host, and port.</summary>
    function Netloc: string;
    /// <summary>Returns the host component, for compatibility with Python's urlparse.</summary>
    function Hostname: string;
  end;

implementation

uses
  System.SysUtils,
  JsonSchema.Registry.Uri,
  JsonSchema.Registry.Types,
  JsonSchema.Registry.Utils;

{ TURIParseResult }

class function TURIParseResult.From(const pURIString, pEncoding: string): TURIParseResult;
var
  lURI: TURIReference;
  lPortStr: string;
  lPortInt: Integer;
  lUserInfo, lUsername, lPassword: string;
begin
  lURI := TURIReference.From(pURIString, pEncoding);

  Result.Scheme   := lURI.Scheme;
  Result.Path     := lURI.Path;
  Result.Query    := lURI.Query;
  Result.Fragment := lURI.Fragment;

  TURIUtils.ParseAuthority(lURI.Authority, lUserInfo, Result.Host, lPortStr);
  TURIUtils.ParseUserInfo(lUserInfo, lUsername, lPassword);

  if not lUserInfo.IsEmpty then
  begin
    if not lUsername.IsEmpty then
      Result.UserInfo := TURIUtils.EncodingUserInfo(lUsername);

    if not lPassword.IsEmpty then
      Result.UserInfo := Result.UserInfo + ':' + TURIUtils.EncodingUserInfo(lPassword);
  end;

  if lPortStr <> '' then
  begin
    if not TryStrToInt(lPortStr, lPortInt) then
      raise EInvalidAuthority.CreateFmt('Invalid port value in authority component: "%s"', [lPortStr]);

    if (lPortInt < 0) or (lPortInt > High(Word)) then
      raise EInvalidAuthority.CreateFmt('Port value out of range (0-65535): %d', [lPortInt]);

    Result.Port := Word(lPortInt);
  end
  else
    Result.Port := 0;
end;

function TURIParseResult.Hostname: string;
begin
  Result := Self.Host;
end;

function TURIParseResult.Netloc: string;
var
  lBuilder: TStringBuilder;
begin
  if Self.Host = '' then
    Exit('');

  lBuilder := TStringBuilder.Create;
  try
    if Self.UserInfo <> '' then
    begin
      lBuilder.Append(Self.UserInfo);
      lBuilder.Append('@');
    end;

    lBuilder.Append(Self.Host);

    if Self.Port > 0 then
    begin
      lBuilder.Append(':');
      lBuilder.Append(Self.Port.ToString);
    end;

    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

end.
