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

{ TTranslate_ptBR }

function TTranslate_ptBR.TranslateAllOf: TErrorMessage;
begin
  Result.Error := 'O valor n�o � v�lido contra todos os sub-schemas em "allOf". Falhou no �ndice %d.';
  Result.Hint  := 'O valor deve atender a todas as condi��es especificadas nos schemas dentro de "allOf".';
end;

function TTranslate_ptBR.TranslateAnyOf: TErrorMessage;
begin
  Result.Error := 'O valor n�o � v�lido contra nenhum dos sub-schemas em "anyOf".';
  Result.Hint  := 'O valor deve atender a pelo menos uma das condi��es especificadas nos schemas dentro de "anyOf".';
end;

function TTranslate_ptBR.TranslateConstValueMismatch: TErrorMessage;
begin
  Result.Error := 'O valor n�o corresponde ao valor constante esperado';
  Result.Hint  := 'O valor deve ser exatamente igual a %s';
end;

function TTranslate_ptBR.TranslateContains: TErrorMessage;
begin
  Result.Error := 'O array n�o cont�m nenhum item que corresponda ao schema de "contains".';
  Result.Hint  := 'Adicione pelo menos um item ao array que seja v�lido de acordo com o schema especificado em "contains".';
end;

function TTranslate_ptBR.TranslateDependentRequired: TErrorMessage;
begin
  Result.Error := 'A presen�a da propriedade "%s" requer que a(s) propriedade(s) "%s" tamb�m esteja(m) presente(s).';
  Result.Hint  := 'Quando a propriedade "%s" existir, certifique-se de que as propriedades "%s" tamb�m sejam inclu�das no objeto.';
end;

function TTranslate_ptBR.TranslateEnumValueMismatch: TErrorMessage;
begin
  Result.Error := 'O valor n�o corresponde a nenhum dos valores permitidos na enumera��o';
  Result.Hint  := 'O valor deve ser exatamente um dos seguintes: %s';
end;

function TTranslate_ptBR.TranslateExclusiveMaximum: TErrorMessage;
begin
  Result.Error := 'O valor � igual ou excede o m�ximo exclusivo permitido de %s';
  Result.Hint  := 'O valor deve ser menor que %s';
end;

function TTranslate_ptBR.TranslateExclusiveMinimum: TErrorMessage;
begin
  Result.Error := 'O valor � igual ou menor que o m�nimo exclusivo permitido de %s';
  Result.Hint  := 'O valor deve ser maior que %s';
end;

function TTranslate_ptBR.TranslateInvalidFormat: TErrorMessage;
begin
  Result.Error := 'O valor n�o corresponde ao formato esperado de "%s".';
  Result.Hint  := 'Corrija o valor para que siga o formato "%s". Por exemplo, uma data deve estar no formato "AAAA-MM-DD".';
end;

function TTranslate_ptBR.TranslateInvalidPropertyName: TErrorMessage;
begin
  Result.Error := 'O nome da propriedade "%s" n�o � v�lido de acordo com o schema de "propertyNames".';
  Result.Hint  := 'Renomeie a propriedade "%s" para que ela corresponda ao schema definido em "propertyNames".';
end;

function TTranslate_ptBR.TranslateInvalidType: TErrorMessage;
begin
  Result.Error := 'O valor fornecido n�o corresponde ao tipo esperado. Esperado: "%s", encontrado: "%s"';
  Result.Hint  := 'Verifique se o valor do campo est� formatado corretamente para o tipo "%s". Por exemplo, valores num�ricos n�o devem estar entre aspas';
end;

function TTranslate_ptBR.TranslateMaxContains: TErrorMessage;
begin
  Result.Error := 'O array cont�m %d itens que correspondem ao schema "contains", excedendo o m�ximo de %d.';
  Result.Hint  := 'Remova os itens correspondentes em excesso. O m�ximo permitido � %d.';
end;

function TTranslate_ptBR.TranslateMaximum: TErrorMessage;
begin
  Result.Error := 'O valor excede o m�ximo permitido de %s';
  Result.Hint  := 'O valor deve ser menor ou igual a %s';
end;

function TTranslate_ptBR.TranslateMaxItems: TErrorMessage;
begin
  Result.Error := 'O array excede o m�ximo de %d itens';
  Result.Hint  := 'O array n�o deve conter mais de %d itens';
end;

function TTranslate_ptBR.TranslateMaxLength: TErrorMessage;
begin
  Result.Error := 'A string cont�m mais caracteres que o m�ximo de %d';
  Result.Hint  := 'A string deve ter no m�ximo %d caracteres';
end;

function TTranslate_ptBR.TranslateMaxProperties: TErrorMessage;
begin
  Result.Error := 'O objeto cont�m mais propriedades que o m�ximo de %d';
  Result.Hint  := 'O objeto deve conter no m�ximo %d propriedades';
end;

function TTranslate_ptBR.TranslateMinContains: TErrorMessage;
begin
  Result.Error := 'O array cont�m %d itens que correspondem ao schema "contains", o que � menos que o m�nimo de %d.';
  Result.Hint  := 'Adicione mais itens correspondentes. O m�nimo exigido � %d.';
