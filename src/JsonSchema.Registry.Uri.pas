unit JsonSchema.Registry.Uri;

interface

type
  /// <summary>Representa de forma imut�vel os cinco componentes principais de uma URI, conforme a RFC 3986.</summary>
  /// <remarks>
  ///   Esta � a estrutura central da biblioteca. Uma vez criada, uma inst�ncia de TURIReference n�o pode ser alterada.
  ///   M�todos como Normalize e ResolveWith retornam novas inst�ncias. Refer�ncia RFC 3986: Se��o 3.
  /// </remarks>
  TURIReference = record
  private
    FScheme: string;
    FAuthority: string;
    FPath: string;
    FQuery: string;
    FFragment: string;
    FEncoding: string;

  public
    /// <summary>Cria uma nova inst�ncia de TURIReference a partir de uma string.</summary>
    /// <param name="AURIString">A string da URI a ser parseada.</param>
    /// <param name="AEncoding">A codifica��o da string (padr�o 'utf-8').</param>
    /// <returns>Uma inst�ncia de TURIReference preenchida.</returns>
    class function From(const pURIString: string; const pEncoding: string = 'utf-8'): TURIReference; static;

    /// <summary>Recomp�e os componentes da URI em uma �nica string.</summary>
    /// <returns>A string completa da URI.</returns>
    /// <remarks>Refer�ncia RFC 3986: Se��o 5.3.</remarks>
    function Unsplit: string;

    /// <summary>Verifica se a refer�ncia � uma URI absoluta.</summary>
    /// <returns>True se a URI possui um scheme e n�o possui fragmento.</returns>
    /// <remarks>Refer�ncia RFC 3986: Se��o 4.3.</remarks>
    function IsAbsolute: Boolean;

    /// <summary>Aplica o algoritmo de normaliza��o na URI.</summary>
    /// <returns>Uma nova inst�ncia de TURIReference normalizada.</returns>
    /// <remarks>Refer�ncia RFC 3986: Se��o 6.</remarks>
    function Normalize: TURIReference;

    /// <summary>Resolve esta URI (potencialmente relativa) contra uma URI base.</summary>
    /// <param name="ABaseURI">A URI base absoluta para a resolu��o.</param>
    /// <returns>Uma nova inst�ncia de TURIReference representando a URI resolvida.</returns>
    /// <remarks>Refer�ncia RFC 3986: Se��o 5.2.</remarks>
    function ResolveWith(const pBaseURI: TURIReference): TURIReference;

    /// <summary>Cria uma c�pia desta refer�ncia, substituindo os componentes especificados.</summary>
    function CopyWith(const pScheme, pAuthority, pPath, pQuery, pFragment: string): TURIReference;

    /// <summary>Indica se esta URI e a parametrizada possui a mesma origem</summary>
    function IsSameOrigin(const pURI: TURIReference): Boolean;

    class operator Equal(const pA, pB: TURIReference): Boolean;
    class operator NotEqual(const pA, pB: TURIReference): Boolean;

    class function New(const pURIString: string): TURIReference; static;

    /// <summary>O componente 'scheme' da URI (ex: 'http', 'ftp').</summary>
    property Scheme: string read FScheme write FScheme;
    /// <summary>O componente 'authority' (ex: 'user@example.com:8080').</summary>
    property Authority: string read FAuthority write FAuthority;
    /// <summary>O componente 'path' (ex: '/path/to/resource').</summary>
    property Path: string read FPath write FPath;
    /// <summary>O componente 'query' (ex: 'key=value').</summary>
    property Query: string read FQuery write FQuery;
    /// <summary>O componente 'fragment' (ex: 'section1').</summary>
    property Fragment: string read FFragment write FFragment;
    property Encoding: string read FEncoding write FEncoding;

    { Sub-component properties }
    /// <summary>O subcomponente 'userinfo' da autoridade.</summary>
    function UserInfo: string;
    /// <summary>O subcomponente 'host' da autoridade.</summary>
    function Host: string;
    /// <summary>O subcomponente 'port' da autoridade.</summary>
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
  Result.FScheme := pScheme;
  Result.FAuthority := pAuthority;
  Result.FPath := pPath;
  Result.FQuery := pQuery;
  Result.FFragment := pFragment;
  Result.FEncoding := Self.FEncoding;
end;

class operator TURIReference.Equal(const pA, pB: TURIReference): Boolean;
var
  NormA, NormB: TURIReference;
