unit JsonSchema.Visitor.Applicator.Combiner;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Types,
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
  ///   Visitor for applicator combiners: allOf, anyOf, oneOf, not.
  ///   This class is meant to be composed into a full validation visitor.
  /// </summary>
  TCombinerApplicatorVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseApplicatorVisitor<T>)
  private
    function GetValidationVisitor: IValidationVisitor<T>;
    function GetCurrentScope: TScope;
    procedure UpdateScope(const pScope: TScope);
    function EvaluateSubSchema(const pSubSchema: TJSONValue; const pSchemaPathSuffix: string;
      out pSubScope: TScope): Boolean;
    procedure CollectEvaluatedFromVisitor(const pVisitor: IValidationVisitor<T>;
      const pSubScope: TScope; var pCombinedEvaluated: THashSet<string>;
      var pCombinedCoveredItems: TArray<Integer>;
      var pCombinedCoveredProperties: TArray<string>);
  public
    [VisitorKeyword('allOf')]
    procedure VisitAllOf(const pValue: TJSONArray);

    [VisitorKeyword('anyOf')]
    procedure VisitAnyOf(const pValue: TJSONArray);

    [VisitorKeyword('oneOf')]
    procedure VisitOneOf(const pValue: TJSONArray);

    [VisitorKeyword('not')]
    procedure VisitNot(const pValue: TJSONValue);

    // Unsupported applicator methods – no‑op to satisfy the interface
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
  System.SysUtils,
  System.Math;

{ TCombinerApplicatorVisitor<T> }

function TCombinerApplicatorVisitor<T>.GetValidationVisitor: IValidationVisitor<T>;
begin
  Supports(Visitor, IValidationVisitor<T>, Result);
end;

function TCombinerApplicatorVisitor<T>.GetCurrentScope: TScope;
var
  lVisitor: IValidationVisitor<T>;
begin
  FillChar(Result, SizeOf(Result), 0);
  lVisitor := GetValidationVisitor;
  if Assigned(lVisitor) then
    Result := lVisitor.CurrentScope;
end;

procedure TCombinerApplicatorVisitor<T>.UpdateScope(const pScope: TScope);
var
  lVisitor: IValidationVisitor<T>;
begin
  lVisitor := GetValidationVisitor;
  if Assigned(lVisitor) then
    lVisitor.UpdateScope(pScope);
end;

function TCombinerApplicatorVisitor<T>.EvaluateSubSchema(const pSubSchema: TJSONValue;
  const pSchemaPathSuffix: string; out pSubScope: TScope): Boolean;
var
  lVisitor: IValidationVisitor<T>;
  lParentScope: TScope;
  lSubVisitor: IValidationVisitor<T>;
  lWalker: IWalker;
begin
  Result := False;
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lParentScope := GetCurrentScope;
  pSubScope := lParentScope;
  pSubScope.SchemaNode := pSubSchema;
  pSubScope.SchemaPath := TJsonPathUtils.JoinPath(lParentScope.SchemaPath, pSchemaPathSuffix);
  pSubScope.CoveredItems := [];
  pSubScope.ContainsCount := 0;
  pSubScope.VisitedKeywords := [];
  pSubScope.CoveredProperties := [];
  pSubScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

  lSubVisitor := lVisitor.New(pSubSchema, lParentScope.InstanceNode, lParentScope.BaseURI);
  lSubVisitor.PushScope(pSubScope);
  try
    lWalker := TWalker<T>.Create(pSubSchema, lSubVisitor);
    lWalker.Walk;
    Result := lSubVisitor.Result.IsValid;
  finally
    pSubScope := lSubVisitor.PopScope;
  end;
end;

procedure TCombinerApplicatorVisitor<T>.CollectEvaluatedFromVisitor(const pVisitor: IValidationVisitor<T>;
  const pSubScope: TScope; var pCombinedEvaluated: THashSet<string>;
  var pCombinedCoveredItems: TArray<Integer>;
  var pCombinedCoveredProperties: TArray<string>);
var
  lEvaluatedProp: string;
  lNormalized: string;
