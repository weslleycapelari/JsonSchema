unit JsonSchema.Visitor.Applicator.Conditional;

interface

uses
  System.JSON,
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
  ///   Visitor for conditional applicator keywords: if, then, else.
  ///   Evaluates the 'if' sub‑schema; if valid, applies 'then'; otherwise applies 'else'.
  ///   This class is meant to be composed into a full validation visitor.
  /// </summary>
  TConditionalApplicatorVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseApplicatorVisitor<T>)
  private
    function GetValidationVisitor: IValidationVisitor<T>;
    function GetCurrentScope: TScope;
    procedure UpdateScope(const pScope: TScope);
    function EvaluateSubSchema(const pSubSchema: TJSONValue; out pSubScope: TScope): Boolean;
    procedure MergeSubScope(const pSubScope: TScope; var pParentScope: TScope);
  public
    [VisitorKeyword('if')]
    procedure VisitIf(const pValue: TJSONValue);

    [VisitorKeyword('then')]
    procedure VisitThen(const pValue: TJSONValue);

    [VisitorKeyword('else')]
    procedure VisitElse(const pValue: TJSONValue);

    // Unsupported applicator methods – no‑op to satisfy the interface
    procedure VisitAllOf(const pValue: TJSONArray); virtual;
    procedure VisitAnyOf(const pValue: TJSONArray); virtual;
    procedure VisitOneOf(const pValue: TJSONArray); virtual;
    procedure VisitNot(const pValue: TJSONValue); virtual;
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
  System.Generics.Collections;

{ TConditionalApplicatorVisitor<T> }

function TConditionalApplicatorVisitor<T>.GetValidationVisitor: IValidationVisitor<T>;
begin
  Supports(Visitor, IValidationVisitor<T>, Result);
end;

function TConditionalApplicatorVisitor<T>.GetCurrentScope: TScope;
var
  lVisitor: IValidationVisitor<T>;
begin
  FillChar(Result, SizeOf(Result), 0);
  lVisitor := GetValidationVisitor;
  if Assigned(lVisitor) then
    Result := lVisitor.CurrentScope;
end;

procedure TConditionalApplicatorVisitor<T>.UpdateScope(const pScope: TScope);
var
  lVisitor: IValidationVisitor<T>;
begin
  lVisitor := GetValidationVisitor;
  if Assigned(lVisitor) then
    lVisitor.UpdateScope(pScope);
end;

function TConditionalApplicatorVisitor<T>.EvaluateSubSchema(const pSubSchema: TJSONValue;
  out pSubScope: TScope): Boolean;
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
  pSubScope.SchemaPath := TJsonPathUtils.JoinPath(lParentScope.SchemaPath, 'if');
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
  finally
    pSubScope := lSubVisitor.PopScope;
  end;

  Result := lSubVisitor.Result.IsValid;
end;

procedure TConditionalApplicatorVisitor<T>.MergeSubScope(const pSubScope: TScope; var pParentScope: TScope);
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

procedure TConditionalApplicatorVisitor<T>.VisitIf(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lThenSchema: TJSONValue;
  lElseSchema: TJSONValue;
  lSubScope: TScope;
  lIfValid: Boolean;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;

  // Evaluate the 'if' sub‑schema
  lIfValid := EvaluateSubSchema(pValue, lSubScope);
  if lIfValid then
  begin
    // Merge any covered items/properties from the 'if' evaluation
    MergeSubScope(lSubScope, lScope);
    UpdateScope(lScope);

    // Apply 'then' if present
    if (lScope.SchemaNode is TJSONObject) and
       TJSONObject(lScope.SchemaNode).TryGetValue('then', lThenSchema) then
    begin
      // Defer to VisitThen for actual validation
      VisitThen(lThenSchema);
    end;
  end
  else
  begin
    // Apply 'else' if present
    if (lScope.SchemaNode is TJSONObject) and
       TJSONObject(lScope.SchemaNode).TryGetValue('else', lElseSchema) then
    begin
      VisitElse(lElseSchema);
    end;
  end;

  // Mark keywords as visited to avoid reprocessing
  lVisitor.AddVisitedKeyword('then');
  lVisitor.AddVisitedKeyword('else');
end;

procedure TConditionalApplicatorVisitor<T>.VisitThen(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lSubScope: TScope;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  if not EvaluateSubSchema(pValue, lSubScope) then
  begin
    // 'then' validation failed; errors are already added by EvaluateSubSchema
    // No need to add extra error – the sub‑visitor already recorded failures.
  end;
  MergeSubScope(lSubScope, lScope);
  UpdateScope(lScope);
end;

procedure TConditionalApplicatorVisitor<T>.VisitElse(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lSubScope: TScope;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  if not EvaluateSubSchema(pValue, lSubScope) then
  begin
    // 'else' validation failed; errors added by sub‑visitor
  end;
  MergeSubScope(lSubScope, lScope);
  UpdateScope(lScope);
end;

// Unsupported methods – no‑op

procedure TConditionalApplicatorVisitor<T>.VisitAllOf(const pValue: TJSONArray);
begin
  // Empty - this visitor only handles 'if', 'then', and 'else'. Other applicator keywords are ignored.
end;

procedure TConditionalApplicatorVisitor<T>.VisitAnyOf(const pValue: TJSONArray);
begin
  // Empty - this visitor only handles 'if', 'then', and 'else'. Other applicator keywords are ignored.
end;

procedure TConditionalApplicatorVisitor<T>.VisitOneOf(const pValue: TJSONArray);
begin
  // Empty - this visitor only handles 'if', 'then', and 'else'. Other applicator keywords are ignored.
end;

procedure TConditionalApplicatorVisitor<T>.VisitNot(const pValue: TJSONValue);
begin
  // Empty - this visitor only handles 'if', 'then', and 'else'. Other applicator keywords are ignored.
end;

procedure TConditionalApplicatorVisitor<T>.VisitProperties(const pValue: TJSONObject);
begin
  // Empty - this visitor only handles 'if', 'then', and 'else'. Other applicator keywords are ignored.
end;

procedure TConditionalApplicatorVisitor<T>.VisitPatternProperties(const pValue: TJSONObject);
begin
  // Empty - this visitor only handles 'if', 'then', and 'else'. Other applicator keywords are ignored.
end;

procedure TConditionalApplicatorVisitor<T>.VisitAdditionalProperties(const pValue: TJSONValue);
begin
  // Empty - this visitor only handles 'if', 'then', and 'else'. Other applicator keywords are ignored.
end;

procedure TConditionalApplicatorVisitor<T>.VisitItems(const pValue: TJSONValue);
begin
  // Empty - this visitor only handles 'if', 'then', and 'else'. Other applicator keywords are ignored.
end;

procedure TConditionalApplicatorVisitor<T>.VisitAdditionalItems(const pValue: TJSONValue);
begin
  // Empty - this visitor only handles 'if', 'then', and 'else'. Other applicator keywords are ignored.
end;

procedure TConditionalApplicatorVisitor<T>.VisitPrefixItems(const pValue: TJSONArray);
begin
  // Empty - this visitor only handles 'if', 'then', and 'else'. Other applicator keywords are ignored.
end;

end.
