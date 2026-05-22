unit JsonSchema.Walker;

interface

uses
  System.JSON,
  System.Generics.Collections,
  JsonSchema.Types,
  JsonSchema.Interfaces,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces;

type
  TJSONValueClass = class of TJSONValue;

  /// <summary>Core walker that traverses a JSON Schema document and dispatches to visitor methods.</summary>
  IWalker = interface(IInterface)
    ['{AEC155F6-90DD-479F-AD21-3B26426AF03B}']
    procedure Walk;
    function GetValidationResult: IValidationResult;
  end;

  /// <summary>
  ///   Generic walker implementation that uses cached RTTI to discover visitor methods
  ///   and dispatches based on keyword names.
  /// </summary>
  TWalker<T: IVisitor<T>> = class(TInterfacedObject, IWalker)
  private
    FSchema: TJSONValue;
    FVisitor: T;
    FVisitorMethod: TDictionary<string, TVisitorProc>;
    FVisitorMethodParamType: TDictionary<string, TJSONValueClass>;
    FProcessedKeywords: THashSet<string>;
    FSilentMode: Boolean;

    procedure MapMethodsForObject(const pObject: TObject; const pTargetMap: TDictionary<string, TVisitorProc>);
    procedure MapVisitorComponent(const pComponent: IInterface; const pComponentName: string);
    procedure InitializeSilentMode;
    function IsValidationKeyword(const pKeyword: string): Boolean;
    function ShouldVisit(const pKeyword: string): Boolean;
    procedure ProcessPrecedence(const pPrecedence: TArray<string>);
    procedure ProcessPairs;
    procedure DispatchVisit(const pName: string; const pValue: TJSONValue);
  public
    constructor Create(const pSchema: TJSONValue; const pVisitor: T);
    destructor Destroy; override;
    procedure Walk;
    function GetValidationResult: IValidationResult;
    function Visitor: T;
  end;

  /// <summary>Factory class for creating validation walkers with automatic draft detection.</summary>
  TValidationWalker = class
  public
    class function New(const pSchema: TJSONValue; const pData: TJSONValue; const pCustomHint: TJSONValue = nil;
      const pDraft: TDraftVersion = TDraftVersion.dvUnknown): IWalker; static;
  end;

implementation

uses
  System.Rtti,
  System.TypInfo,
  System.SysUtils,
  JsonSchema.Exceptions,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Draft6,
  JsonSchema.Validation.Draft7,
  JsonSchema.Validation.Draft2019_09,
  JsonSchema.Validation.Draft2020_12,
  JsonSchema.Common.Utils;

{ TWalker<T> }

constructor TWalker<T>.Create(const pSchema: TJSONValue; const pVisitor: T);
begin
  inherited Create;
  FSchema := pSchema;
  FVisitor := pVisitor;
  FVisitorMethod := TDictionary<string, TVisitorProc>.Create;
  FVisitorMethodParamType := TDictionary<string, TJSONValueClass>.Create;
  FProcessedKeywords := THashSet<string>.Create;
  FSilentMode := False;

  MapVisitorComponent(FVisitor.Core as IInterface, 'Core');
  MapVisitorComponent(FVisitor.Applicator as IInterface, 'Applicator');
  MapVisitorComponent(FVisitor.Validation as IInterface, 'Validation');
  MapVisitorComponent(FVisitor.HyperSchema as IInterface, 'HyperSchema');
  MapVisitorComponent(FVisitor.RelativeJsonPointer as IInterface, 'RelativeJsonPointer');
end;

destructor TWalker<T>.Destroy;
begin
  FProcessedKeywords.Free;
  FVisitorMethodParamType.Free;
  FVisitorMethod.Free;
  inherited;
end;

procedure TWalker<T>.MapMethodsForObject(const pObject: TObject; const pTargetMap: TDictionary<string, TVisitorProc>);
var
  lContext: TRttiContext;
  lType: TRttiType;
  lMethod: TRttiMethod;
  lAttr: TCustomAttribute;
  lMethodPtr: TMethod;
  lHasKeyword: Boolean;
  lKeywordName: string;
  lParams: TArray<TRttiParameter>;
