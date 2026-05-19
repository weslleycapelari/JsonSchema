unit JsonSchema.Validation.Draft2020_12;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Validation.Visitor.Core,
  JsonSchema.Validation.Visitor.Applicator,
  JsonSchema.Validation.Visitor.Validation;

type
  /// <summary>Main validator visitor for JSON Schema Draft 2020-12.</summary>
  TDraft2020_12Visitor = class(TValidationVisitor<TDraft2020_12Visitor>, IDraft2019_09ValidationVocabularyMode)
  private
    FFormatAssertionEnabled: Boolean;
    FValidationVocabularySilent: Boolean;
  public
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string; const pCustomHint: TJSONValue = nil);
    /// <summary>Creates a child visitor inheriting the current registry and configuration.</summary>
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft2020_12Visitor; override;
    /// <summary>Returns the keyword processing order specific to Draft 2020-12.</summary>
    function KeywordPrecedence: TArray<string>; override;
    function IsFormatAssertionEnabled: Boolean;
    procedure SetFormatAssertionEnabled(const pValue: Boolean);
    function IsValidationVocabularySilent: Boolean;
    procedure SetValidationVocabularySilent(const pValue: Boolean);
  end;

  /// <summary>Interface for Draft 2020-12 core keyword visitors.</summary>
  IDraft2020_12CoreVisitor = interface(IBaseCoreVisitor<TDraft2020_12Visitor>)
    ['{D73FF534-BC9D-4673-8C79-EF7D745FF989}']
    procedure VisitSchema(const pValue: TJSONString);
    procedure VisitComment(const pValue: TJSONString);
    procedure VisitAnchor(const pValue: TJSONString);
    procedure VisitDynamicRef(const pValue: TJSONString);
    procedure VisitDynamicAnchor(const pValue: TJSONString);
    procedure VisitVocabulary(const pValue: TJSONObject);
  end;

  /// <summary>Interface for Draft 2020-12 applicator keyword visitors.</summary>
  IDraft2020_12ApplicatorVisitor = interface(IBaseApplicatorVisitor<TDraft2020_12Visitor>)
    ['{93807819-1E9D-4017-A18B-67D5E9DDEC91}']
    procedure VisitItems(const pValue: TJSONValue);
    procedure VisitPrefixItems(const pValue: TJSONArray);
    procedure VisitDependentSchemas(const pValue: TJSONObject);
    procedure VisitUnevaluatedItems(const pValue: TJSONValue);
    procedure VisitUnevaluatedProperties(const pValue: TJSONValue);
  end;

  /// <summary>Interface for Draft 2020-12 validation keyword visitors.</summary>
  IDraft2020_12ValidationVisitor = interface(IBaseValidationVisitor<TDraft2020_12Visitor>)
    ['{5FCB391C-EA34-44F8-B46B-05423547C9F6}']
    procedure VisitContains(const pValue: TJSONValue);
    procedure VisitPropertyNames(const pValue: TJSONValue);
    procedure VisitDependentRequired(const pValue: TJSONObject);
    procedure VisitMaxContains(const pValue: TJSONNumber);
    procedure VisitMinContains(const pValue: TJSONNumber);
  end;

  /// <summary>Interface for Draft 2020-12 relative JSON pointer resolution.</summary>
  IDraft2020_12RelativeJsonPointer = interface(IBaseRelativeJsonPointer<TDraft2020_12Visitor>)
    ['{B4EA36F6-247C-41AA-BCC6-5A83AC80CE1B}']
  end;

  /// <summary>Implements core keyword visitors for JSON Schema Draft 2020-12.</summary>
  TDraft2020_12CoreVisitor = class(TBaseCoreVisitor<TDraft2020_12Visitor>, IDraft2020_12CoreVisitor)
    [VisitorKeyword('$schema')]
    procedure VisitSchema(const pValue: TJSONString);
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

  /// <summary>Implements applicator keyword visitors for JSON Schema Draft 2020-12.</summary>
  TDraft2020_12ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft2020_12Visitor>, IDraft2020_12ApplicatorVisitor)
    [VisitorKeyword('items')]
    procedure VisitItems(const pValue: TJSONValue);
    [VisitorKeyword('prefixItems')]
    procedure VisitPrefixItems(const pValue: TJSONArray);
    [VisitorKeyword('dependentSchemas')]
    procedure VisitDependentSchemas(const pValue: TJSONObject);
    [VisitorKeyword('unevaluatedItems')]
    procedure VisitUnevaluatedItems(const pValue: TJSONValue);
    [VisitorKeyword('unevaluatedProperties')]
    procedure VisitUnevaluatedProperties(const pValue: TJSONValue);
  end;

  /// <summary>Implements validation keyword visitors for JSON Schema Draft 2020-12.</summary>
  TDraft2020_12ValidationVisitor = class(TBaseValidationVisitor<TDraft2020_12Visitor>, IDraft2020_12ValidationVisitor)
  public
    [VisitorKeyword('format')]
    procedure VisitFormat(const pValue: TJSONString); reintroduce;
    [VisitorKeyword('contains')]
    procedure VisitContains(const pValue: TJSONValue);
    [VisitorKeyword('propertyNames')]
    procedure VisitPropertyNames(const pValue: TJSONValue);
    [VisitorKeyword('dependentRequired')]
    procedure VisitDependentRequired(const pValue: TJSONObject);
    [VisitorKeyword('maxContains')]
    procedure VisitMaxContains(const pValue: TJSONNumber);
    [VisitorKeyword('minContains')]
    procedure VisitMinContains(const pValue: TJSONNumber);
  end;

  /// <summary>Implements relative JSON pointer resolution for Draft 2020-12.</summary>
  TDraft2020_12RelativeJsonPointer = class(TBaseRelativeJsonPointer<TDraft2020_12Visitor>, IDraft2020_12RelativeJsonPointer)
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  System.StrUtils,
  System.Generics.Collections,
  JsonSchema.Common.Utils,
  JsonSchema.Translate.Types,
  JsonSchema.Walker,
  JsonSchema.Registry.Resource,
  JsonSchema.Registry.Uri;

