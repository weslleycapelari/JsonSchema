unit JsonSchema.Registry.Uri.Validator;

interface

uses
  System.Classes,
  JsonSchema.Exceptions,
  JsonSchema.Registry.Types,
  JsonSchema.Registry.Uri;

type
  /// <summary>
  ///   Configures and executes validation rules against a TURIReference.
  ///   Build rules fluently, then call Validate to enforce them.
  /// </summary>
  TURIValidator = class
  private
    FRequiredComponents: TURIComponents;
    FAllowedSchemes: TStringList;
    FAllowedHosts: TStringList;
    FForbidPassword: Boolean;
    FForbidUserInfo: Boolean;
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

    /// <summary>Fails validation when the URI contains any userinfo component.</summary>
    function ForbidUserInfo: TURIValidator;

    /// <summary>Validates the URI against all configured rules.</summary>
    /// <exception cref="EValidationError">Raised when the URI fails any configured rule.</exception>
    procedure Validate(const pURI: TURIReference);
  end;

implementation

uses
  System.SysUtils;

{ TURIValidator }

constructor TURIValidator.Create;
begin
  inherited Create;
  FRequiredComponents := [];
  FAllowedSchemes := TStringList.Create;
  FAllowedHosts := TStringList.Create;
  FForbidPassword := False;
  FForbidUserInfo := False;
end;

destructor TURIValidator.Destroy;
begin
  FAllowedSchemes.Free;
  FAllowedHosts.Free;
  inherited;
end;

function TURIValidator.RequirePresenceOf(const pComponents: TURIComponents): TURIValidator;
begin
  FRequiredComponents := FRequiredComponents + pComponents;
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

function TURIValidator.AllowHosts(const pHosts: array of string): TURIValidator;
var
  lHost: string;
begin
  FAllowedHosts.Clear;
  for lHost in pHosts do
    FAllowedHosts.Add(lHost.ToLower);
  Result := Self;
end;

function TURIValidator.ForbidPassword: TURIValidator;
begin
  FForbidPassword := True;
  Result := Self;
end;

function TURIValidator.ForbidUserInfo: TURIValidator;
begin
  FForbidUserInfo := True;
  Result := Self;
end;

procedure TURIValidator.Validate(const pURI: TURIReference);
var
  lRequiredComponents: TURIComponents;
  lComponent: TURIComponent;
  lMissingComponents: string;
  lUserInfo: string;
  lPasswordPresent: Boolean;
begin
  lRequiredComponents := FRequiredComponents;

  // URN URIs do not have an authority component
  if SameText(pURI.Scheme, 'urn') then
    lRequiredComponents := lRequiredComponents - [uricAuthority];

  lMissingComponents := '';
  for lComponent in lRequiredComponents do
  begin
    case lComponent of
      uricScheme:
        if pURI.Scheme.IsEmpty then
          lMissingComponents := lMissingComponents + 'Scheme, ';
      uricAuthority:
        if pURI.Authority.IsEmpty then
          lMissingComponents := lMissingComponents + 'Authority, ';
      uricUserInfo:
        if pURI.UserInfo.IsEmpty then
          lMissingComponents := lMissingComponents + 'UserInfo, ';
      uricHost:
        if pURI.Host.IsEmpty then
          lMissingComponents := lMissingComponents + 'Host, ';
      uricPath:
        if pURI.Path.IsEmpty then
          lMissingComponents := lMissingComponents + 'Path, ';
      uricQuery:
        if pURI.Query.IsEmpty then
          lMissingComponents := lMissingComponents + 'Query, ';
      uricFragment:
        if pURI.Fragment.IsEmpty then
          lMissingComponents := lMissingComponents + 'Fragment, ';
    end;
  end;

  if not lMissingComponents.IsEmpty then
  begin
    lMissingComponents := lMissingComponents.Substring(0, lMissingComponents.Length - 2);
    raise EMissingComponentError.CreateFmt(
      'Required URI component(s) are missing: [%s]', [lMissingComponents]);
  end;

  if (FAllowedSchemes.Count > 0) and (FAllowedSchemes.IndexOf(pURI.Scheme.ToLower) = -1) then
    raise EValidationError.CreateFmt(
      'Scheme "%s" is not in the list of allowed schemes.', [pURI.Scheme]);

  if (FAllowedHosts.Count > 0) and (FAllowedHosts.IndexOf(pURI.Host.ToLower) = -1) then
    raise EValidationError.CreateFmt(
      'Host "%s" is not in the list of allowed hosts.', [pURI.Host]);

  if FForbidUserInfo then
  begin
    lUserInfo := pURI.UserInfo;
    if not lUserInfo.IsEmpty then
      raise EValidationError.Create('URI contains userinfo, which is forbidden by the validator.');
  end;

  if FForbidPassword then
  begin
    lUserInfo := pURI.UserInfo;
    lPasswordPresent := (lUserInfo <> '') and (lUserInfo.IndexOf(':') > -1);
    if lPasswordPresent then
      raise EValidationError.Create('URI contains a password, which is forbidden by the validator.');
  end;
end;

end.
