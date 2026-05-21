unit JsonSchema.Visitor.Applicator.Evaluated;

interface

uses
  System.JSON,
  System.SysUtils,
  System.Generics.Collections,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Common.Utils,
  JsonSchema.JsonPathUtils,
  JsonSchema.Walker,
  JsonSchema.Walker.Types,
  JsonSchema.Types;

type
  /// <summary>
  ///   Visitor for keywords that depend on already evaluated properties and items:
  ///   unevaluatedProperties, unevaluatedItems.
  ///   This implementation is shared between Draft 2019‑09 and Draft 2020‑12,
  ///   parametrised by a normalisation function.
  /// </summary>
  TEvaluatedApplicatorVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseApplicatorVisitor<T>)
  private
    FNormalizePath: TFunc<string, string>;
    function GetValidationVisitor: IValidationVisitor<T>;
    function BuildEvaluatedSet(const pScope: TScope): THashSet<string>;
    function NormalizePath(const pPath: string): string;
  public
    /// <summary>
    ///   Creates the visitor. The pNormalizePath parameter allows different drafts
    ///   to use their own path normalisation logic (e.g., TDraft2020_12 uses
    ///   NormalizeToFullInstancePath, while Draft 2019‑09 may use a simpler one).
    ///   If nil, defaults to TJsonPathUtils.NormalizeToCanonical.
    /// </summary>
    constructor Create(pVisitor: T; const pNormalizePath: TFunc<string, string> = nil);
    destructor Destroy; override;

    [VisitorKeyword('unevaluatedProperties')]
    procedure VisitUnevaluatedProperties(const pValue: TJSONValue);

    [VisitorKeyword('unevaluatedItems')]
    procedure VisitUnevaluatedItems(const pValue: TJSONValue);

    // Unsupported applicator methods – no‑op to satisfy the interface
    procedure VisitAllOf(const pValue: TJSONArray); virtual;
    procedure VisitAnyOf(const pValue: TJSONArray); virtual;
    procedure VisitOneOf(const pValue: TJSONArray); virtual;
    procedure VisitNot(const pValue: TJSONValue); virtual;
    procedure VisitIf(const pValue: TJSONValue); virtual;
    procedure VisitThen(const pValue: TJSONValue); virtual;
    procedure VisitElse(const pValue: TJSONValue); virtual;
    procedure VisitProperties(const pValue: TJSONObject); virtual;
    procedure VisitPatternProperties(const pValue: TJSONObject); virtual;
    procedure VisitAdditionalProperties(const pValue: TJSONValue); virtual;
    procedure VisitItems(const pValue: TJSONValue); virtual;
    procedure VisitAdditionalItems(const pValue: TJSONValue); virtual;
    procedure VisitPrefixItems(const pValue: TJSONArray); virtual;
  end;

implementation

uses
  System.Math;

{ TEvaluatedApplicatorVisitor<T> }

constructor TEvaluatedApplicatorVisitor<T>.Create(pVisitor: T;
  const pNormalizePath: TFunc<string, string>);
begin
  inherited Create(pVisitor);
  FNormalizePath := pNormalizePath;
end;

destructor TEvaluatedApplicatorVisitor<T>.Destroy;
begin
  inherited;
end;

function TEvaluatedApplicatorVisitor<T>.GetValidationVisitor: IValidationVisitor<T>;
begin
  Supports(Visitor, IValidationVisitor<T>, Result);
end;

function TEvaluatedApplicatorVisitor<T>.NormalizePath(const pPath: string): string;
begin
  if Assigned(FNormalizePath) then
    Result := FNormalizePath(pPath)
  else
    Result := TJsonPathUtils.NormalizeToCanonical(pPath);
end;

function TEvaluatedApplicatorVisitor<T>.BuildEvaluatedSet(const pScope: TScope): THashSet<string>;
var
  lVisitor: IValidationVisitor<T>;
  lCanonicalBase: string;
  lEvaluatedProp: string;
  lCoveredProp: string;
  lCoveredIdx: Integer;
begin
  Result := THashSet<string>.Create;
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lCanonicalBase := NormalizePath(pScope.InstancePath);
  if not lCanonicalBase.EndsWith('/') and (lCanonicalBase <> '/') then
    lCanonicalBase := lCanonicalBase + '/';

  for lEvaluatedProp in lVisitor.Result.EvaluatedProperties do
    Result.Add(NormalizePath(lEvaluatedProp));

  for lCoveredProp in pScope.CoveredProperties do
    Result.Add(lCanonicalBase + lCoveredProp);

  for lCoveredIdx in pScope.CoveredItems do
    Result.Add(lCanonicalBase + lCoveredIdx.ToString);
