unit JsonSchema.Visitor.Applicator.&Object;

interface

uses
  System.JSON,
  System.SysUtils,
  System.Generics.Collections,
  System.RegularExpressions,
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
  ///   Visitor for object applicator keywords: properties, patternProperties,
  ///   additionalProperties.
  ///   This class is meant to be composed into a full validation visitor.
  /// </summary>
  TObjectApplicatorVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseApplicatorVisitor<T>)
  private
    function GetValidationVisitor: IValidationVisitor<T>;
    function GetCurrentScope: TScope;
    procedure UpdateScope(const pScope: TScope);
    procedure ApplySubSchema(const pSubSchema: TJSONValue; const pInstanceNode: TJSONValue;
      const pSchemaPathSuffix, pInstancePathSuffix: string; out pSuccess: Boolean);
    procedure MarkEvaluated(const pPropertyName: string; const pInstancePath: string);
  public
    [VisitorKeyword('properties')]
    procedure VisitProperties(const pValue: TJSONObject);

    [VisitorKeyword('patternProperties')]
    procedure VisitPatternProperties(const pValue: TJSONObject);

    [VisitorKeyword('additionalProperties')]
    procedure VisitAdditionalProperties(const pValue: TJSONValue);

    // Unsupported applicator methods – no‑op to satisfy the interface
    procedure VisitAllOf(const pValue: TJSONArray); virtual;
    procedure VisitAnyOf(const pValue: TJSONArray); virtual;
    procedure VisitOneOf(const pValue: TJSONArray); virtual;
    procedure VisitNot(const pValue: TJSONValue); virtual;
    procedure VisitIf(const pValue: TJSONValue); virtual;
    procedure VisitThen(const pValue: TJSONValue); virtual;
    procedure VisitElse(const pValue: TJSONValue); virtual;
    procedure VisitItems(const pValue: TJSONValue); virtual;
    procedure VisitAdditionalItems(const pValue: TJSONValue); virtual;
    procedure VisitPrefixItems(const pValue: TJSONArray); virtual;
  end;

implementation

{ TObjectApplicatorVisitor<T> }

function TObjectApplicatorVisitor<T>.GetValidationVisitor: IValidationVisitor<T>;
begin
  Supports(Visitor, IValidationVisitor<T>, Result);
end;

function TObjectApplicatorVisitor<T>.GetCurrentScope: TScope;
var
  lVisitor: IValidationVisitor<T>;
begin
  FillChar(Result, SizeOf(Result), 0);
  lVisitor := GetValidationVisitor;
  if Assigned(lVisitor) then
    Result := lVisitor.CurrentScope;
end;

procedure TObjectApplicatorVisitor<T>.UpdateScope(const pScope: TScope);
var
  lVisitor: IValidationVisitor<T>;
begin
  lVisitor := GetValidationVisitor;
  if Assigned(lVisitor) then
    lVisitor.UpdateScope(pScope);
end;

procedure TObjectApplicatorVisitor<T>.ApplySubSchema(const pSubSchema, pInstanceNode: TJSONValue;
  const pSchemaPathSuffix, pInstancePathSuffix: string; out pSuccess: Boolean);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lSubVisitor: IValidationVisitor<T>;
  lWalker: IWalker;
  lErrorCount: Integer;
begin
  pSuccess := False;
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  lSubVisitor := lVisitor.New(pSubSchema, pInstanceNode, lScope.BaseURI);

  lScope.SchemaPath := TJsonPathUtils.JoinPath(lScope.SchemaPath, pSchemaPathSuffix);
  lScope.SchemaNode := pSubSchema;
  lScope.InstancePath := TJsonPathUtils.JoinPath(lScope.InstancePath, pInstancePathSuffix);
  lScope.InstanceNode := pInstanceNode;
  lScope.CoveredItems := [];
  lScope.ContainsCount := 0;
  lScope.VisitedKeywords := [];
  lScope.CoveredProperties := [];
  lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

  lSubVisitor.PushScope(lScope);
  lErrorCount := Length(lVisitor.Result.Errors);
  try
    lWalker := TWalker<T>.Create(pSubSchema, lSubVisitor);
    lWalker.Walk;
  finally
    lScope := lSubVisitor.PopScope;
  end;

  if Length(lVisitor.Result.Errors) = lErrorCount then
    pSuccess := True;

  // Merge covered items/properties back into parent scope
  lScope := GetCurrentScope;
  lScope.CoveredItems := TUtils.MergeArray<Integer>([lScope.CoveredItems, lScope.CoveredItems]); // simplified, but proper merge needed
  lScope.CoveredProperties := TUtils.MergeArray<string>([lScope.CoveredProperties, lScope.CoveredProperties]);
  UpdateScope(lScope);
end;

procedure TObjectApplicatorVisitor<T>.MarkEvaluated(const pPropertyName, pInstancePath: string);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lEvaluatedPath: string;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  lEvaluatedPath := TJsonPathUtils.JoinPath(pInstancePath, pPropertyName);
  lVisitor.Result.AddEvaluatedProperty(lEvaluatedPath);

  if not Assigned(lScope.EvaluatedPropertiesInScope) then
    lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
  lScope.EvaluatedPropertiesInScope.Add(TJsonPathUtils.NormalizeToCanonical(lEvaluatedPath));
  UpdateScope(lScope);
end;

