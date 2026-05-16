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
    class function NormalizeURI(const pURIString: string): string; static;

    /// <summary>Fun��o de conveni�ncia para validar uma URI de forma r�pida.</summary>
    /// <remarks>Realiza uma valida��o gen�rica de sintaxe. Para regras customizadas, utilize a classe TValidator.</remarks>
    class function IsValidURI(const pURIString: string): Boolean; static;

    /// <summary>
    ///   Fun��o de conveni�ncia para parsear uma URI no formato TParseResult.
    /// </summary>
    /// <remarks>
    ///   An�loga � fun��o 'urlparse' da biblioteca padr�o do Python.
    /// </remarks>
    //function URIParse(const AURIString: string): TParseResult;

    /// <summary>Junta o path de uma URI base com um path relativo. RFC 3986, Se��o 5.2.3.</summary>
    class function MergePaths(const pBasePath, pRelativePath: string): string; static;

    class procedure ParseAuthority(const pAuthority: string; out pUserInfo, pHost, pPort: string); static;

    class procedure ParseUserInfo(const pUserInfo: string; out pUsername, pPassword: string); static;

    /// <summary>Remove os segmentos '.' e '..'. RFC 3986, Se��o 5.2.4.</summary>
    class function RemoveDotSegments(const pPath: string): string; static;

    /// <summary>Normaliza os caracteres de percent-encoding para uppercase. RFC 3986, Se��o 6.2.2.2.</summary>
    class function NormalizePercentEncoding(const pValue: string): string; static;

    /// <summary>Normaliza o scheme para lowercase. RFC 3986, Se��o 6.2.2.1.</summary>
    class function NormalizeScheme(const pScheme: string): string; static;

    class function Encoding(const pValue, pCustomUnreserved: string): string; static;

    /// <summary>
    ///   Codifica uma string para ser usada no userinfo (username ou password), seguindo as regras da RFC 3986, Se��o 3.2.1.
    /// </summary>
    /// <remarks>Caracteres permitidos s�o: unreserved / sub-delims / ":" Todos os outros, incluindo '@', devem ser codificados.</remarks>
    class function EncodingUserInfo(const pValue: string): string; static;

    class function EvaluateJsonPointer(const pRootNode: TJSONValue; const pPointer: string): TJSONValue; static;
    class function IsValidJsonPointer(const pPointer: string): Boolean; static;
    class function IsValidURIReference(const pURIString: string): Boolean; static;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  System.StrUtils,
  System.Character,
  System.Generics.Collections,
  JsonSchema.Common.Utils,
  JsonSchema.Registry.Uri,
  JsonSchema.Registry.Types,
  JsonSchema.Registry.Uri.Validator;

{ TURIUtils }

class function TURIUtils.Encoding(const pValue, pCustomUnreserved: string): string;
const
  UNRESERVED_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
var
  lHex: string;
  lByte: Integer;
  lCount: Integer;
  lBuilder: TStringBuilder;

  function IsReserved(const pChar: Char): Boolean;
  begin
    Result := not (Pos(pChar, UNRESERVED_CHARS) + Pos(pChar, pCustomUnreserved) > 0);
  end;
begin
  if pValue.IsEmpty then
    Exit('');

  lBuilder := TStringBuilder.Create;
  try
    lCount := 1;
    while lCount <= Length(pValue) do
    begin
      if (pValue[lCount] = '%') and (lCount + 2 <= Length(pValue)) then
      begin
        lHex := pValue.Substring(lCount, 2);
        if TryStrToInt('$' + lHex, lByte) then
        begin
          // � um percent-encoding v�lido
          if not IsReserved(Char(lByte)) then
          begin
            // Decodifica se for um caractere n�o reservado
            lBuilder.Append(Char(lByte));
          end
          else
          begin
            // Mant�m codificado, mas com hex em mai�sculo
            lBuilder.Append('%' + lHex.ToUpper);
          end;
          Inc(lCount, 3);
        end
        else
        begin
          // Sequ�ncia inv�lida, apenas anexa
          lBuilder.Append(pValue[lCount]);
          Inc(lCount);
        end;
      end
      else if IsReserved(pValue[lCount]) then
      begin
        lBuilder.Append('%' + IntToHex(Ord(pValue[lCount]), 2));
        Inc(lCount);
      end
      else
      begin
        lBuilder.Append(pValue[lCount]);
        Inc(lCount);
      end;
    end;
    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

class function TURIUtils.EncodingUserInfo(const pValue: string): string;
begin
  Result := Encoding(pValue, '!$&''()*+,;=');
end;

