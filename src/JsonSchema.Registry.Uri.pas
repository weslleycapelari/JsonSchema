unit JsonSchema.Registry.Uri;

interface

type
  /// <summary>
  /// Immutable five-component URI reference as specified by RFC 3986.
  /// All mutation methods (Normalize, ResolveWith) return new instances.
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
    /// <param name="pURIString">The URI string to parse.</param>
    /// <param name="pEncoding">Character encoding hint (default: utf-8).</param>
    /// <returns>A populated TURIReference instance.</returns>
    class function From(const pURIString: string; const pEncoding: string = 'utf-8'): TURIReference; static;

    /// <summary>Reassembles the URI components into a single string (RFC 3986, Section 5.3).</summary>
    function Unsplit: string;

    /// <summary>Returns True if the URI has a scheme and no fragment (RFC 3986, Section 4.3).</summary>
    function IsAbsolute: Boolean;

    /// <summary>Returns a new normalized TURIReference (RFC 3986, Section 6).</summary>
    function Normalize: TURIReference;

    /// <summary>
    /// Resolves this URI (potentially relative) against a base URI (RFC 3986, Section 5.2).
    /// </summary>
    /// <param name="pBaseURI">The absolute base URI for resolution.</param>
    /// <returns>A new TURIReference representing the resolved URI.</returns>
    function ResolveWith(const pBaseURI: TURIReference): TURIReference;

    /// <summary>Returns a copy of this reference with the specified components replaced.</summary>
    function CopyWith(const pScheme, pAuthority, pPath, pQuery, pFragment: string): TURIReference;

    /// <summary>Returns True if this URI and pURI share the same scheme and authority.</summary>
    function IsSameOrigin(const pURI: TURIReference): Boolean;

    class operator Equal(const pA, pB: TURIReference): Boolean;
    class operator NotEqual(const pA, pB: TURIReference): Boolean;

    class function New(const pURIString: string): TURIReference; static;

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
    /// <summary>The port sub-component of the authority.</summary>
    function Port: string;
  end;

implementation

uses
  System.SysUtils,
  System.RegularExpressions,
  JsonSchema.Registry.Types,
  JsonSchema.Registry.Utils;

{ TURIReference }

function TURIReference.CopyWith(const pScheme, pAuthority, pPath, pQuery, pFragment: string): TURIReference;
begin
  Result.FScheme    := pScheme;
  Result.FAuthority := pAuthority;
  Result.FPath      := pPath;
  Result.FQuery     := pQuery;
  Result.FFragment  := pFragment;
  Result.FEncoding  := Self.FEncoding;
end;

class operator TURIReference.Equal(const pA, pB: TURIReference): Boolean;
var
  lNormA, lNormB: TURIReference;
begin
  Result := (pA.FScheme    = pB.FScheme)    and
            (pA.FAuthority = pB.FAuthority) and
            (pA.FPath      = pB.FPath)      and
            (pA.FQuery     = pB.FQuery)     and
            (pA.FFragment  = pB.FFragment);

  if Result then
    Exit;

  // Normalized comparison per RFC 6.2.2.
  lNormA := pA.Normalize;
  lNormB := pB.Normalize;
  Result := (lNormA.FScheme    = lNormB.FScheme)    and
            (lNormA.FAuthority = lNormB.FAuthority) and
            (lNormA.FPath      = lNormB.FPath)      and
            (lNormA.FQuery     = lNormB.FQuery)     and
            (lNormA.FFragment  = lNormB.FFragment);
end;

class function TURIReference.From(const pURIString, pEncoding: string): TURIReference;
var
  lMatch: TMatch;

  function GetGroupValue(const pName: string): string;
  begin
    if not lMatch.Groups.ContainsNamedGroup(pName) then
      Exit;

    Result := lMatch.Groups[pName].Value;
  end;
begin
  if pURIString.IsEmpty then
    Exit;

  lMatch := TRegEx.Create(URI_PATTERN).Match(pURIString);

  if not lMatch.Success then
    raise ERFC3986Exception.CreateFmt('Invalid URI string: "%s"', [pURIString]);

  Result.FScheme    := GetGroupValue('scheme');
  Result.FAuthority := GetGroupValue('authority');
  Result.FPath      := GetGroupValue('path');
  Result.FQuery     := GetGroupValue('query');
  Result.FFragment  := GetGroupValue('fragment');
  Result.FEncoding  := pEncoding;
end;

function TURIReference.Host: string;
var
  lUserInfo, lHost, lPort: string;
begin
  TURIUtils.ParseAuthority(Self.FAuthority, lUserInfo, lHost, lPort);
  Result := lHost;
end;

function TURIReference.IsAbsolute: Boolean;
begin
  Result := (FScheme <> '') and (FFragment = '');
end;

function TURIReference.IsSameOrigin(const pURI: TURIReference): Boolean;
var
  lNormA, lNormB: TURIReference;
begin
  Result := (Self.FScheme = pURI.FScheme) and (Self.FAuthority = pURI.FAuthority);

  if Result then
    Exit;

  // Normalized comparison per RFC 6.2.2.
  lNormA := Self.Normalize;
  lNormB := pURI.Normalize;
  Result := (lNormA.FScheme = lNormB.FScheme) and (lNormA.FAuthority = lNormB.FAuthority);
end;

class function TURIReference.New(const pURIString: string): TURIReference;
begin
  Result := TURIReference.From(pURIString);
end;

