unit JsonSchema.Localization.PtBR;

(*
--------------------------------------------------------------------------------
Portuguese (Pt-BR) localization implementation.
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
  /// <summary>Localization provider for Portuguese (Pt-BR) validation errors.</summary>
  TLocalizationPtBR = class(TLocalizationBase)
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

{ TLocalizationPtBR }

constructor TLocalizationPtBR.Create;
begin
  inherited Create(TLocale.PtBR);
end;

function TLocalizationPtBR.TranslateType(const pError: IValidationError): TTranslation;
var
  lExpected, lActual: string;
begin
  if not pError.Context.TryGetValue<string>('expected', lExpected) then
    lExpected := 'unknown';
  if not pError.Context.TryGetValue<string>('actual', lActual) then
    lActual := 'unknown';
  
  Result := TTranslation.Create(
    Format('Tipo esperado "%s" mas recebeu "%s"', [lExpected, lActual]),
    Format('Certifique-se de que o valor seja um JSON %s válido', [lExpected])
  );
end;

function TLocalizationPtBR.TranslateMinLength(const pError: IValidationError): TTranslation;
var
  lLimit, lActualLen: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Integer>('actual', lActualLen) then
    lActualLen := 0;
  
  Result := TTranslation.Create(
    Format('O tamanho da string %d é menor do que o mínimo permitido %d', [lActualLen, lLimit]),
    Format('Forneça uma string com pelo menos %d caracteres', [lLimit])
  );
end;

function TLocalizationPtBR.TranslateEnum(const pError: IValidationError): TTranslation;
var
  lAllowed: string;
begin
  if not pError.Context.TryGetValue<string>('allowed', lAllowed) then
    lAllowed := '[]';

  Result := TTranslation.Create(
    Format('O valor não é um dos valores permitidos: %s', [lAllowed]),
    'Certifique-se de que o valor corresponda a uma das opções permitidas'
  );
end;

function TLocalizationPtBR.TranslateConst(const pError: IValidationError): TTranslation;
var
  lExpected: string;
begin
  if not pError.Context.TryGetValue<string>('expected', lExpected) then
    lExpected := 'unknown';

  Result := TTranslation.Create(
    Format('O valor não corresponde à constante: %s', [lExpected]),
    Format('Certifique-se de que o valor seja exatamente %s', [lExpected])
  );
end;

function TLocalizationPtBR.TranslateRequired(const pError: IValidationError): TTranslation;
var
  lMissing: string;
begin
  if not pError.Context.TryGetValue<string>('missing', lMissing) then
    lMissing := 'unknown';

  Result := TTranslation.Create(
    Format('Propriedade obrigatória ausente: "%s"', [lMissing]),
    Format('Forneça a propriedade ausente "%s" no objeto', [lMissing])
  );
end;

function TLocalizationPtBR.TranslateMinimum(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Double;
begin
  if not pError.Context.TryGetValue<Double>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Double>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('O valor %g é menor do que o mínimo %g', [lActual, lLimit]),
    Format('Forneça um número maior ou igual a %g', [lLimit])
  );
end;

function TLocalizationPtBR.TranslateMaximum(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Double;
begin
  if not pError.Context.TryGetValue<Double>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Double>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('O valor %g é maior do que o máximo %g', [lActual, lLimit]),
    Format('Forneça um número menor ou igual a %g', [lLimit])
  );
end;

function TLocalizationPtBR.TranslateMaxLength(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Integer>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('O tamanho da string %d é maior do que o máximo permitido %d', [lActual, lLimit]),
    Format('Forneça uma string com no máximo %d caracteres', [lLimit])
  );
end;

function TLocalizationPtBR.TranslateMinItems(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Integer>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('A quantidade de itens no array %d é menor do que o mínimo permitido %d', [lActual, lLimit]),
    Format('Forneça um array com pelo menos %d itens', [lLimit])
  );
end;

function TLocalizationPtBR.TranslateMaxItems(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Integer>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('A quantidade de itens no array %d é maior do que o máximo permitido %d', [lActual, lLimit]),
    Format('Forneça um array com no máximo %d itens', [lLimit])
  );
end;

function TLocalizationPtBR.TranslateMultipleOf(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Double;
begin
  if not pError.Context.TryGetValue<Double>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Double>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('O valor %g não é um múltiplo de %g', [lActual, lLimit]),
    Format('Forneça um número que seja múltiplo de %g', [lLimit])
  );
end;

function TLocalizationPtBR.TranslateExclusiveMaximum(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Double;
begin
  if not pError.Context.TryGetValue<Double>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Double>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('O valor %g é maior ou igual ao limite máximo exclusivo %g', [lActual, lLimit]),
    Format('Forneça um número estritamente menor que %g', [lLimit])
  );
end;

function TLocalizationPtBR.TranslateExclusiveMinimum(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Double;
begin
  if not pError.Context.TryGetValue<Double>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Double>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('O valor %g é menor ou igual ao limite mínimo exclusivo %g', [lActual, lLimit]),
    Format('Forneça um número estritamente maior que %g', [lLimit])
  );
end;

function TLocalizationPtBR.TranslatePattern(const pError: IValidationError): TTranslation;
var
  lPattern, lActual: string;
begin
  if not pError.Context.TryGetValue<string>('pattern', lPattern) then
    lPattern := 'unknown';
  if not pError.Context.TryGetValue<string>('actual', lActual) then
    lActual := '';

  Result := TTranslation.Create(
    Format('O valor "%s" não corresponde ao padrão regex "%s"', [lActual, lPattern]),
    Format('Forneça um valor que corresponda ao padrão "%s"', [lPattern])
  );
end;

function TLocalizationPtBR.TranslateItems(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Falha na validação dos itens do array',
    'Certifique-se de que todos os elementos do array correspondam aos seus schemas'
  );
end;

function TLocalizationPtBR.TranslateAdditionalItems(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Integer>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('Itens adicionais encontrados (%d itens) mas o schema restringe itens adicionais além de %d', [lActual, lLimit]),
    'Certifique-se de que o array não contenha mais itens do que o definido pelo schema'
  );
end;

function TLocalizationPtBR.TranslateUniqueItems(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Os itens do array não são únicos',
    'Remova os elementos duplicados do array'
  );
end;

// Corresponds to 'contains'
function TLocalizationPtBR.TranslateContains(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'O array não contém nenhum item que valide contra o schema esperado',
    'Forneça pelo menos um item que corresponda à restrição'
  );
end;

function TLocalizationPtBR.TranslateMaxProperties(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Integer>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('O objeto possui %d propriedades, o máximo permitido é %d', [lActual, lLimit]),
    Format('Forneça um objeto com no máximo %d propriedades', [lLimit])
  );
end;

function TLocalizationPtBR.TranslateMinProperties(const pError: IValidationError): TTranslation;
var
  lLimit, lActual: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('limit', lLimit) then
    lLimit := 0;
  if not pError.Context.TryGetValue<Integer>('actual', lActual) then
    lActual := 0;

  Result := TTranslation.Create(
    Format('O objeto possui %d propriedades, o mínimo obrigatório é %d', [lActual, lLimit]),
    Format('Forneça um objeto com no mínimo %d propriedades', [lLimit])
  );
end;

function TLocalizationPtBR.TranslateProperties(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Falha na validação das propriedades',
    'Certifique-se de que todas as propriedades do objeto conformem com seus schemas'
  );
end;

function TLocalizationPtBR.TranslatePatternProperties(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Falha na validação das propriedades por padrão (patternProperties)',
    'Certifique-se de que todas as propriedades que casam com o padrão conformem com seus schemas'
  );
end;

function TLocalizationPtBR.TranslateAdditionalProperties(const pError: IValidationError): TTranslation;
var
  lPropName: string;
begin
  if not pError.Context.TryGetValue<string>('propertyName', lPropName) then
    lPropName := 'unknown';

  Result := TTranslation.Create(
    Format('A propriedade "%s" não é permitida neste objeto', [lPropName]),
    'Remova propriedades não documentadas do objeto JSON'
  );
end;

function TLocalizationPtBR.TranslateDependencies(const pError: IValidationError): TTranslation;
var
  lTrigger, lMissing: string;
begin
  if pError.Context.TryGetValue<string>('trigger', lTrigger) and pError.Context.TryGetValue<string>('missing', lMissing) then
  begin
    Result := TTranslation.Create(
      Format('A propriedade "%s" depende da propriedade "%s" que está ausente', [lTrigger, lMissing]),
      Format('Adicione a propriedade ausente obrigatória "%s"', [lMissing])
    );
  end else
  begin
    Result := TTranslation.Create(
      'Falha na validação de dependências',
      'Certifique-se de que todas as restrições de dependência de propriedades sejam atendidas'
    );
  end;
end;

function TLocalizationPtBR.TranslatePropertyNames(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Um ou mais nomes de propriedades falharam na validação',
    'Certifique-se de que todas as chaves do objeto correspondam ao schema de propertyNames'
  );
end;

function TLocalizationPtBR.TranslateAllOf(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'A validação falhou em relação aos sub-esquemas do allOf',
    'Certifique-se de que a instância esteja em conformidade com todos os sub-esquemas especificados'
  );
end;

function TLocalizationPtBR.TranslateAnyOf(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'A validação falhou em relação aos sub-esquemas do anyOf',
    'Certifique-se de que a instância esteja em conformidade com pelo menos um dos sub-esquemas'
  );
end;

function TLocalizationPtBR.TranslateOneOf(const pError: IValidationError): TTranslation;
var
  lActual: Integer;
begin
  if not pError.Context.TryGetValue<Integer>('actual', lActual) then
    lActual := 0;

  if lActual = 0 then
  begin
    Result := TTranslation.Create(
      'Conforme com 0 sub-esquemas quando exatamente 1 era esperado',
      'Certifique-se de que a instância esteja em conformidade com exatamente um dos sub-esquemas'
    );
  end else
  begin
    Result := TTranslation.Create(
      Format('Conforme com %d sub-esquemas quando exatamente 1 era esperado', [lActual]),
      'Certifique-se de que a instância esteja em conformidade com exatamente um dos sub-esquemas'
    );
  end;
end;

function TLocalizationPtBR.TranslateNot(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'A validação falhou em relação ao sub-esquema do not',
    'Certifique-se de que a instância não esteja em conformidade com o sub-esquema'
  );
end;

function TLocalizationPtBR.TranslateRef(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Falha na validação de referência ou referência não resolvida',
    'Certifique-se de que a referência aponte para um documento de schema válido e acessível'
  );
end;

function TLocalizationPtBR.TranslateSchema(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Incompatibilidade de declaração de schema',
    'Certifique-se de que o schema esteja em conformidade com o draft do JSON Schema especificado'
  );
end;

function TLocalizationPtBR.TranslateId(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create(
    'Incompatibilidade do identificador do schema',
    'Certifique-se de que o identificador do schema seja uma URI absoluta válida'
  );
end;

end.
