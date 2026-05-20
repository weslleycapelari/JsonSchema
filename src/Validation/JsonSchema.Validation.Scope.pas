unit JsonSchema.Validation.Scope;

interface

uses
  System.Generics.Collections,
  System.JSON,
  JsonSchema.Visitors.Types;

type
  /// <summary>
  ///   Manages the scope stack during JSON Schema validation traversal.
  ///   Provides thread‑safe operations for pushing, popping, and querying scopes,
  ///   as well as tracking evaluated properties and covered items.
  /// </summary>
  TValidationScope = class
  private
    FScopeStack: TStack<TScope>;
    function GetCurrent(const pOffset: Integer): TScope;
    procedure SetCurrent(const pOffset: Integer; const pValue: TScope);
  public
    constructor Create(const pRootSchema, pRootData: TJSONValue; const pBaseURI: string);
    destructor Destroy; override;

    /// <summary>Pushes a new scope onto the stack.</summary>
    /// <returns>The newly pushed scope (caller may modify it).</returns>
    function Push(const pScope: TScope): TScope;

    /// <summary>Pops the top scope from the stack and returns it.</summary>
    function Pop: TScope;

    /// <summary>Returns the scope at the given offset (0 = top, 1 = parent, etc.).</summary>
    function Current(const pOffset: Integer = 0): TScope;

    /// <summary>Updates the scope at the given offset.</summary>
    procedure Update(const pScope: TScope; const pOffset: Integer = 0);

    /// <summary>Returns True if the stack is empty.</summary>
    function IsEmpty: Boolean;

    /// <summary>Returns the number of scopes on the stack.</summary>
    function Depth: Integer;

    /// <summary>Creates a new child scope based on the current scope for a sub‑schema.</summary>
    function CreateChildScope(const pSchemaNode: TJSONValue; const pInstanceNode: TJSONValue;
      const pSchemaPathSuffix, pInstancePathSuffix: string): TScope;
  end;

  /// <summary>
  ///   Tracks evaluated properties and covered items during validation.
  ///   Used by unevaluatedProperties and unevaluatedItems keywords.
  /// </summary>
  TEvaluatedTracker = class
  private
    FEvaluatedProperties: THashSet<string>;
    FCoveredProperties: TArray<string>;
    FCoveredItems: TArray<Integer>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddEvaluatedProperty(const pPropertyPath: string);
    procedure AddCoveredProperty(const pPropertyName: string);
    procedure AddCoveredItem(const pIndex: Integer);

    function GetEvaluatedProperties: TEnumerable<string>;
    function GetCoveredProperties: TArray<string>;
    function GetCoveredItems: TArray<Integer>;

    function HasEvaluatedProperty(const pPropertyPath: string): Boolean;
    function HasCoveredProperty(const pPropertyName: string): Boolean;
    function HasCoveredItem(const pIndex: Integer): Boolean;

    procedure Clear;
  end;

implementation

uses
  System.SysUtils,
  JsonSchema.Exceptions,
  JsonSchema.JsonPathUtils,
  JsonSchema.Common.Utils;

{ TValidationScope }

constructor TValidationScope.Create(const pRootSchema, pRootData: TJSONValue; const pBaseURI: string);
var
  lRootScope: TScope;
begin
  inherited Create;
  FScopeStack := TStack<TScope>.Create;

  lRootScope.BaseURI := pBaseURI;
  lRootScope.SchemaPath := '#';
  lRootScope.SchemaNode := pRootSchema;
  lRootScope.InstancePath := '#';
  lRootScope.InstanceNode := pRootData;
  lRootScope.CoveredItems := [];
  lRootScope.ContainsCount := 0;
  lRootScope.VisitedKeywords := [];
  lRootScope.CoveredProperties := [];
  lRootScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
  FScopeStack.Push(lRootScope);
end;

destructor TValidationScope.Destroy;
var
  lScope: TScope;
  lFreedSets: TList<THashSet<string>>;
begin
  lFreedSets := TList<THashSet<string>>.Create;
  try
    for lScope in FScopeStack do
      if Assigned(lScope.EvaluatedPropertiesInScope) and not lFreedSets.Contains(lScope.EvaluatedPropertiesInScope) then
      begin
        lFreedSets.Add(lScope.EvaluatedPropertiesInScope);
        lScope.EvaluatedPropertiesInScope.Free;
      end;
  finally
    lFreedSets.Free;
  end;
  FScopeStack.Free;
  inherited;
end;

function TValidationScope.GetCurrent(const pOffset: Integer): TScope;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not Assigned(FScopeStack) then
    raise EJsonSchemaError.Create('Validation scope stack is not initialized.');

  if (pOffset = 0) and (FScopeStack.Count = 0) then
    raise EJsonSchemaError.Create('Validation scope stack is empty: current scope is unavailable.');

  if FScopeStack.Count > pOffset then
    Result := FScopeStack.List[FScopeStack.Count - pOffset - 1];
end;

