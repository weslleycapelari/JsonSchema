unit JsonSchema.JsonPathUtils;

interface

uses
  System.JSON,
  System.Generics.Collections;

type
  /// <summary>
  ///   Utilitários estáticos para operações com JSON Pointer (RFC 6901):
  ///   normalização de paths, codificação/decodificação de segmentos,
  ///   navegação em documentos JSON e construção de conjuntos de paths avaliados.
  /// </summary>
  /// <remarks>
  ///   Todos os métodos são estáticos e thread-safe. A classe não possui estado
  ///   e não precisa ser instanciada.
  ///
  ///   Convenção de paths internos: caminhos canônicos sempre começam com <c>'/'</c>.
  ///   O path raiz é representado por <c>'/'</c> isolado.
  /// </remarks>
  TJsonPathUtils = class
  public
    /// <summary>
    ///   Normaliza um path de propriedade para a forma canônica delimitada por barras.
    ///   Trata os prefixos <c>'#/'</c>, <c>'#.'</c>, <c>'.'</c>, <c>'#'</c> e paths
    ///   sem prefixo, além de colapsar barras consecutivas e remover barra final.
    /// </summary>
    /// <param name="pPath">Path de entrada (ex.: <c>'#/foo/bar'</c> ou <c>'#.foo.bar'</c>).</param>
    /// <returns>Path canônico iniciando com <c>'/'</c> (ex.: <c>'/foo/bar'</c>).</returns>
    class function NormalizeToCanonical(const pPath: string): string; static;

    /// <summary>
    ///   Divide um path canônico nos seus segmentos já decodificados (RFC 6901).
    ///   Exemplo: <c>'/foo/bar~1baz'</c> → <c>['foo', 'bar/baz']</c>.
    ///   Retorna array vazio para o path raiz (<c>'/'</c>).
    /// </summary>
    class function SplitPathIntoSegments(const pPath: string): TArray<string>; static;

    /// <summary>
    ///   Codifica um segmento para uso em JSON Pointer (RFC 6901).
    ///   Substitui <c>'~'</c> por <c>'~0'</c> e <c>'/'</c> por <c>'~1'</c>,
    ///   nesta ordem, conforme exige a especificação.
    /// </summary>
    class function EncodeSegment(const pSegment: string): string; static;

    /// <summary>
    ///   Decodifica um segmento de JSON Pointer (RFC 6901).
    ///   Substitui <c>'~1'</c> por <c>'/'</c> e <c>'~0'</c> por <c>'~'</c>,
    ///   nesta ordem obrigatória para evitar dupla decodificação incorreta.
    /// </summary>
    class function DecodeSegment(const pSegment: string): string; static;

    /// <summary>
    ///   Valida se uma string é um JSON Pointer sintaticamente correto (RFC 6901).
    ///   Um pointer vazio é válido (referencia o documento raiz).
    ///   Todo pointer não vazio deve começar com <c>'/'</c> e conter apenas
    ///   escapes <c>'~0'</c> e <c>'~1'</c>.
    /// </summary>
    class function IsValidPointer(const pPointer: string): Boolean; static;

    /// <summary>
    ///   Navega um documento JSON usando um JSON Pointer e retorna o nó referenciado.
    ///   Retorna <c>nil</c> se o pointer não resolver para um nó existente ou se
    ///   o pointer for inválido.
    /// </summary>
    /// <remarks>
    ///   Os segmentos retornados por <c>SplitPathIntoSegments</c> já estão decodificados;
    ///   não é necessário (e seria incorreto) decodificá-los novamente durante a navegação.
    /// </remarks>
    class function EvaluatePointer(const pRoot: TJSONValue; const pPointer: string): TJSONValue; static;

    /// <summary>
    ///   Constrói um <c>THashSet</c> de paths avaliados a partir do resultado de
    ///   uma validação, para uso nas keywords <c>unevaluatedProperties</c> e
    ///   <c>unevaluatedItems</c>.
    /// </summary>
    /// <remarks>
    ///   O chamador é responsável por liberar o <c>THashSet</c> retornado.
    /// </remarks>
    /// <param name="pBasePath">Path base canônico do objeto/array sendo avaliado.</param>
    /// <param name="pEvaluatedProperties">Paths já avaliados em validações anteriores.</param>
    /// <param name="pCoveredProperties">Nomes de propriedades cobertas nesta validação.</param>
    /// <param name="pCoveredItems">Índices de itens cobertos nesta validação.</param>
    /// <returns>Novo <c>THashSet</c> com todos os paths avaliados normalizados.</returns>
    class function BuildEvaluatedSet(const pBasePath: string; const pEvaluatedProperties: TEnumerable<string>;
      const pCoveredProperties: TArray<string>; const pCoveredItems: TArray<Integer>): THashSet<string>; static;

    /// <summary>
    ///   Une um path base com um sufixo, garantindo exatamente um separador
    ///   <c>'/'</c> entre eles.
    /// </summary>
    class function JoinPath(const pBasePath, pSuffix: string): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.RegularExpressions,
  JsonSchema.Common.Utils;

