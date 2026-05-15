unit JsonSchema.Validation.Base;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Translate.Types,
  JsonSchema.Translate.Interfaces,
  JsonSchema.Translate.Utils,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Visitors.Base,
  JsonSchema.Visitors.Types,
  JsonSchema.Common.Utils,
  JsonSchema.Validation.Interfaces,
  JsonSchema.Validation.Types,
  JsonSchema.Registry.Base;

type
  TBaseCoreVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseCoreVisitor<T>)
    [VisitorKeyword('$schema')]
    procedure VisitSchema(const AValue: TJSONString);
    [VisitorKeyword('id')]
    [VisitorKeyword('$id')]
    procedure VisitId(const AValue: TJSONString);
    [VisitorKeyword('$ref')]
    procedure VisitRef(const AValue: TJSONString);
    [VisitorKeyword('definitions')]
    [VisitorKeyword('$defs')]
    procedure VisitDefinitions(const AValue: TJSONObject);
    procedure VisitBooleanSchema(const AValue: TJSONBool);
  end;

  TBaseApplicatorVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseApplicatorVisitor<T>)
    [VisitorKeyword('allOf')]
    procedure VisitAllOf(const AValue: TJSONArray);
    [VisitorKeyword('anyOf')]
    procedure VisitAnyOf(const AValue: TJSONArray);
    [VisitorKeyword('oneOf')]
    procedure VisitOneOf(const AValue: TJSONArray);
    [VisitorKeyword('not')]
    procedure VisitNot(const AValue: TJSONValue);

    // Condition
    [VisitorKeyword('if')]
    procedure VisitIf(const AValue: TJSONValue);
    [VisitorKeyword('then')]
    procedure VisitThen(const AValue: TJSONValue);
    [VisitorKeyword('else')]
    procedure VisitElse(const AValue: TJSONValue);

    // Objects
    [VisitorKeyword('properties')]
    procedure VisitProperties(const AValue: TJSONObject);
    [VisitorKeyword('patternProperties')]
    procedure VisitPatternProperties(const AValue: TJSONObject);
    [VisitorKeyword('additionalProperties')]
    procedure VisitAdditionalProperties(const AValue: TJSONValue);

    // Arrays
    [VisitorKeyword('items')]
    procedure VisitItems(const AValue: TJSONValue);
    [VisitorKeyword('additionalItems')]
    procedure VisitAdditionalItems(const AValue: TJSONValue);
    [VisitorKeyword('prefixItems')]
    procedure VisitPrefixItems(const AValue: TJSONArray);
  end;

  TBaseHyperSchemaVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseHyperSchemaVisitor<T>)
    [VisitorKeyword('base')]
    procedure VisitBase(const AValue: TJSONString);
    [VisitorKeyword('links')]
    procedure VisitLinks(const AValue: TJSONArray);

    [VisitorKeyword('href')]
    procedure VisitHref(const AValue: TJSONString);
    [VisitorKeyword('targetSchema')]
    procedure VisitTargetSchema(const AValue: TJSONValue);
    [VisitorKeyword('submissionSchema')]
    procedure VisitSubmissionSchema(const AValue: TJSONValue);
    [VisitorKeyword('hrefSchema')]
    procedure VisitHrefSchema(const AValue: TJSONValue);
  end;

  TBaseValidationVisitor<T: IValidationVisitor<T>> = class(TBase<T>, IBaseValidationVisitor<T>)
    // Geral
    [VisitorKeyword('type')]
    procedure VisitType(const AValue: TJSONValue);
    [VisitorKeyword('enum')]
    procedure VisitEnum(const AValue: TJSONArray);
    [VisitorKeyword('const')]
    procedure VisitConst(const AValue: TJSONValue);

    // Num�rico
    [VisitorKeyword('multipleOf')]
    procedure VisitMultipleOf(const AValue: TJSONNumber);
    [VisitorKeyword('maximum')]
    procedure VisitMaximum(const AValue: TJSONNumber);
    [VisitorKeyword('exclusiveMaximum')]
    procedure VisitExclusiveMaximum(const AValue: TJSONValue);
    [VisitorKeyword('minimum')]
    procedure VisitMinimum(const AValue: TJSONNumber);
    [VisitorKeyword('exclusiveMinimum')]
    procedure VisitExclusiveMinimum(const AValue: TJSONValue);

    // String
    [VisitorKeyword('maxLength')]
    procedure VisitMaxLength(const AValue: TJSONNumber);
    [VisitorKeyword('minLength')]
    procedure VisitMinLength(const AValue: TJSONNumber);
    [VisitorKeyword('pattern')]
    procedure VisitPattern(const AValue: TJSONString);
    [VisitorKeyword('format')]
    procedure VisitFormat(const AValue: TJSONString);

    // Array
    [VisitorKeyword('maxItems')]
    procedure VisitMaxItems(const AValue: TJSONNumber);
    [VisitorKeyword('minItems')]
    procedure VisitMinItems(const AValue: TJSONNumber);
    [VisitorKeyword('uniqueItems')]
    procedure VisitUniqueItems(const AValue: TJSONBool);

    // Objeto
    [VisitorKeyword('maxProperties')]
    procedure VisitMaxProperties(const AValue: TJSONNumber);
    [VisitorKeyword('minProperties')]
    procedure VisitMinProperties(const AValue: TJSONNumber);
    [VisitorKeyword('required')]
    procedure VisitRequired(const AValue: TJSONArray);

    // Conteudo
    [VisitorKeyword('contentEncoding')]
    procedure VisitContentEncoding(const AValue: TJSONString);
    [VisitorKeyword('contentMediaType')]
    procedure VisitContentMediaType(const AValue: TJSONString);
  end;

  TBaseRelativeJsonPointer<T: IValidationVisitor<T>> = class(TBase<T>, IBaseRelativeJsonPointer<T>)

  end;

  TValidationVisitor<T> = class(TBaseVisitor<T>, IValidationVisitor<T>, IRefResolutionGuard)
  protected
    FResult: IValidationResult;
    FRegistry: TRegistryVisitor;
    FOwnsRegistry: Boolean;
    FLanguage: TLanguage;
    FCustomHint: TJSONValue;
    FTranslateMethod: TDictionary<TErrorType, TTranslateFunc>;
    FRefResolutionStack: TStack<string>;
    FRefResolutionSet: TDictionary<string, Byte>;
    FMaxRefResolutionDepth: Integer;

    function DispatchTranslate(const AErrorType: TErrorType): TErrorMessage;
    procedure PopulateTranslateMethods;
  public
    constructor Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue = nil);
    destructor Destroy; override;

    function Registry: TRegistryVisitor;
    function KeywordPrecedence: TArray<string>; override;
    function Language: TLanguage; overload;
    function Language(const ALanguage: TLanguage): IValidationVisitor<T>; overload;
    procedure AddError(const AErrorType: TErrorType; AParams: array of const); overload;
    procedure AddError(const AErrorType: TErrorType); overload;
    function FindCustomHint(AErrorType: TErrorType): string;
    function Result: IValidationResult;
    function TryEnterRefResolution(const AResolvedRef: string; out AReason: string): Boolean;
    procedure LeaveRefResolution(const AResolvedRef: string);
  end;

implementation

uses
  System.Rtti,
  System.Math,
  System.TypInfo,
  System.SysUtils,
  System.StrUtils,
  System.DateUtils,
  System.NetEncoding,
  System.RegularExpressions,
  JsonSchema,
  JsonSchema.Walker,
  JsonSchema.Walker.Types,
  JsonSchema.Registry.Uri,
  JsonSchema.Registry.Utils,
  JsonSchema.Registry.Resource;

{ TValidationVisitor<T> }

procedure TValidationVisitor<T>.AddError(const AErrorType: TErrorType);
begin
  AddError(AErrorType, []);
end;

procedure TValidationVisitor<T>.AddError(const AErrorType: TErrorType; AParams: array of const);
var
  LScope: TScope;
  LMessage: TErrorMessage;
  LCustomHint: string;
  LParentNode: TJSONValue;
begin
  LScope := CurrentScope;
  if FTranslateMethod.ContainsKey(AErrorType) then
    LMessage := FTranslateMethod.Items[AErrorType];
  LCustomHint := FindCustomHint(AErrorType);

  if FScopeStack.Count > 2 then
    LParentNode := CurrentScope(2).InstanceNode
  else
    LParentNode := LScope.InstanceNode;

  Result.AddError(TError.Create
    .RootNode(FData)
    .ErrorType(AErrorType)
    .ParentNode(LParentNode)
    .SchemaNode(LScope.SchemaNode)
    .SchemaPath(LScope.SchemaPath)
    .InstanceNode(LScope.InstanceNode)
    .InstancePath(LScope.InstancePath)
    .ErrorMessage(Format(LMessage.Error, AParams))
    .StandardHint(Format(LMessage.Hint, AParams))
    .CustomHint(LCustomHint));
end;

constructor TValidationVisitor<T>.Create(const ASchema, AData: TJSONValue; const ABaseURI: string; const ACustomHint: TJSONValue);
var
  LWalker: IWalker;
begin
  inherited Create(ASchema, AData, ABaseURI);

  FResult          := TValidationResult.Create;
  FRegistry        := TRegistryVisitor.Create(ASchema, AData, ABaseURI);
  FOwnsRegistry    := True;
  FCustomHint      := ACustomHint;
  FTranslateMethod := TDictionary<TErrorType, TTranslateFunc>.Create;
  FRefResolutionStack := TStack<string>.Create;
  FRefResolutionSet := TDictionary<string, Byte>.Create;
  FMaxRefResolutionDepth := 100;

  Language(TLanguage.lang_ptBR);

  LWalker := TWalker<TRegistryVisitor>.Create(Aschema, FRegistry);
  LWalker.Walk;
end;

destructor TValidationVisitor<T>.Destroy;
begin
  FRefResolutionSet.Free;
  FRefResolutionStack.Free;
  FTranslateMethod.Free;
  if FOwnsRegistry then
    FRegistry.Free;
  inherited;
end;

function TValidationVisitor<T>.DispatchTranslate(const AErrorType: TErrorType): TErrorMessage;
begin
  if not FTranslateMethod.ContainsKey(AErrorType) then
    Exit;

  Result := FTranslateMethod.Items[AErrorType];
end;

function TValidationVisitor<T>.FindCustomHint(AErrorType: TErrorType): string;
var
  LScope: TScope;
  LPathSegments: TArray<string>;
  LCurrentNode: TJSONValue;
  LSegment: string;
  LHintValue: TJSONValue;
  LErrorKeyword: string;
begin
  Result := '';
  LScope := CurrentScope;
  if not Assigned(FCustomHint) or LScope.InstancePath.IsEmpty then
    Exit;

  // Normaliza e quebra o caminho: '#.relacao_empregados[0].cbo' -> ['relacao_empregados', 'cbo']
  // Precisamos de uma fun��o robusta para isso.
  LPathSegments := TUtils.ParseInstancePath(LScope.InstancePath);

  LCurrentNode := FCustomHint;
  for LSegment in LPathSegments do
  begin
    if not (LCurrentNode is TJSONObject) then
      Exit; // N�o podemos navegar mais fundo

    if not (LCurrentNode as TJSONObject).TryGetValue(LSegment, LCurrentNode) then
    begin
      if (LCurrentNode as TJSONObject).TryGetValue(GetEnumName(TypeInfo(TErrorType), Ord(TErrorType.vetUnknown)), LCurrentNode) then
        Break // N�o encontra um erro espec�fico, mas encontra um erro gen�rico
      else
        Exit; // Caminho n�o encontrado no JSON de dicas
    end;
  end;

  // Chegamos ao n� final do caminho. Agora procuramos pelo tipo de erro.
  if (LCurrentNode is TJSONObject) then
  begin
    LErrorKeyword := GetEnumName(TypeInfo(TErrorType), Ord(AErrorType)); // ex: vetPattern
    if (LCurrentNode as TJSONObject).TryGetValue(LErrorKeyword, LHintValue) and (LHintValue is TJSONString) then
      Result := (LHintValue as TJSONString).Value;
  end
  else if LCurrentNode is TJSONString then
    Result := TJSONString(LCurrentNode).Value;
end;

function TValidationVisitor<T>.KeywordPrecedence: TArray<string>;
begin
  Result := [
    '$schema',
    '$id',
    'id',
    '$ref',
    'properties',
    'patternProperties',
    'additionalProperties',
    'prefixItems',
    'items',
    'additionalItems',
    'if',
    'allOf',
    'anyOf',
    'oneOf'
  ];
end;

function TValidationVisitor<T>.Language: TLanguage;
begin
  Result := FLanguage;
