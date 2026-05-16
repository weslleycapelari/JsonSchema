unit JsonSchema.Registry.Uri.Builder;

interface

uses
  System.Generics.Collections,
  JsonSchema.Registry.Uri;

type
  /// <summary>Classe para constru��o program�tica e fluente de uma TURIReference.</summary>
  /// <remarks>
  ///   Permite a montagem de uma URI parte por parte, garantindo a formata��o correta ao final do processo.
  ///   Refer�ncia RFC 3986: Se��o 5.3 (Component Recomposition).
  /// </remarks>
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
    class function FromURI(const AURI: TURIReference): TURIBuilder;

    function WithScheme(const AValue: string): TURIBuilder;
    function WithCredentials(const AUsername, APassword: string): TURIBuilder;
    function WithHost(const AValue: string): TURIBuilder;
    function WithPort(const AValue: Word): TURIBuilder;
    function WithPath(const AValue: string): TURIBuilder;
    function AppendPath(const AValue: string): TURIBuilder;
    function WithQuery(const AValue: string): TURIBuilder;
    function WithQueryFromPairs(const APairs: TDictionary<string, string>): TURIBuilder;
    function WithFragment(const AValue: string): TURIBuilder;

    /// <summary>Finaliza a constru��o e retorna a TURIReference resultante.</summary>
    function Build: TURIReference;

    /// <summary>Finaliza a constru��o e retorna a string da URI resultante.</summary>
    function Unsplit: string;
  end;

implementation

uses
  System.SysUtils,
  System.NetEncoding,
  JsonSchema.Registry.Types,
  JsonSchema.Registry.Utils;

{ TURIBuilder }

function TURIBuilder.AppendPath(const AValue: string): TURIBuilder;
var
  LBasePath, LAppendPath: string;
begin
  LBasePath   := FPath.TrimRight(['/']);
  LAppendPath := AValue.Trim(['/']);

  if LBasePath.IsEmpty then
    FPath := '/' + LAppendPath
  else
    FPath := LBasePath + '/' + LAppendPath;

  Result := Self;
end;

function TURIBuilder.Build: TURIReference;
var
  LAuthority: string;
  LReference: TURIReference;
  LAuthorityBuilder: TStringBuilder;
begin
  // 1. Monta o componente 'Authority' a partir das suas partes.
  LAuthorityBuilder := TStringBuilder.Create;
  try
    if not FHost.IsEmpty then
    begin
      if not FUserInfo.IsEmpty then
      begin
        LAuthorityBuilder.Append(FUserInfo);
        LAuthorityBuilder.Append('@');
      end;
      // Host j� deve estar no formato correto (ex: [::1] para IPv6 literal).
      LAuthorityBuilder.Append(FHost);
      if not FPort.IsEmpty then
      begin
        LAuthorityBuilder.Append(':');
        LAuthorityBuilder.Append(FPort);
      end;
    end;
    LAuthority := LAuthorityBuilder.ToString;
  finally
    LAuthorityBuilder.Free;
  end;

  // 2. Cria a inst�ncia de TURIReference com os componentes montados.
  // A normaliza��o ocorre dentro do m�todo Normalize da pr�pria TURIReference.
  LReference.Scheme    := Self.FScheme;
  LReference.Authority := LAuthority;
  LReference.Path      := Self.FPath;
  LReference.Query     := Self.FQuery;
  LReference.Fragment  := Self.FFragment;
  LReference.Encoding  := 'utf-8'; // Padr?o

  Result := TURIReference.From(LReference.Unsplit).Normalize;
end;

constructor TURIBuilder.Create;
begin
  // Inicializa todos os campos como strings vazias.
  FScheme   := '';
  FUserInfo := '';
  FHost     := '';
  FPort     := '';
  FPath     := '';
  FQuery    := '';
  FFragment := '';
end;

class function TURIBuilder.FromURI(const AURI: TURIReference): TURIBuilder;
begin
  // Factory method para criar um builder a partir de uma URI existente.
  Result := TURIBuilder.Create;
  Result.FScheme   := AURI.Scheme;
  Result.FUserInfo := AURI.UserInfo;
  Result.FHost     := AURI.Host;
  Result.FPort     := AURI.Port;
  Result.FPath     := AURI.Path;
  Result.FQuery    := AURI.Query;
  Result.FFragment := AURI.Fragment;
end;

function TURIBuilder.Unsplit: string;
begin
  // M�todo de conveni�ncia que constr�i e j� converte para string.
  Result := Self.Build.Unsplit;
end;

function TURIBuilder.WithCredentials(const AUsername, APassword: string): TURIBuilder;
var
  LEncoder: TNetEncoding;
begin
  // Constr�i o subcomponente 'userinfo' com o devido percent-encoding.
  // RFC 3986, Se��o 3.2.1
  LEncoder := TNetEncoding.URL;
  if AUsername.IsEmpty then
    raise ERFC3986Exception.Create('Username cannot be empty in WithCredentials');

  FUserInfo := TURIUtils.EncodingUserInfo(LEncoder.Encode(AUsername));
  if not APassword.IsEmpty then
    FUserInfo := FUserInfo + ':' + TURIUtils.EncodingUserInfo(LEncoder.Encode(APassword));

  Result := Self;
end;

function TURIBuilder.WithFragment(const AValue: string): TURIBuilder;
begin
  FFragment := AValue;
  Result := Self;
end;

function TURIBuilder.WithHost(const AValue: string): TURIBuilder;
begin
  FHost := AValue;
  Result := Self;
end;

function TURIBuilder.WithPath(const AValue: string): TURIBuilder;
begin
  FPath := AValue;
  // Garante que o path comece com '/' se uma autoridade for definida,
  // conforme a l�gica do Build far� a montagem.
  if (FHost <> '') and (not FPath.StartsWith('/')) and (FPath <> '') then
    FPath := '/' + FPath;

  Result := Self;
end;

function TURIBuilder.WithPort(const AValue: Word): TURIBuilder;
begin
  // A porta � armazenada como string. O tipo Word j� garante o range (0-65535).
  FPort := AValue.ToString;
  Result := Self;
end;

function TURIBuilder.WithQuery(const AValue: string): TURIBuilder;
begin
  FQuery := AValue;
  Result := Self;
end;

function TURIBuilder.WithQueryFromPairs(const APairs: TDictionary<string, string>): TURIBuilder;
var
  LBuilder: TStringBuilder;
  LEncoder: TNetEncoding;
  LPair: TPair<string, string>;
  LFirst: Boolean;
begin
  if APairs.Count = 0 then
  begin
    FQuery := '';
    Exit(Self);
  end;

  LBuilder := TStringBuilder.Create;
  LEncoder := TNetEncoding.URL;
  LFirst   := True;
  try
    for LPair in APairs do
    begin
      if not LFirst then
        LBuilder.Append('&');

      LBuilder.Append(LEncoder.Encode(LPair.Key));
      LBuilder.Append('=');
      LBuilder.Append(LEncoder.Encode(LPair.Value));
      LFirst := False;
    end;
    FQuery := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
  Result := Self;
end;

function TURIBuilder.WithScheme(const AValue: string): TURIBuilder;
begin
  FScheme := AValue;
  Result := Self;
end;

end.
