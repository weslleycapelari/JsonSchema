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
  JsonSchema.Registry.Base,
  JsonSchema.Validation.Visitor.Core,
  JsonSchema.Validation.Visitor.Applicator,
  JsonSchema.Validation.Visitor.Validation,
  JsonSchema.Validation.Visitor.HyperSchema;

type
  // Allows draft-specific visitors to configure format assertion behavior at runtime.
  // Identified by GUID to avoid a direct dependency on the draft unit.
  IDraftFormatAssertionMode = interface(IInterface)
    ['{1E9E0329-00E8-47F6-AB75-A0A33A3774E4}']
    function IsFormatAssertionEnabled: Boolean;
    procedure SetFormatAssertionEnabled(const pValue: Boolean);
  end;

  // Allows draft-specific visitors to silence the validation vocabulary at runtime.
  // Identified by GUID to avoid a direct dependency on the draft unit.
  IDraft2019_09ValidationVocabularyMode = interface(IInterface)
    ['{7D1B6A0D-31EA-4F2F-9A45-77A2D65A8E5B}']
    function IsValidationVocabularySilent: Boolean;
    procedure SetValidationVocabularySilent(const pValue: Boolean);
  end;

  /// <summary>
  /// Empty base class for the Relative JSON Pointer vocabulary.
  /// Draft-specific visitors inherit from this to participate in the visitor hierarchy.
  /// </summary>
  TBaseRelativeJsonPointer<T: IValidationVisitor<T>> = class(TBase<T>, IBaseRelativeJsonPointer<T>)

  end;

  /// <summary>
  /// Orchestrates JSON Schema validation by composing vocabulary-specific sub-visitors
  /// and managing the validation result, error reporting, language, and $ref resolution.
  /// </summary>
  TValidationVisitor<T> = class(TBaseVisitor<T>, IValidationVisitor<T>, IRefResolutionGuard)
  protected
    FResult: IValidationResult;
    FRegistry: TRegistryVisitor;
    FOwnsRegistry: Boolean;
    FLanguage: TLanguage;
    FCustomHint: TJSONValue;
    FTranslation: ITranslate;
    FRefResolutionStack: TStack<string>;
    FRefResolutionSet: TDictionary<string, Byte>;
    FMaxRefResolutionDepth: Integer;
  public
    constructor Create(const pSchema, pData: TJSONValue; const pBaseURI: string; const pCustomHint: TJSONValue = nil);
    destructor Destroy; override;

    function Registry: TRegistryVisitor;
    function KeywordPrecedence: TArray<string>; override;
    function Language: TLanguage; overload;
    function Language(const pLanguage: TLanguage): IValidationVisitor<T>; overload;
    procedure AddError(const pErrorType: TErrorType; pParams: array of const); overload;
    procedure AddError(const pErrorType: TErrorType); overload;
    function FindCustomHint(pErrorType: TErrorType): string;
    function Result: IValidationResult;
    function TryEnterRefResolution(const pResolvedRef: string; out pReason: string): Boolean;
    procedure LeaveRefResolution(const pResolvedRef: string);
  end;

implementation

uses
  System.TypInfo,
  System.SysUtils,
  JsonSchema.Walker,
  JsonSchema.Walker.Types;

{ TValidationVisitor<T> }

procedure TValidationVisitor<T>.AddError(const pErrorType: TErrorType);
begin
  AddError(pErrorType, []);
end;

procedure TValidationVisitor<T>.AddError(const pErrorType: TErrorType; pParams: array of const);
var
  lScope: TScope;
  lMessage: TErrorMessage;
  lCustomHint: string;
  lParentNode: TJSONValue;
begin
  lScope      := CurrentScope;
  lMessage    := FTranslation.GetMessage(pErrorType);
  lCustomHint := FindCustomHint(pErrorType);

  if FScopeStack.Count > 2 then
    lParentNode := CurrentScope(2).InstanceNode
  else
    lParentNode := lScope.InstanceNode;

  Result.AddError(TError.Create
    .RootNode(FData)
    .ErrorType(pErrorType)
    .ParentNode(lParentNode)
    .SchemaNode(lScope.SchemaNode)
    .SchemaPath(lScope.SchemaPath)
    .InstanceNode(lScope.InstanceNode)
    .InstancePath(lScope.InstancePath)
    .ErrorMessage(Format(lMessage.Error, pParams))
    .StandardHint(Format(lMessage.Hint, pParams))
    .CustomHint(lCustomHint));
end;

constructor TValidationVisitor<T>.Create(const pSchema, pData: TJSONValue; const pBaseURI: string; const pCustomHint: TJSONValue);
var
  lWalker: IWalker;
