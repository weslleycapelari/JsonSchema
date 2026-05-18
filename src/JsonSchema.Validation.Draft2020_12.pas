unit JsonSchema.Validation.Draft2020_12;

interface

uses
  System.JSON,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Interfaces;

type
  TDraft2020_12Visitor = class(TValidationVisitor<TDraft2020_12Visitor>, IDraft2019_09ValidationVocabularyMode)
  private
    FFormatAssertionEnabled: Boolean;
    FValidationVocabularySilent: Boolean;
  public
    constructor Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue = nil);
    function New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft2020_12Visitor; override;
    function KeywordPrecedence: TArray<string>; override;
    function IsFormatAssertionEnabled: Boolean;
    procedure SetFormatAssertionEnabled(const AValue: Boolean);
    function IsValidationVocabularySilent: Boolean;
    procedure SetValidationVocabularySilent(const AValue: Boolean);
  end;

  IDraft2020_12CoreVisitor = interface(IBaseCoreVisitor<TDraft2020_12Visitor>)
    ['{D73FF534-BC9D-4673-8C79-EF7D745FF989}']
    procedure VisitSchema(const AValue: TJSONString);
    procedure VisitComment(const AValue: TJSONString);
    procedure VisitAnchor(const AValue: TJSONString);
    procedure VisitDynamicRef(const AValue: TJSONString);
    procedure VisitDynamicAnchor(const AValue: TJSONString);
    procedure VisitVocabulary(const AValue: TJSONObject);
  end;

  IDraft2020_12ApplicatorVisitor = interface(IBaseApplicatorVisitor<TDraft2020_12Visitor>)
    ['{93807819-1E9D-4017-A18B-67D5E9DDEC91}']
    procedure VisitItems(const AValue: TJSONValue);
    procedure VisitPrefixItems(const AValue: TJSONArray);
    procedure VisitDependentSchemas(const AValue: TJSONObject);
    procedure VisitUnevaluatedItems(const AValue: TJSONValue);
    procedure VisitUnevaluatedProperties(const AValue: TJSONValue);
  end;

  IDraft2020_12ValidationVisitor = interface(IBaseValidationVisitor<TDraft2020_12Visitor>)
    ['{5FCB391C-EA34-44F8-B46B-05423547C9F6}']
    procedure VisitContains(const AValue: TJSONValue);
    procedure VisitPropertyNames(const AValue: TJSONValue);
    procedure VisitDependentRequired(const AValue: TJSONObject);
    procedure VisitMaxContains(const AValue: TJSONNumber);
    procedure VisitMinContains(const AValue: TJSONNumber);
  end;

  IDraft2020_12RelativeJsonPointer = interface(IBaseRelativeJsonPointer<TDraft2020_12Visitor>)
    ['{B4EA36F6-247C-41AA-BCC6-5A83AC80CE1B}']
  end;

  TDraft2020_12CoreVisitor = class(TBaseCoreVisitor<TDraft2020_12Visitor>, IDraft2020_12CoreVisitor)
    [VisitorKeyword('$schema')]
    procedure VisitSchema(const AValue: TJSONString);
    [VisitorKeyword('$comment')]
    procedure VisitComment(const AValue: TJSONString);
    [VisitorKeyword('$anchor')]
    procedure VisitAnchor(const AValue: TJSONString);
    [VisitorKeyword('$dynamicRef')]
    procedure VisitDynamicRef(const AValue: TJSONString);
    [VisitorKeyword('$dynamicAnchor')]
    procedure VisitDynamicAnchor(const AValue: TJSONString);
    [VisitorKeyword('$vocabulary')]
    procedure VisitVocabulary(const AValue: TJSONObject);
  end;

  TDraft2020_12ApplicatorVisitor = class(TBaseApplicatorVisitor<TDraft2020_12Visitor>, IDraft2020_12ApplicatorVisitor)
    [VisitorKeyword('items')]
    procedure VisitItems(const AValue: TJSONValue);
    [VisitorKeyword('prefixItems')]
    procedure VisitPrefixItems(const AValue: TJSONArray);
    [VisitorKeyword('dependentSchemas')]
    procedure VisitDependentSchemas(const AValue: TJSONObject);
    [VisitorKeyword('unevaluatedItems')]
    procedure VisitUnevaluatedItems(const AValue: TJSONValue);
    [VisitorKeyword('unevaluatedProperties')]
    procedure VisitUnevaluatedProperties(const AValue: TJSONValue);
  end;

  TDraft2020_12ValidationVisitor = class(TBaseValidationVisitor<TDraft2020_12Visitor>, IDraft2020_12ValidationVisitor)
  public
    [VisitorKeyword('format')]
    procedure VisitFormat(const pValue: TJSONString); reintroduce;
    [VisitorKeyword('contains')]
    procedure VisitContains(const AValue: TJSONValue);
    [VisitorKeyword('propertyNames')]
    procedure VisitPropertyNames(const AValue: TJSONValue);
    [VisitorKeyword('dependentRequired')]
    procedure VisitDependentRequired(const AValue: TJSONObject);
    [VisitorKeyword('maxContains')]
    procedure VisitMaxContains(const AValue: TJSONNumber);
    [VisitorKeyword('minContains')]
    procedure VisitMinContains(const AValue: TJSONNumber);
  end;

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