function NormalizeToFullInstancePath(const pPath: string): string; forward;

{ TDraft2020_12Visitor }

constructor TDraft2020_12Visitor.Create(const pSchema, pData: TJSONValue; const pBaseURI: string; const pCustomHint: TJSONValue);
var
  lSchemaURI: string;
begin
  inherited Create(pSchema, pData, pBaseURI, pCustomHint);

  FFormatAssertionEnabled := False;
  FValidationVocabularySilent := False;
  if (pSchema is TJSONObject) and
     TJSONObject(pSchema).TryGetValue<string>('$schema', lSchemaURI) and
     ContainsText(lSchemaURI, 'metaschema-no-validation.json') then
    FValidationVocabularySilent := True;

  FCore                := TDraft2020_12CoreVisitor.Create(Self);
  FApplicator          := TDraft2020_12ApplicatorVisitor.Create(Self);
  FValidation          := TDraft2020_12ValidationVisitor.Create(Self);
  FRelativeJsonPointer := TDraft2020_12RelativeJsonPointer.Create(Self);
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
    'additionalItems',
    'if',
    'allOf',
    'anyOf',
    'oneOf',
    'unevaluatedProperties',
    'unevaluatedItems'
  ];
end;

function TDraft2020_12Visitor.New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft2020_12Visitor;
begin
  Result := TDraft2020_12Visitor.Create(pSchema, pData, pBaseURI, FCustomHint);
  Result.FRegistry.Free;
  Result.FRegistry := FRegistry;
  Result.FOwnsRegistry := False;
  Result.FFormatAssertionEnabled := FFormatAssertionEnabled;
  Result.FValidationVocabularySilent := FValidationVocabularySilent;
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

{ TDraft2020_12CoreVisitor }

/// <summary>Resolves $schema and configures format assertion and validation vocabulary modes.</summary>
procedure TDraft2020_12CoreVisitor.VisitSchema(const pValue: TJSONString);
const
  CValidationVocabularyURI = 'https://json-schema.org/draft/2020-12/vocab/validation';
  CValidationKeywords: array[0..17] of string = (
    'type',
    'multipleOf',
    'maximum',
    'exclusiveMaximum',
    'minimum',
    'exclusiveMinimum',
    'maxLength',
    'minLength',
    'pattern',
    'maxItems',
    'minItems',
    'uniqueItems',
    'maxProperties',
    'minProperties',
    'required',
    'enum',
    'const',
    'format'
  );
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
  // Em 2020-12, format é anotação por padrão.
  // A ativação estrita é controlada por $vocabulary no schema corrente.
  TDraft2020_12Visitor(Visitor).SetFormatAssertionEnabled(False);

  lScope := Visitor.CurrentScope;
  lSchemaURI := TURIReference.From(pValue.Value).ResolveWith(TURIReference.From(lScope.BaseURI));

  if not Visitor.Registry.TryFindResource(lSchemaURI.Unsplit, lMetaResource) then
  begin
    if ContainsText(lSchemaURI.Unsplit, 'metaschema-no-validation.json') then
      TDraft2020_12Visitor(Visitor).SetValidationVocabularySilent(True);
  end
  else
  begin
    lMetaSchemaRoot := lMetaResource.ResolveFragment('');
    if (lMetaSchemaRoot is TJSONObject) and
       TJSONObject(lMetaSchemaRoot).TryGetValue('$vocabulary', lVocabularyValue) and
       (lVocabularyValue is TJSONObject) and
       TJSONObject(lVocabularyValue).TryGetValue(CValidationVocabularyURI, lValidationVocabularyValue) and
       (lValidationVocabularyValue is TJSONBool) then
      lValidationVocabularyRequired := TJSONBool(lValidationVocabularyValue).AsBoolean
    else
      lValidationVocabularyRequired := True;

    TDraft2020_12Visitor(Visitor).SetValidationVocabularySilent(not lValidationVocabularyRequired);
  end;

  if TDraft2020_12Visitor(Visitor).IsValidationVocabularySilent then
    for lValidationKeyword in CValidationKeywords do
      Visitor.AddVisitedKeyword(lValidationKeyword);
