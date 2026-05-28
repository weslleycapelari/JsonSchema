unit JsonSchema.Validation.Draft2020_12;

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
  JsonSchema.Visitor.Validation.&String,
  JsonSchema.Visitor.Validation.Numeric,
  JsonSchema.Visitor.Validation.&Array,
  JsonSchema.Visitor.Validation.&Object,
  JsonSchema.Visitor.RelativePointer.Stub,
  JsonSchema.Visitor.HyperSchema.Stub,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Registry.Base,
  JsonSchema.Registry.Resource,
  JsonSchema.Registry.Uri,
  JsonSchema.Common.Utils,
  JsonSchema.JsonPathUtils;

type
  /// <summary>Main validation visitor for JSON Schema Draft 2020‑12, implementing format-assertion and validation vocabulary modes.</summary>
  TDraft2020_12Visitor = class(TValidationVisitor<TDraft2020_12Visitor>, IDraftFormatAssertionMode,
    IDraft2019_09ValidationVocabularyMode)
  private
    FFormatAssertionEnabled: Boolean;
    FValidationVocabularySilent: Boolean;
  public
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string;
      const pCustomHint: TJSONValue = nil);
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft2020_12Visitor; override;
    function KeywordPrecedence: TArray<string>; override;

    // IDraftFormatAssertionMode
    function IsFormatAssertionEnabled: Boolean;
    procedure SetFormatAssertionEnabled(const pValue: Boolean);

    // IDraft2019_09ValidationVocabularyMode (reused interface)
    function IsValidationVocabularySilent: Boolean;
    procedure SetValidationVocabularySilent(const pValue: Boolean);
  end;

  /// <summary>Core visitor for Draft 2020‑12, handling $schema, $comment, $anchor, $dynamicRef, $dynamicAnchor, $vocabulary.</summary>
  TDraft2020_12CoreVisitor = class(TBaseCoreVisitor<TDraft2020_12Visitor>)
  private
    function NormalizeLocalPath(const pPath: string): string;
    function FindDynamicBaseURI(const pDynamicAnchorName: string): string;
    procedure InjectParentEvaluatedIntoCurrentScope;
    procedure ExecuteRefWithCurrentVisitor(const pRefValue: TJSONString);
  public
    [VisitorKeyword('$schema')]
    procedure VisitSchema(const pValue: TJSONString); override;

    [VisitorKeyword('$comment')]
    procedure VisitComment(const pValue: TJSONString);

    [VisitorKeyword('$anchor')]
    procedure VisitAnchor(const pValue: TJSONString);

    [VisitorKeyword('$dynamicRef')]
    procedure VisitDynamicRef(const pValue: TJSONString);

    [VisitorKeyword('$dynamicAnchor')]
    procedure VisitDynamicAnchor(const pValue: TJSONString);

    [VisitorKeyword('$vocabulary')]
    procedure VisitVocabulary(const pValue: TJSONObject);
  end;

  /// <summary>Applicator visitor for Draft 2020‑12, adding items (non‑tuple), prefixItems, dependentSchemas, unevaluatedItems, unevaluatedProperties.</summary>
  TDraft2020_12ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft2020_12Visitor>)
  public
    [VisitorKeyword('items')]
    procedure VisitItems(const pValue: TJSONValue); override;

    [VisitorKeyword('prefixItems')]
    procedure VisitPrefixItems(const pValue: TJSONArray); override;

    [VisitorKeyword('dependentSchemas')]
    procedure VisitDependentSchemas(const pValue: TJSONObject);

    [VisitorKeyword('unevaluatedItems')]
    procedure VisitUnevaluatedItems(const pValue: TJSONValue);

    [VisitorKeyword('unevaluatedProperties')]
    procedure VisitUnevaluatedProperties(const pValue: TJSONValue);
  end;

  /// <summary>Validation visitor for Draft 2020‑12, adding format assertion control, contains with min/maxContains, dependentRequired.</summary>
  TDraft2020_12ValidationVisitor = class(TBaseValidationVisitor<TDraft2020_12Visitor>)
  private
    function IsFormatAssertionEnabled: Boolean;
  public
    [VisitorKeyword('format')]
    procedure VisitFormat(const pValue: TJSONString);

    [VisitorKeyword('contains')]
    procedure VisitContains(const pValue: TJSONValue);

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
  JsonSchema.Registry.Utils;

