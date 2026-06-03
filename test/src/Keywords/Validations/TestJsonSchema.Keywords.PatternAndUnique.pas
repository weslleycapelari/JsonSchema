unit TestJsonSchema.Keywords.PatternAndUnique;

(*
--------------------------------------------------------------------------------
Unit tests for the 'pattern' and 'uniqueItems' validation keywords.
--------------------------------------------------------------------------------
*)

interface

uses
  TestFramework,
  System.JSON,
  System.SysUtils,
  JsonSchema.Core.Constants,
  JsonSchema.Core.Interfaces,
  JsonSchema.Keywords.Pattern,
  JsonSchema.Keywords.UniqueItems,
  JsonSchema.Results;

type
  TTestPatternAndUniqueKeywords = class(TTestCase)
  published
    procedure TestPatternPasses;
    procedure TestPatternFails;
    procedure TestPatternIgnoredOnNonStrings;
    procedure TestUniqueItemsPasses;
    procedure TestUniqueItemsFails;
    procedure TestUniqueItemsIgnoredOnNonArrays;
  end;

implementation

uses
  JsonSchema.JSONHelper;

{ TTestPatternAndUniqueKeywords }

procedure TTestPatternAndUniqueKeywords.TestPatternPasses;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('abcdef');
  try
    lKeyword := TPatternKeyword.Create('^abc');
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, '"abcdef" should match "^abc"');
  finally
    lInstance.Free;
  end;

  lInstance := TJSONString.Create('123abc456');
  try
    lKeyword := TPatternKeyword.Create('abc');
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, '"123abc456" should match "abc"');
  finally
    lInstance.Free;
  end;
end;

procedure TTestPatternAndUniqueKeywords.TestPatternFails;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('defabc');
  try
    lKeyword := TPatternKeyword.Create('^abc');
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, '"defabc" should not match "^abc"');
    CheckEquals(KEYWORD_PATTERN, lResult.Errors[0].Keyword);
    CheckEquals('^abc', lResult.Errors[0].Context.GetValue<string>('pattern'));
    CheckEquals('defabc', lResult.Errors[0].Context.GetValue<string>('actual'));
  finally
    lInstance.Free;
  end;
end;

procedure TTestPatternAndUniqueKeywords.TestPatternIgnoredOnNonStrings;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONNumber.Create(123);
  try
    lKeyword := TPatternKeyword.Create('^abc');
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Pattern should be ignored for numbers');
  finally
    lInstance.Free;
  end;
end;

procedure TTestPatternAndUniqueKeywords.TestUniqueItemsPasses;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONObject.ParseJSONValue('[1, 2, 3, 4]');
  try
    lKeyword := TUniqueItemsKeyword.Create(True);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, '[1,2,3,4] has unique elements');
  finally
    lInstance.Free;
  end;

  lInstance := TJSONObject.ParseJSONValue('[{"a": 1}, {"a": 2}]');
  try
    lKeyword := TUniqueItemsKeyword.Create(True);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'Different objects should be unique');
  finally
    lInstance.Free;
  end;
end;

procedure TTestPatternAndUniqueKeywords.TestUniqueItemsFails;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONObject.ParseJSONValue('[1, 2, 3, 2]');
  try
    lKeyword := TUniqueItemsKeyword.Create(True);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, '[1,2,3,2] has duplicate "2"');
    CheckEquals(KEYWORD_UNIQUEITEMS, lResult.Errors[0].Keyword);
  finally
    lInstance.Free;
  end;

  lInstance := TJSONObject.ParseJSONValue('[{"a": 1, "b": 2}, {"b": 2, "a": 1}]');
  try
    lKeyword := TUniqueItemsKeyword.Create(True);
    lResult := lKeyword.Validate(lInstance);
    CheckFalse(lResult.IsValid, 'Objects with same pairs but different order are equivalent and thus non-unique');
  finally
    lInstance.Free;
  end;
end;

procedure TTestPatternAndUniqueKeywords.TestUniqueItemsIgnoredOnNonArrays;
var
  lInstance: TJSONValue;
  lKeyword: IJsonSchemaKeyword;
  lResult: IValidationResult;
begin
  lInstance := TJSONString.Create('abc');
  try
    lKeyword := TUniqueItemsKeyword.Create(True);
    lResult := lKeyword.Validate(lInstance);
    CheckTrue(lResult.IsValid, 'UniqueItems should be ignored on strings');
  finally
    lInstance.Free;
  end;
end;

initialization
  RegisterTest(TTestPatternAndUniqueKeywords.Suite);

end.