function NormalizeToFullInstancePath(const APath: string): string; forward;

{ TDraft2020_12Visitor }

constructor TDraft2020_12Visitor.Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue);
var
  LSchemaURI: string;
begin
  inherited Create(ASchema, AData, ABaseURI, ACustomHint);

  FFormatAssertionEnabled := False;
  FValidationVocabularySilent := False;
  if (ASchema is TJSONObject) and
     TJSONObject(ASchema).TryGetValue<string>('$schema', LSchemaURI) and
     ContainsText(LSchemaURI, 'metaschema-no-validation.json') then
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

function TDraft2020_12Visitor.New(const ASchema, AData: TJSONValue; const ABaseURI: string): TDraft2020_12Visitor;
begin
  Result := TDraft2020_12Visitor.Create(ASchema, AData, ABaseURI, FCustomHint);
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

procedure TDraft2020_12Visitor.SetFormatAssertionEnabled(const AValue: Boolean);
begin
  FFormatAssertionEnabled := AValue;
end;

function TDraft2020_12Visitor.IsValidationVocabularySilent: Boolean;
begin
  Result := FValidationVocabularySilent;
end;

procedure TDraft2020_12Visitor.SetValidationVocabularySilent(const AValue: Boolean);
begin
  FValidationVocabularySilent := AValue;
end;

{ TDraft2020_12CoreVisitor }

procedure TDraft2020_12CoreVisitor.VisitSchema(const AValue: TJSONString);
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
  LScope: TScope;
  LSchemaURI: TURIReference;
  LMetaResource: TResource;
  LMetaSchemaRoot: TJSONValue;
  LVocabularyValue: TJSONValue;
  LValidationVocabularyValue: TJSONValue;
  LValidationVocabularyRequired: Boolean;
  LValidationKeyword: string;