begin
  if Assigned(pSubScope.EvaluatedPropertiesInScope) then
    for lEvaluatedProp in pSubScope.EvaluatedPropertiesInScope do
      pCombinedEvaluated.Add(lEvaluatedProp);

  for lEvaluatedProp in pVisitor.Result.EvaluatedProperties do
  begin
    lNormalized := TJsonPathUtils.NormalizeToCanonical(lEvaluatedProp);
    pCombinedEvaluated.Add(lNormalized);
  end;

  pCombinedCoveredItems := TUtils.MergeArray<Integer>([pCombinedCoveredItems, pSubScope.CoveredItems]);
  pCombinedCoveredProperties := TUtils.MergeArray<string>([pCombinedCoveredProperties, pSubScope.CoveredProperties]);
end;

procedure TCombinerApplicatorVisitor<T>.VisitAllOf(const pValue: TJSONArray);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lCombinedCoveredItems: TArray<Integer>;
  lCombinedCoveredProperties: TArray<string>;
  lCombinedEvaluated: THashSet<string>;
  lIndex: Integer;
  lSubScope: TScope;
  lSubValid: Boolean;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  lCombinedCoveredItems := lScope.CoveredItems;
  lCombinedCoveredProperties := lScope.CoveredProperties;
  lCombinedEvaluated := THashSet<string>.Create;
  try
    if Assigned(lScope.EvaluatedPropertiesInScope) then
      for var lProp in lScope.EvaluatedPropertiesInScope do
        lCombinedEvaluated.Add(lProp);

    for lIndex := 0 to pValue.Count - 1 do
    begin
      lSubValid := EvaluateSubSchema(pValue[lIndex], Format('allOf/%d', [lIndex]), lSubScope);
      if not lSubValid then
      begin
        lVisitor.AddError(TErrorType.vetAllOf, [lIndex]);
        Exit;
      end;
      CollectEvaluatedFromVisitor(lVisitor, lSubScope, lCombinedEvaluated,
        lCombinedCoveredItems, lCombinedCoveredProperties);
    end;

    lScope.CoveredItems := lCombinedCoveredItems;
    lScope.CoveredProperties := lCombinedCoveredProperties;
    if lCombinedEvaluated.Count > 0 then
    begin
      if not Assigned(lScope.EvaluatedPropertiesInScope) then
        lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
      for var lProp in lCombinedEvaluated do
        lScope.EvaluatedPropertiesInScope.Add(lProp);
    end;
    UpdateScope(lScope);
  finally
    lCombinedEvaluated.Free;
  end;
end;

procedure TCombinerApplicatorVisitor<T>.VisitAnyOf(const pValue: TJSONArray);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lIndex: Integer;
  lSubScope: TScope;
  lSubValid: Boolean;
  lAnyValid: Boolean;
  lWinningCoveredItems: TArray<Integer>;
  lWinningCoveredProperties: TArray<string>;
  lWinningEvaluated: THashSet<string>;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  lAnyValid := False;
  lWinningCoveredItems := [];
  lWinningCoveredProperties := [];
  lWinningEvaluated := THashSet<string>.Create;
  try
    for lIndex := 0 to pValue.Count - 1 do
    begin
      lSubValid := EvaluateSubSchema(pValue[lIndex], Format('anyOf/%d', [lIndex]), lSubScope);
      if lSubValid then
      begin
        lAnyValid := True;
        lWinningCoveredItems := lSubScope.CoveredItems;
        lWinningCoveredProperties := lSubScope.CoveredProperties;
        lWinningEvaluated.Clear;
        if Assigned(lSubScope.EvaluatedPropertiesInScope) then
          for var lProp in lSubScope.EvaluatedPropertiesInScope do
            lWinningEvaluated.Add(lProp);
        Break; // anyOf stops at first success
      end;
    end;

    if not lAnyValid then
      lVisitor.AddError(TErrorType.vetAnyOf)
    else
    begin
      lScope.CoveredItems := TUtils.MergeArray<Integer>([lScope.CoveredItems, lWinningCoveredItems]);
      lScope.CoveredProperties := TUtils.MergeArray<string>([lScope.CoveredProperties, lWinningCoveredProperties]);
      if lWinningEvaluated.Count > 0 then
      begin
        if not Assigned(lScope.EvaluatedPropertiesInScope) then
          lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
        for var lProp in lWinningEvaluated do
          lScope.EvaluatedPropertiesInScope.Add(lProp);
      end;
      UpdateScope(lScope);
    end;
  finally
    lWinningEvaluated.Free;
  end;
