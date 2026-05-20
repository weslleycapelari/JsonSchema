unit JsonSchema.Visitor.Applicator.Base;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Common.Utils,
  JsonSchema.JsonPathUtils,
  JsonSchema.Walker,
  JsonSchema.Walker.Types;

type
  /// <summary>
  ///   Base visitor that handles common applicator functionality:
  ///   evaluating sub‑schemas, merging scopes, and providing default no‑op
  ///   implementations for all applicator keywords.
  ///   Concrete applicator visitors should inherit from this class and
  ///   override only the methods they need.
  /// </summary>
  TBaseApplicatorVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseApplicatorVisitor<T>)
  protected
    /// <summary>
    ///   Evaluates a sub‑schema against the current instance (or a different instance node).
    ///   Creates a child visitor, walks the schema, and returns the sub‑scope after evaluation.
    ///   Returns True if the sub‑schema validation succeeded.
    /// </summary>
    function EvaluateSubSchema(const pSubSchema: TJSONValue; const pInstanceNode: TJSONValue;
      const pSchemaPathSuffix, pInstancePathSuffix: string; out pSubScope: TScope): Boolean; overload;

    /// <summary>
    ///   Evaluates a sub‑schema against the current instance node, using the current instance path.
    ///   Simplified version of the above.
    /// </summary>
    function EvaluateSubSchema(const pSubSchema: TJSONValue; const pSchemaPathSuffix: string;
      out pSubScope: TScope): Boolean; overload;

    /// <summary>
    ///   Merges a sub‑scope (from a sub‑validation) back into a parent scope.
    ///   Combines CoveredItems, CoveredProperties, and EvaluatedPropertiesInScope.
    /// </summary>
    procedure MergeSubScope(const pSubScope: TScope; var pParentScope: TScope);

    /// <summary>
    ///   Adds a property to the evaluated set of the current scope and to the global result.
    /// </summary>
    procedure MarkEvaluatedProperty(const pPropertyPath: string);

    /// <summary>
    ///   Adds an item index to the covered items of the current scope.
    /// </summary>
    procedure MarkCoveredItem(const pIndex: Integer);

    /// <summary>
    ///   Adds a property name to the covered properties of the current scope.
    /// </summary>
    procedure MarkCoveredProperty(const pPropertyName: string);
  public
    // All applicator keywords – default implementation is no‑op.
    // Concrete subclasses override as needed.

    [VisitorKeyword('allOf')]
    procedure VisitAllOf(const pValue: TJSONArray); virtual;

    [VisitorKeyword('anyOf')]
    procedure VisitAnyOf(const pValue: TJSONArray); virtual;

    [VisitorKeyword('oneOf')]
    procedure VisitOneOf(const pValue: TJSONArray); virtual;

    [VisitorKeyword('not')]
    procedure VisitNot(const pValue: TJSONValue); virtual;

    [VisitorKeyword('if')]
    procedure VisitIf(const pValue: TJSONValue); virtual;

    [VisitorKeyword('then')]
    procedure VisitThen(const pValue: TJSONValue); virtual;

    [VisitorKeyword('else')]
    procedure VisitElse(const pValue: TJSONValue); virtual;

    [VisitorKeyword('properties')]
    procedure VisitProperties(const pValue: TJSONObject); virtual;

    [VisitorKeyword('patternProperties')]
    procedure VisitPatternProperties(const pValue: TJSONObject); virtual;

    [VisitorKeyword('additionalProperties')]
    procedure VisitAdditionalProperties(const pValue: TJSONValue); virtual;

    [VisitorKeyword('items')]
    procedure VisitItems(const pValue: TJSONValue); virtual;

    [VisitorKeyword('additionalItems')]
    procedure VisitAdditionalItems(const pValue: TJSONValue); virtual;

    [VisitorKeyword('prefixItems')]
    procedure VisitPrefixItems(const pValue: TJSONArray); virtual;
  end;

implementation

uses
  System.SysUtils;

{ TBaseApplicatorVisitor<T> }

function TBaseApplicatorVisitor<T>.EvaluateSubSchema(const pSubSchema, pInstanceNode: TJSONValue;
  const pSchemaPathSuffix, pInstancePathSuffix: string; out pSubScope: TScope): Boolean;
var
  lVisitor: IValidationVisitor<T>;
  lParentScope: TScope;
  lSubVisitor: IValidationVisitor<T>;
  lWalker: IWalker;
