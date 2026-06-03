unit JsonSchema.Localization.EnUS;

(*
--------------------------------------------------------------------------------
Default English (En-US) localization implementation.
--------------------------------------------------------------------------------
*)

interface

uses
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Localization.Enums,
  JsonSchema.Localization.Interfaces,
  JsonSchema.Localization.Base;

type
  /// <summary>Localization provider for English (En-US) validation errors.</summary>
  TLocalizationEnUS = class(TLocalizationBase)
  public
    constructor Create;
    function TranslateType(const pError: IValidationError): TTranslation; override;
    function TranslateMinLength(const pError: IValidationError): TTranslation; override;
    function TranslateEnum(const pError: IValidationError): TTranslation; override;
    function TranslateConst(const pError: IValidationError): TTranslation; override;
    function TranslateRequired(const pError: IValidationError): TTranslation; override;
    function TranslateMinimum(const pError: IValidationError): TTranslation; override;
    function TranslateMaximum(const pError: IValidationError): TTranslation; override;
    function TranslateMaxLength(const pError: IValidationError): TTranslation; override;
    function TranslateMinItems(const pError: IValidationError): TTranslation; override;
    function TranslateMaxItems(const pError: IValidationError): TTranslation; override;
    function TranslateMultipleOf(const pError: IValidationError): TTranslation; override;
    function TranslateExclusiveMaximum(const pError: IValidationError): TTranslation; override;
    function TranslateExclusiveMinimum(const pError: IValidationError): TTranslation; override;
    function TranslatePattern(const pError: IValidationError): TTranslation; override;
    function TranslateItems(const pError: IValidationError): TTranslation; override;
    function TranslateAdditionalItems(const pError: IValidationError): TTranslation; override;
    function TranslateUniqueItems(const pError: IValidationError): TTranslation; override;
    function TranslateContains(const pError: IValidationError): TTranslation; override;
    function TranslateMaxProperties(const pError: IValidationError): TTranslation; override;
    function TranslateMinProperties(const pError: IValidationError): TTranslation; override;
    function TranslateProperties(const pError: IValidationError): TTranslation; override;
    function TranslatePatternProperties(const pError: IValidationError): TTranslation; override;
    function TranslateAdditionalProperties(const pError: IValidationError): TTranslation; override;
    function TranslateDependencies(const pError: IValidationError): TTranslation; override;
    function TranslatePropertyNames(const pError: IValidationError): TTranslation; override;
    function TranslateAllOf(const pError: IValidationError): TTranslation; override;
    function TranslateAnyOf(const pError: IValidationError): TTranslation; override;
    function TranslateOneOf(const pError: IValidationError): TTranslation; override;
    function TranslateNot(const pError: IValidationError): TTranslation; override;
    function TranslateRef(const pError: IValidationError): TTranslation; override;
    function TranslateSchema(const pError: IValidationError): TTranslation; override;
    function TranslateId(const pError: IValidationError): TTranslation; override;
  end;

implementation

{ TLocalizationEnUS }

constructor TLocalizationEnUS.Create;
begin
  inherited Create(TLocale.EnUS);
end;

function TLocalizationEnUS.TranslateType(const pError: IValidationError): TTranslation;
var
  lExpected, lActual: string;
begin
  if not pError.Context.TryGetValue<string>('expected', lExpected) then
    lExpected := 'unknown';
  if not pError.Context.TryGetValue<string>('actual', lActual) then
    lActual := 'unknown';
  
  Result := TTranslation.Create(
    Format('Expected type "%s" but got "%s"', [lExpected, lActual]),
    Format('Ensure the value is a valid JSON %s', [lExpected])
  );
end;

function TLocalizationEnUS.TranslateMinLength(const pError: IValidationError): TTranslation;
var
  lLimit, lActualLen: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Integer>('actual', lActualLen) then
    lActualLen := 0;
  
  Result := TTranslation.Create(
    Format('String length %d is less than minLength %d', [lActualLen, lLimit]),
    Format('Provide a string with at least %d characters', [lLimit])
  );
end;

