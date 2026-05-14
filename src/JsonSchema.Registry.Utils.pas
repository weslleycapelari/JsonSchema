unit JsonSchema.Registry.Utils;

interface

uses
  System.JSON;

type
  TURIUtils = class
    /// <summary>
    ///   Fun��o de conveni�ncia para parsear uma string em uma TURIReference.
    /// </summary>
    //function URIReference(const AURIString: string): TURIReference;

    /// <summary>Fun��o de conveni�ncia para normalizar uma URI.</summary>
    /// <returns>A string da URI normalizada.</returns>
    class function NormalizeURI(const AURIString: string): string; static;

    /// <summary>Fun��o de conveni�ncia para validar uma URI de forma r�pida.</summary>
    /// <remarks>Realiza uma valida��o gen�rica de sintaxe. Para regras customizadas, utilize a classe TValidator.</remarks>
    class function IsValidURI(const AURIString: string): Boolean; static;

    /// <summary>
    ///   Fun��o de conveni�ncia para parsear uma URI no formato TParseResult.
    /// </summary>
    /// <remarks>
    ///   An�loga � fun��o 'urlparse' da biblioteca padr�o do Python.
    /// </remarks>
    //function URIParse(const AURIString: string): TParseResult;

    /// <summary>Junta o path de uma URI base com um path relativo. RFC 3986, Se��o 5.2.3.</summary>
    class function MergePaths(const ABasePath, ARelativePath: string): string; static;

    class procedure ParseAuthority(const AAuthority: string; out AUserInfo, AHost, APort: string); static;

    class procedure ParseUserInfo(const AUserInfo: string; out AUsername, APassword: string); static;

    /// <summary>Remove os segmentos '.' e '..'. RFC 3986, Se��o 5.2.4.</summary>
    class function RemoveDotSegments(const APath: string): string; static;

    /// <summary>Normaliza os caracteres de percent-encoding para uppercase. RFC 3986, Se��o 6.2.2.2.</summary>
    class function NormalizePercentEncoding(const AValue: string): string; static;

    /// <summary>Normaliza o scheme para lowercase. RFC 3986, Se��o 6.2.2.1.</summary>
    class function NormalizeScheme(const AScheme: string): string; static;

    class function Encoding(const AValue, ACustomUnreserved: string): string; static;

    /// <summary>
    ///   Codifica uma string para ser usada no userinfo (username ou password), seguindo as regras da RFC 3986, Se��o 3.2.1.
    /// </summary>
    /// <remarks>Caracteres permitidos s�o: unreserved / sub-delims / ":" Todos os outros, incluindo '@', devem ser codificados.</remarks>
    class function EncodingUserInfo(const AValue: string): string; static;

    class function EvaluateJsonPointer(const ARootNode: TJSONValue; const APointer: string): TJSONValue; static;
    class function IsValidJsonPointer(const APointer: string): Boolean; static;
    class function IsValidURIReference(const AURIString: string): Boolean; static;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  System.StrUtils,
  System.Character,
  System.Generics.Collections,
  JsonSchema.Registry.Uri,
  JsonSchema.Registry.Types,
  JsonSchema.Registry.Uri.Validator;

{ TURIUtils }

class function TURIUtils.Encoding(const AValue, ACustomUnreserved: string): string;
const
  UNRESERVED_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
var
  LHex: string;
  LByte: Integer;
  LCount: Integer;
  LBuilder: TStringBuilder;

  function IsReserved(const AChar: Char): Boolean;
  begin
    Result := not (Pos(AChar, UNRESERVED_CHARS) + Pos(AChar, ACustomUnreserved) > 0);
  end;
begin
  if AValue.IsEmpty then
    Exit('');

  LBuilder := TStringBuilder.Create;
  try
    LCount := 1;
    while LCount <= Length(AValue) do
    begin
      if (AValue[LCount] = '%') and (LCount + 2 <= Length(AValue)) then
      begin
        LHex := AValue.Substring(LCount, 2);
        if TryStrToInt('$' + LHex, LByte) then
        begin
          // � um percent-encoding v�lido
          if not IsReserved(Char(LByte)) then
          begin
            // Decodifica se for um caractere n�o reservado
            LBuilder.Append(Char(LByte));
          end
          else
          begin
            // Mant�m codificado, mas com hex em mai�sculo
            LBuilder.Append('%' + LHex.ToUpper);
          end;
          Inc(LCount, 3);
        end
        else
        begin
          // Sequ�ncia inv�lida, apenas anexa
          LBuilder.Append(AValue[LCount]);
          Inc(LCount);
        end;
      end
      else if IsReserved(AValue[LCount]) then
      begin
        LBuilder.Append('%' + IntToHex(Ord(AValue[LCount]), 2));
        Inc(LCount);
      end
      else
      begin
        LBuilder.Append(AValue[LCount]);
        Inc(LCount);
      end;
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

class function TURIUtils.EncodingUserInfo(const AValue: string): string;
begin
  Result := Encoding(AValue, '!$&''()*+,;=');
end;