end;

procedure TCombinerApplicatorVisitor<T>.VisitOneOf(const pValue: TJSONArray);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lIndex: Integer;
  lSubScope: TScope;
  lSubValid: Boolean;
  lValidCount: Integer;
  lWinningCoveredItems: TArray<Integer>;
  lWinningCoveredProperties: TArray<string>;
  lWinningEvaluated: THashSet<string>;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  lValidCount := 0;
  lWinningCoveredItems := [];
  lWinningCoveredProperties := [];
  lWinningEvaluated := THashSet<string>.Create;
  try
    for lIndex := 0 to pValue.Count - 1 do
    begin
      lSubValid := EvaluateSubSchema(pValue[lIndex], Format('oneOf/%d', [lIndex]), lSubScope);
      if lSubValid then
      begin
        Inc(lValidCount);
        if lValidCount = 1 then
        begin
          lWinningCoveredItems := lSubScope.CoveredItems;
          lWinningCoveredProperties := lSubScope.CoveredProperties;
          lWinningEvaluated.Clear;
          if Assigned(lSubScope.EvaluatedPropertiesInScope) then
            for var lProp in lSubScope.EvaluatedPropertiesInScope do
              lWinningEvaluated.Add(lProp);
        end;
      end;
    end;

    if lValidCount = 0 then
      lVisitor.AddError(TErrorType.vetOneOf_NoMatch)
    else if lValidCount > 1 then
      lVisitor.AddError(TErrorType.vetOneOf_MultipleMatches)
    else
    begin
      lScope.CoveredItems := TUtils.MergeArray<Integer>([lScope.CoveredItems, lWinningCoveredItems]);
      lScope.CoveredProperties := TUtils.MergeArray<string>([lScope.CoveredProperties, lWinningCoveredProperties]);
      if lWinningEvaluated.Count > 0 then
      begin
        if not Assigned(lScope.EvaluatedPropertiesInScope) then
          lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
        for var lProp in lWinningEvaluated do
          lScope.EvaluatedPropertiesInScope.Add(lProp);
      end;
      UpdateScope(lScope);
    end;
  finally
    lWinningEvaluated.Free;
  end;
end;

procedure TCombinerApplicatorVisitor<T>.VisitNot(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lSubScope: TScope;
  lSubValid: Boolean;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  lSubValid := EvaluateSubSchema(pValue, 'not', lSubScope);
  if lSubValid then
    lVisitor.AddError(TErrorType.vetNot);
  // No merge of covered/evaluated from 'not' because it failed (or passed).
end;

// No‑op stubs for other applicator methods

procedure TCombinerApplicatorVisitor<T>.VisitIf(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle 'if' directly, but must implement the method to satisfy the interface.
end;

procedure TCombinerApplicatorVisitor<T>.VisitThen(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle 'then' directly, but must implement the method to satisfy the interface.
end;

procedure TCombinerApplicatorVisitor<T>.VisitElse(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle 'else' directly, but must implement the method to satisfy the interface.
end;

procedure TCombinerApplicatorVisitor<T>.VisitProperties(const pValue: TJSONObject);
begin
  // Empty - this visitor does not handle 'properties' directly, but must implement the method to satisfy the interface.
end;

procedure TCombinerApplicatorVisitor<T>.VisitPatternProperties(const pValue: TJSONObject);
begin
  // Empty - this visitor does not handle 'patternProperties' directly, but must implement the method to satisfy the interface.
end;

procedure TCombinerApplicatorVisitor<T>.VisitAdditionalProperties(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle 'additionalProperties' directly, but must implement the method to satisfy the interface.
end;

procedure TCombinerApplicatorVisitor<T>.VisitItems(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle 'items' directly, but must implement the method to satisfy the interface.
end;

procedure TCombinerApplicatorVisitor<T>.VisitAdditionalItems(const pValue: TJSONValue);
begin
  // Empty - this visitor does not handle 'additionalItems' directly, but must implement the method to satisfy the interface.
end;

procedure TCombinerApplicatorVisitor<T>.VisitPrefixItems(const pValue: TJSONArray);
begin
  // Empty - this visitor does not handle 'prefixItems' directly, but must implement the method to satisfy the interface.
end;

end.
