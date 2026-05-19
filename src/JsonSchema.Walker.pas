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
  /// <summary>Core walker that traverses a JSON Schema document and dispatches to visitor methods.</summary>
  IWalker = interface(IInterface)
    ['{AEC155F6-90DD-479F-AD21-3B26426AF03B}']
    /// <summary>Starts the walk process. The walker will call visitor methods as it encounters keywords.</summary>
    procedure Walk;
  end;

  /// <summary>Generic walker implementation that uses RTTI to discover visitor methods and dispatches based on keyword names.</summary>
  TWalker<T: IVisitor<T>> = class(TInterfacedPersistent, IWalker)
  strict private
    const
      C_VALIDATION_KEYWORDS: array [0 .. 17] of string = (
        'type', 'multipleOf', 'maximum', 'exclusiveMaximum', 'minimum', 'exclusiveMinimum',
        'maxLength', 'minLength', 'pattern', 'maxItems', 'minItems', 'uniqueItems',
        'maxProperties', 'minProperties', 'required', 'enum', 'const', 'format'
      );
  private
    FSchema: TJSONValue;
    FVisitor: T;
    FVisitorMethod: TDictionary<string, TVisitorProc>;

    /// <summary>Dispatches the visit to the appropriate visitor method based on the keyword name.</summary>
    /// <param name="pName">The JSON Schema keyword name.</param>
    /// <param name="pValue">The JSON value associated with the keyword.</param>
    procedure DispatchVisit(const pName: string; const pValue: TJSONValue);

    /// <summary>Populates the FVisitorMethod dictionary by scanning the visitor's methods for VisitorKeyword attributes.</summary>
    procedure PopulateVisitorMethods;

    /// <summary>Maps the methods of a given object to the FVisitorMethod dictionary based on VisitorKeyword attributes.</summary>
    /// <param name="pObject">The object whose methods are to be mapped.</param>
    procedure MapMethodsForObject(const pObject: TObject);

    /// <summary>Detects the JSON Schema draft version based on the $schema keyword or the presence of draft-specific keywords.</summary>
    /// <param name="pPrecedence">The ordered list of keywords to check for draft detection.</param>
    /// <returns>The detected TDraftVersion, or dvUnknown if it cannot be determined.</returns>
    function DetectDraftVersion(const pPrecedence: TArray<string>): TDraftVersion;

    /// <summary>Determines if a given keyword is a validation keyword that should be skipped in silent mode.</summary>
    /// <param name="pKeyword">The keyword to check.</param>
    /// <param name="pSilentMode">Indicates whether silent mode is enabled.</param>
    /// <returns>True if the keyword should be skipped in silent mode, false otherwise.</returns>
    function IsValidationKeyword(const pKeyword: string; const pSilentMode: Boolean): Boolean;

    /// <summary>Determines if a given keyword should be visited based on whether it has been visited before and whether it's a validation keyword in silent mode.</summary>
    /// <param name="pKeyword">The keyword to check.</param>
    /// <param name="pSilentMode">Indicates whether silent mode is enabled.</param>
    /// <returns>True if the keyword should be visited, false otherwise.</returns>
    function ShouldVisit(const pKeyword: string; const pSilentMode: Boolean): Boolean;

    /// <summary>Processes the keywords in the specified precedence order, dispatching visits for those that should be visited.</summary>
    /// <param name="pPrecedence">The ordered list of keywords to process.</param>
    /// <param name="pSilentMode">Indicates whether silent mode is enabled, which affects whether validation keywords are visited.</param>
    procedure ProcessPrecedence(const pPrecedence: TArray<string>; const pSilentMode: Boolean);

    /// <summary>Processes all keyword-value pairs in the schema object, dispatching visits for those that should be visited.</summary>
    /// <param name="pSilentMode">Indicates whether silent mode is enabled, which affects whether validation keywords are visited.</param>
    procedure ProcessPairs(const pSilentMode: Boolean);

    /// <summary>Initializes the visitor's visited keyword set in silent mode to skip all validation keywords.</summary>
    procedure InitializeSilentMode;
  public
    /// <summary>Initializes a new walker with the given schema and visitor instance. The visitor's methods will be discovered via RTTI.</summary>
    /// <param name="pSchema">The JSON Schema document to walk.</param>
    /// <param name="pVisitor">The visitor instance whose methods will be invoked during the walk.</param>
    constructor Create(const pSchema: TJSONValue; const pVisitor: T);

    /// <summary>Frees the walker and its resources.</summary>
    destructor Destroy; override;

    /// <summary>Starts the walk process. The walker will call visitor methods as it encounters keywords.</summary>
    procedure Walk;

    /// <summary>Returns the visitor instance associated with this walker.</summary>
    function Visitor: T;
  end;

  /// <summary>Factory class for creating validation walkers.</summary>
  TValidationWalker = class
  public
    /// <summary>Creates a new validation walker for the given schema and data, automatically selecting the appropriate draft visitor based on the $schema keyword.</summary>
    /// <param name="pSchema">The JSON Schema document to validate against.</param>
    /// <param name="pData">The JSON value to validate.</param>
    /// <param name="pCustomHint">Optional JSON object with per-field custom error hints to be passed to the visitor.</param>
    /// <returns>An instance of IWalker for the specified schema and data.</returns>
    class function New(const pSchema: TJSONValue; const pData: TJSONValue; const pCustomHint: TJSONValue = nil): IWalker;
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

