unit TestJsonSchema.Keywords.ConstKeyword;

(*
--------------------------------------------------------------------------------
Unit tests for the 'const' validation keyword.
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Keywords.ConstKeyword,
  JsonSchema.Results;

type
  TTestConstKeyword = class(TTestCase)
  published
    procedure TestConstStringEquals;
    procedure TestConstStringNotEquals;
    procedure TestConstObjectEquals;
    procedure TestConstObjectNotEquals;
    procedure TestConstArrayEquals;
    procedure TestConstArrayNotEquals;
    procedure TestConstNullEquals;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TTestConstKeyword }

procedure TTestConstKeyword.TestConstStringEquals;
var
  lConstVal, lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lConstVal := TJSONString.Create('hello');
  lInstance := TJSONString.Create('hello');
  try
    lKeyword := TConstKeyword.Create(lConstVal);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'String idêntica deve ser válida');
  finally
    lConstVal.Free;
    lInstance.Free;
  end;
end;

procedure TTestConstKeyword.TestConstStringNotEquals;
var
  lConstVal, lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lConstVal := TJSONString.Create('hello');
  lInstance := TJSONString.Create('world');
  try
    lKeyword := TConstKeyword.Create(lConstVal);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Strings diferentes devem ser inválidas');
    CheckEquals(KEYWORD_CONST, lResult.Errors[0].Keyword);
    CheckEquals('"hello"', lResult.Errors[0].Context.GetValue<string>('expected'));
  finally
    lConstVal.Free;
    lInstance.Free;
  end;
end;

procedure TTestConstKeyword.TestConstObjectEquals;
var
  lConstVal, lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lConstVal := TJSONObject.ParseJSONValue('{"a": 1, "b": true}');
  lInstance := TJSONObject.ParseJSONValue('{"b": true, "a": 1}'); // keys in different order
  try
    lKeyword := TConstKeyword.Create(lConstVal);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Objetos com pares idênticos devem ser válidos independente da ordem');
  finally
    lConstVal.Free;
    lInstance.Free;
  end;
end;

procedure TTestConstKeyword.TestConstObjectNotEquals;
var
  lConstVal, lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lConstVal := TJSONObject.ParseJSONValue('{"a": 1}');
  lInstance := TJSONObject.ParseJSONValue('{"a": 2}');
  try
    lKeyword := TConstKeyword.Create(lConstVal);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Objetos com valores diferentes devem ser inválidos');
  finally
    lConstVal.Free;
    lInstance.Free;
  end;
end;

procedure TTestConstKeyword.TestConstArrayEquals;
var
  lConstVal, lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lConstVal := TJSONObject.ParseJSONValue('[1, "abc", null]');
  lInstance := TJSONObject.ParseJSONValue('[1, "abc", null]');
  try
    lKeyword := TConstKeyword.Create(lConstVal);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Arrays idênticos devem ser válidos');
  finally
    lConstVal.Free;
    lInstance.Free;
  end;
end;

procedure TTestConstKeyword.TestConstArrayNotEquals;
var
  lConstVal, lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lConstVal := TJSONObject.ParseJSONValue('[1, 2]');
  lInstance := TJSONObject.ParseJSONValue('[2, 1]'); // different order in arrays matters
  try
    lKeyword := TConstKeyword.Create(lConstVal);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Arrays com ordem diferente devem ser inválidos');
  finally
    lConstVal.Free;
    lInstance.Free;
  end;
end;

procedure TTestConstKeyword.TestConstNullEquals;
var
  lConstVal, lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lConstVal := TJSONNull.Create;
  lInstance := TJSONNull.Create;
  try
    lKeyword := TConstKeyword.Create(lConstVal);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Null deve ser igual a null');
  finally
    lConstVal.Free;
    lInstance.Free;
  end;
end;

initialization
  RegisterTest(TTestConstKeyword.Suite);

end.
