unit JsonSchema.Validation.Draft2019_09;

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
  /// <summary>Main validation visitor for JSON Schema Draft 2019-09, coordinating core, applicator, and validation vocabularies.</summary>
  TDraft2019_09Visitor = class(TValidationVisitor<TDraft2019_09Visitor>, IDraft2019_09ValidationVocabularyMode)
  private
    FValidationVocabularySilent: Boolean;
  public
    /// <summary>Creates a new Draft 2019-09 visitor, initializing sub-visitors and detecting metaschema-no-validation mode.</summary>
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string; const pCustomHint: TJSONValue = nil);
    /// <summary>Creates a child visitor sharing the same registry and vocabulary-silent state as the current instance.</summary>
    function New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft2019_09Visitor; override;
    /// <summary>Returns the ordered list of keywords that must be visited before others in Draft 2019-09.</summary>
    function KeywordPrecedence: TArray<string>; override;
    function IsValidationVocabularySilent: Boolean;
    procedure SetValidationVocabularySilent(const pValue: Boolean);
  end;

  /// <summary>Interface for the Draft 2019-09 Core vocabulary visitor, handling $schema, $comment, $anchor, $recursiveRef, $recursiveAnchor, and $vocabulary keywords.</summary>
  IDraft2019_09CoreVisitor = interface(IBaseCoreVisitor<TDraft2019_09Visitor>)
    ['{4B72E0CE-AFBF-4C25-92CC-EA0509595809}']
    procedure VisitSchema(const pValue: TJSONString);
    procedure VisitComment(const pValue: TJSONString);
    procedure VisitAnchor(const pValue: TJSONString);
    procedure VisitRecursiveRef(const pValue: TJSONString);
    procedure VisitRecursiveAnchor(const pValue: TJSONBool);
    procedure VisitVocabulary(const pValue: TJSONObject);
  end;

  /// <summary>Interface for the Draft 2019-09 Applicator vocabulary visitor, handling prefixItems, dependentSchemas, unevaluatedItems, and unevaluatedProperties keywords.</summary>
  IDraft2019_09ApplicatorVisitor = interface(IBaseApplicatorVisitor<TDraft2019_09Visitor>)
    ['{44142A26-AC72-414C-BB83-75DA511A0A36}']
    procedure VisitPrefixItems(const pValue: TJSONArray);
    procedure VisitDependentSchemas(const pValue: TJSONObject);
    procedure VisitUnevaluatedItems(const pValue: TJSONValue);
    procedure VisitUnevaluatedProperties(const pValue: TJSONValue);
  end;

  /// <summary>Interface for the Draft 2019-09 Validation vocabulary visitor, extending base validation with minimum, contains, propertyNames, dependencies, dependentRequired, maxContains, and minContains keywords.</summary>
  IDraft2019_09ValidationVisitor = interface(IBaseValidationVisitor<TDraft2019_09Visitor>)
    ['{E995D611-5477-4970-B791-81A4555AF554}']
    procedure VisitMinimum(const pValue: TJSONNumber);
    procedure VisitContains(const pValue: TJSONValue);
    procedure VisitPropertyNames(const pValue: TJSONValue);
    procedure VisitDependencies(const pValue: TJSONObject);
    procedure VisitDependentRequired(const pValue: TJSONObject);
    procedure VisitMaxContains(const pValue: TJSONNumber);
    procedure VisitMinContains(const pValue: TJSONNumber);
  end;

  /// <summary>Interface for the Draft 2019-09 Relative JSON Pointer vocabulary visitor.</summary>
  IDraft2019_09RelativeJsonPointer = interface(IBaseRelativeJsonPointer<TDraft2019_09Visitor>)
    ['{E40B5CE3-7207-430E-81BA-07A8E798EC60}']
  end;

  /// <summary>Implements the Draft 2019-09 Core vocabulary visitor, processing $schema, $comment, $anchor, $recursiveRef, $recursiveAnchor, and $vocabulary keywords.</summary>
  TDraft2019_09CoreVisitor = class(TBaseCoreVisitor<TDraft2019_09Visitor>, IDraft2019_09CoreVisitor)
    [VisitorKeyword('$schema')]
    /// <summary>Reads the metaschema URI and activates validation-vocabulary-silent mode when the metaschema excludes the validation vocabulary.</summary>
    procedure VisitSchema(const pValue: TJSONString);
    [VisitorKeyword('$comment')]
    procedure VisitComment(const pValue: TJSONString);
    [VisitorKeyword('$anchor')]
    procedure VisitAnchor(const pValue: TJSONString);
    [VisitorKeyword('$recursiveRef')]
    /// <summary>Validates the "$recursiveRef" keyword by walking the dynamic scope chain to find the outermost schema that declares $recursiveAnchor: true and redirecting resolution to it.</summary>
    procedure VisitRecursiveRef(const pValue: TJSONString);
    [VisitorKeyword('$recursiveAnchor')]
    procedure VisitRecursiveAnchor(const pValue: TJSONBool);
    [VisitorKeyword('$vocabulary')]
    /// <summary>Processes the "$vocabulary" map, raising an error for unknown required vocabularies and suppressing validation keywords when the validation vocabulary is absent or optional.</summary>
    procedure VisitVocabulary(const pValue: TJSONObject);
  end;

  /// <summary>Implements the Draft 2019-09 Applicator vocabulary visitor, handling prefixItems, dependentSchemas, unevaluatedItems, and unevaluatedProperties.</summary>
  TDraft2019_09ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft2019_09Visitor>, IDraft2019_09ApplicatorVisitor)
    [VisitorKeyword('$defs')]
    procedure VisitDefs(const pValue: TJSONObject);
    [VisitorKeyword('prefixItems')]
    procedure VisitPrefixItems(const pValue: TJSONArray);
    [VisitorKeyword('dependentSchemas')]
    /// <summary>Evaluates each dependent sub-schema against the instance when the triggering property is present, and promotes evaluated properties to the parent scope on success.</summary>
    procedure VisitDependentSchemas(const pValue: TJSONObject);
    [VisitorKeyword('unevaluatedItems')]
    /// <summary>Applies the unevaluatedItems sub-schema to every array item that was not covered by any prior keyword in the current validation scope.</summary>
    procedure VisitUnevaluatedItems(const pValue: TJSONValue);
    [VisitorKeyword('unevaluatedProperties')]
    /// <summary>Applies the unevaluatedProperties sub-schema to every object property that was not covered by any prior keyword in the current validation scope.</summary>
    procedure VisitUnevaluatedProperties(const pValue: TJSONValue);
  end;

  /// <summary>Implements the Draft 2019-09 Validation vocabulary visitor, extending base validation with support for validation-vocabulary-silent mode.</summary>
  TDraft2019_09ValidationVisitor = class(TBaseValidationVisitor<TDraft2019_09Visitor>, IDraft2019_09ValidationVisitor)
  private
    function ValidationVocabularySilent: Boolean;
  public
    [VisitorKeyword('type')]
    procedure VisitType(const pValue: TJSONValue);
    [VisitorKeyword('multipleOf')]
    procedure VisitMultipleOf(const pValue: TJSONNumber);
    [VisitorKeyword('maximum')]
    procedure VisitMaximum(const pValue: TJSONNumber);
    [VisitorKeyword('exclusiveMaximum')]
    procedure VisitExclusiveMaximum(const pValue: TJSONValue);
    [VisitorKeyword('minimum')]
    procedure VisitMinimum(const pValue: TJSONNumber);
    [VisitorKeyword('exclusiveMinimum')]
    procedure VisitExclusiveMinimum(const pValue: TJSONValue);
    [VisitorKeyword('maxLength')]
    procedure VisitMaxLength(const pValue: TJSONNumber);
    [VisitorKeyword('minLength')]
    procedure VisitMinLength(const pValue: TJSONNumber);
    [VisitorKeyword('pattern')]
    procedure VisitPattern(const pValue: TJSONString);
    [VisitorKeyword('format')]
    procedure VisitFormat(const pValue: TJSONString);
    [VisitorKeyword('maxItems')]
    procedure VisitMaxItems(const pValue: TJSONNumber);
    [VisitorKeyword('minItems')]
    procedure VisitMinItems(const pValue: TJSONNumber);
    [VisitorKeyword('uniqueItems')]
    procedure VisitUniqueItems(const pValue: TJSONBool);
    [VisitorKeyword('maxProperties')]
    procedure VisitMaxProperties(const pValue: TJSONNumber);
    [VisitorKeyword('minProperties')]
    procedure VisitMinProperties(const pValue: TJSONNumber);
    [VisitorKeyword('required')]
    procedure VisitRequired(const pValue: TJSONArray);
    [VisitorKeyword('enum')]
    procedure VisitEnum(const pValue: TJSONArray);
    [VisitorKeyword('const')]
    procedure VisitConst(const pValue: TJSONValue);
    [VisitorKeyword('contentEncoding')]
    procedure VisitContentEncoding(const pValue: TJSONString);
    [VisitorKeyword('contentMediaType')]
    procedure VisitContentMediaType(const pValue: TJSONString);
    [VisitorKeyword('contains')]
    /// <summary>Counts matching items against the contains sub-schema and delegates min/maxContains enforcement, creating a synthetic minContains of 1 when not declared.</summary>
    procedure VisitContains(const pValue: TJSONValue);
    [VisitorKeyword('propertyNames')]
    procedure VisitPropertyNames(const pValue: TJSONValue);
    [VisitorKeyword('dependencies')]
    /// <summary>Implements the legacy "dependencies" keyword, routing array values through dependentRequired semantics and object values through dependentSchemas semantics.</summary>
    procedure VisitDependencies(const pValue: TJSONObject);
    [VisitorKeyword('dependentRequired')]
    /// <summary>Validates that all properties listed as dependents of a present property also exist on the instance.</summary>
    procedure VisitDependentRequired(const pValue: TJSONObject);
    [VisitorKeyword('maxContains')]
    /// <summary>Validates that the number of items matching the contains sub-schema does not exceed the declared maximum.</summary>
    procedure VisitMaxContains(const pValue: TJSONNumber);
    [VisitorKeyword('minContains')]
    /// <summary>Validates that the number of items matching the contains sub-schema meets the declared minimum, reusing the vetContains error when the minimum is 1.</summary>
    procedure VisitMinContains(const pValue: TJSONNumber);
  end;

  /// <summary>Implements the Draft 2019-09 Relative JSON Pointer vocabulary visitor.</summary>
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