procedure TWalker<T>.PopulateVisitorMethods;
var
  lObject: TObject;
  lObjects: TArray<TObject>;
begin
  lObjects := [
    TObject(FVisitor.Core), TObject(FVisitor.Applicator),
    TObject(FVisitor.Validation), TObject(FVisitor.HyperSchema),
    TObject(FVisitor.RelativeJsonPointer)
  ];

  for lObject in lObjects do
  begin
    if Assigned(lObject) then
    begin
      MapMethodsForObject(lObject);
    end;
  end;
end;

procedure TWalker<T>.MapMethodsForObject(const pObject: TObject);
var
  lContext: TRttiContext;
  lMethod: TRttiMethod;
  lAttr: TCustomAttribute;
  lMethodPtr: TMethod;
begin
  for lMethod in lContext.GetType(pObject.ClassType).GetMethods do
  begin
    for lAttr in lMethod.GetAttributes do
    begin
      if (lAttr is VisitorKeywordAttribute) and (Length(lMethod.GetParameters) = 1) then
      begin
        lMethodPtr.Code := lMethod.CodeAddress;
        lMethodPtr.Data := pObject;
        FVisitorMethod.AddOrSetValue(VisitorKeywordAttribute(lAttr).Name, TVisitorProc(lMethodPtr));
      end;
    end;
  end;
end;

function TWalker<T>.DetectDraftVersion(const pPrecedence: TArray<string>): TDraftVersion;
var
  lSchemaDraft: string;
  lKey: string;
begin
  Result := TDraftVersion.dvUnknown;
  if TJSONObject(FSchema).TryGetValue('$schema', lSchemaDraft) then
  begin
    Result := TDraftVersion.FromSchema(lSchemaDraft);
  end else
  begin
    for lKey in pPrecedence do
    begin
      if (Result = TDraftVersion.dvUnknown) and
         ((lKey = '$recursiveRef') or (lKey = '$dynamicRef') or (lKey = 'unevaluatedProperties')) then
        Result := TDraftVersion.dvDraft2019_09;
    end;
  end;
end;

procedure TWalker<T>.InitializeSilentMode;
var
  lVocabMode: IDraft2019_09ValidationVocabularyMode;
  lKey: string;
begin
  if Supports(FVisitor, IDraft2019_09ValidationVocabularyMode, lVocabMode) and lVocabMode.IsValidationVocabularySilent then
  begin
    for lKey in C_VALIDATION_KEYWORDS do
    begin
      FVisitor.AddVisitedKeyword(lKey);
    end;
  end;
end;

function TWalker<T>.IsValidationKeyword(const pKeyword: string; const pSilentMode: Boolean): Boolean;
var
  lKey: string;
begin
  Result := False;
  if pSilentMode then
  begin
    for lKey in C_VALIDATION_KEYWORDS do
    begin
      if SameText(pKeyword, lKey) then
      begin
        Result := True;
      end;
    end;
  end;