begin
  // Em 2020-12, format e anotacao por padrao.
  // A ativacao estrita e controlada por $vocabulary no schema corrente.
  TDraft2020_12Visitor(Visitor).SetFormatAssertionEnabled(False);

  LScope := Visitor.CurrentScope;
  LSchemaURI := TURIReference.From(AValue.Value).ResolveWith(TURIReference.From(LScope.BaseURI));

  if not Visitor.Registry.TryFindResource(LSchemaURI.Unsplit, LMetaResource) then
  begin
    if ContainsText(LSchemaURI.Unsplit, 'metaschema-no-validation.json') then
      TDraft2020_12Visitor(Visitor).SetValidationVocabularySilent(True);
  end
  else
  begin
    LMetaSchemaRoot := LMetaResource.ResolveFragment('');
    if (LMetaSchemaRoot is TJSONObject) and
       TJSONObject(LMetaSchemaRoot).TryGetValue('$vocabulary', LVocabularyValue) and
       (LVocabularyValue is TJSONObject) and
       TJSONObject(LVocabularyValue).TryGetValue(CValidationVocabularyURI, LValidationVocabularyValue) and
       (LValidationVocabularyValue is TJSONBool) then
      LValidationVocabularyRequired := TJSONBool(LValidationVocabularyValue).AsBoolean
    else
      LValidationVocabularyRequired := True;

    TDraft2020_12Visitor(Visitor).SetValidationVocabularySilent(not LValidationVocabularyRequired);
  end;

  if TDraft2020_12Visitor(Visitor).IsValidationVocabularySilent then
    for LValidationKeyword in CValidationKeywords do
      Visitor.AddVisitedKeyword(LValidationKeyword);
end;

procedure TDraft2020_12CoreVisitor.VisitAnchor(const AValue: TJSONString);
begin

end;

procedure TDraft2020_12CoreVisitor.VisitComment(const AValue: TJSONString);
begin

end;

procedure TDraft2020_12CoreVisitor.VisitDynamicAnchor(const AValue: TJSONString);
begin

end;