begin
  if not Assigned(pObject) then
    Exit;

  lContext := TRttiContext.Create;
  try
    lType := lContext.GetType(pObject.ClassType);
    if lType = nil then
      Exit;

    for lMethod in lType.GetMethods do
    begin
      lHasKeyword := False;

      // Primeiro detecta se método possui VisitorKeywordAttribute
      for lAttr in lMethod.GetAttributes do
      begin
        if lAttr is VisitorKeywordAttribute then
        begin
          lHasKeyword := True;
          Break;
        end;
      end;

      // Se não possui atributo, ignora
      if not lHasKeyword then
        Continue;

      lParams := lMethod.GetParameters;

      if Length(lParams) <> 1 then
        raise EJsonSchemaError.CreateFmt('Visitor method "%s.%s" must receive exactly one parameter.', [pObject.ClassName, lMethod.Name]);

      if (lParams[0].ParamType = nil) or
        (lParams[0].ParamType.TypeKind <> tkClass) or
        (not lParams[0].ParamType.AsInstance.MetaclassType.InheritsFrom(TJSONValue)) then
      begin
        raise EJsonSchemaError.CreateFmt('Visitor method "%s.%s" must receive a TJSONValue descendant.', [pObject.ClassName, lMethod.Name]);
      end;

      for lAttr in lMethod.GetAttributes do
      begin
        if not (lAttr is VisitorKeywordAttribute) then
          Continue;

        lKeywordName := VisitorKeywordAttribute(lAttr).Name;

        if pTargetMap.ContainsKey(lKeywordName) then
          raise EJsonSchemaError.CreateFmt('Duplicate visitor mapping for keyword "%s".', [lKeywordName]);

        lMethodPtr.Code := lMethod.CodeAddress;
        lMethodPtr.Data := pObject;

        pTargetMap.Add(lKeywordName, TVisitorProc(lMethodPtr));
        FVisitorMethodParamType.Add(lKeywordName, TJSONValueClass(lParams[0].ParamType.AsInstance.MetaclassType));
      end;
    end;
  finally
    lContext.Free;
  end;
end;

procedure TWalker<T>.MapVisitorComponent(const pComponent: IInterface; const pComponentName: string);
var
  lObject: TObject;
begin
  if not Assigned(pComponent) then
    raise EJsonSchemaError.CreateFmt('Visitor component "%s" is not assigned.', [pComponentName]);

  try
    lObject := TObject(pComponent);
  except
    on E: Exception do
      raise EJsonSchemaError.CreateFmt('Visitor component "%s" must be object-backed to support RTTI dispatch. %s', [pComponentName, E.Message]);
  end;

  if not Assigned(lObject) then
    raise EJsonSchemaError.CreateFmt('Visitor component "%s" resolved to nil object instance.', [pComponentName]);

  MapMethodsForObject(lObject, FVisitorMethod);
end;

procedure TWalker<T>.InitializeSilentMode;
var
  lVocabMode: IDraft2019_09ValidationVocabularyMode;
  lKey: string;
begin
  if Supports(FVisitor, IDraft2019_09ValidationVocabularyMode, lVocabMode) and
    lVocabMode.IsValidationVocabularySilent then
  begin
    FSilentMode := True;
    for lKey in CValidationKeywords do
      FVisitor.AddVisitedKeyword(lKey);
  end;
end;

function TWalker<T>.IsValidationKeyword(const pKeyword: string): Boolean;
var
  lKey: string;
begin
  Result := False;
  if FSilentMode then
    for lKey in CValidationKeywords do
      if SameText(pKeyword, lKey) then
        Exit(True);
end;

function TWalker<T>.ShouldVisit(const pKeyword: string): Boolean;
begin
  Result := (not IsValidationKeyword(pKeyword)) and (not FProcessedKeywords.Contains(pKeyword));
end;

procedure TWalker<T>.ProcessPrecedence(const pPrecedence: TArray<string>);
var
  lKey: string;
  lVal: TJSONValue;
  lObj: TJSONObject;
begin
  if not (FSchema is TJSONObject) then
    Exit;

  lObj := TJSONObject(FSchema);
  for lKey in pPrecedence do
  begin
    if lObj.TryGetValue(lKey, lVal) and ShouldVisit(lKey) then
    begin
      DispatchVisit(lKey, lVal);
      FProcessedKeywords.Add(lKey);
    end;
  end;
end;

procedure TWalker<T>.ProcessPairs;
var
  lPair: TJSONPair;
  lObj: TJSONObject;
begin
  if not (FSchema is TJSONObject) then
    Exit;

  lObj := TJSONObject(FSchema);
  for lPair in lObj do
  begin
    if ShouldVisit(lPair.JsonString.Value) then
    begin
      DispatchVisit(lPair.JsonString.Value, lPair.JsonValue);
      FProcessedKeywords.Add(lPair.JsonString.Value);
    end;
  end;
end;

procedure TWalker<T>.DispatchVisit(const pName: string; const pValue: TJSONValue);
var
  lProc: TVisitorProc;
  lExpectedType: TJSONValueClass;
begin
  if not Assigned(pValue) then
    raise EJsonSchemaDispatchError.CreateFmt('Keyword "%s" has nil JSON value during dispatch.', [pName]);

  if FVisitorMethodParamType.TryGetValue(pName, lExpectedType) and
    Assigned(lExpectedType) and
    (not pValue.InheritsFrom(lExpectedType)) then
  begin
    raise EJsonSchemaDispatchError.CreateFmt('Invalid JSON type for keyword "%s": expected %s, got %s.',
      [pName, lExpectedType.ClassName, pValue.ClassName]);
  end;

  if FVisitorMethod.TryGetValue(pName, lProc) then
    lProc(pValue);