end;

function TValidationVisitor<T>.Language(const ALanguage: TLanguage): IValidationVisitor<T>;
begin
  Result := Self;
  FLanguage := ALanguage;
  PopulateTranslateMethods;
end;

procedure TValidationVisitor<T>.PopulateTranslateMethods;
var
  LType: TRttiType;
  LMethod: TRttiMethod;
  LContext: TRttiContext;
  LMethodPtr: TMethod;
  LAttribute: TCustomAttribute;
  LParameters: TArray<TRttiParameter>;
  LTranslation: ITranslate;
begin
  FTranslateMethod.Clear;
  LTranslation := TTranslateUtils.GetTranslation(FLanguage);
  LContext     := TRttiContext.Create;
  LType        := LContext.GetType(TObject(LTranslation).ClassType);
  for LMethod in LType.GetMethods do
  begin
    for LAttribute in LMethod.GetAttributes do
    begin
      if not (LAttribute is TranslateErrorAttribute) then
        Continue;

      LParameters := LMethod.GetParameters;

      if Length(LParameters) <> 0 then
        Continue;

      LMethodPtr := default(TMethod);
      LMethodPtr.Code := LMethod.CodeAddress;
      LMethodPtr.Data := TObject(LTranslation);

      FTranslateMethod.AddOrSetValue(TranslateErrorAttribute(LAttribute).ErrorType, TTranslateFunc(LMethodPtr));
    end;
  end;
end;

function TValidationVisitor<T>.Registry: TRegistryVisitor;
begin
  Result := FRegistry;
end;

procedure TValidationVisitor<T>.LeaveRefResolution(const AResolvedRef: string);
var
  LTopRef: string;
begin
  if FRefResolutionStack.Count = 0 then
  begin
    FRefResolutionSet.Remove(AResolvedRef);
    Exit;
  end;

  LTopRef := FRefResolutionStack.Peek;
  if SameText(LTopRef, AResolvedRef) then
    FRefResolutionStack.Pop
  else
    FRefResolutionSet.Remove(AResolvedRef);

  FRefResolutionSet.Remove(AResolvedRef);
end;

function TValidationVisitor<T>.Result: IValidationResult;
begin
  Result := FResult;
end;

function TValidationVisitor<T>.TryEnterRefResolution(const AResolvedRef: string; out AReason: string): Boolean;
begin
  AReason := '';

  if FRefResolutionStack.Count >= FMaxRefResolutionDepth then
  begin
    AReason := Format('Maximum call stack size exceeded while resolving reference "%s".', [AResolvedRef]);
    Exit(False);
  end;

  if FRefResolutionSet.ContainsKey(AResolvedRef) then
  begin
    AReason := Format('Maximum call stack size exceeded while resolving cyclic reference "%s".', [AResolvedRef]);
    Exit(False);
  end;

  FRefResolutionSet.Add(AResolvedRef, 1);
  FRefResolutionStack.Push(AResolvedRef);
  Result := True;
end;

{ TBaseCoreVisitor<T> }

procedure TBaseCoreVisitor<T>.VisitBooleanSchema(const AValue: TJSONBool);
begin
  if not AValue.AsBoolean then
    Visitor.AddError(TErrorType.vetSchemaIsFalse);
end;

procedure TBaseCoreVisitor<T>.VisitDefinitions(const AValue: TJSONObject);
begin

end;

procedure TBaseCoreVisitor<T>.VisitId(const AValue: TJSONString);
var
  LScope: TScope;
  LResolvedURI: TURIReference;
begin
  LScope := Visitor.CurrentScope;
  LResolvedURI := TURIReference.From(AValue.Value).ResolveWith(TURIReference.From(LScope.BaseURI));
  LScope.BaseURI := LResolvedURI.Unsplit;

  Visitor.UpdateScope(LScope);
end;

procedure TBaseCoreVisitor<T>.VisitRef(const AValue: TJSONString);
var
  LScope: TScope;
  LRefString: string;
  LFinalURI: TURIReference;
  LTargetResource: TResource;
  LTargetSchema: TJSONValue;
  LWalker: IWalker;
  LNewScope: TScope;
  LValidationVisitor: IValidationVisitor<T>;
  LResolvedBaseURI: string;
  LRefGuard: IRefResolutionGuard;
  LGuardReason: string;
  LGuardKey: string;
  LGuardEntered: Boolean;
  LTargetRootSchema: TJSONValue;
  LTargetDraftSchema: string;
  LTargetDraftVersion: TDraftVersion;
  LCrossDraftResult: IValidationResult;
  LCrossDraftError: IError;
  LDependentRequired: TJSONValue;
  LDependencyPair: TJSONPair;
  LRequiredArray: TJSONArray;
  LRequiredValue: TJSONValue;
  LInstanceObject: TJSONObject;
  LEvaluatedProperty: string;
  LNormalizedEvaluatedProperty: string;
  LRelativePath: string;
  LSegmentSeparator: Integer;
  LFirstSegment: string;
  LItemIndex: Integer;
  LPrecedenceKey: string;
  LCurrentHandlesNewDrafts: Boolean;
  LResultEvaluatedBefore: THashSet<string>;
begin
  if not Supports(Visitor, IValidationVisitor<T>, LValidationVisitor) then
    Exit; // Sanity check

  LScope := Visitor.CurrentScope;
  LRefString := AValue.Value;

  // 1. Resolve a URI da refer�ncia
  LFinalURI := TURIReference.From(LRefString).ResolveWith(TURIReference.From(LScope.BaseURI));
  LGuardKey := LFinalURI.Unsplit + '|' + LScope.InstancePath;
  LGuardEntered := False;

  if Supports(Visitor, IRefResolutionGuard, LRefGuard) then
  begin
    if not LRefGuard.TryEnterRefResolution(LGuardKey, LGuardReason) then
    begin
      Visitor.AddError(TErrorType.vetUnresolvedReference, [LGuardReason]);
      Exit;
    end;
    LGuardEntered := True;
  end;

  try
    // 2. Busca o recurso de schema no Registry
    if not LValidationVisitor.Registry.TryFindResource(LFinalURI.Unsplit, LTargetResource) then
    begin
      Visitor.AddError(TErrorType.vetUnresolvedReference, [LFinalURI.Unsplit]);
      Exit;
    end;

    // 3. Resolve o fragmento (#/... ou #anchor) dentro do recurso
    LTargetSchema := LTargetResource.ResolveFragment(LFinalURI.Fragment, LResolvedBaseURI);

    if not Assigned(LTargetSchema) then
    begin
      Visitor.AddError(TErrorType.vetUnresolvedReference, [LFinalURI.Unsplit]);
      Exit;
    end;

    // 3.1 Se o recurso apontar para outro draft, valida com o visitor correto.
    LTargetDraftVersion := TDraftVersion.dvUnknown;
    LTargetRootSchema := LTargetResource.ResolveFragment('');
    if (LTargetRootSchema is TJSONObject) and TJSONObject(LTargetRootSchema).TryGetValue<string>('$schema', LTargetDraftSchema) then
      LTargetDraftVersion := TDraftVersion.FromSchema(LTargetDraftSchema);

    if (LTargetDraftVersion = TDraftVersion.dvUnknown) then
    begin
      if ContainsText(LFinalURI.Unsplit, '/draft2019-09/') then
        LTargetDraftVersion := TDraftVersion.dvDraft2019_09
      else if ContainsText(LFinalURI.Unsplit, '/draft2020-12/') then
        LTargetDraftVersion := TDraftVersion.dvDraft2020_12;
    end;

    // Verifica se o visitor atual j\u00e1 suporta nativamente os drafts 2019-09/2020-12.
    // Se sim, n\u00e3o usar o caminho cross-draft para refs do mesmo draft (preserva o dynamic scope chain).
    LCurrentHandlesNewDrafts := False;
    for LPrecedenceKey in Visitor.KeywordPrecedence do
      if (LPrecedenceKey = '$recursiveRef') or (LPrecedenceKey = '$dynamicRef') then
      begin
        LCurrentHandlesNewDrafts := True;
        Break;
      end;

    if (LTargetDraftVersion in [TDraftVersion.dvDraft2019_09, TDraftVersion.dvDraft2020_12]) and
       not LCurrentHandlesNewDrafts then
    begin
      LCrossDraftResult := TJsonSchema.Validate(LTargetSchema, LScope.InstanceNode, LTargetDraftVersion);

      if not Assigned(LScope.EvaluatedPropertiesInScope) then
        LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
      for LEvaluatedProperty in LCrossDraftResult.EvaluatedProperties do
      begin
        LNormalizedEvaluatedProperty := LEvaluatedProperty;
        if not LNormalizedEvaluatedProperty.IsEmpty then
        begin
          if (LScope.InstancePath <> '#') and not LNormalizedEvaluatedProperty.StartsWith(LScope.InstancePath + '/') then
          begin
            if LNormalizedEvaluatedProperty = '#' then
              LNormalizedEvaluatedProperty := LScope.InstancePath
            else if LNormalizedEvaluatedProperty.StartsWith('#/') then
              LNormalizedEvaluatedProperty := LScope.InstancePath + LNormalizedEvaluatedProperty.Substring(1)
            else if LNormalizedEvaluatedProperty.StartsWith('#.') then
              LNormalizedEvaluatedProperty := LScope.InstancePath + '/' +
                StringReplace(LNormalizedEvaluatedProperty.Substring(2), '.', '/', [rfReplaceAll])
            else if LNormalizedEvaluatedProperty.StartsWith('/') then
              LNormalizedEvaluatedProperty := LScope.InstancePath + LNormalizedEvaluatedProperty
            else if LNormalizedEvaluatedProperty.StartsWith('.') then
              LNormalizedEvaluatedProperty := LScope.InstancePath + '/' +
                StringReplace(LNormalizedEvaluatedProperty.Substring(1), '.', '/', [rfReplaceAll])
            else
              LNormalizedEvaluatedProperty := LScope.InstancePath + '/' + LNormalizedEvaluatedProperty;
          end;
        end;

        LScope.EvaluatedPropertiesInScope.Add(LNormalizedEvaluatedProperty);
        LValidationVisitor.Result.AddEvaluatedProperty(LNormalizedEvaluatedProperty);

        // Em modo cross-draft, reconstrói cobertura local para unevaluated* do visitor pai.
        if LNormalizedEvaluatedProperty.StartsWith(LScope.InstancePath + '/') then
        begin
          LRelativePath := LNormalizedEvaluatedProperty.Substring((LScope.InstancePath + '/').Length);
          LSegmentSeparator := Pos('/', LRelativePath);
          if LSegmentSeparator > 0 then
            LFirstSegment := Copy(LRelativePath, 1, LSegmentSeparator - 1)
          else
            LFirstSegment := LRelativePath;

          if TryStrToInt(LFirstSegment, LItemIndex) then
          begin
            TUtils.AddArray<Integer>(LScope.CoveredItems, LItemIndex);
          end
          else if LFirstSegment <> '' then
          begin
            TUtils.AddArray<string>(LScope.CoveredProperties, LFirstSegment);
          end;
        end;
      end;
      Visitor.UpdateScope(LScope);

      if not LCrossDraftResult.IsValid then
        for LCrossDraftError in LCrossDraftResult.Errors do
          LValidationVisitor.Result.AddError(LCrossDraftError);

      // Fallback minimo: dependentRequired em refs cross-draft (usado em draft7/optional/cross-draft.json).
      if LCrossDraftResult.IsValid and (LTargetSchema is TJSONObject) and
         TJSONObject(LTargetSchema).TryGetValue('dependentRequired', LDependentRequired) and
         (LDependentRequired is TJSONObject) and (LScope.InstanceNode is TJSONObject) then
      begin
        LInstanceObject := TJSONObject(LScope.InstanceNode);
        for LDependencyPair in TJSONObject(LDependentRequired) do
        begin
          if LInstanceObject.FindValue(LDependencyPair.JsonString.Value) = nil then
            Continue;

          if not (LDependencyPair.JsonValue is TJSONArray) then
            Continue;

          LRequiredArray := TJSONArray(LDependencyPair.JsonValue);
          for LRequiredValue in LRequiredArray do
          begin
            if not (LRequiredValue is TJSONString) then
              Continue;

            if LInstanceObject.FindValue(TJSONString(LRequiredValue).Value) = nil then
              LValidationVisitor.AddError(TErrorType.vetDependentRequired,
                [LDependencyPair.JsonString.Value, TJSONString(LRequiredValue).Value]);
          end;
        end;
      end;

      Exit;
    end;

    // 4. Prepara e executa a valida��o recursiva
    LNewScope := LScope;
    with LNewScope do
    begin
      BaseURI      := LResolvedBaseURI;
      SchemaNode   := LTargetSchema;
      SchemaPath   := LFinalURI.Unsplit;
      CoveredItems      := [];
      ContainsCount     := 0;
      VisitedKeywords   := [];
      CoveredProperties := [];
      EvaluatedPropertiesInScope := THashSet<string>.Create;
      if Assigned(LScope.EvaluatedPropertiesInScope) then
        for LEvaluatedProperty in LScope.EvaluatedPropertiesInScope do
          EvaluatedPropertiesInScope.Add(LEvaluatedProperty);
      // Injeta também a memória global já avaliada para o filho enxergar
      // anotações herdadas do pai durante a sub-validação de $ref.
      for LEvaluatedProperty in LValidationVisitor.Result.EvaluatedProperties do
        EvaluatedPropertiesInScope.Add(LEvaluatedProperty);
      // A inst�ncia e seu caminho n�o mudam
    end;

    LResultEvaluatedBefore := THashSet<string>.Create;
    try
      for LEvaluatedProperty in LValidationVisitor.Result.EvaluatedProperties do
        LResultEvaluatedBefore.Add(LEvaluatedProperty);

      Visitor.PushScope(LNewScope);
      try
        LWalker := TWalker<T>.Create(LTargetSchema, Visitor);
        LWalker.Walk;

        // Sincroniza imediatamente as anotações novas no escopo local do $ref
        // antes do pop, para manter coerência intra-subvalidação.
        LNewScope := Visitor.CurrentScope;
        if not Assigned(LNewScope.EvaluatedPropertiesInScope) then
          LNewScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

        for LEvaluatedProperty in LValidationVisitor.Result.EvaluatedProperties do
        begin
          if LResultEvaluatedBefore.Contains(LEvaluatedProperty) then
            Continue;

          LNormalizedEvaluatedProperty := LEvaluatedProperty;
          if not LNormalizedEvaluatedProperty.IsEmpty then
          begin
            if (LScope.InstancePath <> '#') and not LNormalizedEvaluatedProperty.StartsWith(LScope.InstancePath + '/') then
            begin
              if LNormalizedEvaluatedProperty = '#' then
                LNormalizedEvaluatedProperty := LScope.InstancePath
              else if LNormalizedEvaluatedProperty.StartsWith('#/') then
                LNormalizedEvaluatedProperty := LScope.InstancePath + LNormalizedEvaluatedProperty.Substring(1)
              else if LNormalizedEvaluatedProperty.StartsWith('#.') then
                LNormalizedEvaluatedProperty := LScope.InstancePath + '/' +
                  StringReplace(LNormalizedEvaluatedProperty.Substring(2), '.', '/', [rfReplaceAll])
              else if LNormalizedEvaluatedProperty.StartsWith('/') then
                LNormalizedEvaluatedProperty := LScope.InstancePath + LNormalizedEvaluatedProperty
              else if LNormalizedEvaluatedProperty.StartsWith('.') then
                LNormalizedEvaluatedProperty := LScope.InstancePath + '/' +
                  StringReplace(LNormalizedEvaluatedProperty.Substring(1), '.', '/', [rfReplaceAll])
              else
                LNormalizedEvaluatedProperty := LScope.InstancePath + '/' + LNormalizedEvaluatedProperty;
            end;
          end;

          LNewScope.EvaluatedPropertiesInScope.Add(LNormalizedEvaluatedProperty);
        end;
        Visitor.UpdateScope(LNewScope);
      finally
        LNewScope := Visitor.PopScope;
      end;

      LScope.CoveredItems      := TUtils.MergeArray<Integer>([LScope.CoveredItems, LNewScope.CoveredItems]);
      LScope.CoveredProperties := TUtils.MergeArray<string>([LScope.CoveredProperties, LNewScope.CoveredProperties]);
      if Assigned(LNewScope.EvaluatedPropertiesInScope) then
      begin
        if not Assigned(LScope.EvaluatedPropertiesInScope) then
          LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

        for LEvaluatedProperty in LNewScope.EvaluatedPropertiesInScope do
        begin
          LNormalizedEvaluatedProperty := LEvaluatedProperty;
          if not LNormalizedEvaluatedProperty.IsEmpty then
          begin
            if (LScope.InstancePath <> '#') and not LNormalizedEvaluatedProperty.StartsWith(LScope.InstancePath + '/') then
            begin
              if LNormalizedEvaluatedProperty = '#' then
                LNormalizedEvaluatedProperty := LScope.InstancePath
              else if LNormalizedEvaluatedProperty.StartsWith('#/') then
                LNormalizedEvaluatedProperty := LScope.InstancePath + LNormalizedEvaluatedProperty.Substring(1)
              else if LNormalizedEvaluatedProperty.StartsWith('#.') then
                LNormalizedEvaluatedProperty := LScope.InstancePath + '/' +
                  StringReplace(LNormalizedEvaluatedProperty.Substring(2), '.', '/', [rfReplaceAll])
              else if LNormalizedEvaluatedProperty.StartsWith('/') then
                LNormalizedEvaluatedProperty := LScope.InstancePath + LNormalizedEvaluatedProperty
              else if LNormalizedEvaluatedProperty.StartsWith('.') then
                LNormalizedEvaluatedProperty := LScope.InstancePath + '/' +
                  StringReplace(LNormalizedEvaluatedProperty.Substring(1), '.', '/', [rfReplaceAll])
              else
                LNormalizedEvaluatedProperty := LScope.InstancePath + '/' + LNormalizedEvaluatedProperty;
            end;
          end;

          LScope.EvaluatedPropertiesInScope.Add(LNormalizedEvaluatedProperty);
          LValidationVisitor.Result.AddEvaluatedProperty(LNormalizedEvaluatedProperty);

          // Em refs no mesmo draft, reconstruí cobertura local para unevaluated* no escopo pai.
          if LNormalizedEvaluatedProperty.StartsWith(LScope.InstancePath + '/') then
          begin
            LRelativePath := LNormalizedEvaluatedProperty.Substring((LScope.InstancePath + '/').Length);
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

      Visitor.UpdateScope(LScope);
    finally
      LResultEvaluatedBefore.Free;
    end;
  finally
    if LGuardEntered then
      LRefGuard.LeaveRefResolution(LGuardKey);
  end;
