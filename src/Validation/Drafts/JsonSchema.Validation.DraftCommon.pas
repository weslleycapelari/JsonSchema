unit JsonSchema.Validation.DraftCommon;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Types,
  JsonSchema.Consts,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitor.Core.Base,
  JsonSchema.Visitor.Applicator.Base,
  JsonSchema.Visitor.Applicator.Combiner,
  JsonSchema.Visitor.Applicator.Conditional,
  JsonSchema.Visitor.Applicator.&Object,
  JsonSchema.Visitor.Applicator.&Array,
  JsonSchema.Visitor.Applicator.Evaluated,
  JsonSchema.Visitor.Validation.Base,
  JsonSchema.Visitor.Validation.Numeric,
  JsonSchema.Visitor.Validation.&String,
  JsonSchema.Visitor.Validation.&Array,
  JsonSchema.Visitor.Validation.&Object,
  JsonSchema.Visitor.Validation.Format,
  JsonSchema.Visitor.RelativePointer.Stub,
  JsonSchema.Visitor.HyperSchema.Stub,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Registry.Base,
  JsonSchema.Registry.Resource,
  JsonSchema.Registry.Uri,
  JsonSchema.Common.Utils,
  JsonSchema.JsonPathUtils,
  JsonSchema.Walker,
  JsonSchema.Walker.Types;

type
  /// <summary>
  ///   Abstract base class for Draft 2019‑09 and Draft 2020‑12 validation visitors.
  ///   Centralises shared logic for evaluated properties/items, contains with min/maxContains,
  ///   dependentSchemas, dependentRequired, and unevaluated keywords.
  ///   Concrete drafts must implement their own normalisation behaviour and
  ///   specific vocabulary configuration.
  /// </summary>
  /// <typeparam name="T">The concrete draft visitor type (CRTP).</typeparam>
  TDraft2019_2020Visitor<T: IValidationVisitor<T>> = class abstract(TValidationVisitor<T>, IDraft2019_09ValidationVocabularyMode)
  private
    FValidationVocabularySilent: Boolean;

    /// <summary>Normalises a path according to the draft's rules (overridden by descendants).</summary>
    function NormalizePath(const pPath: string): string; virtual; abstract;

    /// <summary>Returns the default minContains value (1 for both drafts).</summary>
    class function GetDefaultMinContains: Integer; virtual;

    /// <summary>Checks whether minContains should be enforced automatically when contains is present.</summary>
    class function EnforceDefaultMinContains: Boolean; virtual;
  protected
    /// <summary>
    ///   Creates a specialised evaluated applicator visitor using the draft's
    ///   path normalisation function.
    /// </summary>
    function CreateEvaluatedApplicator: TEvaluatedApplicatorVisitor<T>;

    /// <summary>
    ///   Handles the 'contains' keyword, counting matching items and enforcing
    ///   minContains/maxContains. Uses the draft's path normalisation for evaluated items.
    /// </summary>
    procedure CommonVisitContains(const pValue: TJSONValue);

    /// <summary>
    ///   Handles 'dependentRequired' keyword (shared between drafts).
    /// </summary>
    procedure CommonVisitDependentRequired(const pValue: TJSONObject);

    /// <summary>
    ///   Handles 'dependentSchemas' keyword (shared between drafts).
    /// </summary>
    procedure CommonVisitDependentSchemas(const pValue: TJSONObject);

    /// <summary>
    ///   Handles 'unevaluatedProperties' keyword, delegating to TEvaluatedApplicatorVisitor
    ///   with the draft's normalisation function.
    /// </summary>
    procedure CommonVisitUnevaluatedProperties(const pValue: TJSONValue);

    /// <summary>
    ///   Handles 'unevaluatedItems' keyword, delegating to TEvaluatedApplicatorVisitor
    ///   with the draft's normalisation function.
    /// </summary>
    procedure CommonVisitUnevaluatedItems(const pValue: TJSONValue);
  public
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string; const pCustomHint: TJSONValue = nil);

    // IDraft2019_09ValidationVocabularyMode
    function IsValidationVocabularySilent: Boolean;
    procedure SetValidationVocabularySilent(const pValue: Boolean);
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils;

{ TDraft2019_2020Visitor<T> }

constructor TDraft2019_2020Visitor<T>.Create(const pSchema, pData: TJSONValue; const pBaseURI: string; const pCustomHint: TJSONValue);
var
  lSchemaURI: string;