begin
  Result := False;
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lParentScope := GetCurrentScope;
  pSubScope := lParentScope;
  pSubScope.SchemaNode := pSubSchema;
  pSubScope.SchemaPath := TJsonPathUtils.JoinPath(lParentScope.SchemaPath, pSchemaPathSuffix);
  pSubScope.InstanceNode := pInstanceNode;
  pSubScope.InstancePath := TJsonPathUtils.JoinPath(lParentScope.InstancePath, pInstancePathSuffix);
  pSubScope.CoveredItems := [];
  pSubScope.ContainsCount := 0;
  pSubScope.VisitedKeywords := [];
  pSubScope.CoveredProperties := [];
  pSubScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

  lSubVisitor := lVisitor.New(pSubSchema, pInstanceNode, lParentScope.BaseURI);
  lSubVisitor.PushScope(pSubScope);
  try
    lWalker := TWalker<T>.Create(pSubSchema, lSubVisitor);
    lWalker.Walk;
    Result := lSubVisitor.Result.IsValid;
  finally
    pSubScope := lSubVisitor.PopScope;
  end;
end;

function TBaseApplicatorVisitor<T>.EvaluateSubSchema(const pSubSchema: TJSONValue;
  const pSchemaPathSuffix: string; out pSubScope: TScope): Boolean;
var
  lParentScope: TScope;
begin
  lParentScope := GetCurrentScope;
  Result := EvaluateSubSchema(pSubSchema, lParentScope.InstanceNode,
    pSchemaPathSuffix, '', pSubScope);
end;

procedure TBaseApplicatorVisitor<T>.MergeSubScope(const pSubScope: TScope; var pParentScope: TScope);
begin
  pParentScope.CoveredItems := TUtils.MergeArray<Integer>([pParentScope.CoveredItems, pSubScope.CoveredItems]);
  pParentScope.CoveredProperties := TUtils.MergeArray<string>([pParentScope.CoveredProperties, pSubScope.CoveredProperties]);

  if Assigned(pSubScope.EvaluatedPropertiesInScope) then
  begin
    if not Assigned(pParentScope.EvaluatedPropertiesInScope) then
      pParentScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
    for var lProp in pSubScope.EvaluatedPropertiesInScope do
      pParentScope.EvaluatedPropertiesInScope.Add(lProp);
  end;
end;

procedure TBaseApplicatorVisitor<T>.MarkEvaluatedProperty(const pPropertyPath: string);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lCanonicalPath: string;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  lCanonicalPath := TJsonPathUtils.NormalizeToCanonical(pPropertyPath);
  lVisitor.Result.AddEvaluatedProperty(lCanonicalPath);
  if not Assigned(lScope.EvaluatedPropertiesInScope) then
    lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
  lScope.EvaluatedPropertiesInScope.Add(lCanonicalPath);
  UpdateScope(lScope);
end;

procedure TBaseApplicatorVisitor<T>.MarkCoveredItem(const pIndex: Integer);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  TUtils.AddArray<Integer>(lScope.CoveredItems, pIndex);
  UpdateScope(lScope);
end;

procedure TBaseApplicatorVisitor<T>.MarkCoveredProperty(const pPropertyName: string);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  TUtils.AddArray<string>(lScope.CoveredProperties, pPropertyName);
  UpdateScope(lScope);
end;

// Default no‑op implementations

procedure TBaseApplicatorVisitor<T>.VisitAllOf(const pValue: TJSONArray);
begin
  // Empty - applicator visitors override as needed
end;

procedure TBaseApplicatorVisitor<T>.VisitAnyOf(const pValue: TJSONArray);
begin
  // Empty - applicator visitors override as needed
end;

procedure TBaseApplicatorVisitor<T>.VisitOneOf(const pValue: TJSONArray);
begin
  // Empty - applicator visitors override as needed
end;

procedure TBaseApplicatorVisitor<T>.VisitNot(const pValue: TJSONValue);
begin
  // Empty - applicator visitors override as needed
end;

procedure TBaseApplicatorVisitor<T>.VisitIf(const pValue: TJSONValue);
begin
  // Empty - applicator visitors override as needed
end;

procedure TBaseApplicatorVisitor<T>.VisitThen(const pValue: TJSONValue);
begin
  // Empty - applicator visitors override as needed
end;

procedure TBaseApplicatorVisitor<T>.VisitElse(const pValue: TJSONValue);
begin
  // Empty - applicator visitors override as needed
end;

procedure TBaseApplicatorVisitor<T>.VisitProperties(const pValue: TJSONObject);
begin
  // Empty - applicator visitors override as needed
end;

procedure TBaseApplicatorVisitor<T>.VisitPatternProperties(const pValue: TJSONObject);
begin
  // Empty - applicator visitors override as needed
end;

procedure TBaseApplicatorVisitor<T>.VisitAdditionalProperties(const pValue: TJSONValue);
begin
  // Empty - applicator visitors override as needed
end;

procedure TBaseApplicatorVisitor<T>.VisitItems(const pValue: TJSONValue);
begin
  // Empty - applicator visitors override as needed
end;

procedure TBaseApplicatorVisitor<T>.VisitAdditionalItems(const pValue: TJSONValue);
begin
  // Empty - applicator visitors override as needed
end;

procedure TBaseApplicatorVisitor<T>.VisitPrefixItems(const pValue: TJSONArray);
begin
  // Empty - applicator visitors override as needed
end;

end.
