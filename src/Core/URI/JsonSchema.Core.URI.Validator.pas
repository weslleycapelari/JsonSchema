unit JsonSchema.Core.URI.Validator;

(*
--------------------------------------------------------------------------------
Provides TURIValidator class to validate TURIReference instances against
RFC 3986 structural rules and profile constraints.
--------------------------------------------------------------------------------
*)

interface

uses
  System.SysUtils,
  JsonSchema.Core.URI.Types,
  JsonSchema.Core.URI.Reference;

type
  /// <summary>
  /// Validates a TURIReference against RFC 3986 rules and custom profile constraints.
  /// </summary>
  TURIValidator = class
  private
    FRequiredComponents: TURIComponents;
    FForbiddenComponents: TURIComponents;
  public
    constructor Create; overload;
    constructor Create(const pRequired, pForbidden: TURIComponents); overload;

    /// <summary>Validates the components of a URI reference, raising EValidationError on failure.</summary>
    procedure Validate(const pURI: TURIReference);

    /// <summary>Returns True if the URI reference conforms to the validator rules.</summary>
    function IsValid(const pURI: TURIReference): Boolean;

    /// <summary>Fluent API to configure required components.</summary>
    function Require(const pComponents: TURIComponents): TURIValidator;
    /// <summary>Fluent API to configure forbidden components.</summary>
    function Forbid(const pComponents: TURIComponents): TURIValidator;
  end;

implementation

uses
  System.RegularExpressions;

{ TURIValidator }

constructor TURIValidator.Create;
begin
  inherited Create;
  FRequiredComponents := [];
  FForbiddenComponents := [];
end;

constructor TURIValidator.Create(const pRequired, pForbidden: TURIComponents);
begin
  inherited Create;
  FRequiredComponents := pRequired;
  FForbiddenComponents := pForbidden;
end;

function TURIValidator.Forbid(const pComponents: TURIComponents): TURIValidator;
begin
  FForbiddenComponents := FForbiddenComponents + pComponents;
  Result := Self;
end;

function TURIValidator.IsValid(const pURI: TURIReference): Boolean;
begin
  try
    Validate(pURI);
    Result := True;
  except
    on EValidationError do
      Result := False;
  end;
end;

function TURIValidator.Require(const pComponents: TURIComponents): TURIValidator;
begin
  FRequiredComponents := FRequiredComponents + pComponents;
  Result := Self;
end;

procedure TURIValidator.Validate(const pURI: TURIReference);
var
  lFirstSegment: string;
  lSlashPos: Integer;
  lUnsplitURI: string;
  lI: Integer;