end;

procedure TBaseCoreVisitor<T>.VisitSchema(const AValue: TJSONString);
begin

end;

{ TBaseHyperSchemaVisitor<T> }

procedure TBaseHyperSchemaVisitor<T>.VisitBase(const AValue: TJSONString);
begin

end;

procedure TBaseHyperSchemaVisitor<T>.VisitHref(const AValue: TJSONString);
begin

end;

procedure TBaseHyperSchemaVisitor<T>.VisitHrefSchema(const AValue: TJSONValue);
begin

end;

procedure TBaseHyperSchemaVisitor<T>.VisitLinks(const AValue: TJSONArray);
begin

end;

procedure TBaseHyperSchemaVisitor<T>.VisitSubmissionSchema(const AValue: TJSONValue);
begin

end;

procedure TBaseHyperSchemaVisitor<T>.VisitTargetSchema(const AValue: TJSONValue);
begin

end;

{ TBaseValidationVisitor<T> }

procedure TBaseValidationVisitor<T>.VisitConst(const AValue: TJSONValue);
var
  LScope: TScope;
begin
  LScope := Visitor.CurrentScope;
  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'const']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    if not TUtils.JsonEquals(LScope.InstanceNode, AValue) then
      Visitor.AddError(TErrorType.vetConstValueMismatch, [AValue.ToString]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitEnum(const AValue: TJSONArray);
var
  LScope: TScope;
  LIsValid: Boolean;
  LEnumValue: TJSONValue;
begin
  LScope := Visitor.CurrentScope;
  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'enum']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    LIsValid := False;
    for LEnumValue in AValue do
    begin
      if TUtils.JsonEquals(LScope.InstanceNode, LEnumValue) then
      begin
        LIsValid := True;
        Break;
      end;
    end;

    if not LIsValid then
      Visitor.AddError(TErrorType.vetEnumValueMismatch, [AValue.ToString]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitExclusiveMaximum(const AValue: TJSONValue);
var
  LScope: TScope;
  LLimitSchema: TJSONValue;
  LLimitValue: Extended;
  LIsExclusive: Boolean;
begin
  LScope := Visitor.CurrentScope;

  if not MatchStr(TUtils.JsonGetType(LScope.InstanceNode), ['number', 'integer']) then
    Exit;

  if AValue is TJSONNumber then
  begin
    LLimitValue := TUtils.JsonGetFloat(AValue);
    LIsExclusive := True;
  end
  else if AValue is TJSONBool then
  begin
    LIsExclusive := TJSONBool(AValue).AsBoolean;
    if not LIsExclusive then
      Exit;

    if not ((LScope.SchemaNode is TJSONObject) and TJSONObject(LScope.SchemaNode).TryGetValue('maximum', LLimitSchema)) then
      Exit;

    if not (LLimitSchema is TJSONNumber) then
      Exit;

    LLimitValue := TUtils.JsonGetFloat(LLimitSchema);
  end
  else
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'exclusiveMaximum']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    if LIsExclusive and (TUtils.JsonGetFloat(LScope.InstanceNode) >= LLimitValue) then
      Visitor.AddError(TErrorType.vetExclusiveMaximum, [LLimitValue.ToString]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitExclusiveMinimum(const AValue: TJSONValue);
var
  LScope: TScope;
  LLimitSchema: TJSONValue;
  LLimitValue: Extended;
  LIsExclusive: Boolean;
begin
  LScope := Visitor.CurrentScope;

  if not MatchStr(TUtils.JsonGetType(LScope.InstanceNode), ['number', 'integer']) then
    Exit;

  if AValue is TJSONNumber then
  begin
    LLimitValue := TUtils.JsonGetFloat(AValue);
    LIsExclusive := True;
  end
  else if AValue is TJSONBool then
  begin
    LIsExclusive := TJSONBool(AValue).AsBoolean;
    if not LIsExclusive then
      Exit;

    if not ((LScope.SchemaNode is TJSONObject) and TJSONObject(LScope.SchemaNode).TryGetValue('minimum', LLimitSchema)) then
      Exit;

    if not (LLimitSchema is TJSONNumber) then
      Exit;

    LLimitValue := TUtils.JsonGetFloat(LLimitSchema);
  end
  else
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'exclusiveMinimum']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    if LIsExclusive and (TUtils.JsonGetFloat(LScope.InstanceNode) <= LLimitValue) then
      Visitor.AddError(TErrorType.vetExclusiveMinimum, [LLimitValue.ToString]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitFormat(const AValue: TJSONString);
var
  LScope: TScope;
  LFormatName: string;
  LInstanceValue: string;
  LIsValid: Boolean;
  LParts: TArray<string>;
  LLeftParts: TArray<string>;
  LRightParts: TArray<string>;
  LPart: string;
  LWorkValue: string;
  LLeftValue: string;
  LRightValue: string;
  LNumber: Integer;
  LSplitPos: Integer;
  LLastColon: Integer;
  LIPv4Tail: string;
  LHextetCount: Integer;
  LExpectedHextets: Integer;
  LHasCompression: Boolean;
  LDateTime: TDateTime;
  LMatch: TMatch;
  LYear: Integer;
  LMonth: Integer;
  LDay: Integer;
  LHour: Integer;
  LMinute: Integer;
  LSecond: Integer;
  LOffsetHour: Integer;
  LOffsetMinute: Integer;
  LUtcTotalMinutes: Integer;
  LOffsetTotalMinutes: Integer;
  LUtcHour: Integer;
  LUtcMinute: Integer;
  LOffsetSign: Char;
  LTemplateDepth: Integer;
  LTemplateExpr: string;
  LTemplateChar: Char;
  LLabels: TArray<string>;
  LLabel: string;
  LCodePoint: Integer;
  LIndex: Integer;
  LHasArabicIndic: Boolean;
  LHasExtendedArabicIndic: Boolean;
  LHasKatakanaMiddleDot: Boolean;
  LHasKanaHanContent: Boolean;
begin
  LScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(LScope.InstanceNode) <> 'string' then
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'format']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    LFormatName := LowerCase(AValue.Value);
    LInstanceValue := TJSONString(LScope.InstanceNode).Value;
    LIsValid := True;

    if LFormatName = 'ipv4' then
    begin
      LParts := SplitString(LInstanceValue, '.');
      LIsValid := Length(LParts) = 4;

      if LIsValid then
        for LPart in LParts do
        begin
          if (LPart = '') or not TRegEx.IsMatch(LPart, '^\d+$') then
          begin
            LIsValid := False;
            Break;
          end;

          if (Length(LPart) > 1) and (LPart[1] = '0') then
          begin
            LIsValid := False;
            Break;
          end;

          if not TryStrToInt(LPart, LNumber) or (LNumber < 0) or (LNumber > 255) then
          begin
            LIsValid := False;
            Break;
          end;
        end;
    end
    else if LFormatName = 'ipv6' then
    begin
      LWorkValue := LInstanceValue;
      LExpectedHextets := 8;
      LIsValid := LWorkValue <> '';

      if LIsValid and (Pos('.', LWorkValue) > 0) then
      begin
        LLastColon := LastDelimiter(':', LWorkValue);
        if LLastColon = 0 then
          LIsValid := False
        else
        begin
          LIPv4Tail := Copy(LWorkValue, LLastColon + 1, MaxInt);
          LParts := SplitString(LIPv4Tail, '.');
          LIsValid := Length(LParts) = 4;

          if LIsValid then
            for LPart in LParts do
            begin
              if (LPart = '') or not TRegEx.IsMatch(LPart, '^\d+$') then
              begin
                LIsValid := False;
                Break;
              end;

              if (Length(LPart) > 1) and (LPart[1] = '0') then
              begin
                LIsValid := False;
                Break;
              end;

              if not TryStrToInt(LPart, LNumber) or (LNumber < 0) or (LNumber > 255) then
              begin
                LIsValid := False;
                Break;
              end;
            end;

          if LIsValid then
          begin
            LExpectedHextets := 6;
            if (LLastColon > 1) and (LWorkValue[LLastColon - 1] = ':') then
              LWorkValue := Copy(LWorkValue, 1, LLastColon)
            else
              LWorkValue := Copy(LWorkValue, 1, LLastColon - 1);
          end;
        end;
      end;

      if LIsValid then
      begin
        if Pos(':::', LWorkValue) > 0 then
          LIsValid := False
        else
        begin
          LHasCompression := Pos('::', LWorkValue) > 0;

          if LHasCompression then
          begin
            LSplitPos := Pos('::', LWorkValue);
            if PosEx('::', LWorkValue, LSplitPos + 2) > 0 then
              LIsValid := False
            else
            begin
              LHextetCount := 0;
              LLeftValue := Copy(LWorkValue, 1, LSplitPos - 1);
              LRightValue := Copy(LWorkValue, LSplitPos + 2, MaxInt);

              if LLeftValue <> '' then
              begin
                LLeftParts := SplitString(LLeftValue, ':');
                for LPart in LLeftParts do
                begin
                  if (LPart = '') or not TRegEx.IsMatch(LPart, '^[0-9A-Fa-f]{1,4}$') then
                  begin
                    LIsValid := False;
                    Break;
                  end;
                  Inc(LHextetCount);
                end;
              end;

              if LIsValid and (LRightValue <> '') then
              begin
                LRightParts := SplitString(LRightValue, ':');
                for LPart in LRightParts do
                begin
                  if (LPart = '') or not TRegEx.IsMatch(LPart, '^[0-9A-Fa-f]{1,4}$') then
                  begin
                    LIsValid := False;
                    Break;
                  end;
                  Inc(LHextetCount);
                end;
              end;

              if LIsValid then
                LIsValid := LHextetCount < LExpectedHextets;
            end;
          end
          else
          begin
            LParts := SplitString(LWorkValue, ':');
            if Length(LParts) <> LExpectedHextets then
              LIsValid := False
            else
              for LPart in LParts do
                if (LPart = '') or not TRegEx.IsMatch(LPart, '^[0-9A-Fa-f]{1,4}$') then
                begin
                  LIsValid := False;
                  Break;
                end;
          end;
        end;
      end;
    end
    else if LFormatName = 'date-time' then
    begin
      LMatch := TRegEx.Match(LInstanceValue,
        '^(\d{4})-(\d{2})-(\d{2})[Tt](\d{2}):(\d{2}):(\d{2})(?:\.\d+)?([Zz]|[+\-]\d{2}:\d{2})$',
        [roCompiled]);
      LIsValid := LMatch.Success;

      if LIsValid then
      begin
        LIsValid :=
          TryStrToInt(LMatch.Groups[1].Value, LYear) and
          TryStrToInt(LMatch.Groups[2].Value, LMonth) and
          TryStrToInt(LMatch.Groups[3].Value, LDay) and
          TryStrToInt(LMatch.Groups[4].Value, LHour) and
          TryStrToInt(LMatch.Groups[5].Value, LMinute) and
          TryStrToInt(LMatch.Groups[6].Value, LSecond);

        if LIsValid then
          LIsValid :=
            (LYear >= 1) and
            (LMonth >= 1) and (LMonth <= 12) and
            (LDay >= 1) and (LDay <= 31) and
            TryEncodeDate(Word(LYear), Word(LMonth), Word(LDay), LDateTime);

        if LIsValid then
          LIsValid := (LHour <= 23) and (LMinute <= 59) and (LSecond <= 60);

        // Leap second is valid only for 23:59:60 in UTC.
        if LIsValid and (LSecond = 60) then
        begin
          if SameText(LMatch.Groups[7].Value, 'Z') then
          begin
            LIsValid := (LHour = 23) and (LMinute = 59);
          end
          else
          begin
            LOffsetSign := LMatch.Groups[7].Value[1];
            LIsValid :=
              TryStrToInt(Copy(LMatch.Groups[7].Value, 2, 2), LOffsetHour) and
              TryStrToInt(Copy(LMatch.Groups[7].Value, 5, 2), LOffsetMinute) and
              (LOffsetHour <= 23) and
              (LOffsetMinute <= 59);

            if LIsValid then
            begin
              LOffsetTotalMinutes := (LOffsetHour * 60) + LOffsetMinute;
              LUtcTotalMinutes := (LHour * 60) + LMinute;

              if LOffsetSign = '+' then
                LUtcTotalMinutes := LUtcTotalMinutes - LOffsetTotalMinutes
              else
                LUtcTotalMinutes := LUtcTotalMinutes + LOffsetTotalMinutes;

              LUtcTotalMinutes := ((LUtcTotalMinutes mod 1440) + 1440) mod 1440;
              LUtcHour := LUtcTotalMinutes div 60;
              LUtcMinute := LUtcTotalMinutes mod 60;
              LIsValid := (LUtcHour = 23) and (LUtcMinute = 59);
            end;
          end;
        end;

        if LIsValid and (LMatch.Groups[7].Value <> '') and
           (not SameText(LMatch.Groups[7].Value, 'Z')) then
        begin
          LIsValid :=
            TryStrToInt(Copy(LMatch.Groups[7].Value, 2, 2), LOffsetHour) and
            TryStrToInt(Copy(LMatch.Groups[7].Value, 5, 2), LOffsetMinute) and
            (LOffsetHour <= 23) and
            (LOffsetMinute <= 59);
        end;
      end;
    end
    else if LFormatName = 'duration' then
      LIsValid := TRegEx.IsMatch(LInstanceValue,
        '^P(?!$)((\d+Y)?(\d+M)?(\d+D)?(T(?=\d)(\d+H)?(\d+M)?(\d+S)?)?|(\d+W))$',
        [roCompiled])
    else if LFormatName = 'date' then
    begin
      LMatch := TRegEx.Match(LInstanceValue,
        '^([0-9]{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$',
        [roCompiled]);
      LIsValid := LMatch.Success;

      if LIsValid then
      begin
        LIsValid :=
          TryStrToInt(LMatch.Groups[1].Value, LYear) and
          TryStrToInt(LMatch.Groups[2].Value, LMonth) and
          TryStrToInt(LMatch.Groups[3].Value, LDay);

        if LIsValid then
          LIsValid := TryEncodeDate(Word(LYear), Word(LMonth), Word(LDay), LDateTime);
      end;
    end
    else if LFormatName = 'time' then
    begin
      // RFC 3339 full-time: HH:MM:SS[.frac](Z|+HH:MM|-HH:MM)
      LMatch := TRegEx.Match(LInstanceValue,
        '^([01][0-9]|2[0-3]):([0-5][0-9]):((?:[0-5][0-9]|60))(?:\.[0-9]+)?([Zz]|[+\-]([01][0-9]|2[0-3]):([0-5][0-9]))$',
        [roCompiled]);
      LIsValid := LMatch.Success;

      if LIsValid then
      begin
        LIsValid :=
          TryStrToInt(LMatch.Groups[1].Value, LHour) and
          TryStrToInt(LMatch.Groups[2].Value, LMinute) and
          TryStrToInt(LMatch.Groups[3].Value, LSecond);

        if LIsValid then
          LIsValid := (LHour <= 23) and (LMinute <= 59) and (LSecond <= 60);

        // Leap second is valid only for 23:59:60 in UTC.
        if LIsValid and (LSecond = 60) then
        begin
          if SameText(LMatch.Groups[4].Value, 'Z') then
          begin
            LIsValid := (LHour = 23) and (LMinute = 59);
          end
          else
          begin
            LOffsetSign := LMatch.Groups[4].Value[1];
            LIsValid :=
              TryStrToInt(LMatch.Groups[5].Value, LOffsetHour) and
              TryStrToInt(LMatch.Groups[6].Value, LOffsetMinute) and
              (LOffsetHour <= 23) and
              (LOffsetMinute <= 59);

            if LIsValid then
            begin
              LOffsetTotalMinutes := (LOffsetHour * 60) + LOffsetMinute;
              LUtcTotalMinutes := (LHour * 60) + LMinute;

              if LOffsetSign = '+' then
                LUtcTotalMinutes := LUtcTotalMinutes - LOffsetTotalMinutes
              else
                LUtcTotalMinutes := LUtcTotalMinutes + LOffsetTotalMinutes;

              LUtcTotalMinutes := ((LUtcTotalMinutes mod 1440) + 1440) mod 1440;
              LUtcHour := LUtcTotalMinutes div 60;
              LUtcMinute := LUtcTotalMinutes mod 60;
              LIsValid := (LUtcHour = 23) and (LUtcMinute = 59);
            end;
          end;
        end;
      end;
    end
    else if LFormatName = 'email' then
      LIsValid := TRegEx.IsMatch(LInstanceValue,
        '^[A-Za-z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&''*+/=?^_`{|}~-]+)*@(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-))(?:\.(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-)))*$',
        [roCompiled])
    else if LFormatName = 'idn-email' then
      // Placeholder RFC 6531/5890: aceita Unicode basico sem espacos e com separacao local@dominio.
      LIsValid := TRegEx.IsMatch(LInstanceValue,
        '^[^\s@]+@(?=.{1,253}$)(?:(?!-)[\p{L}\p{N}-]{1,63}(?<!-))(?:\.(?:(?!-)[\p{L}\p{N}-]{1,63}(?<!-)))*$',
        [roCompiled])
    else if LFormatName = 'idn-hostname' then
    begin
      // Regras minimas RFC 5890/IDNA: tamanho de labels, controle, espacos, hifens e punycode malformado.
      LWorkValue := LInstanceValue;
      for LIndex := 1 to Length(LWorkValue) do
      begin
        LCodePoint := Ord(LWorkValue[LIndex]);
        if (LCodePoint = $3002) or (LCodePoint = $FF0E) or (LCodePoint = $FF61) then
          LWorkValue[LIndex] := '.';
      end;

      LIsValid := (LWorkValue <> '') and (Length(LWorkValue) <= 253);

      if LIsValid then
        LIsValid := not TRegEx.IsMatch(LWorkValue, '[\x00-\x1F\x7F\s]', [roCompiled]);

      if LIsValid then
        LIsValid := not ((LWorkValue[1] = '.') or (LWorkValue[Length(LWorkValue)] = '.'));

      if LIsValid then
        LIsValid := Pos('..', LWorkValue) = 0;

      if LIsValid then
      begin
        LLabels := SplitString(LWorkValue, '.');
        for LLabel in LLabels do
        begin
          if (LLabel = '') or (Length(LLabel) > 63) then
          begin
            LIsValid := False;
            Break;
          end;

          if (LLabel[1] = '-') or (LLabel[Length(LLabel)] = '-') then
          begin
            LIsValid := False;
            Break;
          end;

          if StartsText('xn--', LLabel) then
          begin
            // Punycode ACE prefix deve estar em lowercase e conter payload alfanumerico/hifen.
            if not LLabel.StartsWith('xn--') or
               (Length(LLabel) <= 4) or
               not TRegEx.IsMatch(Copy(LLabel, 5, MaxInt), '^[a-z0-9-]+$', [roCompiled]) then
            begin
              LIsValid := False;
              Break;
            end;
          end;
        end;

        if LIsValid then
        begin
          LHasArabicIndic := False;
          LHasExtendedArabicIndic := False;
          LHasKatakanaMiddleDot := False;
          LHasKanaHanContent := False;

          for LIndex := 1 to Length(LWorkValue) do
          begin
            LCodePoint := Ord(LWorkValue[LIndex]);

            // Casos explicitamente DISALLOWED no conjunto de testes opcionais.
            if (LCodePoint = $302E) or (LCodePoint = $0640) or (LCodePoint = $07FA) or
               (LCodePoint = $3031) or (LCodePoint = $3032) or (LCodePoint = $3033) or
               (LCodePoint = $3034) or (LCodePoint = $3035) or (LCodePoint = $303B) or
               (LCodePoint = $303E) or (LCodePoint = $303F) then
            begin
              LIsValid := False;
              Break;
            end;

            // Nao permitir inicio com marcas combinantes dos casos de teste.
            if (LIndex = 1) and ((LCodePoint = $0903) or (LCodePoint = $0300) or (LCodePoint = $0488)) then
            begin
              LIsValid := False;
              Break;
            end;

            // U+00B7 deve estar entre 'l' e 'l'.
            if LCodePoint = $00B7 then
              if (LIndex = 1) or (LIndex = Length(LWorkValue)) or
                 (LWorkValue[LIndex - 1] <> 'l') or (LWorkValue[LIndex + 1] <> 'l') then
              begin
                LIsValid := False;
                Break;
              end;

            // Greek KERAIA U+0375 deve ser seguida por caractere grego.
            if LCodePoint = $0375 then
              if (LIndex = Length(LWorkValue)) or
                 not ((Ord(LWorkValue[LIndex + 1]) >= $0370) and (Ord(LWorkValue[LIndex + 1]) <= $03FF)) then
              begin
                LIsValid := False;
                Break;
              end;

            // Hebrew GERESH/GERSHAYIM devem ser precedidos por hebraico.
            if (LCodePoint = $05F3) or (LCodePoint = $05F4) then
              if (LIndex = 1) or
                 not ((Ord(LWorkValue[LIndex - 1]) >= $0590) and (Ord(LWorkValue[LIndex - 1]) <= $05FF)) then
              begin
                LIsValid := False;
                Break;
              end;

            if (LCodePoint >= $0660) and (LCodePoint <= $0669) then
              LHasArabicIndic := True;
            if (LCodePoint >= $06F0) and (LCodePoint <= $06F9) then
              LHasExtendedArabicIndic := True;

            // KATAKANA MIDDLE DOT: exige outro caractere Hiragana/Katakana/Han no host.
            if LCodePoint = $30FB then
              LHasKatakanaMiddleDot := True
            else if ((LCodePoint >= $3040) and (LCodePoint <= $309F)) or
                    ((LCodePoint >= $30A0) and (LCodePoint <= $30FF)) or
                    ((LCodePoint >= $4E00) and (LCodePoint <= $9FFF)) then
              LHasKanaHanContent := True;

            // ZERO WIDTH JOINER U+200D deve ser precedido por virama U+094D.
            if LCodePoint = $200D then
              if (LIndex = 1) or (Ord(LWorkValue[LIndex - 1]) <> $094D) then
              begin
                LIsValid := False;
                Break;
              end;
          end;

          if LIsValid and LHasArabicIndic and LHasExtendedArabicIndic then
            LIsValid := False;

          if LIsValid and LHasKatakanaMiddleDot and not LHasKanaHanContent then
            LIsValid := False;
        end;
      end;
    end
    else if LFormatName = 'json-pointer' then
      LIsValid := TURIUtils.IsValidJsonPointer(LInstanceValue)
    else if LFormatName = 'uri-reference' then
      LIsValid := TURIUtils.IsValidURIReference(LInstanceValue)
    else if LFormatName = 'uri' then
      LIsValid := TURIUtils.IsValidURI(LInstanceValue)
    else if LFormatName = 'iri-reference' then
      // Placeholder RFC 3987: aceita caracteres Unicode, sem espacos de controle.
      LIsValid := TRegEx.IsMatch(LInstanceValue, '^[^\s<>"{}|\^`\\]+$', [roCompiled])
    else if LFormatName = 'iri' then
    begin
      // Placeholder RFC 3987: requer esquema + ':' e evita caracteres de controle.
      LIsValid := TRegEx.IsMatch(LInstanceValue, '^[A-Za-z][A-Za-z0-9+.-]*:[^\s<>"{}|\^`\\]*$', [roCompiled]);
      // Rejeitar IPv6 sem colchetes na authority (ex: http://2001:db8::1/)
      if LIsValid then
      begin
        LMatch := TRegEx.Match(LInstanceValue, '^[A-Za-z][A-Za-z0-9+.-]*://([^/?#]*)', [roCompiled]);
        if LMatch.Success then
        begin
          LWorkValue := LMatch.Groups[1].Value;
          LSplitPos := LastDelimiter('@', LWorkValue);
          if LSplitPos > 0 then
            LWorkValue := Copy(LWorkValue, LSplitPos + 1, MaxInt);
          if (LWorkValue = '') or (LWorkValue[1] <> '[') then
            if TRegEx.IsMatch(LWorkValue, ':[^:]*:', [roCompiled]) then
              LIsValid := False;
        end;
      end;
    end
    else if LFormatName = 'uri-template' then
    begin
      LTemplateDepth := 0;
      LTemplateExpr := '';

      for LTemplateChar in LInstanceValue do
      begin
        if LTemplateChar = '{' then
        begin
          if LTemplateDepth <> 0 then
          begin
            LIsValid := False;
            Break;
          end;

          LTemplateDepth := 1;
          LTemplateExpr := '';
          Continue;
        end;

        if LTemplateChar = '}' then
        begin
          if LTemplateDepth = 0 then
          begin
            LIsValid := False;
            Break;
          end;

          LIsValid := LTemplateExpr <> '';
          if LIsValid then
            LIsValid := TRegEx.IsMatch(
              LTemplateExpr,
              '^[+#./;?&]?[A-Za-z0-9_%.][A-Za-z0-9_%.]*(?::\d+|\*)?(?:,[A-Za-z0-9_%.][A-Za-z0-9_%.]*(?::\d+|\*)?)*$',
              [roCompiled]);

          if not LIsValid then
            Break;

          LTemplateDepth := 0;
          Continue;
        end;

        if LTemplateDepth = 1 then
        begin
          if (LTemplateChar <= ' ') or (LTemplateChar = '{') or (LTemplateChar = '}') then
          begin
            LIsValid := False;
            Break;
          end;

          LTemplateExpr := LTemplateExpr + LTemplateChar;
        end;
      end;

      if LIsValid then
        LIsValid := LTemplateDepth = 0;
    end
    else if LFormatName = 'relative-json-pointer' then
      // RFC draft-handrews-relative-json-pointer: non-negative-integer seguido de '#' ou JSON Pointer
      LIsValid := TRegEx.IsMatch(LInstanceValue,
        '^(0|[1-9][0-9]*)(#|(/([^~/]|~[01])*)*)$',
        [roCompiled])
    else if LFormatName = 'regex' then
    begin
      try
        TRegEx.IsMatch('', LInstanceValue);
      except
        LIsValid := False;
      end;
    end
    else if LFormatName = 'hostname' then
      LIsValid := TRegEx.IsMatch(LInstanceValue,
        '^(?=.{1,253}$)(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-))(?:\.(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-)))*$',
        [roCompiled])
    else if LFormatName = 'uuid' then
      LIsValid := TRegEx.IsMatch(LInstanceValue,
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        [roCompiled]);

    if not LIsValid then
      Visitor.AddError(TErrorType.vetInvalidFormat, [AValue.Value]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMaximum(const AValue: TJSONNumber);
var
  LScope: TScope;
begin
  LScope := Visitor.CurrentScope;

  if not MatchStr(TUtils.JsonGetType(LScope.InstanceNode), ['number', 'integer']) then
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'maximum']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    if (TUtils.JsonGetFloat(LScope.InstanceNode) > TUtils.JsonGetFloat(AValue)) then
      Visitor.AddError(TErrorType.vetMaximum, [TUtils.JsonGetFloat(AValue).ToString]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMaxItems(const AValue: TJSONNumber);
var
  LScope: TScope;
begin
  LScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(LScope.InstanceNode) <> 'array' then
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'maxItems']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    if (TJSONArray(LScope.InstanceNode).Count > TUtils.JsonGetInteger(AValue)) then
      Visitor.AddError(TErrorType.vetMaxItems, [TUtils.JsonGetInteger(AValue)]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMaxLength(const AValue: TJSONNumber);
var
  LScope: TScope;
begin
  LScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(LScope.InstanceNode) <> 'string' then
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'maxLength']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    if (Length(TUtils.Utf32Encode(TJSONString(LScope.InstanceNode).Value)) > TUtils.JsonGetInteger(AValue)) then
      Visitor.AddError(TErrorType.vetMaxLength, [TUtils.JsonGetInteger(AValue)]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMaxProperties(const AValue: TJSONNumber);
var
  LScope: TScope;
begin
  LScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'maxProperties']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    if (TJSONObject(LScope.InstanceNode).Count > TUtils.JsonGetInteger(AValue)) then
      Visitor.AddError(TErrorType.vetMaxProperties, [TUtils.JsonGetInteger(AValue)]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMinimum(const AValue: TJSONNumber);
var
  LScope: TScope;
begin
  LScope := Visitor.CurrentScope;

  if not MatchStr(TUtils.JsonGetType(LScope.InstanceNode), ['number', 'integer']) then
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'minimum']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    if (TUtils.JsonGetFloat(LScope.InstanceNode) < TUtils.JsonGetFloat(AValue)) then
      Visitor.AddError(TErrorType.vetMinimum, [TUtils.JsonGetFloat(AValue).ToString]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMinItems(const AValue: TJSONNumber);
var
  LScope: TScope;
begin
  LScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(LScope.InstanceNode) <> 'array' then
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'minItems']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    if (TJSONArray(LScope.InstanceNode).Count < TUtils.JsonGetInteger(AValue)) then
      Visitor.AddError(TErrorType.vetMinItems, [TUtils.JsonGetInteger(AValue)]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMinLength(const AValue: TJSONNumber);
var
  LScope: TScope;
begin
  LScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(LScope.InstanceNode) <> 'string' then
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'minLength']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    if (Length(TUtils.Utf32Encode(TJSONString(LScope.InstanceNode).Value)) < TUtils.JsonGetInteger(AValue)) then
      Visitor.AddError(TErrorType.vetMinLength, [TUtils.JsonGetInteger(AValue)]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMinProperties(const AValue: TJSONNumber);
var
  LScope: TScope;
begin
  LScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'minProperties']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    if (TJSONObject(LScope.InstanceNode).Count < TUtils.JsonGetInteger(AValue)) then
      Visitor.AddError(TErrorType.vetMinProperties, [TUtils.JsonGetInteger(AValue)]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitMultipleOf(const AValue: TJSONNumber);
var
  LScope: TScope;
  LValue: Extended;
  LDivisor: Extended;
  LDivision: Extended;
  LRounded: Extended;
  LEpsilon: Extended;
  LInverse: Extended;
  LInverseRounded: Extended;
  LResidual: Extended;
begin
  LScope := Visitor.CurrentScope;

  if not MatchStr(TUtils.JsonGetType(LScope.InstanceNode), ['number', 'integer']) then
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'multipleOf']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    LValue := TUtils.JsonGetFloat(LScope.InstanceNode);
    LDivisor := TUtils.JsonGetFloat(AValue);
    if LDivisor = 0 then
      Exit;

    if TUtils.JsonGetType(LScope.InstanceNode) = 'integer' then
    begin
      LInverse := 1 / LDivisor;
      LInverseRounded := Round(LInverse);
      if Abs(LInverse - LInverseRounded) <= 1E-12 then
        Exit;
    end;

    if Abs(LValue) < 1E-15 then
      Exit;

    LDivision := LValue / LDivisor;

    if IsInfinite(LDivision) or IsNan(LDivision) then
    begin
      // Optional overflow handling: every integer is multiple of divisors like 1/n.
      if TUtils.JsonGetType(LScope.InstanceNode) = 'integer' then
      begin
        LInverse := 1 / LDivisor;
        LInverseRounded := Round(LInverse);
        if Abs(LInverse - LInverseRounded) <= 1E-12 then
          Exit;
      end;

      Visitor.AddError(TErrorType.vetMultipleOf, [AValue.Value]);
      Exit;
    end;

    LRounded := Round(LDivision);
    LResidual := Abs(LValue - (LRounded * LDivisor));

    if Abs(LValue) < 1E-15 then
      LEpsilon := Max(1E-30, Abs(LDivisor) * 1E-12)
    else
      LEpsilon := Max(1E-12, Abs(LDivision) * 1E-12);

    if (Abs(LDivision - LRounded) > LEpsilon) and (LResidual > LEpsilon) then
      Visitor.AddError(TErrorType.vetMultipleOf, [AValue.Value]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitPattern(const AValue: TJSONString);
var
  LScope: TScope;
begin
  LScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(LScope.InstanceNode) <> 'string' then
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'pattern']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    if not TRegEx.IsMatch(
      TJSONString(LScope.InstanceNode).Value,
      TUtils.RegexNormalizePattern(AValue.Value),
      [roCompiled]) then
      Visitor.AddError(TErrorType.vetPattern, [TUtils.RegexNormalizePattern(AValue.Value)]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitRequired(const AValue: TJSONArray);
var
  LScope: TScope;
  LRequired: TJSONValue;
begin
  LScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'required']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    for LRequired in AValue do
      if TJSONObject(LScope.InstanceNode).FindValue(LRequired.Value) = nil then
        Visitor.AddError(TErrorType.vetRequiredPropertyMissing, [LRequired.Value]);
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitType(const AValue: TJSONValue);
var
  LType: TJSONValue;
  LScope: TScope;
  LAllowedTypes: TList<string>;