{ TJsonPathUtils }

class function TJsonPathUtils.NormalizeToCanonical(const pPath: string): string;
begin
  Result := Trim(pPath);

  if Result.IsEmpty or (Result = '#') then
    Exit('/');

  if Result.StartsWith('#/') then
    Result := Result.Substring(1)
  else if Result.StartsWith('#.') then
    Result := '/' + StringReplace(Result.Substring(2), '.', '/', [rfReplaceAll])
  else if Result.StartsWith('.') then
    Result := '/' + StringReplace(Result.Substring(1), '.', '/', [rfReplaceAll])
  else if Result.StartsWith('#') then
    Result := '/' + Result.Substring(1)
  else if not Result.StartsWith('/') then
    Result := '/' + Result;

  // Colapsa barras consecutivas geradas pelas substituições acima.
  // StringReplace com rfReplaceAll faz uma passagem; o while garante que
  // '//' restantes de '///' (ex.) também sejam eliminados.
  while Pos('//', Result) > 0 do
    Result := StringReplace(Result, '//', '/', [rfReplaceAll]);

  // Remove barra final, exceto quando o path é exatamente a raiz '/'
  if Result.EndsWith('/') and (Result <> '/') then
    Delete(Result, Length(Result), 1);
end;

class function TJsonPathUtils.SplitPathIntoSegments(const pPath: string): TArray<string>;
var
  lCanonical: string;
  lRawSegments: TArray<string>;
  lSegment: string;
  lResult: TList<string>;
begin
  lCanonical := NormalizeToCanonical(pPath);

  if (lCanonical = '/') or lCanonical.IsEmpty then
  begin
    Result := [];
    Exit;
  end;

  // Remove a barra inicial antes de dividir
  lRawSegments := lCanonical.Substring(1).Split(['/']);

  // TList evita realocações O(n²) que ocorreriam com Result := Result + [x] em loop
  lResult := TList<string>.Create;
  try
    for lSegment in lRawSegments do
      lResult.Add(DecodeSegment(lSegment));

    Result := lResult.ToArray;
  finally
    lResult.Free;
  end;
end;

class function TJsonPathUtils.EncodeSegment(const pSegment: string): string;
begin
  // A ordem importa: '~' deve ser codificado antes de '/' para evitar que
  // '~1' gerado pela codificação de '/' seja re-codificado como '~01'
  Result := pSegment
    .Replace('~', '~0', [rfReplaceAll])
    .Replace('/', '~1', [rfReplaceAll]);
end;

class function TJsonPathUtils.DecodeSegment(const pSegment: string): string;
begin
  // A ordem importa (RFC 6901): '~1' deve ser decodificado antes de '~0'
  // para que '~01' resulte em '~1' e não em '/'.
  Result := pSegment
    .Replace('~1', '/', [rfReplaceAll])
    .Replace('~0', '~', [rfReplaceAll]);
end;

class function TJsonPathUtils.IsValidPointer(const pPointer: string): Boolean;
var
  lRawSegments: TArray<string>;
  lSegment: string;
  lSegIndex: Integer;
  lCharIndex: Integer;
  lIsValid: Boolean;
