unit JsonSchema.Validation.Draft2019_09;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Types,
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
  JsonSchema.Consts;

type
  /// <summary>Main validation visitor for JSON Schema Draft 2019‑09.</summary>
  TDraft2019_09Visitor = class(TValidationVisitor<TDraft2019_09Visitor>, IDraft2019_09ValidationVocabularyMode)
  private
    FValidationVocabularySilent: Boolean;
  public
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string;
      const pCustomHint: TJSONValue = nil);
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft2019_09Visitor; override;
    function KeywordPrecedence: TArray<string>; override;

    function IsValidationVocabularySilent: Boolean;
    procedure SetValidationVocabularySilent(const pValue: Boolean);
  end;

  /// <summary>Core visitor for Draft 2019‑09, handling $schema, $comment, $anchor, $recursiveRef, $recursiveAnchor, $vocabulary.</summary>
  TDraft2019_09CoreVisitor = class(TBaseCoreVisitor<TDraft2019_09Visitor>)
  private
    function FindRecursiveAnchorInDynamicScope: string;
    procedure ExecuteRefWithBaseURIRestoration(const pValue: TJSONString);
  public
    [VisitorKeyword('$schema')]
    procedure VisitSchema(const pValue: TJSONString); override;

    [VisitorKeyword('$comment')]
    procedure VisitComment(const pValue: TJSONString);

    [VisitorKeyword('$anchor')]
    procedure VisitAnchor(const pValue: TJSONString);

    [VisitorKeyword('$recursiveRef')]
    procedure VisitRecursiveRef(const pValue: TJSONString);

    [VisitorKeyword('$recursiveAnchor')]
    procedure VisitRecursiveAnchor(const pValue: TJSONBool);

    [VisitorKeyword('$vocabulary')]
    procedure VisitVocabulary(const pValue: TJSONObject);
  end;

  /// <summary>Applicator visitor for Draft 2019‑09, adding prefixItems, dependentSchemas, unevaluatedItems, unevaluatedProperties.</summary>
  TDraft2019_09ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft2019_09Visitor>)
  public
    [VisitorKeyword('$defs')]
    procedure VisitDefs(const pValue: TJSONObject);

    [VisitorKeyword('prefixItems')]
    procedure VisitPrefixItems(const pValue: TJSONArray); override;

    [VisitorKeyword('dependentSchemas')]
    procedure VisitDependentSchemas(const pValue: TJSONObject);

    [VisitorKeyword('unevaluatedItems')]
    procedure VisitUnevaluatedItems(const pValue: TJSONValue);

    [VisitorKeyword('unevaluatedProperties')]
    procedure VisitUnevaluatedProperties(const pValue: TJSONValue);
  end;

  /// <summary>Validation visitor for Draft 2019‑09, extending base with minContains/maxContains and vocabulary silence.</summary>
  TDraft2019_09ValidationVisitor = class(TBaseValidationVisitor<TDraft2019_09Visitor>)
  private
    function IsValidationVocabularySilent: Boolean;
  public
    [VisitorKeyword('minimum')]
    procedure VisitMinimum(const pValue: TJSONNumber); override;

    [VisitorKeyword('contains')]
    procedure VisitContains(const pValue: TJSONValue); override;

    [VisitorKeyword('maxContains')]
    procedure VisitMaxContains(const pValue: TJSONNumber);

    [VisitorKeyword('minContains')]
    procedure VisitMinContains(const pValue: TJSONNumber);

    [VisitorKeyword('dependentRequired')]
    procedure VisitDependentRequired(const pValue: TJSONObject);
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  JsonSchema.Walker,
  JsonSchema.Walker.Types,
  JsonSchema.JsonPathUtils,
  JsonSchema.Registry.Utils;

{ TDraft2019_09CoreVisitor }

procedure TDraft2019_09CoreVisitor.VisitSchema(const pValue: TJSONString);
var
  lScope: TScope;
  lSchemaURI: TURIReference;
  lMetaResource: TResource;
  lMetaSchemaRoot: TJSONValue;
  lVocabularyValue: TJSONValue;
  lValidationVocabularyValue: TJSONValue;
  lValidationVocabularyRequired: Boolean;
  lValidationKeyword: string;
