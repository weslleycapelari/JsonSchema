unit JsonSchema.Translate.enUS;

interface

uses
  JsonSchema.Translate.Types,
  JsonSchema.Translate.Interfaces;

type
  TTranslate_enUS = class(TInterfacedObject, ITranslate)
    // --- Erros de Tipo e Valor ---
    [TranslateError(vetInvalidType)]
    function TranslateInvalidType: TErrorMessage;
    [TranslateError(vetEnumValueMismatch)]
    function TranslateEnumValueMismatch: TErrorMessage;
    [TranslateError(vetConstValueMismatch)]
    function TranslateConstValueMismatch: TErrorMessage;

    // --- Erros Num�ricos ---
    [TranslateError(vetMultipleOf)]
    function TranslateMultipleOf: TErrorMessage;
    [TranslateError(vetMaximum)]
    function TranslateMaximum: TErrorMessage;
    [TranslateError(vetExclusiveMaximum)]
    function TranslateExclusiveMaximum: TErrorMessage;
    [TranslateError(vetMinimum)]
    function TranslateMinimum: TErrorMessage;
    [TranslateError(vetExclusiveMinimum)]
    function TranslateExclusiveMinimum: TErrorMessage;

    // --- Erros de String ---
    [TranslateError(vetMaxLength)]
    function TranslateMaxLength: TErrorMessage;
    [TranslateError(vetMinLength)]
    function TranslateMinLength: TErrorMessage;
    [TranslateError(vetPattern)]
    function TranslatePattern: TErrorMessage;
    [TranslateError(vetInvalidFormat)]
    function TranslateInvalidFormat: TErrorMessage;

    // --- Erros de Array ---
    [TranslateError(vetMaxItems)]
    function TranslateMaxItems: TErrorMessage;
    [TranslateError(vetMinItems)]
    function TranslateMinItems: TErrorMessage;
    [TranslateError(vetUniqueItems)]
    function TranslateUniqueItems: TErrorMessage;
    [TranslateError(vetContains)]
    function TranslateContains: TErrorMessage;
    [TranslateError(vetMaxContains)]
    function TranslateMaxContains: TErrorMessage;
    [TranslateError(vetMinContains)]
    function TranslateMinContains: TErrorMessage;
    [TranslateError(vetUnevaluatedItems)]
    function TranslateUnevaluatedItems: TErrorMessage;

    // --- Erros de Objeto ---
    [TranslateError(vetMaxProperties)]
    function TranslateMaxProperties: TErrorMessage;
    [TranslateError(vetMinProperties)]
    function TranslateMinProperties: TErrorMessage;
    [TranslateError(vetRequiredPropertyMissing)]
    function TranslateRequiredPropertyMissing: TErrorMessage;
    [TranslateError(vetDependentRequired)]
    function TranslateDependentRequired: TErrorMessage;
    [TranslateError(vetUnevaluatedProperties)]
    function TranslateUnevaluatedProperties: TErrorMessage;
    [TranslateError(vetInvalidPropertyName)]
    function TranslateInvalidPropertyName: TErrorMessage;

    // --- Erros de Aplicadores ---
    [TranslateError(vetAllOf)]
    function TranslateAllOf: TErrorMessage;
    [TranslateError(vetAnyOf)]
    function TranslateAnyOf: TErrorMessage;
    [TranslateError(vetOneOf_NoMatch)]
    function TranslateOneOf_NoMatch: TErrorMessage;
    [TranslateError(vetOneOf_MultipleMatches)]
    function TranslateOneOf_MultipleMatches: TErrorMessage;
    [TranslateError(vetNot)]
    function TranslateNot: TErrorMessage;
    [TranslateError(vetSchemaIsFalse)]
    function TranslateSchemaIsFalse: TErrorMessage;

    // --- Fallback ---
    [TranslateError(vetUnresolvedReference)]
    function TranslateUnresolvedReference: TErrorMessage;
    [TranslateError(vetUnsupportedVocabulary)]
    function TranslateUnsupportedVocabulary: TErrorMessage;
    [TranslateError(vetUnknown)]
    function TranslateUnknown: TErrorMessage;
  end;

implementation

{ TTranslate_enUS }