end;

procedure TDraft2020_12CoreVisitor.VisitAnchor(const pValue: TJSONString);
begin

end;

procedure TDraft2020_12CoreVisitor.VisitComment(const pValue: TJSONString);
begin

end;

procedure TDraft2020_12CoreVisitor.VisitDynamicAnchor(const pValue: TJSONString);
begin

end;

/// <summary>Resolves $dynamicRef following the Draft 2020-12 dynamic scoping rules.</summary>
procedure TDraft2020_12CoreVisitor.VisitDynamicRef(const pValue: TJSONString);
var
  lScope: TScope;
  lFinalURI: TURIReference;
  lTargetResource: TResource;
  lTargetSchema: TJSONValue;
  lResolvedBaseURI: string;
  lTargetDynamicAnchorValue: TJSONValue;
  lDynamicAnchorName: string;
  lScopeAnchorValue: TJSONValue;
  lScopeAnchorName: string;
  lOffset: Integer;
  lMaxOffset: Integer;
  lDynamicBaseRef: TURIReference;
  lDynamicBaseURI: string;
  lDynamicRefValue: TJSONString;
  lOriginalScope: TScope;
  lScopeAfterRef: TScope;
  lResultEvaluatedBeforeRef: THashSet<string>;
  lScopeResource: TResource;
  lScopeAnchoredSchema: TJSONValue;

  function ResolveDynamicAnchor(const pResource: TResource; const pAnchorName: string; out pResolvedBaseURI: string): TJSONValue;
  begin
    Result := pResource.ResolveFragment(pAnchorName, pResolvedBaseURI);
    if Assigned(Result) then
      Exit;

    Result := pResource.ResolveFragment('#' + pAnchorName, pResolvedBaseURI);
  end;

  function NormalizeAnchorName(const pAnchor: string): string;
  begin
    Result := Trim(pAnchor);
    if Result.StartsWith('#') then
      Result := Result.Substring(1);
  end;

  function NormalizeLocalPath(const pPath: string): string;
  begin
    Result := Trim(pPath);

    if Result.IsEmpty or (Result = '#') then
      Exit('/');

    if Result.StartsWith('#/') then
      Result := Result.Substring(1)
    else if Result.StartsWith('#.') then
      Result := '/' + StringReplace(Result.Substring(2), '.', '/', [rfReplaceAll])
    else if Result.StartsWith('.') then
      Result := '/' + StringReplace(Result.Substring(1), '.', '/', [rfReplaceAll])
    else if not Result.StartsWith('/') then
      Result := '/' + Result;

    while Pos('//', Result) > 0 do
      Result := StringReplace(Result, '//', '/', [rfReplaceAll]);

    if Result.EndsWith('/') and (Result <> '/') then
      Delete(Result, Length(Result), 1);
  end;

  procedure InjectParentEvaluatedIntoCurrentScope;
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

  procedure ExecuteRefWithCurrentVisitor(const pRefValue: TJSONString);
  var
    lEvaluatedProperty: string;
    lNormalizedEvaluatedProperty: string;
    lScopeForSync: TScope;
    lCanonicalScopePath: string;
    lCanonicalPrefix: string;
    lRelativePath: string;
    lSegmentSeparator: Integer;
    lFirstSegment: string;
    lItemIndex: Integer;
  begin
    InjectParentEvaluatedIntoCurrentScope;

    lResultEvaluatedBeforeRef := THashSet<string>.Create;
    for lEvaluatedProperty in Visitor.Result.EvaluatedProperties do
      lResultEvaluatedBeforeRef.Add(NormalizeLocalPath(lEvaluatedProperty));

    lOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(pRefValue);

      lScopeForSync := Visitor.CurrentScope;
      if not Assigned(lScopeForSync.EvaluatedPropertiesInScope) then
        lScopeForSync.EvaluatedPropertiesInScope := THashSet<string>.Create;

      for lEvaluatedProperty in Visitor.Result.EvaluatedProperties do
      begin
        lNormalizedEvaluatedProperty := NormalizeLocalPath(lEvaluatedProperty);
        if lResultEvaluatedBeforeRef.Contains(lNormalizedEvaluatedProperty) then
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
      lResultEvaluatedBeforeRef.Free;

      lScopeAfterRef := Visitor.CurrentScope;
      if not SameText(lScopeAfterRef.BaseURI, lOriginalScope.BaseURI) then
      begin
        lScopeAfterRef.BaseURI := lOriginalScope.BaseURI;
        Visitor.UpdateScope(lScopeAfterRef);
      end;
    end;
  end;

