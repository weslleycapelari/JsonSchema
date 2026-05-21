unit JsonSchema.Translate.enUS;

interface

uses
  JsonSchema.Translate.Interfaces,
  JsonSchema.Translate.Types;

type
  /// <summary>
  ///   Provides English (en-US) validation error messages.
  ///   Implements ITranslate for the en-US locale.
  /// </summary>
  TTranslate_enUS = class(TInterfacedObject, ITranslate)
  private
    function GetInvalidType: TErrorMessage;
    function GetEnumValueMismatch: TErrorMessage;
    function GetConstValueMismatch: TErrorMessage;
    function GetMultipleOf: TErrorMessage;
    function GetMaximum: TErrorMessage;
    function GetExclusiveMaximum: TErrorMessage;
    function GetMinimum: TErrorMessage;
    function GetExclusiveMinimum: TErrorMessage;
    function GetMaxLength: TErrorMessage;
    function GetMinLength: TErrorMessage;
    function GetPattern: TErrorMessage;
    function GetInvalidFormat: TErrorMessage;
    function GetMaxItems: TErrorMessage;
    function GetMinItems: TErrorMessage;
    function GetUniqueItems: TErrorMessage;
    function GetContains: TErrorMessage;
    function GetMaxContains: TErrorMessage;
    function GetMinContains: TErrorMessage;
    function GetUnevaluatedItems: TErrorMessage;
    function GetMaxProperties: TErrorMessage;
    function GetMinProperties: TErrorMessage;
    function GetRequiredPropertyMissing: TErrorMessage;
    function GetDependentRequired: TErrorMessage;
    function GetUnevaluatedProperties: TErrorMessage;
    function GetInvalidPropertyName: TErrorMessage;
    function GetAllOf: TErrorMessage;
    function GetAnyOf: TErrorMessage;
    function GetOneOfNoMatch: TErrorMessage;
    function GetOneOfMultipleMatches: TErrorMessage;
    function GetNot: TErrorMessage;
    function GetSchemaIsFalse: TErrorMessage;
    function GetUnresolvedReference: TErrorMessage;
    function GetUnsupportedVocabulary: TErrorMessage;
    function GetUnknown: TErrorMessage;
  public
    function GetMessage(const pErrorType: TErrorType): TErrorMessage;
  end;

implementation

{ TTranslate_enUS }

function TTranslate_enUS.GetInvalidType: TErrorMessage;
begin
  Result.Error := 'The provided value does not match the expected type. Expected: "%s", found: "%s"';
  Result.Hint := 'Verify that the field value is formatted correctly for the "%s" type. ' +
    'For example, numeric values should not be enclosed in quotes.';
end;

function TTranslate_enUS.GetEnumValueMismatch: TErrorMessage;
begin
  Result.Error := 'The value does not match any of the allowed values in the enumeration.';
  Result.Hint := 'The value must be exactly one of the following: %s';
end;

function TTranslate_enUS.GetConstValueMismatch: TErrorMessage;
begin
  Result.Error := 'The value does not match the expected constant value.';
  Result.Hint := 'The value must be exactly equal to %s';
end;

function TTranslate_enUS.GetMultipleOf: TErrorMessage;
begin
  Result.Error := 'The value is not a multiple of %s';
  Result.Hint := 'Adjust the value so that it is divisible by %s without a remainder.';
end;

function TTranslate_enUS.GetMaximum: TErrorMessage;
begin
  Result.Error := 'The value exceeds the maximum allowed value of %s';
  Result.Hint := 'Value must be less than or equal to %s';
end;

function TTranslate_enUS.GetExclusiveMaximum: TErrorMessage;
begin
  Result.Error := 'The value is equal to or exceeds the exclusive maximum allowed of %s';
  Result.Hint := 'The value must be strictly less than %s';
end;

function TTranslate_enUS.GetMinimum: TErrorMessage;
begin
  Result.Error := 'The value is less than the minimum allowed value of %s';
  Result.Hint := 'Value must be greater than or equal to %s';
end;

function TTranslate_enUS.GetExclusiveMinimum: TErrorMessage;
begin
  Result.Error := 'The value is equal to or less than the exclusive minimum allowed of %s';
  Result.Hint := 'The value must be strictly greater than %s';
end;

function TTranslate_enUS.GetMaxLength: TErrorMessage;
begin
  Result.Error := 'The string contains more than the maximum of %d characters';
  Result.Hint := 'The string must have at most %d characters';
end;

