unit JsonSchema.Translate.ptBR;

interface

uses
  JsonSchema.Translate.Interfaces,
  JsonSchema.Translate.Types;

type
  /// <summary>
  ///   Provides Portuguese (pt-BR) validation error messages.
  ///   Implements ITranslate for the pt-BR locale.
  /// </summary>
  TTranslate_ptBR = class(TInterfacedObject, ITranslate)
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

{ TTranslate_ptBR }

function TTranslate_ptBR.GetInvalidType: TErrorMessage;
begin
  Result.Error := 'O valor fornecido não corresponde ao tipo esperado. Esperado: "%s", encontrado: "%s"';
  Result.Hint := 'Verifique se o valor do campo está formatado corretamente para o tipo "%s". ' +
    'Por exemplo, valores numéricos não devem estar entre aspas.';
end;

function TTranslate_ptBR.GetEnumValueMismatch: TErrorMessage;
begin
  Result.Error := 'O valor não corresponde a nenhum dos valores permitidos na enumeração.';
  Result.Hint := 'O valor deve ser exatamente um dos seguintes: %s';
end;

function TTranslate_ptBR.GetConstValueMismatch: TErrorMessage;
begin
  Result.Error := 'O valor não corresponde ao valor constante esperado.';
  Result.Hint := 'O valor deve ser exatamente igual a %s';
end;

function TTranslate_ptBR.GetMultipleOf: TErrorMessage;
begin
  Result.Error := 'O valor não é um múltiplo de %s';
  Result.Hint := 'Ajuste o valor para que seja divisível por %s sem deixar resto.';
end;

function TTranslate_ptBR.GetMaximum: TErrorMessage;
begin
  Result.Error := 'O valor excede o valor máximo permitido de %s';
  Result.Hint := 'O valor deve ser menor ou igual a %s';
end;

function TTranslate_ptBR.GetExclusiveMaximum: TErrorMessage;
begin
  Result.Error := 'O valor é igual ou excede o máximo exclusivo permitido de %s';
  Result.Hint := 'O valor deve ser estritamente menor que %s';
end;

function TTranslate_ptBR.GetMinimum: TErrorMessage;
begin
  Result.Error := 'O valor é menor que o valor mínimo permitido de %s';
  Result.Hint := 'O valor deve ser maior ou igual a %s';
end;

function TTranslate_ptBR.GetExclusiveMinimum: TErrorMessage;
begin
  Result.Error := 'O valor é igual ou menor que o mínimo exclusivo permitido de %s';
  Result.Hint := 'O valor deve ser estritamente maior que %s';
end;

function TTranslate_ptBR.GetMaxLength: TErrorMessage;
begin
  Result.Error := 'A string contém mais que o máximo de %d caracteres';
  Result.Hint := 'A string deve ter no máximo %d caracteres';
end;

function TTranslate_ptBR.GetMinLength: TErrorMessage;
begin
  Result.Error := 'A string contém menos que o mínimo de %d caracteres';
  Result.Hint := 'A string deve ter pelo menos %d caracteres';
end;

function TTranslate_ptBR.GetPattern: TErrorMessage;
begin
  Result.Error := 'A string não corresponde ao padrão de expressão regular exigido: %s';
  Result.Hint := 'Verifique o formato da string para garantir que corresponda ao padrão regex esperado.';
end;

function TTranslate_ptBR.GetInvalidFormat: TErrorMessage;
begin
  Result.Error := 'O valor não corresponde ao formato esperado de "%s".';
  Result.Hint := 'Corrija o valor para que siga o formato "%s". Por exemplo, uma data deve estar no formato "AAAA-MM-DD".';
end;

function TTranslate_ptBR.GetMaxItems: TErrorMessage;
begin
  Result.Error := 'O array excede o máximo de %d itens';
  Result.Hint := 'O array não deve conter mais de %d itens';
end;

function TTranslate_ptBR.GetMinItems: TErrorMessage;
begin
  Result.Error := 'O array contém menos que o mínimo de %d itens';
  Result.Hint := 'O array deve conter pelo menos %d itens';
end;

function TTranslate_ptBR.GetUniqueItems: TErrorMessage;
begin
  Result.Error := 'O array contém itens duplicados. O item "%s" aparece mais de uma vez.';
  Result.Hint := 'Remova elementos duplicados do array para garantir que cada item seja único.';
end;

function TTranslate_ptBR.GetContains: TErrorMessage;
begin
  Result.Error := 'O array não contém nenhum item que corresponda ao schema "contains".';
  Result.Hint := 'Adicione pelo menos um item ao array que seja válido de acordo com o schema especificado em "contains".';
end;

function TTranslate_ptBR.GetMaxContains: TErrorMessage;
begin
  Result.Error := 'O array contém %d itens que correspondem ao schema "contains", excedendo o máximo de %d.';
  Result.Hint := 'Remova os itens correspondentes em excesso. O máximo permitido é %d.';
end;