begin
  inherited Create(pSchema, pData, pBaseURI);

  FResult               := TValidationResult.Create;
  FRegistry             := TRegistryVisitor.Create(pSchema, pData, pBaseURI);
  FOwnsRegistry         := True;
  FCustomHint           := pCustomHint;
  FRefResolutionStack   := TStack<string>.Create;
  FRefResolutionSet     := TDictionary<string, Byte>.Create;
  FMaxRefResolutionDepth := 100;

  Language(TLanguage.lang_ptBR);

  lWalker := TWalker<TRegistryVisitor>.Create(pSchema, FRegistry);
  lWalker.Walk;
end;

destructor TValidationVisitor<T>.Destroy;
begin
  FRefResolutionSet.Free;
  FRefResolutionStack.Free;
  if FOwnsRegistry then
    FRegistry.Free;
  inherited;
end;

function TValidationVisitor<T>.FindCustomHint(pErrorType: TErrorType): string;
var
  lScope: TScope;
  lPathSegments: TArray<string>;
  lCurrentNode: TJSONValue;
  lSegment: string;
  lHintValue: TJSONValue;
  lErrorKeyword: string;
begin
  Result := '';
  lScope := CurrentScope;
  if not Assigned(FCustomHint) or lScope.InstancePath.IsEmpty then
    Exit;

  // Normaliza e quebra o caminho: '#.relacao_empregados[0].cbo' -> ['relacao_empregados', 'cbo']
  // Precisamos de uma função robusta para isso.
  lPathSegments := TUtils.ParseInstancePath(lScope.InstancePath);

  lCurrentNode := FCustomHint;
  for lSegment in lPathSegments do
  begin
    if not (lCurrentNode is TJSONObject) then
      Exit; // Não podemos navegar mais fundo

    if not (lCurrentNode as TJSONObject).TryGetValue(lSegment, lCurrentNode) then
    begin
      if (lCurrentNode as TJSONObject).TryGetValue(GetEnumName(TypeInfo(TErrorType), Ord(TErrorType.vetUnknown)), lCurrentNode) then
        Break // Não encontra um erro específico, mas encontra um erro genérico
      else
        Exit; // Caminho não encontrado no JSON de dicas
    end;
  end;

  // Chegamos ao nó final do caminho. Agora procuramos pelo tipo de erro.
  if (lCurrentNode is TJSONObject) then
  begin
    lErrorKeyword := GetEnumName(TypeInfo(TErrorType), Ord(pErrorType)); // ex: vetPattern
    if (lCurrentNode as TJSONObject).TryGetValue(lErrorKeyword, lHintValue) and (lHintValue is TJSONString) then
      Result := (lHintValue as TJSONString).Value;
  end
  else if lCurrentNode is TJSONString then
    Result := TJSONString(lCurrentNode).Value;
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

function TValidationVisitor<T>.Language(const pLanguage: TLanguage): IValidationVisitor<T>;
begin
  Result    := Self;
  FLanguage := pLanguage;
  FTranslation := TTranslateUtils.GetTranslation(pLanguage);
end;

function TValidationVisitor<T>.Registry: TRegistryVisitor;
begin
  Result := FRegistry;
end;

procedure TValidationVisitor<T>.LeaveRefResolution(const pResolvedRef: string);
var
  lTopRef: string;
begin
  if FRefResolutionStack.Count = 0 then
  begin
    FRefResolutionSet.Remove(pResolvedRef);
    Exit;
  end;

  lTopRef := FRefResolutionStack.Peek;
  if SameText(lTopRef, pResolvedRef) then
    FRefResolutionStack.Pop
  else
    FRefResolutionSet.Remove(pResolvedRef);

  FRefResolutionSet.Remove(pResolvedRef);
end;

function TValidationVisitor<T>.Result: IValidationResult;
begin
  Result := FResult;
end;

function TValidationVisitor<T>.TryEnterRefResolution(const pResolvedRef: string; out pReason: string): Boolean;
begin
  pReason := '';

  if FRefResolutionStack.Count >= FMaxRefResolutionDepth then
  begin
    pReason := Format('Maximum call stack size exceeded while resolving reference "%s".', [pResolvedRef]);
    Exit(False);
  end;

  if FRefResolutionSet.ContainsKey(pResolvedRef) then
  begin
    pReason := Format('Maximum call stack size exceeded while resolving cyclic reference "%s".', [pResolvedRef]);
    Exit(False);
  end;

  FRefResolutionSet.Add(pResolvedRef, 1);
  FRefResolutionStack.Push(pResolvedRef);
  Result := True;
end;

end.
