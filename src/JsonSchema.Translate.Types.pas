unit JsonSchema.Translate.Types;

interface

type
  TLanguage = (
    lang_enUS,    // Inglês (Estados Unidos)
    lang_ptBR     // Português (Brasil)
  );

  /// <summary>Estrutura da resposta de mensagem de erro/hint da biblioteca</summary>
  TErrorMessage = record
    Error: string;
    Hint: string;
  end;

  /// <summary>Tipo de função de tradução que retorna a estrutura de mensagem de erro</summary>
  TTranslateFunc = function: TErrorMessage of object;

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

    // Erro genérico
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