end;

function TWalker<T>.ShouldVisit(const pKeyword: string; const pSilentMode: Boolean): Boolean;
begin
  Result := (not IsValidationKeyword(pKeyword, pSilentMode)) and (not FVisitor.HasVisitedKeyword(pKeyword));
end;

procedure TWalker<T>.ProcessPrecedence(const pPrecedence: TArray<string>; const pSilentMode: Boolean);
var
  lKey: string;
  lVal: TJSONValue;
begin
  for lKey in pPrecedence do
  begin
    if TJSONObject(FSchema).TryGetValue(lKey, lVal) and ShouldVisit(lKey, pSilentMode) then
    begin
      DispatchVisit(lKey, lVal);
      FVisitor.AddVisitedKeyword(lKey);
    end;
  end;
end;

procedure TWalker<T>.ProcessPairs(const pSilentMode: Boolean);
var
  lPair: TJSONPair;
begin
  for lPair in TJSONObject(FSchema) do
  begin
    if ShouldVisit(lPair.JsonString.Value, pSilentMode) then
    begin
      DispatchVisit(lPair.JsonString.Value, lPair.JsonValue);
    end;
  end;
end;

procedure TWalker<T>.Walk;
var
  lRefVal: TJSONValue;
  lDraft: TDraftVersion;
  lSilent: Boolean;
  lVocab: IDraft2019_09ValidationVocabularyMode;
begin
  if (not Assigned(FSchema)) or (not Assigned(FVisitor)) then
    Exit;

  if FSchema is TJSONBool then
  begin
    FVisitor.Core.VisitBooleanSchema(TJSONBool(FSchema));
  end else if FSchema is TJSONObject then
  begin
    lDraft := DetectDraftVersion(FVisitor.KeywordPrecedence);
    lSilent := Supports(FVisitor, IDraft2019_09ValidationVocabularyMode, lVocab) and lVocab.IsValidationVocabularySilent;

    InitializeSilentMode;

    if TJSONObject(FSchema).TryGetValue('$ref', lRefVal) and
       (not (lDraft in [TDraftVersion.dvDraft2019_09, TDraftVersion.dvDraft2020_12])) then
    begin
      DispatchVisit('$ref', lRefVal);
    end else
    begin
      ProcessPrecedence(FVisitor.KeywordPrecedence, lSilent);
      ProcessPairs(lSilent);
    end;
  end;
end;

procedure TWalker<T>.DispatchVisit(const pName: string; const pValue: TJSONValue);
begin
  if FVisitorMethod.ContainsKey(pName) then
    FVisitorMethod.Items[pName](pValue);
end;

function TWalker<T>.Visitor: T;
begin
  Result := FVisitor;
end;

{ TValidationWalker }

class function TValidationWalker.New(const pSchema, pData: TJSONValue; const pCustomHint: TJSONValue): IWalker;
var
  lDraft: TDraftVersion;
  lSchema: string;
  lBase: string;
begin
  pSchema.TryGetValue('$schema', lSchema);
  lDraft := TDraftVersion.FromSchema(lSchema);
  lBase := TUtils.UriGenerateRandom;

  case lDraft of
    dvDraft6:
      Result := TWalker<TDraft6Visitor>.Create(pSchema, TDraft6Visitor.Create(pSchema, pData, lBase, pCustomHint));
    dvDraft7:
      Result := TWalker<TDraft7Visitor>.Create(pSchema, TDraft7Visitor.Create(pSchema, pData, lBase, pCustomHint));
    dvDraft2019_09:
      Result := TWalker<TDraft2019_09Visitor>.Create(pSchema, TDraft2019_09Visitor.Create(pSchema, pData, lBase, pCustomHint));
    dvDraft2020_12:
      Result := TWalker<TDraft2020_12Visitor>.Create(pSchema, TDraft2020_12Visitor.Create(pSchema, pData, lBase, pCustomHint));
  else
    Result := TWalker<TDraft2020_12Visitor>.Create(pSchema, TDraft2020_12Visitor.Create(pSchema, pData, lBase, pCustomHint));
  end;
end;

end.