function TURIReference.Normalize: TURIReference;
var
  lUserInfo, lHost, lPort, lUsername, lPassword: string;
  lAuthorityBuilder: TStringBuilder;
begin
  // 1. Normalize scheme to lowercase.
  Result.FScheme := TURIUtils.NormalizeScheme(Self.FScheme);

  // 2. Decompose, normalize, and reassemble the authority.
  if Self.FAuthority <> '' then
  begin
    // 2a. Decompose the authority into sub-components.
    TURIUtils.ParseAuthority(Self.FAuthority, lUserInfo, lHost, lPort);
    TURIUtils.ParseUserInfo(lUserInfo, lUsername, lPassword);

    // 2b. Normalize each sub-component.
    lHost := lHost.ToLower;
    // Port has no syntax normalization (scheme-based port removal is not performed).

    // 2c. Reassemble the authority string from normalized sub-components.
    lAuthorityBuilder := TStringBuilder.Create;
    try
      if not lUserInfo.IsEmpty then
      begin
        if not lUsername.IsEmpty then
          lAuthorityBuilder.Append(TURIUtils.EncodingUserInfo(lUsername));

        if not lPassword.IsEmpty then
        begin
          lAuthorityBuilder.Append(':');
          lAuthorityBuilder.Append(TURIUtils.EncodingUserInfo(lPassword));
        end;

        lAuthorityBuilder.Append('@');
      end;

      lAuthorityBuilder.Append(lHost);

      if not lPort.IsEmpty then
      begin
        lAuthorityBuilder.Append(':');
        lAuthorityBuilder.Append(lPort);
      end;
      Result.FAuthority := lAuthorityBuilder.ToString;
    finally
      lAuthorityBuilder.Free;
    end;
  end
  else
    Result.FAuthority := '';

  // 3. Normalize remaining components.
  Result.FPath     := TURIUtils.NormalizePercentEncoding(TURIUtils.RemoveDotSegments(Self.FPath));
  Result.FQuery    := TURIUtils.NormalizePercentEncoding(Self.FQuery);
  Result.FFragment := TURIUtils.NormalizePercentEncoding(Self.FFragment);

  // 4. Preserve the encoding hint.
  Result.FEncoding := Self.FEncoding;
end;

class operator TURIReference.NotEqual(const pA, pB: TURIReference): Boolean;
begin
  Result := not (pA = pB);
end;

function TURIReference.Port: string;
var
  lUserInfo, lHost, lPort: string;
begin
  TURIUtils.ParseAuthority(Self.FAuthority, lUserInfo, lHost, lPort);
  Result := lPort;
end;

function TURIReference.ResolveWith(const pBaseURI: TURIReference): TURIReference;
begin
  // RFC 3986, Section 5.2.2 resolution algorithm.
  // R = Self, Base = pBaseURI, T = Result
  if Self.FScheme <> '' then
  begin
    Result.FScheme    := Self.FScheme;
    Result.FAuthority := Self.FAuthority;
    Result.FPath      := TURIUtils.RemoveDotSegments(Self.FPath);
    Result.FQuery     := Self.FQuery;
  end
  else
  begin
    if Self.FAuthority <> '' then
    begin
      Result.FAuthority := Self.FAuthority;
      Result.FPath      := TURIUtils.RemoveDotSegments(Self.FPath);
      Result.FQuery     := Self.FQuery;
    end
    else
    begin
      if Self.FPath = '' then
      begin
        Result.FPath := pBaseURI.FPath;
        if Self.FQuery <> '' then
          Result.FQuery := Self.FQuery
        else
          Result.FQuery := pBaseURI.FQuery;
      end
      else
      begin
        if Self.FPath.StartsWith('/') then
          Result.FPath := TURIUtils.RemoveDotSegments(Self.FPath)
        else
        begin
          var lMergedPath: string;
          if (pBaseURI.FAuthority <> '') and (pBaseURI.FPath = '') then
            lMergedPath := '/' + Self.FPath
          else
            lMergedPath := TURIUtils.MergePaths(pBaseURI.FPath, Self.FPath);
          Result.FPath := TURIUtils.RemoveDotSegments(lMergedPath);
        end;
        Result.FQuery := Self.FQuery;
      end;
      Result.FAuthority := pBaseURI.FAuthority;
    end;
    Result.FScheme := pBaseURI.FScheme;
  end;

  Result.FFragment := Self.FFragment;
  Result.FEncoding := Self.FEncoding;
end;

function TURIReference.Unsplit: string;
var
  lBuilder: TStringBuilder;
begin
  lBuilder := TStringBuilder.Create;
  try
    if FScheme <> '' then
    begin
      lBuilder.Append(FScheme);
      lBuilder.Append(':');
    end;

    if FAuthority <> '' then
    begin
      lBuilder.Append('//');
      lBuilder.Append(FAuthority);
    end;

    lBuilder.Append(FPath);

    // A simplified implementation that does not distinguish an absent query component
    // from an empty one (e.g. "a.com" vs "a.com?"). Both are stored as '' by From.
    if FQuery <> '' then
    begin
      lBuilder.Append('?');
      lBuilder.Append(FQuery);
    end;

    if FFragment <> '' then
    begin
      lBuilder.Append('#');
      lBuilder.Append(FFragment);
    end;

    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

function TURIReference.UserInfo: string;
var
  lUserInfo, lHost, lPort: string;
begin
  TURIUtils.ParseAuthority(Self.FAuthority, lUserInfo, lHost, lPort);
  Result := lUserInfo;
end;

end.