{ TDraft2020_12CoreVisitor }

function TDraft2020_12CoreVisitor.NormalizeLocalPath(const pPath: string): string;
begin
  Result := TJsonPathUtils.NormalizeToCanonical(pPath);
end;

function TDraft2020_12CoreVisitor.FindDynamicBaseURI(const pDynamicAnchorName: string): string;
var
  lOffset: Integer;
  lMaxOffset: Integer;
  lScope: TScope;
  lScopeResource: TResource;
  lScopeAnchoredSchema: TJSONValue;
  lResolvedBaseURI: string;
  lScopeAnchorValue: TJSONValue;
  lScopeAnchorName: string;
  lDynamicBaseRef: TURIReference;
begin
  Result := '';
  lMaxOffset := -1;
  lOffset := 0;
  while Assigned(Visitor.CurrentScope(lOffset).SchemaNode) do
  begin
    lMaxOffset := lOffset;
    Inc(lOffset);
  end;

  for lOffset := lMaxOffset downto 0 do
  begin
    lScope := Visitor.CurrentScope(lOffset);
    if lScope.BaseURI.IsEmpty then
      Continue;

    if not Visitor.Registry.TryFindResource(lScope.BaseURI, lScopeResource) then
      Continue;

    lScopeAnchoredSchema := lScopeResource.ResolveFragment(pDynamicAnchorName, lResolvedBaseURI);
    if not Assigned(lScopeAnchoredSchema) then
      Continue;

    if not ((lScopeAnchoredSchema is TJSONObject) and
            TJSONObject(lScopeAnchoredSchema).TryGetValue('$dynamicAnchor', lScopeAnchorValue) and
            (lScopeAnchorValue is TJSONString)) then
      Continue;

    lScopeAnchorName := lScopeAnchorValue.Value;
    if SameText(lScopeAnchorName, pDynamicAnchorName) then
    begin
      lDynamicBaseRef := TURIReference.From(lScope.BaseURI);
      lDynamicBaseRef.Query := '';
      lDynamicBaseRef.Fragment := '';
      Result := lDynamicBaseRef.Unsplit;
      Break;
    end;
  end;
end;

procedure TDraft2020_12CoreVisitor.InjectParentEvaluatedIntoCurrentScope;
var
  lInjectScope: TScope;
  lEvaluatedProperty: string;
begin
  lInjectScope := Visitor.CurrentScope;
  if not Assigned(lInjectScope.EvaluatedPropertiesInScope) then
    lInjectScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

  for lEvaluatedProperty in Visitor.Result.EvaluatedProperties do
    lInjectScope.EvaluatedPropertiesInScope.Add(NormalizeLocalPath(lEvaluatedProperty));

  Visitor.UpdateScope(lInjectScope);
end;

procedure TDraft2020_12CoreVisitor.ExecuteRefWithCurrentVisitor(const pRefValue: TJSONString);
var
  lResultEvaluatedBefore: THashSet<string>;
  lEvaluatedProperty: string;
  lNormalizedEvaluatedProperty: string;
  lScopeForSync: TScope;
  lCanonicalScopePath: string;
  lCanonicalPrefix: string;
  lRelativePath: string;
  lSegmentSeparator: Integer;
  lFirstSegment: string;
  lItemIndex: Integer;
  lOriginalScope: TScope;
  lScopeAfterRef: TScope;