function TTranslate_enUS.TranslateAllOf: TErrorMessage;
begin
  Result.Error := 'The value is not valid against all subschemas in "allOf". Failed at index %d.';
  Result.Hint  := 'The value must meet all conditions specified in the schemas within "allOf".';
end;

function TTranslate_enUS.TranslateAnyOf: TErrorMessage;
begin
  Result.Error := 'The value is not valid against any of the subschemas in "anyOf".';
  Result.Hint  := 'The value must meet at least one of the conditions specified in the schemas within "anyOf".';
end;

function TTranslate_enUS.TranslateConstValueMismatch: TErrorMessage;
begin
  Result.Error := 'The value does not match the expected constant value';
  Result.Hint  := 'The value must be exactly equal to %s';
end;

function TTranslate_enUS.TranslateContains: TErrorMessage;
begin
  Result.Error := 'The array does not contain any items that match the "contains" schema.';
  Result.Hint  := 'Add at least one item to the array that is valid according to the schema specified in "contains".';
end;

function TTranslate_enUS.TranslateDependentRequired: TErrorMessage;
begin
  Result.Error := 'The presence of the "%s" property requires that the "%s" property(s) also be present.';
  Result.Hint  := 'When the "%s" property exists, ensure that the "%s" properties are also included in the object.';
end;

function TTranslate_enUS.TranslateEnumValueMismatch: TErrorMessage;
begin
  Result.Error := 'The value does not match any of the allowed values in the enumeration';
  Result.Hint  := 'The value must be exactly one of the following: %s';
end;

function TTranslate_enUS.TranslateExclusiveMaximum: TErrorMessage;
begin
  Result.Error := 'The value is equal to or exceeds the maximum unique allowed of %s';
  Result.Hint  := 'The value must be less than %s';
end;

function TTranslate_enUS.TranslateExclusiveMinimum: TErrorMessage;
begin
  Result.Error := 'The value is equal to or less than the minimum unique allowed of %s';
  Result.Hint  := 'The value must be greater than %s';
end;

function TTranslate_enUS.TranslateInvalidFormat: TErrorMessage;
begin
  Result.Error := 'The value does not match the expected format of "%s".';
  Result.Hint  := 'Correct the value so that it follows the format "%s". For example, a date must be in the format "YYYY-MM-DD".';
end;

function TTranslate_enUS.TranslateInvalidPropertyName: TErrorMessage;
begin
  Result.Error := 'The property name "%s" is not valid according to the "propertyNames" schema.';
  Result.Hint  := 'Rename the property "%s" so that it matches the schema defined in "propertyNames".';
end;

function TTranslate_enUS.TranslateInvalidType: TErrorMessage;
begin
  Result.Error := 'The provided value does not match the expected type. Expected: "%s", found: "%s"';
  Result.Hint  := 'Verify that the field value is formatted correctly for the "%s" type. For example, numeric values should not be enclosed in quotes';
end;

function TTranslate_enUS.TranslateMaxContains: TErrorMessage;
begin
  Result.Error := 'The array contains %d items that match the "contains" schema, exceeding the maximum of %d.';
  Result.Hint  := 'Remove excess matching items. The maximum allowed is %d.';
end;

function TTranslate_enUS.TranslateMaximum: TErrorMessage;
begin
  Result.Error := 'The value exceeds the maximum allowed value of %s';
  Result.Hint  := 'Value must be less than or equal to %s';
end;

function TTranslate_enUS.TranslateMaxItems: TErrorMessage;
begin
  Result.Error := 'Array exceeds maximum of %d items';
  Result.Hint  := 'The array must not contain more than %d items';
end;

function TTranslate_enUS.TranslateMaxLength: TErrorMessage;
begin
  Result.Error := 'The string contains more than the maximum of %d characters';
  Result.Hint  := 'The string must have a maximum of %d characters';
end;

function TTranslate_enUS.TranslateMaxProperties: TErrorMessage;
begin
  Result.Error := 'The object contains more than the maximum of %d properties';
  Result.Hint  := 'The object must contain a maximum of %d properties';
end;

function TTranslate_enUS.TranslateMinContains: TErrorMessage;
begin
  Result.Error := 'The array contains %d items that match the "contains" schema, which is less than the minimum of %d.';
  Result.Hint  := 'Add more matching items. The minimum required is %d.';
end;