class function TURIUtils.EvaluateJsonPointer(const ARootNode: TJSONValue; const APointer: string): TJSONValue;
var
  LSegments: TArray<string>;
  LSegment: string;
  LSegmentStr: string;
  LCurrentNode: TJSONValue;
  LIndex: Integer;
  LCount: Integer;
  LDecoded: TStringBuilder;
begin
  if not Assigned(ARootNode) then
    Exit(nil);

  // Um ponteiro vazio refere-se ao documento inteiro.
  if APointer.IsEmpty then
    Exit(ARootNode);

  // Um ponteiro JSON deve come�ar com '/'.
  if not APointer.StartsWith('/') then
    Exit(nil); // Ou raise uma exce��o, dependendo da sua estrat�gia de erro.

  LCurrentNode := ARootNode;
  LSegments := APointer.Substring(1).Split(['/']); // Pula o primeiro '/'

  for LSegment in LSegments do
  begin
    if not Assigned(LCurrentNode) then
      Exit(nil); // N�o � poss�vel navegar mais fundo.

    // Decodifica estritamente '~1' -> '/' e '~0' -> '~' (RFC 6901, Se��o 3).
    // Qualquer '~' n�o seguido de '0' ou '1' invalida o ponteiro.
    LDecoded := TStringBuilder.Create;
    try
      LCount := 1;
      while LCount <= Length(LSegment) do
      begin
        if LSegment[LCount] = '~' then
        begin
          if LCount = Length(LSegment) then
            Exit(nil);

          case LSegment[LCount + 1] of
            '0': LDecoded.Append('~');
            '1': LDecoded.Append('/');
          else
            Exit(nil);
          end;
          Inc(LCount, 2);
        end
        else
        begin
          LDecoded.Append(LSegment[LCount]);
          Inc(LCount);
        end;
      end;
      LSegmentStr := LDecoded.ToString;
    finally
      LDecoded.Free;
    end;

    if LCurrentNode is TJSONObject then
    begin
      // Tenta obter o valor da propriedade. GetValue retorna nil se n�o encontrar.
      LCurrentNode := (LCurrentNode as TJSONObject).GetValue(LSegmentStr);
    end
    else if LCurrentNode is TJSONArray then
    begin
      // Tenta converter o segmento para um �ndice de array.
      if TryStrToInt(LSegmentStr, LIndex) and (LIndex >= 0) and (LIndex < (LCurrentNode as TJSONArray).Count) then
      begin
        LCurrentNode := (LCurrentNode as TJSONArray).Items[LIndex];
      end
      else
      begin
        // �ndice inv�lido ou fora do intervalo.
        Exit(nil);
      end;
    end
    else
    begin
      // N�o � poss�vel navegar dentro de tipos primitivos (string, number, etc.).
      Exit(nil);
    end;
  end;

  Result := LCurrentNode;
end;

class function TURIUtils.IsValidJsonPointer(const APointer: string): Boolean;
var
  LSegments: TArray<string>;
  LSegment: string;
  LCount: Integer;
begin
  if APointer = '' then
    Exit(True);

  if not APointer.StartsWith('/') then
    Exit(False);

  LSegments := APointer.Substring(1).Split(['/']);
  for LSegment in LSegments do
  begin
    LCount := 1;
    while LCount <= Length(LSegment) do
    begin
      if LSegment[LCount] = '~' then
      begin
        if (LCount = Length(LSegment)) or
           ((LSegment[LCount + 1] <> '0') and (LSegment[LCount + 1] <> '1')) then
          Exit(False);

        Inc(LCount, 2);
      end
      else
        Inc(LCount);
    end;
  end;

  Result := True;
end;

class function TURIUtils.IsValidURIReference(const AURIString: string): Boolean;
var
  LURI: TURIReference;
  LChar: Char;
begin
  // Espa�os e controles n�o s�o permitidos em URI/URI-reference sem percent-encoding.
  for LChar in AURIString do
    if (Ord(LChar) <= 32) or (Ord(LChar) = 127) then
      Exit(False);

  try
    LURI := TURIReference.From(AURIString);
    LURI := LURI.Normalize;
    Result := True;
  except
    on ERFC3986Exception do
      Result := False;
  end;
end;

class function TURIUtils.IsValidURI(const AURIString: string): Boolean;
var
  LURI: TURIReference;
begin
  if not IsValidURIReference(AURIString) then
    Exit(False);

  try
    LURI := TURIReference.From(AURIString);
    Result := LURI.Scheme <> '';
  except
    on ERFC3986Exception do
      Result := False;
  end;
end;

class function TURIUtils.MergePaths(const ABasePath, ARelativePath: string): string;
var
  LPos: Integer;
begin
  if ABasePath = '' then
    Exit(ARelativePath);

  LPos := ABasePath.LastIndexOf('/');
  if LPos < 0 then
    Exit(ARelativePath)
  else
    Result := ABasePath.Substring(0, LPos + 1) + ARelativePath;
end;

class function TURIUtils.NormalizePercentEncoding(const AValue: string): string;
const
  UNRESERVED_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
