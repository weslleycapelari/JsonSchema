unit JsonSchema.Translate.ptBR;

interface

uses
  JsonSchema.Translate.Types,
  JsonSchema.Translate.Interfaces;

type
  TTranslate_ptBR = class(TInterfacedObject, ITranslate)
    // --- Erros de Tipo e Valor ---
    [TranslateError(vetInvalidType)]
    function TranslateInvalidType: TErrorMessage;
    [TranslateError(vetEnumValueMismatch)]
    function TranslateEnumValueMismatch: TErrorMessage;
    [TranslateError(vetConstValueMismatch)]
    function TranslateConstValueMismatch: TErrorMessage;

    // --- Erros Numéricos ---
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
    [TranslateError(vetUnknown)]
    function TranslateUnknown: TErrorMessage;
  end;

implementation

{ TTranslate_ptBR }

function TTranslate_ptBR.TranslateAllOf: TErrorMessage;
begin
  Result.Error := 'O valor não é válido contra todos os sub-schemas em "allOf". Falhou no índice %d.';
  Result.Hint  := 'O valor deve atender a todas as condições especificadas nos schemas dentro de "allOf".';
end;

function TTranslate_ptBR.TranslateAnyOf: TErrorMessage;
begin
  Result.Error := 'O valor não é válido contra nenhum dos sub-schemas em "anyOf".';
  Result.Hint  := 'O valor deve atender a pelo menos uma das condições especificadas nos schemas dentro de "anyOf".';
end;

function TTranslate_ptBR.TranslateConstValueMismatch: TErrorMessage;
begin
  Result.Error := 'O valor não corresponde ao valor constante esperado';
  Result.Hint  := 'O valor deve ser exatamente igual a %s';
end;

function TTranslate_ptBR.TranslateContains: TErrorMessage;
begin
  Result.Error := 'O array não contém nenhum item que corresponda ao schema de "contains".';
  Result.Hint  := 'Adicione pelo menos um item ao array que seja válido de acordo com o schema especificado em "contains".';
end;

function TTranslate_ptBR.TranslateDependentRequired: TErrorMessage;
begin
  Result.Error := 'A presença da propriedade "%s" requer que a(s) propriedade(s) "%s" também esteja(m) presente(s).';
  Result.Hint  := 'Quando a propriedade "%s" existir, certifique-se de que as propriedades "%s" também sejam incluídas no objeto.';
end;

function TTranslate_ptBR.TranslateEnumValueMismatch: TErrorMessage;
begin
  Result.Error := 'O valor não corresponde a nenhum dos valores permitidos na enumeração';
  Result.Hint  := 'O valor deve ser exatamente um dos seguintes: %s';
end;

function TTranslate_ptBR.TranslateExclusiveMaximum: TErrorMessage;
begin
  Result.Error := 'O valor é igual ou excede o máximo exclusivo permitido de %s';
  Result.Hint  := 'O valor deve ser menor que %s';
end;

function TTranslate_ptBR.TranslateExclusiveMinimum: TErrorMessage;
begin
  Result.Error := 'O valor é igual ou menor que o mínimo exclusivo permitido de %s';
  Result.Hint  := 'O valor deve ser maior que %s';
end;

function TTranslate_ptBR.TranslateInvalidFormat: TErrorMessage;
begin
  Result.Error := 'O valor não corresponde ao formato esperado de "%s".';
  Result.Hint  := 'Corrija o valor para que siga o formato "%s". Por exemplo, uma data deve estar no formato "AAAA-MM-DD".';
end;

function TTranslate_ptBR.TranslateInvalidPropertyName: TErrorMessage;
begin
  Result.Error := 'O nome da propriedade "%s" não é válido de acordo com o schema de "propertyNames".';
  Result.Hint  := 'Renomeie a propriedade "%s" para que ela corresponda ao schema definido em "propertyNames".';
end;

function TTranslate_ptBR.TranslateInvalidType: TErrorMessage;
begin
  Result.Error := 'O valor fornecido não corresponde ao tipo esperado. Esperado: "%s", encontrado: "%s"';
  Result.Hint  := 'Verifique se o valor do campo está formatado corretamente para o tipo "%s". Por exemplo, valores numéricos não devem estar entre aspas';
end;

function TTranslate_ptBR.TranslateMaxContains: TErrorMessage;
begin
  Result.Error := 'O array contém %d itens que correspondem ao schema "contains", excedendo o máximo de %d.';
  Result.Hint  := 'Remova os itens correspondentes em excesso. O máximo permitido é %d.';
end;

function TTranslate_ptBR.TranslateMaximum: TErrorMessage;
begin
  Result.Error := 'O valor excede o máximo permitido de %s';
  Result.Hint  := 'O valor deve ser menor ou igual a %s';
end;

function TTranslate_ptBR.TranslateMaxItems: TErrorMessage;
begin
  Result.Error := 'O array excede o máximo de %d itens';
  Result.Hint  := 'O array não deve conter mais de %d itens';
end;

function TTranslate_ptBR.TranslateMaxLength: TErrorMessage;
begin
  Result.Error := 'A string contém mais caracteres que o máximo de %d';
  Result.Hint  := 'A string deve ter no máximo %d caracteres';