begin
  inherited Create(pSchema, pData, pBaseURI, pCustomHint);

  FValidationVocabularySilent := False;
  if (pSchema is TJSONObject) and
    TJSONObject(pSchema).TryGetValue<string>('$schema', lSchemaURI) and
    ContainsText(lSchemaURI, META_SCHEMA_NO_VALIDATION_URI) then
  begin
    FValidationVocabularySilent := True;
  end;
end;

class function TDraft2019_2020Visitor<T>.GetDefaultMinContains: Integer;
begin
  Result := 1;
end;

class function TDraft2019_2020Visitor<T>.EnforceDefaultMinContains: Boolean;
begin
  Result := True;
end;

function TDraft2019_2020Visitor<T>.CreateEvaluatedApplicator: TEvaluatedApplicatorVisitor<T>;
var
  lSelf: T;
begin
  lSelf := T(Self);
  Result := TEvaluatedApplicatorVisitor<T>.Create(lSelf,
    function (pPath: string): string
    begin
      Result := NormalizePath(pPath);
    end);
end;

function TDraft2019_2020Visitor<T>.IsValidationVocabularySilent: Boolean;
begin
  Result := FValidationVocabularySilent;
end;

procedure TDraft2019_2020Visitor<T>.SetValidationVocabularySilent(const pValue: Boolean);
begin
  FValidationVocabularySilent := pValue;
end;

