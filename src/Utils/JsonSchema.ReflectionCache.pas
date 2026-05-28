unit JsonSchema.ReflectionCache;

interface

uses
  System.JSON,
  System.Generics.Collections,
  System.Rtti,
  System.SyncObjs,
  JsonSchema.Visitors.Types;

type
  /// <summary>
  ///   Cache singleton thread-safe que armazena mapas de despacho de métodos para
  ///   classes visitor. Para cada classe, escaneia via RTTI os métodos decorados
  ///   com <c>[VisitorKeyword]</c> e constrói um dicionário mapeando nomes de
  ///   keyword para ponteiros de método.
  /// </summary>
  /// <remarks>
  ///   O cache elimina o escaneamento repetitivo de RTTI toda vez que um walker
  ///   é criado: o mapa é construído uma única vez por classe e compartilhado
  ///   entre todas as instâncias.
  ///
  ///   Thread safety:
  ///   - O acesso à instância singleton é protegido por <c>TMonitor</c> com
  ///     double-checked locking.
  ///   - O acesso ao dicionário de cache interno é protegido por <c>TCriticalSection</c>.
  ///   - Os mapas retornados por <c>GetMethodMap</c> são compartilhados e devem
  ///     ser tratados como somente leitura pelo chamador.
  ///
  ///   Ciclo de vida: o singleton é criado na primeira chamada a <c>GetMethodMap</c>
  ///   e destruído automaticamente na seção <c>finalization</c> da unit.
  /// </remarks>
  TReflectionCache = class
  strict private
    /// <summary>
    ///   Mapa principal: classe visitor → dicionário (keyword → proc).
    ///   Cada dicionário interno é de propriedade deste cache e liberado no destrutor.
    /// </summary>
    FCache: TDictionary<TClass, TDictionary<string, TVisitorProc>>;

    /// <summary>Protege o acesso concorrente a <c>FCache</c>.</summary>
    FLockCache: TCriticalSection;

    /// <summary>
    ///   Retorna o mapa de despacho para <paramref name="pClass"/>, criando-o
    ///   se ainda não existir. Operação thread-safe via <c>FLockCache</c>.
    /// </summary>
    function GetOrCreateMapForClass(const pClass: TClass): TDictionary<string, TVisitorProc>;

    /// <summary>
    ///   Escaneia via RTTI todos os métodos de <paramref name="pClass"/> e
    ///   registra em <paramref name="pMap"/> aqueles decorados com
    ///   <c>[VisitorKeyword]</c> que possuam exatamente um parâmetro.
    ///   O RTTI já inclui métodos herdados, portanto a hierarquia completa
    ///   é coberta em uma única chamada.
    /// </summary>
    procedure ScanMethodsForClass(const pClass: TClass; const pMap: TDictionary<string, TVisitorProc>);

    /// <summary>Instância única (singleton). Acesso via <c>GetInstance</c>.</summary>
    class var FInstance: TReflectionCache;

    /// <summary>
    ///   Retorna (criando se necessário) a instância singleton com double-checked
    ///   locking para garantir thread-safety na criação.
    /// </summary>
    class function GetInstance: TReflectionCache; static;
  private
    /// <summary>
    ///   Mutex para o double-checked locking de <c>GetInstance</c>.
    ///   Criado em <c>initialization</c> e destruído em <c>finalization</c>.
    /// </summary>
    class var FLock: TObject;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Retorna o mapa de despacho de métodos para a classe do visitor informado.
    ///   O mapa é compartilhado entre todas as instâncias da mesma classe e não
    ///   deve ser modificado pelo chamador.
    /// </summary>
    /// <param name="pVisitor">Instância cujo <c>ClassType</c> será consultado.</param>
    class function GetMethodMap(const pVisitor: TObject): TDictionary<string, TVisitorProc>;

    /// <summary>
    ///   Destrói o singleton e libera todos os mapas em cache.
    ///   Útil em testes de unidade ou para forçar a liberação antecipada de memória.
    ///   Thread-safe: usa <c>TMonitor</c> para garantir que apenas uma thread
    ///   destrua a instância.
    /// </summary>
    class procedure Clear;
  end;

implementation

uses
  System.SysUtils,
  System.TypInfo;

{ TReflectionCache }

constructor TReflectionCache.Create;
begin
  FCache := TDictionary<TClass, TDictionary<string, TVisitorProc>>.Create;
  FLockCache := TCriticalSection.Create;
end;

destructor TReflectionCache.Destroy;
var
  lPair: TPair<TClass, TDictionary<string, TVisitorProc>>;
begin
  for lPair in FCache do
    lPair.Value.Free;

  FCache.Free;
  FLockCache.Free;
  inherited;
end;

class function TReflectionCache.GetInstance: TReflectionCache;
begin
  // Double-checked locking: evita o custo de TMonitor.Enter na maioria das chamadas
  if FInstance = nil then
  begin
    TMonitor.Enter(FLock);
    try
      if FInstance = nil then
        FInstance := TReflectionCache.Create;
    finally
      TMonitor.Exit(FLock);
    end;
  end;

  Result := FInstance;
end;

class function TReflectionCache.GetMethodMap(const pVisitor: TObject): TDictionary<string, TVisitorProc>;
begin
  Result := GetInstance.GetOrCreateMapForClass(pVisitor.ClassType);
end;

function TReflectionCache.GetOrCreateMapForClass(const pClass: TClass): TDictionary<string, TVisitorProc>;
begin
  FLockCache.Enter;
  try
    if not FCache.TryGetValue(pClass, Result) then
    begin
      Result := TDictionary<string, TVisitorProc>.Create;
      ScanMethodsForClass(pClass, Result);
      FCache.Add(pClass, Result);
    end;
  finally
    FLockCache.Leave;
  end;
end;

procedure TReflectionCache.ScanMethodsForClass(const pClass: TClass; const pMap: TDictionary<string, TVisitorProc>);
var
  lContext: TRttiContext;
  lType: TRttiType;
  lMethod: TRttiMethod;
  lAttr: TCustomAttribute;
  lMethodPtr: TMethod;
begin
  lContext := TRttiContext.Create;
  try
    lType := lContext.GetType(pClass);

    if not Assigned(lType) then
      Exit;

    for lMethod in lType.GetMethods do
    begin
      for lAttr in lMethod.GetAttributes do
      begin
        // Apenas métodos com exatamente um parâmetro são registrados como handlers
        if (lAttr is VisitorKeywordAttribute) and (Length(lMethod.GetParameters) = 1) then
        begin
          lMethodPtr.Code := lMethod.CodeAddress;
          // Data é nil aqui; será preenchido com a instância visitor no momento da invocação
          lMethodPtr.Data := nil;
          pMap.AddOrSetValue(
            VisitorKeywordAttribute(lAttr).Name,
            TVisitorProc(lMethodPtr));
        end;
      end;
    end;
  finally
    lContext.Free;
  end;
end;

class procedure TReflectionCache.Clear;
var
  lOldInstance: TReflectionCache;
begin
  TMonitor.Enter(FLock);
  try
    lOldInstance := FInstance;
    FInstance := nil;
  finally
    TMonitor.Exit(FLock);
  end;

  // Libera fora do lock para não bloquear outras threads durante a destruição
  lOldInstance.Free;
end;

initialization
  TReflectionCache.FLock := TObject.Create;

finalization
  TReflectionCache.Clear;
  TReflectionCache.FLock.Free;

end.