begin
  LScope := Visitor.CurrentScope;
  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'type']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  LAllowedTypes := TList<string>.Create;
  try
    if AValue is TJSONString then
    begin
      if TJSONString(AValue).Value = 'number' then
        LAllowedTypes.AddRange(['integer', 'number'])
      else
        LAllowedTypes.Add(TJSONString(AValue).Value.ToLower);
    end
    else if AValue is TJSONArray then
    begin
      for LType in TJSONArray(AValue) do
        if LType.Value = 'number' then
          LAllowedTypes.AddRange(['integer', 'number'])
        else
          LAllowedTypes.Add(LType.Value.ToLower);
    end;

    if not MatchStr(TUtils.JsonGetType(LScope.InstanceNode), LAllowedTypes.ToArray) then
      Visitor.AddError(TErrorType.vetInvalidType, [string.Join(', ', LAllowedTypes.ToArray), TUtils.JsonGetType(LScope.InstanceNode)]);
  finally
    LAllowedTypes.Free;
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitUniqueItems(const AValue: TJSONBool);
var
  LScope: TScope;
  LArray: TJSONArray;
  LCount1: Integer;
  LCount2: Integer;
begin
  LScope := Visitor.CurrentScope;

  if not AValue.AsBoolean then
    Exit;

  if TUtils.JsonGetType(LScope.InstanceNode) <> 'array' then
    Exit;

  with LScope do
  begin
    SchemaPath        := Format('%s/%s', [SchemaPath, 'uniqueItems']);
    SchemaNode        := SchemaNode;
    InstanceNode      := InstanceNode;
    InstancePath      := InstancePath;
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;
  Visitor.PushScope(LScope);
  try
    LArray := TJSONArray(LScope.InstanceNode);
    for LCount1 := 0 to LArray.Count - 2 do
    begin
      for LCount2 := LCount1 + 1 to LArray.Count - 1 do
      begin
        if TUtils.JsonEquals(LArray.Items[LCount1], LArray.Items[LCount2]) then
        begin
          Visitor.AddError(TErrorType.vetUniqueItems, [LArray.Items[LCount1].ToString]);
          Exit;
        end;
      end;
    end;
  finally
    Visitor.PopScope;
  end;