begin
  InjectParentEvaluatedIntoCurrentScope;

  lResultEvaluatedBefore := THashSet<string>.Create;
  try
    for lEvaluatedProperty in Visitor.Result.EvaluatedProperties do
      lResultEvaluatedBefore.Add(NormalizeLocalPath(lEvaluatedProperty));

    lOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(pRefValue);
    finally
      lScopeAfterRef := Visitor.CurrentScope;
      if not SameText(lScopeAfterRef.BaseURI, lOriginalScope.BaseURI) then
      begin
        lScopeAfterRef.BaseURI := lOriginalScope.BaseURI;
        Visitor.UpdateScope(lScopeAfterRef);
      end;
    end;

    lScopeForSync := Visitor.CurrentScope;
    if not Assigned(lScopeForSync.EvaluatedPropertiesInScope) then
      lScopeForSync.EvaluatedPropertiesInScope := THashSet<string>.Create;

    for lEvaluatedProperty in Visitor.Result.EvaluatedProperties do
    begin
      lNormalizedEvaluatedProperty := NormalizeLocalPath(lEvaluatedProperty);
      if lResultEvaluatedBefore.Contains(lNormalizedEvaluatedProperty) then
        Continue;

      lScopeForSync.EvaluatedPropertiesInScope.Add(lNormalizedEvaluatedProperty);

      lCanonicalScopePath := NormalizeLocalPath(lScopeForSync.InstancePath);
      if lCanonicalScopePath = '/' then
        lCanonicalPrefix := '/'
      else
        lCanonicalPrefix := lCanonicalScopePath + '/';

      if not lNormalizedEvaluatedProperty.StartsWith(lCanonicalPrefix) then
        Continue;

      lRelativePath := lNormalizedEvaluatedProperty.Substring(Length(lCanonicalPrefix));
      lSegmentSeparator := Pos('/', lRelativePath);
      if lSegmentSeparator > 0 then
        lFirstSegment := Copy(lRelativePath, 1, lSegmentSeparator - 1)
      else
        lFirstSegment := lRelativePath;

      if TryStrToInt(lFirstSegment, lItemIndex) then
        TUtils.AddArray<Integer>(lScopeForSync.CoveredItems, lItemIndex)
      else if lFirstSegment <> '' then
        TUtils.AddArray<string>(lScopeForSync.CoveredProperties, lFirstSegment);
    end;
    Visitor.UpdateScope(lScopeForSync);
  finally
    lResultEvaluatedBefore.Free;
  end;
end;

procedure TDraft2020_12CoreVisitor.VisitSchema(const pValue: TJSONString);
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
  TDraft2020_12Visitor(Visitor).SetFormatAssertionEnabled(False);

  lScope := Visitor.CurrentScope;
  lSchemaURI := TURIReference.From(pValue.Value).ResolveWith(TURIReference.From(lScope.BaseURI));

  if not Visitor.Registry.TryFindResource(lSchemaURI.Unsplit, lMetaResource) then
  begin
    if ContainsText(lSchemaURI.Unsplit, META_SCHEMA_NO_VALIDATION_URI) then
      TDraft2020_12Visitor(Visitor).SetValidationVocabularySilent(True);
    Exit;
  end;

  lMetaSchemaRoot := lMetaResource.ResolveFragment('');
  if not (lMetaSchemaRoot is TJSONObject) then
    Exit;

  lValidationVocabularyRequired := True;
  if TJSONObject(lMetaSchemaRoot).TryGetValue('$vocabulary', lVocabularyValue) and
     (lVocabularyValue is TJSONObject) and
     TJSONObject(lVocabularyValue).TryGetValue(DRAFT2020_12_VALIDATION_VOCABULARY_URI, lValidationVocabularyValue) and
     (lValidationVocabularyValue is TJSONBool) then
    lValidationVocabularyRequired := TJSONBool(lValidationVocabularyValue).AsBoolean;

  TDraft2020_12Visitor(Visitor).SetValidationVocabularySilent(not lValidationVocabularyRequired);
  if TDraft2020_12Visitor(Visitor).IsValidationVocabularySilent then
    for lValidationKeyword in CValidationKeywords do
      Visitor.AddVisitedKeyword(lValidationKeyword);
end;

procedure TDraft2020_12CoreVisitor.VisitComment(const pValue: TJSONString);
begin
  // No action
end;

procedure TDraft2020_12CoreVisitor.VisitAnchor(const pValue: TJSONString);
begin
  // Processed during registry phase
end;

procedure TDraft2020_12CoreVisitor.VisitDynamicRef(const pValue: TJSONString);
var
  lScope: TScope;
  lFinalURI: TURIReference;
  lTargetResource: TResource;
  lTargetSchema: TJSONValue;
  lResolvedBaseURI: string;
  lDynamicAnchorName: string;
  lDynamicBaseURI: string;
  lDynamicRefValue: TJSONString;
  lAnchorValue: TJSONValue;
