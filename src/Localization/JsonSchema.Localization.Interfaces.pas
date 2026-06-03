unit JsonSchema.Localization.Interfaces;

(*
--------------------------------------------------------------------------------
Defines the translation structures and localization plugin interface.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Localization.Enums;

type
  /// <summary>Represents localized error message and resolution suggestion texts.</summary>
  TTranslation = record
    /// <summary>The localized error description.</summary>
    Message: string;

    /// <summary>The suggested steps to resolve the validation error.</summary>
    Resolution: string;

    constructor Create(const pMessage, pResolution: string);
  end;

  /// <summary>Contract for localized translators handling validation errors.</summary>
  ILocalization = interface
    ['{E8A3756D-6DF0-4D88-BFEA-1B862C1D2A4F}']
    function GetLocale: TLocale;
    function Translate(const pError: IValidationError): TTranslation;
    
    /// <summary>Translates a 'type' validation error.</summary>
    function TranslateType(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'minLength' validation error.</summary>
    function TranslateMinLength(const pError: IValidationError): TTranslation;

    /// <summary>Translates an 'enum' validation error.</summary>
    function TranslateEnum(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'const' validation error.</summary>
    function TranslateConst(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'required' validation error.</summary>
    function TranslateRequired(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'minimum' validation error.</summary>
    function TranslateMinimum(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'maximum' validation error.</summary>
    function TranslateMaximum(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'maxLength' validation error.</summary>
    function TranslateMaxLength(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'minItems' validation error.</summary>
    function TranslateMinItems(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'maxItems' validation error.</summary>
    function TranslateMaxItems(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'multipleOf' validation error.</summary>
    function TranslateMultipleOf(const pError: IValidationError): TTranslation;

    /// <summary>Translates an 'exclusiveMaximum' validation error.</summary>
    function TranslateExclusiveMaximum(const pError: IValidationError): TTranslation;

    /// <summary>Translates an 'exclusiveMinimum' validation error.</summary>
    function TranslateExclusiveMinimum(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'pattern' validation error.</summary>
    function TranslatePattern(const pError: IValidationError): TTranslation;

    /// <summary>Translates an 'items' validation error.</summary>
    function TranslateItems(const pError: IValidationError): TTranslation;

    /// <summary>Translates an 'additionalItems' validation error.</summary>
    function TranslateAdditionalItems(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'uniqueItems' validation error.</summary>
    function TranslateUniqueItems(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'contains' validation error.</summary>
    function TranslateContains(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'maxProperties' validation error.</summary>
    function TranslateMaxProperties(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'minProperties' validation error.</summary>
    function TranslateMinProperties(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'properties' validation error.</summary>
    function TranslateProperties(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'patternProperties' validation error.</summary>
    function TranslatePatternProperties(const pError: IValidationError): TTranslation;

    /// <summary>Translates an 'additionalProperties' validation error.</summary>
    function TranslateAdditionalProperties(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'dependencies' validation error.</summary>
    function TranslateDependencies(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'propertyNames' validation error.</summary>
    function TranslatePropertyNames(const pError: IValidationError): TTranslation;

    /// <summary>Translates an 'allOf' validation error.</summary>
    function TranslateAllOf(const pError: IValidationError): TTranslation;

    /// <summary>Translates an 'anyOf' validation error.</summary>
    function TranslateAnyOf(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'oneOf' validation error.</summary>
    function TranslateOneOf(const pError: IValidationError): TTranslation;

    /// <summary>Translates a 'not' validation error.</summary>
    function TranslateNot(const pError: IValidationError): TTranslation;

    /// <summary>Translates a '$ref' validation error.</summary>
    function TranslateRef(const pError: IValidationError): TTranslation;

    /// <summary>Translates a '$schema' validation error.</summary>
    function TranslateSchema(const pError: IValidationError): TTranslation;

    /// <summary>Translates an '$id' (or 'id') validation error.</summary>
    function TranslateId(const pError: IValidationError): TTranslation;

    property Locale: TLocale read GetLocale;
  end;

implementation

{ TTranslation }

constructor TTranslation.Create(const pMessage, pResolution: string);
begin
  Message := pMessage;
  Resolution := pResolution;
end;

end.