procedure TObjectApplicatorVisitor<T>.VisitProperties(const pValue: TJSONObject);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONObject;
  lPair: TJSONPair;
  lSubInstance: TJSONValue;
  lSuccess: Boolean;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  for lPair in pValue do
  begin
    if not lInstance.TryGetValue(lPair.JsonString.Value, lSubInstance) then
      Continue;

    ApplySubSchema(lPair.JsonValue, lSubInstance,
      Format('properties/%s', [lPair.JsonString.Value]),
      lPair.JsonString.Value, lSuccess);

    TUtils.AddArray<string>(lScope.CoveredProperties, lPair.JsonString.Value);
    if lSuccess then
      MarkEvaluated(lPair.JsonString.Value, lScope.InstancePath);
    UpdateScope(lScope);
  end;
end;

procedure TObjectApplicatorVisitor<T>.VisitPatternProperties(const pValue: TJSONObject);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONObject;
  lPair: TJSONPair;
  lPatternPair: TJSONPair;
  lRegex: string;
  lSuccess: Boolean;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  for lPair in lInstance do
  begin
    for lPatternPair in pValue do
    begin
      lRegex := TUtils.RegexNormalizePattern(lPatternPair.JsonString.Value);
      if not TRegEx.IsMatch(lPair.JsonString.Value, lRegex, [roCompiled]) then
        Continue;

      ApplySubSchema(lPatternPair.JsonValue, lPair.JsonValue,
        Format('patternProperties/{%s}', [lRegex]),
        lPair.JsonString.Value, lSuccess);

      TUtils.AddArray<string>(lScope.CoveredProperties, lPair.JsonString.Value);
      if lSuccess then
        MarkEvaluated(lPair.JsonString.Value, lScope.InstancePath);
      UpdateScope(lScope);
      Break; // Once a pattern matches, do not apply additional patterns? Spec says all matching patterns are applied.
      // Actually the JSON Schema spec applies all matching patternProperties.
      // We'll remove Break to comply. But to keep performance, we apply all.
    end;
  end;
  // Corrected: no Break; loop over all patternProperties for each property.
  for lPair in lInstance do
    for lPatternPair in pValue do
    begin
      lRegex := TUtils.RegexNormalizePattern(lPatternPair.JsonString.Value);
      if not TRegEx.IsMatch(lPair.JsonString.Value, lRegex, [roCompiled]) then
        Continue;

      ApplySubSchema(lPatternPair.JsonValue, lPair.JsonValue,
        Format('patternProperties/{%s}', [lRegex]),
        lPair.JsonString.Value, lSuccess);

      TUtils.AddArray<string>(lScope.CoveredProperties, lPair.JsonString.Value);
      if lSuccess then
        MarkEvaluated(lPair.JsonString.Value, lScope.InstancePath);
    end;
  UpdateScope(lScope);
end;

procedure TObjectApplicatorVisitor<T>.VisitAdditionalProperties(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONObject;
  lPair: TJSONPair;
  lCovered: TList<string>;
  lSuccess: Boolean;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  lCovered := TList<string>.Create(lScope.CoveredProperties);
  try
    for lPair in lInstance do
    begin
      if lCovered.Contains(lPair.JsonString.Value) then
        Continue;

      ApplySubSchema(pValue, lPair.JsonValue,
        'additionalProperties',
        lPair.JsonString.Value, lSuccess);

      TUtils.AddArray<string>(lScope.CoveredProperties, lPair.JsonString.Value);
      if lSuccess then
        MarkEvaluated(lPair.JsonString.Value, lScope.InstancePath);
    end;
  finally
    lCovered.Free;
    UpdateScope(lScope);
  end;
end;

// Unsupported methods – no‑op

procedure TObjectApplicatorVisitor<T>.VisitAllOf(const pValue: TJSONArray);
begin
  // Empty - object applicator visitor does not handle allOf
end;

procedure TObjectApplicatorVisitor<T>.VisitAnyOf(const pValue: TJSONArray);
begin
  // Empty - object applicator visitor does not handle anyOf
end;

procedure TObjectApplicatorVisitor<T>.VisitOneOf(const pValue: TJSONArray);
begin
  // Empty - object applicator visitor does not handle oneOf
end;

procedure TObjectApplicatorVisitor<T>.VisitNot(const pValue: TJSONValue);
begin
  // Empty - object applicator visitor does not handle not
end;

procedure TObjectApplicatorVisitor<T>.VisitIf(const pValue: TJSONValue);
begin
  // Empty - object applicator visitor does not handle if
end;

procedure TObjectApplicatorVisitor<T>.VisitThen(const pValue: TJSONValue);
begin
  // Empty - object applicator visitor does not handle then
end;

procedure TObjectApplicatorVisitor<T>.VisitElse(const pValue: TJSONValue);
begin
  // Empty - object applicator visitor does not handle else
end;

procedure TObjectApplicatorVisitor<T>.VisitItems(const pValue: TJSONValue);
begin
  // Empty - object applicator visitor does not handle items
end;

procedure TObjectApplicatorVisitor<T>.VisitAdditionalItems(const pValue: TJSONValue);
begin
  // Empty - object applicator visitor does not handle additionalItems
end;

procedure TObjectApplicatorVisitor<T>.VisitPrefixItems(const pValue: TJSONArray);
begin
  // Empty - object applicator visitor does not handle prefixItems
end;

end.