begin
  lScope := Visitor.CurrentScope;
  lFinalURI := TURIReference.From(pValue.Value).ResolveWith(TURIReference.From(lScope.BaseURI));
  lDynamicAnchorName := lFinalURI.Fragment;

  if lDynamicAnchorName.IsEmpty or lDynamicAnchorName.StartsWith('/') then
  begin
    ExecuteRefWithCurrentVisitor(pValue);
    Exit;
  end;

  if not Visitor.Registry.TryFindResource(lFinalURI.Unsplit, lTargetResource) then
  begin
    ExecuteRefWithCurrentVisitor(pValue);
    Exit;
  end;

  lTargetSchema := lTargetResource.ResolveFragment(lDynamicAnchorName, lResolvedBaseURI);
  if not Assigned(lTargetSchema) then
  begin
    ExecuteRefWithCurrentVisitor(pValue);
    Exit;
  end;

  // Ensure the target schema actually declares a $dynamicAnchor with the same name
  if not ((lTargetSchema is TJSONObject) and
          TJSONObject(lTargetSchema).TryGetValue('$dynamicAnchor', lAnchorValue) and
          (lAnchorValue is TJSONString) and
          SameText(lAnchorValue.Value, lDynamicAnchorName)) then
  begin
    ExecuteRefWithCurrentVisitor(pValue);
    Exit;
  end;

  lDynamicBaseURI := FindDynamicBaseURI(lDynamicAnchorName);
  if lDynamicBaseURI.IsEmpty then
  begin
    ExecuteRefWithCurrentVisitor(pValue);
    Exit;
  end;

  lDynamicRefValue := TJSONString.Create(lDynamicBaseURI + '#' + lDynamicAnchorName);
  try
    ExecuteRefWithCurrentVisitor(lDynamicRefValue);
  finally
    lDynamicRefValue.Free;
  end;
end;

procedure TDraft2020_12CoreVisitor.VisitDynamicAnchor(const pValue: TJSONString);
begin
  // Registry phase already handles this
end;

procedure TDraft2020_12CoreVisitor.VisitVocabulary(const pValue: TJSONObject);
var
  lFormatAssertionValue: TJSONValue;
begin
  if pValue.TryGetValue(DRAFT2020_12_FORMAT_ASSERTION_VOCABULARY_URI, lFormatAssertionValue) and
     (lFormatAssertionValue is TJSONBool) then
    TDraft2020_12Visitor(Visitor).SetFormatAssertionEnabled(TJSONBool(lFormatAssertionValue).AsBoolean)
  else
    TDraft2020_12Visitor(Visitor).SetFormatAssertionEnabled(False);
end;

{ TDraft2020_12ApplicatorVisitor }

procedure TDraft2020_12ApplicatorVisitor.VisitItems(const pValue: TJSONValue);
begin
  // In Draft 2020‑12, 'items' when an array is ignored (tuple validation moved to prefixItems)
  if pValue is TJSONArray then
    Exit;
  inherited VisitItems(pValue);
end;

procedure TDraft2020_12ApplicatorVisitor.VisitPrefixItems(const pValue: TJSONArray);
begin
  inherited VisitPrefixItems(pValue);
end;

procedure TDraft2020_12ApplicatorVisitor.VisitDependentSchemas(const pValue: TJSONObject);
var
  lVisitor: IVisitor<TDraft2020_12Visitor>;
  lScope: TScope;
  lInstance: TJSONObject;
  lDependencyPair: TJSONPair;
  lSubScope: TScope;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
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
  UpdateScope(lScope);
end;

procedure TDraft2020_12ApplicatorVisitor.VisitUnevaluatedItems(const pValue: TJSONValue);
var
  lVisitor: IVisitor<TDraft2020_12Visitor>;
  lEvaluatedVisitor: TEvaluatedApplicatorVisitor<TDraft2020_12Visitor>;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lEvaluatedVisitor := TEvaluatedApplicatorVisitor<TDraft2020_12Visitor>.Create(Visitor,
    function (pPath: string): string
    begin
      Result := TJsonPathUtils.NormalizeToCanonical(pPath);
    end);
  try
    lEvaluatedVisitor.VisitUnevaluatedItems(pValue);
  finally
    lEvaluatedVisitor.Free;
  end;
