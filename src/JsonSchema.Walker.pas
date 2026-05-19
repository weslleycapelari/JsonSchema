unit JsonSchema.Walker;

interface

uses
  System.JSON,
  System.Classes,
  System.Generics.Collections,
  JsonSchema.Visitors.Types,
  JsonSchema.Visitors.Interfaces,
  JsonSchema.Walker.Types;

type
  /// <summary>Contract for a schema walker that dispatches keyword visits.</summary>
  IWalker = interface(IInterface)
    ['{AEC155F6-90DD-479F-AD21-3B26426AF03B}']
    procedure Walk;
  end;

  /// <summary>Generic schema walker that uses RTTI to discover and dispatch visitor methods by keyword.</summary>
  TWalker<T: IVisitor<T>> = class(TInterfacedPersistent, IWalker)
  private
    FSchema: TJSONValue;
    FVisitor: T;
    FVisitorMethod: TDictionary<string, TVisitorProc>;

    procedure DispatchVisit(const pName: string; const pValue: TJSONValue);
    procedure PopulateVisitorMethods;
  public
    /// <summary>Creates the walker for the given schema node, binding it to the supplied visitor.</summary>
    constructor Create(const pSchema: TJSONValue; const pVisitor: T);
    destructor Destroy; override;

    /// <summary>Iterates over every keyword in the schema and dispatches the matching visitor method.</summary>
    procedure Walk;
    function Visitor: T;
  end;

  /// <summary>Factory that builds a correctly versioned IWalker for a root schema document.</summary>
  TValidationWalker = class
  public
    /// <summary>Detects the draft version from the schema and returns the appropriate walker.</summary>
    class function New(const pSchema, pData: TJSONValue; const pCustomHint: TJSONValue = nil): IWalker;
  end;

implementation

uses
  System.Rtti,
  System.SysUtils,
  System.TypInfo,
  JsonSchema.Common.Utils,
  JsonSchema.Validation.Base,
  JsonSchema.Validation.Draft6,
  JsonSchema.Validation.Draft7,
  JsonSchema.Validation.Draft2019_09,
  JsonSchema.Validation.Draft2020_12;

{ TWalker<T> }

constructor TWalker<T>.Create(const pSchema: TJSONValue; const pVisitor: T);
begin
  FSchema := pSchema;
  FVisitor := pVisitor;
  FVisitorMethod := TDictionary<string, TVisitorProc>.Create;

  PopulateVisitorMethods;
end;

destructor TWalker<T>.Destroy;
begin
  FVisitorMethod.Free;
  inherited;
end;

procedure TWalker<T>.DispatchVisit(const pName: string; const pValue: TJSONValue);
begin
  if not FVisitorMethod.ContainsKey(pName) then
    Exit;

  FVisitorMethod.Items[pName](pValue);
end;

procedure TWalker<T>.PopulateVisitorMethods;
var
  lType: TRttiType;
  lMethod: TRttiMethod;
  lObject: TObject;
  lObjects: TArray<TObject>;
  lContext: TRttiContext;
  lMethodPtr: TMethod;
  lAttribute: TCustomAttribute;
  lParameters: TArray<TRttiParameter>;
  lKeyword: string;
begin
  lContext := TRttiContext.Create;
  lObjects := [
    TObject(FVisitor.Core),
    TObject(FVisitor.Applicator),
    TObject(FVisitor.Validation),
    TObject(FVisitor.HyperSchema),
    TObject(FVisitor.RelativeJsonPointer)
  ];

  for lObject in lObjects do
  begin
    if Assigned(lObject) then
    begin
      lType := lContext.GetType(lObject.ClassType);

      // GetMethods returns methods in VMT order (base first, then derived/reintroduce).
      // AddOrSetValue ensures the derived method wins over the base class method for the same keyword.
      for lMethod in lType.GetMethods do
      begin
        for lAttribute in lMethod.GetAttributes do
        begin
          if lAttribute is VisitorKeywordAttribute then
          begin
            lKeyword := VisitorKeywordAttribute(lAttribute).Name;
            if not lKeyword.IsEmpty then
            begin
              lParameters := lMethod.GetParameters;
              if Length(lParameters) = 1 then
              begin
                lMethodPtr := default(TMethod);
                lMethodPtr.Code := lMethod.CodeAddress;
                lMethodPtr.Data := lObject;
                FVisitorMethod.AddOrSetValue(lKeyword, TVisitorProc(lMethodPtr));
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

function TWalker<T>.Visitor: T;
begin
  Result := FVisitor;
end;

procedure TWalker<T>.Walk;
const
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
  lPair: TJSONPair;
  lKeyword: string;
  lJsonValue: TJSONValue;
  lRefValue: TJSONValue;
  lHasRef: Boolean;
  lPrecedence: TArray<string>;
  lPrecedentKeyword: string;
  lSchemaDraft: string;
  lDraftVersion: TDraftVersion;
  lAllowSiblingKeywordsWithRef: Boolean;
  lValidationKeyword: string;
  lDraft2019VocabularyMode: IDraft2019_09ValidationVocabularyMode;
  lSilentValidationMode: Boolean;
  lIsValidationKeyword: Boolean;