begin
  // --- 1. Validate Required Components ---
  if (uricScheme in FRequiredComponents) and pURI.Scheme.IsEmpty then
    raise EMissingComponentError.Create('Scheme component is required but missing.');

  if (uricAuthority in FRequiredComponents) and pURI.Authority.IsEmpty then
    raise EMissingComponentError.Create('Authority component is required but missing.');

  if (uricUserInfo in FRequiredComponents) and pURI.UserInfo.IsEmpty then
    raise EMissingComponentError.Create('UserInfo sub-component is required but missing.');

  if (uricHost in FRequiredComponents) and pURI.Host.IsEmpty then
    raise EMissingComponentError.Create('Host sub-component is required but missing.');

  if (uricPort in FRequiredComponents) and pURI.Port.IsEmpty then
    raise EMissingComponentError.Create('Port sub-component is required but missing.');

  if (uricPath in FRequiredComponents) and pURI.Path.IsEmpty then
    raise EMissingComponentError.Create('Path component is required but missing.');

  if (uricQuery in FRequiredComponents) and pURI.Query.IsEmpty then
    raise EMissingComponentError.Create('Query component is required but missing.');

  if (uricFragment in FRequiredComponents) and pURI.Fragment.IsEmpty then
    raise EMissingComponentError.Create('Fragment component is required but missing.');

  // --- 2. Validate Forbidden Components ---
  if (uricScheme in FForbiddenComponents) and not pURI.Scheme.IsEmpty then
    raise EValidationError.Create('Scheme component is forbidden but present.');

  if (uricAuthority in FForbiddenComponents) and not pURI.Authority.IsEmpty then
    raise EValidationError.Create('Authority component is forbidden but present.');

  if (uricUserInfo in FForbiddenComponents) and not pURI.UserInfo.IsEmpty then
    raise EValidationError.Create('UserInfo sub-component is forbidden but present.');

  if (uricHost in FForbiddenComponents) and not pURI.Host.IsEmpty then
    raise EValidationError.Create('Host sub-component is forbidden but present.');

  if (uricPort in FForbiddenComponents) and not pURI.Port.IsEmpty then
    raise EValidationError.Create('Port sub-component is forbidden but present.');

  if (uricPath in FForbiddenComponents) and not pURI.Path.IsEmpty then
    raise EValidationError.Create('Path component is forbidden but present.');

  if (uricQuery in FForbiddenComponents) and not pURI.Query.IsEmpty then
    raise EValidationError.Create('Query component is forbidden but present.');

  if (uricFragment in FForbiddenComponents) and not pURI.Fragment.IsEmpty then
    raise EValidationError.Create('Fragment component is forbidden but present.');

  // --- 3. RFC 3986 Structural Validations ---

  // Scheme syntax validation (RFC 3986, Section 3.1)
  if not pURI.Scheme.IsEmpty then
  begin
    if not TRegEx.IsMatch(pURI.Scheme, '^[a-zA-Z][a-zA-Z0-9+\-\.]*$') then
      raise EValidationError.CreateFmt('Invalid scheme syntax: "%s"', [pURI.Scheme]);
  end;

  // Path constraints relative to Authority (RFC 3986, Section 3)
  if not pURI.Authority.IsEmpty then
  begin
    if (not pURI.Path.IsEmpty) and (not pURI.Path.StartsWith('/')) then
      raise EValidationError.Create('If authority is present, path must be empty or begin with a slash ("/").');
  end else
  begin
    // If no authority is present, path cannot begin with "//" (RFC 3986, Section 3)
    if pURI.Path.StartsWith('//') then
      raise EValidationError.Create('If authority is missing, path cannot begin with double slash ("//").');
  end;

  // Relative reference path first segment colon check (RFC 3986, Section 4.2)
  if pURI.Scheme.IsEmpty and (not pURI.Path.IsEmpty) and (not pURI.Path.StartsWith('/')) then
  begin
    lSlashPos := pURI.Path.IndexOf('/');
    if lSlashPos > 0 then
      lFirstSegment := pURI.Path.Substring(0, lSlashPos)
    else
      lFirstSegment := pURI.Path;

    if lFirstSegment.Contains(':') then
      raise EValidationError.Create('First segment of a relative path cannot contain a colon (":").');
  end;

  // Strict character and percent-encoding validation (RFC 3986)
  lUnsplitURI := pURI.Unsplit;
  for lI := 1 to Length(lUnsplitURI) do
  begin
    if not CharInSet(lUnsplitURI[lI], ['A'..'Z', 'a'..'z', '0'..'9', '-', '.', '_', '~', ':', '/', '?', '#', '[',
                                       ']', '@', '!', '$', '&', '''', '(', ')', '*', '+', ',', ';', '=', '%']) then
      raise EValidationError.CreateFmt('Invalid character in URI reference: "%s"', [lUnsplitURI[lI]]);
    
    if lUnsplitURI[lI] = '%' then
    begin
      if (lI + 2 > Length(lUnsplitURI)) or
         not CharInSet(lUnsplitURI[lI+1], ['0'..'9', 'a'..'f', 'A'..'F']) or
         not CharInSet(lUnsplitURI[lI+2], ['0'..'9', 'a'..'f', 'A'..'F']) then
        raise EValidationError.Create('Invalid percent-encoding sequence.');
    end;
  end;
end;

end.