procedure TDraft2020_12CoreVisitor.VisitDynamicRef(const AValue: TJSONString);
var
  LScope: TScope;
  LFinalURI: TURIReference;
  LTargetResource: TResource;
  LTargetSchema: TJSONValue;
  LResolvedBaseURI: string;
  LTargetDynamicAnchorValue: TJSONValue;
  LDynamicAnchorName: string;
  LScopeAnchorValue: TJSONValue;
  LScopeAnchorName: string;
  LOffset: Integer;
  LMaxOffset: Integer;
  LDynamicBaseRef: TURIReference;
  LDynamicBaseURI: string;
  LDynamicRefValue: TJSONString;
  LOriginalScope: TScope;
  LScopeAfterRef: TScope;
  LResultEvaluatedBeforeRef: THashSet<string>;
  LScopeResource: TResource;
  LScopeAnchoredSchema: TJSONValue;

  function ResolveDynamicAnchor(const AResource: TResource; const AAnchorName: string; out AResolvedBaseURI: string): TJSONValue;
  begin
    Result := AResource.ResolveFragment(AAnchorName, AResolvedBaseURI);
    if Assigned(Result) then
      Exit;

    Result := AResource.ResolveFragment('#' + AAnchorName, AResolvedBaseURI);
  end;

  function NormalizeAnchorName(const AAnchor: string): string;
  begin
    Result := Trim(AAnchor);
    if Result.StartsWith('#') then
      Result := Result.Substring(1);
  end;

  function NormalizeLocalPath(const APath: string): string;
  begin
    Result := Trim(APath);

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
    LInjectScope: TScope;
    LEvaluatedProperty: string;
  begin
    LInjectScope := Visitor.CurrentScope;
    if not Assigned(LInjectScope.EvaluatedPropertiesInScope) then
      LInjectScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

    for LEvaluatedProperty in Visitor.Result.EvaluatedProperties do
      LInjectScope.EvaluatedPropertiesInScope.Add(NormalizeLocalPath(LEvaluatedProperty));

    Visitor.UpdateScope(LInjectScope);
  end;

  procedure ExecuteRefWithCurrentVisitor(const ARefValue: TJSONString);
  var
    LEvaluatedProperty: string;
    LNormalizedEvaluatedProperty: string;
    LScopeForSync: TScope;
    LCanonicalScopePath: string;
    LCanonicalPrefix: string;
    LRelativePath: string;
    LSegmentSeparator: Integer;
    LFirstSegment: string;
    LItemIndex: Integer;
  begin
    InjectParentEvaluatedIntoCurrentScope;

    LResultEvaluatedBeforeRef := THashSet<string>.Create;
    for LEvaluatedProperty in Visitor.Result.EvaluatedProperties do
      LResultEvaluatedBeforeRef.Add(NormalizeLocalPath(LEvaluatedProperty));

    LOriginalScope := Visitor.CurrentScope;
    try
      inherited VisitRef(ARefValue);

      LScopeForSync := Visitor.CurrentScope;
      if not Assigned(LScopeForSync.EvaluatedPropertiesInScope) then
        LScopeForSync.EvaluatedPropertiesInScope := THashSet<string>.Create;

      for LEvaluatedProperty in Visitor.Result.EvaluatedProperties do
      begin
        LNormalizedEvaluatedProperty := NormalizeLocalPath(LEvaluatedProperty);
        if LResultEvaluatedBeforeRef.Contains(LNormalizedEvaluatedProperty) then
          Continue;

        LScopeForSync.EvaluatedPropertiesInScope.Add(LNormalizedEvaluatedProperty);

        LCanonicalScopePath := NormalizeLocalPath(LScopeForSync.InstancePath);
        if LCanonicalScopePath = '/' then
          LCanonicalPrefix := '/'
        else
          LCanonicalPrefix := LCanonicalScopePath + '/';

        if not LNormalizedEvaluatedProperty.StartsWith(LCanonicalPrefix) then
          Continue;

        LRelativePath := LNormalizedEvaluatedProperty.Substring(Length(LCanonicalPrefix));
        LSegmentSeparator := Pos('/', LRelativePath);
        if LSegmentSeparator > 0 then
          LFirstSegment := Copy(LRelativePath, 1, LSegmentSeparator - 1)
        else
          LFirstSegment := LRelativePath;

        if TryStrToInt(LFirstSegment, LItemIndex) then
          TUtils.AddArray<Integer>(LScopeForSync.CoveredItems, LItemIndex)
        else if LFirstSegment <> '' then
          TUtils.AddArray<string>(LScopeForSync.CoveredProperties, LFirstSegment);
      end;
      Visitor.UpdateScope(LScopeForSync);
    finally
      LResultEvaluatedBeforeRef.Free;

      LScopeAfterRef := Visitor.CurrentScope;
      if not SameText(LScopeAfterRef.BaseURI, LOriginalScope.BaseURI) then
      begin
        LScopeAfterRef.BaseURI := LOriginalScope.BaseURI;
        Visitor.UpdateScope(LScopeAfterRef);
      end;
    end;
  end;

