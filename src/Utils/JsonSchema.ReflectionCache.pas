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
  ///   Thread-safe cache that stores method dispatch maps for visitor classes.
  ///   For each visitor class, it scans methods decorated with [VisitorKeyword]
  ///   and builds a dictionary mapping keyword names to method pointers.
  ///   This eliminates repetitive RTTI scanning each time a walker is created.
  /// </summary>
  TReflectionCache = class
  private
    class var FInstance: TReflectionCache;
    class var FLock: TObject;
    class function GetInstance: TReflectionCache; static;

  private
    FCache: TDictionary<TClass, TDictionary<string, TVisitorProc>>;
    FLockCache: TCriticalSection;

    function GetOrCreateMapForClass(const pClass: TClass): TDictionary<string, TVisitorProc>;
    procedure ScanMethodsForClass(const pClass: TClass; const pMap: TDictionary<string, TVisitorProc>);

  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Returns the method dispatch map for the given visitor instance.
    ///   The map is shared among all instances of the same class.
    /// </summary>
    class function GetMethodMap(const pVisitor: TObject): TDictionary<string, TVisitorProc>;

    /// <summary>
    ///   Clears the entire cache (useful for testing or memory cleanup).
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

procedure TReflectionCache.ScanMethodsForClass(const pClass: TClass;
  const pMap: TDictionary<string, TVisitorProc>);
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
    if lType = nil then
      Exit;

    for lMethod in lType.GetMethods do
    begin
      for lAttr in lMethod.GetAttributes do
      begin
        if (lAttr is VisitorKeywordAttribute) and (Length(lMethod.GetParameters) = 1) then
        begin
          lMethodPtr.Code := lMethod.CodeAddress;
          lMethodPtr.Data := nil; // Data will be set when invoking (visitor instance)
          pMap.AddOrSetValue(VisitorKeywordAttribute(lAttr).Name, TVisitorProc(lMethodPtr));
        end;
      end;
    end;
  finally
    lContext.Free;
  end;

  // Also scan ancestor classes (already covered by RTTI, but ensure we don't miss if we stop early)
  // RTTI already includes inherited methods, so no need to recurse.
end;

class procedure TReflectionCache.Clear;
var
  lInstance: TReflectionCache;
begin
  TMonitor.Enter(FLock);
  try
    lInstance := FInstance;
    FInstance := nil;
  finally
    TMonitor.Exit(FLock);
  end;
  lInstance.Free;
end;

initialization
  TReflectionCache.FLock := TObject.Create;

finalization
  TReflectionCache.Clear;
  TReflectionCache.FLock.Free;

end.