var
  LHex: string;
  LByte: Integer;
  LCount: Integer;
  LBuilder: TStringBuilder;
begin
  if AValue.IsEmpty then
    Exit('');

  LBuilder := TStringBuilder.Create;
  try
    LCount := 1;
    while LCount <= Length(AValue) do
    begin
      if (AValue[LCount] = '%') and (LCount + 2 <= Length(AValue)) then
      begin
        LHex := AValue.Substring(LCount, 2);
        if TryStrToInt('$' + LHex, LByte) then
        begin
          // � um percent-encoding v�lido
          if Pos(Char(LByte), UNRESERVED_CHARS) > 0 then
          begin
            // Decodifica se for um caractere n�o reservado
            LBuilder.Append(Char(LByte));
          end
          else
          begin
            // Mant�m codificado, mas com hex em mai�sculo
            LBuilder.Append('%' + LHex.ToUpper);
          end;
          Inc(LCount, 3);
        end
        else
        begin
          // Sequ�ncia inv�lida, apenas anexa
          LBuilder.Append(AValue[LCount]);
          Inc(LCount);
        end;
      end
      else
      begin
        LBuilder.Append(AValue[LCount]);
        Inc(LCount);
      end;
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

class function TURIUtils.NormalizeScheme(const AScheme: string): string;
begin
  Result := AScheme.ToLower;
end;

class function TURIUtils.NormalizeURI(const AURIString: string): string;
var
  LURI, LNormalizedURI: TURIReference;
begin
  // 1. Parseia a string para obter a estrutura TURIReference.
  LURI := TURIReference.From(AURIString);
  // 2. Chama o m�todo de normaliza��o, que retorna uma nova inst�ncia.
  LNormalizedURI := LURI.Normalize;
  // 3. Recomp�e a URI normalizada de volta para uma string.
  Result := LNormalizedURI.Unsplit;
end;

class procedure TURIUtils.ParseAuthority(const AAuthority: string; out AUserInfo, AHost, APort: string);
var
  LRest: string;
  LAtPos: Integer;
  LColonPos: Integer;
  LBracketPos: Integer;
begin
  AUserInfo := '';
  AHost := '';
  APort := '';

  if AAuthority = '' then
    Exit;

  LRest := AAuthority;

  LAtPos := LRest.LastIndexOf('@');
  if LAtPos > -1 then
  begin
    AUserInfo := LRest.Substring(0, LAtPos);
    LRest := LRest.Substring(LAtPos + 1);
  end;

  // Trata hosts IPv6 literais [::1]
  LBracketPos := LRest.LastIndexOf(']');
  if LRest.StartsWith('[') and (LBracketPos > 0) then
  begin
    AHost := LRest.Substring(0, LBracketPos + 1);
    LRest := LRest.Substring(LBracketPos + 1);
    if LRest.StartsWith(':') then
      APort := LRest.Substring(1)
    else
      APort := '';
  end
  else
  begin
    LColonPos := LRest.LastIndexOf(':');
    if (LColonPos > -1) and (LRest.IndexOf(']') < LColonPos) then
    begin
      AHost := LRest.Substring(0, LColonPos);
      APort := LRest.Substring(LColonPos + 1);
    end
    else
    begin
      AHost := LRest;
      APort := '';
    end;
  end;
end;

class procedure TURIUtils.ParseUserInfo(const AUserInfo: string; out AUsername, APassword: string);
var
  LAtPos: Integer;
begin
  AUsername := '';
  APassword := '';

  if AUserInfo = '' then
    Exit;

  LAtPos := AUserInfo.IndexOf(':');
  if LAtPos > -1 then
  begin
    AUsername := AUserInfo.Substring(0, LAtPos);
    APassword := AUserInfo.Substring(LAtPos + 1);
  end
  else
    AUsername := AUserInfo;
end;

class function TURIUtils.RemoveDotSegments(const APath: string): string;
var
  LCount: Integer;
  LInput: TStringList;
  LOutput: TStringList;
begin
  if APath = '' then
    Exit('');

  LInput := TStringList.Create;
  LOutput := TStringList.Create;
  try
    // Divide o path em segmentos
    LInput.Text := APath.Replace('/', sLineBreak);

    for LCount := 0 to LInput.Count - 1 do
    begin
      if LInput[LCount] = '.' then
        Continue
      else if LInput[LCount] = '..' then
      begin
        if LOutput.Count > 0 then
          LOutput.Delete(LOutput.Count - 1);
      end
      else
        LOutput.Add(LInput[LCount]);
    end;

    Result := LOutput.Text.TrimRight.Replace(sLineBreak, '/');


    if APath.StartsWith('/') and (Result <> '') and not Result.StartsWith('/') then
      Result := '/' + Result;

    if not Result.EndsWith('/') then
      if (APath.EndsWith('/.') or APath.EndsWith('/..') or APath.EndsWith('/') or MatchStr(APath, ['.', '..'])) then
        Result := Result + '/';
  finally
    LInput.Free;
    LOutput.Free;
  end;
end;

end.
