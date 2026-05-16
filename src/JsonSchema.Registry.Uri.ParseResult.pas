unit JsonSchema.Registry.Uri.ParseResult;

interface

type
  /// <summary>Representa o resultado de um parse de URI, compat�vel com a fun��o 'urlparse' de outras linguagens.</summary>
  /// <remarks>Oferece uma vis�o mais detalhada dos subcomponentes da autoridade. Refer�ncia RFC 3986: Ap�ndice B.</remarks>
  TURIParseResult = record
    Scheme: string;
    UserInfo: string;
    Host: string;
    Port: Word;
    Path: string;
    Query: string;
    Fragment: string;

    class function From(const AURIString: string; const AEncoding: string = 'utf-8'): TURIParseResult; static;

    /// <summary>Propriedade de compatibilidade para 'netloc'.</summary>
    function Netloc: string;
    /// <summary>Propriedade de compatibilidade para 'hostname'.</summary>
    function Hostname: string;
  end;

implementation

uses
  System.SysUtils,
  JsonSchema.Registry.Uri,
  JsonSchema.Registry.Types,
  JsonSchema.Registry.Utils;

{ TURIParseResult }

class function TURIParseResult.From(const AURIString, AEncoding: string): TURIParseResult;
var
  LURI: TURIReference;
  LPortStr: string;
  LPortInt: Integer;
  LUserInfo, LUsername, LPassword: string;
begin
  // 1. Reutilizamos o parser principal para obter os 5 componentes gen�ricos.
  LURI := TURIReference.From(AURIString, AEncoding);

  // 2. Atribu�mos os componentes que s�o mapeados diretamente.
  Result.Scheme   := LURI.Scheme;
  Result.Path     := LURI.Path;
  Result.Query    := LURI.Query;
  Result.Fragment := LURI.Fragment;

  // 3. Decompomos o componente 'Authority' em suas subpartes usando o helper.
  TURIUtils.ParseAuthority(LURI.Authority, LUserInfo, Result.Host, LPortStr);
  TURIUtils.ParseUserInfo(LUserInfo, LUsername, LPassword);

  if not LUserInfo.IsEmpty then
  begin
    if not LUsername.IsEmpty then
      Result.UserInfo := TURIUtils.EncodingUserInfo(LUsername);

    if not LPassword.IsEmpty then
      Result.UserInfo := Result.UserInfo + ':' + TURIUtils.EncodingUserInfo(LPassword);
  end;

  // 4. Convertemos a string da porta para Word, com valida��o.
  if LPortStr <> '' then
  begin
    // Usamos TryStrToInt para evitar exce��es em casos de formato inv�lido.
    if not TryStrToInt(LPortStr, LPortInt) then
      raise EInvalidAuthority.CreateFmt('Invalid port value in authority component: "%s"', [LPortStr]);

    // Validamos se a porta est� no range v�lido (0-65535).
    if (LPortInt < 0) or (LPortInt > High(Word)) then
      raise EInvalidAuthority.CreateFmt('Port value out of range (0-65535): %d', [LPortInt]);

    Result.Port := Word(LPortInt);
  end
  else
  begin
    // Usamos 0 para indicar que nenhuma porta foi especificada.
    Result.Port := 0;
  end;
end;

function TURIParseResult.Hostname: string;
begin
  Result := Self.Host;
end;

function TURIParseResult.Netloc: string;
var
  LBuilder: TStringBuilder;
begin
  // N�o faz sentido ter uma autoridade sem um host.
  if Self.Host = '' then
    Exit('');

  LBuilder := TStringBuilder.Create;
  try
    if Self.UserInfo <> '' then
    begin
      LBuilder.Append(Self.UserInfo);
      LBuilder.Append('@');
    end;

    LBuilder.Append(Self.Host);

    // Adiciona a porta apenas se ela foi explicitamente definida (maior que 0).
    if Self.Port > 0 then
    begin
      LBuilder.Append(':');
      LBuilder.Append(Self.Port.ToString);
    end;

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

end.