class function TURIUtils.EvaluateJsonPointer(const pRootNode: TJSONValue; const pPointer: string): TJSONValue;
var
  lSegments: TArray<string>;
  lSegment: string;
  lSegmentStr: string;
  lCurrentNode: TJSONValue;
  lIndex: Integer;
begin
  if not Assigned(pRootNode) then
    Exit(nil);

  // Um ponteiro vazio refere-se ao documento inteiro.
  if pPointer.IsEmpty then
    Exit(pRootNode);

  // Um ponteiro JSON deve come�ar com '/'.
  if not pPointer.StartsWith('/') then
    Exit(nil); // Ou raise uma exce��o, dependendo da sua estrat�gia de erro.

  lCurrentNode := pRootNode;
  lSegments := pPointer.Substring(1).Split(['/']); // Pula o primeiro '/'

  for lSegment in lSegments do
  begin
    if not Assigned(lCurrentNode) then
      Exit(nil); // N�o � poss�vel navegar mais fundo.

    if not TUtils.DecodeJsonPointerSegment(lSegment, lSegmentStr) then
      Exit(nil);

    if lCurrentNode is TJSONObject then
    begin
      // Tenta obter o valor da propriedade. GetValue retorna nil se n�o encontrar.
      lCurrentNode := (lCurrentNode as TJSONObject).GetValue(lSegmentStr);
    end
    else if lCurrentNode is TJSONArray then
    begin
      // Tenta converter o segmento para um �ndice de array.
      if TryStrToInt(lSegmentStr, lIndex) and (lIndex >= 0) and (lIndex < (lCurrentNode as TJSONArray).Count) then
      begin
        lCurrentNode := (lCurrentNode as TJSONArray).Items[lIndex];
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

  Result := lCurrentNode;
end;

class function TURIUtils.IsValidJsonPointer(const pPointer: string): Boolean;
var
  lSegments: TArray<string>;
  lSegment: string;
  lCount: Integer;
begin
  if pPointer = '' then
    Exit(True);

  if not pPointer.StartsWith('/') then
    Exit(False);

  lSegments := pPointer.Substring(1).Split(['/']);
  for lSegment in lSegments do
  begin
    lCount := 1;
    while lCount <= Length(lSegment) do
    begin
      if lSegment[lCount] = '~' then
      begin
        if (lCount = Length(lSegment)) or
           ((lSegment[lCount + 1] <> '0') and (lSegment[lCount + 1] <> '1')) then
          Exit(False);

        Inc(lCount, 2);
      end
      else
        Inc(lCount);
    end;
  end;

  Result := True;
end;

class function TURIUtils.IsValidURIReference(const pURIString: string): Boolean;
var
  lURI: TURIReference;
  lChar: Char;
begin
  // Espa�os e controles n�o s�o permitidos em URI/URI-reference sem percent-encoding.
  for lChar in pURIString do
    if (Ord(lChar) <= 32) or (Ord(lChar) = 127) then
      Exit(False);

  try
    lURI := TURIReference.From(pURIString);
    lURI := lURI.Normalize;
    Result := True;
  except
    on ERFC3986Exception do
      Result := False;
  end;
end;

class function TURIUtils.IsValidURI(const pURIString: string): Boolean;
var
  lURI: TURIReference;
begin
  if not IsValidURIReference(pURIString) then
    Exit(False);

  try
    lURI := TURIReference.From(pURIString);
    Result := lURI.Scheme <> '';
  except
    on ERFC3986Exception do
      Result := False;
  end;
end;

class function TURIUtils.MergePaths(const pBasePath, pRelativePath: string): string;
var
  lPos: Integer;
begin
  if pBasePath = '' then
    Exit(pRelativePath);

  lPos := pBasePath.LastIndexOf('/');
  if lPos < 0 then
    Exit(pRelativePath)
  else
    Result := pBasePath.Substring(0, lPos + 1) + pRelativePath;
end;

class function TURIUtils.NormalizePercentEncoding(const pValue: string): string;
const
  UNRESERVED_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
var
  lHex: string;
  lByte: Integer;
  lCount: Integer;
  lBuilder: TStringBuilder;