function TTranslate_enUS.TranslateMinimum: TErrorMessage;
begin
  Result.Error := 'The value is less than the minimum allowed value of %s';
  Result.Hint  := 'Value must be greater than or equal to %s';
end;

function TTranslate_enUS.TranslateMinItems: TErrorMessage;
begin
  Result.Error := 'The array is less than the minimum of %d items';
  Result.Hint  := 'The array must contain at least %d items';
end;

function TTranslate_enUS.TranslateMinLength: TErrorMessage;
begin
  Result.Error := 'The string contains fewer than the minimum of %d characters';
  Result.Hint  := 'The string must have at least %d characters';
end;

function TTranslate_enUS.TranslateMinProperties: TErrorMessage;
begin
  Result.Error := 'The object contains fewer than the minimum of %d properties';
  Result.Hint  := 'The object must contain at least %d properties';
end;

function TTranslate_enUS.TranslateMultipleOf: TErrorMessage;
begin
  Result.Error := 'The value is not a multiple of %s';
  Result.Hint  := 'Adjust the value so that it is divisible by %s without a remainder';
end;

function TTranslate_enUS.TranslateNot: TErrorMessage;
begin
  Result.Error := 'The value was successfully validated by the schema in "not", which is not allowed.';
  Result.Hint  := 'The value must not be valid according to the schema specified within the "not" clause.';
end;

function TTranslate_enUS.TranslateOneOf_MultipleMatches: TErrorMessage;
begin
  Result.Error := 'The value is valid against multiple sub-schemas in "oneOf".';
  Result.Hint  := 'The value must match exactly one of the schemas defined in "oneOf". Currently, it matches more than one.';
end;

function TTranslate_enUS.TranslateOneOf_NoMatch: TErrorMessage;
begin
  Result.Error := 'The value is not valid against any of the subschemas in "oneOf".';
  Result.Hint  := 'The value must match exactly one of the schemas defined in "oneOf". Currently, it does not match any.';
end;

function TTranslate_enUS.TranslatePattern: TErrorMessage;
begin
  Result.Error := 'The string does not match the required regular expression pattern: %s';
  Result.Hint  := 'Check the format of the string to ensure it matches the expected regex pattern';
end;

function TTranslate_enUS.TranslateRequiredPropertyMissing: TErrorMessage;
begin
  Result.Error := 'The required property "%s" was not found on the object';
  Result.Hint  := 'Add property "%s" to the object with a valid value';
end;

function TTranslate_enUS.TranslateSchemaIsFalse: TErrorMessage;
begin
  Result.Error := 'Validation failed because the schema is "false".';
  Result.Hint  := 'The schema "false" prohibits any value. Validation will never pass at this point.';
end;

function TTranslate_enUS.TranslateUnevaluatedItems: TErrorMessage;
begin
  Result.Error := 'The array contains items not allowed starting at index %d.';
  Result.Hint  := 'Remove the additional items or adjust the schema (using "items" or "prefixItems") to allow them.';
end;

function TTranslate_enUS.TranslateUnevaluatedProperties: TErrorMessage;
begin
  Result.Error := 'The object contains the disallowed property(s): %s.';
  Result.Hint  := 'Remove the unspecified properties or adjust the schema (using "properties", "patternProperties", or "additionalProperties") to allow them.';
end;

function TTranslate_enUS.TranslateUniqueItems: TErrorMessage;
begin
  Result.Error := 'The array contains duplicate items. The item "%s" appears more than once';
  Result.Hint  := 'Remove duplicate elements from the array to ensure each item is unique';
end;

function TTranslate_enUS.TranslateUnknown: TErrorMessage;
begin
  Result.Error := 'An unknown validation error occurred.';
  Result.Hint  := 'No hints available for this error.';
end;

function TTranslate_enUS.TranslateUnresolvedReference: TErrorMessage;
begin
  Result.Error := 'Could not find the reference "%s".';
  Result.Hint  := 'Check if the reference name is correct.';
end;

function TTranslate_enUS.TranslateUnsupportedVocabulary: TErrorMessage;
begin
  Result.Error := 'The required vocabulary "%s" is not supported.';
  Result.Hint  := 'Use only vocabularies supported by this validator or mark unknown vocabularies as optional.';
end;

end.
