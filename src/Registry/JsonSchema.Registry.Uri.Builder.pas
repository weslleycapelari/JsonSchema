unit JsonSchema.Registry.Uri.Builder;

interface

uses
  System.Generics.Collections,
  JsonSchema.Registry.Uri;

type
  /// <summary>
  ///   Fluent builder for programmatic construction of a TURIReference.
  ///   Compose a URI component by component; call Build or Unsplit to get the result.
  ///   Reference: RFC 3986, Section 5.3 (Component Recomposition).
  /// </summary>
  TURIBuilder = class
  private
    FScheme: string;
    FUserInfo: string;
    FHost: string;
    FPort: string;
    FPath: string;
    FQuery: string;
    FFragment: string;
  public
    constructor Create;

    /// <summary>Creates a builder pre-populated from an existing TURIReference.</summary>
    class function FromURI(const pURI: TURIReference): TURIBuilder; static;

    /// <summary>Sets the scheme component.</summary>
    function WithScheme(const pValue: string): TURIBuilder;

    /// <summary>
    ///   Sets the userinfo sub-component with percent-encoded credentials
    ///   per RFC 3986, Section 3.2.1.
    /// </summary>
    function WithCredentials(const pUsername, pPassword: string): TURIBuilder;

    /// <summary>Sets the host sub-component.</summary>
    function WithHost(const pValue: string): TURIBuilder;

    /// <summary>
    ///   Sets the port sub-component. The Word type constrains the range to 0-65535.
    ///   A value of 0 removes the port.
    /// </summary>
    function WithPort(const pValue: Word): TURIBuilder;

    /// <summary>
    ///   Sets the path component.
    ///   Automatically prepends '/' when an authority is present.
    /// </summary>
    function WithPath(const pValue: string): TURIBuilder;

    /// <summary>Appends a path segment, ensuring exactly one '/' separator.</summary>
    function AppendPath(const pValue: string): TURIBuilder;

    /// <summary>Sets the query component.</summary>
    function WithQuery(const pValue: string): TURIBuilder;

    /// <summary>Builds a URL-encoded query string from key-value pairs.</summary>
    function WithQueryFromPairs(const pPairs: TDictionary<string, string>): TURIBuilder;

    /// <summary>Sets the fragment component.</summary>
    function WithFragment(const pValue: string): TURIBuilder;

    /// <summary>Finalizes construction and returns the composed TURIReference.</summary>
    function Build: TURIReference;

    /// <summary>Finalizes construction and returns the URI as a string.</summary>
    function Unsplit: string;
  end;

implementation

uses
  System.SysUtils,
  System.NetEncoding,
  JsonSchema.Registry.Utils,
  JsonSchema.Exceptions;

{ TURIBuilder }

constructor TURIBuilder.Create;
begin
  FScheme := '';
  FUserInfo := '';
  FHost := '';
  FPort := '';
  FPath := '';
  FQuery := '';
  FFragment := '';
end;

class function TURIBuilder.FromURI(const pURI: TURIReference): TURIBuilder;
begin
  Result := TURIBuilder.Create;
  Result.FScheme := pURI.Scheme;
  Result.FUserInfo := pURI.UserInfo;
  Result.FHost := pURI.Host;
  Result.FPort := pURI.Port;
  Result.FPath := pURI.Path;
  Result.FQuery := pURI.Query;
  Result.FFragment := pURI.Fragment;
end;

function TURIBuilder.WithScheme(const pValue: string): TURIBuilder;
begin
  FScheme := pValue;
  Result := Self;
end;

function TURIBuilder.WithCredentials(const pUsername, pPassword: string): TURIBuilder;
var
  lEncoder: TNetEncoding;
begin
  if pUsername.IsEmpty then
    raise EJsonSchemaError.Create('Username cannot be empty in WithCredentials');

  lEncoder := TNetEncoding.URL;
  FUserInfo := TURIUtils.EncodingUserInfo(lEncoder.Encode(pUsername));

  if not pPassword.IsEmpty then
    FUserInfo := FUserInfo + ':' + TURIUtils.EncodingUserInfo(lEncoder.Encode(pPassword));

  Result := Self;
end;

function TURIBuilder.WithHost(const pValue: string): TURIBuilder;
begin
  FHost := pValue;
  Result := Self;
end;

function TURIBuilder.WithPort(const pValue: Word): TURIBuilder;
begin
  if pValue = 0 then
    FPort := ''
  else
    FPort := pValue.ToString;
  Result := Self;
end;

function TURIBuilder.WithPath(const pValue: string): TURIBuilder;
begin
  FPath := pValue;

  // Ensure the path starts with '/' when an authority is present
  if (FHost <> '') and not FPath.StartsWith('/') and (FPath <> '') then
    FPath := '/' + FPath;

  Result := Self;
end;

function TURIBuilder.AppendPath(const pValue: string): TURIBuilder;
var
  lBasePath: string;
  lAppendPath: string;
begin
  lBasePath := FPath.TrimRight(['/']);
  lAppendPath := pValue.Trim(['/']);

  if lBasePath.IsEmpty then
    FPath := '/' + lAppendPath
  else
    FPath := lBasePath + '/' + lAppendPath;

  Result := Self;
end;

function TURIBuilder.WithQuery(const pValue: string): TURIBuilder;
begin
  FQuery := pValue;
  Result := Self;
end;

function TURIBuilder.WithQueryFromPairs(const pPairs: TDictionary<string, string>): TURIBuilder;
var
  lBuilder: TStringBuilder;
  lEncoder: TNetEncoding;
  lPair: TPair<string, string>;
  lFirst: Boolean;
begin
  if (pPairs = nil) or (pPairs.Count = 0) then
  begin
    FQuery := '';
    Exit(Self);
  end;

  lBuilder := TStringBuilder.Create;
  lEncoder := TNetEncoding.URL;
  lFirst := True;
  try
    for lPair in pPairs do
    begin
      if not lFirst then
        lBuilder.Append('&');

      lBuilder.Append(lEncoder.Encode(lPair.Key));
      lBuilder.Append('=');
      lBuilder.Append(lEncoder.Encode(lPair.Value));
      lFirst := False;
    end;
    FQuery := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
  Result := Self;
end;

function TURIBuilder.WithFragment(const pValue: string): TURIBuilder;
begin
  FFragment := pValue;
  Result := Self;
end;

function TURIBuilder.Build: TURIReference;
var
  lAuthority: string;
  lAuthorityBuilder: TStringBuilder;
begin
  lAuthorityBuilder := TStringBuilder.Create;
  try
    if not FHost.IsEmpty then
    begin
      if not FUserInfo.IsEmpty then
      begin
        lAuthorityBuilder.Append(FUserInfo);
        lAuthorityBuilder.Append('@');
      end;
      lAuthorityBuilder.Append(FHost);
      if not FPort.IsEmpty then
      begin
        lAuthorityBuilder.Append(':');
        lAuthorityBuilder.Append(FPort);
      end;
    end;
    lAuthority := lAuthorityBuilder.ToString;
  finally
    lAuthorityBuilder.Free;
  end;

  Result.Scheme := FScheme;
  Result.Authority := lAuthority;
  Result.Path := FPath;
  Result.Query := FQuery;
  Result.Fragment := FFragment;
  Result.Encoding := 'utf-8';
  Result := Result.Normalize;
end;

function TURIBuilder.Unsplit: string;
begin
  Result := Self.Build.Unsplit;
end;

end.