procedure TValidationScope.SetCurrent(const pOffset: Integer; const pValue: TScope);
begin
  if not Assigned(FScopeStack) then
    raise EJsonSchemaError.Create('Validation scope stack is not initialized.');

  if (pOffset = 0) and (FScopeStack.Count = 0) then
    raise EJsonSchemaError.Create('Validation scope stack is empty: cannot update current scope.');

  if FScopeStack.Count > pOffset then
    FScopeStack.List[FScopeStack.Count - pOffset - 1] := pValue;
end;

function TValidationScope.Push(const pScope: TScope): TScope;
var
  lScope: TScope;
begin
  lScope := pScope;

  // Ensure EvaluatedPropertiesInScope is not accidentally shared
  if (FScopeStack.Count > 0) and Assigned(Current(0).EvaluatedPropertiesInScope) and
     (lScope.EvaluatedPropertiesInScope = Current(0).EvaluatedPropertiesInScope) then
    lScope.EvaluatedPropertiesInScope := THashSet<string>.Create
  else if not Assigned(lScope.EvaluatedPropertiesInScope) then
    lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

  FScopeStack.Push(lScope);
  Result := lScope;
end;

function TValidationScope.Pop: TScope;
begin
  if not Assigned(FScopeStack) or (FScopeStack.Count = 0) then
    raise EJsonSchemaError.Create('Validation scope stack underflow: cannot pop from an empty scope stack.');

  Result := FScopeStack.Pop;
end;

function TValidationScope.Current(const pOffset: Integer): TScope;
begin
  Result := GetCurrent(pOffset);
end;

procedure TValidationScope.Update(const pScope: TScope; const pOffset: Integer);
begin
  SetCurrent(pOffset, pScope);
end;

function TValidationScope.IsEmpty: Boolean;
begin
  Result := FScopeStack.Count = 0;
end;

function TValidationScope.Depth: Integer;
begin
  Result := FScopeStack.Count;
end;

function TValidationScope.CreateChildScope(const pSchemaNode: TJSONValue;
  const pInstanceNode: TJSONValue; const pSchemaPathSuffix, pInstancePathSuffix: string): TScope;
var
  lParent: TScope;
begin
  lParent := Current(0);
  Result := lParent;
  Result.SchemaNode := pSchemaNode;
  Result.InstanceNode := pInstanceNode;

  if pSchemaPathSuffix <> '' then
    Result.SchemaPath := TJsonPathUtils.JoinPath(lParent.SchemaPath, pSchemaPathSuffix);
  if pInstancePathSuffix <> '' then
    Result.InstancePath := TJsonPathUtils.JoinPath(lParent.InstancePath, pInstancePathSuffix);

  Result.CoveredItems := [];
  Result.ContainsCount := 0;
  Result.VisitedKeywords := [];
  Result.CoveredProperties := [];
  Result.EvaluatedPropertiesInScope := nil; // Will be created in Push
end;

{ TEvaluatedTracker }

constructor TEvaluatedTracker.Create;
begin
  inherited Create;
  FEvaluatedProperties := THashSet<string>.Create;
  FCoveredProperties := [];
  FCoveredItems := [];
end;

destructor TEvaluatedTracker.Destroy;
begin
  FEvaluatedProperties.Free;
  inherited;
end;

procedure TEvaluatedTracker.AddEvaluatedProperty(const pPropertyPath: string);
begin
  if not pPropertyPath.IsEmpty then
    FEvaluatedProperties.Add(TJsonPathUtils.NormalizeToCanonical(pPropertyPath));
end;

procedure TEvaluatedTracker.AddCoveredProperty(const pPropertyName: string);
begin
  TUtils.AddArray<string>(FCoveredProperties, pPropertyName);
end;

procedure TEvaluatedTracker.AddCoveredItem(const pIndex: Integer);
begin
  TUtils.AddArray<Integer>(FCoveredItems, pIndex);
end;

function TEvaluatedTracker.GetEvaluatedProperties: TEnumerable<string>;
begin
  Result := FEvaluatedProperties;
end;

function TEvaluatedTracker.GetCoveredProperties: TArray<string>;
begin
  Result := FCoveredProperties;
end;

function TEvaluatedTracker.GetCoveredItems: TArray<Integer>;
begin
  Result := FCoveredItems;
end;

function TEvaluatedTracker.HasEvaluatedProperty(const pPropertyPath: string): Boolean;
begin
  Result := FEvaluatedProperties.Contains(TJsonPathUtils.NormalizeToCanonical(pPropertyPath));
end;

function TEvaluatedTracker.HasCoveredProperty(const pPropertyName: string): Boolean;
var
  lProp: string;
begin
  for lProp in FCoveredProperties do
    if lProp = pPropertyName then
      Exit(True);
  Result := False;
end;

function TEvaluatedTracker.HasCoveredItem(const pIndex: Integer): Boolean;
var
  lItem: Integer;
begin
  for lItem in FCoveredItems do
    if lItem = pIndex then
      Exit(True);
  Result := False;
end;

procedure TEvaluatedTracker.Clear;
begin
  FEvaluatedProperties.Clear;
  FCoveredProperties := [];
  FCoveredItems := [];
end;

end.