end;

function TTranslate_ptBR.TranslateMaxProperties: TErrorMessage;
begin
  Result.Error := 'O objeto contém mais propriedades que o máximo de %d';
  Result.Hint  := 'O objeto deve conter no máximo %d propriedades';
end;

function TTranslate_ptBR.TranslateMinContains: TErrorMessage;
begin
  Result.Error := 'O array contém %d itens que correspondem ao schema "contains", o que é menos que o mínimo de %d.';
  Result.Hint  := 'Adicione mais itens correspondentes. O mínimo exigido é %d.';
end;

function TTranslate_ptBR.TranslateMinimum: TErrorMessage;
begin
  Result.Error := 'O valor é menor que o mínimo permitido de %s';
  Result.Hint  := 'O valor deve ser maior ou igual a %s';
end;

function TTranslate_ptBR.TranslateMinItems: TErrorMessage;
begin
  Result.Error := 'O array contém menos que o mínimo de %d itens';
  Result.Hint  := 'O array deve conter pelo menos %d itens';
end;

function TTranslate_ptBR.TranslateMinLength: TErrorMessage;
begin
  Result.Error := 'A string contém menos caracteres que o mínimo de %d';
  Result.Hint  := 'A string deve ter no mínimo %d caracteres';
end;

function TTranslate_ptBR.TranslateMinProperties: TErrorMessage;
begin
  Result.Error := 'O objeto contém menos propriedades que o mínimo de %d';
  Result.Hint  := 'O objeto deve conter pelo menos %d propriedades';
end;

function TTranslate_ptBR.TranslateMultipleOf: TErrorMessage;
begin
  Result.Error := 'O valor não é um múltiplo de %s';
  Result.Hint  := 'Ajuste o valor para que seja divisível por %s sem deixar resto';
end;

function TTranslate_ptBR.TranslateNot: TErrorMessage;
begin
  Result.Error := 'O valor foi validado com sucesso pelo schema em "not", o que não é permitido.';
  Result.Hint  := 'O valor não deve ser válido de acordo com o schema especificado dentro da cláusula "not".';
end;

function TTranslate_ptBR.TranslateOneOf_MultipleMatches: TErrorMessage;
begin
  Result.Error := 'O valor é válido contra múltiplos sub-schemas em "oneOf".';
  Result.Hint  := 'O valor deve corresponder a exatamente um dos schemas definidos em "oneOf". Atualmente, corresponde a mais de um.';
end;

function TTranslate_ptBR.TranslateOneOf_NoMatch: TErrorMessage;
begin
  Result.Error := 'O valor não é válido contra nenhum dos sub-schemas em "oneOf".';
  Result.Hint  := 'O valor deve corresponder a exatamente um dos schemas definidos em "oneOf". Atualmente, não corresponde a nenhum.';
end;

function TTranslate_ptBR.TranslatePattern: TErrorMessage;
begin
  Result.Error := 'A string não corresponde ao padrão de expressão regular exigido: %s';
  Result.Hint  := 'Verifique o formato da string para garantir que corresponda ao padrão regex esperado';
end;

function TTranslate_ptBR.TranslateRequiredPropertyMissing: TErrorMessage;
begin
  Result.Error := 'A propriedade obrigatória "%s" não foi encontrada no objeto';
  Result.Hint  := 'Adicione a propriedade "%s" ao objeto com um valor válido';
end;

function TTranslate_ptBR.TranslateSchemaIsFalse: TErrorMessage;
begin
  Result.Error := 'A validação falhou porque o schema é "false".';
  Result.Hint  := 'O schema "false" proíbe qualquer valor. A validação nunca passará neste ponto.';
end;

function TTranslate_ptBR.TranslateUnevaluatedItems: TErrorMessage;
begin
  Result.Error := 'O array contém itens não permitidos a partir do índice %d.';
  Result.Hint  := 'Remova os itens adicionais ou ajuste o schema (usando "items" ou "prefixItems") para permiti-los.';
end;

function TTranslate_ptBR.TranslateUnevaluatedProperties: TErrorMessage;
begin
  Result.Error := 'O objeto contém a(s) propriedade(s) não permitida(s): %s.';
  Result.Hint  := 'Remova as propriedades não especificadas ou ajuste o schema (usando "properties", "patternProperties" ou "additionalProperties") para permiti-las.';
end;

function TTranslate_ptBR.TranslateUniqueItems: TErrorMessage;
begin
  Result.Error := 'O array contém itens duplicados. O item "%s" aparece mais de uma vez';
  Result.Hint  := 'Remova os elementos duplicados do array para garantir que cada item seja único';
end;

function TTranslate_ptBR.TranslateUnknown: TErrorMessage;
begin
  Result.Error := 'Ocorreu um erro de validação desconhecido.';
  Result.Hint  := 'Nenhuma dica disponível para este erro.';
end;

function TTranslate_ptBR.TranslateUnresolvedReference: TErrorMessage;
begin
  Result.Error := 'Não foi possivel encontrar a referência "%s".';
  Result.Hint  := 'Verificar se o nome da referência esta correta.';
end;

end.
