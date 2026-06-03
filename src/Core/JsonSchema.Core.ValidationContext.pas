unit JsonSchema.Core.ValidationContext;

(*
--------------------------------------------------------------------------------
Tracks evaluated properties, items, and active schema traversal stack during a session.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.Generics.Collections,
  System.SysUtils,
  JsonSchema.Core.Interfaces,
  JsonSchema.Core.SchemaRegistry;

type
  TActiveSchema = record
    SchemaObj: TJSONObject;
    Compiled: ICompiledSchema;
    Instance: TJSONValue;
  end;

  TScope = class
  public
    PropertyEvaluations: TDictionary<TJSONValue, TList<string>>;
    ItemEvaluations: TDictionary<TJSONValue, TList<Integer>>;
    constructor Create;
    destructor Destroy; override;
    procedure MarkProperty(const pInstance: TJSONValue; const pProperty: string);
    procedure MarkItem(const pInstance: TJSONValue; const pIndex: Integer);
    function IsPropertyMarked(const pInstance: TJSONValue; const pProperty: string): Boolean;
    function IsItemMarked(const pInstance: TJSONValue; const pIndex: Integer): Boolean;
    procedure Merge(const pSource: TScope);
  end;

  TValidationContext = class
  strict private
    class threadvar FCurrent: TValidationContext;
    class threadvar FEnforceFormats: Boolean;
    FScopeStack: TList<TScope>;
    FSchemaStack: TList<TActiveSchema>;
    function GetCurrentScope: TScope;
    class function GetEnforceFormats: Boolean; static;
    class procedure SetEnforceFormats(const pValue: Boolean); static;
  public
    constructor Create;
    destructor Destroy; override;

    class procedure StartSession; static;
    class procedure EndSession; static;

    class procedure PushScope; static;
    class procedure PopScope(const pKeep: Boolean); static;

    class procedure MarkPropertyEvaluated(const pInstance: TJSONValue; const pProperty: string); static;
    class procedure MarkItemEvaluated(const pInstance: TJSONValue; const pIndex: Integer); static;

    class function IsPropertyEvaluated(const pInstance: TJSONValue; const pProperty: string): Boolean; static;
    class function IsItemEvaluated(const pInstance: TJSONValue; const pIndex: Integer): Boolean; static;

    class procedure PushSchema(const pSchemaObj: TJSONObject; const pCompiled: ICompiledSchema;
      const pInstance: TJSONValue); static;
    class procedure PopSchema; static;
    class function ResolveRecursiveRef: ICompiledSchema; static;
    class function ResolveDynamicAnchor(const pAnchorName: string): TJSONObject; static;
    class function IsCurrentlyValidating(const pSchemaObj: TJSONObject; const pInstance: TJSONValue): Boolean; static;

    class property EnforceFormats: Boolean read GetEnforceFormats write SetEnforceFormats;
  end;

implementation

{ TScope }

constructor TScope.Create;
begin
  inherited Create;
  PropertyEvaluations := TDictionary<TJSONValue, TList<string>>.Create;
  ItemEvaluations := TDictionary<TJSONValue, TList<Integer>>.Create;
end;

destructor TScope.Destroy;
var
  lLs: TList<string>;
  lLi: TList<Integer>;
begin
  for lLs in PropertyEvaluations.Values do
    lLs.Free;
  PropertyEvaluations.Free;

  for lLi in ItemEvaluations.Values do
    lLi.Free;
  ItemEvaluations.Free;

  inherited Destroy;
end;

procedure TScope.MarkProperty(const pInstance: TJSONValue; const pProperty: string);
var
  lList: TList<string>;
begin
  if not Assigned(pInstance) then
    Exit;

  if not PropertyEvaluations.TryGetValue(pInstance, lList) then
  begin
    lList := TList<string>.Create;
    PropertyEvaluations.Add(pInstance, lList);
  end;

  if not lList.Contains(pProperty) then
    lList.Add(pProperty);
end;

procedure TScope.MarkItem(const pInstance: TJSONValue; const pIndex: Integer);
var
  lList: TList<Integer>;
begin
  if not Assigned(pInstance) then
    Exit;

  if not ItemEvaluations.TryGetValue(pInstance, lList) then
  begin
    lList := TList<Integer>.Create;
    ItemEvaluations.Add(pInstance, lList);
  end;

  if not lList.Contains(pIndex) then
    lList.Add(pIndex);
end;

function TScope.IsPropertyMarked(const pInstance: TJSONValue; const pProperty: string): Boolean;
var
  lList: TList<string>;
begin
  Result := False;
  if Assigned(pInstance) and PropertyEvaluations.TryGetValue(pInstance, lList) then
    Result := lList.Contains(pProperty);
end;

function TScope.IsItemMarked(const pInstance: TJSONValue; const pIndex: Integer): Boolean;
var
  lList: TList<Integer>;
begin
  Result := False;
  if Assigned(pInstance) and ItemEvaluations.TryGetValue(pInstance, lList) then
    Result := lList.Contains(pIndex);
end;

procedure TScope.Merge(const pSource: TScope);
var
  lPairProp: TPair<TJSONValue, TList<string>>;
  lPairItem: TPair<TJSONValue, TList<Integer>>;
  lProp: string;
  lIdx: Integer;
begin
  if not Assigned(pSource) then
    Exit;

  for lPairProp in pSource.PropertyEvaluations do
  begin
    for lProp in lPairProp.Value do
      MarkProperty(lPairProp.Key, lProp);
  end;

  for lPairItem in pSource.ItemEvaluations do
  begin
    for lIdx in lPairItem.Value do
      MarkItem(lPairItem.Key, lIdx);
  end;
end;

{ TValidationContext }

constructor TValidationContext.Create;
begin
  inherited Create;
  FScopeStack := TList<TScope>.Create;
  FSchemaStack := TList<TActiveSchema>.Create;
end;

class function TValidationContext.GetEnforceFormats: Boolean;
begin
  Result := FEnforceFormats;
end;

class procedure TValidationContext.SetEnforceFormats(const pValue: Boolean);
begin
  FEnforceFormats := pValue;
end;

destructor TValidationContext.Destroy;
var
  lScope: TScope;
begin
  for lScope in FScopeStack do
    lScope.Free;
  FScopeStack.Free;
  FSchemaStack.Free;
  inherited Destroy;
end;

class procedure TValidationContext.StartSession;
begin
  if Assigned(FCurrent) then
    FreeAndNil(FCurrent);
  FCurrent := TValidationContext.Create;
end;

class procedure TValidationContext.EndSession;
begin
  if Assigned(FCurrent) then
    FreeAndNil(FCurrent);
end;

class procedure TValidationContext.PushScope;
begin
  if Assigned(FCurrent) then
    FCurrent.FScopeStack.Add(TScope.Create);
end;

class procedure TValidationContext.PopScope(const pKeep: Boolean);
var
  lPopped: TScope;
  lParent: TScope;
begin
  if not Assigned(FCurrent) or (FCurrent.FScopeStack.Count = 0) then
    Exit;

  lPopped := FCurrent.FScopeStack[FCurrent.FScopeStack.Count - 1];
  FCurrent.FScopeStack.Delete(FCurrent.FScopeStack.Count - 1);
  try
    if pKeep and (FCurrent.FScopeStack.Count > 0) then
    begin
      lParent := FCurrent.FScopeStack[FCurrent.FScopeStack.Count - 1];
      lParent.Merge(lPopped);
    end;
  finally
    lPopped.Free;
  end;
end;

function TValidationContext.GetCurrentScope: TScope;
begin
  if FScopeStack.Count > 0 then
    Result := FScopeStack[FScopeStack.Count - 1]
  else
    Result := nil;
end;

class procedure TValidationContext.MarkPropertyEvaluated(const pInstance: TJSONValue; const pProperty: string);
var
  lScope: TScope;
begin
  if Assigned(FCurrent) then
  begin
    lScope := FCurrent.GetCurrentScope;
    if Assigned(lScope) then
      lScope.MarkProperty(pInstance, pProperty);
  end;
end;

class procedure TValidationContext.MarkItemEvaluated(const pInstance: TJSONValue; const pIndex: Integer);
var
  lScope: TScope;
begin
  if Assigned(FCurrent) then
  begin
    lScope := FCurrent.GetCurrentScope;
    if Assigned(lScope) then
      lScope.MarkItem(pInstance, pIndex);
  end;
end;

class function TValidationContext.IsPropertyEvaluated(const pInstance: TJSONValue; const pProperty: string): Boolean;
var
  lScope: TScope;
begin
  Result := False;
  if Assigned(FCurrent) then
  begin
    lScope := FCurrent.GetCurrentScope;
    if Assigned(lScope) then
      Result := lScope.IsPropertyMarked(pInstance, pProperty);
  end;
end;

class function TValidationContext.IsItemEvaluated(const pInstance: TJSONValue; const pIndex: Integer): Boolean;
var
  lScope: TScope;
begin
  Result := False;
  if Assigned(FCurrent) then
  begin
    lScope := FCurrent.GetCurrentScope;
    if Assigned(lScope) then
      Result := lScope.IsItemMarked(pInstance, pIndex);
  end;
end;

class procedure TValidationContext.PushSchema(const pSchemaObj: TJSONObject; const pCompiled: ICompiledSchema;
  const pInstance: TJSONValue);
var
  lActive: TActiveSchema;
begin
  if not Assigned(FCurrent) then
    Exit;

  lActive.SchemaObj := pSchemaObj;
  lActive.Compiled := pCompiled;
  lActive.Instance := pInstance;
  FCurrent.FSchemaStack.Add(lActive);
end;

class procedure TValidationContext.PopSchema;
begin
  if not Assigned(FCurrent) or (FCurrent.FSchemaStack.Count = 0) then
    Exit;

  FCurrent.FSchemaStack.Delete(FCurrent.FSchemaStack.Count - 1);
end;

class function TValidationContext.ResolveRecursiveRef: ICompiledSchema;
var
  lIdx: Integer;
begin
  Result := nil;
  if not Assigned(FCurrent) then
    Exit;

  for lIdx := 0 to FCurrent.FSchemaStack.Count - 1 do
  begin
    if Assigned(FCurrent.FSchemaStack[lIdx].SchemaObj) and
       TSchemaRegistry.IsRecursiveAnchor(FCurrent.FSchemaStack[lIdx].SchemaObj) then
    begin
      Result := FCurrent.FSchemaStack[lIdx].Compiled;
      Break;
    end;
  end;
end;

class function TValidationContext.ResolveDynamicAnchor(const pAnchorName: string): TJSONObject;
var
  lIdx: Integer;
  lAncestorIdx: Integer;
  lActiveObj: TJSONObject;
  lURI: string;
  lBaseURI: string;
  lAnchorURI: string;
  lTargetVal: TJSONValue;
  lPair: TJSONPair;
begin
  Result := nil;
  if not Assigned(FCurrent) then
    Exit;

  for lIdx := 0 to FCurrent.FSchemaStack.Count - 1 do
  begin
    lURI := '';
    for lAncestorIdx := lIdx downto 0 do
    begin
      lActiveObj := FCurrent.FSchemaStack[lAncestorIdx].SchemaObj;
      if Assigned(lActiveObj) and TSchemaRegistry.GetSchemaURI(lActiveObj, lURI) then
        Break;
    end;

    if lURI <> '' then
    begin
      if lURI.Contains('#') then
        lBaseURI := lURI.Substring(0, lURI.IndexOf('#'))
      else
        lBaseURI := lURI;

      lAnchorURI := lBaseURI + '#' + pAnchorName;
      if TSchemaRegistry.FindSchema(lAnchorURI, lTargetVal) then
      begin
        if lTargetVal is TJSONObject then
        begin
          lPair := TJSONObject(lTargetVal).Get('$dynamicAnchor');
          if Assigned(lPair) and (lPair.JsonValue is TJSONString) and
             (lPair.JsonValue.Value = pAnchorName) then
          begin
            Result := TJSONObject(lTargetVal);
            Break;
          end;
        end;
      end;
    end;
  end;
end;

class function TValidationContext.IsCurrentlyValidating(const pSchemaObj: TJSONObject; const pInstance: TJSONValue): Boolean;
var
  lIdx: Integer;
begin
  Result := False;
  if not Assigned(FCurrent) then
    Exit;

  for lIdx := 0 to FCurrent.FSchemaStack.Count - 1 do
  begin
    if (FCurrent.FSchemaStack[lIdx].SchemaObj = pSchemaObj) and
       (FCurrent.FSchemaStack[lIdx].Instance = pInstance) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

end.