constructor TDraft2019_09Visitor.Create(const pSchema, pData: TJSONValue; const pBaseURI: string; const pCustomHint: TJSONValue);
var
  lSchemaURI: string;
begin
  inherited Create(pSchema, pData, pBaseURI, pCustomHint);

  FValidationVocabularySilent := False;
  if (pSchema is TJSONObject) and
     TJSONObject(pSchema).TryGetValue<string>('$schema', lSchemaURI) and
     ContainsText(lSchemaURI, 'metaschema-no-validation.json') then
    FValidationVocabularySilent := True;

  FCore                := TDraft2019_09CoreVisitor.Create(Self);
  FApplicator          := TDraft2019_09ApplicatorVisitor.Create(Self);
  FValidation          := TDraft2019_09ValidationVisitor.Create(Self);
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

function TDraft2019_09Visitor.New(const pSchema, pData: TJSONValue; const pBaseURI: string): TDraft2019_09Visitor;
begin
  Result := TDraft2019_09Visitor.Create(pSchema, pData, pBaseURI, FCustomHint);
  Result.FRegistry.Free;
  Result.FRegistry := FRegistry;
  Result.FOwnsRegistry := False;
  Result.FValidationVocabularySilent := FValidationVocabularySilent;
end;

procedure TDraft2019_09Visitor.SetValidationVocabularySilent(const pValue: Boolean);
begin
  FValidationVocabularySilent := pValue;
