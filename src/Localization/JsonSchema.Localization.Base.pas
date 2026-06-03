unit JsonSchema.Localization.Base;

(*
--------------------------------------------------------------------------------
Provides a base abstract class for all localization implementations,
dispatching translations dynamically by keyword.
--------------------------------------------------------------------------------
*)

interface

uses
  System.Generics.Collections,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Localization.Enums,
  JsonSchema.Localization.Interfaces;

type
  /// <summary>Signature of method pointers used to translate specific keywords.</summary>
  TTranslateMethod = function(const pError: IValidationError): TTranslation of object;

  /// <summary>Abstract base class implementing the ILocalization contract using a dispatcher.</summary>
  TLocalizationBase = class abstract(TInterfacedObject, ILocalization)
  strict private
    FLocale: TLocale;
    FMethods: TDictionary<string, TTranslateMethod>;
  protected
    function GetLocale: TLocale; virtual;
    procedure RegisterKeywordTranslator(const pKeywordName: string; pMethod: TTranslateMethod);

    /// <summary>Fallback translator used when the keyword is not recognized by the dispatcher.</summary>
    function TranslateFallback(const pError: IValidationError): TTranslation; virtual;
  public
    constructor Create(const pLocale: TLocale);
    destructor Destroy; override;
    function Translate(const pError: IValidationError): TTranslation; virtual;

    /// <summary>Translates a 'type' validation error.</summary>
    function TranslateType(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'minLength' validation error.</summary>
    function TranslateMinLength(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates an 'enum' validation error.</summary>
    function TranslateEnum(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'const' validation error.</summary>
    function TranslateConst(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'required' validation error.</summary>
    function TranslateRequired(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'minimum' validation error.</summary>
    function TranslateMinimum(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'maximum' validation error.</summary>
    function TranslateMaximum(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'maxLength' validation error.</summary>
    function TranslateMaxLength(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'minItems' validation error.</summary>
    function TranslateMinItems(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'maxItems' validation error.</summary>
    function TranslateMaxItems(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'multipleOf' validation error.</summary>
    function TranslateMultipleOf(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates an 'exclusiveMaximum' validation error.</summary>
    function TranslateExclusiveMaximum(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates an 'exclusiveMinimum' validation error.</summary>
    function TranslateExclusiveMinimum(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'pattern' validation error.</summary>
    function TranslatePattern(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates an 'items' validation error.</summary>
    function TranslateItems(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates an 'additionalItems' validation error.</summary>
    function TranslateAdditionalItems(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'uniqueItems' validation error.</summary>
    function TranslateUniqueItems(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'contains' validation error.</summary>
    function TranslateContains(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'maxProperties' validation error.</summary>
    function TranslateMaxProperties(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'minProperties' validation error.</summary>
    function TranslateMinProperties(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'properties' validation error.</summary>
    function TranslateProperties(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'patternProperties' validation error.</summary>
    function TranslatePatternProperties(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates an 'additionalProperties' validation error.</summary>
    function TranslateAdditionalProperties(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'dependencies' validation error.</summary>
    function TranslateDependencies(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'propertyNames' validation error.</summary>
    function TranslatePropertyNames(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates an 'allOf' validation error.</summary>
    function TranslateAllOf(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates an 'anyOf' validation error.</summary>
    function TranslateAnyOf(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'oneOf' validation error.</summary>
    function TranslateOneOf(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a 'not' validation error.</summary>
    function TranslateNot(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a '$ref' validation error.</summary>
    function TranslateRef(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates a '$schema' validation error.</summary>
    function TranslateSchema(const pError: IValidationError): TTranslation; virtual; abstract;

    /// <summary>Translates an '$id' (or 'id') validation error.</summary>
    function TranslateId(const pError: IValidationError): TTranslation; virtual; abstract;

    property Locale: TLocale read GetLocale;
  end;

implementation

{ TLocalizationBase }

constructor TLocalizationBase.Create(const pLocale: TLocale);
begin
  inherited Create;
  FLocale := pLocale;
  FMethods := TDictionary<string, TTranslateMethod>.Create;

  // Register native keyword dispatch methods
  RegisterKeywordTranslator(KEYWORD_TYPE, TranslateType);
  RegisterKeywordTranslator(KEYWORD_MINLENGTH, TranslateMinLength);
  RegisterKeywordTranslator(KEYWORD_ENUM, TranslateEnum);
  RegisterKeywordTranslator(KEYWORD_CONST, TranslateConst);
  RegisterKeywordTranslator(KEYWORD_REQUIRED, TranslateRequired);
  RegisterKeywordTranslator(KEYWORD_MINIMUM, TranslateMinimum);
  RegisterKeywordTranslator(KEYWORD_MAXIMUM, TranslateMaximum);
  RegisterKeywordTranslator(KEYWORD_MAXLENGTH, TranslateMaxLength);
  RegisterKeywordTranslator(KEYWORD_MINITEMS, TranslateMinItems);
  RegisterKeywordTranslator(KEYWORD_MAXITEMS, TranslateMaxItems);

  RegisterKeywordTranslator(KEYWORD_MULTIPLEOF, TranslateMultipleOf);
  RegisterKeywordTranslator(KEYWORD_EXCLUSIVEMAXIMUM, TranslateExclusiveMaximum);
  RegisterKeywordTranslator(KEYWORD_EXCLUSIVEMINIMUM, TranslateExclusiveMinimum);
  RegisterKeywordTranslator(KEYWORD_PATTERN, TranslatePattern);
  RegisterKeywordTranslator(KEYWORD_ITEMS, TranslateItems);
  RegisterKeywordTranslator(KEYWORD_ADDITIONALITEMS, TranslateAdditionalItems);
  RegisterKeywordTranslator(KEYWORD_UNIQUEITEMS, TranslateUniqueItems);
  RegisterKeywordTranslator(KEYWORD_CONTAINS, TranslateContains);
  RegisterKeywordTranslator(KEYWORD_MAXPROPERTIES, TranslateMaxProperties);
  RegisterKeywordTranslator(KEYWORD_MINPROPERTIES, TranslateMinProperties);
  RegisterKeywordTranslator(KEYWORD_PROPERTIES, TranslateProperties);
  RegisterKeywordTranslator(KEYWORD_PATTERNPROPERTIES, TranslatePatternProperties);
  RegisterKeywordTranslator(KEYWORD_ADDITIONALPROPERTIES, TranslateAdditionalProperties);
  RegisterKeywordTranslator(KEYWORD_DEPENDENCIES, TranslateDependencies);
  RegisterKeywordTranslator(KEYWORD_PROPERTYNAMES, TranslatePropertyNames);
  RegisterKeywordTranslator(KEYWORD_ALLOF, TranslateAllOf);
  RegisterKeywordTranslator(KEYWORD_ANYOF, TranslateAnyOf);
  RegisterKeywordTranslator(KEYWORD_ONEOF, TranslateOneOf);
  RegisterKeywordTranslator(KEYWORD_NOT, TranslateNot);
  RegisterKeywordTranslator(KEYWORD_REF, TranslateRef);
  RegisterKeywordTranslator(KEYWORD_SCHEMA, TranslateSchema);
  RegisterKeywordTranslator(KEYWORD_ID, TranslateId);
  RegisterKeywordTranslator(KEYWORD_ID_LEGACY, TranslateId);
end;

destructor TLocalizationBase.Destroy;
begin
  FMethods.Free;
  inherited Destroy;
end;

function TLocalizationBase.GetLocale: TLocale;
begin
  Result := FLocale;
end;

procedure TLocalizationBase.RegisterKeywordTranslator(const pKeywordName: string; pMethod: TTranslateMethod);
begin
  FMethods.AddOrSetValue(pKeywordName, pMethod);
end;

function TLocalizationBase.Translate(const pError: IValidationError): TTranslation;
var
  lMethod: TTranslateMethod;
begin
  if FMethods.TryGetValue(pError.Keyword, lMethod) then
    Result := lMethod(pError)
  else
    Result := TranslateFallback(pError);
end;

function TLocalizationBase.TranslateFallback(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Validation failed for keyword: ' + pError.Keyword,
    'Check the JSON Schema documentation for this keyword'
  );
end;

end.
