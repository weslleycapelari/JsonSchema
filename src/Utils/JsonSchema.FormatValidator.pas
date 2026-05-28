unit JsonSchema.FormatValidator;

interface

uses
  System.JSON,
  System.RegularExpressions;

type
  /// <summary>
  ///   Valida valores string contra as assertions de formato do JSON Schema
  ///   (ipv4, ipv6, date-time, email, uri, json-pointer, uuid, etc.).
  /// </summary>
  /// <remarks>
  ///   Todos os métodos são estáticos e thread-safe. A classe não possui estado
  ///   e não precisa ser instanciada.
  ///
  ///   Os formatos seguem as RFCs referenciadas pelo JSON Schema Draft 2020-12.
  ///   Validações de IDN (Internationalized Domain Names) são simplificadas
  ///   e não realizam lookup DNS nem validação IDNA completa.
  /// </remarks>
  TFormatValidator = class
  strict private
    /// <summary>
    ///   Verifica se um segundo de salto (second = 60) é válido para o horário
    ///   e fuso horário fornecidos. Segundos de salto só ocorrem às 23:59 UTC.
    /// </summary>
    /// <param name="pTimezone">
    ///   String de timezone: <c>'Z'</c>, <c>'z'</c> ou <c>'+HH:MM'</c>/<c>'-HH:MM'</c>.
    /// </param>
    /// <param name="pHour">Hora local (0–23) do instante com segundo de salto.</param>
    /// <param name="pMinute">Minuto local (0–59) do instante com segundo de salto.</param>
    class function ValidateLeapSecond(const pTimezone: string; const pHour, pMinute: Integer): Boolean; static;

    /// <summary>
    ///   Valida um array de hextets IPv6 (cada um deve ser 1–4 dígitos hexadecimais)
    ///   e conta quantos hextets válidos foram encontrados.
    ///   Retorna <c>False</c> e interrompe na primeira entrada inválida.
    /// </summary>
    /// <param name="pParts">Array de strings candidatas a hextet.</param>
    /// <param name="pCount">Número de hextets válidos encontrados (parâmetro de saída).</param>
    class function ValidateHextets(const pParts: TArray<string>; out pCount: Integer): Boolean; static;
  public
    /// <summary>Valida um endereço IPv4 (ex.: <c>'192.168.0.1'</c>).</summary>
    class function IsIPv4(const pValue: string): Boolean; static;

    /// <summary>
    ///   Valida um endereço IPv6 (ex.: <c>'2001:db8::1'</c>).
    ///   Suporta compressão <c>'::'</c>, endereços mistos IPv4-em-IPv6
    ///   e a representação canônica completa com 8 hextets.
    /// </summary>
    class function IsIPv6(const pValue: string): Boolean; static;

    /// <summary>Valida um hostname RFC 1123 (ASCII, sem Unicode).</summary>
    class function IsHostname(const pValue: string): Boolean; static;

    /// <summary>Valida um hostname internacionalizado (IDN, RFC 5890, simplificado).</summary>
    class function IsIDNHostname(const pValue: string): Boolean; static;

    /// <summary>
    ///   Valida uma string date-time per RFC 3339 (ex.: <c>'2024-01-15T14:30:00Z'</c>).
    ///   Valida calendário (incluindo anos bissextos) e segundos de salto.
    /// </summary>
    class function IsDateTime(const pValue: string): Boolean; static;

    /// <summary>
    ///   Valida uma string de data (ex.: <c>'2024-01-15'</c>).
    ///   Valida o calendário gregoriano, incluindo anos bissextos.
    /// </summary>
    class function IsDate(const pValue: string): Boolean; static;

    /// <summary>
    ///   Valida uma string de hora com timezone obrigatório
    ///   (ex.: <c>'14:30:00Z'</c> ou <c>'14:30:60+05:30'</c>).
    ///   Valida segundos de salto verificando a equivalência UTC a 23:59.
    /// </summary>
    class function IsTime(const pValue: string): Boolean; static;

    /// <summary>Valida uma duração ISO 8601 (ex.: <c>'P3Y6M4DT12H30M5S'</c> ou <c>'P4W'</c>).</summary>
    class function IsDuration(const pValue: string): Boolean; static;

    /// <summary>Valida um endereço de e-mail (RFC 5322, forma simplificada).</summary>
    class function IsEmail(const pValue: string): Boolean; static;

    /// <summary>Valida um endereço de e-mail internacionalizado (IDN, Unicode).</summary>
    class function IsIDNEmail(const pValue: string): Boolean; static;

    /// <summary>Valida uma URI absoluta com scheme (delega para TURIUtils).</summary>
    class function IsURI(const pValue: string): Boolean; static;

    /// <summary>Valida uma URI-reference (absoluta ou relativa, delega para TURIUtils).</summary>
    class function IsURIReference(const pValue: string): Boolean; static;

    /// <summary>Valida uma IRI (URI internacionalizada, RFC 3987, verificação simplificada).</summary>
    class function IsIRI(const pValue: string): Boolean; static;

    /// <summary>
    ///   Valida uma IRI-reference (IRI ou referência relativa).
    ///   String vazia é considerada válida (representa referência nula).
    /// </summary>
    class function IsIRIReference(const pValue: string): Boolean; static;

    /// <summary>Valida um URI Template (RFC 6570, verificação simplificada de scheme).</summary>
    class function IsURITemplate(const pValue: string): Boolean; static;

    /// <summary>Valida um JSON Pointer (RFC 6901, delega para TURIUtils).</summary>
    class function IsJSONPointer(const pValue: string): Boolean; static;

    /// <summary>
    ///   Valida um Relative JSON Pointer (draft-handrews-relative-json-pointer):
    ///   inteiro não-negativo seguido de <c>'#'</c> ou um JSON Pointer.
    /// </summary>
    class function IsRelativeJSONPointer(const pValue: string): Boolean; static;

    /// <summary>Valida um UUID (RFC 4122, formato com hífens).</summary>
    class function IsUUID(const pValue: string): Boolean; static;

    /// <summary>
    ///   Verifica se a string é uma expressão regular sintaticamente válida,
    ///   tentando compilá-la. Retorna <c>False</c> se <c>TRegEx</c> lançar exceção.
    /// </summary>
    class function IsRegex(const pValue: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.DateUtils,
  JsonSchema.Registry.Utils,
  JsonSchema.Common.Utils;

{ TFormatValidator }

class function TFormatValidator.ValidateLeapSecond(const pTimezone: string; const pHour, pMinute: Integer): Boolean;
var
  lOffsetHour: Integer;
  lOffsetMinute: Integer;
  lOffsetTotal: Integer;
  lUtcTotal: Integer;
  lUtcHour: Integer;
  lUtcMinute: Integer;
  lOffsetSign: Char;
begin
  // Timezone 'Z' ou 'z': hora local já é UTC
  if SameText(pTimezone, 'Z') then
    Exit((pHour = 23) and (pMinute = 59));

  lOffsetSign := pTimezone[1];

  if not TryStrToInt(Copy(pTimezone, 2, 2), lOffsetHour) or
    not TryStrToInt(Copy(pTimezone, 5, 2), lOffsetMinute) then
  begin
    Exit(False);
  end;

  if (lOffsetHour > 23) or (lOffsetMinute > 59) then
    Exit(False);

  // Converte a hora local para UTC e verifica se é 23:59
  lOffsetTotal := (lOffsetHour * 60) + lOffsetMinute;
  lUtcTotal := (pHour * 60) + pMinute;

  if lOffsetSign = '+' then
    lUtcTotal := lUtcTotal - lOffsetTotal
  else
    lUtcTotal := lUtcTotal + lOffsetTotal;

  // Normaliza para o intervalo [0, 1440) minutos/dia
  lUtcTotal := ((lUtcTotal mod 1440) + 1440) mod 1440;
  lUtcHour := lUtcTotal div 60;
  lUtcMinute := lUtcTotal mod 60;
  Result := (lUtcHour = 23) and (lUtcMinute = 59);
end;

class function TFormatValidator.ValidateHextets(const pParts: TArray<string>; out pCount: Integer): Boolean;
const
  HEXTET_PATTERN = '^[0-9A-Fa-f]{1,4}$';
var
  lIndex: Integer;
  lPart: string;
begin
  pCount := 0;
  lIndex := 0;
  Result := True;

  while Result and (lIndex < Length(pParts)) do
  begin
    lPart := pParts[lIndex];
    Result := not lPart.IsEmpty and TRegEx.IsMatch(lPart, HEXTET_PATTERN, [roCompiled]);

    if Result then
      Inc(pCount);

    Inc(lIndex);
  end;
end;

class function TFormatValidator.IsIPv4(const pValue: string): Boolean;
const
  DIGITS_ONLY_PATTERN = '^\d+$';
var
  lParts: TArray<string>;
  lPart: string;
  lNumber: Integer;
  lIndex: Integer;
begin
  lParts := pValue.Split(['.']);

  if Length(lParts) <> 4 then
    Exit(False);

  lIndex := 0;
  Result := True;

  while Result and (lIndex < 4) do
  begin
    lPart := lParts[lIndex];

    if lPart.IsEmpty or not TRegEx.IsMatch(lPart, DIGITS_ONLY_PATTERN, [roCompiled]) then
      Result := False
    else if (lPart.Length > 1) and (lPart[1] = '0') then
      // Zeros à esquerda não são permitidos (ex.: '01' é inválido)
      Result := False
    else if not TryStrToInt(lPart, lNumber) or (lNumber < 0) or (lNumber > 255) then
      Result := False;

    Inc(lIndex);
  end;
end;

class function TFormatValidator.IsIPv6(const pValue: string): Boolean;
var
  lWorkValue: string;
  lExpectedHextets: Integer;
  lHasCompression: Boolean;
  lLeftParts: TArray<string>;
  lRightParts: TArray<string>;
  lFullParts: TArray<string>;
  lSplitPos: Integer;
  lLastColon: Integer;
  lIPv4Tail: string;
  lLeftStr: string;
  lRightStr: string;
  lLeftCount: Integer;
  lRightCount: Integer;
  lFullCount: Integer;
  lLeftValid: Boolean;
  lRightValid: Boolean;
begin
  if pValue.IsEmpty then
    Exit(False);

  lWorkValue := pValue;
  lExpectedHextets := 8;

  // Trata endereços IPv4-em-IPv6 (ex.: '::ffff:192.168.1.1')
  if Pos('.', lWorkValue) > 0 then
  begin
    lLastColon := LastDelimiter(':', lWorkValue);

    if lLastColon = 0 then
      Exit(False);

    lIPv4Tail := Copy(lWorkValue, lLastColon + 1, MaxInt);

    if not IsIPv4(lIPv4Tail) then
      Exit(False);

    // Com IPv4 embutido, espera-se apenas 6 hextets na parte IPv6
    lExpectedHextets := 6;

    // Preserva a barra dupla '::' antes do IPv4 se houver
    if (lLastColon > 1) and (lWorkValue[lLastColon - 1] = ':') then
      lWorkValue := Copy(lWorkValue, 1, lLastColon)
    else
      lWorkValue := Copy(lWorkValue, 1, lLastColon - 1);
  end;

  // Três dois-pontos consecutivos nunca são válidos
  if Pos(':::', lWorkValue) > 0 then
    Exit(False);

  lHasCompression := Pos('::', lWorkValue) > 0;

  if lHasCompression then
  begin
    // Apenas um '::' é permitido por endereço
    if PosEx('::', lWorkValue, Pos('::', lWorkValue) + 2) > 0 then
      Exit(False);

    lSplitPos := Pos('::', lWorkValue);

    // Extrai a parte esquerda e direita do '::'; strings vazias resultam em
    // arrays de zero elementos para que ValidateHextets não rejeite o caso '::' (all-zeros)
    lLeftStr := Copy(lWorkValue, 1, lSplitPos - 1);
    lRightStr := Copy(lWorkValue, lSplitPos + 2, MaxInt);

    if lLeftStr.IsEmpty then
      lLeftParts := []
    else
      lLeftParts := lLeftStr.Split([':']);

    if lRightStr.IsEmpty then
      lRightParts := []
    else
      lRightParts := lRightStr.Split([':']);

    lLeftValid := ValidateHextets(lLeftParts, lLeftCount);
    lRightValid := ValidateHextets(lRightParts, lRightCount);

    // Ambas as partes devem ser válidas e o total deve ser inferior ao esperado
    // (a compressão '::' representa os hextets ausentes como zeros)
    Result := lLeftValid and lRightValid and
              ((lLeftCount + lRightCount) < lExpectedHextets);
  end else
  begin
    lFullParts := lWorkValue.Split([':']);

    // Sem compressão, o número exato de hextets é obrigatório
    if Length(lFullParts) <> lExpectedHextets then
      Exit(False);

    Result := ValidateHextets(lFullParts, lFullCount) and
              (lFullCount = lExpectedHextets);
  end;
end;

class function TFormatValidator.IsDateTime(const pValue: string): Boolean;
const
  DATETIME_PATTERN =
    '^(\d{4})-(\d{2})-(\d{2})[Tt](\d{2}):(\d{2}):(\d{2})' +
    '(?:\.\d+)?([Zz]|[+\-]\d{2}:\d{2})$';
var
  lMatch: TMatch;
  lYear: Integer;
  lMonth: Integer;
  lDay: Integer;
  lHour: Integer;
  lMinute: Integer;
  lSecond: Integer;
  lDateTime: TDateTime;
begin
  lMatch := TRegEx.Match(pValue, DATETIME_PATTERN, [roCompiled]);

  if not lMatch.Success then
    Exit(False);

  if not (TryStrToInt(lMatch.Groups[1].Value, lYear) and
          TryStrToInt(lMatch.Groups[2].Value, lMonth) and
          TryStrToInt(lMatch.Groups[3].Value, lDay) and
          TryStrToInt(lMatch.Groups[4].Value, lHour) and
          TryStrToInt(lMatch.Groups[5].Value, lMinute) and
          TryStrToInt(lMatch.Groups[6].Value, lSecond)) then
  begin
    Exit(False);
  end;

  if not TryEncodeDate(Word(lYear), Word(lMonth), Word(lDay), lDateTime) then
    Exit(False);

  if (lHour > 23) or (lMinute > 59) or (lSecond > 60) then
    Exit(False);

  // Segundo 60 só é válido como segundo de salto às 23:59 UTC
  if lSecond = 60 then
    Result := ValidateLeapSecond(lMatch.Groups[7].Value, lHour, lMinute)
  else
    Result := True;
end;

class function TFormatValidator.IsDate(const pValue: string): Boolean;
const
  DATE_PATTERN = '^([0-9]{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$';
var
  lMatch: TMatch;
  lYear: Integer;
  lMonth: Integer;
  lDay: Integer;
  lDateTime: TDateTime;
begin
  lMatch := TRegEx.Match(pValue, DATE_PATTERN, [roCompiled]);

  if not lMatch.Success then
    Exit(False);

  if not (TryStrToInt(lMatch.Groups[1].Value, lYear) and
          TryStrToInt(lMatch.Groups[2].Value, lMonth) and
          TryStrToInt(lMatch.Groups[3].Value, lDay)) then
  begin
    Exit(False);
  end;

  // TryEncodeDate valida calendário gregoriano (ex.: rejeita 29/02 em anos não-bissextos)
  Result := TryEncodeDate(Word(lYear), Word(lMonth), Word(lDay), lDateTime);
end;

class function TFormatValidator.IsTime(const pValue: string): Boolean;
const
  TIME_PATTERN =
    '^([01][0-9]|2[0-3]):([0-5][0-9]):((?:[0-5][0-9]|60))' +
    '(?:\.[0-9]+)?([Zz]|[+\-]([01][0-9]|2[0-3]):([0-5][0-9]))$';
var
  lMatch: TMatch;
  lHour: Integer;
  lMinute: Integer;
  lSecond: Integer;
begin
  lMatch := TRegEx.Match(pValue, TIME_PATTERN, [roCompiled]);

  if not lMatch.Success then
    Exit(False);

  if not (TryStrToInt(lMatch.Groups[1].Value, lHour) and
          TryStrToInt(lMatch.Groups[2].Value, lMinute) and
          TryStrToInt(lMatch.Groups[3].Value, lSecond)) then
  begin
    Exit(False);
  end;

  if (lHour > 23) or (lMinute > 59) or (lSecond > 60) then
    Exit(False);

  // Segundo 60 só é válido como segundo de salto às 23:59 UTC.
  // Usa ValidateLeapSecond compartilhado com IsDateTime (elimina duplicação).
  if lSecond = 60 then
    Result := ValidateLeapSecond(lMatch.Groups[4].Value, lHour, lMinute)
  else
    Result := True;
end;

class function TFormatValidator.IsDuration(const pValue: string): Boolean;
const
  // ISO 8601: PnYnMnDTnHnMnS ou PnW (semanas não se combinam com outros componentes)
  DURATION_PATTERN =
    '^P(?!$)((\d+Y)?(\d+M)?(\d+D)?(T(?=\d)(\d+H)?(\d+M)?(\d+S)?)?|(\d+W))$';
begin
  Result := TRegEx.IsMatch(pValue, DURATION_PATTERN, [roCompiled]);
end;

class function TFormatValidator.IsEmail(const pValue: string): Boolean;
const
  // RFC 5322 simplificado: local-part@domain
  EMAIL_PATTERN =
    '^[A-Za-z0-9!#$%&''*+/=?^_`{|}~-]+' +
    '(?:\.[A-Za-z0-9!#$%&''*+/=?^_`{|}~-]+)*' +
    '@(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-))' +
    '(?:\.(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-)))*$';
begin
  Result := TRegEx.IsMatch(pValue, EMAIL_PATTERN, [roCompiled]);
end;

class function TFormatValidator.IsIDNEmail(const pValue: string): Boolean;
const
  // IDN Email: aceita letras Unicode no local-part e no domínio
  IDN_EMAIL_PATTERN =
    '^[^\s@]+@(?=.{1,253}$)' +
    '(?:(?!-)[\p{L}\p{N}-]{1,63}(?<!-))' +
    '(?:\.(?:(?!-)[\p{L}\p{N}-]{1,63}(?<!-)))*$';
begin
  Result := TRegEx.IsMatch(pValue, IDN_EMAIL_PATTERN, [roCompiled]);
end;

class function TFormatValidator.IsIDNHostname(const pValue: string): Boolean;
var
  lWorkValue: string;
  lLabels: TArray<string>;
  lLabel: string;
  lIndex: Integer;
  lCodePoint: Integer;
  lIsValid: Boolean;
begin
  // Normaliza separadores de domínio Unicode alternativos para '.' ASCII
  lWorkValue := pValue;

  for lIndex := 1 to Length(lWorkValue) do
  begin
    lCodePoint := Ord(lWorkValue[lIndex]);

    if (lCodePoint = $3002) or (lCodePoint = $FF0E) or (lCodePoint = $FF61) then
      lWorkValue[lIndex] := '.';
  end;

  if lWorkValue.IsEmpty or (lWorkValue.Length > 253) then
    Exit(False);

  // Caracteres de controle e espaços são sempre inválidos em hostnames
  if TRegEx.IsMatch(lWorkValue, '[\x00-\x1F\x7F\s]', [roCompiled]) then
    Exit(False);

  if (lWorkValue[1] = '.') or (lWorkValue[lWorkValue.Length] = '.') then
    Exit(False);

  if Pos('..', lWorkValue) > 0 then
    Exit(False);

  lLabels := lWorkValue.Split(['.']);
  lIndex := 0;
  lIsValid := True;

  while lIsValid and (lIndex < Length(lLabels)) do
  begin
    lLabel := lLabels[lIndex];
    lIsValid := not lLabel.IsEmpty and (lLabel.Length <= 63);

    if lIsValid then
      lIsValid := (lLabel[1] <> '-') and (lLabel[lLabel.Length] <> '-');

    // Rótulos ACE (Punycode 'xn--') exigem conteúdo válido após o prefixo
    if lIsValid and lLabel.StartsWith('xn--') then
      lIsValid := (lLabel.Length > 4) and
                  TRegEx.IsMatch(lLabel.Substring(4), '^[a-z0-9-]+$', [roCompiled]);

    Inc(lIndex);
  end;

  Result := lIsValid;
end;

class function TFormatValidator.IsHostname(const pValue: string): Boolean;
const
  HOSTNAME_PATTERN =
    '^(?=.{1,253}$)(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-))' +
    '(?:\.(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-)))*$';
begin
  Result := TRegEx.IsMatch(pValue, HOSTNAME_PATTERN, [roCompiled]);
end;

class function TFormatValidator.IsURI(const pValue: string): Boolean;
begin
  Result := TURIUtils.IsValidURI(pValue);
end;

class function TFormatValidator.IsURIReference(const pValue: string): Boolean;
begin
  Result := TURIUtils.IsValidURIReference(pValue);
end;

class function TFormatValidator.IsIRI(const pValue: string): Boolean;
const
  // IRI: scheme obrigatório + path sem caracteres proibidos
  IRI_SCHEME_PATTERN = '^[A-Za-z][A-Za-z0-9+.-]*:[^\s<>"{}|\^`\\]*$';
  IRI_CHARS_PATTERN = '^[^\x00-\x1F\x7F<>"{}|\\^`]+$';
begin
  Result := TRegEx.IsMatch(pValue, IRI_SCHEME_PATTERN, [roCompiled]) and
            TRegEx.IsMatch(pValue, IRI_CHARS_PATTERN, [roCompiled]);
end;

class function TFormatValidator.IsIRIReference(const pValue: string): Boolean;
const
  // IRI-reference permite caminho relativo e fragmentos; string vazia é válida
  IRI_REFERENCE_PATTERN = '^[^\x00-\x1F\x7F<>"{}|\\^`]*$';
begin
  if pValue.IsEmpty then
    Exit(True);

  Result := TRegEx.IsMatch(pValue, IRI_REFERENCE_PATTERN, [roCompiled]);
end;

class function TFormatValidator.IsURITemplate(const pValue: string): Boolean;
const
  // RFC 6570: scheme + path (verificação simplificada)
  URI_TEMPLATE_PATTERN = '^[A-Za-z][A-Za-z0-9+.-]*:[^\s]*$';
begin
  Result := TRegEx.IsMatch(pValue, URI_TEMPLATE_PATTERN, [roCompiled]);
end;

class function TFormatValidator.IsJSONPointer(const pValue: string): Boolean;
begin
  Result := TURIUtils.IsValidJsonPointer(pValue);
end;

class function TFormatValidator.IsRelativeJSONPointer(const pValue: string): Boolean;
const
  // Inteiro não-negativo seguido de '#' (índice de chave/item) ou JSON Pointer
  RELATIVE_POINTER_PATTERN = '^(0|[1-9][0-9]*)(#|(/([^~/]|~[01])*)*)$';
begin
  Result := TRegEx.IsMatch(pValue, RELATIVE_POINTER_PATTERN, [roCompiled]);
end;

class function TFormatValidator.IsUUID(const pValue: string): Boolean;
const
  UUID_PATTERN =
    '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}' +
    '-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';
begin
  Result := TRegEx.IsMatch(pValue, UUID_PATTERN, [roCompiled]);
end;

class function TFormatValidator.IsRegex(const pValue: string): Boolean;
begin
  // A única forma prática de validar sintaxe de regex é tentar compilá-la
  try
    TRegEx.IsMatch('', pValue);
    Result := True;
  except
    Result := False;
  end;
end;

end.