function TLocalizationEnUS.TranslateEnum(const pError: IValidationError): TTranslation;
var
  lAllowed: string;
begin
  if not pError.Context.TryGetValue<string>('allowed', lAllowed) then
    lAllowed := '[]';

  Result := TTranslation.Create(
    Format('Value is not one of the allowed values: %s', [lAllowed]),
    'Ensure the value matches one of the expected enum options'
  );
end;

function TLocalizationEnUS.TranslateConst(const pError: IValidationError): TTranslation;
var
  lExpected: string;
begin
  if not pError.Context.TryGetValue<string>('expected', lExpected) then
    lExpected := 'unknown';

  Result := TTranslation.Create(
    Format('Value does not match the constant: %s', [lExpected]),
    Format('Ensure the value is exactly %s', [lExpected])
  );
end;

function TLocalizationEnUS.TranslateRequired(const pError: IValidationError): TTranslation;
var
  lMissing: string;
begin
  if not pError.Context.TryGetValue<string>('missing', lMissing) then
    lMissing := 'unknown';

  Result := TTranslation.Create(
    Format('Missing required property: "%s"', [lMissing]),
    Format('Provide the missing property "%s" in the object', [lMissing])
  );
end;

function TLocalizationEnUS.TranslateMinimum(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Double;
begin
  if not pError.Context.TryGetValue<Double>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Double>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('Value %g is less than minimum %g', [lActual, lLimit]),
    Format('Provide a number greater than or equal to %g', [lLimit])
  );
end;

function TLocalizationEnUS.TranslateMaximum(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Double;
begin
  if not pError.Context.TryGetValue<Double>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Double>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('Value %g is greater than maximum %g', [lActual, lLimit]),
    Format('Provide a number less than or equal to %g', [lLimit])
  );
end;

function TLocalizationEnUS.TranslateMaxLength(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Integer>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('String length %d is greater than maxLength %d', [lActual, lLimit]),
    Format('Provide a string with at most %d characters', [lLimit])
  );
end;

function TLocalizationEnUS.TranslateMinItems(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Integer>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('Array count %d is less than minItems %d', [lActual, lLimit]),
    Format('Provide an array with at least %d items', [lLimit])
  );
end;

function TLocalizationEnUS.TranslateMaxItems(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Integer>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('Array count %d is greater than maxItems %d', [lActual, lLimit]),
    Format('Provide an array with at most %d items', [lLimit])
  );
end;

function TLocalizationEnUS.TranslateMultipleOf(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Double;
begin
  if not pError.Context.TryGetValue<Double>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Double>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('Value %g is not a multiple of %g', [lActual, lLimit]),
    Format('Provide a number that is a multiple of %g', [lLimit])
  );
end;

function TLocalizationEnUS.TranslateExclusiveMaximum(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Double;
begin
  if not pError.Context.TryGetValue<Double>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Double>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('Value %g is greater than or equal to exclusiveMaximum %g', [lActual, lLimit]),
    Format('Provide a number strictly less than %g', [lLimit])
  );
end;

function TLocalizationEnUS.TranslateExclusiveMinimum(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Double;
begin
  if not pError.Context.TryGetValue<Double>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Double>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('Value %g is less than or equal to exclusiveMinimum %g', [lActual, lLimit]),
    Format('Provide a number strictly greater than %g', [lLimit])
  );
end;

function TLocalizationEnUS.TranslatePattern(const pError: IValidationError): TTranslation;
var
  lPattern, lActual: string;
begin
  if not pError.Context.TryGetValue<string>('pattern', lPattern) then
    lPattern := 'unknown';
  if not pError.Context.TryGetValue<string>('actual', lActual) then
    lActual := '';

  Result := TTranslation.Create(
    Format('Value "%s" does not match regex pattern "%s"', [lActual, lPattern]),
    Format('Provide a value matching pattern "%s"', [lPattern])
  );
end;

function TLocalizationEnUS.TranslateItems(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Items validation failed',
    'Ensure all array elements match their schemas'
  );
end;