begin
  if not Assigned(FSchema) then
    Exit;

  if not Assigned(FVisitor) then
    Exit;

  if (FSchema is TJSONBool) then
  begin
    FVisitor.Core.VisitBooleanSchema(TJSONBool(FSchema));
    Exit;
  end;

  if not (FSchema is TJSONObject) then
    Exit;

  lPrecedence := FVisitor.KeywordPrecedence;

  lDraftVersion := TDraftVersion.dvUnknown;
  if TJSONObject(FSchema).TryGetValue('$schema', lSchemaDraft) then
    lDraftVersion := TDraftVersion.FromSchema(lSchemaDraft)
  else
  begin
    for lPrecedentKeyword in lPrecedence do
      if (lDraftVersion = TDraftVersion.dvUnknown) and
         ((lPrecedentKeyword = '$recursiveRef') or (lPrecedentKeyword = '$dynamicRef') or
          (lPrecedentKeyword = 'unevaluatedProperties')) then
        lDraftVersion := TDraftVersion.dvDraft2019_09;
  end;

  lAllowSiblingKeywordsWithRef := lDraftVersion in [TDraftVersion.dvDraft2019_09, TDraftVersion.dvDraft2020_12];

  lSilentValidationMode := Supports(FVisitor, IDraft2019_09ValidationVocabularyMode, lDraft2019VocabularyMode) and
    lDraft2019VocabularyMode.IsValidationVocabularySilent;

  if lSilentValidationMode then
    for lValidationKeyword in CValidationKeywords do
      FVisitor.AddVisitedKeyword(lValidationKeyword);

  lHasRef := TJSONObject(FSchema).TryGetValue('$ref', lRefValue);
  if lHasRef and (not lAllowSiblingKeywordsWithRef) then
  begin
    DispatchVisit('$ref', lRefValue);
    Exit;
  end;

  if Length(lPrecedence) > 0 then
  begin
    for lPrecedentKeyword in lPrecedence do
    begin
      if TJSONObject(FSchema).TryGetValue(lPrecedentKeyword, lJsonValue) then
      begin
        lIsValidationKeyword := False;
        if lSilentValidationMode then
          for lValidationKeyword in CValidationKeywords do
            if not lIsValidationKeyword and SameText(lPrecedentKeyword, lValidationKeyword) then
              lIsValidationKeyword := True;

        if not lIsValidationKeyword and not FVisitor.HasVisitedKeyword(lPrecedentKeyword) then
        begin
          DispatchVisit(lPrecedentKeyword, lJsonValue);
          FVisitor.AddVisitedKeyword(lPrecedentKeyword);
        end;
      end;
    end;
  end;

  lSilentValidationMode := Supports(FVisitor, IDraft2019_09ValidationVocabularyMode, lDraft2019VocabularyMode) and
    lDraft2019VocabularyMode.IsValidationVocabularySilent;

  if lSilentValidationMode then
    for lValidationKeyword in CValidationKeywords do
      FVisitor.AddVisitedKeyword(lValidationKeyword);

  for lPair in TJSONObject(FSchema) do
  begin
    lKeyword := lPair.JsonString.Value;

    lIsValidationKeyword := False;
    if lSilentValidationMode then
      for lValidationKeyword in CValidationKeywords do
        if not lIsValidationKeyword and SameText(lKeyword, lValidationKeyword) then
          lIsValidationKeyword := True;

    if not lIsValidationKeyword and not FVisitor.HasVisitedKeyword(lKeyword) then
      DispatchVisit(lKeyword, lPair.JsonValue);
  end;
end;

{ TValidationWalker }

class function TValidationWalker.New(const pSchema, pData: TJSONValue; const pCustomHint: TJSONValue): IWalker;
var
  lDraft: TDraftVersion;
  lSchema: string;
  lBaseURI: string;
begin
  pSchema.TryGetValue('$schema', lSchema);
  lDraft := TDraftVersion.FromSchema(lSchema);
  lBaseURI := TUtils.UriGenerateRandom;

  case lDraft of
    dvDraft6:       Result := TWalker<TDraft6Visitor>.Create(pSchema, TDraft6Visitor.Create(pSchema, pData, lBaseURI, pCustomHint));
    dvDraft7:       Result := TWalker<TDraft7Visitor>.Create(pSchema, TDraft7Visitor.Create(pSchema, pData, lBaseURI, pCustomHint));
    dvDraft2019_09: Result := TWalker<TDraft2019_09Visitor>.Create(pSchema, TDraft2019_09Visitor.Create(pSchema, pData, lBaseURI, pCustomHint));
    dvDraft2020_12: Result := TWalker<TDraft2020_12Visitor>.Create(pSchema, TDraft2020_12Visitor.Create(pSchema, pData, lBaseURI, pCustomHint));
  else
    Result := TWalker<TDraft2020_12Visitor>.Create(pSchema, TDraft2020_12Visitor.Create(pSchema, pData, lBaseURI, pCustomHint));
  end;
end;

end.
