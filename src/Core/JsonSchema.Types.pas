unit JsonSchema.Types;

interface

type
  /// <summary>
  ///   Supported display languages for validation error messages.
  /// </summary>
  {$SCOPEDENUMS ON}
  TLanguage = (
    lang_enUS,
    lang_ptBR
  );
  {$SCOPEDENUMS OFF}

  /// <summary>
  ///   Identifies each validation error type produced by the JSON Schema validator.
  /// </summary>
  {$SCOPEDENUMS ON}
  TErrorType = (
    // Type and value errors
    vetInvalidType,
    vetEnumValueMismatch,
    vetConstValueMismatch,

    // Numeric errors
    vetMultipleOf,
    vetMaximum,
    vetExclusiveMaximum,
    vetMinimum,
    vetExclusiveMinimum,

    // String errors
    vetMaxLength,
    vetMinLength,
    vetPattern,
    vetInvalidFormat,

    // Array errors
    vetMaxItems,
    vetMinItems,
    vetUniqueItems,
    vetMaxContains,
    vetMinContains,
    vetContains,
    vetUnevaluatedItems,

    // Object errors
    vetMaxProperties,
    vetMinProperties,
    vetRequiredPropertyMissing,
    vetDependentRequired,
    vetUnevaluatedProperties,
    vetInvalidPropertyName,

    // Applicator errors
    vetAllOf,
    vetAnyOf,
    vetOneOf_NoMatch,
    vetOneOf_MultipleMatches,
    vetNot,

    // Reference and vocabulary errors
    vetUnresolvedReference,
    vetUnsupportedVocabulary,

    // Generic errors
    vetSchemaIsFalse,
    vetUnknown
  );
  {$SCOPEDENUMS OFF}

  /// <summary>
  ///   Holds the localized error message and hint text for a validation error.
  /// </summary>
  TErrorMessage = record
    Error: string;
    Hint: string;
  end;

  /// <summary>
  ///   Identifies the JSON Schema draft version of a given schema document.
  ///   Used to select the correct visitor and resolve cross‑draft $refs.
  /// </summary>
  TDraftVersion = (
    dvUnknown,
    dvDraft6,
    dvDraft7,
    dvDraft2019_09,
    dvDraft2020_12
  );

  /// <summary>
  ///   Helper methods for converting between TDraftVersion and the canonical $schema URI.
  /// </summary>
  TDraftVersionHelper = record helper for TDraftVersion
    /// <summary>Parses the $schema URI and returns the matching draft version.</summary>
    class function FromSchema(const pSchema: string): TDraftVersion; static;

    /// <summary>Returns the canonical $schema URI for this draft version.</summary>
    function ToSchema: string;
  end;

const
  /// <summary>
  ///   The complete list of JSON Schema validation vocabulary keywords.
  ///   Used to mark keywords as visited or silenced when $vocabulary excludes the validation vocabulary.
  /// </summary>
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

implementation

uses
  System.SysUtils;

{ TDraftVersionHelper }

class function TDraftVersionHelper.FromSchema(const pSchema: string): TDraftVersion;
var
  lSchema: string;
begin
  lSchema := LowerCase(Trim(pSchema));
  if lSchema.EndsWith('#') then
    lSchema := lSchema.Substring(0, lSchema.Length - 1);
  if lSchema.EndsWith('/') then
    lSchema := lSchema.Substring(0, lSchema.Length - 1);

  if (lSchema = 'https://json-schema.org/draft-06/schema') or
     (lSchema = 'http://json-schema.org/draft-06/schema') then
    Result := TDraftVersion.dvDraft6
  else if (lSchema = 'https://json-schema.org/draft-07/schema') or
          (lSchema = 'http://json-schema.org/draft-07/schema') then
    Result := TDraftVersion.dvDraft7
  else if (lSchema = 'https://json-schema.org/draft/2019-09/schema') or
          (lSchema = 'http://json-schema.org/draft/2019-09/schema') then
    Result := TDraftVersion.dvDraft2019_09
  else if (lSchema = 'https://json-schema.org/draft/2020-12/schema') or
          (lSchema = 'http://json-schema.org/draft/2020-12/schema') then
    Result := TDraftVersion.dvDraft2020_12
  else
    Result := TDraftVersion.dvUnknown;
end;

function TDraftVersionHelper.ToSchema: string;
begin
  case Self of
    dvUnknown:
      Result := '';
    dvDraft6:
      Result := 'https://json-schema.org/draft-06/schema';
    dvDraft7:
      Result := 'https://json-schema.org/draft-07/schema';
    dvDraft2019_09:
      Result := 'https://json-schema.org/draft/2019-09/schema';
    dvDraft2020_12:
      Result := 'https://json-schema.org/draft/2020-12/schema';
  else
    Result := '';
  end;
end;

end.