begin
  LScope := Visitor.CurrentScope;
  LFinalURI := TURIReference.From(AValue.Value).ResolveWith(TURIReference.From(LScope.BaseURI));
  LDynamicAnchorName := NormalizeAnchorName(LFinalURI.Fragment);

  if LDynamicAnchorName.IsEmpty or LDynamicAnchorName.StartsWith('/') then
  begin
    ExecuteRefWithCurrentVisitor(AValue);
    Exit;
  end;

  // Regra estrita: so aplica escopo dinamico se o alvo original for dynamic anchor valido.
  if not Visitor.Registry.TryFindResource(LFinalURI.Unsplit, LTargetResource) then
  begin
    ExecuteRefWithCurrentVisitor(AValue);
    Exit;
  end;

  LTargetSchema := ResolveDynamicAnchor(LTargetResource, LDynamicAnchorName, LResolvedBaseURI);
  if not Assigned(LTargetSchema) then
  begin
    ExecuteRefWithCurrentVisitor(AValue);
    Exit;
  end;

  if not ((LTargetSchema is TJSONObject) and
          TJSONObject(LTargetSchema).TryGetValue('$dynamicAnchor', LTargetDynamicAnchorValue) and
          (LTargetDynamicAnchorValue is TJSONString) and
          SameText(NormalizeAnchorName(TJSONString(LTargetDynamicAnchorValue).Value), LDynamicAnchorName)) then
  begin
    ExecuteRefWithCurrentVisitor(AValue);
    Exit;
  end;

  LDynamicBaseURI := '';
  LMaxOffset := -1;
  LOffset := 0;
  while Assigned(Visitor.CurrentScope(LOffset).SchemaNode) do
  begin
    LMaxOffset := LOffset;
    Inc(LOffset);
  end;

  // Spec: traverse from outermost (root) to innermost scope.
  // For each scope, resolve the anchor via Registry by BaseURI — not by inspecting SchemaNode directly,
  // because the $dynamicAnchor may live in a $defs sub-schema, not at the root of the scope's SchemaNode.
  for LOffset := LMaxOffset downto 0 do
  begin
    LScope := Visitor.CurrentScope(LOffset);
    if LScope.BaseURI.IsEmpty then
      Continue;

    if not Visitor.Registry.TryFindResource(LScope.BaseURI, LScopeResource) then
      Continue;

    LScopeAnchoredSchema := ResolveDynamicAnchor(LScopeResource, LDynamicAnchorName, LResolvedBaseURI);
    if not Assigned(LScopeAnchoredSchema) then
      Continue;

    if not ((LScopeAnchoredSchema is TJSONObject) and
            TJSONObject(LScopeAnchoredSchema).TryGetValue('$dynamicAnchor', LScopeAnchorValue) and
            (LScopeAnchorValue is TJSONString)) then
      Continue;

    LScopeAnchorName := NormalizeAnchorName(TJSONString(LScopeAnchorValue).Value);
    if not SameText(LScopeAnchorName, LDynamicAnchorName) then
      Continue;

    LDynamicBaseRef := TURIReference.From(LScope.BaseURI);
    LDynamicBaseRef.Query := '';
    LDynamicBaseRef.Fragment := '';
    LDynamicBaseURI := LDynamicBaseRef.Unsplit;
    Break;
  end;

  if LDynamicBaseURI.IsEmpty then
  begin
    ExecuteRefWithCurrentVisitor(AValue);
    Exit;
  end;

  LDynamicRefValue := TJSONString.Create(LDynamicBaseURI + '#' + LDynamicAnchorName);
  try
    ExecuteRefWithCurrentVisitor(LDynamicRefValue);
  finally
    LDynamicRefValue.Free;
  end;
end;

procedure TDraft2020_12CoreVisitor.VisitVocabulary(const AValue: TJSONObject);
const
  CFormatAssertionVocabularyURI = 'https://json-schema.org/draft/2020-12/vocab/format-assertion';
var
  LFormatAssertionValue: TJSONValue;
  LFormatAssertionEnabled: Boolean;
begin
  LFormatAssertionEnabled := False;

  if AValue.TryGetValue(CFormatAssertionVocabularyURI, LFormatAssertionValue) and
     (LFormatAssertionValue is TJSONBool) and
     TJSONBool(LFormatAssertionValue).AsBoolean then
    LFormatAssertionEnabled := True;

  TDraft2020_12Visitor(Visitor).SetFormatAssertionEnabled(LFormatAssertionEnabled);
end;

{ TDraft2020_12ValidationVisitor }

procedure TDraft2020_12ValidationVisitor.VisitFormat(const pValue: TJSONString);
begin
  Visitor.Result.AddEvaluatedProperty(NormalizeToFullInstancePath(Visitor.CurrentScope.InstancePath));
  Visitor.Result.AddAnnotation('format', pValue.Value);

  if not TDraft2020_12Visitor(Visitor).FFormatAssertionEnabled then
    Exit;

  inherited VisitFormat(pValue);
end;