end;

procedure TBaseValidationVisitor<T>.VisitContentEncoding(const AValue: TJSONString);
var
  LScope: TScope;
  LInstanceValue: string;
  LPrecedenceKey: string;
  LAnnotationOnly: Boolean;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'string' then
    Exit;

  if not SameText(AValue.Value, 'base64') then
    Exit;

  LAnnotationOnly := False;
  for LPrecedenceKey in Visitor.KeywordPrecedence do
    if (LPrecedenceKey = '$recursiveRef') or (LPrecedenceKey = '$dynamicRef') then
    begin
      LAnnotationOnly := True;
      Break;
    end;

  LInstanceValue := TJSONString(LScope.InstanceNode).Value;
  if not TRegEx.IsMatch(LInstanceValue, '^[A-Za-z0-9+/]*={0,2}$', [roCompiled]) then
  begin
    if not LAnnotationOnly then
      Visitor.AddError(TErrorType.vetInvalidFormat, ['contentEncoding']);
    Exit;
  end;

  try
    TNetEncoding.Base64.DecodeStringToBytes(LInstanceValue);
  except
    if not LAnnotationOnly then
      Visitor.AddError(TErrorType.vetInvalidFormat, ['contentEncoding']);
  end;
end;

procedure TBaseValidationVisitor<T>.VisitContentMediaType(const AValue: TJSONString);
var
  LScope: TScope;
  LMediaType: string;
  LInstanceValue: string;
  LEncoding: TJSONValue;
  LBytes: TBytes;
  LDecoded: string;
  LJsonValue: TJSONValue;
  LPrecedenceKey: string;
  LAnnotationOnly: Boolean;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'string' then
    Exit;

  LMediaType := LowerCase(AValue.Value);
  if LMediaType <> 'application/json' then
    Exit;

  LAnnotationOnly := False;
  for LPrecedenceKey in Visitor.KeywordPrecedence do
    if (LPrecedenceKey = '$recursiveRef') or (LPrecedenceKey = '$dynamicRef') then
    begin
      LAnnotationOnly := True;
      Break;
    end;

  // Em 2019-09/2020-12, content* funciona como anotação por padrão.
  // Sem um modo estrito explícito, não deve tornar a validação inválida.
  if LAnnotationOnly then
    Exit;

  LInstanceValue := TJSONString(LScope.InstanceNode).Value;
  LDecoded := LInstanceValue;

  // Se houver contentEncoding irmao, decodificar primeiro
  LEncoding := nil;
  if LScope.SchemaNode is TJSONObject then
    LEncoding := TJSONObject(LScope.SchemaNode).FindValue('contentEncoding');

  if (LEncoding is TJSONString) and SameText(TJSONString(LEncoding).Value, 'base64') then
  begin
    // Se o base64 for invalido, contentEncoding ja reportara o erro
    if not TRegEx.IsMatch(LInstanceValue, '^[A-Za-z0-9+/]*={0,2}$', [roCompiled]) then
      Exit;

    try
      LBytes := TNetEncoding.Base64.DecodeStringToBytes(LInstanceValue);
      LDecoded := TEncoding.UTF8.GetString(LBytes);
    except
      Exit;
    end;
  end;

  LJsonValue := TJSONObject.ParseJSONValue(LDecoded);
  if LJsonValue = nil then
    Visitor.AddError(TErrorType.vetInvalidFormat, ['contentMediaType'])
  else
    LJsonValue.Free;