function TTranslate_ptBR.GetMinContains: TErrorMessage;
begin
  Result.Error := 'O array contém %d itens que correspondem ao schema "contains", o que é menos que o mínimo de %d.';
  Result.Hint := 'Adicione mais itens correspondentes. O mínimo exigido é %d.';
end;

function TTranslate_ptBR.GetUnevaluatedItems: TErrorMessage;
begin
  Result.Error := 'O array contém itens não permitidos a partir do índice %d.';
  Result.Hint := 'Remova os itens adicionais ou ajuste o schema (usando "items" ou "prefixItems") para permiti-los.';
end;

function TTranslate_ptBR.GetMaxProperties: TErrorMessage;
begin
  Result.Error := 'O objeto contém mais que o máximo de %d propriedades';
  Result.Hint := 'O objeto deve conter no máximo %d propriedades';
end;

function TTranslate_ptBR.GetMinProperties: TErrorMessage;
begin
  Result.Error := 'O objeto contém menos que o mínimo de %d propriedades';
  Result.Hint := 'O objeto deve conter pelo menos %d propriedades';
end;

function TTranslate_ptBR.GetRequiredPropertyMissing: TErrorMessage;
begin
  Result.Error := 'A propriedade obrigatória "%s" não foi encontrada no objeto';
  Result.Hint := 'Adicione a propriedade "%s" ao objeto com um valor válido';
end;

function TTranslate_ptBR.GetDependentRequired: TErrorMessage;
begin
  Result.Error := 'A presença da propriedade "%s" requer que a(s) propriedade(s) "%s" também esteja(m) presente(s).';
  Result.Hint := 'Quando a propriedade "%s" existir, certifique-se de que as propriedades "%s" também sejam incluídas no objeto.';
end;

function TTranslate_ptBR.GetUnevaluatedProperties: TErrorMessage;
begin
  Result.Error := 'O objeto contém a(s) propriedade(s) não permitida(s): %s.';
  Result.Hint := 'Remova as propriedades não especificadas ou ajuste o schema (usando "properties", "patternProperties" ou "additionalProperties") para permiti-las.';
end;

function TTranslate_ptBR.GetInvalidPropertyName: TErrorMessage;
begin
  Result.Error := 'O nome da propriedade "%s" não é válido de acordo com o schema "propertyNames".';
  Result.Hint := 'Renomeie a propriedade "%s" para que corresponda ao schema definido em "propertyNames".';
end;

function TTranslate_ptBR.GetAllOf: TErrorMessage;
begin
  Result.Error := 'O valor não é válido contra todos os subesquemas em "allOf". Falhou no índice %d.';
  Result.Hint := 'O valor deve atender a todas as condições especificadas nos esquemas dentro de "allOf".';
end;

function TTranslate_ptBR.GetAnyOf: TErrorMessage;
begin
  Result.Error := 'O valor não é válido contra nenhum dos subesquemas em "anyOf".';
  Result.Hint := 'O valor deve atender a pelo menos uma das condições especificadas nos esquemas dentro de "anyOf".';
end;

function TTranslate_ptBR.GetOneOfNoMatch: TErrorMessage;
begin
  Result.Error := 'O valor não é válido contra nenhum dos subesquemas em "oneOf".';
  Result.Hint := 'O valor deve corresponder exatamente a um dos esquemas definidos em "oneOf". Atualmente, não corresponde a nenhum.';
end;

function TTranslate_ptBR.GetOneOfMultipleMatches: TErrorMessage;
begin
  Result.Error := 'O valor é válido contra múltiplos subesquemas em "oneOf".';
  Result.Hint := 'O valor deve corresponder exatamente a um dos esquemas definidos em "oneOf". Atualmente, corresponde a mais de um.';
end;

function TTranslate_ptBR.GetNot: TErrorMessage;
begin
  Result.Error := 'O valor foi validado com sucesso pelo esquema em "not", o que não é permitido.';
  Result.Hint := 'O valor não deve ser válido de acordo com o esquema especificado dentro da cláusula "not".';
end;

function TTranslate_ptBR.GetSchemaIsFalse: TErrorMessage;
begin
  Result.Error := 'A validação falhou porque o esquema é "false".';
  Result.Hint := 'O esquema "false" proíbe qualquer valor. A validação nunca passará neste ponto.';
end;

function TTranslate_ptBR.GetUnresolvedReference: TErrorMessage;
begin
  Result.Error := 'Não foi possível encontrar a referência "%s".';
  Result.Hint := 'Verifique se o nome da referência está correto.';
end;

function TTranslate_ptBR.GetUnsupportedVocabulary: TErrorMessage;
begin
  Result.Error := 'O vocabulário obrigatório "%s" não é suportado.';
  Result.Hint := 'Use apenas vocabulários suportados por este validador ou marque vocabulários desconhecidos como opcionais.';
end;

function TTranslate_ptBR.GetUnknown: TErrorMessage;
begin
  Result.Error := 'Ocorreu um erro de validação desconhecido.';
  Result.Hint := 'Nenhuma dica disponível para este erro.';
end;

function TTranslate_ptBR.GetMessage(const pErrorType: TErrorType): TErrorMessage;
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