procedure TDraft2020_12ValidationVisitor.VisitContains(const AValue: TJSONValue);
var
  LScope: TScope;
  LCount: Integer;
  LWalker: IWalker;
  LSchema: TJSONNumber;
  LVisitor: TDraft2020_12Visitor;
  LNewScope: TScope;
  LInstance: TJSONArray;
  LItemPath: string;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'array' then
    Exit;

  if AValue is TJSONBool then
  begin
    if TJSONBool(AValue).AsBoolean and (TJSONArray(LScope.InstanceNode).Count > 0) then
    begin
      LInstance := TJSONArray(LScope.InstanceNode);
      for LCount := 0 to LInstance.Count - 1 do
      begin
        TUtils.AddArray<Integer>(LScope.CoveredItems, LCount);
        LItemPath := NormalizeToFullInstancePath(Format('%s/%d', [LScope.InstancePath, LCount]));
        Visitor.Result.AddEvaluatedProperty(LItemPath);
      end;
      Visitor.UpdateScope(LScope);
      Exit;
    end;

    if not TJSONBool(AValue).AsBoolean then
    begin
       Visitor.AddError(vetContains);
       Exit;
    end;
  end;

  LInstance := TJSONArray(LScope.InstanceNode);
  for LCount := 0 to LInstance.Count - 1 do
  begin
    LNewScope := LScope;
    LNewScope.SchemaPath        := Format('%s/contains', [LScope.SchemaPath]);
    LNewScope.SchemaNode        := AValue;
    LNewScope.InstanceNode      := LInstance[LCount];
    LNewScope.InstancePath      := Format('%s/%d', [LScope.InstancePath, LCount]);
    LNewScope.CoveredItems      := [];
    LNewScope.ContainsCount     := 0;
    LNewScope.VisitedKeywords   := [];
    LNewScope.CoveredProperties := [];

    Visitor.PushScope(LNewScope);
    LVisitor := Visitor.New(AValue, LInstance[LCount], LScope.BaseURI);
    try
      LWalker := TWalker<TDraft2020_12Visitor>.Create(AValue, LVisitor);
      LWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    if LVisitor.Result.IsValid then
    begin
      Inc(LScope.ContainsCount);
      TUtils.AddArray<Integer>(LScope.CoveredItems, LCount);
      LItemPath := NormalizeToFullInstancePath(Format('%s/%d', [LScope.InstancePath, LCount]));
      Visitor.Result.AddEvaluatedProperty(LItemPath);
    end;
  end;

  Visitor.UpdateScope(LScope);

  if not LScope.SchemaNode.TryGetValue('minContains', LSchema) then
    LSchema := TJSONNumber.Create(1);

  VisitMinContains(LSchema);

  if LScope.SchemaNode.TryGetValue('maxContains', LSchema) then
    VisitMaxContains(LSchema);

  Visitor
    .AddVisitedKeyword('minContains')
    .AddVisitedKeyword('maxContains');
end;

procedure TDraft2020_12ValidationVisitor.VisitDependentRequired(const AValue: TJSONObject);
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

procedure TDraft2020_12ValidationVisitor.VisitMaxContains(const AValue: TJSONNumber);
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

procedure TDraft2020_12ValidationVisitor.VisitMinContains(const AValue: TJSONNumber);
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

procedure TDraft2020_12ValidationVisitor.VisitPropertyNames(const AValue: TJSONValue);
begin
  inherited VisitPropertyNames(AValue);
end;

{ TDraft2020_12ApplicatorVisitor }

procedure TDraft2020_12ApplicatorVisitor.VisitItems(const AValue: TJSONValue);
begin
  // Em 2020-12, tuple validation foi movida para prefixItems.
  if AValue is TJSONArray then
    Exit;

  inherited VisitItems(AValue);
end;

procedure TDraft2020_12ApplicatorVisitor.VisitPrefixItems(const AValue: TJSONArray);
begin
  inherited VisitPrefixItems(AValue);
end;

