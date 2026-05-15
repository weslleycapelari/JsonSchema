unit JsonSchema.Validation.Draft2019_09;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces;

type
  IDraft2019_09ValidationVocabularyMode = interface(IInterface)
    ['{7D1B6A0D-31EA-4F2F-9A45-77A2D65A8E5B}']
    function IsValidationVocabularySilent: Boolean;
    procedure SetValidationVocabularySilent(const AValue: Boolean);
  end;

  TDraft2019_09Visitor = class(TValidationVisitor<TDraft2019_09Visitor>, IDraft2019_09ValidationVocabularyMode)
  private
    FValidationVocabularySilent: Boolean;
  public
    constructor Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue = nil);
    function New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft2019_09Visitor; override;
    function KeywordPrecedence: TArray<string>; override;
    function IsValidationVocabularySilent: Boolean;
    procedure SetValidationVocabularySilent(const AValue: Boolean);
  end;

  IDraft2019_09CoreVisitor = interface(IBaseCoreVisitor<TDraft2019_09Visitor>)
    ['{4B72E0CE-AFBF-4C25-92CC-EA0509595809}']
    procedure VisitSchema(const AValue: TJSONString);
    procedure VisitComment(const AValue: TJSONString);
    procedure VisitAnchor(const AValue: TJSONString);
    procedure VisitRecursiveRef(const AValue: TJSONString);
    procedure VisitRecursiveAnchor(const AValue: TJSONBool);
    procedure VisitVocabulary(const AValue: TJSONObject);
  end;

  IDraft2019_09ApplicatorVisitor = interface(IBaseApplicatorVisitor<TDraft2019_09Visitor>)
    ['{44142A26-AC72-414C-BB83-75DA511A0A36}']
    procedure VisitDependentSchemas(const AValue: TJSONObject);
    procedure VisitUnevaluatedItems(const AValue: TJSONValue);
    procedure VisitUnevaluatedProperties(const AValue: TJSONValue);
  end;

  IDraft2019_09ValidationVisitor = interface(IBaseValidationVisitor<TDraft2019_09Visitor>)
    ['{E995D611-5477-4970-B791-81A4555AF554}']
    procedure VisitContains(const AValue: TJSONValue);
    procedure VisitPropertyNames(const AValue: TJSONValue);
    procedure VisitDependencies(const AValue: TJSONObject);
    procedure VisitDependentRequired(const AValue: TJSONObject);
    procedure VisitMaxContains(const AValue: TJSONNumber);
    procedure VisitMinContains(const AValue: TJSONNumber);
  end;

  IDraft2019_09HyperSchemaVisitor = interface(IBaseHyperSchemaVisitor<TDraft2019_09Visitor>)
    procedure VisitRel(const AValue: TJSONString);
    procedure VisitTitle(const AValue: TJSONString);
    procedure VisitAnchor(const AValue: TJSONString);
    procedure VisitAnchorPointer(const AValue: TJSONString);
    procedure VisitTemplatePointers(const AValue: TJSONObject);
    procedure VisitTemplateRequired(const AValue: TJSONArray);
    procedure VisitDescription(const AValue: TJSONString);
    procedure VisitTargetMediaType(const AValue: TJSONString);
    procedure VisitTargetHints(const AValue: TJSONObject);
    procedure VisitHeaderSchema(const AValue: TJSONValue);
    procedure VisitSubmissionMediaType(const AValue: TJSONString);
  end;

  IDraft2019_09RelativeJsonPointer = interface(IBaseRelativeJsonPointer<TDraft2019_09Visitor>)
    ['{E40B5CE3-7207-430E-81BA-07A8E798EC60}']
  end;

  TDraft2019_09CoreVisitor = class(TBaseCoreVisitor<TDraft2019_09Visitor>, IDraft2019_09CoreVisitor)
    [VisitorKeyword('$schema')]
    procedure VisitSchema(const AValue: TJSONString);
    [VisitorKeyword('$comment')]
    procedure VisitComment(const AValue: TJSONString);
    [VisitorKeyword('$anchor')]
    procedure VisitAnchor(const AValue: TJSONString);
    [VisitorKeyword('$recursiveRef')]
    procedure VisitRecursiveRef(const AValue: TJSONString);
    [VisitorKeyword('$recursiveAnchor')]
    procedure VisitRecursiveAnchor(const AValue: TJSONBool);
    [VisitorKeyword('$vocabulary')]
    procedure VisitVocabulary(const AValue: TJSONObject);
  end;

  TDraft2019_09ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft2019_09Visitor>, IDraft2019_09ApplicatorVisitor)
    [VisitorKeyword('$defs')]
    procedure VisitDefs(const AValue: TJSONObject);
    [VisitorKeyword('dependentSchemas')]
    procedure VisitDependentSchemas(const AValue: TJSONObject);
    [VisitorKeyword('unevaluatedItems')]
    procedure VisitUnevaluatedItems(const AValue: TJSONValue);
    [VisitorKeyword('unevaluatedProperties')]
    procedure VisitUnevaluatedProperties(const AValue: TJSONValue);
  end;

  TDraft2019_09ValidationVisitor = class(TBaseValidationVisitor<TDraft2019_09Visitor>, IDraft2019_09ValidationVisitor)
    [VisitorKeyword('contentEncoding')]
    procedure VisitContentEncoding(const AValue: TJSONString);
    [VisitorKeyword('contentMediaType')]
    procedure VisitContentMediaType(const AValue: TJSONString);
    [VisitorKeyword('contains')]
    procedure VisitContains(const AValue: TJSONValue);
    [VisitorKeyword('propertyNames')]
    procedure VisitPropertyNames(const AValue: TJSONValue);
    [VisitorKeyword('dependencies')]
    procedure VisitDependencies(const AValue: TJSONObject);
    [VisitorKeyword('dependentRequired')]
    procedure VisitDependentRequired(const AValue: TJSONObject);
    [VisitorKeyword('maxContains')]
    procedure VisitMaxContains(const AValue: TJSONNumber);
    [VisitorKeyword('minContains')]
    procedure VisitMinContains(const AValue: TJSONNumber);
  end;

  TDraft2019_09HyperSchemaVisitor = class(TBaseHyperSchemaVisitor<TDraft2019_09Visitor>, IDraft2019_09HyperSchemaVisitor)
    [VisitorKeyword('rel')]
    procedure VisitRel(const AValue: TJSONString);
    [VisitorKeyword('title')]
    procedure VisitTitle(const AValue: TJSONString);
    [VisitorKeyword('anchor')]
    procedure VisitAnchor(const AValue: TJSONString);
    [VisitorKeyword('anchorPointer')]
    procedure VisitAnchorPointer(const AValue: TJSONString);
    [VisitorKeyword('templatePointers')]
    procedure VisitTemplatePointers(const AValue: TJSONObject);
    [VisitorKeyword('templateRequired')]
    procedure VisitTemplateRequired(const AValue: TJSONArray);
    [VisitorKeyword('description')]
    procedure VisitDescription(const AValue: TJSONString);
    [VisitorKeyword('targetMediaType')]
    procedure VisitTargetMediaType(const AValue: TJSONString);
    [VisitorKeyword('targetHints')]
    procedure VisitTargetHints(const AValue: TJSONObject);
    [VisitorKeyword('headerSchema')]
    procedure VisitHeaderSchema(const AValue: TJSONValue);
    [VisitorKeyword('submissionMediaType')]
    procedure VisitSubmissionMediaType(const AValue: TJSONString);
  end;

  TDraft2019_09RelativeJsonPointer = class(TBaseRelativeJsonPointer<TDraft2019_09Visitor>, IDraft2019_09RelativeJsonPointer)
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