end;

procedure TWalker<T>.Walk;
var
  lRefVal: TJSONValue;
  lDraft: TDraftVersion;
  lSchemaObj: TJSONObject;
  lSchemaDraft: string;
begin
  if not Assigned(FSchema) then
    raise EJsonSchemaError.Create('Walker schema is not assigned.');

  if not Assigned(FVisitor) then
    raise EJsonSchemaError.Create('Walker visitor is not assigned.');

  // Boolean schema
  if FSchema is TJSONBool then
  begin
    FVisitor.Core.VisitBooleanSchema(TJSONBool(FSchema));
    Exit;
  end;

  if not (FSchema is TJSONObject) then
    Exit;

  lSchemaObj := TJSONObject(FSchema);
  InitializeSilentMode;

  // Detect draft version from $schema or keyword precedence
  lDraft := TDraftVersion.dvUnknown;
  if lSchemaObj.TryGetValue('$schema', lSchemaDraft) then
    lDraft := TDraftVersion.FromSchema(lSchemaDraft);

  if lDraft = TDraftVersion.dvUnknown then
  begin
    for lSchemaDraft in FVisitor.KeywordPrecedence do
    begin
      if (lSchemaDraft = '$recursiveRef') or (lSchemaDraft = '$dynamicRef') or (lSchemaDraft = 'unevaluatedProperties') then
      begin
        lDraft := TDraftVersion.dvDraft2019_09;
        Break;
      end;
    end;
  end;

  // For drafts prior to 2019‑09, process $ref first (legacy behavior)
  if lSchemaObj.TryGetValue('$ref', lRefVal) and
     not (lDraft in [TDraftVersion.dvDraft2019_09, TDraftVersion.dvDraft2020_12]) then
  begin
    DispatchVisit('$ref', lRefVal);
  end
  else
  begin
    ProcessPrecedence(FVisitor.KeywordPrecedence);
    ProcessPairs;
  end;
end;

function TWalker<T>.Visitor: T;
begin
  Result := FVisitor;
end;

function TWalker<T>.GetValidationResult: IValidationResult;
var
  lProvider: IResultProvider;
begin
  Result := nil;

  if not Assigned(FVisitor) then
    raise EJsonSchemaError.Create('Validation walker has no visitor instance.');

  // Try interface-based resolution first.
  if Supports(FVisitor, IResultProvider, lProvider) then
  begin
    Result := lProvider.GetValidationResult;
    if not Assigned(Result) then
      raise EJsonSchemaError.Create('Validation visitor returned a nil validation result.');
    Exit;
  end;

  raise EJsonSchemaError.Create('Validation visitor does not implement IResultProvider.');
end;

{ TValidationWalker }

class function TValidationWalker.New(const pSchema, pData: TJSONValue; const pCustomHint: TJSONValue; const pDraft: TDraftVersion): IWalker;
var
  lDraft: TDraftVersion;
  lSchemaDraft: string;
  lBaseURI: string;
begin
  if not Assigned(pSchema) then
    raise EJsonSchemaError.Create('Schema cannot be nil.');

  if not Assigned(pData) then
    raise EJsonSchemaError.Create('Validation data cannot be nil.');

  lBaseURI := TUtils.UriGenerateRandom;

  if pDraft <> TDraftVersion.dvUnknown then
    lDraft := pDraft
  else if (pSchema is TJSONObject) and TJSONObject(pSchema).TryGetValue('$schema', lSchemaDraft) then
    lDraft := TDraftVersion.FromSchema(lSchemaDraft)
  else
    lDraft := TDraftVersion.dvDraft2020_12;

  case lDraft of
    dvDraft6:
      Result := TWalker<TDraft6Visitor>.Create(pSchema, TDraft6Visitor.Create(pSchema, pData, lBaseURI, pCustomHint));
    dvDraft7:
      Result := TWalker<TDraft7Visitor>.Create(pSchema, TDraft7Visitor.Create(pSchema, pData, lBaseURI, pCustomHint));
    dvDraft2019_09:
      Result := TWalker<TDraft2019_09Visitor>.Create(pSchema, TDraft2019_09Visitor.Create(pSchema, pData, lBaseURI, pCustomHint));
    dvDraft2020_12:
        Result := TWalker<TDraft2020_12Visitor>.Create(pSchema, TDraft2020_12Visitor.Create(pSchema, pData, lBaseURI, pCustomHint));
  else
    Result := TWalker<TDraft2020_12Visitor>.Create(pSchema, TDraft2020_12Visitor.Create(pSchema, pData, lBaseURI, pCustomHint));
  end;
end;

end.