begin
  lScope := Visitor.CurrentScope;
  lSchemaURI := TURIReference.From(pValue.Value).ResolveWith(TURIReference.From(lScope.BaseURI));

  if not Visitor.Registry.TryFindResource(lSchemaURI.Unsplit, lMetaResource) then
  begin
    if ContainsText(lSchemaURI.Unsplit, META_SCHEMA_NO_VALIDATION_URI) then
      TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(True);
    Exit;
  end;

  lMetaSchemaRoot := lMetaResource.ResolveFragment('');
  if not (lMetaSchemaRoot is TJSONObject) then
  begin
    if ContainsText(lSchemaURI.Unsplit, META_SCHEMA_NO_VALIDATION_URI) then
      TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(True);
    Exit;
  end;

  lValidationVocabularyRequired := False;
  if TJSONObject(lMetaSchemaRoot).TryGetValue('$vocabulary', lVocabularyValue) and
     (lVocabularyValue is TJSONObject) and
     TJSONObject(lVocabularyValue).TryGetValue(DRAFT2019_09_VALIDATION_VOCABULARY_URI, lValidationVocabularyValue) and
     (lValidationVocabularyValue is TJSONBool) then
    lValidationVocabularyRequired := TJSONBool(lValidationVocabularyValue).AsBoolean;

  TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(not lValidationVocabularyRequired);
  if TDraft2019_09Visitor(Visitor).IsValidationVocabularySilent then
    for lValidationKeyword in CValidationKeywords do
      Visitor.AddVisitedKeyword(lValidationKeyword);
end;

procedure TDraft2019_09CoreVisitor.VisitComment(const pValue: TJSONString);
begin
  // $comment is informational – no action
end;

procedure TDraft2019_09CoreVisitor.VisitAnchor(const pValue: TJSONString);
begin
  // Anchors are processed during registry phase; validation phase does nothing.
end;

procedure TDraft2019_09CoreVisitor.ExecuteRefWithBaseURIRestoration(const pValue: TJSONString);
var
  lOriginalScope: TScope;
  lScopeAfterRef: TScope;
begin
  lOriginalScope := Visitor.CurrentScope;
  try
    inherited VisitRef(pValue);
  finally
    lScopeAfterRef := Visitor.CurrentScope;
    if not SameText(lScopeAfterRef.BaseURI, lOriginalScope.BaseURI) then
    begin
      lScopeAfterRef.BaseURI := lOriginalScope.BaseURI;
      Visitor.UpdateScope(lScopeAfterRef);
    end;
  end;
end;

function TDraft2019_09CoreVisitor.FindRecursiveAnchorInDynamicScope: string;
var
  lOffset: Integer;
  lScope: TScope;
  lAnchorValue: TJSONValue;
begin
  Result := '';
  lOffset := 0;
  while Assigned(Visitor.CurrentScope(lOffset).SchemaNode) do
  begin
    lScope := Visitor.CurrentScope(lOffset);
    if (lScope.SchemaNode is TJSONObject) and
       TJSONObject(lScope.SchemaNode).TryGetValue('$recursiveAnchor', lAnchorValue) and
       (lAnchorValue is TJSONBool) and TJSONBool(lAnchorValue).AsBoolean then
    begin
      Result := lScope.BaseURI;
      Break;
    end;
    Inc(lOffset);
  end;
end;

procedure TDraft2019_09CoreVisitor.VisitRecursiveRef(const pValue: TJSONString);
var
  lScope: TScope;
  lFinalURI: TURIReference;
  lTargetResource: TResource;
  lTargetSchema: TJSONValue;
  lResolvedBaseURI: string;
  lTargetRecursiveAnchor: TJSONValue;
  lRecursiveBaseURI: string;
  lRecursiveRefValue: TJSONString;