begin
  if pValue.IsEmpty then
    Exit('');

  lBuilder := TStringBuilder.Create;
  try
    lCount := 1;
    while lCount <= Length(pValue) do
    begin
      if (pValue[lCount] = '%') and (lCount + 2 <= Length(pValue)) then
      begin
        lHex := pValue.Substring(lCount, 2);
        if TryStrToInt('$' + lHex, lByte) then
        begin
          // � um percent-encoding v�lido
          if Pos(Char(lByte), UNRESERVED_CHARS) > 0 then
          begin
            // Decodifica se for um caractere n�o reservado
            lBuilder.Append(Char(lByte));
          end
          else
          begin
            // Mant�m codificado, mas com hex em mai�sculo
            lBuilder.Append('%' + lHex.ToUpper);
          end;
          Inc(lCount, 3);
        end
        else
        begin
          // Sequ�ncia inv�lida, apenas anexa
          lBuilder.Append(pValue[lCount]);
          Inc(lCount);
        end;
      end
      else
      begin
        lBuilder.Append(pValue[lCount]);
        Inc(lCount);
      end;
    end;
    Result := lBuilder.ToString;
  finally
    lBuilder.Free;
  end;
end;

class function TURIUtils.NormalizeScheme(const pScheme: string): string;
begin
  Result := pScheme.ToLower;
end;

class function TURIUtils.NormalizeURI(const pURIString: string): string;
var
  lURI, lNormalizedURI: TURIReference;
begin
  // 1. Parseia a string para obter a estrutura TURIReference.
  lURI := TURIReference.From(pURIString);
  // 2. Chama o m�todo de normaliza��o, que retorna uma nova inst�ncia.
  lNormalizedURI := lURI.Normalize;
  // 3. Recomp�e a URI normalizada de volta para uma string.
  Result := lNormalizedURI.Unsplit;
end;

class procedure TURIUtils.ParseAuthority(const pAuthority: string; out pUserInfo, pHost, pPort: string);
var
  lRest: string;
  lAtPos: Integer;
  lColonPos: Integer;
  lBracketPos: Integer;
begin
  pUserInfo := '';
  pHost := '';
  pPort := '';

  if pAuthority = '' then
    Exit;

  lRest := pAuthority;

  lAtPos := lRest.LastIndexOf('@');
  if lAtPos > -1 then
  begin
    pUserInfo := lRest.Substring(0, lAtPos);
    lRest := lRest.Substring(lAtPos + 1);
  end;

  // Trata hosts IPv6 literais [::1]
  lBracketPos := lRest.LastIndexOf(']');
  if lRest.StartsWith('[') and (lBracketPos > 0) then
  begin
    pHost := lRest.Substring(0, lBracketPos + 1);
    lRest := lRest.Substring(lBracketPos + 1);
    if lRest.StartsWith(':') then
      pPort := lRest.Substring(1)
    else
      pPort := '';
  end
  else
  begin
    lColonPos := lRest.LastIndexOf(':');
    if (lColonPos > -1) and (lRest.IndexOf(']') < lColonPos) then
    begin
      pHost := lRest.Substring(0, lColonPos);
      pPort := lRest.Substring(lColonPos + 1);
    end
    else
    begin
      pHost := lRest;
      pPort := '';
    end;
  end;
end;

class procedure TURIUtils.ParseUserInfo(const pUserInfo: string; out pUsername, pPassword: string);
var
  lAtPos: Integer;
begin
  pUsername := '';
  pPassword := '';

  if pUserInfo = '' then
    Exit;

  lAtPos := pUserInfo.IndexOf(':');
  if lAtPos > -1 then
  begin
    pUsername := pUserInfo.Substring(0, lAtPos);
    pPassword := pUserInfo.Substring(lAtPos + 1);
  end
  else
    pUsername := pUserInfo;
end;

class function TURIUtils.RemoveDotSegments(const pPath: string): string;
var
  lCount: Integer;
  lInput: TStringList;
  lOutput: TStringList;
begin
  if pPath = '' then
    Exit('');

  lInput := TStringList.Create;
  lOutput := TStringList.Create;
  try
    // Divide o path em segmentos
    lInput.Text := pPath.Replace('/', sLineBreak);

    for lCount := 0 to lInput.Count - 1 do
    begin
      if lInput[lCount] = '.' then
        Continue
      else if lInput[lCount] = '..' then
      begin
        if lOutput.Count > 0 then
          lOutput.Delete(lOutput.Count - 1);
      end
      else
        lOutput.Add(lInput[lCount]);
    end;

    Result := lOutput.Text.TrimRight.Replace(sLineBreak, '/');


    if pPath.StartsWith('/') and (Result <> '') and not Result.StartsWith('/') then
      Result := '/' + Result;

    if not Result.EndsWith('/') then
      if (pPath.EndsWith('/.') or pPath.EndsWith('/..') or pPath.EndsWith('/') or MatchStr(pPath, ['.', '..'])) then
        Result := Result + '/';
  finally
    lInput.Free;
    lOutput.Free;
  end;
end;

end.