end;

procedure TDraft2020_12ApplicatorVisitor.VisitUnevaluatedProperties(const pValue: TJSONValue);
var
  lVisitor: IVisitor<TDraft2020_12Visitor>;
  lEvaluatedVisitor: TEvaluatedApplicatorVisitor<TDraft2020_12Visitor>;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lEvaluatedVisitor := TEvaluatedApplicatorVisitor<TDraft2020_12Visitor>.Create(Visitor,
    function (pPath: string): string
    begin
      Result := TJsonPathUtils.NormalizeToCanonical(pPath);
    end);
  try
    lEvaluatedVisitor.VisitUnevaluatedProperties(pValue);
  finally
    lEvaluatedVisitor.Free;
  end;
end;

{ TDraft2020_12ValidationVisitor }

function TDraft2020_12ValidationVisitor.IsFormatAssertionEnabled: Boolean;
begin
  Result := TDraft2020_12Visitor(Visitor).IsFormatAssertionEnabled;
end;

procedure TDraft2020_12ValidationVisitor.VisitFormat(const pValue: TJSONString);
var
  lVisitor: IValidationVisitor<TDraft2020_12Visitor>;
  lScope: TScope;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) = 'string' then
    lVisitor.Result.AddAnnotation('format', pValue.Value);

  if not IsFormatAssertionEnabled then
    Exit;

  //inherited VisitFormat(pValue);
end;

procedure TDraft2020_12ValidationVisitor.VisitContains(const pValue: TJSONValue);
var
  lVisitor: IValidationVisitor<TDraft2020_12Visitor>;
  lScope: TScope;
  lInstance: TJSONArray;
  lCount: Integer;
  lSubVisitor: TDraft2020_12Visitor;
  lWalker: IWalker;
  lNewScope: TScope;
  lFound: Boolean;
  lMinContainsNode: TJSONValue;
  lMinimumContains: Integer;
  lItemPath: string;
  lCanonicalBase: string;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lInstance := TJSONArray(lScope.InstanceNode);
  lFound := False;
  lCanonicalBase := TJsonPathUtils.NormalizeToCanonical(lScope.InstancePath);
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
      lWalker := TWalker<TDraft2020_12Visitor>.Create(pValue, lSubVisitor);
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

  // minContains (default 1) and maxContains
  if (lScope.SchemaNode is TJSONObject) and
     TJSONObject(lScope.SchemaNode).TryGetValue('minContains', lMinContainsNode) and
     (lMinContainsNode is TJSONNumber) then
    lMinimumContains := TUtils.JsonGetInteger(TJSONNumber(lMinContainsNode))
  else
    lMinimumContains := 1;

  if not lFound and (lMinimumContains > 0) then
    lVisitor.AddError(TErrorType.vetContains)
  else if lFound and (lMinimumContains > 1) then
    lVisitor.AddError(TErrorType.vetMinContains, [lMinimumContains, 1]);

  if (lScope.SchemaNode is TJSONObject) and
     TJSONObject(lScope.SchemaNode).TryGetValue('maxContains', lMinContainsNode) and
     (lMinContainsNode is TJSONNumber) then
    VisitMaxContains(TJSONNumber(lMinContainsNode));

  UpdateScope(lScope);
end;