begin
  lScope := Visitor.CurrentScope;
  lFinalURI := TURIReference.From(pValue.Value).ResolveWith(TURIReference.From(lScope.BaseURI));

  if not Visitor.Registry.TryFindResource(lFinalURI.Unsplit, lTargetResource) then
  begin
    ExecuteRefWithBaseURIRestoration(pValue);
    Exit;
  end;

  lTargetSchema := lTargetResource.ResolveFragment(lFinalURI.Fragment, lResolvedBaseURI);
  if not Assigned(lTargetSchema) then
  begin
    ExecuteRefWithBaseURIRestoration(pValue);
    Exit;
  end;

  if not ((lTargetSchema is TJSONObject) and
          TJSONObject(lTargetSchema).TryGetValue('$recursiveAnchor', lTargetRecursiveAnchor) and
          (lTargetRecursiveAnchor is TJSONBool) and
          TJSONBool(lTargetRecursiveAnchor).AsBoolean) then
  begin
    ExecuteRefWithBaseURIRestoration(pValue);
    Exit;
  end;

  lRecursiveBaseURI := FindRecursiveAnchorInDynamicScope;
  if lRecursiveBaseURI.IsEmpty then
  begin
    ExecuteRefWithBaseURIRestoration(pValue);
    Exit;
  end;

  lRecursiveRefValue := TJSONString.Create(lRecursiveBaseURI + '#');
  try
    ExecuteRefWithBaseURIRestoration(lRecursiveRefValue);
  finally
    lRecursiveRefValue.Free;
  end;
end;

procedure TDraft2019_09CoreVisitor.VisitRecursiveAnchor(const pValue: TJSONBool);
begin
  // No action; the presence of the keyword is detected during recursiveRef resolution
end;

procedure TDraft2019_09CoreVisitor.VisitVocabulary(const pValue: TJSONObject);
const
  CKnownVocabularies: array[0..6] of string = (
    'https://json-schema.org/draft/2019-09/vocab/core',
    'https://json-schema.org/draft/2019-09/vocab/applicator',
    'https://json-schema.org/draft/2019-09/vocab/validation',
    'https://json-schema.org/draft/2019-09/vocab/meta-data',
    'https://json-schema.org/draft/2019-09/vocab/format',
    'https://json-schema.org/draft/2019-09/vocab/content',
    'https://json-schema.org/draft/2019-09/vocab/hyper-schema'
  );
var
  lVocabulary: TJSONPair;
  lRequired: Boolean;
  lKnown: string;
  lValidationVocabularyDeclared: Boolean;
  lValidationVocabularyRequired: Boolean;
  lValidationKeyword: string;
begin
  lValidationVocabularyDeclared := False;
  lValidationVocabularyRequired := False;

  for lVocabulary in pValue do
  begin
    if not (lVocabulary.JsonValue is TJSONBool) then
      Continue;

    lRequired := TJSONBool(lVocabulary.JsonValue).AsBoolean;

    if SameText(lVocabulary.JsonString.Value, DRAFT2019_09_VALIDATION_VOCABULARY_URI) then
    begin
      lValidationVocabularyDeclared := True;
      lValidationVocabularyRequired := lRequired;
    end;

    if not lRequired then
      Continue;

    lKnown := '';
    for var lKnownVocab in CKnownVocabularies do
      if SameText(lVocabulary.JsonString.Value, lKnownVocab) then
      begin
        lKnown := lKnownVocab;
        Break;
      end;

    if lKnown.IsEmpty then
      Visitor.AddError(TErrorType.vetUnsupportedVocabulary, [lVocabulary.JsonString.Value]);
  end;

  if (not lValidationVocabularyDeclared) or (not lValidationVocabularyRequired) then
  begin
    TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(True);
    for lValidationKeyword in CValidationKeywords do
      Visitor.AddVisitedKeyword(lValidationKeyword);
  end
  else
    TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(False);
end;

{ TDraft2019_09ApplicatorVisitor }

procedure TDraft2019_09ApplicatorVisitor.VisitDefs(const pValue: TJSONObject);
begin
  // $defs are already traversed by the walker; no additional action needed.
end;

procedure TDraft2019_09ApplicatorVisitor.VisitPrefixItems(const pValue: TJSONArray);
begin
  // Draft 2019‑09 does not support prefixItems; ignore.
end;

