unit JsonSchema.Registry.Uri;

interface

uses
  JsonSchema.Registry.Types,
  JsonSchema.Registry.Utils;

type
  /// <summary>
  ///   Immutable five-component URI reference as specified by RFC 3986.
  ///   All mutation methods (Normalize, ResolveWith) return new instances.
  /// </summary>
  TURIReference = record
  private
    FScheme: string;
    FAuthority: string;
    FPath: string;
    FQuery: string;
    FFragment: string;
    FEncoding: string;
  public
    /// <summary>Parses a URI string into its five components.</summary>
    class function From(const pURIString: string; const pEncoding: string = 'utf-8'): TURIReference; static;

    /// <summary>Convenience factory method with default encoding.</summary>
    class function New(const pURIString: string): TURIReference; static;

    /// <summary>Reassembles the URI components into a single string (RFC 3986, Section 5.3).</summary>
    function Unsplit: string;

    /// <summary>Returns True if the URI has a scheme and no fragment (RFC 3986, Section 4.3).</summary>
    function IsAbsolute: Boolean;

    /// <summary>Returns a new normalized TURIReference (RFC 3986, Section 6).</summary>
    function Normalize: TURIReference;

    /// <summary>
    ///   Resolves this URI (potentially relative) against a base URI (RFC 3986, Section 5.2).
    /// </summary>
    function ResolveWith(const pBaseURI: TURIReference): TURIReference;

    /// <summary>Returns a copy of this reference with the specified components replaced.</summary>
    function CopyWith(const pScheme, pAuthority, pPath, pQuery, pFragment: string): TURIReference;

    /// <summary>Returns True if this URI and pURI share the same scheme and authority.</summary>
    function IsSameOrigin(const pURI: TURIReference): Boolean;

    class operator Equal(const pA, pB: TURIReference): Boolean;
    class operator NotEqual(const pA, pB: TURIReference): Boolean;

    property Scheme: string read FScheme write FScheme;
    property Authority: string read FAuthority write FAuthority;
    property Path: string read FPath write FPath;
    property Query: string read FQuery write FQuery;
    property Fragment: string read FFragment write FFragment;
    property Encoding: string read FEncoding write FEncoding;

    /// <summary>The userinfo sub-component of the authority.</summary>
    function UserInfo: string;

    /// <summary>The host sub-component of the authority.</summary>
    function Host: string;

    /// <summary>The port sub-component of the authority (as string, empty if absent).</summary>
    function Port: string;
  end;

implementation

uses
  System.SysUtils,
  System.RegularExpressions,
  System.StrUtils,
  JsonSchema.Exceptions;

{ TURIReference }

class function TURIReference.From(const pURIString, pEncoding: string): TURIReference;
var
  lMatch: TMatch;

  function GetGroup(const pName: string): string;
  begin
    if lMatch.Groups.ContainsNamedGroup(pName) then
      Result := lMatch.Groups[pName].Value
    else
      Result := '';
  end;
begin
  if pURIString.IsEmpty then
    raise EJsonSchemaError.Create('Cannot parse empty URI string');

  lMatch := TRegEx.Create(URI_PATTERN).Match(pURIString);
  if not lMatch.Success then
    raise EJsonSchemaError.CreateFmt('Invalid URI string: "%s"', [pURIString]);

  Result.FScheme := GetGroup('scheme');
  Result.FAuthority := GetGroup('authority');
  Result.FPath := GetGroup('path');
  Result.FQuery := GetGroup('query');
  Result.FFragment := GetGroup('fragment');
  Result.FEncoding := pEncoding;
end;

class function TURIReference.New(const pURIString: string): TURIReference;
begin
  Result := From(pURIString);
end;

function TURIReference.Unsplit: string;
var
  lBuilder: TStringBuilder;
begin
  lBuilder := TStringBuilder.Create;
  try
    if not FScheme.IsEmpty then
    begin
      lBuilder.Append(FScheme);
      lBuilder.Append(':');
    end;

    if not FAuthority.IsEmpty then
    begin
      lBuilder.Append('//');
      lBuilder.Append(FAuthority);
    end;

    lBuilder.Append(FPath);

    if not FQuery.IsEmpty then
    begin
      lBuilder.Append('?');
      lBuilder.Append(FQuery);
    end;

    if not FFragment.IsEmpty then
    begin
      lBuilder.Append('#');
      lBuilder.Append(FFragment);
    end;

    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

function TURIReference.IsAbsolute: Boolean;
begin
  Result := (not FScheme.IsEmpty) and (FFragment.IsEmpty);
end;

function TURIReference.Normalize: TURIReference;
var
  lUserInfo: string;
  lHost: string;
  lPort: string;
  lUsername: string;
  lPassword: string;
  lBuilder: TStringBuilder;
