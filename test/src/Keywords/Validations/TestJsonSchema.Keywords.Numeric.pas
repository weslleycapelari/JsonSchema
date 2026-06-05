unit TestJsonSchema.Keywords.Numeric;

(*
--------------------------------------------------------------------------------
Unit tests for the 'minimum' and 'maximum' validation keywords.
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Keywords.Minimum,
  JsonSchema.Keywords.Maximum,
  JsonSchema.Keywords.MultipleOf,
  JsonSchema.Keywords.ExclusiveMaximum,
  JsonSchema.Keywords.ExclusiveMinimum,
  JsonSchema.Results;

type
  TTestNumericKeywords = class(TTestCase)
  published
    procedure TestMinimumPasses;
    procedure TestMinimumFails;
    procedure TestMinimumIgnoredOnNonNumbers;
    procedure TestMaximumPasses;
    procedure TestMaximumFails;
    procedure TestMaximumIgnoredOnNonNumbers;
    procedure TestMultipleOfPasses;
    procedure TestMultipleOfFails;
    procedure TestMultipleOfIgnoredOnNonNumbers;
    procedure TestExclusiveMinimumPasses;
    procedure TestExclusiveMinimumFails;
    procedure TestExclusiveMinimumIgnoredOnNonNumbers;
    procedure TestExclusiveMaximumPasses;
    procedure TestExclusiveMaximumFails;
    procedure TestExclusiveMaximumIgnoredOnNonNumbers;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TTestNumericKeywords }

procedure TTestNumericKeywords.TestMinimumPasses;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONNumber.Create(10);
  try
    lKeyword := TMinimumKeyword.Create(10.0);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Valor igual ao mínimo deve ser válido');
  finally
    lInstance.Free;
  end;

  lInstance := TJSONNumber.Create(15.5);
  try
    lKeyword := TMinimumKeyword.Create(10.0);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Valor maior do que o mínimo deve ser válido');
  finally
    lInstance.Free;
  end;
end;

procedure TTestNumericKeywords.TestMinimumFails;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONNumber.Create(9.99);
  try
    lKeyword := TMinimumKeyword.Create(10.0);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Valor menor do que o mínimo deve ser inválido');
    CheckEquals(KEYWORD_MINIMUM, lResult.Errors[0].Keyword);
    CheckEquals(10.0, lResult.Errors[0].Context.GetValue<Double>('limit'), 0.0001);
    CheckEquals(9.99, lResult.Errors[0].Context.GetValue<Double>('actual'), 0.0001);
  finally
    lInstance.Free;
  end;
end;

procedure TTestNumericKeywords.TestMinimumIgnoredOnNonNumbers;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('9');
  try
    lKeyword := TMinimumKeyword.Create(10.0);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Validação de mínimo deve ser ignorada para strings');
  finally
    lInstance.Free;
  end;
end;

procedure TTestNumericKeywords.TestMaximumPasses;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONNumber.Create(100);
  try
    lKeyword := TMaximumKeyword.Create(100.0);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Valor igual ao máximo deve ser válido');
  finally
    lInstance.Free;
  end;

  lInstance := TJSONNumber.Create(50);
  try
    lKeyword := TMaximumKeyword.Create(100.0);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Valor menor do que o máximo deve ser válido');
  finally
    lInstance.Free;
  end;
end;

procedure TTestNumericKeywords.TestMaximumFails;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONNumber.Create(100.01);
  try
    lKeyword := TMaximumKeyword.Create(100.0);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Valor maior do que o máximo deve ser inválido');
    CheckEquals(KEYWORD_MAXIMUM, lResult.Errors[0].Keyword);
    CheckEquals(100.0, lResult.Errors[0].Context.GetValue<Double>('limit'), 0.0001);
    CheckEquals(100.01, lResult.Errors[0].Context.GetValue<Double>('actual'), 0.0001);
  finally
    lInstance.Free;
  end;
end;

procedure TTestNumericKeywords.TestMaximumIgnoredOnNonNumbers;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('101');
  try
    lKeyword := TMaximumKeyword.Create(100.0);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Validação de máximo deve ser ignorada para strings');
  finally
    lInstance.Free;
  end;
