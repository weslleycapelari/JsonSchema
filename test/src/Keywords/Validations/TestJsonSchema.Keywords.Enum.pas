unit TestJsonSchema.Keywords.Enum;

(*
--------------------------------------------------------------------------------
Unit tests for the 'enum' validation keyword.
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Keywords.Enum,
  JsonSchema.Results;

type
  TTestEnumKeyword = class(TTestCase)
  published
    procedure TestEnumContainsString;
    procedure TestEnumDoesNotContainString;
    procedure TestEnumContainsMixedTypes;
    procedure TestEnumDoesNotContainMixedTypes;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TTestEnumKeyword }

procedure TTestEnumKeyword.TestEnumContainsString;
var
  lEnumArray: TJSONArray;
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lEnumArray := TJSONArray(TJSONObject.ParseJSONValue('["apple", "banana", "cherry"]'));
  lInstance := TJSONString.Create('banana');
  try
    lKeyword := TEnumKeyword.Create(lEnumArray);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Item presente no enum deve ser válido');
  finally
    lEnumArray.Free;
    lInstance.Free;
  end;
end;

procedure TTestEnumKeyword.TestEnumDoesNotContainString;
var
  lEnumArray: TJSONArray;
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lEnumArray := TJSONArray(TJSONObject.ParseJSONValue('["apple", "banana"]'));
  lInstance := TJSONString.Create('cherry');
  try
    lKeyword := TEnumKeyword.Create(lEnumArray);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Item ausente no enum deve ser inválido');
    CheckEquals(KEYWORD_ENUM, lResult.Errors[0].Keyword);
    CheckEquals('["apple","banana"]', lResult.Errors[0].Context.GetValue<string>('allowed'));
  finally
    lEnumArray.Free;
    lInstance.Free;
  end;
end;

procedure TTestEnumKeyword.TestEnumContainsMixedTypes;
var
  lEnumArray: TJSONArray;
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lEnumArray := TJSONArray(TJSONObject.ParseJSONValue('[123, "hello", {"a": true}, null]'));
  lInstance := TJSONObject.ParseJSONValue('{"a": true}');
  try
    lKeyword := TEnumKeyword.Create(lEnumArray);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Objeto idêntico presente no enum misto deve ser válido');
  finally
    lEnumArray.Free;
    lInstance.Free;
  end;
end;

procedure TTestEnumKeyword.TestEnumDoesNotContainMixedTypes;
var
  lEnumArray: TJSONArray;
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lEnumArray := TJSONArray(TJSONObject.ParseJSONValue('[123, "hello", {"a": true}]'));
  lInstance := TJSONNull.Create;
  try
    lKeyword := TEnumKeyword.Create(lEnumArray);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Null ausente no enum misto deve ser inválido');
  finally
    lEnumArray.Free;
    lInstance.Free;
  end;
end;

initialization
  RegisterTest(TTestEnumKeyword.Suite);

end.
