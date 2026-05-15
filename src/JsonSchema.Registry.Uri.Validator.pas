unit JsonSchema.Registry.Uri.Validator;

interface

uses
  System.Classes,
  JsonSchema.Registry.Types,
  JsonSchema.Registry.Uri;

type
  /// <summary>
  ///   Classe para configurar e executar a valida��o de uma TURIReference.
  /// </summary>
  /// <remarks>
  ///   Permite definir um conjunto de regras (ex: esquemas permitidos,
  ///   componentes obrigat�rios) e aplic�-las a uma URI.
  ///   Refer�ncia RFC 3986: Se��es 3 e 7.
  /// </remarks>
  TURIValidator = class
  private
    FRequiredComponents: TURIComponents;
    FAllowedSchemes: TStrings;
    FAllowedHosts: TStrings;
    FForbidPassword: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function RequirePresenceOf(const AComponents: TURIComponents): TURIValidator;
    function AllowSchemes(const ASchemes: array of string): TURIValidator;
    function AllowHosts(const AHosts: array of string): TURIValidator;
    function ForbidPassword: TURIValidator;

    /// <summary>
    ///   Executa a valida��o na URI fornecida.
    /// </summary>
    /// <param name="AURI">A inst�ncia de TURIReference a ser validada.</param>
    /// <exception cref="EValidationError">Lan�ada se a URI falhar na valida��o.</exception>
    procedure Validate(const AURI: TURIReference);
  end;

implementation

uses
  System.SysUtils;

{ TURIValidator }

function TURIValidator.AllowHosts(const AHosts: array of string): TURIValidator;
var
  LHost: string;
begin
  FAllowedHosts.Clear;
  for LHost in AHosts do
  begin
    // Armazena os hosts j� normalizados (lowercase) para compara��o eficiente.
    FAllowedHosts.Add(LHost.ToLower);
  end;
  Result := Self;
end;

function TURIValidator.AllowSchemes(const ASchemes: array of string): TURIValidator;
var
  LScheme: string;
begin
  FAllowedSchemes.Clear;
  for LScheme in ASchemes do
  begin
    // Armazena os schemes j� normalizados (lowercase) para compara��o eficiente.
    FAllowedSchemes.Add(LScheme.ToLower);
  end;
  Result := Self;
end;

constructor TURIValidator.Create;
begin
  inherited Create;
  FRequiredComponents := [];
  FAllowedSchemes := TStringList.Create;
  FAllowedHosts := TStringList.Create;
  FForbidPassword := False;
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

function TURIValidator.RequirePresenceOf(const AComponents: TURIComponents): TURIValidator;
begin
  FRequiredComponents := FRequiredComponents + AComponents;
  Result := Self;
end;

procedure TURIValidator.Validate(const AURI: TURIReference);
var
  LComponent: TURIComponent;
  LRequiredComponents: TURIComponents;
  LMissingComponents: string;
  LUserInfo: string;
begin
  LRequiredComponents := FRequiredComponents;
  if SameText(AURI.Scheme, 'urn') then
    LRequiredComponents := LRequiredComponents - [uricAuthority];

  // 1. Validar componentes obrigat�rios
  LMissingComponents := '';
  if LRequiredComponents <> [] then
  begin
    for LComponent in LRequiredComponents do
    begin
      case LComponent of
        uricScheme:    if AURI.Scheme = '' then LMissingComponents := LMissingComponents + 'Scheme, ';
        uricAuthority: if AURI.Authority = '' then LMissingComponents := LMissingComponents + 'Authority, ';
        uricUserInfo:  if AURI.UserInfo = '' then LMissingComponents := LMissingComponents + 'UserInfo, ';
        uricHost:      if AURI.Host = '' then LMissingComponents := LMissingComponents + 'Host, ';
        uricPath:      if AURI.Path = '' then LMissingComponents := LMissingComponents + 'Path, ';
        // Query e Fragment podem ser vazios mas presentes ('?'), ent�o a verifica��o
        // de aus�ncia (nil na lib python) � mais complexa e aqui checamos apenas o conte�do.
        uricQuery:     if AURI.Query = '' then LMissingComponents := LMissingComponents + 'Query, ';
        uricFragment:  if AURI.Fragment = '' then LMissingComponents := LMissingComponents + 'Fragment, ';
      end;
    end;

    if LMissingComponents <> '' then
    begin
      // Remove a v�rgula e o espa�o do final
      LMissingComponents := LMissingComponents.Substring(0, LMissingComponents.Length - 2);
      raise EMissingComponentError.CreateFmt(
        'Required URI component(s) are missing: [%s]', [LMissingComponents]);
    end;
  end;

  // 2. Validar schemes permitidos
  if (FAllowedSchemes.Count > 0) and (FAllowedSchemes.IndexOf(AURI.Scheme.ToLower) = -1) then
  begin
    raise EValidationError.CreateFmt(
      'Scheme "%s" is not in the list of allowed schemes.', [AURI.Scheme]);
  end;

  // 3. Validar hosts permitidos
  if (FAllowedHosts.Count > 0) and (FAllowedHosts.IndexOf(AURI.Host.ToLower) = -1) then
  begin
    raise EValidationError.CreateFmt(
      'Host "%s" is not in the list of allowed hosts.', [AURI.Host]);
  end;

  // 4. Validar se a senha � proibida
  if FForbidPassword then
  begin
    LUserInfo := AURI.UserInfo;
    // Se 'userinfo' existe e cont�m ':' (indicando uma senha), lan�a a exce��o.
    if (LUserInfo <> '') and (LUserInfo.IndexOf(':') > -1) then
    begin
      raise EValidationError.Create('URI contains a password, which is forbidden by the validator.');
    end;
  end;

  // Se todas as valida��es passaram, o m�todo termina sem exce��es.
end;

end.