begin
  lScope := Visitor.CurrentScope;
  lFinalURI := TURIReference.From(pValue.Value).ResolveWith(TURIReference.From(lScope.BaseURI));
  lDynamicAnchorName := NormalizeAnchorName(lFinalURI.Fragment);

  if lDynamicAnchorName.IsEmpty or lDynamicAnchorName.StartsWith('/') then
  begin
    ExecuteRefWithCurrentVisitor(pValue);
    Exit;
  end;

  // Regra estrita: só aplica escopo dinâmico se o alvo original for dynamic anchor válido.
  if not Visitor.Registry.TryFindResource(lFinalURI.Unsplit, lTargetResource) then
  begin
    ExecuteRefWithCurrentVisitor(pValue);
    Exit;
  end;

  lTargetSchema := ResolveDynamicAnchor(lTargetResource, lDynamicAnchorName, lResolvedBaseURI);
  if not Assigned(lTargetSchema) then
  begin
    ExecuteRefWithCurrentVisitor(pValue);
    Exit;
  end;

  if not ((lTargetSchema is TJSONObject) and
          TJSONObject(lTargetSchema).TryGetValue('$dynamicAnchor', lTargetDynamicAnchorValue) and
          (lTargetDynamicAnchorValue is TJSONString) and
          SameText(NormalizeAnchorName(TJSONString(lTargetDynamicAnchorValue).Value), lDynamicAnchorName)) then
  begin
    ExecuteRefWithCurrentVisitor(pValue);
    Exit;
  end;

  lDynamicBaseURI := '';
  lMaxOffset := -1;
  lOffset := 0;
  while Assigned(Visitor.CurrentScope(lOffset).SchemaNode) do
  begin
    lMaxOffset := lOffset;
    Inc(lOffset);
  end;

  // Spec: traverse from outermost (root) to innermost scope.
  // For each scope, resolve the anchor via Registry by BaseURI — not by inspecting SchemaNode directly,
  // because the $dynamicAnchor may live in a $defs sub-schema, not at the root of the scope's SchemaNode.
  for lOffset := lMaxOffset downto 0 do
  begin
    lScope := Visitor.CurrentScope(lOffset);
    if lScope.BaseURI.IsEmpty then
      Continue;

    if not Visitor.Registry.TryFindResource(lScope.BaseURI, lScopeResource) then
      Continue;

    lScopeAnchoredSchema := ResolveDynamicAnchor(lScopeResource, lDynamicAnchorName, lResolvedBaseURI);
    if not Assigned(lScopeAnchoredSchema) then
      Continue;

    if not ((lScopeAnchoredSchema is TJSONObject) and
            TJSONObject(lScopeAnchoredSchema).TryGetValue('$dynamicAnchor', lScopeAnchorValue) and
            (lScopeAnchorValue is TJSONString)) then
      Continue;

    lScopeAnchorName := NormalizeAnchorName(TJSONString(lScopeAnchorValue).Value);
    if not SameText(lScopeAnchorName, lDynamicAnchorName) then
      Continue;

    lDynamicBaseRef := TURIReference.From(lScope.BaseURI);
    lDynamicBaseRef.Query := '';
    lDynamicBaseRef.Fragment := '';
    lDynamicBaseURI := lDynamicBaseRef.Unsplit;
    Break;
  end;

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

/// <summary>Reads $vocabulary to configure format assertion enforcement.</summary>
procedure TDraft2020_12CoreVisitor.VisitVocabulary(const pValue: TJSONObject);
const
  CFormatAssertionVocabularyURI = 'https://json-schema.org/draft/2020-12/vocab/format-assertion';
var
  lFormatAssertionValue: TJSONValue;
  lFormatAssertionEnabled: Boolean;