begin
  // String vazia é um pointer válido (referencia o documento raiz)
  if pPointer.IsEmpty then
    Exit(True);

  if not pPointer.StartsWith('/') then
    Exit(False);

  lRawSegments := pPointer.Substring(1).Split(['/']);
  lSegIndex := 0;
  lIsValid := True;

  while lIsValid and (lSegIndex < Length(lRawSegments)) do
  begin
    lSegment := lRawSegments[lSegIndex];
    lCharIndex := 1;

    while lIsValid and (lCharIndex <= lSegment.Length) do
    begin
      if lSegment[lCharIndex] = '~' then
      begin
        // '~' só pode ser seguido de '0' ou '1'
        if (lCharIndex = lSegment.Length) or
          ((lSegment[lCharIndex + 1] <> '0') and (lSegment[lCharIndex + 1] <> '1')) then
        begin
          lIsValid := False;
        end;

        Inc(lCharIndex, 2);
      end else
        Inc(lCharIndex);
    end;

    Inc(lSegIndex);
  end;

  Result := lIsValid;
end;

class function TJsonPathUtils.EvaluatePointer(const pRoot: TJSONValue; const pPointer: string): TJSONValue;
var
  lDecodedSegments: TArray<string>;
  lSegment: string;
  lCurrent: TJSONValue;
  lSegIndex: Integer;
  lArrayIndex: Integer;
begin
  if not Assigned(pRoot) then
    Exit(nil);

  if pPointer.IsEmpty or (pPointer = '#') then
    Exit(pRoot);

  if not IsValidPointer(pPointer) then
    Exit(nil);

  // SplitPathIntoSegments já decodifica cada segmento via DecodeSegment.
  // Não deve-se decodificar novamente: '~01' decodificado uma vez resulta em
  // '~1' (correto); decodificado duas vezes resultaria em '/' (incorreto).
  lDecodedSegments := SplitPathIntoSegments(pPointer);
  lCurrent := pRoot;
  lSegIndex := 0;

  while Assigned(lCurrent) and (lSegIndex < Length(lDecodedSegments)) do
  begin
    lSegment := lDecodedSegments[lSegIndex];

    if lCurrent is TJSONObject then
      lCurrent := TJSONObject(lCurrent).GetValue(lSegment)
    else if lCurrent is TJSONArray then
    begin
      if TryStrToInt(lSegment, lArrayIndex) and
        (lArrayIndex >= 0) and
        (lArrayIndex < TJSONArray(lCurrent).Count) then
      begin
        lCurrent := TJSONArray(lCurrent).Items[lArrayIndex];
      end else
        lCurrent := nil;
    end else
      lCurrent := nil;

    Inc(lSegIndex);
  end;

  Result := lCurrent;
end;

class function TJsonPathUtils.BuildEvaluatedSet(const pBasePath: string; const pEvaluatedProperties: TEnumerable<string>;
  const pCoveredProperties: TArray<string>; const pCoveredItems: TArray<Integer>): THashSet<string>;
var
  lCanonicalBase: string;
  lItem: string;
  lIndex: Integer;
begin
  Result := THashSet<string>.Create;
  lCanonicalBase := NormalizeToCanonical(pBasePath);

  // Garante que o base termine com '/' para concatenar sub-paths corretamente
  if not lCanonicalBase.EndsWith('/') and (lCanonicalBase <> '/') then
    lCanonicalBase := lCanonicalBase + '/';

  if Assigned(pEvaluatedProperties) then
  begin
    for lItem in pEvaluatedProperties do
      Result.Add(NormalizeToCanonical(lItem));
  end;

  for lItem in pCoveredProperties do
    Result.Add(lCanonicalBase + lItem);

  for lIndex in pCoveredItems do
    Result.Add(lCanonicalBase + lIndex.ToString);
end;

class function TJsonPathUtils.JoinPath(const pBasePath, pSuffix: string): string;
var
  lBase: string;
begin
  lBase := NormalizeToCanonical(pBasePath);

  if lBase = '/' then
    Result := '/' + pSuffix
  else if lBase.EndsWith('/') then
    Result := lBase + pSuffix
  else
    Result := lBase + '/' + pSuffix;
end;

end.