procedure TDraft2020_12ApplicatorVisitor.VisitDependentSchemas(const AValue: TJSONObject);
var
  LScope: TScope;
  LInstance: TJSONObject;
  LDependencyPair: TJSONPair;
  LSubSchema: TJSONValue;
  LNewScope: TScope;
  LWalker: IWalker;
  LErrorCount: Integer;
  LResultEvaluatedBefore: THashSet<string>;
  LEvaluatedProperty: string;
  LNormalizedEvaluatedProperty: string;
  LCanonicalScopePath: string;
  LCanonicalPrefix: string;
  LRelativePath: string;
  LSegmentSeparator: Integer;
  LFirstSegment: string;
  LItemIndex: Integer;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  LResultEvaluatedBefore := THashSet<string>.Create;
  try
    for LEvaluatedProperty in Visitor.Result.EvaluatedProperties do
      LResultEvaluatedBefore.Add(LEvaluatedProperty);

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
        LWalker := TWalker<TDraft2020_12Visitor>.Create(LSubSchema, Visitor);
        LWalker.Walk;
      finally
        LNewScope := Visitor.PopScope;
      end;

      if Length(Visitor.Result.Errors) = LErrorCount then
      begin
        LScope.CoveredItems := TUtils.MergeArray<Integer>([LScope.CoveredItems, LNewScope.CoveredItems]);
        LScope.CoveredProperties := TUtils.MergeArray<string>([LScope.CoveredProperties, LNewScope.CoveredProperties]);

        if not Assigned(LScope.EvaluatedPropertiesInScope) then
          LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

        if Assigned(LNewScope.EvaluatedPropertiesInScope) then
          for LEvaluatedProperty in LNewScope.EvaluatedPropertiesInScope do
            LScope.EvaluatedPropertiesInScope.Add(LEvaluatedProperty);

        LCanonicalScopePath := NormalizeToFullInstancePath(LScope.InstancePath);
        if LCanonicalScopePath = '/' then
          LCanonicalPrefix := '/'
        else
          LCanonicalPrefix := LCanonicalScopePath + '/';

        for LEvaluatedProperty in Visitor.Result.EvaluatedProperties do
        begin
          if LResultEvaluatedBefore.Contains(LEvaluatedProperty) then
            Continue;

          LNormalizedEvaluatedProperty := NormalizeToFullInstancePath(LEvaluatedProperty);
          LScope.EvaluatedPropertiesInScope.Add(LNormalizedEvaluatedProperty);

          if not LNormalizedEvaluatedProperty.StartsWith(LCanonicalPrefix) then
            Continue;

          LRelativePath := LNormalizedEvaluatedProperty.Substring(Length(LCanonicalPrefix));
          LSegmentSeparator := Pos('/', LRelativePath);
          if LSegmentSeparator > 0 then
            LFirstSegment := Copy(LRelativePath, 1, LSegmentSeparator - 1)
          else
            LFirstSegment := LRelativePath;

          if TryStrToInt(LFirstSegment, LItemIndex) then
            TUtils.AddArray<Integer>(LScope.CoveredItems, LItemIndex)
          else if LFirstSegment <> '' then
            TUtils.AddArray<string>(LScope.CoveredProperties, LFirstSegment);
        end;
      end;
    end;
  end;

  Visitor.UpdateScope(LScope);
  finally
    LResultEvaluatedBefore.Free;
  end;
end;

function NormalizeToFullInstancePath(const APath: string): string;
begin
  Result := Trim(APath);

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