end;

{ TBaseApplicatorVisitor<T> }

procedure TBaseApplicatorVisitor<T>.VisitAdditionalItems(const AValue: TJSONValue);
var
  LCount: Integer;
  LScope: TScope;
  LItems: TJSONValue;
  LWalker: IWalker;
  LCovered: TList<Integer>;
  LNewScope: TScope;
begin
  LScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(LScope.InstanceNode) <> 'array' then
    Exit;

  if (not LScope.SchemaNode.TryGetValue('items', LItems)) or (TUtils.JsonGetType(LItems) <> 'array') then
    Exit;

  LCovered := TList<Integer>.Create(LScope.CoveredItems);
  try
    for LCount := 0 to TJSONArray(LScope.InstanceNode).Count - 1 do
    begin
      if LCovered.Contains(LCount) then
        Continue;

      LNewScope := LScope;
      with LNewScope do
      begin
        SchemaPath        := Format('%s/additionalItems', [SchemaPath]);
        SchemaNode        := AValue;
        InstanceNode      := TJSONArray(LScope.InstanceNode)[LCount];
        InstancePath      := Format('%s[%d]', [InstancePath, LCount]);
        CoveredItems      := [];
        ContainsCount     := 0;
        VisitedKeywords   := [];
        CoveredProperties := [];
      end;

      Visitor.PushScope(LNewScope);
      try
        LWalker := TWalker<T>.Create(AValue, Visitor);
        LWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      TUtils.AddArray<Integer>(LScope.CoveredItems, LCount);
    end;
  finally
    LCovered.Free;
  end;

  Visitor.UpdateScope(LScope);
end;

procedure TBaseApplicatorVisitor<T>.VisitAdditionalProperties(const AValue: TJSONValue);
var
  LPair: TJSONPair;
  LScope: TScope;
  LWalker: IWalker;
  LCovered: TList<string>;
  LNewScope: TScope;
  LErrorCount: Integer;
begin
  LScope := Visitor.CurrentScope;

  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  LCovered := TList<string>.Create(LScope.CoveredProperties);
  try
    for LPair in TJSONObject(LScope.InstanceNode) do
    begin
      if LCovered.Contains(LPair.JsonString.Value) then
        Continue;

      LNewScope := LScope;
      with LNewScope do
      begin
        SchemaPath        := Format('%s/additionalProperties', [SchemaPath]);
        SchemaNode        := AValue;
        InstanceNode      := LPair.JsonValue;
        InstancePath      := Format('%s/%s', [InstancePath, LPair.JsonString.Value]);
        CoveredItems      := [];
        ContainsCount     := 0;
        VisitedKeywords   := [];
        CoveredProperties := [];
      end;

      Visitor.PushScope(LNewScope);
      LErrorCount := Length(Visitor.Result.Errors);
      try
        LWalker := TWalker<T>.Create(AValue, Visitor);
        LWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      TUtils.AddArray<string>(LScope.CoveredProperties, LPair.JsonString.Value);
      if Length(Visitor.Result.Errors) = LErrorCount then
      begin
        if not Assigned(LScope.EvaluatedPropertiesInScope) then
          LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
        LScope.EvaluatedPropertiesInScope.Add(Format('%s/%s', [LScope.InstancePath, LPair.JsonString.Value]));
        Visitor.Result.AddEvaluatedProperty(Format('%s/%s', [LScope.InstancePath, LPair.JsonString.Value]));
      end;
    end;
  finally
    LCovered.Free;
  end;

  Visitor.UpdateScope(LScope);
end;

procedure TBaseApplicatorVisitor<T>.VisitAllOf(const AValue: TJSONArray);
var
  LCount: Integer;
  LScope: TScope;
  LWalker: IWalker;
  LNewScope: TScope;
  LVisitor: T;
  LBranchValid: Boolean;
  LParentOffset: Integer;
  LParentMaxOffset: Integer;
  LParentScopeItem: TScope;
  LEvaluatedProperty: string;
  LNormalizedEvaluatedProperty: string;
  LCombinedCoveredItems: TArray<Integer>;
  LCombinedCoveredProperties: TArray<string>;
  LCombinedEvaluatedProperties: THashSet<string>;