procedure TDraft2019_09ApplicatorVisitor.VisitDependentSchemas(const pValue: TJSONObject);
var
  lVisitor: IValidationVisitor<TDraft2019_09Visitor>;
  lScope: TScope;
  lInstance: TJSONObject;
  lDependencyPair: TJSONPair;
  lSubScope: TScope;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  for lDependencyPair in pValue do
  begin
    if lInstance.FindValue(lDependencyPair.JsonString.Value) <> nil then
    begin
      if EvaluateSubSchema(lDependencyPair.JsonValue,
          Format('dependentSchemas/%s', [lDependencyPair.JsonString.Value]), lSubScope) then
        MergeSubScope(lSubScope, lScope);
    end;
  end;
  lVisitor.UpdateScope(lScope);
end;

procedure TDraft2019_09ApplicatorVisitor.VisitUnevaluatedItems(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<TDraft2019_09Visitor>;
  lEvaluatedVisitor: TEvaluatedApplicatorVisitor<TDraft2019_09Visitor>;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  // Reuse the common evaluated visitor with default normalisation
  lEvaluatedVisitor := TEvaluatedApplicatorVisitor<TDraft2019_09Visitor>.Create(Visitor, nil);
  try
    lEvaluatedVisitor.VisitUnevaluatedItems(pValue);
  finally
    lEvaluatedVisitor.Free;
  end;
end;

procedure TDraft2019_09ApplicatorVisitor.VisitUnevaluatedProperties(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<TDraft2019_09Visitor>;
  lEvaluatedVisitor: TEvaluatedApplicatorVisitor<TDraft2019_09Visitor>;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lEvaluatedVisitor := TEvaluatedApplicatorVisitor<TDraft2019_09Visitor>.Create(Visitor, nil);
  try
    lEvaluatedVisitor.VisitUnevaluatedProperties(pValue);
  finally
    lEvaluatedVisitor.Free;
  end;
end;

{ TDraft2019_09ValidationVisitor }

function TDraft2019_09ValidationVisitor.IsValidationVocabularySilent: Boolean;
begin
  Result := TDraft2019_09Visitor(Visitor).IsValidationVocabularySilent;
end;

procedure TDraft2019_09ValidationVisitor.VisitMinimum(const pValue: TJSONNumber);
begin
  if IsValidationVocabularySilent then
    Exit;
  inherited;
end;

procedure TDraft2019_09ValidationVisitor.VisitContains(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<TDraft2019_09Visitor>;
  lScope: TScope;
  lInstance: TJSONArray;
  lCount: Integer;
  lSubVisitor: TDraft2019_09Visitor;
  lWalker: IWalker;
  lNewScope: TScope;
  lFound: Boolean;
  lMinContainsNode: TJSONValue;
  lMinimumContains: Integer;
  lItemPath: string;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsValidationVocabularySilent then
    Exit;

  lScope := lVisitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lInstance := TJSONArray(lScope.InstanceNode);
  lFound := False;

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

    var lNewVisitorInstance: TDraft2019_09Visitor := lVisitor.New(pValue, lInstance[lCount], lScope.BaseURI);
    lSubVisitor := lNewVisitorInstance;

    lSubVisitor.PushScope(lNewScope);
    try
      lWalker := TWalker<TDraft2019_09Visitor>.Create(pValue, lSubVisitor);
      lWalker.Walk;
    finally
      lSubVisitor.PopScope;
    end;

    if lSubVisitor.Result.IsValid then
    begin
      lFound := True;
      TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
      lItemPath := TJsonPathUtils.JoinPath(lScope.InstancePath, lCount.ToString);
      lVisitor.Result.AddEvaluatedProperty(lItemPath);
    end;
  end;

  // Apply minContains (default 1) and maxContains
  if (lScope.SchemaNode is TJSONObject) and
     TJSONObject(lScope.SchemaNode).TryGetValue('minContains', lMinContainsNode) and
     (lMinContainsNode is TJSONNumber) then
    lMinimumContains := TUtils.JsonGetInteger(TJSONNumber(lMinContainsNode))
  else
    lMinimumContains := 1;

  if not lFound and (lMinimumContains > 0) then
    lVisitor.AddError(TErrorType.vetContains)
  else if lFound and (lMinimumContains > 1) then
    lVisitor.AddError(TErrorType.vetMinContains, [lMinimumContains, 1]); // simplified

  if (lScope.SchemaNode is TJSONObject) and
     TJSONObject(lScope.SchemaNode).TryGetValue('maxContains', lMinContainsNode) and
     (lMinContainsNode is TJSONNumber) then
    VisitMaxContains(TJSONNumber(lMinContainsNode));

  lVisitor.UpdateScope(lScope);
end;

procedure TDraft2019_09ValidationVisitor.VisitMaxContains(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<TDraft2019_09Visitor>;
  lScope: TScope;
  lMax: Integer;
  lContainsCount: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  lMax := TUtils.JsonGetInteger(pValue);
  lContainsCount := lScope.ContainsCount;
  if lContainsCount > lMax then
    lVisitor.AddError(TErrorType.vetMaxContains, [lMax, lContainsCount]);
end;

procedure TDraft2019_09ValidationVisitor.VisitMinContains(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<TDraft2019_09Visitor>;
  lScope: TScope;
  lMin: Integer;
  lContainsCount: Integer;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := lVisitor.CurrentScope;
  lMin := TUtils.JsonGetInteger(pValue);
  lContainsCount := lScope.ContainsCount;
  if lContainsCount < lMin then
    if lMin = 1 then
      lVisitor.AddError(TErrorType.vetContains)
    else
      lVisitor.AddError(TErrorType.vetMinContains, [lMin, lContainsCount]);
end;

procedure TDraft2019_09ValidationVisitor.VisitDependentRequired(const pValue: TJSONObject);
var
  lVisitor: IValidationVisitor<TDraft2019_09Visitor>;
  lScope: TScope;
  lInstance: TJSONObject;
  lDependencyPair: TJSONPair;
  lRequiredList: TJSONArray;
  lRequiredValue: TJSONValue;
  lRequiredName: string;
begin
  lVisitor := GetValidationVisitor;
  if not Assigned(lVisitor) then
    Exit;

  if IsValidationVocabularySilent then
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

{ TDraft2019_09Visitor }

constructor TDraft2019_09Visitor.Create(const pSchema, pData: TJSONValue; const pBaseURI: string;
  const pCustomHint: TJSONValue);
var
  lSchemaURI: string;
begin
  inherited Create(pSchema, pData, pBaseURI, pCustomHint);

  FValidationVocabularySilent := False;
  if (pSchema is TJSONObject) and
     TJSONObject(pSchema).TryGetValue<string>('$schema', lSchemaURI) and
     ContainsText(lSchemaURI, META_SCHEMA_NO_VALIDATION_URI) then
    FValidationVocabularySilent := True;

  FCore := TDraft2019_09CoreVisitor.Create(Self);
  FApplicator := TDraft2019_09ApplicatorVisitor.Create(Self);
  FValidation := TDraft2019_09ValidationVisitor.Create(Self);
  FHyperSchema := TStubHyperSchemaVisitor<TDraft2019_09Visitor>.Create(Self);
  FRelativeJsonPointer := TStubRelativeJsonPointer<TDraft2019_09Visitor>.Create(Self);
end;

function TDraft2019_09Visitor.New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft2019_09Visitor;
begin
  Result := TDraft2019_09Visitor.Create(pSchema, pData, pBaseURI, FCustomHint);
  Result.FRegistry := FRegistry;
  Result.FOwnsRegistry := False;
  Result.FValidationVocabularySilent := FValidationVocabularySilent;
end;

function TDraft2019_09Visitor.KeywordPrecedence: TArray<string>;
begin
  Result := [
    '$schema',
    '$id',
    '$ref',
    '$recursiveRef',
    '$anchor',
    '$recursiveAnchor',
    'properties',
    'patternProperties',
    'additionalProperties',
    'items',
    'additionalItems',
    'contains',
    'allOf',
    'anyOf',
    'oneOf',
    'not',
    'if',
    'then',
    'else',
    'dependentSchemas',
    'unevaluatedProperties',
    'unevaluatedItems'
  ];
end;

function TDraft2019_09Visitor.IsValidationVocabularySilent: Boolean;
begin
  Result := FValidationVocabularySilent;
end;

procedure TDraft2019_09Visitor.SetValidationVocabularySilent(const pValue: Boolean);
begin
  FValidationVocabularySilent := pValue;
end;

end.