end;

{ TDraft2019_09CoreVisitor }

procedure TDraft2019_09CoreVisitor.VisitAnchor(const pValue: TJSONString);
begin

end;

procedure TDraft2019_09CoreVisitor.VisitComment(const pValue: TJSONString);
begin

end;

procedure TDraft2019_09CoreVisitor.VisitRecursiveAnchor(const pValue: TJSONBool);
begin

end;

procedure TDraft2019_09CoreVisitor.VisitRecursiveRef(const pValue: TJSONString);
var
  lScope: TScope;
  lFinalURI: TURIReference;
  lTargetResource: TResource;
  lTargetSchema: TJSONValue;
  lResolvedBaseURI: string;
  lTargetRecursiveAnchor: TJSONValue;
  lScopes: TList<TScope>;
  lScopeIndex: Integer;
  lOffset: Integer;
  lRecursiveBaseURI: string;
  lAnchorValue: TJSONValue;
  lRecursiveRefValue: TJSONString;
  lHasRecursiveAnchor: Boolean;
  lOriginalScope: TScope;
  lScopeAfterRef: TScope;
begin
  lScope := Visitor.CurrentScope;
  lFinalURI := TURIReference.From(pValue.Value).ResolveWith(TURIReference.From(lScope.BaseURI));

  if not Visitor.Registry.TryFindResource(lFinalURI.Unsplit, lTargetResource) then
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
    Exit;
  end;

  lTargetSchema := lTargetResource.ResolveFragment(lFinalURI.Fragment, lResolvedBaseURI);
  if not Assigned(lTargetSchema) then
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
    Exit;
  end;

  if not ((lTargetSchema is TJSONObject) and
          TJSONObject(lTargetSchema).TryGetValue('$recursiveAnchor', lTargetRecursiveAnchor) and
          (lTargetRecursiveAnchor is TJSONBool) and
          TJSONBool(lTargetRecursiveAnchor).AsBoolean) then
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
    Exit;
  end;

  lRecursiveBaseURI := '';

  lScopes := TList<TScope>.Create;
  try
    lOffset := 0;
    while Assigned(Visitor.CurrentScope(lOffset).SchemaNode) do
    begin
      lScopes.Add(Visitor.CurrentScope(lOffset));
      Inc(lOffset);
    end;

    // Busca do root para o escopo atual e usa o primeiro recursive anchor
    // encontrado no dynamic scope chain.
    for lScopeIndex := lScopes.Count - 1 downto 0 do
    begin
      lScope := lScopes[lScopeIndex];

      lHasRecursiveAnchor := (lScope.SchemaNode is TJSONObject) and
        TJSONObject(lScope.SchemaNode).TryGetValue('$recursiveAnchor', lAnchorValue) and
        (lAnchorValue is TJSONBool) and TJSONBool(lAnchorValue).AsBoolean;

      if lHasRecursiveAnchor then
      begin
        lRecursiveBaseURI := lScope.BaseURI;
        Break;
      end;
    end;
  finally
    lScopes.Free;
  end;

  if lRecursiveBaseURI.IsEmpty then
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
    Exit;
  end;

  lRecursiveRefValue := TJSONString.Create(lRecursiveBaseURI + '#');
  try
    lOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(lRecursiveRefValue);
    finally
      lScopeAfterRef := Visitor.CurrentScope;
      if not SameText(lScopeAfterRef.BaseURI, lOriginalScope.BaseURI) then
      begin
        lScopeAfterRef.BaseURI := lOriginalScope.BaseURI;
        Visitor.UpdateScope(lScopeAfterRef);
      end;
    end;
  finally
    lRecursiveRefValue.Free;
  end;