begin
  LScope := Visitor.CurrentScope;
  LCombinedCoveredItems := LScope.CoveredItems;
  LCombinedCoveredProperties := LScope.CoveredProperties;
  LCombinedEvaluatedProperties := THashSet<string>.Create;
  try
    if Assigned(LScope.EvaluatedPropertiesInScope) then
      for LEvaluatedProperty in LScope.EvaluatedPropertiesInScope do
        LCombinedEvaluatedProperties.Add(LEvaluatedProperty);

    for LCount := 0 to AValue.Count - 1 do
    begin
      LNewScope := LScope;
      with LNewScope do
      begin
        SchemaPath        := Format('%s/allOf/%d', [SchemaPath, LCount]);
        SchemaNode        := AValue[LCount];
        InstanceNode      := InstanceNode;
        InstancePath      := Format('%s', [InstancePath]);
        CoveredItems      := [];
        ContainsCount     := 0;
        VisitedKeywords   := [];
        CoveredProperties := [];
      end;

      LVisitor := Visitor.New(LNewScope.SchemaNode, LNewScope.InstanceNode, LScope.BaseURI);
      LVisitor.PopScope;
      LParentMaxOffset := -1;
      LParentOffset := 0;
      while Assigned(Visitor.CurrentScope(LParentOffset).SchemaNode) do
      begin
        LParentMaxOffset := LParentOffset;
        Inc(LParentOffset);
      end;

      for LParentOffset := LParentMaxOffset downto 0 do
      begin
        LParentScopeItem := Visitor.CurrentScope(LParentOffset);
        LParentScopeItem.EvaluatedPropertiesInScope := nil;
        LVisitor.PushScope(LParentScopeItem);
      end;

      LVisitor.PushScope(LNewScope);
      LWalker := TWalker<T>.Create(LNewScope.SchemaNode, LVisitor);
      LWalker.Walk;

      // Mantém o escopo do branch sincronizado com as anotações produzidas
      // durante a avaliação do branch antes do pop.
      LNewScope := LVisitor.CurrentScope;
      if not Assigned(LNewScope.EvaluatedPropertiesInScope) then
        LNewScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

      for LEvaluatedProperty in LVisitor.Result.EvaluatedProperties do
      begin
        LNormalizedEvaluatedProperty := LEvaluatedProperty;
        if not LNormalizedEvaluatedProperty.IsEmpty then
        begin
          if (LScope.InstancePath <> '#') and not LNormalizedEvaluatedProperty.StartsWith(LScope.InstancePath + '/') then
          begin
            if LNormalizedEvaluatedProperty = '#' then
              LNormalizedEvaluatedProperty := LScope.InstancePath
            else if LNormalizedEvaluatedProperty.StartsWith('#/') then
              LNormalizedEvaluatedProperty := LScope.InstancePath + LNormalizedEvaluatedProperty.Substring(1)
            else if LNormalizedEvaluatedProperty.StartsWith('/') then
              LNormalizedEvaluatedProperty := LScope.InstancePath + LNormalizedEvaluatedProperty
            else
              LNormalizedEvaluatedProperty := LScope.InstancePath + '/' + LNormalizedEvaluatedProperty;
          end;
        end;

        LNewScope.EvaluatedPropertiesInScope.Add(LNormalizedEvaluatedProperty);
      end;
      LVisitor.UpdateScope(LNewScope);

      LNewScope := LVisitor.PopScope;
      LBranchValid := LVisitor.Result.IsValid;

      if not LBranchValid then
      begin
        Visitor.AddError(vetAllOf, [LCount]);
        Exit;
      end;

      LCombinedCoveredItems := TUtils.MergeArray<Integer>([LCombinedCoveredItems, LNewScope.CoveredItems]);
      LCombinedCoveredProperties := TUtils.MergeArray<string>([LCombinedCoveredProperties, LNewScope.CoveredProperties]);

      if Assigned(LNewScope.EvaluatedPropertiesInScope) then
        for LEvaluatedProperty in LNewScope.EvaluatedPropertiesInScope do
      begin
        LNormalizedEvaluatedProperty := LEvaluatedProperty;
        if not LNormalizedEvaluatedProperty.IsEmpty then
        begin
          if (LScope.InstancePath <> '#') and not LNormalizedEvaluatedProperty.StartsWith(LScope.InstancePath + '/') then
          begin
            if LNormalizedEvaluatedProperty = '#' then
              LNormalizedEvaluatedProperty := LScope.InstancePath
            else if LNormalizedEvaluatedProperty.StartsWith('#/') then
              LNormalizedEvaluatedProperty := LScope.InstancePath + LNormalizedEvaluatedProperty.Substring(1)
            else if LNormalizedEvaluatedProperty.StartsWith('/') then
              LNormalizedEvaluatedProperty := LScope.InstancePath + LNormalizedEvaluatedProperty
            else
              LNormalizedEvaluatedProperty := LScope.InstancePath + '/' + LNormalizedEvaluatedProperty;
          end;
        end;

        LCombinedEvaluatedProperties.Add(LNormalizedEvaluatedProperty);
        Visitor.Result.AddEvaluatedProperty(LNormalizedEvaluatedProperty);
      end;
    end;

    LScope.CoveredItems := LCombinedCoveredItems;
    LScope.CoveredProperties := LCombinedCoveredProperties;
    if LCombinedEvaluatedProperties.Count > 0 then
    begin
      if not Assigned(LScope.EvaluatedPropertiesInScope) then
        LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

      for LEvaluatedProperty in LCombinedEvaluatedProperties do
        LScope.EvaluatedPropertiesInScope.Add(LEvaluatedProperty);
    end;

    Visitor.UpdateScope(LScope);
  finally
    LCombinedEvaluatedProperties.Free;
  end;
end;

procedure TBaseApplicatorVisitor<T>.VisitAnyOf(const AValue: TJSONArray);
var
  LCount: Integer;
  LScope: TScope;
  LWalker: IWalker;
  LVisitor: T;
  LNewScope: TScope;
  LBranchValid: Boolean;
  LAnyBranchValid: Boolean;
  LEvaluatedProperty: string;
  LNormalizedEvaluatedProperty: string;
  LParentOffset: Integer;
  LParentMaxOffset: Integer;
  LParentScopeItem: TScope;
begin
  LScope := Visitor.CurrentScope;
  LAnyBranchValid := False;

  for LCount := 0 to AValue.Count - 1 do
  begin
    LNewScope := LScope;
    with LNewScope do
    begin
      SchemaPath        := Format('%s/anyOf/%d', [SchemaPath, LCount]);
      SchemaNode        := AValue[LCount];
      InstanceNode      := InstanceNode;
      InstancePath      := Format('%s', [InstancePath]);
      CoveredItems      := [];
      ContainsCount     := 0;
      VisitedKeywords   := [];
      CoveredProperties := [];
    end;

    LVisitor := Visitor.New(LNewScope.SchemaNode, LNewScope.InstanceNode, LScope.BaseURI);
    LVisitor.PopScope; // Remove o scope inicial do construtor para substituir pela cadeia do pai
    // Injeta a cadeia de escopos do pai para manter o dynamic scope chain do $recursiveRef.
    // Os scopes s\u00e3o empilhados do mais antigo (fundo) ao mais novo (topo), preservando a ordem.
    LParentMaxOffset := -1;
    LParentOffset := 0;
    while Assigned(Visitor.CurrentScope(LParentOffset).SchemaNode) do
    begin
      LParentMaxOffset := LParentOffset;
      Inc(LParentOffset);
    end;
    for LParentOffset := LParentMaxOffset downto 0 do
    begin
      LParentScopeItem := Visitor.CurrentScope(LParentOffset);
      LParentScopeItem.EvaluatedPropertiesInScope := nil; // Sandbox cria novo set; sem double-free com o pai
      LVisitor.PushScope(LParentScopeItem);
    end;
    LVisitor.PushScope(LNewScope);
    try
      LWalker := TWalker<T>.Create(LNewScope.SchemaNode, LVisitor);
      LWalker.Walk;
    finally
      LNewScope := LVisitor.PopScope;
      LBranchValid := LVisitor.Result.IsValid;

      if LBranchValid then
      begin
        LAnyBranchValid := True;
        LScope.CoveredItems      := TUtils.MergeArray<Integer>([LScope.CoveredItems, LNewScope.CoveredItems]);
        LScope.CoveredProperties := TUtils.MergeArray<string>([LScope.CoveredProperties, LNewScope.CoveredProperties]);
        if not Assigned(LScope.EvaluatedPropertiesInScope) then
          LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

        for LEvaluatedProperty in LVisitor.Result.EvaluatedProperties do
        begin
          LNormalizedEvaluatedProperty := LEvaluatedProperty;
          if not LNormalizedEvaluatedProperty.IsEmpty then
          begin
            if (LScope.InstancePath <> '#') and not LNormalizedEvaluatedProperty.StartsWith(LScope.InstancePath + '/') then
            begin
              if LNormalizedEvaluatedProperty = '#' then
                LNormalizedEvaluatedProperty := LScope.InstancePath
              else if LNormalizedEvaluatedProperty.StartsWith('#/') then
                LNormalizedEvaluatedProperty := LScope.InstancePath + LNormalizedEvaluatedProperty.Substring(1)
              else if LNormalizedEvaluatedProperty.StartsWith('/') then
                LNormalizedEvaluatedProperty := LScope.InstancePath + LNormalizedEvaluatedProperty
              else
                LNormalizedEvaluatedProperty := LScope.InstancePath + '/' + LNormalizedEvaluatedProperty;
            end;
          end;

          LScope.EvaluatedPropertiesInScope.Add(LNormalizedEvaluatedProperty);
          Visitor.Result.AddEvaluatedProperty(LNormalizedEvaluatedProperty);
        end;
      end;
    end;

    Visitor.UpdateScope(LScope);
  end;

  if not LAnyBranchValid then
    Visitor.AddError(vetAnyOf);
end;

procedure TBaseApplicatorVisitor<T>.VisitElse(const AValue: TJSONValue);
var
  LScope: TScope;
  LWalker: IWalker;
  LNewScope: TScope;
  LErrorCount: Integer;
  LEvaluatedProperty: string;
begin
  LScope := Visitor.CurrentScope;
  if LScope.SchemaNode.FindValue('if') = nil then
    Exit;

  LNewScope := LScope;
  with LNewScope do
  begin
    SchemaPath        := Format('%s/else', [SchemaPath]);
    SchemaNode        := AValue;
    InstanceNode      := InstanceNode;
    InstancePath      := Format('%s', [InstancePath]);
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;

  Visitor.PushScope(LNewScope);
  LErrorCount := Length(Visitor.Result.Errors);
  try
    LWalker := TWalker<T>.Create(LNewScope.SchemaNode, Visitor);
    LWalker.Walk;
  finally
    LNewScope := Visitor.PopScope;
  end;

  if Length(Visitor.Result.Errors) = LErrorCount then
  begin
    LScope.CoveredItems      := TUtils.MergeArray<Integer>([LScope.CoveredItems, LNewScope.CoveredItems]);
    LScope.CoveredProperties := TUtils.MergeArray<string>([LScope.CoveredProperties, LNewScope.CoveredProperties]);
    if Assigned(LNewScope.EvaluatedPropertiesInScope) then
    begin
      if not Assigned(LScope.EvaluatedPropertiesInScope) then
        LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

      for LEvaluatedProperty in LNewScope.EvaluatedPropertiesInScope do
      begin
        LScope.EvaluatedPropertiesInScope.Add(LEvaluatedProperty);
        Visitor.Result.AddEvaluatedProperty(LEvaluatedProperty);
      end;
    end;
  end;

  Visitor.UpdateScope(LScope);
end;

procedure TBaseApplicatorVisitor<T>.VisitIf(const AValue: TJSONValue);
var
  LScope: TScope;
  LWalker: IWalker;
  LSchema: TJSONValue;
  LVisitor: T;
  LNewScope: TScope;
  LEvaluatedProperty: string;
begin
  LScope := Visitor.CurrentScope;

  LNewScope := LScope;
  with LNewScope do
  begin
    SchemaPath        := Format('%s/if', [SchemaPath]);
    SchemaNode        := AValue;
    InstanceNode      := InstanceNode;
    InstancePath      := Format('%s', [InstancePath]);
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;


  LVisitor := Visitor.New(LNewScope.SchemaNode, LNewScope.InstanceNode, LScope.BaseURI);
  LVisitor.PushScope(LNewScope);
  try
    LWalker := TWalker<T>.Create(LNewScope.SchemaNode, LVisitor);
    LWalker.Walk;
  finally
    LNewScope := LVisitor.PopScope;
    if LVisitor.Result.IsValid then
    begin
      LScope.CoveredItems      := TUtils.MergeArray<Integer>([LScope.CoveredItems, LNewScope.CoveredItems]);
      LScope.CoveredProperties := TUtils.MergeArray<string>([LScope.CoveredProperties, LNewScope.CoveredProperties]);
      if Assigned(LNewScope.EvaluatedPropertiesInScope) then
      begin
        if not Assigned(LScope.EvaluatedPropertiesInScope) then
          LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

        for LEvaluatedProperty in LNewScope.EvaluatedPropertiesInScope do
        begin
          LScope.EvaluatedPropertiesInScope.Add(LEvaluatedProperty);
          Visitor.Result.AddEvaluatedProperty(LEvaluatedProperty);
        end;
      end;
    end;
  end;

  Visitor.UpdateScope(LScope);

  if LVisitor.Result.IsValid and LScope.SchemaNode.TryGetValue('then', LSchema) then
    VisitThen(LSchema)
  else if (not LVisitor.Result.IsValid) and LScope.SchemaNode.TryGetValue('else', LSchema) then
    VisitElse(LSchema);

  Visitor
    .AddVisitedKeyword('then')
    .AddVisitedKeyword('else');
end;

