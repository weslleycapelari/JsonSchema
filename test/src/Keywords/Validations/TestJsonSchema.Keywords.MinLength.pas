unit TestJsonSchema.Keywords.MinLength;

(*
--------------------------------------------------------------------------------
Unit tests for the 'minLength' keyword validator (TMinLengthKeyword).
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Keywords.MinLength,
  JsonSchema.Localization.Interfaces,
  JsonSchema.Localization.EnUS;

type
  /// <summary>DUnit test suite to validate the behaviors of the TMinLengthKeyword validator.</summary>
  TTestMinLengthKeyword = class(TTestCase)
  published
    procedure TestExactLengthPasses;
    procedure TestGreaterLengthPasses;
    procedure TestLessThanLengthFails;
    procedure TestEmptyStringWithMinLength1Fails;
    procedure TestEmptyStringWithMinLength0Passes;
    procedure TestNonStringValuePasses;
    procedure TestErrorMessageContainsLengths;
  end;

implementation

{ TTestMinLengthKeyword }

procedure TTestMinLengthKeyword.TestExactLengthPasses;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lKeyword := TMinLengthKeyword.Create(3);
  lInstance := TJSONString.Create('abc');
  try
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'String with length equal to minLength should pass');
  finally
    lInstance.Free;
  end;
end;

procedure TTestMinLengthKeyword.TestGreaterLengthPasses;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lKeyword := TMinLengthKeyword.Create(3);
  lInstance := TJSONString.Create('abcdef');
  try
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'String with length greater than minLength should pass');
  finally
    lInstance.Free;
  end;
end;

procedure TTestMinLengthKeyword.TestLessThanLengthFails;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lKeyword := TMinLengthKeyword.Create(5);
  lInstance := TJSONString.Create('ab');
  try
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'String with length less than minLength should fail');
    CheckEquals(1, Length(lResult.Errors), 'One error expected');
    CheckEquals('minLength', lResult.Errors[0].Keyword);
  finally
    lInstance.Free;
  end;
end;

procedure TTestMinLengthKeyword.TestEmptyStringWithMinLength1Fails;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lKeyword := TMinLengthKeyword.Create(1);
  lInstance := TJSONString.Create('');
  try
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Empty string with minLength=1 should fail');
    CheckEquals(1, Length(lResult.Errors));
  finally
    lInstance.Free;
  end;
end;

procedure TTestMinLengthKeyword.TestEmptyStringWithMinLength0Passes;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
begin
  lKeyword := TMinLengthKeyword.Create(0);
  lInstance := TJSONString.Create('');
  try
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Empty string with minLength=0 should pass');
  finally
    lInstance.Free;
  end;
end;

procedure TTestMinLengthKeyword.TestNonStringValuePasses;
var
  lKeyword: IJsonSchemaKeyword;
  lNumber: TJSONValue;
  lBool: TJSONValue;
  lNull: TJSONValue;
  lResult: IValidationResult;
begin
  lKeyword := TMinLengthKeyword.Create(5);

  lNumber := TJSONNumber.Create(42);
  try
    lResult := lKeyword.Validate(lNumber);
    CheckTrue(lResult.IsValid, 'minLength should not apply to numbers');
  finally
    lNumber.Free;
  end;

  lBool := TJSONTrue.Create;
  try
    lResult := lKeyword.Validate(lBool);
    CheckTrue(lResult.IsValid, 'minLength should not apply to booleans');
  finally
    lBool.Free;
  end;

  lNull := TJSONNull.Create;
  try
    lResult := lKeyword.Validate(lNull);
    CheckTrue(lResult.IsValid, 'minLength should not apply to null');
  finally
    lNull.Free;
  end;
end;

procedure TTestMinLengthKeyword.TestErrorMessageContainsLengths;
var
  lKeyword: IJsonSchemaKeyword;
  lInstance: TJSONValue;
  lResult: IValidationResult;
  lTranslator: ILocalization;
  lTranslation: TTranslation;
begin
  lKeyword := TMinLengthKeyword.Create(10);
  lInstance := TJSONString.Create('hi');
  try
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid);
    
    lTranslator := TLocalizationEnUS.Create;
    lTranslation := lTranslator.Translate(lResult.Errors[0]);
    
    Check(Pos('2', lTranslation.Message) > 0, 'Error message should contain actual length "2"');
    Check(Pos('10', lTranslation.Message) > 0, 'Error message should contain expected minLength "10"');
  finally
    lInstance.Free;
  end;
end;

initialization
  RegisterTest(TTestMinLengthKeyword.Suite);

end.
