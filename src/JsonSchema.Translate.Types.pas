unit JsonSchema.Translate.Types;

interface

type
  TLanguage = (
    lang_enUS,    // Ingl�s (Estados Unidos)
    lang_ptBR     // Portugu�s (Brasil)
  );

  /// <summary>Estrutura da resposta de mensagem de erro/hint da biblioteca</summary>
  TErrorMessage = record
    Error: string;
    Hint: string;
  end;

  /// <summary>Tipo de fun��o de tradu��o que retorna a estrutura de mensagem de erro</summary>
  TTranslateFunc = function: TErrorMessage of object;

  TErrorType = (
    // Erros de tipo e valor
    vetInvalidType,
    vetEnumValueMismatch,
    vetConstValueMismatch,

    // Erros num�ricos
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

    // Erro gen�rico
    vetSchemaIsFalse,
    vetUnknown
  );

  TranslateErrorAttribute = class(TCustomAttribute)
  private
    FErrorType: TErrorType;
  public
    constructor Create(const AErrorType: TErrorType);
    property ErrorType: TErrorType read FErrorType;
  end;

implementation

{ TranslateErrorAttribute }

constructor TranslateErrorAttribute.Create(const AErrorType: TErrorType);
begin
  FErrorType := AErrorType;
end;

end.