procedure TDraft2020_12ValidationVisitor.VisitMaxContains(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<TDraft2020_12Visitor>;
  lScope: TScope;
  lMax: Integer;
  lContainsCount: Integer;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  lMax := TUtils.JsonGetInteger(pValue);
  lContainsCount := lScope.ContainsCount;
  if lContainsCount > lMax then
    lVisitor.AddError(TErrorType.vetMaxContains, [lMax, lContainsCount]);
end;

procedure TDraft2020_12ValidationVisitor.VisitMinContains(const pValue: TJSONNumber);
var
  lVisitor: IValidationVisitor<TDraft2020_12Visitor>;
  lScope: TScope;
  lMin: Integer;
  lContainsCount: Integer;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
  lMin := TUtils.JsonGetInteger(pValue);
  lContainsCount := lScope.ContainsCount;
  if lContainsCount < lMin then
    if lMin = 1 then
      lVisitor.AddError(TErrorType.vetContains)
    else
      lVisitor.AddError(TErrorType.vetMinContains, [lMin, lContainsCount]);
end;

procedure TDraft2020_12ValidationVisitor.VisitDependentRequired(const pValue: TJSONObject);
var
  lVisitor: IValidationVisitor<TDraft2020_12Visitor>;
  lScope: TScope;
  lInstance: TJSONObject;
  lDependencyPair: TJSONPair;
  lRequiredList: TJSONArray;
  lRequiredValue: TJSONValue;
  lRequiredName: string;
begin
  lVisitor := Visitor;
  if not Assigned(lVisitor) then
    Exit;

  lScope := GetCurrentScope;
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

{ TDraft2020_12Visitor }

constructor TDraft2020_12Visitor.Create(const pSchema, pData: TJSONValue; const pBaseURI: string;
  const pCustomHint: TJSONValue);
var
  lSchemaURI: string;
begin
  inherited Create(pSchema, pData, pBaseURI, pCustomHint);

  FFormatAssertionEnabled := False;
  FValidationVocabularySilent := False;
  if (pSchema is TJSONObject) and
     TJSONObject(pSchema).TryGetValue<string>('$schema', lSchemaURI) and
     ContainsText(lSchemaURI, META_SCHEMA_NO_VALIDATION_URI) then
    FValidationVocabularySilent := True;

  FCore := TDraft2020_12CoreVisitor.Create(Self);
  FApplicator := TDraft2020_12ApplicatorVisitor.Create(Self);
  
  SetLength(FValidationComponents, 5);
  FValidationComponents[0] := TDraft2020_12ValidationVisitor.Create(Self);
  FValidationComponents[1] := TStringValidationVisitor<TDraft2020_12Visitor>.Create(Self);
  FValidationComponents[2] := TNumericValidationVisitor<TDraft2020_12Visitor>.Create(Self);
  FValidationComponents[3] := TArrayValidationVisitor<TDraft2020_12Visitor>.Create(Self);
  FValidationComponents[4] := TObjectValidationVisitor<TDraft2020_12Visitor>.Create(Self);

  FHyperSchema := TStubHyperSchemaVisitor<TDraft2020_12Visitor>.Create(Self);
  FRelativeJsonPointer := TStubRelativeJsonPointer<TDraft2020_12Visitor>.Create(Self);
end;

function TDraft2020_12Visitor.New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft2020_12Visitor;
begin
  Result := TDraft2020_12Visitor.Create(pSchema, pData, pBaseURI, FCustomHint);
  Result.FRegistry := FRegistry;
  Result.FOwnsRegistry := False;
  Result.FFormatAssertionEnabled := FFormatAssertionEnabled;
  Result.FValidationVocabularySilent := FValidationVocabularySilent;
end;

function TDraft2020_12Visitor.KeywordPrecedence: TArray<string>;
begin
  Result := [
    '$schema',
    '$vocabulary',
    '$id',
    '$ref',
    '$dynamicRef',
    '$anchor',
    '$dynamicAnchor',
    'properties',
    'patternProperties',
    'additionalProperties',
    'prefixItems',
    'items',
    'contains',
    'if',
    'allOf',
    'anyOf',
    'oneOf',
    'not',
    'then',
    'else',
    'dependentSchemas',
    'dependentRequired',
    'unevaluatedProperties',
    'unevaluatedItems'
  ];
end;

function TDraft2020_12Visitor.IsFormatAssertionEnabled: Boolean;
begin
  Result := FFormatAssertionEnabled;
end;

procedure TDraft2020_12Visitor.SetFormatAssertionEnabled(const pValue: Boolean);
begin
  FFormatAssertionEnabled := pValue;
end;

function TDraft2020_12Visitor.IsValidationVocabularySilent: Boolean;
begin
  Result := FValidationVocabularySilent;
end;

procedure TDraft2020_12Visitor.SetValidationVocabularySilent(const pValue: Boolean);
begin
  FValidationVocabularySilent := pValue;
end;

end.
