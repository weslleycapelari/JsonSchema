unit JsonSchema.Registry.Uri.Validator;

interface

uses
  System.Classes,
  JsonSchema.Registry.Types,
  JsonSchema.Registry.Uri;

type
  /// <summary>
  /// Configures and executes validation rules against a TURIReference.
  /// Build rules fluently, then call Validate to enforce them.
  /// </summary>
  TURIValidator = class
  private
    FRequiredComponents: TURIComponents;
    FAllowedSchemes: TStrings;
    FAllowedHosts: TStrings;
    FForbidPassword: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Requires the specified components to be non-empty in the validated URI.</summary>
    function RequirePresenceOf(const pComponents: TURIComponents): TURIValidator;
    /// <summary>Restricts the URI to one of the specified schemes (case-insensitive).</summary>
    function AllowSchemes(const pSchemes: array of string): TURIValidator;
    /// <summary>Restricts the URI to one of the specified hosts (case-insensitive).</summary>
    function AllowHosts(const pHosts: array of string): TURIValidator;
    /// <summary>Fails validation when the URI contains a password in the userinfo component.</summary>
    function ForbidPassword: TURIValidator;

    /// <summary>Validates the URI against all configured rules.</summary>
    /// <param name="pURI">The TURIReference to validate.</param>
    /// <exception cref="EValidationError">Raised when the URI fails any configured rule.</exception>
    procedure Validate(const pURI: TURIReference);
  end;

implementation

uses
  System.SysUtils;

{ TURIValidator }

function TURIValidator.AllowHosts(const pHosts: array of string): TURIValidator;
var
  lHost: string;
begin
  FAllowedHosts.Clear;
  for lHost in pHosts do
    FAllowedHosts.Add(lHost.ToLower);
  Result := Self;
end;

function TURIValidator.AllowSchemes(const pSchemes: array of string): TURIValidator;
var
  lScheme: string;
begin
  FAllowedSchemes.Clear;
  for lScheme in pSchemes do
    FAllowedSchemes.Add(lScheme.ToLower);
  Result := Self;
end;

constructor TURIValidator.Create;
begin
  inherited Create;
  FRequiredComponents := [];
  FAllowedSchemes     := TStringList.Create;
  FAllowedHosts       := TStringList.Create;
  FForbidPassword     := False;
end;

destructor TURIValidator.Destroy;
begin
  FAllowedSchemes.Free;
  FAllowedHosts.Free;
  inherited;
end;

function TURIValidator.ForbidPassword: TURIValidator;
begin
  FForbidPassword := True;
  Result := Self;
end;

function TURIValidator.RequirePresenceOf(const pComponents: TURIComponents): TURIValidator;
begin
  FRequiredComponents := FRequiredComponents + pComponents;
  Result := Self;
end;

procedure TURIValidator.Validate(const pURI: TURIReference);
var
  lComponent: TURIComponent;
  lRequiredComponents: TURIComponents;
  lMissingComponents: string;
  lUserInfo: string;
begin
  lRequiredComponents := FRequiredComponents;
  // URN URIs do not have an authority component.
  if SameText(pURI.Scheme, 'urn') then
    lRequiredComponents := lRequiredComponents - [uricAuthority];

  lMissingComponents := '';
  if lRequiredComponents <> [] then
  begin
    for lComponent in lRequiredComponents do
    begin
      case lComponent of
        uricScheme:    if pURI.Scheme = ''    then lMissingComponents := lMissingComponents + 'Scheme, ';
        uricAuthority: if pURI.Authority = '' then lMissingComponents := lMissingComponents + 'Authority, ';
        uricUserInfo:  if pURI.UserInfo = ''  then lMissingComponents := lMissingComponents + 'UserInfo, ';
        uricHost:      if pURI.Host = ''      then lMissingComponents := lMissingComponents + 'Host, ';
        uricPath:      if pURI.Path = ''      then lMissingComponents := lMissingComponents + 'Path, ';
        // Query and Fragment may be empty yet present (e.g. "a.com?"); only content presence is checked.
        uricQuery:     if pURI.Query = ''    then lMissingComponents := lMissingComponents + 'Query, ';
        uricFragment:  if pURI.Fragment = '' then lMissingComponents := lMissingComponents + 'Fragment, ';
      end;
    end;

    if lMissingComponents <> '' then
    begin
      lMissingComponents := lMissingComponents.Substring(0, lMissingComponents.Length - 2);
      raise EMissingComponentError.CreateFmt(
        'Required URI component(s) are missing: [%s]', [lMissingComponents]);
    end;
  end;

  if (FAllowedSchemes.Count > 0) and (FAllowedSchemes.IndexOf(pURI.Scheme.ToLower) = -1) then
    raise EValidationError.CreateFmt(
      'Scheme "%s" is not in the list of allowed schemes.', [pURI.Scheme]);

  if (FAllowedHosts.Count > 0) and (FAllowedHosts.IndexOf(pURI.Host.ToLower) = -1) then
    raise EValidationError.CreateFmt(
      'Host "%s" is not in the list of allowed hosts.', [pURI.Host]);

  if FForbidPassword then
  begin
    lUserInfo := pURI.UserInfo;
    // A ':' in userinfo signals a password sub-component (RFC 3986, Section 3.2.1).
    if (lUserInfo <> '') and (lUserInfo.IndexOf(':') > -1) then
      raise EValidationError.Create('URI contains a password, which is forbidden by the validator.');
  end;
end;

end.