function TTranslate_enUS.GetMinLength: TErrorMessage;
begin
  Result.Error := 'The string contains fewer than the minimum of %d characters';
  Result.Hint := 'The string must have at least %d characters';
end;

function TTranslate_enUS.GetPattern: TErrorMessage;
begin
  Result.Error := 'The string does not match the required regular expression pattern: %s';
  Result.Hint := 'Check the format of the string to ensure it matches the expected regex pattern.';
end;

function TTranslate_enUS.GetInvalidFormat: TErrorMessage;
begin
  Result.Error := 'The value does not match the expected format of "%s".';
  Result.Hint := 'Correct the value so that it follows the format "%s". For example, a date must be in the format "YYYY-MM-DD".';
end;

function TTranslate_enUS.GetMaxItems: TErrorMessage;
begin
  Result.Error := 'Array exceeds maximum of %d items';
  Result.Hint := 'The array must not contain more than %d items';
end;

function TTranslate_enUS.GetMinItems: TErrorMessage;
begin
  Result.Error := 'Array contains fewer than the minimum of %d items';
  Result.Hint := 'The array must contain at least %d items';
end;

function TTranslate_enUS.GetUniqueItems: TErrorMessage;
begin
  Result.Error := 'The array contains duplicate items. The item "%s" appears more than once.';
  Result.Hint := 'Remove duplicate elements from the array to ensure each item is unique.';
end;

function TTranslate_enUS.GetContains: TErrorMessage;
begin
  Result.Error := 'The array does not contain any items that match the "contains" schema.';
  Result.Hint := 'Add at least one item to the array that is valid according to the schema specified in "contains".';
end;

function TTranslate_enUS.GetMaxContains: TErrorMessage;
begin
  Result.Error := 'The array contains %d items that match the "contains" schema, exceeding the maximum of %d.';
  Result.Hint := 'Remove excess matching items. The maximum allowed is %d.';
end;

function TTranslate_enUS.GetMinContains: TErrorMessage;
begin
  Result.Error := 'The array contains %d items that match the "contains" schema, which is less than the minimum of %d.';
  Result.Hint := 'Add more matching items. The minimum required is %d.';
end;

function TTranslate_enUS.GetUnevaluatedItems: TErrorMessage;
begin
  Result.Error := 'The array contains items not allowed starting at index %d.';
  Result.Hint := 'Remove the additional items or adjust the schema (using "items" or "prefixItems") to allow them.';
end;

function TTranslate_enUS.GetMaxProperties: TErrorMessage;
begin
  Result.Error := 'The object contains more than the maximum of %d properties';
  Result.Hint := 'The object must contain at most %d properties';
end;

function TTranslate_enUS.GetMinProperties: TErrorMessage;
begin
  Result.Error := 'The object contains fewer than the minimum of %d properties';
  Result.Hint := 'The object must contain at least %d properties';
end;

function TTranslate_enUS.GetRequiredPropertyMissing: TErrorMessage;
begin
  Result.Error := 'The required property "%s" was not found on the object';
  Result.Hint := 'Add property "%s" to the object with a valid value';
end;

function TTranslate_enUS.GetDependentRequired: TErrorMessage;
begin
  Result.Error := 'The presence of the "%s" property requires that the "%s" property(s) also be present.';
  Result.Hint := 'When the "%s" property exists, ensure that the "%s" properties are also included in the object.';
end;

function TTranslate_enUS.GetUnevaluatedProperties: TErrorMessage;
begin
  Result.Error := 'The object contains the disallowed property(s): %s.';
  Result.Hint := 'Remove the unspecified properties or adjust the schema (using "properties", "patternProperties", or "additionalProperties") to allow them.';
end;

function TTranslate_enUS.GetInvalidPropertyName: TErrorMessage;
begin
  Result.Error := 'The property name "%s" is not valid according to the "propertyNames" schema.';
  Result.Hint := 'Rename the property "%s" so that it matches the schema defined in "propertyNames".';
end;

function TTranslate_enUS.GetAllOf: TErrorMessage;
begin
  Result.Error := 'The value is not valid against all subschemas in "allOf". Failed at index %d.';
  Result.Hint := 'The value must meet all conditions specified in the schemas within "allOf".';
end;

function TTranslate_enUS.GetAnyOf: TErrorMessage;
begin
  Result.Error := 'The value is not valid against any of the subschemas in "anyOf".';
  Result.Hint := 'The value must meet at least one of the conditions specified in the schemas within "anyOf".';
end;

