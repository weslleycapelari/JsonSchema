unit TestJsonSchema.Keywords.Required;

(*
--------------------------------------------------------------------------------
Unit tests for the 'required' validation keyword.
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Keywords.Required,
  JsonSchema.Results;

type
  TTestRequiredKeyword = class(TTestCase)
  published
    procedure TestRequiredPropertiesExist;
    procedure TestRequiredPropertiesMissing;
    procedure TestRequiredValidationIgnoredOnNonObjects;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TTestRequiredKeyword }

procedure TTestRequiredKeyword.TestRequiredPropertiesExist;
var
  lRequiredList: TJSONArray;
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lRequiredList := TJSONArray(TJSONObject.ParseJSONValue('["name", "age"]'));
  lInstance := TJSONObject.ParseJSONValue('{"name": "John Doe", "age": 30, "gender": "male"}');
  try
    lKeyword := TRequiredKeyword.Create(lRequiredList);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Objeto que contém todos os campos obrigatórios deve ser válido');
  finally
    lRequiredList.Free;
    lInstance.Free;
  end;
end;

procedure TTestRequiredKeyword.TestRequiredPropertiesMissing;
var
  lRequiredList: TJSONArray;
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lRequiredList := TJSONArray(TJSONObject.ParseJSONValue('["name", "age", "email"]'));
  lInstance := TJSONObject.ParseJSONValue('{"name": "John Doe"}'); // missing age and email
  try
    lKeyword := TRequiredKeyword.Create(lRequiredList);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Objeto com campos obrigatórios ausentes deve ser inválido');
    
    // Check that we returned exactly 2 errors (one for age and one for email)
    CheckEquals(2, Length(lResult.Errors), 'Deve ter 2 erros para as 2 propriedades obrigatórias ausentes');
    
    CheckEquals(KEYWORD_REQUIRED, lResult.Errors[0].Keyword);
    CheckEquals('age', lResult.Errors[0].Context.GetValue<string>('missing'));
    
    CheckEquals(KEYWORD_REQUIRED, lResult.Errors[1].Keyword);
    CheckEquals('email', lResult.Errors[1].Context.GetValue<string>('missing'));
  finally
    lRequiredList.Free;
    lInstance.Free;
  end;
end;

procedure TTestRequiredKeyword.TestRequiredValidationIgnoredOnNonObjects;
var
  lRequiredList: TJSONArray;
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lRequiredList := TJSONArray(TJSONObject.ParseJSONValue('["name"]'));
  lInstance := TJSONString.Create('John Doe'); // instance is a string, not an object
  try
    lKeyword := TRequiredKeyword.Create(lRequiredList);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Validação de required deve ser ignorada em tipos que não são objetos');
  finally
    lRequiredList.Free;
    lInstance.Free;
  end;
end;

initialization
  RegisterTest(TTestRequiredKeyword.Suite);

end.