end;

procedure TEvaluatedApplicatorVisitor<T>.VisitUnevaluatedProperties(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONObject;
  lEvaluated: THashSet<string>;
  lPair: TJSONPair;
  lPropKey: string;
  lCanonicalPrefix: string;
  lWalker: IWalker;
  lNewScope: TScope;
  lErrorCount: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  // Boolean shortcut: true means all remaining properties are allowed
  if (pValue is TJSONBool) and TJSONBool(pValue).AsBoolean then
  begin
    lCanonicalPrefix := NormalizePath(lScope.InstancePath);
    if not lCanonicalPrefix.EndsWith('/') then
      lCanonicalPrefix := lCanonicalPrefix + '/';

    if not Assigned(lScope.EvaluatedPropertiesInScope) then
      lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

    lInstance := TJSONObject(lScope.InstanceNode);
    for lPair in lInstance do
    begin
      lPropKey := lCanonicalPrefix + lPair.JsonString.Value;
      TUtils.AddArray<string>(lScope.CoveredProperties, lPair.JsonString.Value);
      lScope.EvaluatedPropertiesInScope.Add(lPropKey);
      lVisitor.Result.AddEvaluatedProperty(lPropKey);
    end;
    lVisitor.UpdateScope(lScope);
    Exit;
  end;

  lEvaluated := BuildEvaluatedSet(lScope);
  try
    lCanonicalPrefix := NormalizePath(lScope.InstancePath);
    if not lCanonicalPrefix.EndsWith('/') then
      lCanonicalPrefix := lCanonicalPrefix + '/';

    lInstance := TJSONObject(lScope.InstanceNode);
    for lPair in lInstance do
    begin
      lPropKey := lCanonicalPrefix + lPair.JsonString.Value;
      if lEvaluated.Contains(lPropKey) then
        Continue;

      lNewScope := lScope;
      lNewScope.SchemaPath := Format('%s/unevaluatedProperties', [lScope.SchemaPath]);
      lNewScope.SchemaNode := pValue;
      lNewScope.InstanceNode := lPair.JsonValue;
      lNewScope.InstancePath := TJsonPathUtils.JoinPath(lScope.InstancePath, lPair.JsonString.Value);
      lNewScope.CoveredItems := [];
      lNewScope.ContainsCount := 0;
      lNewScope.VisitedKeywords := [];
      lNewScope.CoveredProperties := [];
      lNewScope.EvaluatedPropertiesInScope := nil;

      lVisitor.PushScope(lNewScope);
      lErrorCount := Length(lVisitor.Result.Errors);
      try
        lWalker := TWalker<T>.Create(pValue, lVisitor);
        lWalker.Walk;
      finally
        lNewScope := lVisitor.PopScope;
      end;

      if Length(lVisitor.Result.Errors) > lErrorCount then
        lVisitor.AddError(TErrorType.vetUnevaluatedProperties, [lPair.JsonString.Value])
      else
      begin
        TUtils.AddArray<string>(lScope.CoveredProperties, lPair.JsonString.Value);
        if not Assigned(lScope.EvaluatedPropertiesInScope) then
          lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
        lScope.EvaluatedPropertiesInScope.Add(lPropKey);
        lVisitor.Result.AddEvaluatedProperty(lPropKey);
      end;
    end;
  finally
    lEvaluated.Free;
    lVisitor.UpdateScope(lScope);
  end;
end;

procedure TEvaluatedApplicatorVisitor<T>.VisitUnevaluatedItems(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONArray;
  lEvaluated: THashSet<string>;
  lCount: Integer;
  lItemPath: string;
  lCanonicalPrefix: string;
  lNewScope: TScope;
  lWalker: IWalker;
  lErrorCount: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  // Boolean shortcut: true means all remaining items are allowed
  if (pValue is TJSONBool) and TJSONBool(pValue).AsBoolean then
  begin
    lCanonicalPrefix := NormalizePath(lScope.InstancePath);
    if not lCanonicalPrefix.EndsWith('/') then
      lCanonicalPrefix := lCanonicalPrefix + '/';

    lInstance := TJSONArray(lScope.InstanceNode);
    for lCount := 0 to lInstance.Count - 1 do
    begin
      TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
      lItemPath := lCanonicalPrefix + lCount.ToString;
      lVisitor.Result.AddEvaluatedProperty(lItemPath);
    end;
    lVisitor.UpdateScope(lScope);
    Exit;
  end;

  lEvaluated := BuildEvaluatedSet(lScope);
  try
    lCanonicalPrefix := NormalizePath(lScope.InstancePath);
    if not lCanonicalPrefix.EndsWith('/') then
      lCanonicalPrefix := lCanonicalPrefix + '/';

    lInstance := TJSONArray(lScope.InstanceNode);
    for lCount := 0 to lInstance.Count - 1 do
    begin
      lItemPath := lCanonicalPrefix + lCount.ToString;
      if lEvaluated.Contains(lItemPath) then
        Continue;

      lNewScope := lScope;
      lNewScope.SchemaPath := Format('%s/unevaluatedItems', [lScope.SchemaPath]);
      lNewScope.SchemaNode := pValue;
      lNewScope.InstanceNode := lInstance.Items[lCount];
      lNewScope.InstancePath := TJsonPathUtils.JoinPath(lScope.InstancePath, lCount.ToString);
      lNewScope.CoveredItems := [];
      lNewScope.ContainsCount := 0;
      lNewScope.VisitedKeywords := [];
      lNewScope.CoveredProperties := [];
      lNewScope.EvaluatedPropertiesInScope := nil;

      lVisitor.PushScope(lNewScope);
      lErrorCount := Length(lVisitor.Result.Errors);
      try
        lWalker := TWalker<T>.Create(pValue, lVisitor);
        lWalker.Walk;
      finally
        lNewScope := lVisitor.PopScope;
      end;

      if Length(lVisitor.Result.Errors) > lErrorCount then
        lVisitor.AddError(TErrorType.vetUnevaluatedItems, [lCount])
      else
      begin
        TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
        lVisitor.Result.AddEvaluatedProperty(lItemPath);
      end;
    end;
  finally
    lEvaluated.Free;
    lVisitor.UpdateScope(lScope);
  end;
end;

// No‑op stubs for unsupported applicator methods

procedure TEvaluatedApplicatorVisitor<T>.VisitAllOf(const pValue: TJSONArray);
begin
  // Empty - this visitor does not handle allOf, but it must be declared to satisfy the interface
end;

procedure TEvaluatedApplicatorVisitor<T>.VisitAnyOf(const pValue: TJSONArray);
begin
  // Empty - this visitor does not handle anyOf, but it must be declared to satisfy the interface
end;

procedure TEvaluatedApplicatorVisitor<T>.VisitOneOf(const pValue: TJSONArray);
begin
  // Empty - this visitor does not handle oneOf, but it must be declared to satisfy the interface
end;

procedure TEvaluatedApplicatorVisitor<T>.VisitNot(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle not, but it must be declared to satisfy the interface
end;

procedure TEvaluatedApplicatorVisitor<T>.VisitIf(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle if, but it must be declared to satisfy the interface
end;

procedure TEvaluatedApplicatorVisitor<T>.VisitThen(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle then, but it must be declared to satisfy the interface
end;

procedure TEvaluatedApplicatorVisitor<T>.VisitElse(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle else, but it must be declared to satisfy the interface
end;

procedure TEvaluatedApplicatorVisitor<T>.VisitProperties(const pValue: TJSONObject);
begin
  // Empty - this visitor does not handle properties, but it must be declared to satisfy the interface
end;

procedure TEvaluatedApplicatorVisitor<T>.VisitPatternProperties(const pValue: TJSONObject);
begin
  // Empty - this visitor does not handle patternProperties, but it must be declared to satisfy the interface
end;

procedure TEvaluatedApplicatorVisitor<T>.VisitAdditionalProperties(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle additionalProperties, but it must be declared to satisfy the interface
end;

procedure TEvaluatedApplicatorVisitor<T>.VisitItems(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle items, but it must be declared to satisfy the interface
end;

procedure TEvaluatedApplicatorVisitor<T>.VisitAdditionalItems(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle additionalItems, but it must be declared to satisfy the interface
end;

procedure TEvaluatedApplicatorVisitor<T>.VisitPrefixItems(const pValue: TJSONArray);
begin
  // Empty - this visitor does not handle prefixItems, but it must be declared to satisfy the interface
end;

end.