{ TDraft2019_09Visitor }

constructor TDraft2019_09Visitor.Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue);
begin
  inherited Create(ASchema, AData, ABaseURI, ACustomHint);

  FValidationVocabularySilent := False;

  FCore                := TDraft2019_09CoreVisitor.Create(Self);
  FApplicator          := TDraft2019_09ApplicatorVisitor.Create(Self);
  FValidation          := TDraft2019_09ValidationVisitor.Create(Self);
  FHyperSchema         := TDraft2019_09HyperSchemaVisitor.Create(Self);
  FRelativeJsonPointer := TDraft2019_09RelativeJsonPointer.Create(Self);
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
    'prefixItems',
    'items',
    'contains',
    'additionalItems',
    'if',
    'allOf',
    'anyOf',
    'oneOf',
    'dependentSchemas',
    'unevaluatedProperties',
    'unevaluatedItems'
  ];
end;

function TDraft2019_09Visitor.IsValidationVocabularySilent: Boolean;
begin
  Result := FValidationVocabularySilent;
end;

function TDraft2019_09Visitor.New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft2019_09Visitor;
begin
  Result := TDraft2019_09Visitor.Create(ASchema, AData, ABaseURI, FCustomHint);
  Result.FRegistry.Free;
  Result.FRegistry := FRegistry;
  Result.FOwnsRegistry := False;
  Result.FValidationVocabularySilent := FValidationVocabularySilent;
end;

procedure TDraft2019_09Visitor.SetValidationVocabularySilent(const AValue: Boolean);
begin
  FValidationVocabularySilent := AValue;