begin
  // Compara��o simples
  Result := (pA.FScheme = pB.FScheme) and
            (pA.FAuthority = pB.FAuthority) and
            (pA.FPath = pB.FPath) and
            (pA.FQuery = pB.FQuery) and
            (pA.FFragment = pB.FFragment);

  if Result then
    Exit;

  // Compara��o normalizada (RFC 6.2.2)
  NormA := pA.Normalize;
  NormB := pB.Normalize;
  Result := (NormA.FScheme = NormB.FScheme) and
            (NormA.FAuthority = NormB.FAuthority) and
            (NormA.FPath = NormB.FPath) and
            (NormA.FQuery = NormB.FQuery) and
            (NormA.FFragment = NormB.FFragment);
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
  // Conforme RFC 3986, Se��o 4.3, uma URI absoluta tem um 'scheme' e n�o tem 'fragment'.
  Result := (FScheme <> '') and (FFragment = '');
end;

function TURIReference.IsSameOrigin(const pURI: TURIReference): Boolean;
var
  NormA, NormB: TURIReference;
begin
  // Compara��o simples
  Result := (Self.FScheme = pURI.FScheme) and
            (Self.FAuthority = pURI.FAuthority){ and
            (Self.FPath = pURI.FPath)};

  if Result then
    Exit;

  // Compara��o normalizada (RFC 6.2.2)
  NormA := Self.Normalize;
  NormB := pURI.Normalize;
  Result := (NormA.FScheme = NormB.FScheme) and
            (NormA.FAuthority = NormB.FAuthority){ and
            (NormA.FPath = NormB.FPath)};
end;

class function TURIReference.New(const pURIString: string): TURIReference;
begin
  // Delega a chamada diretamente para o m�todo 'From' do record TURIReference.
  Result := TURIReference.From(pURIString);
end;

function TURIReference.Normalize: TURIReference;
var
  lUserInfo, lHost, lPort, lUsername, lPassword: string;
  lAuthorityBuilder: TStringBuilder;
begin
  // 1. Normaliza o Scheme (lowercase)
  Result.FScheme := TURIUtils.NormalizeScheme(Self.FScheme);

  // 2. Decomp�e, normaliza e reconstr�i a Authority
  if Self.FAuthority <> '' then
  begin
    // 2a. Decomp�e a autoridade em suas partes
    TURIUtils.ParseAuthority(Self.FAuthority, lUserInfo, lHost, lPort);
    TURIUtils.ParseUserInfo(lUserInfo, lUsername, lPassword);

    // 2b. Normaliza cada subcomponente individualmente
    lHost := lHost.ToLower;
    // A porta (lPort) n�o possui normaliza��o de sintaxe (apenas de esquema, como remover a porta 80 para http)

    // 2c. Reconstr�i a string da autoridade a partir das partes normalizadas
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
  begin
    Result.FAuthority := '';
  end;

  // 3. Normaliza os demais componentes
  Result.FPath     := TURIUtils.NormalizePercentEncoding(TURIUtils.RemoveDotSegments(Self.FPath));
  Result.FQuery    := TURIUtils.NormalizePercentEncoding(Self.FQuery);
  Result.FFragment := TURIUtils.NormalizePercentEncoding(Self.FFragment);

  // 4. Mant�m a codifica��o
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
  // Implementa��o do algoritmo da RFC 3986, Se��o 5.2.2.
  //if not pBaseURI.IsAbsolute then
  //  raise EResolutionError.Create('Base URI must be an absolute URI.');

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
          var LMergedPath: string;
          if (pBaseURI.FAuthority <> '') and (pBaseURI.FPath = '') then
            LMergedPath := '/' + Self.FPath
          else
            LMergedPath := TURIUtils.MergePaths(pBaseURI.FPath, Self.FPath);
          Result.FPath := TURIUtils.RemoveDotSegments(LMergedPath);
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
  LBuilder: TStringBuilder;
begin
  LBuilder := TStringBuilder.Create;
  try
    if FScheme <> '' then
    begin
      LBuilder.Append(FScheme);
      LBuilder.Append(':');
    end;

    if FAuthority <> '' then
    begin
      LBuilder.Append('//');
      LBuilder.Append(FAuthority);
    end;

    LBuilder.Append(FPath);

    // Nota: Esta implementa��o simplificada n�o distingue um componente
    // ausente de um componente vazio (ex: a diferen�a entre "a.com" e "a.com?").
    // O parser (From) j� armazena '' para ambos os casos.
    if FQuery <> '' then
    begin
      LBuilder.Append('?');
      LBuilder.Append(FQuery);
    end;

    if FFragment <> '' then
    begin
      LBuilder.Append('#');
      LBuilder.Append(FFragment);
    end;

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
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