end;

procedure TDraft2019_09CoreVisitor.VisitSchema(const pValue: TJSONString);
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
    if ContainsText(lSchemaURI.Unsplit, 'metaschema-no-validation.json') then
      TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(True);
    Exit;
  end;

  lMetaSchemaRoot := lMetaResource.ResolveFragment('');
  if not (lMetaSchemaRoot is TJSONObject) then
  begin
    if ContainsText(lSchemaURI.Unsplit, 'metaschema-no-validation.json') then
      TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(True);
    Exit;
  end;

  lValidationVocabularyRequired := False;
  if TJSONObject(lMetaSchemaRoot).TryGetValue('$vocabulary', lVocabularyValue) and (lVocabularyValue is TJSONObject) and
     TJSONObject(lVocabularyValue).TryGetValue(CValidationVocabularyURI, lValidationVocabularyValue) and
     (lValidationVocabularyValue is TJSONBool) then
    lValidationVocabularyRequired := TJSONBool(lValidationVocabularyValue).AsBoolean;

  TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(not lValidationVocabularyRequired);
  if TDraft2019_09Visitor(Visitor).IsValidationVocabularySilent then
    for lValidationKeyword in CValidationKeywords do
      Visitor.AddVisitedKeyword(lValidationKeyword);
end;

procedure TDraft2019_09CoreVisitor.VisitVocabulary(const pValue: TJSONObject);
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
  lVocabulary: TJSONPair;
  lRequired: Boolean;
  lKnownVocabulary: string;
  lIsKnown: Boolean;
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

    if SameText(lVocabulary.JsonString.Value, CValidationVocabularyURI) then
    begin
      lValidationVocabularyDeclared := True;
      lValidationVocabularyRequired := lRequired;
    end;

    if not lRequired then
      Continue;

    lIsKnown := False;
    for lKnownVocabulary in CKnownVocabularies do
      if SameText(lVocabulary.JsonString.Value, lKnownVocabulary) then
      begin
        lIsKnown := True;
        Break;
      end;

    if not lIsKnown then
      Visitor.AddError(vetUnsupportedVocabulary, [lVocabulary.JsonString.Value]);
  end;

  // Se o vocabulário de validação não for obrigatório neste schema,
  // os keywords de validação devem ser tratados como anotativos/ignorados.
  if (not lValidationVocabularyDeclared) or (not lValidationVocabularyRequired) then
  begin
    TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(True);
    for lValidationKeyword in CValidationKeywords do
      Visitor.AddVisitedKeyword(lValidationKeyword);
  end
  else
    TDraft2019_09Visitor(Visitor).SetValidationVocabularySilent(False);
