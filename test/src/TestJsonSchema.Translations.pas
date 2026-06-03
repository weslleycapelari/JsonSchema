unit TestJsonSchema.Translations;

(*
--------------------------------------------------------------------------------
Unit and integration tests for localized error translators (ILocalization).
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Results,
  JsonSchema.Validator,
  JsonSchema.Localization.Enums,
  JsonSchema.Localization.Interfaces,
  JsonSchema.Localization.Base,
  JsonSchema.Localization.EnUS,
  JsonSchema.Localization.PtBR,
  JsonSchema.Localization;

type
  /// <summary>Mock Portuguese (Pt-BR) translator inheriting from TLocalizationPtBR to test custom plugin overrides.</summary>
  TPtBRLocalizationMock = class(TLocalizationPtBR)
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
  end;

  /// <summary>DUnit test suite to validate translation formatting, fallbacks, and translator injections.</summary>
  TTestTranslations = class(TTestCase)
  private
    FValidator: TJsonSchemaValidator;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // Original tests
    procedure TestEnUSTranslatorTypeKeyword;
    procedure TestEnUSTranslatorMinLengthKeyword;
    procedure TestCustomTranslatorInjection;
    procedure TestFallbackTranslationForUnknownKeyword;

    // Unit tests
    procedure TestLocalizationEngineRegisterAndResolve;
    procedure TestLocalizationEngineIsRegistered;
    procedure TestLocalizationEngineResolveUnregisteredThrows;
    procedure TestLocalizationEngineRegisterNilDoesNotCrash;
    procedure TestDirectInterfaceMethodCallsEnUS;
    procedure TestDirectInterfaceMethodCallsPtBR;

    // Edge case tests
    procedure TestTranslateTypeWithEmptyContext;
    procedure TestTranslateMinLengthWithEmptyContext;
    procedure TestResolveWithInvalidLocaleEnum;

    // Smoke tests
    procedure TestValidatorSmokeRunAllSupportedLocales;

    // E2E tests
    procedure TestE2EValidationAndLanguageSwitching;
  end;

implementation

{ TPtBRLocalizationMock }

constructor TPtBRLocalizationMock.Create;
begin
  inherited Create;
end;

function TPtBRLocalizationMock.TranslateType(const pError: IValidationError): TTranslation;
var
  lExpected, lActual: string;
begin
  lExpected := pError.Context.GetValue<string>('expected');
  lActual := pError.Context.GetValue<string>('actual');
  
  Result := TTranslation.Create(
    Format('Mock Tipo esperado "%s" mas recebeu "%s"', [lExpected, lActual]),
    Format('Mock Certifique-se de enviar um %s válido no JSON', [lExpected])
  );
end;

function TPtBRLocalizationMock.TranslateMinLength(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create('Mock MinLength erro', 'Mock Resolution');
end;

function TPtBRLocalizationMock.TranslateEnum(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create('Mock Enum erro', 'Mock Resolution');
end;

function TPtBRLocalizationMock.TranslateConst(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create('Mock Const erro', 'Mock Resolution');
end;

function TPtBRLocalizationMock.TranslateRequired(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create('Mock Required erro', 'Mock Resolution');
end;

function TPtBRLocalizationMock.TranslateMinimum(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create('Mock Minimum erro', 'Mock Resolution');
end;

function TPtBRLocalizationMock.TranslateMaximum(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create('Mock Maximum erro', 'Mock Resolution');
end;

function TPtBRLocalizationMock.TranslateMaxLength(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create('Mock MaxLength erro', 'Mock Resolution');
end;

function TPtBRLocalizationMock.TranslateMinItems(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create('Mock MinItems erro', 'Mock Resolution');
end;

function TPtBRLocalizationMock.TranslateMaxItems(const pError: IValidationError): TTranslation;
begin
  Result := TTranslation.Create('Mock MaxItems erro', 'Mock Resolution');
end;

{ TTestTranslations }

procedure TTestTranslations.SetUp;
begin
  inherited;
  FValidator := TJsonSchemaValidator.Create;
end;

procedure TTestTranslations.TearDown;
begin
  FValidator.Free;
  inherited;
end;

procedure TTestTranslations.TestEnUSTranslatorTypeKeyword;
var
  lSchema, lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lSchema := TJSONObject.ParseJSONValue('{"type": "string"}');
  lInstance := TJSONNumber.Create(123);
  try
    FValidator.Locale := TLocale.EnUS;
    lResult := FValidator.Validate(lSchema, lInstance);
    
    CheckFalse(lResult.IsValid, 'Deve ser inválido');
    CheckEquals(1, Length(lResult.Errors), 'Deve ter 1 erro');
    CheckEquals('type', lResult.Errors[0].Keyword);
    CheckEquals('Expected type "string" but got "number"', lResult.Errors[0].Message);
    CheckEquals('Ensure the value is a valid JSON string', lResult.Errors[0].Resolution);
  finally
    lSchema.Free;
    lInstance.Free;
  end;
end;

procedure TTestTranslations.TestEnUSTranslatorMinLengthKeyword;
var
  lSchema, lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lSchema := TJSONObject.ParseJSONValue('{"minLength": 5}');
  lInstance := TJSONString.Create('abc');
  try
    FValidator.Locale := TLocale.EnUS;
    lResult := FValidator.Validate(lSchema, lInstance);
    
    CheckFalse(lResult.IsValid, 'Deve ser inválido');
    CheckEquals(1, Length(lResult.Errors), 'Deve ter 1 erro');
    CheckEquals('minLength', lResult.Errors[0].Keyword);
    CheckEquals('String length 3 is less than minLength 5', lResult.Errors[0].Message);
    CheckEquals('Provide a string with at least 5 characters', lResult.Errors[0].Resolution);
  finally
    lSchema.Free;
    lInstance.Free;
  end;
end;

procedure TTestTranslations.TestCustomTranslatorInjection;
var
  lSchema, lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  // Register custom mock localization into the validator engine
  FValidator.Engine.RegisterLocalization(TPtBRLocalizationMock.Create);
  FValidator.Locale := TLocale.PtBR;
  
  lSchema := TJSONObject.ParseJSONValue('{"type": "number"}');
  lInstance := TJSONString.Create('texto');
  try
    lResult := FValidator.Validate(lSchema, lInstance);
    
    CheckFalse(lResult.IsValid, 'Deve ser inválido');
    CheckEquals('type', lResult.Errors[0].Keyword);
    
    // Verify that the custom Portuguese translation was injected and formatted correctly
    CheckEquals('Mock Tipo esperado "number" mas recebeu "string"', lResult.Errors[0].Message);
    CheckEquals('Mock Certifique-se de enviar um number válido no JSON', lResult.Errors[0].Resolution);
  finally
    lSchema.Free;
    lInstance.Free;
  end;
end;

procedure TTestTranslations.TestFallbackTranslationForUnknownKeyword;
var
  lTranslator: ILocalization;
  lError: IValidationError;
  lTranslation: TTranslation;
begin
  lTranslator := TLocalizationEnUS.Create;
  lError := TValidationError.Create('unknownKeyword', nil);
  
  lTranslation := lTranslator.Translate(lError);
  
  CheckEquals('Validation failed for keyword: unknownKeyword', lTranslation.Message);
  CheckEquals('Check the JSON Schema documentation for this keyword', lTranslation.Resolution);
end;

procedure TTestTranslations.TestLocalizationEngineRegisterAndResolve;
var
  lEngine: TLocalizationEngine;
  lUS: ILocalization;
  lResolved: ILocalization;
begin
  lEngine := TLocalizationEngine.Create;
  try
    lUS := TLocalizationEnUS.Create;
    lEngine.RegisterLocalization(lUS);
    
    CheckTrue(lEngine.IsRegistered(TLocale.EnUS), 'EnUS deve estar registrado');
    lResolved := lEngine.Resolve(TLocale.EnUS);
    CheckTrue(lUS = lResolved, 'Deve resolver a mesma instancia');
  finally
    lEngine.Free;
  end;
end;

procedure TTestTranslations.TestLocalizationEngineIsRegistered;
var
  lEngine: TLocalizationEngine;
begin
  lEngine := TLocalizationEngine.Create;
  try
    CheckFalse(lEngine.IsRegistered(TLocale.EnUS), 'Nao deve estar registrado inicialmente');
    CheckFalse(lEngine.IsRegistered(TLocale.PtBR), 'Nao deve estar registrado inicialmente');
    
    lEngine.RegisterLocalization(TLocalizationEnUS.Create);
    CheckTrue(lEngine.IsRegistered(TLocale.EnUS), 'EnUS deve estar registrado agora');
    CheckFalse(lEngine.IsRegistered(TLocale.PtBR), 'PtBR ainda nao deve estar registrado');
  finally
    lEngine.Free;
  end;
end;

procedure TTestTranslations.TestLocalizationEngineResolveUnregisteredThrows;
var
  lEngine: TLocalizationEngine;
  lResolved: ILocalization;
  lPassed: Boolean;
begin
  lEngine := TLocalizationEngine.Create;
  try
    lPassed := False;
    try
      lResolved := lEngine.Resolve(TLocale.EnUS);
    except
      on E: Exception do
      begin
        lPassed := True;
        CheckTrue(Pos('not registered', E.Message) > 0, 'Mensagem de exceção deve indicar que não está registrado');
      end;
    end;
    CheckTrue(lPassed, 'Deve levantar uma exceção ao tentar resolver locale não registrado');
  finally
    lEngine.Free;
  end;
end;

procedure TTestTranslations.TestLocalizationEngineRegisterNilDoesNotCrash;
var
  lEngine: TLocalizationEngine;
begin
  lEngine := TLocalizationEngine.Create;
  try
    lEngine.RegisterLocalization(nil); // Should not crash/AV
    CheckFalse(lEngine.IsRegistered(TLocale.EnUS), 'Nao deve registrar nil');
  finally
    lEngine.Free;
  end;
end;

procedure TTestTranslations.TestDirectInterfaceMethodCallsEnUS;
var
  lTranslator: ILocalization;
  lContext: TJSONObject;
  lError: IValidationError;
  lTranslation: TTranslation;
begin
  lTranslator := TLocalizationEnUS.Create;
  
  // Test TranslateType directly through interface function
  lContext := TJSONObject.Create;
  try
    lContext.AddPair('expected', 'string');
    lContext.AddPair('actual', 'number');
    lError := TValidationError.Create('type', lContext);
    
    lTranslation := lTranslator.TranslateType(lError);
    CheckEquals('Expected type "string" but got "number"', lTranslation.Message);
    CheckEquals('Ensure the value is a valid JSON string', lTranslation.Resolution);
  finally
    lContext.Free;
  end;

  // Test TranslateMinLength directly through interface function
  lContext := TJSONObject.Create;
  try
    lContext.AddPair('limit', TJSONNumber.Create(5));
    lContext.AddPair('actual', TJSONNumber.Create(3));
    lError := TValidationError.Create('minLength', lContext);
    
    lTranslation := lTranslator.TranslateMinLength(lError);
    CheckEquals('String length 3 is less than minLength 5', lTranslation.Message);
    CheckEquals('Provide a string with at least 5 characters', lTranslation.Resolution);
  finally
    lContext.Free;
  end;
end;

procedure TTestTranslations.TestDirectInterfaceMethodCallsPtBR;
var
  lTranslator: ILocalization;
  lContext: TJSONObject;
  lError: IValidationError;
  lTranslation: TTranslation;
begin
  lTranslator := TLocalizationPtBR.Create;
  
  // Test TranslateType directly through interface function
  lContext := TJSONObject.Create;
  try
    lContext.AddPair('expected', 'integer');
    lContext.AddPair('actual', 'boolean');
    lError := TValidationError.Create('type', lContext);
    
    lTranslation := lTranslator.TranslateType(lError);
    CheckEquals('Tipo esperado "integer" mas recebeu "boolean"', lTranslation.Message);
    CheckEquals('Certifique-se de que o valor seja um JSON integer válido', lTranslation.Resolution);
  finally
    lContext.Free;
  end;

  // Test TranslateMinLength directly through interface function
  lContext := TJSONObject.Create;
  try
    lContext.AddPair('limit', TJSONNumber.Create(10));
    lContext.AddPair('actual', TJSONNumber.Create(2));
    lError := TValidationError.Create('minLength', lContext);
    
    lTranslation := lTranslator.TranslateMinLength(lError);
    CheckEquals('O tamanho da string 2 é menor do que o mínimo permitido 10', lTranslation.Message);
    CheckEquals('Forneça uma string com pelo menos 10 caracteres', lTranslation.Resolution);
  finally
    lContext.Free;
  end;
end;

procedure TTestTranslations.TestTranslateTypeWithEmptyContext;
var
  lTranslatorUS, lTranslatorBR: ILocalization;
  lError: IValidationError;
  lTranslation: TTranslation;
begin
  lError := TValidationError.Create('type', nil); // Empty/nil context
  
  lTranslatorUS := TLocalizationEnUS.Create;
  lTranslation := lTranslatorUS.TranslateType(lError);
  CheckEquals('Expected type "unknown" but got "unknown"', lTranslation.Message);
  CheckEquals('Ensure the value is a valid JSON unknown', lTranslation.Resolution);
  
  lTranslatorBR := TLocalizationPtBR.Create;
  lTranslation := lTranslatorBR.TranslateType(lError);
  CheckEquals('Tipo esperado "unknown" mas recebeu "unknown"', lTranslation.Message);
  CheckEquals('Certifique-se de que o valor seja um JSON unknown válido', lTranslation.Resolution);
end;

procedure TTestTranslations.TestTranslateMinLengthWithEmptyContext;
var
  lTranslatorUS, lTranslatorBR: ILocalization;
  lError: IValidationError;
  lTranslation: TTranslation;
begin
  lError := TValidationError.Create('minLength', nil); // Empty/nil context
  
  lTranslatorUS := TLocalizationEnUS.Create;
  lTranslation := lTranslatorUS.TranslateMinLength(lError);
  CheckEquals('String length 0 is less than minLength 0', lTranslation.Message);
  CheckEquals('Provide a string with at least 0 characters', lTranslation.Resolution);
  
  lTranslatorBR := TLocalizationPtBR.Create;
  lTranslation := lTranslatorBR.TranslateMinLength(lError);
  CheckEquals('O tamanho da string 0 é menor do que o mínimo permitido 0', lTranslation.Message);
  CheckEquals('Forneça uma string com pelo menos 0 caracteres', lTranslation.Resolution);
end;

procedure TTestTranslations.TestResolveWithInvalidLocaleEnum;
var
  lEngine: TLocalizationEngine;
  lResolved: ILocalization;
  lPassed: Boolean;
begin
  lEngine := TLocalizationEngine.Create;
  try
    lPassed := False;
    try
      lResolved := lEngine.Resolve(TLocale(999));
    except
      on E: Exception do
      begin
        lPassed := True;
        CheckTrue(Pos('not registered', E.Message) > 0, 'Mensagem de exceção deve indicar que não está registrado');
      end;
    end;
    CheckTrue(lPassed, 'Deve levantar uma exceção ao tentar resolver locale ordinal inválido');
  finally
    lEngine.Free;
  end;
end;

procedure TTestTranslations.TestValidatorSmokeRunAllSupportedLocales;
var
  lSchema, lInstance: TJSONValue;
  lResult: IValidationResult;
  lLocale: TLocale;
begin
  lSchema := TJSONObject.ParseJSONValue('{"type": "string", "minLength": 5}');
  lInstance := TJSONNumber.Create(123);
  try
    // Test that the validator can run validation under every locale without raising unexpected errors
    for lLocale := Low(TLocale) to High(TLocale) do
    begin
      FValidator.Locale := lLocale;
      lResult := FValidator.Validate(lSchema, lInstance);
      CheckFalse(lResult.IsValid, 'Deve ser inválido sob o locale ' + IntToStr(Ord(lLocale)));
      CheckTrue(Length(lResult.Errors) > 0, 'Deve retornar erros');
      CheckNotEquals('', lResult.Errors[0].Message, 'Erro deve conter mensagem');
      CheckNotEquals('', lResult.Errors[0].Resolution, 'Erro deve conter resolução');
    end;
  finally
    lSchema.Free;
    lInstance.Free;
  end;
end;

procedure TTestTranslations.TestE2EValidationAndLanguageSwitching;
var
  lSchema, lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lSchema := TJSONObject.ParseJSONValue('{"type": "string", "minLength": 5}');
  lInstance := TJSONString.Create('abc');
  try
    // E2E Run 1: EnUS
    FValidator.Locale := TLocale.EnUS;
    lResult := FValidator.Validate(lSchema, lInstance);
    CheckFalse(lResult.IsValid);
    CheckEquals(1, Length(lResult.Errors));
    CheckEquals('String length 3 is less than minLength 5', lResult.Errors[0].Message);
    CheckEquals('Provide a string with at least 5 characters', lResult.Errors[0].Resolution);
    
    // E2E Run 2: PtBR (Dynamic Switch)
    FValidator.Locale := TLocale.PtBR;
    lResult := FValidator.Validate(lSchema, lInstance);
    CheckFalse(lResult.IsValid);
    CheckEquals(1, Length(lResult.Errors));
    CheckEquals('O tamanho da string 3 é menor do que o mínimo permitido 5', lResult.Errors[0].Message);
    CheckEquals('Forneça uma string com pelo menos 5 caracteres', lResult.Errors[0].Resolution);
  finally
    lSchema.Free;
    lInstance.Free;
  end;
end;

initialization
  RegisterTest(TTestTranslations.Suite);

end.
