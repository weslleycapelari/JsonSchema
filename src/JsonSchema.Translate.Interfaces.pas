unit JsonSchema.Translate.Interfaces;

interface

uses
  JsonSchema.Translate.Types;

type
  ITranslate = interface(IInterface)
    ['{72BDBA2B-8DE8-4ABD-B00A-37B1F78AF13B}']
    // --- Erros de Tipo e Valor ---
    function TranslateInvalidType: TErrorMessage;
    function TranslateEnumValueMismatch: TErrorMessage;
    function TranslateConstValueMismatch: TErrorMessage;

    // --- Erros Num�ricos ---
    function TranslateMultipleOf: TErrorMessage;
    function TranslateMaximum: TErrorMessage;
    function TranslateExclusiveMaximum: TErrorMessage;
    function TranslateMinimum: TErrorMessage;
    function TranslateExclusiveMinimum: TErrorMessage;

    // --- Erros de String ---
    function TranslateMaxLength: TErrorMessage;
    function TranslateMinLength: TErrorMessage;
    function TranslatePattern: TErrorMessage;
    function TranslateInvalidFormat: TErrorMessage;

    // --- Erros de Array ---
    function TranslateMaxItems: TErrorMessage;
    function TranslateMinItems: TErrorMessage;
    function TranslateUniqueItems: TErrorMessage;
    function TranslateContains: TErrorMessage;
    function TranslateMaxContains: TErrorMessage;
    function TranslateMinContains: TErrorMessage;
    function TranslateUnevaluatedItems: TErrorMessage;

    // --- Erros de Objeto ---
    function TranslateMaxProperties: TErrorMessage;
    function TranslateMinProperties: TErrorMessage;
    function TranslateRequiredPropertyMissing: TErrorMessage;
    function TranslateDependentRequired: TErrorMessage;
    function TranslateUnevaluatedProperties: TErrorMessage;
    function TranslateInvalidPropertyName: TErrorMessage;

    // --- Erros de Aplicadores ---
    function TranslateAllOf: TErrorMessage;
    function TranslateAnyOf: TErrorMessage;
    function TranslateOneOf_NoMatch: TErrorMessage;
    function TranslateOneOf_MultipleMatches: TErrorMessage;
    function TranslateNot: TErrorMessage;
    function TranslateSchemaIsFalse: TErrorMessage;

    // --- Fallback ---
    function TranslateUnresolvedReference: TErrorMessage;
    function TranslateUnsupportedVocabulary: TErrorMessage;
    function TranslateUnknown: TErrorMessage;
  end;

implementation

end.