end;

{ TDraft2019_09ValidationVisitor }

function TDraft2019_09ValidationVisitor.ValidationVocabularySilent: Boolean;
begin
  Result := TDraft2019_09Visitor(Visitor).IsValidationVocabularySilent;
end;

procedure TDraft2019_09ValidationVisitor.VisitConst(const pValue: TJSONValue);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitConst(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitEnum(const pValue: TJSONArray);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitEnum(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitExclusiveMaximum(const pValue: TJSONValue);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitExclusiveMaximum(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitExclusiveMinimum(const pValue: TJSONValue);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitExclusiveMinimum(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitFormat(const pValue: TJSONString);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitFormat(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitMaxItems(const pValue: TJSONNumber);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitMaxItems(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitMaxLength(const pValue: TJSONNumber);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitMaxLength(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitMaximum(const pValue: TJSONNumber);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitMaximum(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitMaxProperties(const pValue: TJSONNumber);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitMaxProperties(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitMinItems(const pValue: TJSONNumber);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitMinItems(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitMinLength(const pValue: TJSONNumber);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitMinLength(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitContentEncoding(const pValue: TJSONString);
begin
  inherited VisitContentEncoding(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitContentMediaType(const pValue: TJSONString);
begin
  inherited VisitContentMediaType(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitMinimum(const pValue: TJSONNumber);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitMinimum(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitMinProperties(const pValue: TJSONNumber);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitMinProperties(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitMultipleOf(const pValue: TJSONNumber);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitMultipleOf(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitPattern(const pValue: TJSONString);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitPattern(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitRequired(const pValue: TJSONArray);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitRequired(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitType(const pValue: TJSONValue);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitType(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitUniqueItems(const pValue: TJSONBool);
begin
  if ValidationVocabularySilent then
    Exit;

  inherited VisitUniqueItems(pValue);
end;

procedure TDraft2019_09ValidationVisitor.VisitContains(const pValue: TJSONValue);
var
  lScope: TScope;
  lCount: Integer;
  lWalker: IWalker;
  lSchema: TJSONNumber;
  lMaxSchema: TJSONNumber;
  lVisitor: TDraft2019_09Visitor;
  lNewScope: TScope;
  lInstance: TJSONArray;
  lMinCreated: Boolean;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  if pValue is TJSONBool then
  begin
    if TJSONBool(pValue).AsBoolean and (TJSONArray(lScope.InstanceNode).Count > 0) then
      Exit;

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
    lNewScope.SchemaPath := Format('%s/contains', [lScope.SchemaPath]);
    lNewScope.SchemaNode := pValue;
    lNewScope.InstanceNode := lInstance[lCount];
    lNewScope.InstancePath := Format('%s/%d', [lScope.InstancePath, lCount]);
    lNewScope.CoveredItems := [];
    lNewScope.ContainsCount := 0;
    lNewScope.VisitedKeywords := [];
    lNewScope.CoveredProperties := [];

    Visitor.PushScope(lNewScope);
    lVisitor := Visitor.New(pValue, lInstance[lCount], lScope.BaseURI);
    try
      lWalker := TWalker<TDraft2019_09Visitor>.Create(pValue, lVisitor);
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

    if lScope.SchemaNode.TryGetValue('maxContains', lMaxSchema) then
      VisitMaxContains(lMaxSchema);
  finally
    if lMinCreated then
      lSchema.Free;
  end;

  Visitor
    .AddVisitedKeyword('minContains')
    .AddVisitedKeyword('maxContains');
end;

procedure TDraft2019_09ValidationVisitor.VisitDependentRequired(const pValue: TJSONObject);
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

procedure TDraft2019_09ValidationVisitor.VisitDependencies(const pValue: TJSONObject);
var
  lScope: TScope;
  lInstance: TJSONObject;
  lDependencyPair: TJSONPair;
  lDependencyValue: TJSONValue;
  lRequiredList: TJSONArray;
  lRequiredValue: TJSONValue;
  lRequiredName: string;
  lNewScope: TScope;
  lWalker: IWalker;
  lErrorCount: Integer;
  lPropertyKey: string;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

  lInstance := TJSONObject(lScope.InstanceNode);
  for lDependencyPair in pValue do
  begin
    if lInstance.FindValue(lDependencyPair.JsonString.Value) = nil then
      Continue;

    lDependencyValue := lDependencyPair.JsonValue;

    // Legacy behavior: array behaves like dependentRequired.
    if lDependencyValue is TJSONArray then
    begin
      lRequiredList := TJSONArray(lDependencyValue);
      for lRequiredValue in lRequiredList do
      begin
        if not (lRequiredValue is TJSONString) then
          Continue;

        lRequiredName := TJSONString(lRequiredValue).Value;
        if lInstance.FindValue(lRequiredName) = nil then
          Visitor.AddError(vetDependentRequired, [lDependencyPair.JsonString.Value, lRequiredName]);
      end;
      Continue;
    end;

    // Legacy behavior: schema behaves like dependentSchemas.
    if (lDependencyValue is TJSONObject) or (lDependencyValue is TJSONBool) then
    begin
      lNewScope := lScope;
      lNewScope.SchemaPath        := Format('%s/dependencies/%s', [lScope.SchemaPath, lDependencyPair.JsonString.Value]);
      lNewScope.SchemaNode        := lDependencyValue;
      lNewScope.CoveredItems      := [];
      lNewScope.ContainsCount     := 0;
      lNewScope.VisitedKeywords   := [];
      lNewScope.CoveredProperties := [];

      Visitor.PushScope(lNewScope);
      lErrorCount := Length(Visitor.Result.Errors);
      try
        lWalker := TWalker<TDraft2019_09Visitor>.Create(lDependencyValue, Visitor);
        lWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      if Length(Visitor.Result.Errors) = lErrorCount then
      begin
        lPropertyKey := Format('%s/%s', [lScope.InstancePath, lDependencyPair.JsonString.Value]);
        if not Assigned(lScope.EvaluatedPropertiesInScope) then
          lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
        lScope.EvaluatedPropertiesInScope.Add(lPropertyKey);
        Visitor.Result.AddEvaluatedProperty(lPropertyKey);
      end;
    end;
  end;

  Visitor.UpdateScope(lScope);
end;

procedure TDraft2019_09ValidationVisitor.VisitMaxContains(const pValue: TJSONNumber);
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

procedure TDraft2019_09ValidationVisitor.VisitMinContains(const pValue: TJSONNumber);
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

procedure TDraft2019_09ValidationVisitor.VisitPropertyNames(const pValue: TJSONValue);
begin
  inherited VisitPropertyNames(pValue);
end;

{ TDraft2019_09ApplicatorVisitor }

procedure TDraft2019_09ApplicatorVisitor.VisitDefs(const pValue: TJSONObject);
begin

end;

procedure TDraft2019_09ApplicatorVisitor.VisitDependentSchemas(const pValue: TJSONObject);
var
  lScope: TScope;
  lInstance: TJSONObject;
  lDependencyPair: TJSONPair;
  lSubSchema: TJSONValue;
  lNewScope: TScope;
  lWalker: IWalker;
  lErrorCount: Integer;
  lEvaluatedProperty: string;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'object' then
    Exit;

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
        lWalker := TWalker<TDraft2019_09Visitor>.Create(lSubSchema, Visitor);
        lWalker.Walk;
      finally
        lNewScope := Visitor.PopScope;
      end;

      if Length(Visitor.Result.Errors) = lErrorCount then
      begin
        if not Assigned(lScope.EvaluatedPropertiesInScope) then
          lScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
        if Assigned(lNewScope.EvaluatedPropertiesInScope) then
          for lEvaluatedProperty in lNewScope.EvaluatedPropertiesInScope do
            lScope.EvaluatedPropertiesInScope.Add(lEvaluatedProperty);
      end;
    end;
  end;

  Visitor.UpdateScope(lScope);
end;

procedure TDraft2019_09ApplicatorVisitor.VisitPrefixItems(const pValue: TJSONArray);
begin
  // prefixItems é desconhecido em 2019-09 e deve ser ignorado.
end;

procedure TDraft2019_09ApplicatorVisitor.VisitUnevaluatedItems(const pValue: TJSONValue);
var
  lCount: Integer;
  lScope: TScope;
  lWalker: IWalker;
  lEvaluated: THashSet<string>;
  lEvaluatedPath: string;
  lItemPath: string;
  lCoveredIndex: Integer;
  lCurrentPrefix: string;
  lCanonicalPrefix: string;
  lCanonicalPath: string;
  lNewScope: TScope;
  lErrorCount: Integer;
begin
  lScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(lScope.InstanceNode) <> 'array' then
    Exit;

  lEvaluated := THashSet<string>.Create;
  try
    if lScope.InstancePath.EndsWith('/') then
      lCurrentPrefix := lScope.InstancePath
    else
      lCurrentPrefix := lScope.InstancePath + '/';

    lCanonicalPrefix := lCurrentPrefix;
    if lCanonicalPrefix.StartsWith('#/') then
      lCanonicalPrefix := lCanonicalPrefix.Substring(1)
    else if lCanonicalPrefix = '#/' then
      lCanonicalPrefix := '/'
    else if lCanonicalPrefix.StartsWith('#.') then
      lCanonicalPrefix := '/' + StringReplace(lCanonicalPrefix.Substring(2), '.', '/', [rfReplaceAll]);

    for lEvaluatedPath in Visitor.Result.EvaluatedProperties do
    begin
      lCanonicalPath := lEvaluatedPath;
      if lCanonicalPath.StartsWith('#/') then
        lCanonicalPath := lCanonicalPath.Substring(1)
      else if lCanonicalPath.StartsWith('#.') then
        lCanonicalPath := '/' + StringReplace(lCanonicalPath.Substring(2), '.', '/', [rfReplaceAll]);
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
        lWalker := TWalker<TDraft2019_09Visitor>.Create(pValue, Visitor);
        lWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      if Length(Visitor.Result.Errors) > lErrorCount then
        Visitor.AddError(vetUnevaluatedItems, [lCount]);

      TUtils.AddArray<Integer>(lScope.CoveredItems, lCount);
      Visitor.Result.AddEvaluatedProperty('#' + lItemPath);
    end;
  finally
    lEvaluated.Free;
  end;

  Visitor.UpdateScope(lScope);
end;

procedure TDraft2019_09ApplicatorVisitor.VisitUnevaluatedProperties(const pValue: TJSONValue);
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

  lEvaluated := THashSet<string>.Create;
  try
    if lScope.InstancePath.EndsWith('/') then
      lCurrentPrefix := lScope.InstancePath
    else
      lCurrentPrefix := lScope.InstancePath + '/';

    if lCurrentPrefix.StartsWith('#/') then
      lCurrentPrefix := lCurrentPrefix.Substring(1)
    else if lCurrentPrefix.StartsWith('#.') then
      lCurrentPrefix := '/' + StringReplace(lCurrentPrefix.Substring(2), '.', '/', [rfReplaceAll]);

    for lEvaluatedProp in Visitor.Result.EvaluatedProperties do
    begin
      lCanonicalPath := lEvaluatedProp;
      if lCanonicalPath.StartsWith('#/') then
        lCanonicalPath := lCanonicalPath.Substring(1)
      else if lCanonicalPath.StartsWith('#.') then
        lCanonicalPath := '/' + StringReplace(lCanonicalPath.Substring(2), '.', '/', [rfReplaceAll]);
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
        lWalker := TWalker<TDraft2019_09Visitor>.Create(pValue, Visitor);
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
        lScope.EvaluatedPropertiesInScope.Add('#' + lPropKey);
        Visitor.Result.AddEvaluatedProperty('#' + lPropKey);
      end;
    end;
  finally
    lEvaluated.Free;
  end;

  Visitor.UpdateScope(lScope);
end;

end.