begin
  // 1. Normalize scheme to lowercase
  Result.FScheme := TURIUtils.NormalizeScheme(FScheme);

  // 2. Normalize authority
  if not FAuthority.IsEmpty then
  begin
    TURIUtils.ParseAuthority(FAuthority, lUserInfo, lHost, lPort);
    TURIUtils.ParseUserInfo(lUserInfo, lUsername, lPassword);
    lHost := lHost.ToLower;

    lBuilder := TStringBuilder.Create;
    try
      if not lUserInfo.IsEmpty then
      begin
        if not lUsername.IsEmpty then
          lBuilder.Append(TURIUtils.EncodingUserInfo(lUsername));
        if not lPassword.IsEmpty then
        begin
          lBuilder.Append(':');
          lBuilder.Append(TURIUtils.EncodingUserInfo(lPassword));
        end;
        lBuilder.Append('@');
      end;

      lBuilder.Append(lHost);
      if not lPort.IsEmpty then
      begin
        lBuilder.Append(':');
        lBuilder.Append(lPort);
      end;
      Result.FAuthority := lBuilder.ToString;
    finally
      lBuilder.Free;
    end;
  end
  else
    Result.FAuthority := '';

  // 3. Normalize path: remove dot segments, normalize percent-encoding
  Result.FPath := TURIUtils.NormalizePercentEncoding(TURIUtils.RemoveDotSegments(FPath));

  // 4. Normalize query and fragment percent-encoding
  Result.FQuery := TURIUtils.NormalizePercentEncoding(FQuery);
  Result.FFragment := TURIUtils.NormalizePercentEncoding(FFragment);

  Result.FEncoding := FEncoding;
end;

function TURIReference.ResolveWith(const pBaseURI: TURIReference): TURIReference;
begin
  // RFC 3986, Section 5.2.2
  if FScheme <> '' then
  begin
    Result.FScheme := FScheme;
    Result.FAuthority := FAuthority;
    Result.FPath := TURIUtils.RemoveDotSegments(FPath);
    Result.FQuery := FQuery;
  end
  else
  begin
    if FAuthority <> '' then
    begin
      Result.FAuthority := FAuthority;
      Result.FPath := TURIUtils.RemoveDotSegments(FPath);
      Result.FQuery := FQuery;
    end
    else
    begin
      if FPath = '' then
      begin
        Result.FPath := pBaseURI.FPath;
        if FQuery <> '' then
          Result.FQuery := FQuery
        else
          Result.FQuery := pBaseURI.FQuery;
      end
      else
      begin
        if FPath.StartsWith('/') then
          Result.FPath := TURIUtils.RemoveDotSegments(FPath)
        else
        begin
          if (pBaseURI.FAuthority <> '') and (pBaseURI.FPath = '') then
            Result.FPath := '/' + FPath
          else
            Result.FPath := TURIUtils.RemoveDotSegments(TURIUtils.MergePaths(pBaseURI.FPath, FPath));
        end;
        Result.FQuery := FQuery;
      end;
      Result.FAuthority := pBaseURI.FAuthority;
    end;
    Result.FScheme := pBaseURI.FScheme;
  end;

  Result.FFragment := FFragment;
  Result.FEncoding := FEncoding;
end;

function TURIReference.CopyWith(const pScheme, pAuthority, pPath, pQuery, pFragment: string): TURIReference;
begin
  Result.FScheme := pScheme;
  Result.FAuthority := pAuthority;
  Result.FPath := pPath;
  Result.FQuery := pQuery;
  Result.FFragment := pFragment;
  Result.FEncoding := FEncoding;
end;

function TURIReference.IsSameOrigin(const pURI: TURIReference): Boolean;
var
  lNormA: TURIReference;
  lNormB: TURIReference;
begin
  Result := (FScheme = pURI.FScheme) and (FAuthority = pURI.FAuthority);
  if Result then
    Exit;

  lNormA := Self.Normalize;
  lNormB := pURI.Normalize;
  Result := (lNormA.FScheme = lNormB.FScheme) and (lNormA.FAuthority = lNormB.FAuthority);
end;

class operator TURIReference.Equal(const pA, pB: TURIReference): Boolean;
var
  lNormA: TURIReference;
  lNormB: TURIReference;
begin
  Result := (pA.FScheme = pB.FScheme) and
            (pA.FAuthority = pB.FAuthority) and
            (pA.FPath = pB.FPath) and
            (pA.FQuery = pB.FQuery) and
            (pA.FFragment = pB.FFragment);

  if Result then
    Exit;

  lNormA := pA.Normalize;
  lNormB := pB.Normalize;
  Result := (lNormA.FScheme = lNormB.FScheme) and
            (lNormA.FAuthority = lNormB.FAuthority) and
            (lNormA.FPath = lNormB.FPath) and
            (lNormA.FQuery = lNormB.FQuery) and
            (lNormA.FFragment = lNormB.FFragment);
end;

class operator TURIReference.NotEqual(const pA, pB: TURIReference): Boolean;
begin
  Result := not (pA = pB);
end;

function TURIReference.UserInfo: string;
var
  lUserInfo: string;
  lHost: string;
  lPort: string;
begin
  TURIUtils.ParseAuthority(FAuthority, lUserInfo, lHost, lPort);
  Result := lUserInfo;
end;

function TURIReference.Host: string;
var
  lUserInfo: string;
  lHost: string;
  lPort: string;
begin
  TURIUtils.ParseAuthority(FAuthority, lUserInfo, lHost, lPort);
  Result := lHost;
end;

function TURIReference.Port: string;
var
  lUserInfo: string;
  lHost: string;
  lPort: string;
begin
  TURIUtils.ParseAuthority(FAuthority, lUserInfo, lHost, lPort);
  Result := lPort;
end;

end.