begin
  lFormatAssertionEnabled := False;

  if pValue.TryGetValue(CFormatAssertionVocabularyURI, lFormatAssertionValue) and
     (lFormatAssertionValue is TJSONBool) and
     TJSONBool(lFormatAssertionValue).AsBoolean then
    lFormatAssertionEnabled := True;

  TDraft2020_12Visitor(Visitor).SetFormatAssertionEnabled(lFormatAssertionEnabled);
end;

{ TDraft2020_12ValidationVisitor }

/// <summary>Validates the "format" keyword, asserting only when format-assertion vocabulary is active.</summary>
procedure TDraft2020_12ValidationVisitor.VisitFormat(const pValue: TJSONString);
begin
  Visitor.Result.AddEvaluatedProperty(NormalizeToFullInstancePath(Visitor.CurrentScope.InstancePath));
  Visitor.Result.AddAnnotation('format', pValue.Value);

  if not TDraft2020_12Visitor(Visitor).FFormatAssertionEnabled then
    Exit;

  inherited VisitFormat(pValue);
end;

/// <summary>Validates the "contains" keyword and tracks covered item indices for unevaluated resolution.</summary>
procedure TDraft2020_12ValidationVisitor.VisitContains(const pValue: TJSONValue);
var
  lScope: TScope;
  lCount: Integer;
  lWalker: IWalker;
  lSchema: TJSONNumber;
  lVisitor: TDraft2020_12Visitor;
  lNewScope: TScope;
  lInstance: TJSONArray;
  lItemPath: string;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  if pValue is TJSONBool then
  begin
    if TJSONBool(pValue).AsBoolean and (TJSONArray(lScope.InstanceNode).Count > 0) then
    begin
      lInstance := TJSONArray(lScope.InstanceNode);
      for lCount := 0 to lInstance.Count - 1 do
      begin
        TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
        lItemPath := NormalizeToFullInstancePath(Format('%s/%d', [lScope.InstancePath, lCount]));
        Visitor.Result.AddEvaluatedProperty(lItemPath);
      end;
      Visitor.UpdateScope(lScope);
      Exit;
    end;

    if not TJSONBool(pValue).AsBoolean then
    begin
       Visitor.AddError(vetContains);
       Exit;
    end;
  end;

  lInstance := TJSONArray(lScope.InstanceNode);
  for lCount := 0 to lInstance.Count - 1 do
  begin
    lNewScope := lScope;
    lNewScope.SchemaPath        := Format('%s/contains', [lScope.SchemaPath]);
    lNewScope.SchemaNode        := pValue;
    lNewScope.InstanceNode      := lInstance[lCount];
    lNewScope.InstancePath      := Format('%s/%d', [lScope.InstancePath, lCount]);
    lNewScope.CoveredItems      := [];
    lNewScope.ContainsCount     := 0;
    lNewScope.VisitedKeywords   := [];
    lNewScope.CoveredProperties := [];

    Visitor.PushScope(lNewScope);
    lVisitor := Visitor.New(pValue, lInstance[lCount], lScope.BaseURI);
    try
      lWalker := TWalker<TDraft2020_12Visitor>.Create(pValue, lVisitor);
      lWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    if lVisitor.Result.IsValid then
    begin
      Inc(lScope.ContainsCount);
      TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
      lItemPath := NormalizeToFullInstancePath(Format('%s/%d', [lScope.InstancePath, lCount]));
      Visitor.Result.AddEvaluatedProperty(lItemPath);
    end;
  end;

  Visitor.UpdateScope(lScope);

  if not lScope.SchemaNode.TryGetValue('minContains', lSchema) then
    lSchema := TJSONNumber.Create(1);

  VisitMinContains(lSchema);

  if lScope.SchemaNode.TryGetValue('maxContains', lSchema) then
    VisitMaxContains(lSchema);

  Visitor
    .AddVisitedKeyword('minContains')
    .AddVisitedKeyword('maxContains');
end;

/// <summary>Validates the "dependentRequired" keyword against the instance object.</summary>
procedure TDraft2020_12ValidationVisitor.VisitDependentRequired(const pValue: TJSONObject);
var
  lScope: TScope;
  lInstance: TJSONObject;
  lDependencyPair: TJSONPair;
  lRequiredList: TJSONArray;
  lRequiredValue: TJSONValue;
  lRequiredName: string;
begin
  lScope := Visitor.CurrentScope;
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
        Visitor.AddError(vetDependentRequired, [lDependencyPair.JsonString.Value, lRequiredName]);
    end;
  end;
end;

/// <summary>Validates the "maxContains" keyword against the contains count accumulated in the current scope.</summary>
procedure TDraft2020_12ValidationVisitor.VisitMaxContains(const pValue: TJSONNumber);
var
  lScope: TScope;
  lMaximum: Integer;
