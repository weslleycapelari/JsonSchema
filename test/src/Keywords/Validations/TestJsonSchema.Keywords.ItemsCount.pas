unit TestJsonSchema.Keywords.ItemsCount;

(*
--------------------------------------------------------------------------------
Unit tests for the 'minItems' and 'maxItems' validation keywords.
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Keywords.MinItems,
  JsonSchema.Keywords.MaxItems,
  JsonSchema.Results;

type
  TTestItemsCountKeywords = class(TTestCase)
  published
    procedure TestMinItemsPasses;
    procedure TestMinItemsFails;
    procedure TestMinItemsIgnoredOnNonArrays;
    procedure TestMaxItemsPasses;
    procedure TestMaxItemsFails;
    procedure TestMaxItemsIgnoredOnNonArrays;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TTestItemsCountKeywords }

procedure TTestItemsCountKeywords.TestMinItemsPasses;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONObject.ParseJSONValue('[1, 2, 3]');
  try
    lKeyword := TMinItemsKeyword.Create(3);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Quantidade exata deve passar no minItems');
  finally
    lInstance.Free;
  end;

  lInstance := TJSONObject.ParseJSONValue('[1, 2, 3, 4]');
  try
    lKeyword := TMinItemsKeyword.Create(3);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Quantidade maior deve passar no minItems');
  finally
    lInstance.Free;
  end;
end;

procedure TTestItemsCountKeywords.TestMinItemsFails;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONObject.ParseJSONValue('[1, 2]');
  try
    lKeyword := TMinItemsKeyword.Create(3);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Quantidade menor deve falhar no minItems');
    CheckEquals(KEYWORD_MINITEMS, lResult.Errors[0].Keyword);
    CheckEquals(3, lResult.Errors[0].Context.GetValue<Integer>('limit'));
    CheckEquals(2, lResult.Errors[0].Context.GetValue<Integer>('actual'));
  finally
    lInstance.Free;
  end;
end;

procedure TTestItemsCountKeywords.TestMinItemsIgnoredOnNonArrays;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('hello');
  try
    lKeyword := TMinItemsKeyword.Create(3);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Validação de minItems deve ser ignorada em tipos não array');
  finally
    lInstance.Free;
  end;
end;

procedure TTestItemsCountKeywords.TestMaxItemsPasses;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONObject.ParseJSONValue('[1, 2, 3]');
  try
    lKeyword := TMaxItemsKeyword.Create(3);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Quantidade exata deve passar no maxItems');
  finally
    lInstance.Free;
  end;

  lInstance := TJSONObject.ParseJSONValue('[1, 2]');
  try
    lKeyword := TMaxItemsKeyword.Create(3);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Quantidade menor deve passar no maxItems');
  finally
    lInstance.Free;
  end;
end;

procedure TTestItemsCountKeywords.TestMaxItemsFails;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONObject.ParseJSONValue('[1, 2, 4, 5]');
  try
    lKeyword := TMaxItemsKeyword.Create(3);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Quantidade maior deve falhar no maxItems');
    CheckEquals(KEYWORD_MAXITEMS, lResult.Errors[0].Keyword);
    CheckEquals(3, lResult.Errors[0].Context.GetValue<Integer>('limit'));
    CheckEquals(4, lResult.Errors[0].Context.GetValue<Integer>('actual'));
  finally
    lInstance.Free;
  end;
end;

procedure TTestItemsCountKeywords.TestMaxItemsIgnoredOnNonArrays;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('hello');
  try
    lKeyword := TMaxItemsKeyword.Create(3);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Validação de maxItems deve ser ignorada em tipos não array');
  finally
    lInstance.Free;
  end;
end;

initialization
  RegisterTest(TTestItemsCountKeywords.Suite);

end.