procedure TDraft2020_12ApplicatorVisitor.VisitUnevaluatedItems(const AValue: TJSONValue);
var
  LCount: Integer;
  LScope: TScope;
  LWalker: IWalker;
  LEvaluated: THashSet<string>;
  LEvaluatedPath: string;
  LCoveredIndex: Integer;
  LNewScope: TScope;
  LErrorCount: Integer;
  LCurrentPrefix: string;
  LCanonicalPrefix: string;
  LCanonicalPath: string;
  LItemPath: string;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'array' then
    Exit;

  if (TUtils.JsonGetType(AValue) = 'boolean') and TJSONBool(AValue).AsBoolean then
  begin
    LCurrentPrefix := NormalizeToFullInstancePath(LScope.InstancePath);
    if LCurrentPrefix.EndsWith('/') then
      LCanonicalPrefix := LCurrentPrefix
    else
      LCanonicalPrefix := LCurrentPrefix + '/';

    for LCount := 0 to TJSONArray(LScope.InstanceNode).Count - 1 do
    begin
      TUtils.AddArray<Integer>(LScope.CoveredItems, LCount);
      LItemPath := Format('%s%d', [LCanonicalPrefix, LCount]);
      Visitor.Result.AddEvaluatedProperty(LItemPath);
    end;

    Visitor.UpdateScope(LScope);
    Exit;
  end;

  LEvaluated := THashSet<string>.Create;
  try
    LCurrentPrefix := NormalizeToFullInstancePath(LScope.InstancePath);
    if LCurrentPrefix.EndsWith('/') then
      LCanonicalPrefix := LCurrentPrefix
    else
      LCanonicalPrefix := LCurrentPrefix + '/';

    for LEvaluatedPath in Visitor.Result.EvaluatedProperties do
    begin
      LCanonicalPath := NormalizeToFullInstancePath(LEvaluatedPath);
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
        LWalker := TWalker<TDraft2020_12Visitor>.Create(AValue, Visitor);
        LWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      if Length(Visitor.Result.Errors) > LErrorCount then
        Visitor.AddError(vetUnevaluatedItems, [LCount]);

      TUtils.AddArray<Integer>(LScope.CoveredItems, LCount);
      Visitor.Result.AddEvaluatedProperty(LItemPath);
    end;
  finally
    LEvaluated.Free;
  end;

  Visitor.UpdateScope(LScope);
end;

procedure TDraft2020_12ApplicatorVisitor.VisitUnevaluatedProperties(const AValue: TJSONValue);
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

  if (TUtils.JsonGetType(AValue) = 'boolean') and TJSONBool(AValue).AsBoolean then
  begin
    LCurrentPrefix := NormalizeToFullInstancePath(LScope.InstancePath);
    if not LCurrentPrefix.EndsWith('/') then
      LCurrentPrefix := LCurrentPrefix + '/';

    if not Assigned(LScope.EvaluatedPropertiesInScope) then
      LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

    for LPair in TJSONObject(LScope.InstanceNode) do
    begin
      LPropKey := LCurrentPrefix + LPair.JsonString.Value;
      TUtils.AddArray<string>(LScope.CoveredProperties, LPair.JsonString.Value);
      LScope.EvaluatedPropertiesInScope.Add(LPropKey);
      Visitor.Result.AddEvaluatedProperty(LPropKey);
    end;

    Visitor.UpdateScope(LScope);
    Exit;
  end;

  LEvaluated := THashSet<string>.Create;
  try
    LCurrentPrefix := NormalizeToFullInstancePath(LScope.InstancePath);
    if LCurrentPrefix.EndsWith('/') then
      LCurrentPrefix := LCurrentPrefix
    else
      LCurrentPrefix := LCurrentPrefix + '/';

    for LEvaluatedProp in Visitor.Result.EvaluatedProperties do
    begin
      LCanonicalPath := NormalizeToFullInstancePath(LEvaluatedProp);
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
        LWalker := TWalker<TDraft2020_12Visitor>.Create(AValue, Visitor);
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
        LScope.EvaluatedPropertiesInScope.Add(LPropKey);
        Visitor.Result.AddEvaluatedProperty(LPropKey);
      end;
    end;
  finally
    LEvaluated.Free;
  end;

  Visitor.UpdateScope(LScope);
end;

end.