begin
  lScope := Visitor.CurrentScope;
  if lScope.SchemaNode.FindValue('contains') = nil then
    Exit;

  lMaximum := TUtils.JsonGetInteger(pValue);
  if lScope.ContainsCount > lMaximum then
    Visitor.AddError(vetMaxContains, [lMaximum, lScope.ContainsCount]);
end;

/// <summary>Validates the "minContains" keyword against the contains count accumulated in the current scope.</summary>
procedure TDraft2020_12ValidationVisitor.VisitMinContains(const pValue: TJSONNumber);
var
  lScope: TScope;
  lMinimum: Integer;
begin
  lScope := Visitor.CurrentScope;
  if lScope.SchemaNode.FindValue('contains') = nil then
    Exit;

  lMinimum := TUtils.JsonGetInteger(pValue);
  if lScope.ContainsCount < lMinimum then
    if lMinimum = 1 then
      Visitor.AddError(vetContains)
    else
      Visitor.AddError(vetMinContains, [lMinimum, lScope.ContainsCount]);
end;

procedure TDraft2020_12ValidationVisitor.VisitPropertyNames(const pValue: TJSONValue);
begin
  inherited VisitPropertyNames(pValue);
end;

{ TDraft2020_12ApplicatorVisitor }

procedure TDraft2020_12ApplicatorVisitor.VisitItems(const pValue: TJSONValue);
begin
  // Em 2020-12, tuple validation foi movida para prefixItems.
  if pValue is TJSONArray then
    Exit;

  inherited VisitItems(pValue);
end;

procedure TDraft2020_12ApplicatorVisitor.VisitPrefixItems(const pValue: TJSONArray);
begin
  inherited VisitPrefixItems(pValue);
end;

/// <summary>Validates the "dependentSchemas" keyword and propagates evaluated properties to the parent scope.</summary>
procedure TDraft2020_12ApplicatorVisitor.VisitDependentSchemas(const pValue: TJSONObject);
var
  lScope: TScope;
  lInstance: TJSONObject;
  lDependencyPair: TJSONPair;
  lSubSchema: TJSONValue;
  lNewScope: TScope;
  lWalker: IWalker;
  lErrorCount: Integer;
  lResultEvaluatedBefore: THashSet<string>;
  lEvaluatedProperty: string;
  lNormalizedEvaluatedProperty: string;
  lCanonicalScopePath: string;
  lCanonicalPrefix: string;
  lRelativePath: string;
  lSegmentSeparator: Integer;
  lFirstSegment: string;
  lItemIndex: Integer;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lResultEvaluatedBefore := THashSet<string>.Create;
  try
    for lEvaluatedProperty in Visitor.Result.EvaluatedProperties do
      lResultEvaluatedBefore.Add(lEvaluatedProperty);

  lInstance := TJSONObject(lScope.InstanceNode);
  for lDependencyPair in pValue do
  begin
    if lInstance.FindValue(lDependencyPair.JsonString.Value) <> nil then
    begin
      lSubSchema := lDependencyPair.JsonValue;

      lNewScope := lScope;
      lNewScope.SchemaPath        := Format('%s/dependentSchemas/%s', [lScope.SchemaPath, lDependencyPair.JsonString.Value]);
      lNewScope.SchemaNode        := lSubSchema;
      lNewScope.CoveredItems      := [];
      lNewScope.ContainsCount     := 0;
      lNewScope.VisitedKeywords   := [];
      lNewScope.CoveredProperties := [];

      Visitor.PushScope(lNewScope);
      lErrorCount := Length(Visitor.Result.Errors);
      try
        lWalker := TWalker<TDraft2020_12Visitor>.Create(lSubSchema, Visitor);
        lWalker.Walk;
      finally
        lNewScope := Visitor.PopScope;
      end;

      if Length(Visitor.Result.Errors) = lErrorCount then
      begin
        lScope.CoveredItems := TUtils.MergeArray<Integer>([lScope.CoveredItems, lNewScope.CoveredItems]);
        lScope.CoveredProperties := TUtils.MergeArray<string>([lScope.CoveredProperties, lNewScope.CoveredProperties]);

        if not Assigned(lScope.EvaluatedPropertiesInScope) then
          lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

        if Assigned(lNewScope.EvaluatedPropertiesInScope) then
          for lEvaluatedProperty in lNewScope.EvaluatedPropertiesInScope do
            lScope.EvaluatedPropertiesInScope.Add(lEvaluatedProperty);

        lCanonicalScopePath := NormalizeToFullInstancePath(lScope.InstancePath);
        if lCanonicalScopePath = '/' then
          lCanonicalPrefix := '/'
        else
          lCanonicalPrefix := lCanonicalScopePath + '/';

        for lEvaluatedProperty in Visitor.Result.EvaluatedProperties do
        begin
          if lResultEvaluatedBefore.Contains(lEvaluatedProperty) then
            Continue;

          lNormalizedEvaluatedProperty := NormalizeToFullInstancePath(lEvaluatedProperty);
          lScope.EvaluatedPropertiesInScope.Add(lNormalizedEvaluatedProperty);

          if not lNormalizedEvaluatedProperty.StartsWith(lCanonicalPrefix) then
            Continue;

          lRelativePath := lNormalizedEvaluatedProperty.Substring(Length(lCanonicalPrefix));
          lSegmentSeparator := Pos('/', lRelativePath);
          if lSegmentSeparator > 0 then
            lFirstSegment := Copy(lRelativePath, 1, lSegmentSeparator - 1)
          else
            lFirstSegment := lRelativePath;

          if TryStrToInt(lFirstSegment, lItemIndex) then
            TUtils.AddArray<Integer>(lScope.CoveredItems, lItemIndex)
          else if lFirstSegment <> '' then
            TUtils.AddArray<string>(lScope.CoveredProperties, lFirstSegment);
        end;
      end;
    end;
  end;

  Visitor.UpdateScope(lScope);
  finally
    lResultEvaluatedBefore.Free;
  end;