function TTranslate_enUS.GetOneOfNoMatch: TErrorMessage;
begin
  Result.Error := 'The value is not valid against any of the subschemas in "oneOf".';
  Result.Hint := 'The value must match exactly one of the schemas defined in "oneOf". Currently, it does not match any.';
end;

function TTranslate_enUS.GetOneOfMultipleMatches: TErrorMessage;
begin
  Result.Error := 'The value is valid against multiple sub-schemas in "oneOf".';
  Result.Hint := 'The value must match exactly one of the schemas defined in "oneOf". Currently, it matches more than one.';
end;

function TTranslate_enUS.GetNot: TErrorMessage;
begin
  Result.Error := 'The value was successfully validated by the schema in "not", which is not allowed.';
  Result.Hint := 'The value must not be valid according to the schema specified within the "not" clause.';
end;

function TTranslate_enUS.GetSchemaIsFalse: TErrorMessage;
begin
  Result.Error := 'Validation failed because the schema is "false".';
  Result.Hint := 'The schema "false" prohibits any value. Validation will never pass at this point.';
end;

function TTranslate_enUS.GetUnresolvedReference: TErrorMessage;
begin
  Result.Error := 'Could not find the reference "%s".';
  Result.Hint := 'Check if the reference name is correct.';
end;

function TTranslate_enUS.GetUnsupportedVocabulary: TErrorMessage;
begin
  Result.Error := 'The required vocabulary "%s" is not supported.';
  Result.Hint := 'Use only vocabularies supported by this validator or mark unknown vocabularies as optional.';
end;

function TTranslate_enUS.GetUnknown: TErrorMessage;
begin
  Result.Error := 'An unknown validation error occurred.';
  Result.Hint := 'No hints available for this error.';
end;

function TTranslate_enUS.GetMessage(const pErrorType: TErrorType): TErrorMessage;
begin
  case pErrorType of
    TErrorType.vetInvalidType:              Result := GetInvalidType;
    TErrorType.vetEnumValueMismatch:        Result := GetEnumValueMismatch;
    TErrorType.vetConstValueMismatch:       Result := GetConstValueMismatch;
    TErrorType.vetMultipleOf:               Result := GetMultipleOf;
    TErrorType.vetMaximum:                  Result := GetMaximum;
    TErrorType.vetExclusiveMaximum:         Result := GetExclusiveMaximum;
    TErrorType.vetMinimum:                  Result := GetMinimum;
    TErrorType.vetExclusiveMinimum:         Result := GetExclusiveMinimum;
    TErrorType.vetMaxLength:                Result := GetMaxLength;
    TErrorType.vetMinLength:                Result := GetMinLength;
    TErrorType.vetPattern:                  Result := GetPattern;
    TErrorType.vetInvalidFormat:            Result := GetInvalidFormat;
    TErrorType.vetMaxItems:                 Result := GetMaxItems;
    TErrorType.vetMinItems:                 Result := GetMinItems;
    TErrorType.vetUniqueItems:              Result := GetUniqueItems;
    TErrorType.vetContains:                 Result := GetContains;
    TErrorType.vetMaxContains:              Result := GetMaxContains;
    TErrorType.vetMinContains:              Result := GetMinContains;
    TErrorType.vetUnevaluatedItems:         Result := GetUnevaluatedItems;
    TErrorType.vetMaxProperties:            Result := GetMaxProperties;
    TErrorType.vetMinProperties:            Result := GetMinProperties;
    TErrorType.vetRequiredPropertyMissing:  Result := GetRequiredPropertyMissing;
    TErrorType.vetDependentRequired:        Result := GetDependentRequired;
    TErrorType.vetUnevaluatedProperties:    Result := GetUnevaluatedProperties;
    TErrorType.vetInvalidPropertyName:      Result := GetInvalidPropertyName;
    TErrorType.vetAllOf:                    Result := GetAllOf;
    TErrorType.vetAnyOf:                    Result := GetAnyOf;
    TErrorType.vetOneOf_NoMatch:            Result := GetOneOfNoMatch;
    TErrorType.vetOneOf_MultipleMatches:    Result := GetOneOfMultipleMatches;
    TErrorType.vetNot:                      Result := GetNot;
    TErrorType.vetUnresolvedReference:      Result := GetUnresolvedReference;
    TErrorType.vetUnsupportedVocabulary:    Result := GetUnsupportedVocabulary;
    TErrorType.vetSchemaIsFalse:            Result := GetSchemaIsFalse;
  else
    Result := GetUnknown;
  end;
end;

end.