procedure TDraft2019_2020Visitor<T>.CommonVisitContains(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONArray;
  lCount: Integer;
  lSubVisitor: T;
  lWalker: IWalker;
  lNewScope: TScope;
  lFound: Boolean;
  lMinContainsNode: TJSONValue;
  lMinimumContains: Integer;
  lMaxContainsNode: TJSONValue;
  lItemPath: string;
  lCanonicalBase: string;
begin
  if not Supports(Self, IValidationVisitor<T>, lVisitor) then
    Exit;
  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lInstance := TJSONArray(lScope.InstanceNode);
  lFound := False;
  lCanonicalBase := NormalizePath(lScope.InstancePath);
  if not lCanonicalBase.EndsWith('/') then
    lCanonicalBase := lCanonicalBase + '/';

  for lCount := 0 to lInstance.Count - 1 do
  begin
    lNewScope := lScope;
    lNewScope.SchemaNode := pValue;
    lNewScope.InstanceNode := lInstance[lCount];
    lNewScope.InstancePath := TJsonPathUtils.JoinPath(lScope.InstancePath, lCount.ToString);
    lNewScope.CoveredItems := [];
    lNewScope.ContainsCount := 0;
    lNewScope.VisitedKeywords := [];
    lNewScope.CoveredProperties := [];

    lSubVisitor := lVisitor.New(pValue, lInstance[lCount], lScope.BaseURI);
    lSubVisitor.PushScope(lNewScope);
    try
      lWalker := TWalker<T>.Create(pValue, lSubVisitor);
      lWalker.Walk;
    finally
      lSubVisitor.PopScope;
    end;

    if lSubVisitor.Result.IsValid then
    begin
      lFound := True;
      TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
      lItemPath := lCanonicalBase + lCount.ToString;
      lVisitor.Result.AddEvaluatedProperty(lItemPath);
    end;
  end;

  // Determine minContains (draft‑specific default)
  if (lScope.SchemaNode is TJSONObject) and
     TJSONObject(lScope.SchemaNode).TryGetValue('minContains', lMinContainsNode) and
     (lMinContainsNode is TJSONNumber) then
    lMinimumContains := TUtils.JsonGetInteger(TJSONNumber(lMinContainsNode))
  else if EnforceDefaultMinContains then
    lMinimumContains := GetDefaultMinContains
  else
    lMinimumContains := 0;

  if lMinimumContains > 0 then
  begin
    if not lFound then
      lVisitor.AddError(TErrorType.vetContains)
    else if (lMinimumContains > 1) and (lScope.ContainsCount < lMinimumContains) then
      lVisitor.AddError(TErrorType.vetMinContains, [lMinimumContains, lScope.ContainsCount]);
  end;

  // maxContains enforcement
  if (lScope.SchemaNode is TJSONObject) and
     TJSONObject(lScope.SchemaNode).TryGetValue('maxContains', lMaxContainsNode) and
     (lMaxContainsNode is TJSONNumber) then
  begin
    if lScope.ContainsCount > TUtils.JsonGetInteger(TJSONNumber(lMaxContainsNode)) then
      lVisitor.AddError(TErrorType.vetMaxContains,
        [TUtils.JsonGetInteger(TJSONNumber(lMaxContainsNode)), lScope.ContainsCount]);
  end;

  lVisitor.UpdateScope(lScope);
end;

procedure TDraft2019_2020Visitor<T>.CommonVisitDependentRequired(const pValue: TJSONObject);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONObject;
  lDependencyPair: TJSONPair;
  lRequiredList: TJSONArray;
  lRequiredValue: TJSONValue;
  lRequiredName: string;
begin
  if not Supports(Self, IValidationVisitor<T>, lVisitor) then
    Exit;
  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  for lDependencyPair in pValue do
  begin
    if lInstance.FindValue(lDependencyPair.JsonString.Value) = nil then
      Continue;

    if not (lDependencyPair.JsonValue is TJSONArray) then
      Continue;

    lRequiredList := TJSONArray(lDependencyPair.JsonValue);
    for lRequiredValue in lRequiredList do
    begin
      if not (lRequiredValue is TJSONString) then
        Continue;
      lRequiredName := TJSONString(lRequiredValue).Value;
      if lInstance.FindValue(lRequiredName) = nil then
        lVisitor.AddError(TErrorType.vetDependentRequired, [lDependencyPair.JsonString.Value, lRequiredName]);
    end;
  end;
end;

procedure TDraft2019_2020Visitor<T>.CommonVisitDependentSchemas(const pValue: TJSONObject);
var
  lVisitor: IValidationVisitor<T>;
  lScope: TScope;
  lInstance: TJSONObject;
  lDependencyPair: TJSONPair;
  lSubVisitor: T;
  lWalker: IWalker;
  lNewScope: TScope;
  lSubScope: TScope;
  lErrorCount: Integer;
begin
  if not Supports(Self, IValidationVisitor<T>, lVisitor) then
    Exit;
  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  for lDependencyPair in pValue do
  begin
    if lInstance.FindValue(lDependencyPair.JsonString.Value) = nil then
      Continue;

    lNewScope := lScope;
    lNewScope.SchemaPath := Format('%s/dependentSchemas/%s', [lScope.SchemaPath, lDependencyPair.JsonString.Value]);
    lNewScope.SchemaNode := lDependencyPair.JsonValue;
    lNewScope.CoveredItems := [];
    lNewScope.ContainsCount := 0;
    lNewScope.VisitedKeywords := [];
    lNewScope.CoveredProperties := [];
    lNewScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

    lSubVisitor := lVisitor.New(lDependencyPair.JsonValue, lScope.InstanceNode, lScope.BaseURI);
    lSubVisitor.PushScope(lNewScope);
    lErrorCount := Length(lVisitor.Result.Errors);
    try
      lWalker := TWalker<T>.Create(lDependencyPair.JsonValue, lSubVisitor);
      lWalker.Walk;
    finally
      lSubScope := lSubVisitor.PopScope;
    end;

    if Length(lVisitor.Result.Errors) = lErrorCount then
    begin
      lScope.CoveredItems := TUtils.MergeArray<Integer>([lScope.CoveredItems, lSubScope.CoveredItems]);
      lScope.CoveredProperties := TUtils.MergeArray<string>([lScope.CoveredProperties, lSubScope.CoveredProperties]);
      if Assigned(lSubScope.EvaluatedPropertiesInScope) then
      begin
        if not Assigned(lScope.EvaluatedPropertiesInScope) then
          lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
        for var lProp in lSubScope.EvaluatedPropertiesInScope do
          lScope.EvaluatedPropertiesInScope.Add(lProp);
      end;
    end;
    lVisitor.UpdateScope(lScope);
  end;
end;

procedure TDraft2019_2020Visitor<T>.CommonVisitUnevaluatedProperties(const pValue: TJSONValue);
var
  lEvaluatedVisitor: TEvaluatedApplicatorVisitor<T>;
begin
  lEvaluatedVisitor := CreateEvaluatedApplicator;
  try
    lEvaluatedVisitor.VisitUnevaluatedProperties(pValue);
  finally
    lEvaluatedVisitor.Free;
  end;
end;

procedure TDraft2019_2020Visitor<T>.CommonVisitUnevaluatedItems(const pValue: TJSONValue);
var
  lEvaluatedVisitor: TEvaluatedApplicatorVisitor<T>;
begin
  lEvaluatedVisitor := CreateEvaluatedApplicator;
  try
    lEvaluatedVisitor.VisitUnevaluatedItems(pValue);
  finally
    lEvaluatedVisitor.Free;
  end;
end;

end.