end;

function NormalizeToFullInstancePath(const pPath: string): string;
begin
  Result := Trim(pPath);

  if Result.IsEmpty or (Result = '#') then
    Exit('/');

  if Result.StartsWith('#/') then
    Result := Result.Substring(1)
  else if Result.StartsWith('#.') then
    Result := '/' + StringReplace(Result.Substring(2), '.', '/', [rfReplaceAll])
  else if Result.StartsWith('.') then
    Result := '/' + StringReplace(Result.Substring(1), '.', '/', [rfReplaceAll])
  else if not Result.StartsWith('/') then
    Result := '/' + Result;

  while Pos('//', Result) > 0 do
    Result := StringReplace(Result, '//', '/', [rfReplaceAll]);

  if Result.EndsWith('/') and (Result <> '/') then
    Delete(Result, Length(Result), 1);
end;

/// <summary>Validates the "unevaluatedItems" keyword against array items not covered by prior keywords.</summary>
procedure TDraft2020_12ApplicatorVisitor.VisitUnevaluatedItems(const pValue: TJSONValue);
var
  lCount: Integer;
  lScope: TScope;
  lWalker: IWalker;
  lEvaluated: THashSet<string>;
  lEvaluatedPath: string;
  lCoveredIndex: Integer;
  lNewScope: TScope;
  lErrorCount: Integer;
  lCurrentPrefix: string;
  lCanonicalPrefix: string;
  lCanonicalPath: string;
  lItemPath: string;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  if (TUtils.JsonGetType(pValue) = 'boolean') and TJSONBool(pValue).AsBoolean then
  begin
    lCurrentPrefix := NormalizeToFullInstancePath(lScope.InstancePath);
    if lCurrentPrefix.EndsWith('/') then
      lCanonicalPrefix := lCurrentPrefix
    else
      lCanonicalPrefix := lCurrentPrefix + '/';

    for lCount := 0 to TJSONArray(lScope.InstanceNode).Count - 1 do
    begin
      TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
      lItemPath := Format('%s%d', [lCanonicalPrefix, lCount]);
      Visitor.Result.AddEvaluatedProperty(lItemPath);
    end;

    Visitor.UpdateScope(lScope);
    Exit;
  end;

  lEvaluated := THashSet<string>.Create;
  try
    lCurrentPrefix := NormalizeToFullInstancePath(lScope.InstancePath);
    if lCurrentPrefix.EndsWith('/') then
      lCanonicalPrefix := lCurrentPrefix
    else
      lCanonicalPrefix := lCurrentPrefix + '/';

    for lEvaluatedPath in Visitor.Result.EvaluatedProperties do
    begin
      lCanonicalPath := NormalizeToFullInstancePath(lEvaluatedPath);
      lEvaluated.Add(lCanonicalPath);
    end;

    for lCoveredIndex in lScope.CoveredItems do
      lEvaluated.Add(Format('%s%d', [lCanonicalPrefix, lCoveredIndex]));

    for lCount := 0 to TJSONArray(lScope.InstanceNode).Count - 1 do
    begin
      lItemPath := Format('%s%d', [lCanonicalPrefix, lCount]);
      if lEvaluated.Contains(lItemPath) then
        Continue;

      lNewScope := lScope;
      lNewScope.SchemaPath        := Format('%s/unevaluatedItems', [lScope.SchemaPath]);
      lNewScope.SchemaNode        := pValue;
      lNewScope.InstanceNode      := TJSONArray(lScope.InstanceNode)[lCount];
      lNewScope.InstancePath      := Format('%s/%d', [lScope.InstancePath, lCount]);
      lNewScope.CoveredItems      := [];
      lNewScope.ContainsCount     := 0;
      lNewScope.VisitedKeywords   := [];
      lNewScope.CoveredProperties := [];

      Visitor.PushScope(lNewScope);
      lErrorCount := Length(Visitor.Result.Errors);
      try
        lWalker := TWalker<TDraft2020_12Visitor>.Create(pValue, Visitor);
        lWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      if Length(Visitor.Result.Errors) > lErrorCount then
        Visitor.AddError(vetUnevaluatedItems, [lCount]);

      TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
      Visitor.Result.AddEvaluatedProperty(lItemPath);
    end;
  finally
    lEvaluated.Free;
  end;

  Visitor.UpdateScope(lScope);