function TLocalizationEnUS.TranslateAdditionalItems(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Integer>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('Additional items found (count %d) but schema restricts additional items beyond %d', [lActual, lLimit]),
    'Ensure the array does not contain more items than defined by the schema'
  );
end;

function TLocalizationEnUS.TranslateUniqueItems(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Array items are not unique',
    'Remove duplicate elements from the array'
  );
end;

function TLocalizationEnUS.TranslateContains(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Array does not contain any item validating against the schema',
    'Provide at least one item matching the constraint'
  );
end;

function TLocalizationEnUS.TranslateMaxProperties(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Integer>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('Object has %d properties, maximum allowed is %d', [lActual, lLimit]),
    Format('Provide an object with at most %d properties', [lLimit])
  );
end;

function TLocalizationEnUS.TranslateMinProperties(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Integer>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('Object has %d properties, minimum required is %d', [lActual, lLimit]),
    Format('Provide an object with at least %d properties', [lLimit])
  );
end;

function TLocalizationEnUS.TranslateProperties(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Properties validation failed',
    'Ensure all property values conform to their schemas'
  );
end;

function TLocalizationEnUS.TranslatePatternProperties(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Pattern properties validation failed',
    'Ensure all pattern-matched property values conform to their schemas'
  );
end;

function TLocalizationEnUS.TranslateAdditionalProperties(const pError: IValidationError): TTranslation;
var
  lPropName: string;
begin
  if not pError.Context.TryGetValue<string>('propertyName', lPropName) then
    lPropName := 'unknown';

  Result := TTranslation.Create(
    Format('Property "%s" is not allowed in this object', [lPropName]),
    'Remove any undocumented properties from the JSON object'
  );
end;

function TLocalizationEnUS.TranslateDependencies(const pError: IValidationError): TTranslation;
var
  lTrigger, lMissing: string;
begin
  if pError.Context.TryGetValue<string>('trigger', lTrigger) and pError.Context.TryGetValue<string>('missing', lMissing) then
  begin
    Result := TTranslation.Create(
      Format('Property "%s" depends on property "%s" which is missing', [lTrigger, lMissing]),
      Format('Add the missing dependent property "%s"', [lMissing])
    );
  end else
  begin
    Result := TTranslation.Create(
      'Dependencies validation failed',
      'Ensure all dependent property constraints are met'
    );
  end;
end;

function TLocalizationEnUS.TranslatePropertyNames(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'One or more property names fail validation',
    'Ensure all property keys conform to the propertyNames schema'
  );
end;

function TLocalizationEnUS.TranslateAllOf(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Validation failed against allOf sub-schemas',
    'Ensure the instance conforms to all specified sub-schemas'
  );
end;

function TLocalizationEnUS.TranslateAnyOf(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Validation failed against anyOf sub-schemas',
    'Ensure the instance conforms to at least one of the sub-schemas'
  );
end;

function TLocalizationEnUS.TranslateOneOf(const pError: IValidationError): TTranslation;
var
  lActual: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('actual', lActual) then
    lActual := 0;

  if lActual = 0 then
  begin
    Result := TTranslation.Create(
      'Conformed to 0 sub-schemas when exactly 1 was expected',
      'Ensure the instance conforms to exactly one of the sub-schemas'
    );
  end else
  begin
    Result := TTranslation.Create(
      Format('Conformed to %d sub-schemas when exactly 1 was expected', [lActual]),
      'Ensure the instance conforms to exactly one of the sub-schemas'
    );
  end;
end;

function TLocalizationEnUS.TranslateNot(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Validation failed against not sub-schema',
    'Ensure the instance does not conform to the sub-schema'
  );
end;

function TLocalizationEnUS.TranslateRef(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Reference validation failed or unresolved reference',
    'Ensure the reference points to a valid and reachable schema document'
  );
end;

function TLocalizationEnUS.TranslateSchema(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Schema declaration mismatch',
    'Ensure the schema conforms to the specified JSON Schema draft'
  );
end;

function TLocalizationEnUS.TranslateId(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Schema identifier mismatch',
    'Ensure the schema identifier is a valid absolute URI'
  );
end;

end.
