unit JsonSchema.Registry.Uri.Validator;

interface

uses
  System.Classes,
  JsonSchema.Registry.Types,
  JsonSchema.Registry.Uri;

type
  /// <summary>
  ///   Classe para configurar e executar a validação de uma TURIReference.
  /// </summary>
  /// <remarks>
  ///   Permite definir um conjunto de regras (ex: esquemas permitidos,
  ///   componentes obrigatórios) e aplicá-las a uma URI.
  ///   Referência RFC 3986: Seções 3 e 7.
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
    ///   Executa a validação na URI fornecida.
    /// </summary>
    /// <param name="AURI">A instância de TURIReference a ser validada.</param>
    /// <exception cref="EValidationError">Lançada se a URI falhar na validação.</exception>
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
    // Armazena os hosts já normalizados (lowercase) para comparação eficiente.
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
    // Armazena os schemes já normalizados (lowercase) para comparação eficiente.
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
  LMissingComponents: string;
  LUserInfo: string;
begin
  // 1. Validar componentes obrigatórios
  LMissingComponents := '';
  if FRequiredComponents <> [] then
  begin
    for LComponent in FRequiredComponents do
    begin
      case LComponent of
        uricScheme:    if AURI.Scheme = '' then LMissingComponents := LMissingComponents + 'Scheme, ';
        uricAuthority: if AURI.Authority = '' then LMissingComponents := LMissingComponents + 'Authority, ';
        uricUserInfo:  if AURI.UserInfo = '' then LMissingComponents := LMissingComponents + 'UserInfo, ';
        uricHost:      if AURI.Host = '' then LMissingComponents := LMissingComponents + 'Host, ';
        uricPath:      if AURI.Path = '' then LMissingComponents := LMissingComponents + 'Path, ';
        // Query e Fragment podem ser vazios mas presentes ('?'), então a verificação
        // de ausência (nil na lib python) é mais complexa e aqui checamos apenas o conteúdo.
        uricQuery:     if AURI.Query = '' then LMissingComponents := LMissingComponents + 'Query, ';
        uricFragment:  if AURI.Fragment = '' then LMissingComponents := LMissingComponents + 'Fragment, ';
      end;
    end;

    if LMissingComponents <> '' then
    begin
      // Remove a vírgula e o espaço do final
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

  // 4. Validar se a senha é proibida
  if FForbidPassword then
  begin
    LUserInfo := AURI.UserInfo;
    // Se 'userinfo' existe e contém ':' (indicando uma senha), lança a exceção.
    if (LUserInfo <> '') and (LUserInfo.IndexOf(':') > -1) then
    begin
      raise EValidationError.Create('URI contains a password, which is forbidden by the validator.');
    end;
  end;

  // Se todas as validações passaram, o método termina sem exceções.
end;

end.