end;

function TTranslate_ptBR.TranslateMinimum: TErrorMessage;
begin
  Result.Error := 'O valor � menor que o m�nimo permitido de %s';
  Result.Hint  := 'O valor deve ser maior ou igual a %s';
end;

function TTranslate_ptBR.TranslateMinItems: TErrorMessage;
begin
  Result.Error := 'O array cont�m menos que o m�nimo de %d itens';
  Result.Hint  := 'O array deve conter pelo menos %d itens';
end;

function TTranslate_ptBR.TranslateMinLength: TErrorMessage;
begin
  Result.Error := 'A string cont�m menos caracteres que o m�nimo de %d';
  Result.Hint  := 'A string deve ter no m�nimo %d caracteres';
end;

function TTranslate_ptBR.TranslateMinProperties: TErrorMessage;
begin
  Result.Error := 'O objeto cont�m menos propriedades que o m�nimo de %d';
  Result.Hint  := 'O objeto deve conter pelo menos %d propriedades';
end;

function TTranslate_ptBR.TranslateMultipleOf: TErrorMessage;
begin
  Result.Error := 'O valor n�o � um m�ltiplo de %s';
  Result.Hint  := 'Ajuste o valor para que seja divis�vel por %s sem deixar resto';
end;

function TTranslate_ptBR.TranslateNot: TErrorMessage;
begin
  Result.Error := 'O valor foi validado com sucesso pelo schema em "not", o que n�o � permitido.';
  Result.Hint  := 'O valor n�o deve ser v�lido de acordo com o schema especificado dentro da cl�usula "not".';
end;

function TTranslate_ptBR.TranslateOneOf_MultipleMatches: TErrorMessage;
begin
  Result.Error := 'O valor � v�lido contra m�ltiplos sub-schemas em "oneOf".';
  Result.Hint  := 'O valor deve corresponder a exatamente um dos schemas definidos em "oneOf". Atualmente, corresponde a mais de um.';
end;

function TTranslate_ptBR.TranslateOneOf_NoMatch: TErrorMessage;
begin
  Result.Error := 'O valor n�o � v�lido contra nenhum dos sub-schemas em "oneOf".';
  Result.Hint  := 'O valor deve corresponder a exatamente um dos schemas definidos em "oneOf". Atualmente, n�o corresponde a nenhum.';
end;

function TTranslate_ptBR.TranslatePattern: TErrorMessage;
begin
  Result.Error := 'A string n�o corresponde ao padr�o de express�o regular exigido: %s';
  Result.Hint  := 'Verifique o formato da string para garantir que corresponda ao padr�o regex esperado';
end;

function TTranslate_ptBR.TranslateRequiredPropertyMissing: TErrorMessage;
begin
  Result.Error := 'A propriedade obrigat�ria "%s" n�o foi encontrada no objeto';
  Result.Hint  := 'Adicione a propriedade "%s" ao objeto com um valor v�lido';
end;

function TTranslate_ptBR.TranslateSchemaIsFalse: TErrorMessage;
begin
  Result.Error := 'A valida��o falhou porque o schema � "false".';
  Result.Hint  := 'O schema "false" pro�be qualquer valor. A valida��o nunca passar� neste ponto.';
end;

function TTranslate_ptBR.TranslateUnevaluatedItems: TErrorMessage;
begin
  Result.Error := 'O array cont�m itens n�o permitidos a partir do �ndice %d.';
  Result.Hint  := 'Remova os itens adicionais ou ajuste o schema (usando "items" ou "prefixItems") para permiti-los.';
end;

function TTranslate_ptBR.TranslateUnevaluatedProperties: TErrorMessage;
begin
  Result.Error := 'O objeto cont�m a(s) propriedade(s) n�o permitida(s): %s.';
  Result.Hint  := 'Remova as propriedades n�o especificadas ou ajuste o schema (usando "properties", "patternProperties" ou "additionalProperties") para permiti-las.';
end;

function TTranslate_ptBR.TranslateUniqueItems: TErrorMessage;
begin
  Result.Error := 'O array cont�m itens duplicados. O item "%s" aparece mais de uma vez';
  Result.Hint  := 'Remova os elementos duplicados do array para garantir que cada item seja �nico';
end;

function TTranslate_ptBR.TranslateUnknown: TErrorMessage;
begin
  Result.Error := 'Ocorreu um erro de valida��o desconhecido.';
  Result.Hint  := 'Nenhuma dica dispon�vel para este erro.';
end;

function TTranslate_ptBR.TranslateUnresolvedReference: TErrorMessage;
begin
  Result.Error := 'Não foi possível encontrar a referência "%s".';
  Result.Hint  := 'Verificar se o nome da referência está correto.';
end;

function TTranslate_ptBR.TranslateUnsupportedVocabulary: TErrorMessage;
begin
  Result.Error := 'O vocabulário obrigatório "%s" não é suportado.';
  Result.Hint  := 'Use apenas vocabulários suportados por este validador ou marque vocabulários desconhecidos como opcionais.';
end;

end.
