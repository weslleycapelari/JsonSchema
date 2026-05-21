unit JsonSchema.Translate.Types;

interface

type
  /// <summary>
  /// Supported display languages for validation error messages.
  /// </summary>
  {$SCOPEDENUMS ON}
  TLanguage = (
    lang_enUS,
    lang_ptBR
  );
  {$SCOPEDENUMS OFF}

  /// <summary>
  /// Holds the error message and hint text returned by a translation provider.
  /// </summary>
  TErrorMessage = record
    Error: string;
    Hint: string;
  end;

  /// <summary>
  /// Identifies each validation error type produced by the JSON Schema validator.
  /// </summary>
  TErrorType = (
    // Erros de tipo e valor
    vetInvalidType,
    vetEnumValueMismatch,
    vetConstValueMismatch,

    // Erros numéricos
    vetMultipleOf,
    vetMaximum,
    vetExclusiveMaximum,
    vetMinimum,
    vetExclusiveMinimum,

    // Erros de string
    vetMaxLength,
    vetMinLength,
    vetPattern,
    vetInvalidFormat,

    // Erros de array
    vetMaxItems,
    vetMinItems,
    vetUniqueItems,
    vetMaxContains,
    vetMinContains,
    vetContains,
    vetUnevaluatedItems,

    // Erros de objeto
    vetMaxProperties,
    vetMinProperties,
    vetRequiredPropertyMissing,
    vetDependentRequired,
    vetUnevaluatedProperties,
    vetInvalidPropertyName,

    // Erros de aplicadores
    vetAllOf,
    vetAnyOf,
    vetOneOf_NoMatch,
    vetOneOf_MultipleMatches,
    vetNot,

    vetUnresolvedReference,
    vetUnsupportedVocabulary,

    // Erro genérico
    vetSchemaIsFalse,
    vetUnknown
  );

implementation

end.