end;

procedure TTestNumericKeywords.TestMultipleOfPasses;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONNumber.Create(15.0);
  try
    lKeyword := TMultipleOfKeyword.Create(5.0);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, '15.0 deve ser múltiplo de 5.0');
  finally
    lInstance.Free;
  end;

  lInstance := TJSONNumber.Create(0.0);
  try
    lKeyword := TMultipleOfKeyword.Create(2.5);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, '0.0 deve ser múltiplo de 2.5');
  finally
    lInstance.Free;
  end;
end;

procedure TTestNumericKeywords.TestMultipleOfFails;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONNumber.Create(7.0);
  try
    lKeyword := TMultipleOfKeyword.Create(3.0);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, '7.0 não deve ser múltiplo de 3.0');
    CheckEquals(KEYWORD_MULTIPLEOF, lResult.Errors[0].Keyword);
    CheckEquals(3.0, lResult.Errors[0].Context.GetValue<Double>('limit'));
    CheckEquals(7.0, lResult.Errors[0].Context.GetValue<Double>('actual'));
  finally
    lInstance.Free;
  end;
end;

procedure TTestNumericKeywords.TestMultipleOfIgnoredOnNonNumbers;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('15');
  try
    lKeyword := TMultipleOfKeyword.Create(5.0);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Múltiplo de deve ser ignorado para strings');
  finally
    lInstance.Free;
  end;
end;

procedure TTestNumericKeywords.TestExclusiveMinimumPasses;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONNumber.Create(10.01);
  try
    lKeyword := TExclusiveMinimumKeyword.Create(10.0);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, '10.01 é maior do que exclusivo 10.0');
  finally
    lInstance.Free;
  end;
end;

procedure TTestNumericKeywords.TestExclusiveMinimumFails;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONNumber.Create(10.0);
  try
    lKeyword := TExclusiveMinimumKeyword.Create(10.0);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, '10.0 não é maior do que exclusivo 10.0');
    CheckEquals(KEYWORD_EXCLUSIVEMINIMUM, lResult.Errors[0].Keyword);
  finally
    lInstance.Free;
  end;

  lInstance := TJSONNumber.Create(9.9);
  try
    lKeyword := TExclusiveMinimumKeyword.Create(10.0);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, '9.9 não é maior do que exclusivo 10.0');
  finally
    lInstance.Free;
  end;
end;

procedure TTestNumericKeywords.TestExclusiveMinimumIgnoredOnNonNumbers;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('11');
  try
    lKeyword := TExclusiveMinimumKeyword.Create(10.0);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Ignorado em strings');
  finally
    lInstance.Free;
  end;
end;

procedure TTestNumericKeywords.TestExclusiveMaximumPasses;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONNumber.Create(9.99);
  try
    lKeyword := TExclusiveMaximumKeyword.Create(10.0);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, '9.99 é menor do que exclusivo 10.0');
  finally
    lInstance.Free;
  end;
end;

procedure TTestNumericKeywords.TestExclusiveMaximumFails;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONNumber.Create(10.0);
  try
    lKeyword := TExclusiveMaximumKeyword.Create(10.0);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, '10.0 não é menor do que exclusivo 10.0');
    CheckEquals(KEYWORD_EXCLUSIVEMAXIMUM, lResult.Errors[0].Keyword);
  finally
    lInstance.Free;
  end;

  lInstance := TJSONNumber.Create(10.1);
  try
    lKeyword := TExclusiveMaximumKeyword.Create(10.0);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, '10.1 não é menor do que exclusivo 10.0');
  finally
    lInstance.Free;
  end;
end;

procedure TTestNumericKeywords.TestExclusiveMaximumIgnoredOnNonNumbers;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('9');
  try
    lKeyword := TExclusiveMaximumKeyword.Create(10.0);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Ignorado em strings');
  finally
    lInstance.Free;
  end;
end;

initialization
  RegisterTest(TTestNumericKeywords.Suite);

end.