end;

/// <summary>Validates the "unevaluatedProperties" keyword against object properties not covered by prior keywords.</summary>
procedure TDraft2020_12ApplicatorVisitor.VisitUnevaluatedProperties(const pValue: TJSONValue);
var
  lPair: TJSONPair;
  lScope: TScope;
  lWalker: IWalker;
  lEvaluated: THashSet<string>;
  lEvaluatedProp: string;
  lCoveredProp: string;
  lNewScope: TScope;
  lErrorCount: Integer;
  lPropKey: string;
  lCurrentPrefix: string;
  lCanonicalPath: string;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  if (TUtils.JsonGetType(pValue) = 'boolean') and TJSONBool(pValue).AsBoolean then
  begin
    lCurrentPrefix := NormalizeToFullInstancePath(lScope.InstancePath);
    if not lCurrentPrefix.EndsWith('/') then
      lCurrentPrefix := lCurrentPrefix + '/';

    if not Assigned(lScope.EvaluatedPropertiesInScope) then
      lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

    for lPair in TJSONObject(lScope.InstanceNode) do
    begin
      lPropKey := lCurrentPrefix + lPair.JsonString.Value;
      TUtils.AddArray<string>(lScope.CoveredProperties, lPair.JsonString.Value);
      lScope.EvaluatedPropertiesInScope.Add(lPropKey);
      Visitor.Result.AddEvaluatedProperty(lPropKey);
    end;

    Visitor.UpdateScope(lScope);
    Exit;
  end;

  lEvaluated := THashSet<string>.Create;
  try
    lCurrentPrefix := NormalizeToFullInstancePath(lScope.InstancePath);
    if lCurrentPrefix.EndsWith('/') then
      lCurrentPrefix := lCurrentPrefix
    else
      lCurrentPrefix := lCurrentPrefix + '/';

    for lEvaluatedProp in Visitor.Result.EvaluatedProperties do
    begin
      lCanonicalPath := NormalizeToFullInstancePath(lEvaluatedProp);
      lEvaluated.Add(lCanonicalPath);
    end;

    for lCoveredProp in lScope.CoveredProperties do
      lEvaluated.Add(lCurrentPrefix + lCoveredProp);

    for lPair in TJSONObject(lScope.InstanceNode) do
    begin
      lPropKey := lCurrentPrefix + lPair.JsonString.Value;
      if lEvaluated.Contains(lPropKey) then
        Continue;

      lNewScope := lScope;
      lNewScope.SchemaPath        := Format('%s/unevaluatedProperties', [lScope.SchemaPath]);
      lNewScope.SchemaNode        := pValue;
      lNewScope.InstanceNode      := lPair.JsonValue;
      lNewScope.InstancePath      := Format('%s/%s', [lScope.InstancePath, lPair.JsonString.Value]);
      lNewScope.CoveredItems      := [];
      lNewScope.ContainsCount     := 0;
      lNewScope.VisitedKeywords   := [];
      lNewScope.CoveredProperties := [];

      Visitor.PushScope(lNewScope);
      lErrorCount := Length(Visitor.Result.Errors);
      try
        lWalker := TWalker<TDraft2020_12Visitor>.Create(pValue, Visitor);
        lWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      if Length(Visitor.Result.Errors) > lErrorCount then
        Visitor.AddError(vetUnevaluatedProperties, [lPair.JsonString.Value])
      else
      begin
        TUtils.AddArray<string>(lScope.CoveredProperties, lPair.JsonString.Value);
        if not Assigned(lScope.EvaluatedPropertiesInScope) then
          lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
        lScope.EvaluatedPropertiesInScope.Add(lPropKey);
        Visitor.Result.AddEvaluatedProperty(lPropKey);
      end;
    end;
  finally
    lEvaluated.Free;
  end;

  Visitor.UpdateScope(lScope);
end;

end.
