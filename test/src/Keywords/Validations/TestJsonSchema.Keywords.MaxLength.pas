unit TestJsonSchema.Keywords.MaxLength;

(*
--------------------------------------------------------------------------------
Unit tests for the 'maxLength' validation keyword.
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Keywords.MaxLength,
  JsonSchema.Results;

type
  TTestMaxLengthKeyword = class(TTestCase)
  published
    procedure TestMaxLengthExact;
    procedure TestMaxLengthUnder;
    procedure TestMaxLengthOver;
    procedure TestMaxLengthIgnoredOnNonStrings;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TTestMaxLengthKeyword }

procedure TTestMaxLengthKeyword.TestMaxLengthExact;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('hello');
  try
    lKeyword := TMaxLengthKeyword.Create(5);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Comprimento exato deve ser válido');
  finally
    lInstance.Free;
  end;
end;

procedure TTestMaxLengthKeyword.TestMaxLengthUnder;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('abc');
  try
    lKeyword := TMaxLengthKeyword.Create(5);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Comprimento abaixo do limite deve ser válido');
  finally
    lInstance.Free;
  end;
end;

procedure TTestMaxLengthKeyword.TestMaxLengthOver;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('hello world');
  try
    lKeyword := TMaxLengthKeyword.Create(5);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Comprimento acima do limite deve ser inválido');
    CheckEquals(KEYWORD_MAXLENGTH, lResult.Errors[0].Keyword);
    CheckEquals(5, lResult.Errors[0].Context.GetValue<Integer>('limit'));
    CheckEquals(11, lResult.Errors[0].Context.GetValue<Integer>('actual'));
  finally
    lInstance.Free;
  end;
end;

procedure TTestMaxLengthKeyword.TestMaxLengthIgnoredOnNonStrings;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONNumber.Create(123456789);
  try
    lKeyword := TMaxLengthKeyword.Create(5);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Validação de maxLength deve ser ignorada em tipos não string');
  finally
    lInstance.Free;
  end;
end;

initialization
  RegisterTest(TTestMaxLengthKeyword.Suite);

end.