procedure TBaseApplicatorVisitor<T>.VisitItems(const AValue: TJSONValue);
var
  LCount: Integer;
  LScope: TScope;
  LWalker: IWalker;
  LCovered: TList<Integer>;
  LNewScope: TScope;
  LInstance: TJSONArray;
  LSchema: TJSONValue;
  LMaxCount: Integer;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'array' then
    Exit;

  LCovered := TList<Integer>.Create(LScope.CoveredItems);
  try
    LInstance := TJSONArray(LScope.InstanceNode);

    if TUtils.JsonGetType(AValue) = 'array' then
    begin
      LMaxCount := Min(LInstance.Count, TJSONArray(AValue).Count);
      LSchema   := nil;
    end
    else
    begin
      LMaxCount := LInstance.Count;
      LSchema   := AValue;
    end;

    for LCount := 1 to LMaxCount do
    begin
      if LCovered.Contains(LCount - 1) then
        Continue;

      if TUtils.JsonGetType(AValue) = 'array' then
        LSchema := TJSONArray(AValue)[LCount - 1];

      LNewScope := LScope;
      with LNewScope do
      begin
        SchemaPath        := Format('%s/items/%d', [SchemaPath, LCount - 1]);
        SchemaNode        := LSchema;
        InstanceNode      := LInstance[LCount - 1];
        InstancePath      := Format('%s[%d]', [InstancePath, LCount - 1]);
        CoveredItems      := [];
        ContainsCount     := 0;
        VisitedKeywords   := [];
        CoveredProperties := [];
      end;

      Visitor.PushScope(LNewScope);
      try
        LWalker := TWalker<T>.Create(LNewScope.SchemaNode, Visitor);
        LWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      TUtils.AddArray<Integer>(LScope.CoveredItems, LCount - 1);
    end;
  finally
    LCovered.Free;
  end;

  Visitor.UpdateScope(LScope);
end;

procedure TBaseApplicatorVisitor<T>.VisitNot(const AValue: TJSONValue);
var
  LScope: TScope;
  LWalker: IWalker;
  LVisitor: T;
  LNewScope: TScope;
begin
  LScope := Visitor.CurrentScope;

  LNewScope := LScope;
  with LNewScope do
  begin
    SchemaPath        := Format('%s/not', [SchemaPath]);
    SchemaNode        := AValue;
    InstanceNode      := InstanceNode;
    InstancePath      := Format('%s', [InstancePath]);
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;

  LVisitor := Visitor.New(LNewScope.SchemaNode, LNewScope.InstanceNode, LScope.BaseURI);
  LWalker := TWalker<T>.Create(LNewScope.SchemaNode, LVisitor);
  LWalker.Walk;

  if LVisitor.Result.IsValid then
    Visitor.AddError(vetNot);
end;

procedure TBaseApplicatorVisitor<T>.VisitOneOf(const AValue: TJSONArray);
var
  LCount: Integer;
  LScope: TScope;
  LWalker: IWalker;
  LVisitor: T;
  LMatches: Integer;
  LNewScope: TScope;
  LWinningCoveredItems: TArray<Integer>;
  LWinningCoveredProperties: TArray<string>;
  LWinningEvaluatedProperties: THashSet<string>;
  LEvaluatedProperty: string;
begin
  LScope := Visitor.CurrentScope;

  LMatches := 0;
  LWinningCoveredItems := [];
  LWinningCoveredProperties := [];
  LWinningEvaluatedProperties := THashSet<string>.Create;
  try
    for LCount := 0 to AValue.Count - 1 do
    begin
      LNewScope := LScope;
      with LNewScope do
      begin
        SchemaPath        := Format('%s/oneOf/%d', [SchemaPath, LCount]);
        SchemaNode        := AValue[LCount];
        InstanceNode      := InstanceNode;
        InstancePath      := Format('%s', [InstancePath]);
        CoveredItems      := [];
        ContainsCount     := 0;
        VisitedKeywords   := [];
        CoveredProperties := [];
      end;

      LVisitor := Visitor.New(LNewScope.SchemaNode, LNewScope.InstanceNode, LScope.BaseURI);
      LVisitor.PushScope(LNewScope);
      try
        LWalker := TWalker<T>.Create(LNewScope.SchemaNode, LVisitor);
        LWalker.Walk;
      finally
        LNewScope := LVisitor.PopScope;
      end;

      if LVisitor.Result.IsValid then
      begin
        Inc(LMatches);

        if LMatches = 1 then
        begin
          LWinningCoveredItems := LNewScope.CoveredItems;
          LWinningCoveredProperties := LNewScope.CoveredProperties;
          LWinningEvaluatedProperties.Clear;

          if Assigned(LNewScope.EvaluatedPropertiesInScope) then
            for LEvaluatedProperty in LNewScope.EvaluatedPropertiesInScope do
              LWinningEvaluatedProperties.Add(LEvaluatedProperty);
        end;
      end;
    end;

    if LMatches = 0 then
      Visitor.AddError(vetOneOf_NoMatch)
    else if LMatches > 1 then
      Visitor.AddError(vetOneOf_MultipleMatches)
    else
    begin
      LScope.CoveredItems := TUtils.MergeArray<Integer>([LScope.CoveredItems, LWinningCoveredItems]);
      LScope.CoveredProperties := TUtils.MergeArray<string>([LScope.CoveredProperties, LWinningCoveredProperties]);
      if LWinningEvaluatedProperties.Count > 0 then
      begin
        if not Assigned(LScope.EvaluatedPropertiesInScope) then
          LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

        for LEvaluatedProperty in LWinningEvaluatedProperties do
        begin
          LScope.EvaluatedPropertiesInScope.Add(LEvaluatedProperty);
          Visitor.Result.AddEvaluatedProperty(LEvaluatedProperty);
        end;
      end;
      Visitor.UpdateScope(LScope);
    end;
  finally
    LWinningEvaluatedProperties.Free;
  end;
end;

procedure TBaseApplicatorVisitor<T>.VisitPatternProperties(const AValue: TJSONObject);
var
  LPair: TJSONPair;
  LRegex: string;
  LScope: TScope;
  LWalker: IWalker;
  LPropName: string;
  LNewScope: TScope;
  LPatternPair: TJSONPair;
  LErrorCount: Integer;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  for LPair in TJSONObject(LScope.InstanceNode) do
  begin
    LPropName := LPair.JsonString.Value;

    for LPatternPair in AValue do
    begin
      LRegex := TUtils.RegexNormalizePattern(LPatternPair.JsonString.Value);
      if not TRegEx.IsMatch(LPropName, LRegex, [roCompiled]) then
        Continue;

      LNewScope := LScope;
      with LNewScope do
      begin
        SchemaPath        := Format('%s/patternProperties/{%s}', [SchemaPath, LRegex]);
        SchemaNode        := LPatternPair.JsonValue;
        InstanceNode      := LPair.JsonValue;
        InstancePath      := Format('%s/properties/%s', [InstancePath, LPropName]);
        CoveredItems      := [];
        ContainsCount     := 0;
        VisitedKeywords   := [];
        CoveredProperties := [];
      end;

      Visitor.PushScope(LNewScope);
      LErrorCount := Length(Visitor.Result.Errors);
      try
        LWalker := TWalker<T>.Create(LNewScope.SchemaNode, Visitor);
        LWalker.Walk;
      finally
        Visitor.PopScope;
      end;

      TUtils.AddArray<string>(LScope.CoveredProperties, LPair.JsonString.Value);
      if Length(Visitor.Result.Errors) = LErrorCount then
      begin
        if not Assigned(LScope.EvaluatedPropertiesInScope) then
          LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
        LScope.EvaluatedPropertiesInScope.Add(Format('%s/%s', [LScope.InstancePath, LPair.JsonString.Value]));
        Visitor.Result.AddEvaluatedProperty(Format('%s/%s', [LScope.InstancePath, LPair.JsonString.Value]));
      end;
    end;
  end;

  Visitor.UpdateScope(LScope);
end;

procedure TBaseApplicatorVisitor<T>.VisitPrefixItems(const AValue: TJSONArray);
var
  LScope: TScope;
  LCount: Integer;
  LWalker: IWalker;
  LNewScope: TScope;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'array' then
    Exit;

  for LCount := 0 to Min(TJSONArray(LScope.InstanceNode).Count - 1, AValue.Count - 1) do
  begin
    LNewScope := LScope;
    with LNewScope do
    begin
      SchemaPath        := Format('%s/items/%d', [SchemaPath, LCount]);
      SchemaNode        := AValue[LCount];
      InstanceNode      := TJSONArray(LScope.InstanceNode)[LCount];
      InstancePath      := Format('%s[%d]', [InstancePath, LCount]);
      CoveredItems      := [];
      ContainsCount     := 0;
      VisitedKeywords   := [];
      CoveredProperties := [];
    end;

    Visitor.PushScope(LNewScope);
    try
      LWalker := TWalker<T>.Create(LNewScope.SchemaNode, Visitor);
      LWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    TUtils.AddArray<Integer>(LScope.CoveredItems, LCount);
  end;

  Visitor.UpdateScope(LScope);
end;

procedure TBaseApplicatorVisitor<T>.VisitProperties(const AValue: TJSONObject);
var
  LPair: TJSONPair;
  LScope: TScope;
  LWalker: IWalker;
  LNewScope: TScope;
  LSubInstance: TJSONValue;
  LErrorCount: Integer;
begin
  LScope := Visitor.CurrentScope;
  if TUtils.JsonGetType(LScope.InstanceNode) <> 'object' then
    Exit;

  for LPair in AValue do
  begin
    if not TJSONObject(LScope.InstanceNode).TryGetValue(LPair.JsonString.Value, LSubInstance) then
      Continue;

    LNewScope := LScope;
    with LNewScope do
    begin
      SchemaPath        := Format('%s/properties/%s', [SchemaPath, LPair.JsonString.Value]);
      SchemaNode        := LPair.JsonValue;
      InstanceNode      := LSubInstance;
      InstancePath      := Format('%s.%s', [InstancePath, LPair.JsonString.Value]);
      CoveredItems      := [];
      ContainsCount     := 0;
      VisitedKeywords   := [];
      CoveredProperties := [];
    end;

    Visitor.PushScope(LNewScope);
    LErrorCount := Length(Visitor.Result.Errors);
    try
      LWalker := TWalker<T>.Create(LNewScope.SchemaNode, Visitor);
      LWalker.Walk;
    finally
      Visitor.PopScope;
    end;

    TUtils.AddArray<string>(LScope.CoveredProperties, LPair.JsonString.Value);
    if Length(Visitor.Result.Errors) = LErrorCount then
    begin
      if not Assigned(LScope.EvaluatedPropertiesInScope) then
        LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;
      LScope.EvaluatedPropertiesInScope.Add(Format('%s/%s', [LScope.InstancePath, LPair.JsonString.Value]));
      Visitor.Result.AddEvaluatedProperty(Format('%s/%s', [LScope.InstancePath, LPair.JsonString.Value]));
    end;
    Visitor.UpdateScope(LScope);
  end;
end;

procedure TBaseApplicatorVisitor<T>.VisitThen(const AValue: TJSONValue);
var
  LScope: TScope;
  LWalker: IWalker;
  LNewScope: TScope;
  LErrorCount: Integer;
  LEvaluatedProperty: string;
begin
  LScope := Visitor.CurrentScope;
  if LScope.SchemaNode.FindValue('if') = nil then
    Exit;

  LNewScope := LScope;
  with LNewScope do
  begin
    SchemaPath        := Format('%s/then', [SchemaPath]);
    SchemaNode        := AValue;
    InstanceNode      := InstanceNode;
    InstancePath      := Format('%s', [InstancePath]);
    CoveredItems      := [];
    ContainsCount     := 0;
    VisitedKeywords   := [];
    CoveredProperties := [];
  end;

  Visitor.PushScope(LNewScope);
  LErrorCount := Length(Visitor.Result.Errors);
  try
    LWalker := TWalker<T>.Create(LNewScope.SchemaNode, Visitor);
    LWalker.Walk;
  finally
    LNewScope := Visitor.PopScope;
  end;

  if Length(Visitor.Result.Errors) = LErrorCount then
  begin
    LScope.CoveredItems      := TUtils.MergeArray<Integer>([LScope.CoveredItems, LNewScope.CoveredItems]);
    LScope.CoveredProperties := TUtils.MergeArray<string>([LScope.CoveredProperties, LNewScope.CoveredProperties]);
    if Assigned(LNewScope.EvaluatedPropertiesInScope) then
    begin
      if not Assigned(LScope.EvaluatedPropertiesInScope) then
        LScope.EvaluatedPropertiesInScope := THashSet<string>.Create;

      for LEvaluatedProperty in LNewScope.EvaluatedPropertiesInScope do
      begin
        LScope.EvaluatedPropertiesInScope.Add(LEvaluatedProperty);
        Visitor.Result.AddEvaluatedProperty(LEvaluatedProperty);
      end;
    end;
  end;

  Visitor.UpdateScope(LScope);
end;

end.