end;

{ TDraft2019_09CoreVisitor }

procedure TDraft2019_09CoreVisitor.VisitAnchor(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09CoreVisitor.VisitComment(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09CoreVisitor.VisitRecursiveAnchor(const AValue: TJSONBool);
begin

end;

procedure TDraft2019_09CoreVisitor.VisitRecursiveRef(const AValue: TJSONString);
var
  LScope: TScope;
  LFinalURI: TURIReference;
  LTargetResource: TResource;
  LTargetSchema: TJSONValue;
  LResolvedBaseURI: string;
  LTargetRecursiveAnchor: TJSONValue;
  LScopes: TList<TScope>;
  LScopeIndex: Integer;
  LOffset: Integer;
  LRecursiveBaseURI: string;
  LAnchorValue: TJSONValue;
  LRecursiveRefValue: TJSONString;
  LHasRecursiveAnchor: Boolean;
  LOriginalScope: TScope;
  LScopeAfterRef: TScope;
begin
  LScope := Visitor.CurrentScope;
  LFinalURI := TURIReference.From(AValue.Value).ResolveWith(TURIReference.From(LScope.BaseURI));

  if not Visitor.Registry.TryFindResource(LFinalURI.Unsplit, LTargetResource) then
  begin
    LOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(AValue);
    finally
      LScopeAfterRef := Visitor.CurrentScope;
      if not SameText(LScopeAfterRef.BaseURI, LOriginalScope.BaseURI) then
      begin
        LScopeAfterRef.BaseURI := LOriginalScope.BaseURI;
        Visitor.UpdateScope(LScopeAfterRef);
      end;
    end;
    Exit;
  end;

  LTargetSchema := LTargetResource.ResolveFragment(LFinalURI.Fragment, LResolvedBaseURI);
  if not Assigned(LTargetSchema) then
  begin
    LOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(AValue);
    finally
      LScopeAfterRef := Visitor.CurrentScope;
      if not SameText(LScopeAfterRef.BaseURI, LOriginalScope.BaseURI) then
      begin
        LScopeAfterRef.BaseURI := LOriginalScope.BaseURI;
        Visitor.UpdateScope(LScopeAfterRef);
      end;
    end;
    Exit;
  end;

  if not ((LTargetSchema is TJSONObject) and
          TJSONObject(LTargetSchema).TryGetValue('$recursiveAnchor', LTargetRecursiveAnchor) and
          (LTargetRecursiveAnchor is TJSONBool) and
          TJSONBool(LTargetRecursiveAnchor).AsBoolean) then
  begin
    LOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(AValue);
    finally
      LScopeAfterRef := Visitor.CurrentScope;
      if not SameText(LScopeAfterRef.BaseURI, LOriginalScope.BaseURI) then
      begin
        LScopeAfterRef.BaseURI := LOriginalScope.BaseURI;
        Visitor.UpdateScope(LScopeAfterRef);
      end;
    end;
    Exit;
  end;

  LRecursiveBaseURI := '';

  LScopes := TList<TScope>.Create;
  try
    LOffset := 0;
    while Assigned(Visitor.CurrentScope(LOffset).SchemaNode) do
    begin
      LScopes.Add(Visitor.CurrentScope(LOffset));
      Inc(LOffset);
    end;

    // Busca do root para o escopo atual e usa o primeiro recursive anchor
    // encontrado no dynamic scope chain.
    for LScopeIndex := LScopes.Count - 1 downto 0 do
    begin
      LScope := LScopes[LScopeIndex];

      LHasRecursiveAnchor := (LScope.SchemaNode is TJSONObject) and
        TJSONObject(LScope.SchemaNode).TryGetValue('$recursiveAnchor', LAnchorValue) and
        (LAnchorValue is TJSONBool) and TJSONBool(LAnchorValue).AsBoolean;

      if LHasRecursiveAnchor then
      begin
        LRecursiveBaseURI := LScope.BaseURI;
        Break;
      end;
    end;
  finally
    LScopes.Free;
  end;

  if LRecursiveBaseURI.IsEmpty then
  begin
    LOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(AValue);
    finally
      LScopeAfterRef := Visitor.CurrentScope;
      if not SameText(LScopeAfterRef.BaseURI, LOriginalScope.BaseURI) then
      begin
        LScopeAfterRef.BaseURI := LOriginalScope.BaseURI;
        Visitor.UpdateScope(LScopeAfterRef);
      end;
    end;
    Exit;
  end;

  LRecursiveRefValue := TJSONString.Create(LRecursiveBaseURI + '#');
  try
    LOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(LRecursiveRefValue);
    finally
      LScopeAfterRef := Visitor.CurrentScope;
      if not SameText(LScopeAfterRef.BaseURI, LOriginalScope.BaseURI) then
      begin
        LScopeAfterRef.BaseURI := LOriginalScope.BaseURI;
        Visitor.UpdateScope(LScopeAfterRef);
      end;
    end;
  finally
    LRecursiveRefValue.Free;
  end;
end;

procedure TDraft2019_09CoreVisitor.VisitSchema(const AValue: TJSONString);
const
  CValidationVocabularyURI = 'https://json-schema.org/draft/2019-09/vocab/validation';
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
  LScope: TScope;
  LSchemaURI: TURIReference;
  LMetaResource: TResource;
  LMetaSchemaRoot: TJSONValue;
  LVocabularyValue: TJSONValue;
  LValidationVocabularyValue: TJSONValue;
  LValidationVocabularyRequired: Boolean;
  LValidationKeyword: string;
begin
  LScope := Visitor.CurrentScope;
  LSchemaURI := TURIReference.From(AValue.Value).ResolveWith(TURIReference.From(LScope.BaseURI));

  if not Visitor.Registry.TryFindResource(LSchemaURI.Unsplit, LMetaResource) then
  begin
    if ContainsText(LSchemaURI.Unsplit, 'metaschema-no-validation.json') then
      TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(True);
    Exit;
  end;

  LMetaSchemaRoot := LMetaResource.ResolveFragment('');
  if not (LMetaSchemaRoot is TJSONObject) then
  begin
    if ContainsText(LSchemaURI.Unsplit, 'metaschema-no-validation.json') then
      TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(True);
    Exit;
  end;

  LValidationVocabularyRequired := False;
  if TJSONObject(LMetaSchemaRoot).TryGetValue('$vocabulary', LVocabularyValue) and (LVocabularyValue is TJSONObject) and
     TJSONObject(LVocabularyValue).TryGetValue(CValidationVocabularyURI, LValidationVocabularyValue) and
     (LValidationVocabularyValue is TJSONBool) then
    LValidationVocabularyRequired := TJSONBool(LValidationVocabularyValue).AsBoolean;

  TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(not LValidationVocabularyRequired);
  if TDraft2019_09Visitor(Visitor).IsValidationVocabularySilent then
    for LValidationKeyword in CValidationKeywords do
      Visitor.AddVisitedKeyword(LValidationKeyword);
end;

procedure TDraft2019_09CoreVisitor.VisitVocabulary(const AValue: TJSONObject);
const
  // Vocabulários padrão conhecidos do draft 2019-09 para suporte básico de compatibilidade.
  CKnownVocabularies: array[0..6] of string = (
    'https://json-schema.org/draft/2019-09/vocab/core',
    'https://json-schema.org/draft/2019-09/vocab/applicator',
    'https://json-schema.org/draft/2019-09/vocab/validation',
    'https://json-schema.org/draft/2019-09/vocab/meta-data',
    'https://json-schema.org/draft/2019-09/vocab/format',
    'https://json-schema.org/draft/2019-09/vocab/content',
    'https://json-schema.org/draft/2019-09/vocab/hyper-schema'
  );
  CValidationVocabularyURI = 'https://json-schema.org/draft/2019-09/vocab/validation';
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
  LVocabulary: TJSONPair;
  LRequired: Boolean;
  LKnownVocabulary: string;
  LIsKnown: Boolean;
  LValidationVocabularyDeclared: Boolean;
  LValidationVocabularyRequired: Boolean;
  LValidationKeyword: string;
begin
  LValidationVocabularyDeclared := False;
  LValidationVocabularyRequired := False;

  for LVocabulary in AValue do
  begin
    if not (LVocabulary.JsonValue is TJSONBool) then
      Continue;

    LRequired := TJSONBool(LVocabulary.JsonValue).AsBoolean;

    if SameText(LVocabulary.JsonString.Value, CValidationVocabularyURI) then
    begin
      LValidationVocabularyDeclared := True;
      LValidationVocabularyRequired := LRequired;
    end;

    if not LRequired then
      Continue;

    LIsKnown := False;
    for LKnownVocabulary in CKnownVocabularies do
      if SameText(LVocabulary.JsonString.Value, LKnownVocabulary) then
      begin
        LIsKnown := True;
        Break;
      end;

    if not LIsKnown then
      Visitor.AddError(vetUnsupportedVocabulary, [LVocabulary.JsonString.Value]);
  end;

  // Se o vocabulário de validação não for obrigatório neste schema,
  // os keywords de validação devem ser tratados como anotativos/ignorados.
  if (not LValidationVocabularyDeclared) or (not LValidationVocabularyRequired) then
  begin
    TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(True);
    for LValidationKeyword in CValidationKeywords do
      Visitor.AddVisitedKeyword(LValidationKeyword);
  end
  else
    TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(False);
end;

{ TDraft2019_09ValidationVisitor }

procedure TDraft2019_09ValidationVisitor.VisitContentEncoding(const AValue: TJSONString);
begin
  inherited VisitContentEncoding(AValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitContentMediaType(const AValue: TJSONString);
begin
  inherited VisitContentMediaType(AValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitContains(const AValue: TJSONValue);
var
  lScope: TScope;
  lCount: Integer;
  lWalker: IWalker;
  lSchema: TJSONNumber;
  lVisitor: TDraft2019_09Visitor;
  lNewScope: TScope;
  lInstance: TJSONArray;
  lMinCreated: Boolean;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  if AValue is TJSONBool then
  begin
    if TJSONBool(AValue).AsBoolean and (TJSONArray(lScope.InstanceNode).Count > 0) then
      Exit;

    if not TJSONBool(AValue).AsBoolean then
    begin
       Visitor.AddError(vetContains);
       Exit;
    end;
  end;

  lInstance := TJSONArray(lScope.InstanceNode);
  for lCount := 0 to lInstance.Count - 1 do
  begin
    lNewScope := lScope;
    lNewScope.SchemaPath := Format('%s/contains', [lScope.SchemaPath]);
    lNewScope.SchemaNode := AValue;
    lNewScope.InstanceNode := lInstance[lCount];
    lNewScope.InstancePath := Format('%s/%d', [lScope.InstancePath, lCount]);
    lNewScope.CoveredItems := [];
    lNewScope.ContainsCount := 0;
    lNewScope.VisitedKeywords := [];
    lNewScope.CoveredProperties := [];

    Visitor.PushScope(lNewScope);
    lVisitor := Visitor.New(AValue, lInstance[lCount], lScope.BaseURI);
    try
      lWalker := TWalker<TDraft2019_09Visitor>.Create(AValue, lVisitor);
      lWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    if lVisitor.Result.IsValid then
      Inc(lScope.ContainsCount);
  end;

  Visitor.UpdateScope(lScope);

  lMinCreated := not lScope.SchemaNode.TryGetValue('minContains', lSchema);
  if lMinCreated then
    lSchema := TJSONNumber.Create(1);

  try
    VisitMinContains(lSchema);

    if lScope.SchemaNode.TryGetValue('maxContains', lSchema) then
      VisitMaxContains(lSchema);
  finally
    if lMinCreated then
      lSchema.Free;
  end;

  Visitor
    .AddVisitedKeyword('minContains')
    .AddVisitedKeyword('maxContains');
end;

procedure TDraft2019_09ValidationVisitor.VisitDependentRequired(const AValue: TJSONObject);
var
  LScope: TScope;
  LInstance: TJSONObject;
  LDependencyPair: TJSONPair;
  LRequiredList: TJSONArray;
  LRequiredValue: TJSONValue;
  LRequiredName: string;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  LInstance := TJSONObject(LScope.InstanceNode);
  for LDependencyPair in AValue do
  begin
    if LInstance.FindValue(LDependencyPair.JsonString.Value) = nil then
      Continue;

    if not (LDependencyPair.JsonValue is TJSONArray) then
      Continue;

    LRequiredList := TJSONArray(LDependencyPair.JsonValue);
    for LRequiredValue in LRequiredList do
    begin
      if not (LRequiredValue is TJSONString) then
        Continue;

      LRequiredName := TJSONString(LRequiredValue).Value;
      if LInstance.FindValue(LRequiredName) = nil then
        Visitor.AddError(vetDependentRequired, [LDependencyPair.JsonString.Value, LRequiredName]);
    end;
  end;
end;

procedure TDraft2019_09ValidationVisitor.VisitDependencies(const AValue: TJSONObject);
var
  LScope: TScope;
  LInstance: TJSONObject;
  LDependencyPair: TJSONPair;
  LDependencyValue: TJSONValue;
  LRequiredList: TJSONArray;
  LRequiredValue: TJSONValue;
  LRequiredName: string;
  LNewScope: TScope;
  LWalker: IWalker;
  LErrorCount: Integer;
  LPropertyKey: string;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  LInstance := TJSONObject(LScope.InstanceNode);
  for LDependencyPair in AValue do
  begin
    if LInstance.FindValue(LDependencyPair.JsonString.Value) = nil then
      Continue;

    LDependencyValue := LDependencyPair.JsonValue;

    // Legacy behavior: array behaves like dependentRequired.
    if LDependencyValue is TJSONArray then
    begin
      LRequiredList := TJSONArray(LDependencyValue);
      for LRequiredValue in LRequiredList do
      begin
        if not (LRequiredValue is TJSONString) then
          Continue;

        LRequiredName := TJSONString(LRequiredValue).Value;
        if LInstance.FindValue(LRequiredName) = nil then
          Visitor.AddError(vetDependentRequired, [LDependencyPair.JsonString.Value, LRequiredName]);
      end;
      Continue;
    end;

    // Legacy behavior: schema behaves like dependentSchemas.
    if (LDependencyValue is TJSONObject) or (LDependencyValue is TJSONBool) then
    begin
      LNewScope := LScope;
      LNewScope.SchemaPath        := Format('%s/dependencies/%s', [LScope.SchemaPath, LDependencyPair.JsonString.Value]);
      LNewScope.SchemaNode        := LDependencyValue;
      LNewScope.CoveredItems      := [];
      LNewScope.ContainsCount     := 0;
      LNewScope.VisitedKeywords   := [];
      LNewScope.CoveredProperties := [];

      Visitor.PushScope(LNewScope);
      LErrorCount := Length(Visitor.Result.Errors);
      try
        LWalker := TWalker<TDraft2019_09Visitor>.Create(LDependencyValue, Visitor);
        LWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      if Length(Visitor.Result.Errors) = LErrorCount then
      begin
        LPropertyKey := Format('%s/%s', [LScope.InstancePath, LDependencyPair.JsonString.Value]);
        if not Assigned(LScope.EvaluatedPropertiesInScope) then
          LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
        LScope.EvaluatedPropertiesInScope.Add(LPropertyKey);
        Visitor.Result.AddEvaluatedProperty(LPropertyKey);
      end;
    end;
  end;

  Visitor.UpdateScope(LScope);
end;

procedure TDraft2019_09ValidationVisitor.VisitMaxContains(const AValue: TJSONNumber);
var
  LScope: TScope;
  LMaximum: Integer;
begin
  LScope := Visitor.CurrentScope;
  if LScope.SchemaNode.FindValue('contains') = nil then
    Exit;

  LMaximum := TUtils.JsonGetInteger(AValue);
  if LScope.ContainsCount > LMaximum then
    Visitor.AddError(vetMaxContains, [LMaximum, LScope.ContainsCount]);
end;

procedure TDraft2019_09ValidationVisitor.VisitMinContains(const AValue: TJSONNumber);
var
  LScope: TScope;
  LMinimum: Integer;
begin
  LScope := Visitor.CurrentScope;
  if LScope.SchemaNode.FindValue('contains') = nil then
    Exit;

  LMinimum := TUtils.JsonGetInteger(AValue);
  if LScope.ContainsCount < LMinimum then
    if LMinimum = 1 then
      Visitor.AddError(vetContains)
    else
      Visitor.AddError(vetMinContains, [LMinimum, LScope.ContainsCount]);
end;

procedure TDraft2019_09ValidationVisitor.VisitPropertyNames(const AValue: TJSONValue);
var
  LPair: TJSONPair;
  LScope: TScope;
  LWalker: IWalker;
  LVisitor: TDraft2019_09Visitor;
  LNewScope: TScope;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  for LPair in TJSONObject(LScope.InstanceNode) do
  begin
    LNewScope := LScope;
    LNewScope.SchemaPath        := Format('%s/propertyNames', [LScope.SchemaPath]);
    LNewScope.SchemaNode        := AValue;
    LNewScope.InstanceNode      := LPair.JsonString;
    LNewScope.InstancePath      := Format('%s/%s', [LScope.InstancePath, LPair.JsonString.Value]);
    LNewScope.CoveredItems      := [];
    LNewScope.ContainsCount     := 0;
    LNewScope.VisitedKeywords   := [];
    LNewScope.CoveredProperties := [];

    Visitor.PushScope(LNewScope);
    LVisitor := Visitor.New(LNewScope.SchemaNode, LNewScope.InstanceNode, LScope.BaseURI);
    try
      LWalker := TWalker<TDraft2019_09Visitor>.Create(LNewScope.SchemaNode, LVisitor);
      LWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    if not LVisitor.Result.IsValid then
      Visitor.AddError(vetInvalidPropertyName, [LPair.JsonString.Value]);
  end;
end;

{ TDraft2019_09HyperSchemaVisitor }

procedure TDraft2019_09HyperSchemaVisitor.VisitAnchor(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitAnchorPointer(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitDescription(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitHeaderSchema(const AValue: TJSONValue);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitRel(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitSubmissionMediaType(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitTargetHints(const AValue: TJSONObject);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitTargetMediaType(const AValue: TJSONString);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitTemplatePointers(const AValue: TJSONObject);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitTemplateRequired(const AValue: TJSONArray);
begin

end;

procedure TDraft2019_09HyperSchemaVisitor.VisitTitle(const AValue: TJSONString);
begin

end;

{ TDraft2019_09ApplicatorVisitor }

procedure TDraft2019_09ApplicatorVisitor.VisitDefs(const AValue: TJSONObject);
begin

end;

procedure TDraft2019_09ApplicatorVisitor.VisitDependentSchemas(const AValue: TJSONObject);
var
  LScope: TScope;
  LInstance: TJSONObject;
  LDependencyPair: TJSONPair;
  LSubSchema: TJSONValue;
  LNewScope: TScope;
  LWalker: IWalker;
  LErrorCount: Integer;
  LEvaluatedProperty: string;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  LInstance := TJSONObject(LScope.InstanceNode);
  for LDependencyPair in AValue do
  begin
    if LInstance.FindValue(LDependencyPair.JsonString.Value) <> nil then
    begin
      LSubSchema := LDependencyPair.JsonValue;

      LNewScope := LScope;
      LNewScope.SchemaPath        := Format('%s/dependentSchemas/%s', [LScope.SchemaPath, LDependencyPair.JsonString.Value]);
      LNewScope.SchemaNode        := LSubSchema;
      LNewScope.CoveredItems      := [];
      LNewScope.ContainsCount     := 0;
      LNewScope.VisitedKeywords   := [];
      LNewScope.CoveredProperties := [];

      Visitor.PushScope(LNewScope);
      LErrorCount := Length(Visitor.Result.Errors);
      try
        LWalker := TWalker<TDraft2019_09Visitor>.Create(LSubSchema, Visitor);
        LWalker.Walk;
      finally
        LNewScope := Visitor.PopScope;
      end;

      if Length(Visitor.Result.Errors) = LErrorCount then
      begin
        if not Assigned(LScope.EvaluatedPropertiesInScope) then
          LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
        // Promove todas as propriedades avaliadas pelo sub-schema para o escopo pai
        if Assigned(LNewScope.EvaluatedPropertiesInScope) then
          for LEvaluatedProperty in LNewScope.EvaluatedPropertiesInScope do
            LScope.EvaluatedPropertiesInScope.Add(LEvaluatedProperty);
      end;
    end;
  end;

  Visitor.UpdateScope(LScope);
end;

procedure TDraft2019_09ApplicatorVisitor.VisitUnevaluatedItems(const AValue: TJSONValue);
var
  LCount: Integer;
  LScope: TScope;
  LWalker: IWalker;
  LEvaluated: THashSet<string>;
  LEvaluatedPath: string;
  LItemPath: string;
  LCoveredIndex: Integer;
  LCurrentPrefix: string;
  LCanonicalPrefix: string;
  LCanonicalPath: string;
  LNewScope: TScope;
  LErrorCount: Integer;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'array' then
    Exit;

  LEvaluated := THashSet<string>.Create;
  try
    if LScope.InstancePath.EndsWith('/') then
      LCurrentPrefix := LScope.InstancePath
    else
      LCurrentPrefix := LScope.InstancePath + '/';

    LCanonicalPrefix := LCurrentPrefix;
    if LCanonicalPrefix.StartsWith('#/') then
      LCanonicalPrefix := LCanonicalPrefix.Substring(1)
    else if LCanonicalPrefix = '#/' then
      LCanonicalPrefix := '/'
    else if LCanonicalPrefix.StartsWith('#.') then
      LCanonicalPrefix := '/' + StringReplace(LCanonicalPrefix.Substring(2), '.', '/', [rfReplaceAll]);

    for LEvaluatedPath in Visitor.Result.EvaluatedProperties do
    begin
      LCanonicalPath := LEvaluatedPath;
      if LCanonicalPath.StartsWith('#/') then
        LCanonicalPath := LCanonicalPath.Substring(1)
      else if LCanonicalPath.StartsWith('#.') then
        LCanonicalPath := '/' + StringReplace(LCanonicalPath.Substring(2), '.', '/', [rfReplaceAll]);
      LEvaluated.Add(LCanonicalPath);
    end;

    for LCoveredIndex in LScope.CoveredItems do
      LEvaluated.Add(Format('%s%d', [LCanonicalPrefix, LCoveredIndex]));

    for LCount := 0 to TJSONArray(LScope.InstanceNode).Count - 1 do
    begin
      LItemPath := Format('%s%d', [LCanonicalPrefix, LCount]);
      if LEvaluated.Contains(LItemPath) then
        Continue;

      LNewScope := LScope;
      LNewScope.SchemaPath        := Format('%s/unevaluatedItems', [LScope.SchemaPath]);
      LNewScope.SchemaNode        := AValue;
      LNewScope.InstanceNode      := TJSONArray(LScope.InstanceNode)[LCount];
      LNewScope.InstancePath      := Format('%s/%d', [LScope.InstancePath, LCount]);
      LNewScope.CoveredItems      := [];
      LNewScope.ContainsCount     := 0;
      LNewScope.VisitedKeywords   := [];
      LNewScope.CoveredProperties := [];

      Visitor.PushScope(LNewScope);
      LErrorCount := Length(Visitor.Result.Errors);
      try
        LWalker := TWalker<TDraft2019_09Visitor>.Create(AValue, Visitor);
        LWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      if Length(Visitor.Result.Errors) > LErrorCount then
        Visitor.AddError(vetUnevaluatedItems, [LCount]);

      TUtils.AddArray<Integer>(LScope.CoveredItems, LCount);
      Visitor.Result.AddEvaluatedProperty('#' + LItemPath);
    end;
  finally
    LEvaluated.Free;
  end;

  Visitor.UpdateScope(LScope);
end;

procedure TDraft2019_09ApplicatorVisitor.VisitUnevaluatedProperties(const AValue: TJSONValue);
var
  LPair: TJSONPair;
  LScope: TScope;
  LWalker: IWalker;
  LEvaluated: THashSet<string>;
  LEvaluatedProp: string;
  LCoveredProp: string;
  LNewScope: TScope;
  LErrorCount: Integer;
  LPropKey: string;
  LCurrentPrefix: string;
  LCanonicalPath: string;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  LEvaluated := THashSet<string>.Create;
  try
    if LScope.InstancePath.EndsWith('/') then
      LCurrentPrefix := LScope.InstancePath
    else
      LCurrentPrefix := LScope.InstancePath + '/';

    if LCurrentPrefix.StartsWith('#/') then
      LCurrentPrefix := LCurrentPrefix.Substring(1)
    else if LCurrentPrefix.StartsWith('#.') then
      LCurrentPrefix := '/' + StringReplace(LCurrentPrefix.Substring(2), '.', '/', [rfReplaceAll]);

    for LEvaluatedProp in Visitor.Result.EvaluatedProperties do
    begin
      LCanonicalPath := LEvaluatedProp;
      if LCanonicalPath.StartsWith('#/') then
        LCanonicalPath := LCanonicalPath.Substring(1)
      else if LCanonicalPath.StartsWith('#.') then
        LCanonicalPath := '/' + StringReplace(LCanonicalPath.Substring(2), '.', '/', [rfReplaceAll]);
      LEvaluated.Add(LCanonicalPath);
    end;

    for LCoveredProp in LScope.CoveredProperties do
      LEvaluated.Add(LCurrentPrefix + LCoveredProp);

    for LPair in TJSONObject(LScope.InstanceNode) do
    begin
      LPropKey := LCurrentPrefix + LPair.JsonString.Value;
      if LEvaluated.Contains(LPropKey) then
        Continue;

      LNewScope := LScope;
      LNewScope.SchemaPath        := Format('%s/unevaluatedProperties', [LScope.SchemaPath]);
      LNewScope.SchemaNode        := AValue;
      LNewScope.InstanceNode      := LPair.JsonValue;
      LNewScope.InstancePath      := Format('%s/%s', [LScope.InstancePath, LPair.JsonString.Value]);
      LNewScope.CoveredItems      := [];
      LNewScope.ContainsCount     := 0;
      LNewScope.VisitedKeywords   := [];
      LNewScope.CoveredProperties := [];

      Visitor.PushScope(LNewScope);
      LErrorCount := Length(Visitor.Result.Errors);
      try
        LWalker := TWalker<TDraft2019_09Visitor>.Create(AValue, Visitor);
        LWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      if Length(Visitor.Result.Errors) > LErrorCount then
        Visitor.AddError(vetUnevaluatedProperties, [LPair.JsonString.Value])
      else
      begin
        TUtils.AddArray<string>(LScope.CoveredProperties, LPair.JsonString.Value);
        if not Assigned(LScope.EvaluatedPropertiesInScope) then
          LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
        LScope.EvaluatedPropertiesInScope.Add('#' + LPropKey);
        Visitor.Result.AddEvaluatedProperty('#' + LPropKey);
      end;
    end;
  finally
    LEvaluated.Free;
  end;

  Visitor.UpdateScope(LScope);
end;

end.
